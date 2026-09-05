import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_photo_repository.dart';

final profilePhotoRepositoryProvider = Provider<ProfilePhotoRepository>((ref) {
  return ProfilePhotoRepository();
});

/// The user's profile photo, or null if they haven't set one. Invalidated
/// by the profile-edit sheet after a change so Settings reflects it
/// without a full screen rebuild.
final profilePhotoProvider = FutureProvider<File?>((ref) {
  return ref.watch(profilePhotoRepositoryProvider).getPhoto();
});
