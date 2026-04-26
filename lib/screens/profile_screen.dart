import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../database/db_helper.dart';
import '../models/user.dart';
import '../utils/api_service.dart';
import '../widgets/profile_edit_mode.dart';
import '../widgets/profile_view_mode.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

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
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
      );
      if (pickedFile == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory(path.join(appDir.path, 'profile_images'));
      if (!await imageDir.exists()) await imageDir.create(recursive: true);

      final ext = path.extension(pickedFile.path);
      final fileName =
          'user_${_currentUser.id}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final savedImage = await File(
        pickedFile.path,
      ).copy(path.join(imageDir.path, fileName));

      if (!mounted) return;
      setState(() => _profileImagePath = savedImage.path);

      final remoteUrl = await ApiService.uploadProfileImage(
        _currentUser.id!,
        savedImage,
      );

      if (remoteUrl != null) {
        if (!mounted) return;
        setState(() => _profileImagePath = remoteUrl);
        final updated = _currentUser.copyWith(profileImage: remoteUrl);
        await DBHelper.updateUser(updated);
        _currentUser = updated;
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not upload image')));
    }
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
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
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final updated = User(
        id: _currentUser.id,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        studentId: _studentIdController.text.trim(),
        gender: _gender,
        level: _level != null ? int.parse(_level!) : null,
        password: _currentUser.password,
        profileImage: _profileImagePath,
      );

      await DBHelper.updateUser(updated);
      await ApiService.updateProfile(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      setState(() {
        _currentUser = updated;
        _isEditMode = false;
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
      setState(() => _isSaving = false);
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      _initFormValues();
    });
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
                child: _isEditMode
                    ? ProfileEditMode(
                        formKey: _formKey,
                        profileImagePath: _profileImagePath,
                        nameController: _nameController,
                        emailController: _emailController,
                        studentIdController: _studentIdController,
                        gender: _gender,
                        level: _level,
                        isSaving: _isSaving,
                        onImageTap: _showImageSourceSheet,
                        onGenderChanged: (v) => setState(() => _gender = v),
                        onLevelChanged: (v) => setState(() => _level = v),
                        onSave: _saveProfile,
                        onCancel: _cancelEdit,
                      )
                    : ProfileViewMode(
                        user: _currentUser,
                        onEdit: () => setState(() => _isEditMode = true),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
