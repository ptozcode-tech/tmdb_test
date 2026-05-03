class Movie {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String releaseDate;
  final double voteAverage;
  final String overview;
  final List<String> genres;

  Movie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    required this.overview,
    required this.genres,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      releaseDate: json['release_date'],
      voteAverage: json['vote_average']?.toDouble() ?? 0.0,
      overview: json['overview'],
      genres: (json['genres'] as List<dynamic>?)?.map((g) => g['name'] as String).toList() ?? [],
    );
  }

  String get posterUrl => posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  String? get backdropUrl => backdropPath != null ? 'https://image.tmdb.org/t/p/w780$backdropPath' : null;

  String get releaseYear => releaseDate.isNotEmpty ? releaseDate.substring(0, 4) : '';
}