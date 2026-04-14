import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth_service.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  /// Upload foto profil ke Firebase Storage dan kembalikan URL download-nya.
  /// Path di Storage: profile_photos/{uid}/profile.jpg
  static Future<String?> uploadProfilePhoto(String localFilePath) async {
    if (!AuthService.isLoggedIn) return null;

    try {
      final uid = AuthService.uid;
      final file = File(localFilePath);
      if (!file.existsSync()) {
        print('[StorageService] File tidak ditemukan: $localFilePath');
        return null;
      }

      // Referensi ke path di Firebase Storage
      final ref = _storage.ref().child('profile_photos/$uid/profile.jpg');

      print('[StorageService] Mengupload foto profil ke Firebase Storage...');

      // Upload file dengan metadata
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Ambil URL download setelah upload selesai
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('[StorageService] Upload selesai. URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('[StorageService] ERROR upload: $e');
      return null;
    }
  }

  /// Hapus foto profil lama dari Firebase Storage (opsional, untuk cleanup).
  static Future<void> deleteProfilePhoto() async {
    if (!AuthService.isLoggedIn) return;
    try {
      final uid = AuthService.uid;
      final ref = _storage.ref().child('profile_photos/$uid/profile.jpg');
      await ref.delete();
    } catch (e) {
      // Abaikan jika file tidak ada
    }
  }
}
