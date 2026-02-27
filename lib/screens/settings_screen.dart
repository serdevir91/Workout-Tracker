import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/settings_provider.dart';
import '../providers/workout_provider.dart';
import '../db/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  /// Request storage permissions based on Android version.
  Future<bool> _requestStoragePermission(BuildContext context) async {
    // Android 11+ (API 30+): MANAGE_EXTERNAL_STORAGE
    if (await Permission.manageExternalStorage.isGranted) return true;

    // Try regular storage first (Android < 11)
    var status = await Permission.storage.request();
    if (status.isGranted) return true;

    // Android 11+: request MANAGE_EXTERNAL_STORAGE
    status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;

    // Permission denied — show explanation
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Storage permission is required for backup. Please grant it in Settings.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFFF6B6B),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Open Settings',
            textColor: Colors.white,
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
    return false;
  }

  Future<void> _backupDatabase(BuildContext context) async {
    try {
      // Request storage permission first
      final hasPermission = await _requestStoragePermission(context);
      if (!hasPermission) return;

      final dbHelper = DatabaseHelper();
      final dbPath = await dbHelper.getDbPath();

      // Let user pick destination folder
      final selectedDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder to save backup',
      );

      if (selectedDir == null) {
        // User cancelled
        return;
      }

      // Add timestamp to backup filename
      final now = DateTime.now();
      final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final backupPath = '$selectedDir/workout_backup_$timestamp.db';
      final backupFile = File(backupPath);

      // Overwrite if exists
      if (await backupFile.exists()) {
        await backupFile.delete();
      }

      await File(dbPath).copy(backupPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved:\n$backupPath', style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF00D4AA),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFFF6B6B)),
        );
      }
    }
  }

  Future<void> _restoreDatabase(BuildContext context) async {
    try {
      // Let user pick the backup .db file
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select backup file to restore',
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) {
        // User cancelled
        return;
      }

      final backupFile = File(result.files.single.path!);

      if (!await backupFile.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected file not found.', style: TextStyle(color: Colors.white)),
              backgroundColor: Color(0xFFFF6B6B),
            ),
          );
        }
        return;
      }

      final dbHelper = DatabaseHelper();
      final dbPath = await dbHelper.getDbPath();

      // 1. Close DB to release file lock
      await dbHelper.closeAndReset();

      // 2. Delete existing DB
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      // 3. Copy selected backup to DB path
      await backupFile.copy(dbPath);

      if (context.mounted) {
        // 4. Reload data
        final provider = context.read<WorkoutProvider>();
        await provider.loadWorkouts();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restore successful! Data reloaded.', style: TextStyle(color: Colors.white)),
              backgroundColor: Color(0xFF00D4AA),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFFF6B6B)),
        );
      }
    }
  }


  void _showProfileEditDialog(BuildContext context, SettingsProvider provider) {
    final heightController = TextEditingController(text: (provider.height ?? 0) > 0 ? provider.height.toString() : '');
    final weightController = TextEditingController(text: (provider.weight ?? 0) > 0 ? provider.weight.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Height (cm)',
                labelStyle: const TextStyle(color: Color(0xFF6B6B8D)),
                filled: true,
                fillColor: const Color(0xFF111111),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Weight (${provider.unit})',
                labelStyle: const TextStyle(color: Color(0xFF6B6B8D)),
                filled: true,
                fillColor: const Color(0xFF111111),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final h = double.tryParse(heightController.text) ?? 0;
              final w = double.tryParse(weightController.text) ?? 0;
              provider.updateProfile(h, w);
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF00D4AA))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          const Text('Profile', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF0F0F12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF222222))),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1A1A2E),
                child: Icon(Icons.person, color: Color(0xFF6C63FF)),
              ),
              title: const Text('My Body Stats', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Height: ${(provider.height ?? 0) > 0 ? provider.height : '--'} cm\nWeight: ${(provider.weight ?? 0) > 0 ? provider.weight : '--'} ${provider.unit}',
                style: const TextStyle(color: Color(0xFFA0A0C0), height: 1.4),
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF00D4AA)),
                onPressed: () => _showProfileEditDialog(context, provider),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Preferences Section
          const Text('Preferences', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF0F0F12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF222222))),
            child: Column(
              children: [
                _buildDropdownTile(
                  icon: Icons.brightness_6,
                  title: 'Theme',
                  value: provider.themeMode.name,
                  items: const ['system', 'dark', 'light'],
                  onChanged: (val) => provider.updateTheme(val!),
                ),
                const Divider(color: Color(0xFF222222), height: 1),
                _buildDropdownTile(
                  icon: Icons.language,
                  title: 'Language',
                  value: provider.language,
                  items: const ['en', 'tr', 'es'],
                  onChanged: (val) => provider.updateLanguage(val!),
                ),
                const Divider(color: Color(0xFF222222), height: 1),
                _buildDropdownTile(
                  icon: Icons.fitness_center,
                  title: 'Weight Units',
                  value: provider.unit,
                  items: const ['kg', 'lbs'],
                  onChanged: (val) => provider.updateUnit(val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Advanced / Data Section
          const Text('Data Management', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF0F0F12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF222222))),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.save_alt, color: Color(0xFF00D4AA)),
                  title: const Text('Backup Database', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Save your data to Downloads folder', style: TextStyle(color: Color(0xFF6B6B8D), fontSize: 12)),
                  onTap: () => _backupDatabase(context),
                ),
                const Divider(color: Color(0xFF222222), height: 1),
                ListTile(
                  leading: const Icon(Icons.restore, color: Color(0xFFFF6B6B)),
                  title: const Text('Restore Database', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Load data from Downloads folder', style: TextStyle(color: Color(0xFF6B6B8D), fontSize: 12)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        title: const Text('Restore Backup', style: TextStyle(color: Colors.white)),
                        content: const Text('This will overwrite all current data with the backup. Are you sure?', style: TextStyle(color: Color(0xFFA0A0C0))),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _restoreDatabase(context);
                            },
                            child: const Text('Restore', style: TextStyle(color: Color(0xFFFF6B6B))),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({required IconData icon, required String title, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFA0A0C0)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: const Color(0xFF1A1A2E),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B6B8D)),
        underline: const SizedBox(),
        style: const TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.bold),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
