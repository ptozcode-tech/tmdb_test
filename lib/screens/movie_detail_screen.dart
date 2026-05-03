import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/providers.dart';
import '../models/movie.dart';

final movieProvider = FutureProvider.family<Movie, int>((ref, id) {
  final api = ref.watch(tmdbApiProvider);
  return api.getMovieDetails(id);
});

class MovieDetailScreen extends ConsumerWidget {
  final int movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieAsync = ref.watch(movieProvider(movieId));
    final favourites = ref.watch(favouritesProvider);
    final favouritesNotifier = ref.read(favouritesProvider.notifier);
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Movie Details'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: themeNotifier.toggleTheme,
            icon: Icon(
              themeMode == ThemeModeOption.light
                  ? Icons.light_mode
                  : themeMode == ThemeModeOption.dark
                      ? Icons.dark_mode
                      : Icons.brightness_auto,
              color: Colors.white,
            ),
            tooltip: themeMode == ThemeModeOption.light
                ? 'Switch to dark mode'
                : themeMode == ThemeModeOption.dark
                    ? 'Switch to system mode'
                    : 'Switch to light mode',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withAlpha((0.7 * 255).round()),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: movieAsync.when(
        data: (movie) {
          final isFavourite = favourites.any((item) => item.id == movie.id);
          return Stack(
            children: [
              // Backdrop image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: movie.backdropUrl ?? movie.posterUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Theme.of(context).colorScheme.surface),
                  errorWidget: (context, url, error) => Container(color: Theme.of(context).colorScheme.surface),
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Theme.of(context).colorScheme.surface.withAlpha((0.9 * 255).round()),
                        Theme.of(context).colorScheme.surface,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster with shadow
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha((0.3 * 255).round()),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Hero(
                            tag: 'poster-${movie.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: CachedNetworkImage(
                                imageUrl: movie.posterUrl,
                                height: 280,
                                width: 180,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 280,
                                  width: 180,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 280,
                                  width: 180,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.error,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).round()),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      Text(
                        movie.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Rating and year
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.8 * 255).round()),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                movie.releaseYear,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.star,
                                size: 18,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${movie.voteAverage}/10',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Genres
                      if (movie.genres.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: movie.genres.map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                genre,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),
                      // Overview section
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          movie.overview,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Favourite button
                      Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: FilledButton.icon(
                            key: ValueKey(isFavourite),
                            onPressed: () {
                              if (isFavourite) {
                                favouritesNotifier.removeFavourite(movie.id);
                              } else {
                                favouritesNotifier.addFavourite(movie);
                              }
                            },
                            icon: Icon(isFavourite ? Icons.favorite : Icons.favorite_border),
                            label: Text(isFavourite ? 'Remove from favourites' : 'Add to favourites'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(200, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
