import 'package:flutter_test/flutter_test.dart';
import 'package:tmdb_test/models/movie.dart';
import 'package:tmdb_test/providers/providers.dart';
import 'package:tmdb_test/services/tmdb_api.dart';

class FakeTmdbApi implements TmdbApiClient {
  @override
  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    if (page == 1) {
      return List.generate(
        20,
        (index) => Movie(
          id: index + 1,
          title: 'Movie ${index + 1}',
          posterPath: '/poster${index + 1}.jpg',
          backdropPath: '/backdrop${index + 1}.jpg',
          releaseDate: '2024-01-01',
          voteAverage: 7.5,
          overview: 'Overview for movie ${index + 1}',
          genres: ['Action', 'Drama'],
        ),
      );
    }
    return List.generate(
      5,
      (index) => Movie(
        id: 100 + index,
        title: 'Movie ${100 + index}',
        posterPath: '/poster${100 + index}.jpg',
        backdropPath: '/backdrop${100 + index}.jpg',
        releaseDate: '2024-01-01',
        voteAverage: 7.8,
        overview: 'Overview for movie ${100 + index}',
        genres: ['Comedy'],
      ),
    );
  }

  @override
  Future<Movie> getMovieDetails(int id) async {
    return Movie(
      id: id,
      title: 'Movie $id',
      posterPath: '/poster$id.jpg',
      backdropPath: '/backdrop$id.jpg',
      releaseDate: '2024-01-01',
      voteAverage: 8.0,
      overview: 'Overview for movie $id',
      genres: ['Action'],
    );
  }

  @override
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    return [
      Movie(
        id: 999,
        title: 'Search result',
        posterPath: '/poster999.jpg',
        releaseDate: '2024-01-01',
        voteAverage: 8.0,
        overview: 'Search result overview',
        genres: ['Drama'],
      ),
    ];
  }
}

void main() {
  group('MoviesNotifier', () {
    test('loads first page and paginates next page correctly', () async {
      final api = FakeTmdbApi();
      final notifier = MoviesNotifier(api);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.movies.length, 20);
      expect(notifier.state.page, 1);
      expect(notifier.state.hasMore, true);

      await notifier.loadNextPage();

      expect(notifier.state.isLoadingMore, false);
      expect(notifier.state.page, 2);
      expect(notifier.state.movies.length, 25);
      expect(notifier.state.hasMore, true);
    });
  });
}
