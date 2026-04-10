import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/workout.dart';
import '../services/database_helper.dart';
import '../services/location_service.dart';
import 'strava_import_screen.dart';

class RunningTrackerScreen extends StatefulWidget {
  final double userWeight;
  const RunningTrackerScreen({super.key, required this.userWeight});

  @override
  State<RunningTrackerScreen> createState() => _RunningTrackerScreenState();
}

class _RunningTrackerScreenState extends State<RunningTrackerScreen>
    with WidgetsBindingObserver {
  final MapController _mapController = MapController();

  // ── State UI ──────────────────────────────────────────────────────────
  List<LatLng> _routePoints = [];
  LatLng? _currentLocation;
  bool _isRunning = false;
  bool _hasStarted = false;
  bool _showPauseStopScreen = false;
  double _distanceKm = 0.0;
  int _elapsedSeconds = 0;
  int _movingSeconds = 0;
  double _elevationGain = 0.0;
  double _maxElevation = 0.0;
  List<String> _splits = [];

  // ── Local UI timer (fallback agar timer jalan meski service belum kirim data)
  Timer? _uiTimer;
  DateTime? _uiRunStartTime; // waktu mulai lari (dipakai timer lokal UI)
  int _elapsedBeforePause = 0; // detik yang sudah jalan sebelum pause

  // ── Data final untuk disimpan ─────────────────────────────────────────
  String? _finalSplitsJson;
  String? _finalRouteJson;

  // ── GPS stream awal (sebelum lari dimulai) ────────────────────────────
  StreamSubscription<Position>? _initialLocationStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
    _initGps();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    _uiTimer?.cancel();
    _initialLocationStream?.cancel();
    super.dispose();
  }

  // ── Local UI timer — jalan di main isolate, pasti akurat saat foreground ──
  void _startUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        // Hitung dari _uiRunStartTime agar akurat
        if (_uiRunStartTime != null) {
          _elapsedSeconds =
              _elapsedBeforePause +
              DateTime.now().difference(_uiRunStartTime!).inSeconds;
        }
      });
    });
  }

  void _stopUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = null;
  }

  // ── Terima data dari TaskHandler (GPS/distance update dari background) ─
  void _onReceiveTaskData(Object data) {
    if (!mounted || data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final type = map['type'] as String?;

    if (type == 'location') {
      final lat = map['lat'] as double?;
      final lng = map['lng'] as double?;
      if (lat != null && lng != null) {
        final newLoc = LatLng(lat, lng);
        if (!mounted) return;
        setState(() => _currentLocation = newLoc);
        if (_isRunning) {
          try { _mapController.move(newLoc, 17.0); } catch (_) {}
        }
      }
    } else if (type == 'update') {
      // Ambil data GPS/distance dari service
      // TIDAK override _elapsedSeconds — pakai UI timer yang lebih real-time
      if (!mounted) return;
      setState(() {
        _movingSeconds =
            map['movingSeconds'] as int? ?? _movingSeconds;
        _distanceKm =
            (map['distanceKm'] as num?)?.toDouble() ?? _distanceKm;
        _elevationGain =
            (map['elevationGain'] as num?)?.toDouble() ?? _elevationGain;
        _maxElevation =
            (map['maxElevation'] as num?)?.toDouble() ?? _maxElevation;

        final rawPoints = map['routePoints'];
        if (rawPoints is List && rawPoints.isNotEmpty) {
          _routePoints = rawPoints
              .map((p) =>
                  LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
              .toList();
        }

        final rawSplits = map['splits'];
        if (rawSplits is List) {
          _splits = rawSplits.map((s) => s.toString()).toList();
        }
      });
    } else if (type == 'final') {
      _finalSplitsJson = map['splits'] as String?;
      _finalRouteJson  = map['routePoints'] as String?;
      _distanceKm   = (map['distanceKm']   as num?)?.toDouble() ?? _distanceKm;
      _movingSeconds = map['movingSeconds'] as int?  ?? _movingSeconds;
      _elevationGain = (map['elevationGain'] as num?)?.toDouble() ?? _elevationGain;
      _maxElevation  = (map['maxElevation']  as num?)?.toDouble() ?? _maxElevation;
      _saveRunToDatabase();
    } else if (type == 'pause_from_notif') {
      _stopUiTimer();
      _elapsedBeforePause = _elapsedSeconds;
      setState(() {
        _isRunning = false;
        _showPauseStopScreen = true; // Munculkan layar pause
      });
    } else if (type == 'resume_from_notif') {
      _uiRunStartTime = DateTime.now();
      _startUiTimer();
      setState(() {
        _isRunning = true;
        _showPauseStopScreen = false;
      });
    } else if (type == 'stop_from_notif') {
      _stopRun();
    }
  }

  // ── Init GPS ──────────────────────────────────────────────────────────
  Future<void> _initGps() async {
    LocationService.initialize();
    try {
      await LocationService.requestPermissions();
    } catch (e) {
      debugPrint('⚠️ Permission error: $e');
    }
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Layanan GPS tidak aktif. Aktifkan GPS.');
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Izin lokasi ditolak.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Izin lokasi diblokir. Buka Settings.');
      return;
    }

    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() => _currentLocation = LatLng(lastPos.latitude, lastPos.longitude));
        try { _mapController.move(_currentLocation!, 17.0); } catch (_) {}
      }
    } catch (_) {}

    _startInitialLocationStream();
  }

  void _startInitialLocationStream() {
    _initialLocationStream?.cancel();
    _initialLocationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (!mounted || _isRunning) return;
      setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
      try { _mapController.move(_currentLocation!, 17.0); } catch (_) {}
    }, cancelOnError: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('🔄 [APP] Lifecycle: $state');

    if (state == AppLifecycleState.paused && _isRunning) {
      // Layar mati / app di-background: stop UI timer
      _stopUiTimer();
      debugPrint('⏸️ [UI] UI timer stopped — service keeps tracking in background');
    } else if (state == AppLifecycleState.resumed && _isRunning) {
      // Kembali ke foreground: 
      // JANGAN timpa/hitung ulang _uiRunStartTime karena DateTime.now() akan secara 
      // otomatis menghitung delta waktu asli sejak run dimulai/sejak resume terakhir, 
      // termasuk saat berada di background. Cukup jalankan lagi timer UI.
      _startUiTimer();
      _startInitialLocationStream();
      debugPrint('▶️ [UI] UI timer restarted after resume. Background time included.');
    }
  }

  // ── Start Run ─────────────────────────────────────────────────────────
  Future<void> _startRun() async {
    if (_currentLocation == null) {
      _showSnackBar('Menunggu sinyal GPS...');
      return;
    }

    // Reset semua state
    setState(() {
      _isRunning     = true;
      _hasStarted    = true;
      _showPauseStopScreen = false;
      _routePoints.clear();
      _distanceKm    = 0.0;
      _elapsedSeconds      = 0;
      _movingSeconds  = 0;
      _elevationGain  = 0.0;
      _maxElevation   = 0.0;
      _splits.clear();
      _elapsedBeforePause = 0;
    });

    // Catat waktu mulai untuk timer lokal UI
    _uiRunStartTime = DateTime.now();

    // Start UI timer LANGSUNG — tampilan waktu langsung berjalan
    _startUiTimer();

    // Stop GPS stream awal — service akan ambil alih GPS
    _initialLocationStream?.cancel();

    // Mulai foreground service
    // Service akan AUTO-START sendiri dari _handleStart() saat di call
    await LocationService.startService();
  }

  // ── Pause Run ─────────────────────────────────────────────────────────
  Future<void> _pauseRun() async {
    _stopUiTimer();
    _elapsedBeforePause = _elapsedSeconds; // simpan posisi elapsed

    await LocationService.sendCommand({'command': 'pause'});
    setState(() {
      _isRunning = false;
      _showPauseStopScreen = false;
    });
  }

  // ── Resume Run ────────────────────────────────────────────────────────
  Future<void> _resumeRun() async {
    // Restart timer lokal dari posisi pause terakhir
    _uiRunStartTime = DateTime.now();
    _startUiTimer();

    await LocationService.sendCommand({'command': 'resume'});
    setState(() {
      _isRunning = true;
      _showPauseStopScreen = false;
    });
  }

  // ── Stop Run ──────────────────────────────────────────────────────────
  Future<void> _stopRun() async {
    _stopUiTimer();
    
    // Jangan tunggu pesan balasan 'final' dari service
    // Langsung matikan status lari
    setState(() {
      _isRunning = false;
      _showPauseStopScreen = false;
    });

    // Hentikan service
    await LocationService.sendCommand({'command': 'stop'});
    
    // Simpan dari state UI yang sudah tersinkronisasi tiap detiknya
    await _saveRunToDatabase();
  }

  // ── Simpan ke Database ────────────────────────────────────────────────
  Future<void> _saveRunToDatabase() async {
    await LocationService.stopService();

    // Pencegahan jika tidak ada aktivitas (jarak di bawah 10 meter praktis dianggap 0)
    if (_distanceKm < 0.01) {
      if (mounted) {
        _showSnackBar('Aktivitas dibatalkan: Tidak ada rekaman jarak (0 km).');
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      }
      return;
    }

    final durationMinutes = _elapsedSeconds / 60.0;
    final calories =
        Workout.calculateCalories('running', durationMinutes);
    final protein = Workout.calculateProteinNeeded(
      'running', durationMinutes,
      weight: widget.userWeight,
    );

    final workout = Workout(
      type: 'running',
      duration: durationMinutes,
      distance: _distanceKm,
      caloriesBurned: calories,
      proteinNeeded: protein,
      date: DateTime.now(),
      notes: 'Lari GPS Tracker. Jarak: ${_distanceKm.toStringAsFixed(2)} km',
      movingTime: _movingSeconds / 60.0,
      elevationGain: _elevationGain,
      maxElevation: _maxElevation,
      splitsStr: _finalSplitsJson ?? jsonEncode(_splits),
      polyline: _finalRouteJson ??
          jsonEncode(_routePoints.map((p) => [p.latitude, p.longitude]).toList()),
    );

    await DatabaseHelper().insertWorkout(workout);

    if (mounted) {
      _showSnackBar('Sesi lari berhasil disimpan! 🎉');
      Navigator.pop(context);
    }
  }

  Future<void> _centerOnCurrentLocation() async {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 17.0);
    } else {
      _showSnackBar('Menunggu posisi GPS...');
    }
  }

  void _showSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _handleBackPress() {
    if (_isRunning || (_hasStarted && !_isRunning)) {
      setState(() {
        _showPauseStopScreen = true;
        if (_isRunning) _pauseRun();
      });
    } else {
      Navigator.pop(context);
    }
  }

  // ── Getters ───────────────────────────────────────────────────────────
  String get _formattedTime {
    final h = (_elapsedSeconds ~/ 3600);
    final m = ((_elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  String get _pace {
    if (_distanceKm < 0.01) return '--:--';
    final secs = _movingSeconds > 0 ? _movingSeconds : _elapsedSeconds;
    if (secs == 0) return '--:--';
    final paceMins = (secs / 60.0) / _distanceKm;
    if (paceMins > 99) return '--:--';
    final m = paceMins.truncate();
    final s = ((paceMins - m) * 60).truncate().toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── BUILD ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasStarted && !_isRunning,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _showPauseStopScreen
            ? _buildPauseStopScreen()
            : _buildMainScreen(),
      ),
    );
  }

  // ─── PAUSE/STOP SCREEN ────────────────────────────────────────────────
  Widget _buildPauseStopScreen() {
    return Container(
      color: const Color(0xFF111111),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Sesi Lari Dijeda',
                    style: TextStyle(
                      color: Color(0xFFFFD12B),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _pauseStatItem('Waktu', _formattedTime),
                      _pauseStatItem('Jarak', '${_distanceKm.toStringAsFixed(2)} km'),
                      _pauseStatItem('Pace', _pace),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _pauseStatItem('Elevasi', '${_elevationGain.toStringAsFixed(0)} m'),
                      _pauseStatItem('Max Elev', '${_maxElevation.toStringAsFixed(0)} m'),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GestureDetector(
                onTap: _resumeRun,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC5200),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.white, size: 32),
                      SizedBox(width: 8),
                      Text('Resume',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: GestureDetector(
                onTap: _stopRun,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stop, color: Colors.black, size: 32),
                      SizedBox(width: 8),
                      Text('Finish & Simpan',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _pauseStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ─── MAIN RUNNING SCREEN ──────────────────────────────────────────────
  Widget _buildMainScreen() {
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? const LatLng(-6.200000, 106.816666),
              initialZoom: 17.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.athletesync',
              ),
              PolylineLayer(
                polylines: [
                  if (_routePoints.length > 1)
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6.0,
                      color: const Color(0xFFFC5200),
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent.withValues(alpha: 0.3),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Back button
        Positioned(
          top: 50,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.black38,
            child: IconButton(
              icon: const Icon(Icons.expand_more, color: Colors.white, size: 30),
              onPressed: _handleBackPress,
            ),
          ),
        ),

        // GPS status badge
        Positioned(
          top: 50,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // GPS badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      color: _currentLocation != null ? Colors.greenAccent : Colors.redAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentLocation != null ? 'GPS Ready' : 'Mencari GPS...',
                      style: TextStyle(
                        color: _currentLocation != null ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Tombol import Strava
              if (!_isRunning && !_hasStarted)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StravaImportScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFC5200),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFC5200).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔗', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Text(
                          'Strava',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Map tools
        Positioned(
          right: 16,
          top: 110,
          child: Column(
            children: [
              _mapToolIcon(Icons.near_me_outlined),
              const SizedBox(height: 12),
              _mapToolIcon(Icons.my_location, onTap: _centerOnCurrentLocation),
            ],
          ),
        ),

        // Bottom panel
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isRunning && _hasStarted)
                Container(
                  width: double.infinity,
                  color: const Color(0xFFFFD12B),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Center(
                    child: Text('Dijeda',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 18)),
                  ),
                ),
              Container(
                color: const Color(0xFF191919),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _statItem('Time', _formattedTime),
                        _statItemPace('Avg pace (/km)', _pace),
                        _statItem('Distance (km)', _distanceKm.toStringAsFixed(2)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.black,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Row(
                  children: [
                    if (!_isRunning && _hasStarted) ...[
                      Expanded(child: _actionButton(
                        label: 'Resume',
                        color: const Color(0xFFFC5200),
                        icon: Icons.play_arrow,
                        textColor: Colors.white,
                        onTap: _resumeRun,
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _actionButton(
                        label: 'Finish',
                        color: Colors.white,
                        icon: Icons.stop,
                        textColor: Colors.black,
                        onTap: _stopRun,
                      )),
                    ] else if (_isRunning) ...[
                      Expanded(child: _actionButton(
                        label: 'Pause',
                        color: const Color(0xFFFC5200),
                        icon: Icons.pause,
                        textColor: Colors.white,
                        onTap: _pauseRun,
                      )),
                    ] else ...[
                      Expanded(child: _actionButton(
                        label: _currentLocation == null ? 'Mencari GPS...' : 'Start',
                        color: _currentLocation == null ? Colors.grey : const Color(0xFFFC5200),
                        icon: Icons.play_arrow,
                        textColor: Colors.white,
                        onTap: _currentLocation == null ? () {} : _startRun,
                      )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────
  Widget _mapToolIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
        Text(label,
            style: TextStyle(
                color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _statItemPace(String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.more_horiz, color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          ],
        ),
        Text(label,
            style: TextStyle(
                color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required IconData icon,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(32)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 28),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: textColor, fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
