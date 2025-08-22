import 'package:flutter/material.dart';
import '../../models/program_model.dart';

class ProgramDetailScreen extends StatelessWidget {
  final Program program;
  const ProgramDetailScreen({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(program.namaProgram)),
      // body: Padding(
      //   padding: const EdgeInsets.all(16.0),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       ClipRRect(
      //         borderRadius: BorderRadius.circular(12),
      //         child: Image.asset(
      //           program.fotoAsset,
      //           width: double.infinity,
      //           height: 300,
      //           fit: BoxFit.cover,
      //         ),
      //       ),
      //       const SizedBox(height: 16),
      //       Text(
      //         program.namaProgram,
      //         style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      //       ),
      //       Text(
      //         "Penyiar: ${program.namaPenyiar}",
      //         style: const TextStyle(fontSize: 16),
      //       ),
      //       const SizedBox(height: 8),
      //       Text("Hari: ${program.hari}"),
      //       Text("Jam: ${program.jam}"),
      //     ],
      //   ),
      // ),
    );
  }
}
