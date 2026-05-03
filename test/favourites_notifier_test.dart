import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tmdb_test/models/movie.dart';
import 'package:tmdb_test/providers/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists favourites and reloads them after notifier restart', () async {
    final notifier = FavouritesNotifier();
    await Future<void>.delayed(Duration.zero);

    await notifier.addFavourite(
      Movie(
        id: 42,
        title: 'Saved Movie',
        posterPath: '/poster.jpg',
        backdropPath: '/backdrop.jpg',
        releaseDate: '2024-01-01',
        voteAverage: 8.2,
        overview: 'Stored locally for restart coverage.',
        genres: const ['Action', 'Drama'],
      ),
    );

    final reloadedNotifier = FavouritesNotifier();
    await Future<void>.delayed(Duration.zero);

    expect(reloadedNotifier.state, hasLength(1));
    expect(reloadedNotifier.state.single.id, 42);
    expect(reloadedNotifier.state.single.title, 'Saved Movie');
    expect(reloadedNotifier.state.single.genres, ['Action', 'Drama']);
  });

  test('parses TMDB genre maps and locally stored genre strings', () {
    final movie = Movie.fromJson({
      'id': 7,
      'title': 'Genre Shapes',
      'poster_path': null,
      'backdrop_path': null,
      'release_date': '2024-01-01',
      'vote_average': 7,
      'overview': 'Covers both supported genre payload formats.',
      'genres': [
        {'id': 28, 'name': 'Action'},
        'Drama',
      ],
    });

    expect(movie.genres, ['Action', 'Drama']);
  });
}
