import 'package:flutter/material.dart';
import '../utils/exercise_db.dart';

class ExerciseThumbnail extends StatefulWidget {
  final String exerciseName;
  final double size;
  
  const ExerciseThumbnail({super.key, required this.exerciseName, this.size = 50});

  @override
  State<ExerciseThumbnail> createState() => _ExerciseThumbnailState();
}

class _ExerciseThumbnailState extends State<ExerciseThumbnail> {
  static const int _maxCacheSize = 200;
  static final Map<String, String?> _imageCache = {};
  static final List<String> _cacheKeyOrder = [];
  String? _imageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant ExerciseThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseName != widget.exerciseName) {
      _isLoading = true;
      _imageUrl = null;
      _loadImage();
    }
  }

  static void _addToCache(String key, String? value) {
    if (_imageCache.containsKey(key)) {
      _cacheKeyOrder.remove(key);
    } else if (_imageCache.length >= _maxCacheSize) {
      final evict = _cacheKeyOrder.removeAt(0);
      _imageCache.remove(evict);
    }
    _imageCache[key] = value;
    _cacheKeyOrder.add(key);
  }

  Future<void> _loadImage() async {
    final name = widget.exerciseName;
    if (_imageCache.containsKey(name)) {
      if (mounted) setState(() { _imageUrl = _imageCache[name]; _isLoading = false; });
      return;
    }

    final result = await ExerciseDB.findExercise(name);
    final img = result?['image_url'] as String?;
    _addToCache(name, img);
    
    if (mounted) {
      setState(() {
        _imageUrl = img;
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
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline, borderRadius: BorderRadius.circular(8)),
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.secondary))),
      );
    }

    if (_imageUrl == null || _imageUrl!.isEmpty) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline, borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.onSurfaceVariant, size: widget.size * 0.5),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        _imageUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        cacheWidth: (widget.size * MediaQuery.devicePixelRatioOf(context)).toInt(),
        errorBuilder: (context, error, stackTrace) => Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline, borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.broken_image, color: Theme.of(context).colorScheme.onSurfaceVariant, size: widget.size * 0.5),
        ),
      ),
    );
  }
}
