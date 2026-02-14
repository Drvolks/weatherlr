#!/usr/bin/env python3
"""
Regenerates Cities.plist from the Environment Canada API.

Usage:
    python3 ci_scripts/update_cities.py

- Fetches all ~844 cities from the EC GeoMet OGC API
- Carries over radarId from the existing Cities.plist for known cities
- For new cities, scrapes the EC weather page to find radarId
- Outputs the updated Cities.plist in the app bundle
"""

import json
import os
import plistlib
import re
import subprocess
import sys
import tempfile
import urllib.request
import urllib.error
import time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
PLIST_PATH = os.path.join(PROJECT_DIR, "weatherlr", "Cities.plist")

API_BASE = "https://api.weather.gc.ca/collections/citypageweather-realtime/items"
RADAR_URL = "https://meteo.gc.ca/city/pages/{}_metric_f.html"
RADAR_PATTERN = re.compile(r'"/radar/index_f\.html\?id=(.*?)"')

PAGE_LIMIT = 200


def load_existing_cities():
    """Load the current Cities.plist and return a dict keyed by city ID."""
    if not os.path.exists(PLIST_PATH):
        print(f"No existing plist at {PLIST_PATH}")
        return {}

    with open(PLIST_PATH, "rb") as f:
        raw = plistlib.load(f)

    # Standard Codable format: list of dicts
    if isinstance(raw, list):
        existing = {}
        for city in raw:
            if isinstance(city, dict):
                cid = city.get("id", "")
                if cid:
                    existing[cid] = city
        return existing

    # NSKeyedArchiver format: dict with $archiver key
    if isinstance(raw, dict) and raw.get("$archiver") == "NSKeyedArchiver":
        print("  Detected legacy NSKeyedArchiver format, decoding with Swift...")
        return _decode_nskeyedarchiver()

    print(f"  Unknown plist format: {type(raw)}")
    return {}


def _decode_nskeyedarchiver():
    """Use Swift to decode the NSKeyedArchiver-format Cities.plist."""
    swift_code = r'''
import Foundation

class LegacyCity: NSObject, NSCoding {
    var id = ""
    var frenchName = ""
    var englishName = ""
    var province = ""
    var radarId = ""
    var latitude = ""
    var longitude = ""

    override init() { super.init() }
    func encode(with aCoder: NSCoder) {}

    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
        self.frenchName = aDecoder.decodeObject(forKey: "frenchName") as? String ?? ""
        self.englishName = aDecoder.decodeObject(forKey: "englishName") as? String ?? ""
        self.province = aDecoder.decodeObject(forKey: "province") as? String ?? ""
        self.id = aDecoder.decodeObject(forKey: "id") as? String ?? ""
        self.radarId = aDecoder.decodeObject(forKey: "radar") as? String ?? ""
        self.latitude = aDecoder.decodeObject(forKey: "latitude") as? String ?? ""
        self.longitude = aDecoder.decodeObject(forKey: "longitude") as? String ?? ""
    }
}

NSKeyedUnarchiver.setClass(LegacyCity.self, forClassName: "City")
NSKeyedUnarchiver.setClass(LegacyCity.self, forClassName: "weatherlr.City")
NSKeyedUnarchiver.setClass(LegacyCity.self, forClassName: "weatherlrFree.City")
NSKeyedUnarchiver.setClass(LegacyCity.self, forClassName: "WeatherFramework.City")

let path = CommandLine.arguments[1]
let data = try! Data(contentsOf: URL(fileURLWithPath: path))
let cities = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [LegacyCity]

var result: [[String: String]] = []
for city in cities {
    result.append([
        "id": city.id,
        "frenchName": city.frenchName,
        "englishName": city.englishName,
        "province": city.province,
        "radarId": city.radarId,
        "latitude": city.latitude,
        "longitude": city.longitude,
    ])
}

let jsonData = try! JSONSerialization.data(withJSONObject: result)
FileHandle.standardOutput.write(jsonData)
'''
    with tempfile.NamedTemporaryFile(suffix=".swift", mode="w", delete=False) as f:
        f.write(swift_code)
        swift_path = f.name

    try:
        result = subprocess.run(
            ["swift", swift_path, PLIST_PATH],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            print(f"    Swift decoder failed: {result.stderr.strip()}")
            return {}

        cities = json.loads(result.stdout)
        existing = {}
        for city in cities:
            cid = city.get("id", "")
            if cid:
                existing[cid] = city
        return existing
    except Exception as e:
        print(f"    Error decoding NSKeyedArchiver plist: {e}")
        return {}
    finally:
        os.unlink(swift_path)


def fetch_all_cities_from_api():
    """Fetch all cities from the EC API (paginated)."""
    all_features = []
    offset = 0

    while True:
        url = f"{API_BASE}?f=json&limit={PAGE_LIMIT}&offset={offset}"
        print(f"  Fetching offset={offset} ...", end=" ", flush=True)

        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = json.loads(resp.read())

        features = data.get("features", [])
        print(f"{len(features)} cities")
        all_features.extend(features)

        if len(features) < PAGE_LIMIT:
            break
        offset += PAGE_LIMIT

    print(f"  Total: {len(all_features)} cities from API")
    return all_features


def scrape_radar_id(city_id):
    """Scrape the EC weather page for a city to find its radar ID."""
    url = RADAR_URL.format(city_id)
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=15) as resp:
            html = resp.read().decode("utf-8", errors="replace")
        match = RADAR_PATTERN.search(html)
        if match:
            return match.group(1)
    except Exception as e:
        print(f"    Warning: could not scrape radar for {city_id}: {e}")
    return ""


def main():
    print("Loading existing Cities.plist...")
    existing = load_existing_cities()
    print(f"  {len(existing)} existing cities loaded")

    print("\nFetching cities from Environment Canada API...")
    features = fetch_all_cities_from_api()

    print("\nBuilding city list...")
    new_cities = []
    new_city_ids = []

    for feature in features:
        city_id = feature.get("id", "")
        if not city_id:
            continue

        props = feature.get("properties", {})
        coords = feature.get("geometry", {}).get("coordinates", [])

        name = props.get("name", {})
        english_name = name.get("en", "") or ""
        french_name = name.get("fr", "") or ""

        # Extract province from city ID (e.g., "on-143" -> "on")
        province = city_id.split("-")[0] if "-" in city_id else ""

        # Coordinates: [longitude, latitude, elevation]
        longitude = str(coords[0]) if len(coords) > 0 else ""
        latitude = str(coords[1]) if len(coords) > 1 else ""

        # Carry over radarId from existing plist
        if city_id in existing:
            radar_id = existing[city_id].get("radarId", "")
        else:
            radar_id = ""
            new_city_ids.append(city_id)

        city = {
            "id": city_id,
            "englishName": english_name,
            "frenchName": french_name,
            "province": province,
            "radarId": radar_id,
            "latitude": latitude,
            "longitude": longitude,
        }
        new_cities.append(city)

    # Report changes
    existing_ids = set(existing.keys())
    api_ids = set(c["id"] for c in new_cities)
    added = api_ids - existing_ids
    removed = existing_ids - api_ids

    if added:
        print(f"\n  New cities ({len(added)}):")
        for cid in sorted(added):
            city = next(c for c in new_cities if c["id"] == cid)
            print(f"    + {cid}: {city['englishName']}")

    if removed:
        print(f"\n  Removed cities ({len(removed)}):")
        for cid in sorted(removed):
            print(f"    - {cid}: {existing[cid].get('englishName', '?')}")

    # Scrape radar IDs for new cities
    if new_city_ids:
        print(f"\nScraping radar IDs for {len(new_city_ids)} new cities...")
        for i, city_id in enumerate(new_city_ids):
            print(f"  [{i+1}/{len(new_city_ids)}] {city_id} ...", end=" ", flush=True)
            radar_id = scrape_radar_id(city_id)
            print(f"radar={radar_id}" if radar_id else "no radar")
            for city in new_cities:
                if city["id"] == city_id:
                    city["radarId"] = radar_id
                    break
            time.sleep(0.5)

    # Sort by English name
    new_cities.sort(key=lambda c: c["englishName"].lower())

    # Save
    print(f"\nSaving {len(new_cities)} cities to {PLIST_PATH}...")
    with open(PLIST_PATH, "wb") as f:
        plistlib.dump(new_cities, f, fmt=plistlib.FMT_BINARY)

    print("Done!")

    # Summary
    print(f"\nSummary:")
    print(f"  Cities: {len(existing)} -> {len(new_cities)}")
    print(f"  Added: {len(added)}")
    print(f"  Removed: {len(removed)}")
    no_radar = sum(1 for c in new_cities if not c["radarId"])
    if no_radar:
        print(f"  Cities without radarId: {no_radar}")


if __name__ == "__main__":
    main()
