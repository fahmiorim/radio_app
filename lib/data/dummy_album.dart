import '../../models/video_model.dart';
import '../../models/album_model.dart';

List<VideoModel> videoGalleries = [
  VideoModel(
    title: 'Ini adalah judul video pertama',
    description: 'Ini adalah deskripsi video pertama',
    videoUrl: 'https://www.youtube.com/watch?v=lCFbx8CrvlU',
  ),
  VideoModel(
    title: 'Ini adalah judul video pertama',
    description: 'Ini adalah deskripsi video kedua',
    videoUrl: 'https://www.youtube.com/watch?v=xwn-O8IWlHI',
  ),
];

final List<AlbumModel> imageGalleries = [
  AlbumModel(
    title: 'Podcast bersama Kejaksaan Negeri Batu Bara Tema: Jaga Desa',
    coverUrl: 'assets/image9.jpg',
    photos: ['assets/image8.jpg', 'assets/image11.jpg'],
  ),
  AlbumModel(
    title: 'Festival Budaya',
    coverUrl: 'assets/image1.jpg',
    photos: ['assets/image2.jpg', 'assets/image3.jpg'],
  ),
  AlbumModel(
    title: 'Workshop Edukasi',
    coverUrl: 'assets/image4.jpg',
    photos: ['assets/image5.jpg', 'assets/image6.jpg'],
  ),
  AlbumModel(
    title: 'Kegiatan Mahasiswa',
    coverUrl: 'assets/image7.jpg',
    photos: ['assets/image8.jpg', 'assets/image9.jpg'],
  ),
];
