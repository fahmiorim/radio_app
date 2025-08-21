import 'package:flutter/material.dart';
import '../../../widgets/section_title.dart';
import '../../../data/dummy_penyiar.dart';
import '../../../widgets/skeleton/penyiar_skeleton.dart'; // import skeleton

class PenyiarList extends StatefulWidget {
  final bool? isLoading; // bisa dikontrol dari luar, optional

  const PenyiarList({super.key, this.isLoading});

  @override
  State<PenyiarList> createState() => _PenyiarListState();
}

class _PenyiarListState extends State<PenyiarList>
    with AutomaticKeepAliveClientMixin {
  late bool isLoading;

  @override
  bool get wantKeepAlive => true; // biar widget tetap hidup di memori

  @override
  void initState() {
    super.initState();
    if (widget.isLoading == null) {
      isLoading = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      });
    } else {
      isLoading = widget.isLoading!;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // WAJIB kalau pakai AutomaticKeepAliveClientMixin
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
                  shrinkWrap: true,
                  itemCount: dummyPenyiar.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final penyiar = dummyPenyiar[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              penyiar.fotoAsset,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              cacheWidth: 160,
                              cacheHeight: 160,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            penyiar.nama,
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
