import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The user's profile photo, stored as a single fixed-name file in the
/// app's documents directory — whether it exists at all *is* the
/// "has a photo" state, so there's no separate preference key to keep
/// in sync with it.
class ProfilePhotoRepository {
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'profile_photo.jpg'));
  }

  Future<File?> getPhoto() async {
    final file = await _file();
    return await file.exists() ? file : null;
  }

  Future<void> setPhoto(File source) async {
    final dest = await _file();
    await source.copy(dest.path);
  }

  Future<void> clearPhoto() async {
    final file = await _file();
    if (await file.exists()) await file.delete();
  }
}
