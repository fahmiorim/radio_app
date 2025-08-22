import 'package:flutter/material.dart';
import '../.././models/event_model.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.judul)),
      // body: SingleChildScrollView(
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       Image.asset(event.gambar, fit: BoxFit.cover),
      //       Padding(
      //         padding: const EdgeInsets.all(16),
      //         child: Column(
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           children: [
      //             Text(
      //               event.judul,
      //               style: const TextStyle(
      //                 fontSize: 22,
      //                 fontWeight: FontWeight.bold,
      //               ),
      //             ),
      //             const SizedBox(height: 8),
      //             Text(
      //               "${event.tanggal} | ${event.waktu}",
      //               style: const TextStyle(color: Colors.grey),
      //             ),
      //             const SizedBox(height: 16),
      //             Text(
      //               event.deskripsi,
      //               style: const TextStyle(fontSize: 16, height: 1.4),
      //             ),
      //           ],
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}
