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
        const SectionTitle(title: "Penyiar"),
        const SizedBox(height: 8),
        isLoading
            ? const PenyiarSkeleton()
            : SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: penyiarList.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final penyiar = penyiarList[index];

                    return Container(
                      width: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          ClipOval(
                            child: Image.network(
                              penyiar.avatarUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, size: 80),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            penyiar.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}
