class ItemTypeService {
  // Client-side mapping based on backend normalize_item_type function
  static const Map<String, String> _normalizationMap = {
    'car': 'car',
    'cars': 'car',
    'vehicle': 'car',
    'vehicles': 'car',
    'automobile': 'car',
    'auto': 'car',
    'cat': 'cat',
    'cats': 'cat',
    'feline': 'cat',
    'kitten': 'cat',
    'kittens': 'cat',
    'tree': 'tree',
    'trees': 'tree',
    'plant': 'tree',
    'plants': 'tree',
    'vegetation': 'tree',
    'dog': 'dog',
    'dogs': 'dog',
    'canine': 'dog',
    'puppy': 'dog',
    'puppies': 'dog',
    'building': 'building',
    'buildings': 'building',
    'structure': 'building',
    'structures': 'building',
    'house': 'building',
    'houses': 'building',
    'person': 'person',
    'people': 'person',
    'human': 'person',
    'humans': 'person',
    'individual': 'person',
    'individuals': 'person',
    'sky': 'sky',
    'heaven': 'sky',
    'atmosphere': 'sky',
    'ground': 'ground',
    'floor': 'ground',
    'surface': 'ground',
    'hardware': 'hardware',
    'equipment': 'hardware',
    'tool': 'hardware',
    'tools': 'hardware',
    'device': 'hardware',
    'devices': 'hardware',
    'bicycle': 'bicycle',
    'bike': 'bicycle',
    'bikes': 'bicycle',
    'cycle': 'bicycle',
    'cycles': 'bicycle',
    'chair': 'chair',
    'chairs': 'chair',
    'seat': 'chair',
    'seats': 'chair',
    'furniture': 'chair',
    'bus': 'bus',
    'buses': 'bus',
    'coach': 'bus',
    'coaches': 'bus',
    'truck': 'truck',
    'trucks': 'truck',
    'lorry': 'truck',
    'lorries': 'truck',
    'motorcycle': 'motorcycle',
    'motorbike': 'motorcycle',
    'scooter': 'motorcycle',
    'airplane': 'airplane',
    'plane': 'airplane',
    'aircraft': 'airplane',
    'jet': 'airplane',
    'boat': 'boat',
    'boats': 'boat',
    'ship': 'boat',
    'ships': 'boat',
    'vessel': 'boat',
    'vessels': 'boat',
  };

  static const List<String> _canonicalTypes = [
    'car', 'cat', 'tree', 'dog', 'building', 'person', 'sky', 'ground', 
    'hardware', 'bicycle', 'chair', 'bus', 'truck', 'motorcycle', 
    'airplane', 'boat'
  ];

  /// Normalize an item type to its canonical form
  static String? normalizeItemType(String? input) {
    if (input == null || input.isEmpty) return null;
    
    final normalized = input.toLowerCase().trim();
    return _normalizationMap[normalized];
  }

  /// Get suggestions for an input string
  static List<String> getSuggestions(String input) {
    if (input.isEmpty) return _canonicalTypes;
    
    final normalized = input.toLowerCase().trim();
    final suggestions = <String>[];
    
    // Exact matches first
    for (final canonical in _canonicalTypes) {
      if (canonical.startsWith(normalized)) {
        suggestions.add(canonical);
      }
    }
    
    // Partial matches
    for (final canonical in _canonicalTypes) {
      if (canonical.contains(normalized) && !suggestions.contains(canonical)) {
        suggestions.add(canonical);
      }
    }
    
    // Reverse lookup from normalization map
    for (final entry in _normalizationMap.entries) {
      if (entry.key.contains(normalized) && !suggestions.contains(entry.value)) {
        suggestions.add(entry.value);
      }
    }
    
    return suggestions.take(5).toList();
  }

  /// Get all canonical types
  static List<String> getAllCanonicalTypes() {
    return List.from(_canonicalTypes);
  }
}
