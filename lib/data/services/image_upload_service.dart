import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
class ImageUploadService {
  ImageUploadService({
    FirebaseStorage? storage,
  }) : _storage = storage ?? FirebaseStorage.instance;
  final FirebaseStorage _storage;
  Future<String> uploadProductImage({
    required File file,
    required String fileName,
  }) async {
    final ref = _storage.ref().child('products').child(fileName);
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }
}
