import 'package:flutter_dotenv/flutter_dotenv.dart';

String get _dotenvBearerToken => dotenv.env['TMDB_API_BEARER_TOKEN'] ?? '';
String get _dotenvApiKey => dotenv.env['TMDB_API_KEY'] ?? '';

String get tmdbApiBearerToken {
  if (_dotenvBearerToken.isNotEmpty) {
    return _dotenvBearerToken;
  }
  return const String.fromEnvironment(
    'TMDB_API_BEARER_TOKEN',
    defaultValue: '',
  );
}

String get tmdbApiKey {
  if (_dotenvApiKey.isNotEmpty) {
    return _dotenvApiKey;
  }
  return const String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: '',
  );
}

String get tmdbBaseUrl {
  return dotenv.env['TMDB_BASE_URL'] ??
      const String.fromEnvironment(
        'TMDB_BASE_URL',
        defaultValue: 'https://api.themoviedb.org/3/',
      );
}

bool get tmdbHasBearerToken => tmdbApiBearerToken.isNotEmpty;

bool get tmdbHasApiKey => tmdbApiKey.isNotEmpty;

bool get tmdbHasCredentials => tmdbHasBearerToken || tmdbHasApiKey;

String get tmdbCredentialErrorMessage =>
    'TMDB API credentials not provided. Use --dart-define=TMDB_API_BEARER_TOKEN=<token> '
    'or --dart-define=TMDB_API_KEY=<key> when launching the app.';
