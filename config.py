"""
Configuration constants and utilities for AI Object Counting Application
"""

import re

# canonical allowed object types (lowercase singular)
OBJECT_TYPES = {
    "car", "truck", "bus", "person", "bicycle", "motorcycle", "motorbike", "van", "building",
    "tree", "dog", "cat", "sky", "ground", "hardware", "tank", "armored_vehicle", "armour", "armor",
    "equipment", "vehicle", "trailer", "tractor", "apc", "ifv"
}

# synonym map -> canonical
OBJECT_TYPE_SYNONYMS = {
    "tanks": "tank",
    "armoured": "armored_vehicle",
    "armoured_vehicle": "armored_vehicle",
    "armour": "armored_vehicle",
    "armored": "armored_vehicle",
    "armoured_truck": "armored_vehicle",
    "cars": "car",
    "bikes": "bicycle",
    "bicycles": "bicycle",
    "trucks": "truck",
    "vehicles": "vehicle",
    "equip": "equipment",
    "equipments": "equipment",
    "apcs": "apc",
    "ifvs": "ifv",
}

def normalize_item_type(raw: str) -> str:
    if not raw: 
        return None
    s = raw.strip().lower()
    s = re.sub(r'[^a-z0-9_ ]', '', s)
    s = s.replace('-', '_')
    s = s.rstrip('s')  # simple singularization (keeps 'bus' ok)
    # map synonyms
    mapped = OBJECT_TYPE_SYNONYMS.get(s, s)
    if mapped in OBJECT_TYPES:
        return mapped
    # fallback: if s directly in allowed list
    if s in OBJECT_TYPES:
        return s
    return None
