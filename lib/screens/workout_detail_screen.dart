import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../models/workout.dart';
import '../models/exercise_definition.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

// Modular components imports
import '../widgets/workout_detail/workout_detail_header.dart';
import '../widgets/workout_detail/workout_detail_map.dart';
import '../widgets/workout_detail/workout_detail_results.dart';
import '../widgets/workout_detail/workout_analysis_splits.dart';
import '../widgets/workout_detail/workout_charts_container.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;
  final String? postId;
  final List<dynamic>? likedBy;
  final int? commentsCount;
  final String? authorName;
  final String? authorPhotoUrl;
  final String? authorUid;

  const WorkoutDetailScreen({
    super.key, 
    required this.workout,
    this.postId,
    this.likedBy,
    this.commentsCount,
    this.authorName,
    this.authorPhotoUrl,
    this.authorUid,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late Workout _workout;
  bool _isLoading = false;
  final ScreenshotController _screenshotController = ScreenshotController();
  final ValueNotifier<LatLng?> _trackingPinPositionNotifier = ValueNotifier<LatLng?>(null);

  String _userName = 'Atlet';
  String? _userPhotoUrl;

  /// Incremented to force FutureBuilder to re-fetch photos from DB
  int _photoRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _workout = widget.workout;
    
    // Gunakan data author dari Feed jika tersedia, jika tidak maka load profil user saat ini
    if (widget.authorName != null && widget.authorName!.isNotEmpty) {
      _userName = widget.authorName!;
      _userPhotoUrl = widget.authorPhotoUrl;
    } else {
      _loadUserProfile();
    }
  }

  @override
  void dispose() {
    _trackingPinPositionNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await ProfileService.getProfile();
      if (mounted) {
        setState(() {
          String name = profile[ProfileService.keyName] ?? '';
          if (name.isEmpty) name = AuthService.displayName;
          if (name.isEmpty) name = 'Atlet';
          _userName = name;
          _userPhotoUrl = profile['photoUrl'] ?? AuthService.photoUrl;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      setState(() => _isLoading = true);
      
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(pickedFile.path)}';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

      // Simpan ke tabel terpisah workout_photos (lazy loading)
      if (_workout.id != null) {
        await DatabaseHelper().addWorkoutPhoto(_workout.id!, savedImage.path);
      }

      setState(() {
        _isLoading = false;
        // Trigger rebuild — FutureBuilder akan re-fetch foto dari DB
        _photoRefreshKey++;
      });
    }
  }

  Future<void> _shareActivity() async {
    final image = await _screenshotController.capture();
    if (image != null) {
      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/workout_share.png').create();
      await imagePath.writeAsBytes(image);
      
      await Share.shareXFiles([XFile(imagePath.path)], text: 'Latihan saya hari ini: ${_workout.title ?? _workout.typeLabel}!  #Kora');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double workoutDistance = _workout.distance ?? 0.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppTheme.themeNotifier,
        builder: (context, _, __) {
          return Screenshot(
            controller: _screenshotController,
            child: Stack(
              children: [
                // ── 1. MAPS INTERAKTIF DI LAYER PALING BAWAH (FULL SCREEN) ─────────────────────────
                Positioned.fill(
                  child: WorkoutDetailMap(
                    workout: _workout,
                    trackingPinPositionNotifier: _trackingPinPositionNotifier,
                  ),
                ),

                // ── 2. TOMBOL BACK & SHARE DI POJOK ATAS ─────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  child: CircleAvatar(
                    backgroundColor: AppTheme.background.withOpacity(0.8),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 12,
                  child: CircleAvatar(
                    backgroundColor: AppTheme.background.withOpacity(0.8),
                    child: IconButton(
                      icon: Icon(Icons.share_outlined, color: AppTheme.textPrimary, size: 18),
                      onPressed: _shareActivity,
                    ),
                  ),
                ),

                // ── 3. PANEL DETAIL (DRAGGABLE SHEET) ─────────────────────────────
                DraggableScrollableSheet(
                  initialChildSize: 0.55,
                  minChildSize: 0.10, // Sisakan 10% agar tetap bisa ditarik kembali
                  maxChildSize: 0.95,
                  snap: true,
                  builder: (BuildContext context, ScrollController scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: CustomScrollView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverList(
                            delegate: SliverChildListDelegate([
                              // Handle (Garis kecil di tengah atas panel)
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                                  width: 40,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: AppTheme.textSecondary.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              // A. HEADER & METRIK UTAMA (3x2)
                              WorkoutDetailHeader(
                                workout: _workout,
                                userName: _userName,
                                userPhotoUrl: _userPhotoUrl,
                                postId: widget.postId,
                                likedBy: widget.likedBy,
                                commentsCount: widget.commentsCount,
                              ),
                              const SizedBox(height: 12),

                              // B. HASIL / BEST EFFORTS
                              if (workoutDistance > 0) ...[
                                WorkoutDetailResults(workout: _workout),
                                const SizedBox(height: 16),
                              ],

                              // C. ANALISIS WORKOUT & LAP SPLITS
                              if (workoutDistance > 0) ...[
                                WorkoutAnalysisSplits(workout: _workout),
                                const SizedBox(height: 16),
                              ],

                              // D. PACE GRAFIK, GAP, & PACE ZONES
                              if (workoutDistance > 0) ...[
                                WorkoutChartsContainer(
                                  workout: _workout,
                                  trackingPinPositionNotifier: _trackingPinPositionNotifier,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // E. MUSCLE DISTRIBUTION (jika weightlifting)
                              if (_workout.type == 'weightlifting') ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: _buildMuscleSectionFromNotes(),
                                ),
                                const SizedBox(height: 28),
                              ],

                              // F. DETAIL PER GERAKAN (jika notes/weightlifting)
                              if (_workout.notes.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: _buildSectionTitle('Detail Per Gerakan'),
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: _buildDetailLogsFromNotes(),
                                ),
                                const SizedBox(height: 28),
                              ],

                              // G. GALLERY FOTO LATIHAN
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildSectionTitle('Foto Latihan'),
                                    IconButton(
                                      icon: Icon(Icons.add_a_photo, color: AppTheme.electricBlue),
                                      onPressed: _isLoading ? null : _pickImage,
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_workout.id != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: FutureBuilder<List<String>>(
                                    key: ValueKey('photos_$_photoRefreshKey'),
                                    future: DatabaseHelper().getWorkoutPhotos(_workout.id!),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const SizedBox(
                                          height: 80,
                                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        );
                                      }
                                      final photos = snapshot.data ?? [];
                                      if (photos.isEmpty) return const SizedBox.shrink();
                                      return SizedBox(
                                        height: 160,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: photos.length,
                                          itemBuilder: (context, i) {
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 12),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(16),
                                                child: Image.file(
                                                  File(photos[i]),
                                                  width: 240,
                                                  height: 160,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 100),
                            ]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- PARSE NOTES: Muscle Distribution ---
  Widget _buildMuscleSectionFromNotes() {
    final notes = _workout.notes;
    final detailIdx = notes.indexOf('Detail Latihan:');
    if (detailIdx < 0) return const SizedBox();
    final rawDetail = notes.substring(detailIdx + 'Detail Latihan:'.length).trim();

    final exerciseNames = rawDetail
        .split('\n')
        .where((line) => line.trim().isNotEmpty && line.trim().endsWith(':') && !line.trim().startsWith(' '))
        .map((line) => line.trim().replaceAll(':', '').trim())
        .toList();

    if (exerciseNames.isEmpty) return const SizedBox();

    final Map<String, double> muscleDist = {};
    for (final name in exerciseNames) {
      final ex = exerciseDatabase.cast<ExerciseDefinition?>().firstWhere(
        (e) => e!.name.toLowerCase() == name.toLowerCase(),
        orElse: () => null,
      );
      if (ex != null) {
        for (final muscle in ex.muscleGroups) {
          muscleDist[muscle] = (muscleDist[muscle] ?? 0) + 1;
        }
      } else {
        muscleDist[name] = (muscleDist[name] ?? 0) + 1;
      }
    }

    if (muscleDist.isEmpty) return const SizedBox();

    final totalVol = muscleDist.values.fold(0.0, (a, b) => a + b);
    final sorted = muscleDist.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Otot Terlatih', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...sorted.map((e) {
            final percent = e.value / totalVol;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(width: 110, child: Text(e.key, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 8,
                        backgroundColor: AppTheme.border,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.electricBlue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(width: 40, child: Text('${(percent * 100).toStringAsFixed(0)}%', textAlign: TextAlign.right, style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- PARSE NOTES: Detail Per Gerakan ---
  Widget _buildDetailLogsFromNotes() {
    final notes = _workout.notes;
    final detailIdx = notes.indexOf('Detail Latihan:');
    String rawDetail = detailIdx >= 0 ? notes.substring(detailIdx + 'Detail Latihan:'.length).trim() : notes;

    rawDetail = rawDetail.replaceAll(RegExp(r'Catatan:.*\n?'), '').replaceAll(RegExp(r'Intensitas \(RPE\):.*\n?'), '').trim();

    if (rawDetail.isEmpty) return const SizedBox();

    final blocks = rawDetail.split(RegExp(r'\n(?=[A-Za-z])')).where((b) => b.trim().isNotEmpty).toList();

    return Column(
      children: blocks.map((block) {
        final lines = block.trim().split('\n');
        final title = lines.first.replaceAll(':', '').trim();
        final setLines = lines.skip(1).where((l) => l.trim().isNotEmpty).toList();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.fitness_center_rounded, color: AppTheme.electricBlue, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15))),
              ]),
              if (setLines.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...setLines.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: AppTheme.electricBlue.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text('${e.key + 1}', style: TextStyle(color: AppTheme.electricBlue, fontSize: 12, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    Text(e.value.trim(), style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                  ]),
                )),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
    );
  }
}
