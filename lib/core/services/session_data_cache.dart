class SessionDataCache {
  final Map<String, Object?> _entries = <String, Object?>{};

  T? get<T>(String key) {
    final value = _entries[key];
    if (value is T) return value;
    return null;
  }

  void put<T>(String key, T value) {
    _entries[key] = value;
  }

  void remove(String key) {
    _entries.remove(key);
  }

  void clear() {
    _entries.clear();
  }
}
