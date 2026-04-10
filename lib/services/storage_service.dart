import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<List<XFile>> pickMultipleImages() async {
    return await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
  }

  Future<XFile?> takePhoto() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
  }

  Future<String> uploadMenuItemImage(String itemName, XFile file) async {
    final fileName =
        '${itemName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('menu_items/$fileName');
    final snapshot = await ref.putFile(File(file.path));
    return await snapshot.ref.getDownloadURL();
  }

  Future<List<String>> uploadMultipleMenuItemImages(
      String itemName, List<XFile> files) async {
    final results = await Future.wait(
      files.map((f) => uploadMenuItemImage(itemName, f)),
    );
    return results;
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (_) {
      // Image may not exist, ignore
    }
  }
}
