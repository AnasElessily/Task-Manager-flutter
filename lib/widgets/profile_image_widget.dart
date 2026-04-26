import 'dart:io';

import 'package:flutter/material.dart';

import '../utils/api_service.dart';

class ProfileImageWidget extends StatelessWidget {
  const ProfileImageWidget({
    super.key,
    required this.profileImagePath,
    required this.isEditMode,
    required this.onTap,
  });

  final String? profileImagePath;
  final bool isEditMode;
  final VoidCallback onTap;

  ImageProvider? _resolveImage() {
    if (profileImagePath == null) return null;
    if (profileImagePath!.startsWith('/uploads')) {
      return NetworkImage('${ApiService.rootUrl}$profileImagePath');
    }
    if (File(profileImagePath!).existsSync()) {
      return FileImage(File(profileImagePath!));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _resolveImage();

    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(Icons.person, size: 60, color: Colors.grey.shade400)
                  : null,
            ),
          ),
          if (isEditMode)
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: Theme.of(context).colorScheme.primary,
                shape: const CircleBorder(),
                elevation: 4,
                child: IconButton(
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  onPressed: onTap,
                  icon: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
