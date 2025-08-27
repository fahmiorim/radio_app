import 'package:flutter/material.dart';
import '../../../widgets/section_title.dart';
import '../../../widgets/skeleton/penyiar_skeleton.dart';
import '../../../models/penyiar_model.dart';
import '../../../services/penyiar_service.dart';

class PenyiarList extends StatefulWidget {
  const PenyiarList({super.key});

  @override
  State<PenyiarList> createState() => _PenyiarListState();
}

class _PenyiarListState extends State<PenyiarList>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = true;
  List<Penyiar> penyiarList = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await PenyiarService().fetchPenyiar();
      if (mounted) {
        setState(() {
          penyiarList = data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal ambil data penyiar: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: SectionTitle(title: "Penyiar"),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: isLoading
              ? const PenyiarSkeleton()
              : (penyiarList.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada data penyiar',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: penyiarList.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) {
                          final penyiar = penyiarList[index];
                          return Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 12),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // Full image
                                Container(
                                  width: 110,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    image: penyiar.avatarUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              penyiar.avatarUrl,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: penyiar.avatarUrl.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                                // Overlay nama
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 6,
                                  ),
                                  color: Colors.black.withOpacity(0.5),
                                  child: Text(
                                    penyiar.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )),
        ),
      ],
    );
  }
}
