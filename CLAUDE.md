# CLAUDE.md

## Project Overview
weatherlr is an iOS/watchOS weather app that fetches data from Environment Canada. It supports English and French via bilingual API responses.

## Architecture
- **Targets**: weatherlr (iOS), weatherlrFree (iOS with ads), watch Extension (watchOS), watchFree Extension (watchOS)
- **Data source**: Environment Canada JSON API at `https://api.weather.gc.ca/collections/citypageweather-realtime/items/{cityId}?f=json`
- **Data flow**: URL → JSON Data → `JsonWeatherParser` → `WeatherInformation` / `AlertInformation` → `WeatherInformationWrapper` (cached via `ExpiringCache`) → UI
- **Language**: User-selected (English/French), stored in UserDefaults. The JSON API returns bilingual data (en/fr fields) in a single response.

## Key Directories
- `weatherlr/WeatherFramework/Json/` — JSON API response models (`WeatherApiResponse.swift`) and parser (`JsonWeatherParser.swift`)
- `weatherlr/WeatherFramework/Rss/` — Legacy RSS/XML parser (kept for offline debug mode only)
- `weatherlr/WeatherFramework/Weather/` — Core models: `WeatherInformation`, `WeatherInformationWrapper`, `AlertInformation`, `WeatherEnums`
- `weatherlr/WeatherFramework/City/` — City model and helpers
- `watch Extension/` — watchOS extension (note the space in directory name)

## Important Patterns
- All weather condition strings (e.g., "Partly cloudy", "Dégagement") are mapped through `RssEntryToWeatherInformation.convertWeatherStatus()` — a 400+ case switch statement. This is shared between the JSON parser and the legacy RSS parser.
- The JSON API duplicates forecasts: the array contains the same data twice (first half = second half). `JsonWeatherParser` uses only the first half.
- `currentConditions.condition` is optional in the API — it may be absent at night or when the station isn't reporting. The parser falls back to the first forecast's `abbreviatedForecast.textSummary`.
- `WeatherDay` enum uses raw Int values: `.now = -1`, `.today = 0`, `.tomorow = 1`, `.day2 = 2`, etc.
- The day counter in forecast parsing increments on non-night entries (except `.today` night which also increments).

## Build Notes
- No iPhone 16 simulator available; use iPhone 17 Pro or later
- Pre-existing Swift 6 concurrency issue in `AppDelegateTests.swift:13` — unrelated to app functionality
- When adding new WeatherFramework files, they must be added to all 4 targets (weatherlr, weatherlrFree, watch Extension, watchFree Extension)
- `#if FREE` conditional compilation is used for ad-related code (Google AdMob)

## UI Notes
- The bottom toolbar in `WeatherViewController` is dynamically rebuilt in `decorate()` to avoid empty liquid glass capsules on iOS 26. The warning button is only included when alerts are active.
- `decorate()` is called from `viewDidLayoutSubviews` which can fire before outlets are connected — always guard against nil outlets.
- Radar URL is in localized strings (`radarUrl` key). Currently points to `weather.gc.ca/index_e.html` / `meteo.gc.ca/index_f.html`.

## Testing
```bash
# Build
xcodebuild -scheme weatherlr -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run tests (note: AppDelegateTests has a pre-existing failure)
xcodebuild test -scheme weatherlr -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing weatherlrTests
```
