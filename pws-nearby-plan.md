# Plan: Nearby PWS Stations from Weather Underground

## Context
Currently, adding a PWS requires manually typing a station ID in an alert dialog. The user wants to browse nearby stations fetched from Weather Underground, sorted by distance, and tap to add — on both iOS and watchOS.

## iOS Changes

### 1. Add `fetchNearbyStations` to PWSService
**File:** `weatherlr/WeatherFramework/PWS/PWSService.swift`

Add method using the WU nearby endpoint:
```
GET https://api.weather.com/v2/pws/observations/all?geocode={lat},{lon}&format=json&units=e&apiKey={key}&numStations=25
```
- Returns `[WUObservation]?` — same response shape as current single-station fetch (`WUResponse` with `observations` array)
- No new models needed — existing `WUResponse`/`WUObservation` in `PWSObservation.swift` already have all fields
- If the endpoint URL is wrong, we'll test and adjust during implementation

### 2. Create NearbyStationsViewController (new file, iOS)
**New file:** `weatherlr/NearbyStationsViewController.swift`
**Target membership:** weatherlr (iOS only)

A `UITableViewController` that:
- Takes city lat/lon in its initializer
- On load, calls `PWSService.shared.fetchNearbyStations()`
- Shows activity indicator while loading
- Sorts results by distance using `CLLocation.distance(from:)`
- Each row shows: station name, station ID, distance in km, current temperature
- Already-saved stations show a checkmark and are not re-selectable
- Tapping a station saves it via `PreferenceHelper.savePWSStations()`
- Empty state shows "No nearby stations found" label
- Cancel button dismisses

### 3. Update SettingsViewController
**File:** `weatherlr/SettingsViewController.swift`

- Replace `showAddStationAlert()` with `showNearbyStations()` that presents `NearbyStationsViewController` in a nav controller
- Use `PreferenceHelper.getCityToUse()` for coordinates
- Remove `showAddStationAlert()` and `validateAndAddStation()` methods

## watchOS Changes

### 4. Add `fetchNearbyStationsSync` helper (for watch)
**File:** `weatherlr/WeatherFramework/PWS/PWSService.swift`

Add a static synchronous method (like the existing widget PWS fetch pattern) using `URLSession` + semaphore, usable from watchOS without `@MainActor`:
```swift
static func fetchNearbyStationsSync(latitude: Double, longitude: Double) -> [WUObservation]
```

### 5. Create NearbyStationsController (new file, watchOS)
**New file:** `watch Extension/NearbyStationsController.swift`
**Target membership:** watch Extension

A `WKInterfaceController` (modeled on `SelectCityController`) that:
- Has outlets: `stationsTable` (WKInterfaceTable), `statusLabel` (WKInterfaceLabel), `cancelButton` (WKInterfaceButton)
- Receives city lat/lon via `awake(withContext:)`
- Fetches nearby stations on a background queue using `fetchNearbyStationsSync`
- Sorts by distance, populates `WKInterfaceTable` with a `StationRow` row type
- Each row shows: station name + distance (e.g., "My Station - 2.3 km")
- Already-saved stations get a "✓" prefix
- Tapping a non-saved station adds it and pops back

### 6. Create StationRowController (new file, watchOS)
**New file:** `watch Extension/StationRowController.swift`
**Target membership:** watch Extension

Simple row controller (like `CityRowController`):
```swift
class StationRowController: NSObject {
    @IBOutlet var stationLabel: WKInterfaceLabel!
}
```

### 7. Add storyboard scene for NearbyStations
**File:** `watch/Base.lproj/Interface.storyboard`

Add a new scene (modeled on the `SelectCity` scene):
- Controller identifier: `"NearbyStations"`
- Custom class: `NearbyStationsController`
- Contains: status label, WKInterfaceTable with `StationRow` row type, cancel button
- Connected outlets

### 8. Add menu item to InterfaceController
**File:** `watch Extension/InterfaceController.swift`

In `awake(withContext:)`, add a new menu item (guarded by `#if ENABLE_PWS`):
```swift
addMenuItem(with: .add, title: "Add Station".localized(), action: #selector(addStationSelected))
```
The action method pushes the `NearbyStations` controller with the current city's lat/lon as context.

## Shared Changes

### 9. Add localization strings
**Files:** `weatherlr/en.lproj/Localizable.strings`, `weatherlr/fr.lproj/Localizable.strings`

- "Nearby Stations" / "Stations à proximité"
- "No nearby stations found." / "Aucune station à proximité."
- "Add Station" / "Ajouter une station" (for watch menu item)

### 10. Add files to Xcode project
**File:** `weatherlr.xcodeproj/project.pbxproj`

- `NearbyStationsViewController.swift` → weatherlr target
- `NearbyStationsController.swift` → watch Extension target
- `StationRowController.swift` → watch Extension target

## Files summary
| File | Action |
|------|--------|
| `weatherlr/WeatherFramework/PWS/PWSService.swift` | Add `fetchNearbyStations` + sync variant |
| `weatherlr/NearbyStationsViewController.swift` | **New** — iOS nearby stations UI |
| `weatherlr/SettingsViewController.swift` | Replace alert with nearby stations screen |
| `watch Extension/NearbyStationsController.swift` | **New** — watchOS nearby stations UI |
| `watch Extension/StationRowController.swift` | **New** — watchOS row controller |
| `watch/Base.lproj/Interface.storyboard` | Add NearbyStations scene |
| `watch Extension/InterfaceController.swift` | Add "Add Station" menu item |
| `weatherlr/en.lproj/Localizable.strings` | New keys |
| `weatherlr/fr.lproj/Localizable.strings` | New keys |
| `weatherlr.xcodeproj/project.pbxproj` | Add 3 new files to targets |

## Existing code to reuse
- `PWSService` (`PWSService.swift`) — add methods to existing singleton
- `WUResponse` / `WUObservation` (`PWSObservation.swift`) — reuse for nearby response
- `PWSStation` (`PWSStation.swift`) — create from observation data
- `PreferenceHelper.getPWSStations()` / `savePWSStations()` — existing storage
- `PreferenceHelper.getCityToUse()` — get city with coordinates
- `SelectCityController` pattern — model for watchOS nearby stations controller
- `CityRowController` pattern — model for `StationRowController`

## Verification
1. Build iOS: `xcodebuild -scheme weatherlr -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
2. Build watch: `xcodebuild -scheme "PréviCA+ Watch" -configuration DebugInternal -destination 'id=B275633B-D8E1-40AA-B5D0-E0A3E2459A7A' build`
3. iOS: Settings → "Add Station" → verify nearby list → tap to add → verify in settings → swipe to delete
4. watchOS: Force-press menu → "Add Station" → verify nearby list → tap to add → verify PWS temp shows
