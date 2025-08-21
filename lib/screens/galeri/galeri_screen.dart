import 'package:flutter/material.dart';
import '../galeri/widget/video_list.dart';
import '../galeri/widget/album_list.dart';

class GaleriScreen extends StatelessWidget {
  const GaleriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Galeri"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          bottom: 100,
          left: 16,
          right: 16,
          top: 16,
        ),
        children: const [VideoList(), SizedBox(height: 32), AlbumList()],
      ),
    );
  }
}
