/// Global environment configuration for Prometheon Clinic OS.
class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qshmccjazkupvbelyjhi.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_0FJxIsGzTDi8AeIj42utSQ_IPEKBWkZ',
  );

  static const String supportWhatsApp =
      String.fromEnvironment('SUPPORT_WHATSAPP');
}
