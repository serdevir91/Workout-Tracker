import 'package:flutter/material.dart';
import '../utils/exrx_url_matcher.dart';

class ExerciseThumbnail extends StatefulWidget {
  final String exerciseName;
  final double size;
  
  const ExerciseThumbnail({super.key, required this.exerciseName, this.size = 50});

  @override
  State<ExerciseThumbnail> createState() => _ExerciseThumbnailState();
}

class _ExerciseThumbnailState extends State<ExerciseThumbnail> {
  static const int _maxCacheSize = 200;
  static final Map<String, String?> _gifCache = {};
  static final List<String> _cacheKeyOrder = [];
  String? _gifUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGif();
  }

  @override
  void didUpdateWidget(covariant ExerciseThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseName != widget.exerciseName) {
      _isLoading = true;
      _gifUrl = null;
      _loadGif();
    }
  }

  static void _addToCache(String key, String? value) {
    if (_gifCache.containsKey(key)) {
      _cacheKeyOrder.remove(key);
    } else if (_gifCache.length >= _maxCacheSize) {
      final evict = _cacheKeyOrder.removeAt(0);
      _gifCache.remove(evict);
    }
    _gifCache[key] = value;
    _cacheKeyOrder.add(key);
  }

  Future<void> _loadGif() async {
    final name = widget.exerciseName;
    if (_gifCache.containsKey(name)) {
      if (mounted) setState(() { _gifUrl = _gifCache[name]; _isLoading = false; });
      return;
    }

    final result = await ExrxUrlMatcher.findExercise(name);
    final gif = result?['gif_url'];
    _addToCache(name, gif);
    
    if (mounted) {
      setState(() {
        _gifUrl = gif;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(8)),
        child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D4AA)))),
      );
    }

    if (_gifUrl == null || _gifUrl!.isEmpty) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.fitness_center, color: const Color(0xFF6B6B8D), size: widget.size * 0.5),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        _gifUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        cacheWidth: (widget.size * MediaQuery.devicePixelRatioOf(context)).toInt(),
        errorBuilder: (context, error, stackTrace) => Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.broken_image, color: const Color(0xFF6B6B8D), size: widget.size * 0.5),
        ),
      ),
    );
  }
}
