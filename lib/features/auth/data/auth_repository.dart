import 'package:supabase_flutter/supabase_flutter.dart';
import '../../clinic/models/clinic_member_model.dart';
import '../../clinic/models/profile_model.dart';

abstract class AuthRepository {
  Stream<AuthState> get onAuthStateChange;
  User? get currentUser;
  Session? get currentSession;

  Future<AuthResponse> signUpClinic({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String clinicName,
  });

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> resetPasswordForEmail(String email);

  Future<void> updatePassword(String newPassword);

  Future<void> resendVerificationEmail(String email);

  Future<ProfileModel?> fetchCurrentProfile();

  Future<ClinicMemberModel?> fetchClinicMembership(String userId);
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({SupabaseClient? client}) : _customClient = client;

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  @override
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Future<AuthResponse> signUpClinic({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String clinicName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'account_type': 'clinic',
        'full_name': fullName,
        'phone': phone,
        'clinic_name': clinicName,
      },
    );
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.prometheon.clinic://login-callback/',
    );
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  @override
  Future<void> resendVerificationEmail(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  @override
  Future<ProfileModel?> fetchCurrentProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final res =
        await _client.from('profiles').select().eq('id', uid).maybeSingle();
    if (res == null) return null;
    return ProfileModel.fromJson(res);
  }

  @override
  Future<ClinicMemberModel?> fetchClinicMembership(String userId) async {
    final res = await _client
        .from('clinic_members')
        .select('clinic_id,user_id,role,clinical_access,created_at')
        .eq('user_id', userId)
        .maybeSingle();
    if (res == null) return null;
    return ClinicMemberModel.fromJson(res);
  }
}

class FakeAuthRepository implements AuthRepository {
  User? _mockUser;
  Session? _mockSession;
  ProfileModel? _mockProfile;
  ClinicMemberModel? _mockMembership;

  void setMockState({
    User? user,
    Session? session,
    ProfileModel? profile,
    ClinicMemberModel? membership,
  }) {
    _mockUser = user;
    _mockSession = session;
    _mockProfile = profile;
    _mockMembership = membership;
  }

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  User? get currentUser => _mockUser;

  @override
  Session? get currentSession => _mockSession;

  @override
  Future<AuthResponse> signUpClinic({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String clinicName,
  }) async {
    return AuthResponse(session: _mockSession, user: _mockUser);
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return AuthResponse(session: _mockSession, user: _mockUser);
  }

  @override
  Future<void> signOut() async {
    _mockUser = null;
    _mockSession = null;
    _mockProfile = null;
    _mockMembership = null;
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<void> resendVerificationEmail(String email) async {}

  @override
  Future<ProfileModel?> fetchCurrentProfile() async => _mockProfile;

  @override
  Future<ClinicMemberModel?> fetchClinicMembership(String userId) async =>
      _mockMembership;
}
