import 'package:flutter/material.dart';
import '../../models/artikel_model.dart';
import '../../services/artikel_service.dart';
import '../../widgets/skeleton/artikel_all_skeleton.dart';
import 'artikel_detail_screen.dart';

class ArtikelScreen extends StatefulWidget {
  const ArtikelScreen({super.key});

  @override
  State<ArtikelScreen> createState() => _ArtikelScreenState();
}

class _ArtikelScreenState extends State<ArtikelScreen> {
  final ArtikelService _artikelService = ArtikelService();
  bool isLoading = true;
  String? errorMessage;
  List<Artikel> artikelList = [];
  int currentPage = 1;
  int lastPage = 1;
  bool hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchArtikel();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        hasMore) {
      _loadMoreArtikel();
    }
  }

  Future<void> _fetchArtikel() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await _artikelService.fetchAllArtikel(page: currentPage);
      
      if (!mounted) return;
      setState(() {
        artikelList = response['data'];
        currentPage = response['currentPage'];
        lastPage = response['lastPage'];
        hasMore = currentPage < lastPage;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Gagal memuat artikel. Silakan coba lagi.';
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreArtikel() async {
    if (_isLoadingMore || !hasMore || !mounted) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final nextPage = currentPage + 1;
      final response = await _artikelService.fetchAllArtikel(page: nextPage);

      if (!mounted) return;
      setState(() {
        artikelList.addAll(response['data']);
        currentPage = nextPage;
        lastPage = response['lastPage'];
        hasMore = currentPage < lastPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Artikel"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading && artikelList.isEmpty) {
      return const ArtikelAllSkeleton();
    }

    if (errorMessage != null && artikelList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchArtikel,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchArtikel,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          bottom: 80,
          left: 16,
          right: 16,
          top: 16,
        ),
        itemCount: artikelList.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= artikelList.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final artikel = artikelList[index];
          return _buildArtikelItem(artikel);
        },
      ),
    );
  }

  Widget _buildArtikelItem(Artikel artikel) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArtikelDetailScreen(artikel: artikel),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (artikel.image.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                artikel.image,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 180,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error_outline, color: Colors.red),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            artikel.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (artikel.excerpt.isNotEmpty)
            Text(
              artikel.excerpt,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (artikel.user.isNotEmpty)
                Text(
                  artikel.user,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(width: 8),
Text(
                artikel.formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          const Divider(
            color: Color.fromARGB(255, 48, 48, 48),
            height: 32,
            thickness: 0.5,
          ),
        ],
      ),
    );
  }

}
