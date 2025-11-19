import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audoria/widgets/custom_text.dart';
import 'package:audoria/widgets/custom_bottom_navbar.dart';

class SettingChild extends StatefulWidget {
  final Map<String, String>? childData;

  const SettingChild({super.key, this.childData});

  @override
  State<SettingChild> createState() => _SettingChildState();
}

class _SettingChildState extends State<SettingChild> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  String voiceType = 'Female';
  double volume = 0.8;
  double speed = 1.0;

  final Map<String, String> voiceFiles = {'Female': '', 'Male': ''};

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showAccountDialog() {
    final data = widget.childData;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: CustomText.subtitle('Account')),
              const SizedBox(height: 15),
              Text('👤 Name: ${data?['name'] ?? 'Not set'}'),
              const SizedBox(height: 8),
              Text('🎂 Age: ${data?['age'] ?? 'Not set'}'),
              const SizedBox(height: 8),
              Text('📚 Grade: ${data?['grade'] ?? 'Not set'}'),
              const SizedBox(height: 8),
              Text('🏫 School: ${data?['school'] ?? 'Not set'}'),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // sound
  void _showAudioSettingsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setStateDialog) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: CustomText.body('Audio Settings')),
                  const SizedBox(height: 20),
                  const Text(
                    'Choose Voice',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  RadioListTile<String>(
                    title: const Text('Female'),
                    value: 'Female',
                    groupValue: voiceType,
                    onChanged: (value) {
                      setStateDialog(() => voiceType = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Male'),
                    value: 'Male',
                    groupValue: voiceType,
                    onChanged: (value) {
                      setStateDialog(() => voiceType = value!);
                    },
                  ),
                  const SizedBox(height: 10),
                  CustomText.body('Volume'),
                  Slider(
                    value: volume,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    label: '${(volume * 100).toInt()}%',
                    onChanged: (value) {
                      setStateDialog(() => volume = value);
                      _audioPlayer.setVolume(value);
                    },
                  ),
                  const SizedBox(height: 10),
                  CustomText.body('Speech Speed'),
                  Slider(
                    value: speed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: '${speed.toStringAsFixed(2)}x',
                    onChanged: (value) {
                      setStateDialog(() => speed = value);
                      _audioPlayer.setPlaybackRate(speed);
                    },
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9BB9FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: CustomText.body('Test Voice'),
                      onPressed: () async {
                        final file = voiceFiles[voiceType];
                        if (file != null && file.isNotEmpty) {
                          await _audioPlayer.stop();
                          await _audioPlayer.setVolume(volume);
                          await _audioPlayer.setPlaybackRate(speed);
                          await _audioPlayer.play(AssetSource(file));
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText.username('Settings'),
        backgroundColor: const Color(0xFF9BB9FF),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),
          CustomText.body('General'),
          const SizedBox(height: 10),

          // Account
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF9BB9FF)),
              title: CustomText.body('Account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: _showAccountDialog,
            ),
          ),
          const SizedBox(height: 10),

          // Audio Settings
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(
                Icons.settings_voice,
                color: Color(0xFF9BB9FF),
              ),
              title: CustomText.body('Audio Settings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: _showAudioSettingsDialog,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
