import 'package:flutter/material.dart';
import '../../../widgets/section_title.dart';
import '../../../widgets/skeleton/program_skeleton.dart';
import '../../../config/app_routes.dart';
import '../../../models/program_model.dart';
import '../../../services/program_service.dart';

class ProgramList extends StatefulWidget {
  const ProgramList({super.key});

  @override
  State<ProgramList> createState() => _ProgramListState();
}

class _ProgramListState extends State<ProgramList>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = true;
  List<Program> programList = [];
  final programService = ProgramService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await programService.fetchProgram();
      if (mounted) {
        setState(() {
          programList = data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal ambil data program: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ WAJIB kalau pakai AutomaticKeepAlive
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: "Program"),
        const SizedBox(height: 8),
        isLoading
            ? const ProgramSkeleton()
            : SizedBox(
                height: 300,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: programList.length,
                  padding: const EdgeInsets.only(left: 16),
                  itemBuilder: (context, index) {
                    final program = programList[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.programDetail,
                          arguments: program,
                        );
                      },
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Image.network(
                                program.gambarUrl,
                                height: 225,
                                width: 160,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      height: 225,
                                      width: 160,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image, size: 50),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              program.namaProgram,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              program.penyiarName ?? "-",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            // sementara belum ada jadwal di response
                            // const Text(
                            //   "Jadwal belum tersedia",
                            //   style: TextStyle(
                            //     fontSize: 12,
                            //     color: Colors.grey,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true; // ✅ biar state tetap hidup
}
