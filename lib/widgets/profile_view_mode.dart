import 'package:flutter/material.dart';

import '../models/user.dart';
import 'profile_image_widget.dart';

class ProfileViewMode extends StatelessWidget {
  const ProfileViewMode({
    super.key,
    required this.user,
    required this.onEdit,
  });

  final User user;
  final VoidCallback onEdit;

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(25),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileImageWidget(
          profileImagePath: user.profileImage,
          isEditMode: false,
          onTap: () {},
        ),
        const SizedBox(height: 16),
        Text(
          user.fullName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          user.email,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _infoTile(
                context,
                icon: Icons.badge_outlined,
                label: 'Student ID',
                value: user.studentId,
              ),
              const Divider(height: 1, indent: 64),
              _infoTile(
                context,
                icon: Icons.people_outline,
                label: 'Gender',
                value: user.gender ?? 'Not specified',
              ),
              const Divider(height: 1, indent: 64),
              _infoTile(
                context,
                icon: Icons.school_outlined,
                label: 'Academic Level',
                value: user.level != null
                    ? 'Level ${user.level}'
                    : 'Not specified',
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile', style: TextStyle(fontSize: 18)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
