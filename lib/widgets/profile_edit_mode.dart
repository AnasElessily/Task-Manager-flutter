import 'package:flutter/material.dart';

import 'profile_image_widget.dart';

class ProfileEditMode extends StatelessWidget {
  const ProfileEditMode({
    super.key,
    required this.profileImagePath,
    required this.nameController,
    required this.emailController,
    required this.studentIdController,
    required this.gender,
    required this.level,
    required this.isSaving,
    required this.onImageTap,
    required this.onGenderChanged,
    required this.onLevelChanged,
    required this.onSave,
    required this.onCancel,
    required this.formKey,
  });

  final String? profileImagePath;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController studentIdController;
  final String? gender;
  final String? level;
  final bool isSaving;
  final VoidCallback onImageTap;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String?> onLevelChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          ProfileImageWidget(
            profileImagePath: profileImagePath,
            isEditMode: true,
            onTap: onImageTap,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Full Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Gender',
              prefixIcon: Icon(Icons.people_outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    value: 'Male',
                    groupValue: gender,
                    title: const Text('Male'),
                    contentPadding: EdgeInsets.zero,
                    onChanged: onGenderChanged,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    value: 'Female',
                    groupValue: gender,
                    title: const Text('Female'),
                    contentPadding: EdgeInsets.zero,
                    onChanged: onGenderChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'University Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^\d+@stud\.fci-cu\.edu\.eg$')
                  .hasMatch(value.trim())) {
                return 'Invalid FCI email format';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: studentIdController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Student ID',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Student ID is required';
              }
              final emailId = emailController.text.trim().split('@').first;
              if (emailId != value.trim()) {
                return 'Student ID must match email ID';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: level,
            decoration: const InputDecoration(
              labelText: 'Academic Level',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            items: const ['1', '2', '3', '4']
                .map(
                  (l) => DropdownMenuItem(value: l, child: Text('Level $l')),
                )
                .toList(),
            onChanged: onLevelChanged,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: isSaving ? null : onCancel,
                    child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : onSave,
                    child: isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text('Save', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
