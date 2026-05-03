import 'package:dio/dio.dart';
import '../config.dart';
import '../models/movie.dart';

abstract class TmdbApiClient {
  Future<List<Movie>> getPopularMovies({int page = 1});
  Future<List<Movie>> searchMovies(String query, {int page = 1});
  Future<Movie> getMovieDetails(int id);
}

class TmdbApi implements TmdbApiClient {
  late final Dio _dio;

  TmdbApi() {
    final options = BaseOptions(baseUrl: tmdbBaseUrl);
    if (tmdbHasBearerToken) {
      options.headers = {
        'Authorization': 'Bearer $tmdbApiBearerToken',
      };
    }
    _dio = Dio(options);
  }

  Map<String, dynamic> _buildQueryParameters(Map<String, dynamic> params) {
    return {
      ...params,
      if (tmdbHasApiKey) 'api_key': tmdbApiKey,
    };
  }

  void _ensureCredentials() {
    if (!tmdbHasCredentials) {
      throw StateError(tmdbCredentialErrorMessage);
    }
  }

  @override
  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    _ensureCredentials();
    final response = await _dio.get(
      'movie/popular',
      queryParameters: _buildQueryParameters({'page': page}),
    );
    final results = response.data['results'] as List;
    return results.map((json) => Movie.fromJson(json)).toList();
  }

  @override
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    _ensureCredentials();
    final response = await _dio.get(
      'search/movie',
      queryParameters: _buildQueryParameters({'query': query, 'page': page}),
    );
    final results = response.data['results'] as List;
    return results.map((json) => Movie.fromJson(json)).toList();
  }

  @override
  Future<Movie> getMovieDetails(int id) async {
    _ensureCredentials();
    final response = await _dio.get(
      'movie/$id',
      queryParameters: _buildQueryParameters({}),
    );
    return Movie.fromJson(response.data);
  }
}
