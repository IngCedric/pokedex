/// Exception métier avec un message déjà prêt à afficher à l'utilisateur.
///
/// Toutes les couches data traduisent les erreurs techniques (DioException,
/// AuthException Supabase, erreurs Hive, ...) en [AppException] pour que la
/// couche presentation n'ait jamais à interpréter une exception technique.
class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, {this.cause});

  factory AppException.network() =>
      const AppException('Pas de connexion internet et aucune donnée en cache.');

  factory AppException.timeout() =>
      const AppException('Le serveur met trop de temps à répondre. Réessaie plus tard.');

  factory AppException.notFound() =>
      const AppException("La ressource demandée n'existe pas.");

  factory AppException.unauthorized() =>
      const AppException('Session expirée, merci de te reconnecter.');

  factory AppException.server() =>
      const AppException('Erreur serveur, réessaie plus tard.');

  factory AppException.unknown([Object? cause]) =>
      AppException('Une erreur inattendue est survenue.', cause: cause);

  @override
  String toString() => message;
}
