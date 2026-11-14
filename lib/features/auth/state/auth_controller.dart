import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/error_mapper.dart';
import '../../clinic/models/clinic_member_model.dart';
import '../../clinic/models/profile_model.dart';
import '../data/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? repository})
      : _repo = repository ?? SupabaseAuthRepository() {
    _init();
  }

  final AuthRepository _repo;
  StreamSubscription<AuthState>? _sub;

  bool _loading = true;
  String? _errorMessage;
  ProfileModel? _profile;
  ClinicMemberModel? _membership;
  bool _unconfirmedEmailSent = false;
  int _refreshGeneration = 0;
  String? _profileUserId;

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  ProfileModel? get profile => _profile;
  ClinicMemberModel? get membership => _membership;
  bool get isAuthenticated => _repo.currentUser != null;
  bool get unconfirmedEmailSent => _unconfirmedEmailSent;
  User? get user => _repo.currentUser;

  void _init() {
    _sub = _repo.onAuthStateChange.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        await refreshProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _refreshGeneration++;
        _profileUserId = null;
        _profile = null;
        _membership = null;
        _errorMessage = null;
        _loading = false;
        notifyListeners();
      } else if (event == AuthChangeEvent.passwordRecovery) {
        notifyListeners();
      }
    });

    initSession();
  }

  /// Initializes or re-synchronizes the auth session and user profile.
  Future<void> initSession() async {
    await refreshProfile();
  }

  Future<void> refreshProfile() async {
    final generation = ++_refreshGeneration;
    final userId = _repo.currentUser?.id;
    if (_profileUserId != userId) {
      _profileUserId = userId;
      _profile = null;
      _membership = null;
    }
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (userId == null) {
        _profile = null;
        _membership = null;
        return;
      }
      final profile = await _repo.fetchCurrentProfile();
      if (!_isCurrentRefresh(generation, userId)) return;
      if (profile != null && profile.id != userId) {
        throw StateError('Profil autentikasi tidak sesuai dengan sesi aktif.');
      }
      final membership =
          profile == null ? null : await _repo.fetchClinicMembership(userId);
      if (!_isCurrentRefresh(generation, userId)) return;
      _profile = profile;
      _membership = membership;
    } catch (e) {
      if (_isCurrentRefresh(generation, userId)) {
        _profile = null;
        _membership = null;
        _errorMessage = ErrorMapper.mapError(e);
      }
    } finally {
      if (_isCurrentRefresh(generation, userId)) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  bool _isCurrentRefresh(int generation, String? userId) =>
      generation == _refreshGeneration && _repo.currentUser?.id == userId;

  Future<bool> signUpClinic({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String clinicName,
  }) async {
    _loading = true;
    _errorMessage = null;
    _unconfirmedEmailSent = false;
    notifyListeners();

    try {
      final res = await _repo.signUpClinic(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        clinicName: clinicName,
      );

      _loading = false;
      if (res.session == null && res.user != null) {
        // Email confirmation is enabled
        _unconfirmedEmailSent = true;
        notifyListeners();
        return true;
      }

      await refreshProfile();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.signIn(email: email, password: password);
      await refreshProfile();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repo.signOut();
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
    }
    _refreshGeneration++;
    _profileUserId = _repo.currentUser?.id;
    _profile = null;
    _membership = null;
    _loading = false;
    notifyListeners();
  }

  Future<bool> resetPasswordForEmail(String email) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.resetPasswordForEmail(email);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.updatePassword(newPassword);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerificationEmail(String email) async {
    try {
      await _repo.resendVerificationEmail(email);
      return true;
    } catch (e) {
      _errorMessage = ErrorMapper.mapError(e);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
