import 'package:flutter/material.dart';
import '../../../widgets/section_title.dart';
import '../../../data/dummy_program.dart';
import '../../../widgets/skeleton/program_skeleton.dart';
import '../../../config/app_routes.dart';

class ProgramList extends StatefulWidget {
  const ProgramList({super.key});

  @override
  State<ProgramList> createState() => _ProgramListState();
}

class _ProgramListState extends State<ProgramList>
    with AutomaticKeepAliveClientMixin {
  // ✅ ditambahin

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
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
                  itemCount: dummyProgram.length,
                  padding: const EdgeInsets.only(left: 16),
                  itemBuilder: (context, index) {
                    final program = dummyProgram[index];
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
                              child: Image.asset(
                                program.fotoAsset,
                                height: 225,
                                width: 160,
                                fit: BoxFit.cover,
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
                              program.namaPenyiar,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "${program.hari}, ${program.jam}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
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
