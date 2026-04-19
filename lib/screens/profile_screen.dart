import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../database/db_helper.dart';
import '../models/user.dart';
import '../utils/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _studentIdController;

  late User _currentUser;

  String? _gender;
  String? _level;
  String? _profileImagePath;
  bool _isSaving = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _initFormValues();
  }

  void _initFormValues() {
    _nameController = TextEditingController(text: _currentUser.fullName);
    _emailController = TextEditingController(text: _currentUser.email);
    _studentIdController = TextEditingController(text: _currentUser.studentId);
    _gender = _currentUser.gender;
    _level = _currentUser.level?.toString();
    _profileImagePath = _currentUser.profileImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_isEditMode) return;
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      final appDirectory = await getApplicationDocumentsDirectory();
      final imageDirectory = Directory(
        path.join(appDirectory.path, 'profile_images'),
      );

      if (!await imageDirectory.exists()) {
        await imageDirectory.create(recursive: true);
      }

      final extension = path.extension(pickedFile.path);
      final fileName =
          'user_${_currentUser.id}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final savedImage = await File(
        pickedFile.path,
      ).copy(path.join(imageDirectory.path, fileName));

      if (!mounted) return;

      setState(() {
        _profileImagePath = savedImage.path;
      });

      // Upload to remote
      await ApiService.uploadProfileImage(_currentUser.id!, savedImage);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not select image')),
      );
    }
  }

  Future<void> _showImageSourceSheet() async {
    if (!_isEditMode) return;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedUser = User(
        id: _currentUser.id,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        studentId: _studentIdController.text.trim(),
        gender: _gender,
        level: _level != null ? int.parse(_level!) : null,
        password: _currentUser.password,
        profileImage: _profileImagePath,
      );

      await DBHelper.updateUser(updatedUser);

      // Sync to remote
      await ApiService.updateProfile(updatedUser);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      setState(() {
        _currentUser = updatedUser;
        _isEditMode = false;
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      _initFormValues(); // Reset any unsaved changes
    });
  }

  Widget _buildProfileImage() {
    final hasImage =
        _profileImagePath != null && File(_profileImagePath!).existsSync();

    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
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
              backgroundImage: hasImage ? FileImage(File(_profileImagePath!)) : null,
              child: hasImage
                  ? null
                  : Icon(Icons.person, size: 60, color: Colors.grey.shade400),
            ),
          ),
          if (_isEditMode)
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
                  onPressed: _showImageSourceSheet,
                  icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewMode() {
    return Column(
      children: [
        _buildProfileImage(),
        const SizedBox(height: 16),
        Text(
          _currentUser.fullName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _currentUser.email,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.badge_outlined, color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Student ID', style: TextStyle(color: Colors.grey, fontSize: 13)),
                subtitle: Text(_currentUser.studentId, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              const Divider(height: 1, indent: 64),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.people_outline, color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Gender', style: TextStyle(color: Colors.grey, fontSize: 13)),
                subtitle: Text(_currentUser.gender ?? 'Not specified', style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              const Divider(height: 1, indent: 64),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.school_outlined, color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Academic Level', style: TextStyle(color: Colors.grey, fontSize: 13)),
                subtitle: Text(_currentUser.level != null ? 'Level ${_currentUser.level}' : 'Not specified', style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _isEditMode = true),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile', style: TextStyle(fontSize: 18)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildProfileImage(),
          const SizedBox(height: 32),
          
          TextFormField(
            controller: _nameController,
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
                    groupValue: _gender,
                    title: const Text('Male'),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    value: 'Female',
                    groupValue: _gender,
                    title: const Text('Female'),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'University Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Email is required';
              if (!RegExp(r'^\d+@stud\.fci-cu\.edu\.eg$').hasMatch(value.trim())) {
                return 'Invalid FCI email format';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _studentIdController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Student ID',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Student ID is required';
              final emailId = _emailController.text.trim().split('@').first;
              if (emailId != value.trim()) return 'Student ID must match email ID';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            initialValue: _level,
            decoration: const InputDecoration(
              labelText: 'Academic Level',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            items: const ['1', '2', '3', '4']
                .map((level) => DropdownMenuItem(value: level, child: Text("Level $level")))
                .toList(),
            onChanged: (value) => setState(() => _level = value),
          ),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _cancelEdit,
                    child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving 
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Profile' : 'My Profile'),
        actions: [
          if (!_isEditMode)
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _isEditMode ? _buildEditMode() : _buildViewMode(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
