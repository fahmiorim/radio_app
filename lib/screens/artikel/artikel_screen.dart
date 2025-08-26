import 'package:flutter/material.dart';
import '../../widgets/skeleton/artikel_all_skeleton.dart';

class ArtikelScreen extends StatefulWidget {
  const ArtikelScreen({super.key});

  @override
  State<ArtikelScreen> createState() => _ArtikelScreenState();
}

class _ArtikelScreenState extends State<ArtikelScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Artikel"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const ArtikelAllSkeleton()
          : ListView.builder(
              padding: const EdgeInsets.only(
                bottom: 160,
                left: 16,
                right: 16,
                top: 16,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {},
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [SizedBox(width: 12)],
                        ),
                      ),
                      const Divider(
                        color: Color.fromARGB(255, 48, 48, 48),
                        height: 5,
                        thickness: 0.5,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
