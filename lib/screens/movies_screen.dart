import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/providers.dart';
import '../models/movie.dart';
import 'movie_detail_screen.dart';

class MoviesScreen extends ConsumerStatefulWidget {
  const MoviesScreen({super.key});

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).state = query;
    });
  }

  void _onScroll() {
    if (_scrollController.position.atEdge && _scrollController.position.pixels != 0) {
      ref.read(moviesProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = ref.watch(moviesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchMoviesAsync = ref.watch(searchMoviesProvider);
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies'),
        elevation: 0,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search movies...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: searchQuery.isNotEmpty
          ? searchMoviesAsync.when(
              data: (movies) => _buildMovieList(movies, isSearch: true),
              loading: () => _buildLoadingShimmer(),
              error: (error, stack) => Center(child: Text('Error: $error')),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(moviesProvider.notifier).refresh(),
              child: moviesState.isLoading
                  ? _buildLoadingShimmer()
                  : moviesState.errorMessage != null
                      ? Center(child: Text(moviesState.errorMessage!))
                      : _buildMovieList(
                          moviesState.movies,
                          isLoadingMore: moviesState.isLoadingMore,
                        ),
            ),
    );
  }

  Widget _buildMovieList(List<Movie> movies, {bool isSearch = false, bool isLoadingMore = false}) {
    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              'No movies found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: movies.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == movies.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final movie = movies[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withAlpha((0.08 * 255).round()),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        MovieDetailScreen(movieId: movie.id),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Row(
                children: [
                  Hero(
                    tag: 'poster-${movie.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: movie.posterPath != null ? movie.posterUrl : '',
                        width: 120,
                        height: 180,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          highlightColor: Theme.of(context).colorScheme.surface,
                          child: Container(width: 120, height: 180, color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 120,
                          height: 180,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.movie_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).round()),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                movie.releaseYear,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${movie.voteAverage}/10',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            movie.overview,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.surface,
          highlightColor: Theme.of(context).colorScheme.onSurface.withAlpha((0.08 * 255).round()),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
