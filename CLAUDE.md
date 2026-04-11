# CLAUDE.md

## Project Overview
PréviCA is an iOS/watchOS weather app that fetches data from Environment Canada.
It supports English and French via bilingual API responses.

### Variants
Variants are **build configurations of a single target**, not separate targets:

- **PréviCA** — App Store build (`Debug` / `Release` configurations). `BUNDLE_DISPLAY_NAME = "PréviCA"`.
- **PréviCA+** — Internal build (`DebugInternal` / `ReleaseInternal` configurations). `BUNDLE_DISPLAY_NAME = "PréviCA+"`. Passes `-DENABLE_PWS -DENABLE_PRECIPITATION` via `OTHER_SWIFT_FLAGS`, enabling Personal Weather Station data (`WeatherFramework/PWS/`) and the precipitation chart.

Code that is variant-specific is gated with `#if ENABLE_PWS` or `#if ENABLE_PRECIPITATION` — there is no `#if FREE` flag in this project.

## Tech Stack

- **Platforms**: iOS 16+ / watchOS 10+
- **Language**: Swift 6.2 (strict concurrency)
- **iOS UI**: **UIKit** with storyboards (`Main.storyboard`) and `UIViewController` subclasses. This is not a SwiftUI app on iOS.
- **watchOS UI**: SwiftUI (`WatchApp.swift`, `WeatherContentView.swift`, …)
- **Widgets**: SwiftUI + WidgetKit (`weatherlr Widget/`, `watch Widget/`)
- **Architecture**: Classic UIKit MVC on iOS; lightweight `ObservableObject` model (`WatchWeatherModel`) on watchOS
- **Minimum deployment**: iOS 16.0, watchOS 10.0

## Targets
There are six native targets in `weatherlr.xcodeproj`:

| Target            | Platform | Source directory       |
|-------------------|----------|------------------------|
| `weatherlr`       | iOS      | `weatherlr/`           |
| `watch`           | watchOS  | `watch Extension/` *(note: target name ≠ directory name; `watch/` only holds Info.plist, assets, and entitlements)* |
| `weatherlr Widget`| iOS      | `weatherlr Widget/`    |
| `watch Widget`    | watchOS  | `watch Widget/`        |
| `weatherlrTests`  | iOS      | `weatherlrTests/`      |
| `weatherlrUITests`| iOS      | `weatherlrUITests/`    |

Build configurations per target: `Debug`, `Release`, `DebugInternal`, `ReleaseInternal`.

## Data Flow
- **Primary source**: Environment Canada JSON API
  `https://api.weather.gc.ca/collections/citypageweather-realtime/items/{cityId}?f=json`
- **Pipeline**: URL → JSON `Data` → `JsonWeatherParser` → `WeatherInformation` / `AlertInformation` → `WeatherInformationWrapper` (cached via `ExpiringCache`) → UIKit view controllers
- **Optional sources (PréviCA+ only)**: `WeatherFramework/WeatherKit/WeatherKitService.swift` and `WeatherFramework/PWS/PWSService.swift`
- **Language**: user-selected (English/French), stored in `UserDefaults`. The JSON API returns bilingual data (en/fr fields) in a single response, so there is no second network call to switch language.

## Key Directories
- `weatherlr/` — iOS app source (view controllers, cells, storyboards)
- `weatherlr/WeatherFramework/Json/` — JSON API response models (`WeatherApiResponse.swift`) and parser (`JsonWeatherParser.swift`)
- `weatherlr/WeatherFramework/Rss/` — legacy RSS/XML parser (kept for offline debug mode only)
- `weatherlr/WeatherFramework/Weather/` — core models: `WeatherInformation`, `WeatherInformationWrapper`, `AlertInformation`, `WeatherEnums`
- `weatherlr/WeatherFramework/City/` — city model and helpers
- `weatherlr/WeatherFramework/WeatherKit/` — Apple WeatherKit integration (used for supplemental data in PréviCA+)
- `weatherlr/WeatherFramework/PWS/` — Personal Weather Station service (gated by `ENABLE_PWS`)
- `watch Extension/` — watchOS SwiftUI app source (builds into the `watch` target — note the space in the directory name)
- `weatherlr Widget/`, `watch Widget/` — WidgetKit extensions

## Important Patterns
- All weather condition strings (e.g., "Partly cloudy", "Dégagement") are mapped through `RssEntryToWeatherInformation.convertWeatherStatus()` — a 400+ case switch statement shared between the JSON parser and the legacy RSS parser.
- The JSON API duplicates forecasts: the array contains the same data twice (first half = second half). `JsonWeatherParser` uses only the first half.
- `currentConditions.condition` is optional in the API — it may be absent at night or when the station isn't reporting. The parser falls back to the first forecast's `abbreviatedForecast.textSummary`.
- `WeatherDay` enum (`WeatherFramework/Weather/WeatherEnums.swift`) uses raw `Int` values: `.now = -1`, `.today = 0`, `.tomorow = 1` *(sic — one `r`, do not "fix")*, `.day2 = 2`, … up to `.day20 = 20`.
- The day counter in forecast parsing increments on non-night entries (except `.today` night which also increments).
- When adding new files under `WeatherFramework/`, make sure they are added to every target that needs them (typically `weatherlr`, `watch`, `weatherlr Widget`, `watch Widget`) — there is no shared framework module.

## UI Notes
- **iOS is UIKit**: most screens are `UIViewController` subclasses (`WeatherViewController`, `SettingsViewController`, `AlertViewController`, …). Do not "migrate to SwiftUI" on iOS as a side effect of other work — that's a separate project.
- The bottom toolbar in `WeatherViewController` is dynamically rebuilt in `decorate()` to avoid empty liquid glass capsules on iOS 26. The warning button is only included when alerts are active.
- `decorate()` is called from `viewDidLayoutSubviews`, which can fire before outlets are connected — always guard against nil outlets.
- Radar URL is in localized strings (`radarUrl` key). Currently points to `weather.gc.ca/index_e.html` / `meteo.gc.ca/index_f.html`.
- The watch app is SwiftUI; `WatchWeatherModel` is an `ObservableObject` that the views observe.

## XcodeBuildMCP Integration
**IMPORTANT**: This project uses XcodeBuildMCP for all Xcode operations. Prefer MCP tools over raw `xcodebuild` in the shell.

Per-session flow:
1. Call `mcp__XcodeBuildMCP__session_show_defaults` once at the start of the session to verify project / scheme / simulator are set. Only fall back to `mcp__XcodeBuildMCP__discover_projs` if defaults are missing or wrong.
2. Common operations:
   - **Build & run on sim**: `mcp__XcodeBuildMCP__build_run_sim`
   - **Build only**: `mcp__XcodeBuildMCP__build_sim`
   - **Test**: `mcp__XcodeBuildMCP__test_sim`
   - **Clean**: `mcp__XcodeBuildMCP__clean` (before major rebuilds)
   - **Logs**: `mcp__XcodeBuildMCP__start_sim_log_cap` / `mcp__XcodeBuildMCP__stop_sim_log_cap`

## Build Notes
- No iPhone 16 simulator is available on this machine; use **iPhone 17 Pro** or later.
- `AppDelegateTests.swift:13` has a pre-existing Swift 6 concurrency issue that is unrelated to app functionality — do not block on it.
- To build the PréviCA+ variant, select the `DebugInternal` or `ReleaseInternal` build configuration (scheme setting); do not look for a separate "Free" or "+" target.

## Coding Standards

### Swift
- Swift 6.2 with strict concurrency — address new warnings, don't suppress them.
- `async/await` for all async operations (not completion handlers in new code).
- `guard` for early exits.
- Prefer value types (`struct`) over reference types (`class`) for pure data.
- Force-unwrap (`!`) only with a clear justification (storyboard outlets are the standard exception).
- Follow Apple's Swift API Design Guidelines.

### iOS (UIKit)
- View controllers own their own state; no heavyweight MVVM layer on the iOS side.
- Extract table view cell configuration into cell subclasses (see `WeatherTableViewCell`, `HourlyForecastCell`, …).
- When adding new screens, match the existing storyboard-based pattern unless there's a strong reason to go SwiftUI.

### watchOS / Widgets (SwiftUI)
- Use `@State` for local view state, `@ObservedObject` / `@EnvironmentObject` for shared models.
- Keep views small — extract when they exceed ~100 lines.
- `NavigationStack` over the deprecated `NavigationView`.

### Error handling
Typed errors with `LocalizedError`:

```swift
enum AppError: LocalizedError {
    case networkError(underlying: Error)
    case validationError(message: String)

    var errorDescription: String? {
        switch self {
        case .networkError(let error): return error.localizedDescription
        case .validationError(let msg): return msg
        }
    }
}
```

### Testing
- Unit tests for parsing, model, and helper code under `weatherlrTests/`.
- UI tests for critical user flows under `weatherlrUITests/`.
- Existing tests use XCTest; new tests may use Swift Testing (`@Test`, `#expect`) where it fits.
- Do not mock the network at the `URLSession` layer for parser tests — feed fixture JSON directly into `JsonWeatherParser`.

### Do not
- Introduce UIKit deprecation warnings (e.g. `UIApplication.shared.keyWindow`) — use scene-based APIs.
- Add force unwraps without justification.
- Ignore Swift 6 concurrency warnings.
- Add a `#if FREE` flag — the correct flags in this project are `ENABLE_PWS` and `ENABLE_PRECIPITATION`.
