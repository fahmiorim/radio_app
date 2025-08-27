import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../config/api_client.dart';
import '../../config/app_routes.dart';
import '../../models/album_model.dart';

class AllAlbumsScreen extends StatefulWidget {
  const AllAlbumsScreen({super.key});

  @override
  State<AllAlbumsScreen> createState() => _AllAlbumsScreenState();
}

class _AllAlbumsScreenState extends State<AllAlbumsScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<AlbumModel> _albums = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAlbums();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreAlbums();
    }
  }

  final Dio _dio = ApiClient.dio;

  Future<void> _fetchAlbums() async {
    try {
      setState(() {
        if (_currentPage == 1) {
          _isLoading = true;
        } else {
          _isLoadingMore = true;
        }
        _hasError = false;
      });

      print('Fetching albums page $_currentPage');
      
      final response = await _dio.get(
        '/galeri/semua',
        queryParameters: {'page': _currentPage},
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        print('Parsed response data: $responseData');
        
        if (responseData['status'] == true) {
          final List<dynamic> albumsData = responseData['data'] ?? [];
          print('Found ${albumsData.length} albums');
          
          if (albumsData.isNotEmpty) {
            try {
              final pagination = responseData['pagination'] ?? {};
              final newAlbums = albumsData.map<AlbumModel>((album) {
                print('Processing album: ${album['name']}');
                print('Album data: $album');
                print('Photos data: ${album['photos']}');
                return AlbumModel.fromJson(album);
              }).toList();

              setState(() {
                _albums.addAll(newAlbums);
                _currentPage = (pagination['current_page'] ?? 0) + 1;
                _hasMore = (pagination['current_page'] ?? 0) < (pagination['last_page'] ?? 0);
                _isLoading = false;
                _isLoadingMore = false;
              });
            } catch (e) {
              print('Error processing albums: $e');
              throw Exception('Error processing album data: $e');
            }
          } else {
            setState(() {
              _isLoading = false;
              _isLoadingMore = false;
              _hasMore = false;
            });
          }
        } else {
          final errorMsg = responseData['message'] ?? 'Unknown error';
          print('API Error: $errorMsg');
          throw Exception('Failed to load albums: $errorMsg');
        }
      } else {
        throw Exception('Failed to load albums: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Gagal memuat album. Silakan coba lagi.';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreAlbums() async {
    if (_isLoadingMore || !_hasMore) return;
    await _fetchAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Semua Album'), centerTitle: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _albums.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError && _albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAlbums,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAlbums,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: _albums.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _albums.length) {
            return _buildLoadingIndicator();
          }

          final album = _albums[index];
          return _buildAlbumItem(album);
        },
      ),
    );
  }

  Widget _buildAlbumItem(AlbumModel album) {
    print('Building album item: ${album.name}');
    print('Album photosCount: ${album.photosCount} (type: ${album.photosCount.runtimeType})');
    
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.albumDetail,
          arguments: album.slug,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    album.coverImage,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 36),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${album.photosCount ?? 0} Foto',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
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
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return _isLoadingMore
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        : const SizedBox.shrink();
  }
}
