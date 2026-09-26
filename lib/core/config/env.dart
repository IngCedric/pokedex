import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Accès centralisé aux variables d'environnement (.env).
class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// URL de base de Supabase (sans le suffixe /rest/v1/), utilisée par
  /// `Supabase.initialize`.
  static String get supabaseBaseUrl =>
      supabaseUrl.replaceFirst(RegExp(r'/rest/v1/?$'), '');
}
