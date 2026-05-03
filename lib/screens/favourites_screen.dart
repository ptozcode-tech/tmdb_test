import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/providers.dart';
import 'movie_detail_screen.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourites = ref.watch(favouritesProvider);
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favourites'),
        actions: [
          IconButton(
            onPressed: themeNotifier.toggleTheme,
            icon: Icon(
              themeMode == ThemeModeOption.light
                  ? Icons.light_mode
                  : themeMode == ThemeModeOption.dark
                      ? Icons.dark_mode
                      : Icons.brightness_auto,
            ),
            tooltip: themeMode == ThemeModeOption.light
                ? 'Switch to dark mode'
                : themeMode == ThemeModeOption.dark
                    ? 'Switch to system mode'
                    : 'Switch to light mode',
          ),
        ],
      ),
      body: favourites.isEmpty
          ? const Center(child: Text('No favourite movies yet'))
          : ListView.builder(
              itemCount: favourites.length,
              itemBuilder: (context, index) {
                final movie = favourites[index];
                return ListTile(
                  leading: movie.posterPath != null
                      ? CachedNetworkImage(
                          imageUrl: movie.posterUrl,
                          width: 50,
                          height: 75,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        )
                      : const Icon(Icons.movie, size: 50),
                  title: Text(movie.title),
                  subtitle: Text('${movie.releaseYear} • ${movie.voteAverage}/10'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      ref.read(favouritesProvider.notifier).removeFavourite(movie.id);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(movieId: movie.id),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}