import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a profile picture to Firebase Storage.
  /// Path: profiles/{userId}/profile_pic.jpg
  Future<String?> uploadProfilePic(String userId, File file) async {
    try {
      final ref = _storage.ref().child('profiles').child(userId).child('profile_pic.jpg');
      
      // Setting metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId, 'uploadedAt': DateTime.now().toIso8601String()},
      );

      final uploadTask = await ref.putFile(file, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile pic: $e');
      return null;
    }
  }

  /// Deletes a file from Storage given its URL or path
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref(path).delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }
}
