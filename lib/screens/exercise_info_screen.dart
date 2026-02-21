import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A screen that shows the exercise GIF animation inline
/// with an option to open full ExRx.net page in browser.
class ExerciseInfoScreen extends StatelessWidget {
  final String exerciseName;
  final String exrxUrl;
  final String gifUrl;

  const ExerciseInfoScreen({
    super.key,
    required this.exerciseName,
    required this.exrxUrl,
    this.gifUrl = '',
  });

  Future<void> _launchUrl() async {
    final uri = Uri.parse(exrxUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasGif = gifUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: Text(
          exerciseName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // GIF Animation container
              if (hasGif)
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111122),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2D2D5E),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      gifUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          height: 300,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: const Color(0xFF6C63FF),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Loading animation...',
                                  style: TextStyle(
                                    color: Color(0xFF8888AA),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.broken_image, color: Color(0xFF8888AA), size: 48),
                                const SizedBox(height: 8),
                                const Text(
                                  'Could not load animation',
                                  style: TextStyle(color: Color(0xFF8888AA)),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _launchUrl,
                                  child: const Text('View on ExRx.net'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              if (!hasGif)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D2D5E)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.videocam_off,
                        size: 56,
                        color: Color(0xFF8888AA),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No animation available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8888AA),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'You can view the exercise on ExRx.net',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666688),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Exercise name
              Text(
                exerciseName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // Open full page button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _launchUrl,
                  icon: const Icon(Icons.open_in_new, size: 20),
                  label: const Text(
                    'Full Details on ExRx.net',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'Source: ExRx.net',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
