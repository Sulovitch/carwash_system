import 'dart:collection';

/// مدير الذاكرة المؤقتة للصور والبيانات
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // Cache للصور - نخزن آخر 50 صورة
  final _imageCache = LinkedHashMap<String, dynamic>();
  static const int _maxImageCacheSize = 50;

  // Cache للبيانات - نخزن آخر 20 استعلام
  final _dataCache = LinkedHashMap<String, CacheEntry>();
  static const int _maxDataCacheSize = 20;
  static const Duration _defaultCacheDuration = Duration(minutes: 5);

  /// حفظ صورة في الكاش
  void cacheImage(String url, dynamic image) {
    if (_imageCache.length >= _maxImageCacheSize) {
      _imageCache.remove(_imageCache.keys.first);
    }
    _imageCache[url] = image;
  }

  /// استرجاع صورة من الكاش
  dynamic getImage(String url) {
    return _imageCache[url];
  }

  /// حفظ بيانات في الكاش
  void cacheData(String key, dynamic data, {Duration? duration}) {
    if (_dataCache.length >= _maxDataCacheSize) {
      _dataCache.remove(_dataCache.keys.first);
    }
    _dataCache[key] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      duration: duration ?? _defaultCacheDuration,
    );
  }

  /// استرجاع بيانات من الكاش
  dynamic getData(String key) {
    final entry = _dataCache[key];
    if (entry == null) return null;

    // تحقق من صلاحية البيانات
    if (DateTime.now().difference(entry.timestamp) > entry.duration) {
      _dataCache.remove(key);
      return null;
    }

    return entry.data;
  }

  /// مسح الكاش بالكامل
  void clearCache() {
    _imageCache.clear();
    _dataCache.clear();
  }

  /// مسح كاش معين
  void clearDataCache(String key) {
    _dataCache.remove(key);
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration duration;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.duration,
  });
}
