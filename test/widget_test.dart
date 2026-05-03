import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmdb_test/main.dart';
import 'package:tmdb_test/models/movie.dart';
import 'package:tmdb_test/providers/providers.dart';
import 'package:tmdb_test/services/tmdb_api.dart';

class _FakeTmdbApi implements TmdbApiClient {
  @override
  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    return [
      Movie(
        id: 1,
        title: 'A Very Long Movie Title That Still Needs To Fit',
        releaseDate: '2024-01-01',
        voteAverage: 8.4,
        overview:
            'A long overview that exercises the movie card layout inside the '
            'scrollable list without relying on live image loading.',
        genres: const ['Drama'],
      ),
    ];
  }

  @override
  Future<Movie> getMovieDetails(int id) async {
    return Movie(
      id: id,
      title: 'Movie $id',
      releaseDate: '2024-01-01',
      voteAverage: 8.0,
      overview: 'Movie detail overview',
      genres: const ['Drama'],
    );
  }

  @override
  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    return const [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('movies list lays out loaded cards without paint exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tmdbApiProvider.overrideWithValue(_FakeTmdbApi())],
        child: const MyApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('A Very Long Movie Title That Still Needs To Fit'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
