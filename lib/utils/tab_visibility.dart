import 'package:flutter/foundation.dart';

/// TabVisibility — lightweight event bus berbasis ValueNotifier.
///
/// MainNavigation mem-broadcast index tab aktif ke sini.
/// Screen manapun (misal RunningTrackerScreen) bisa subscribe untuk
/// mengetahui apakah tab induknya sedang visible atau tidak.
///
/// Penggunaan:
///   // Di MainNavigation._goToTab():
///   TabVisibility.instance.setActiveTab(index);
///
///   // Di RunningTrackerScreen:
///   final bool isVisible = TabVisibility.instance.isTabVisible(2);
///   // atau listen:
///   TabVisibility.instance.addListener(_onTabChanged);
class TabVisibility extends ChangeNotifier {
  TabVisibility._();
  static final TabVisibility instance = TabVisibility._();

  int _activeTab = 0;

  /// Index tab yang sedang aktif/ditampilkan ke user.
  int get activeTab => _activeTab;

  /// Dipanggil MainNavigation setiap kali tab berganti.
  void setActiveTab(int index) {
    if (_activeTab == index) return;
    _activeTab = index;
    notifyListeners();
  }

  /// Cek apakah tab tertentu sedang visible.
  bool isTabVisible(int tabIndex) => _activeTab == tabIndex;
}
