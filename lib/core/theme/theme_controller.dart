import 'package:flutter/material.dart';

import 'theme_config.dart';

/// Holds the live [AppThemeConfig]. Widgets call the setters; the app root
/// listens and rebuilds the [ThemeData].
class ThemeController extends ChangeNotifier {
  ThemeController([AppThemeConfig initial = kInitialThemeConfig])
      : _config = initial;

  AppThemeConfig _config;
  AppThemeConfig get config => _config;

  void _set(AppThemeConfig next) {
    _config = next;
    notifyListeners();
  }

  void setPalette(BrandPalette p) => _set(_config.copyWith(palette: p));
  void setMode(ThemeMode m) => _set(_config.copyWith(mode: m));
  void setRadius(double r) => _set(_config.copyWith(radius: r));
  void setDensity(UiDensity d) => _set(_config.copyWith(density: d));
  void setFontScale(double s) => _set(_config.copyWith(fontScale: s));
  void setFontFamily(String f) => _set(_config.copyWith(fontFamily: f));
  void reset() => _set(kInitialThemeConfig);
}
