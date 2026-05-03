import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../services/tmdb_api.dart';

// Theme Provider
enum ThemeModeOption { system, light, dark }

class ThemeNotifier extends StateNotifier<ThemeModeOption> {
  ThemeNotifier() : super(ThemeModeOption.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    state = ThemeModeOption.values[themeIndex];
  }

  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', state.index);
  }

  void setThemeMode(ThemeModeOption mode) {
    state = mode;
    _saveThemeMode();
  }

  void toggleTheme() {
    switch (state) {
      case ThemeModeOption.system:
        state = ThemeModeOption.light;
        break;
      case ThemeModeOption.light:
        state = ThemeModeOption.dark;
        break;
      case ThemeModeOption.dark:
        state = ThemeModeOption.system;
        break;
    }
    _saveThemeMode();
  }

  ThemeMode get themeMode {
    switch (state) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeModeOption>((ref) {
  return ThemeNotifier();
});

// API Provider
final tmdbApiProvider = Provider<TmdbApiClient>((ref) => TmdbApi());

class MoviesState {
  final List<Movie> movies;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int page;
  final bool hasMore;

  const MoviesState({
    this.movies = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.page = 1,
    this.hasMore = true,
  });

  MoviesState copyWith({
    List<Movie>? movies,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? page,
    bool? hasMore,
  }) {
    return MoviesState(
      movies: movies ?? this.movies,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// Movies Provider
final moviesProvider = StateNotifierProvider<MoviesNotifier, MoviesState>((ref) {
  final api = ref.watch(tmdbApiProvider);
  return MoviesNotifier(api);
});

class MoviesNotifier extends StateNotifier<MoviesState> {
  final TmdbApiClient api;

  MoviesNotifier(this.api) : super(const MoviesState(isLoading: true)) {
    fetchMovies();
  }

  Future<void> fetchMovies() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      page: 1,
      hasMore: true,
    );
    try {
      final movies = await api.getPopularMovies(page: 1);
      state = state.copyWith(
        movies: movies,
        isLoading: false,
        page: 1,
        hasMore: movies.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refresh() async {
    await fetchMovies();
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final movies = await api.getPopularMovies(page: nextPage);
      state = state.copyWith(
        movies: [...state.movies, ...movies],
        isLoadingMore: false,
        page: nextPage,
        hasMore: movies.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }
}

// Search Providers
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchMoviesProvider = FutureProvider<List<Movie>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return Future.value([]);
  final api = ref.watch(tmdbApiProvider);
  return api.searchMovies(query);
});

// Favourites Provider
final favouritesProvider = StateNotifierProvider<FavouritesNotifier, List<Movie>>((ref) {
  return FavouritesNotifier();
});

class FavouritesNotifier extends StateNotifier<List<Movie>> {
  FavouritesNotifier() : super([]) {
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('favourites') ?? [];
    state = jsonList.map((json) => Movie.fromJson(jsonDecode(json))).toList();
  }

  Future<void> _saveFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((movie) => jsonEncode({
      'id': movie.id,
      'title': movie.title,
      'poster_path': movie.posterPath,
      'release_date': movie.releaseDate,
      'vote_average': movie.voteAverage,
      'overview': movie.overview,
      'genres': movie.genres,
    })).toList();
    await prefs.setStringList('favourites', jsonList);
  }

  void addFavourite(Movie movie) {
    if (!state.any((m) => m.id == movie.id)) {
      state = [...state, movie];
      _saveFavourites();
    }
  }

  void removeFavourite(int id) {
    state = state.where((m) => m.id != id).toList();
    _saveFavourites();
  }

  bool isFavourite(int id) {
    return state.any((m) => m.id == id);
  }
}

