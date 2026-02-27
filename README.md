
<img width="1024" height="1024" alt="app_icon" src="https://github.com/user-attachments/assets/78a8586c-446b-4428-950a-e7084c01527e" />



# 🦸‍♂️ HeroDex 3000

> A stable cross-platform coordination system for a world rebuilding
> after invasion.

HeroDex 3000 is a Flutter application built with a strong focus on:

-   Stability
-   Clean architecture
-   Defensive programming
-   User consent & privacy

## Run the app

HeroDex 3000 runs on **mobile**, **tablet**, and **web**.

### 1) Install dependencies

```bash
flutter pub get
```

2) Provide your Superhero API key

Search uses the Superhero API. You need an API key (token).

We inject it at build time using Flutter’s recommended --dart-define:

```bash
flutter run --dart-define=SUPERHERO_TOKEN=YOUR_TOKEN
```

## Examples:  
Web
```bash
flutter run -d chrome --dart-define=SUPERHERO_TOKEN=YOUR_TOKEN
```

iOS simulator
```bash
flutter run -d "iPhone 16e" --dart-define=SUPERHERO_TOKEN=YOUR_TOKEN
```

------------------------------------------------------------------------

# 🧱 Architecture

The project follows Separation of Concerns:

lib/ ├── core/ → business logic (combat, utilities) ├── data/ → models,
API client, repositories ├── presentation → UI, Cubits, routing

State management: **Cubit (flutter_bloc)**\
Navigation: **go_router**\
Backend: **Firebase (Auth, Firestore, Crashlytics, Analytics)**

Business logic is isolated from UI and is fully testable.

------------------------------------------------------------------------

# 🔐 Onboarding & Privacy

On first launch, users must explicitly choose:

-   Analytics: Yes / No\
-   Crashlytics: Yes / No

If declined, those services are fully disabled at runtime.

Firebase initialization respects user consent immediately during app
startup.

------------------------------------------------------------------------

# 🔍 Search

-   Debounced API search\
-   Defensive parsing of API data\
-   Card UI with image fallback\
-   Save/remove heroes\
-   Detail view

The app never crashes on:

-   null values\
-   malformed API responses\
-   network failure

All API calls are wrapped in try/catch with controlled UI states.

------------------------------------------------------------------------

# 🏠 Home

Displays:

-   Number of saved characters\
-   Combined strength\
-   Dynamic war status

Values update reactively from local and remote data.

------------------------------------------------------------------------

# ⚔ Combat System

Each hero's **Attack** and **Defense** are calculated dynamically from
their powerstats using weighted formulas.

Before calculation, all stats are sanitized using:

``` dart
static int safeStat(dynamic v, {int max = 999})
```

This ensures:

-   null safety
-   invalid input protection
-   value clamping
-   consistent integer parsing
-   no crashes from malformed API data

------------------------------------------------------------------------

## 🗡 Attack Formula

Attack is calculated using:
```
Attack = (strength \* 0.35) + (power \* 0.30) + (combat \* 0.20) +
(speed \* 0.15)
```
------------------------------------------------------------------------

## 🛡 Defense Formula

Defense is calculated using:
```
Defense = (durability \* 0.40) + (intelligence \* 0.25) + (combat \*
0.20) + (speed \* 0.15)
```
------------------------------------------------------------------------

# 🧪 Testing

Unit tests included for:

-   normalizeAlign (alignment classification)
-   PowerStats.safeStat (defensive stat parsing)

Run tests with:

``` bash
flutter test
```

------------------------------------------------------------------------

# 🛡 Stability Strategy

Implemented through:

-   Defensive null checks
-   Safe stat parsing
-   Exception wrapping
-   Controlled async flows
-   Debounced API calls
-   Image fallback builders
-   Consent-aware Firebase initialization

------------------------------------------------------------------------

# 👨‍💻 Built by

\[JXRXN\]\
HFL25-2\
2026

------------------------------------------------------------------------

# 🌍 Final Statement

Even when the network fails.\
Even when data is malformed.\
Even when the world shakes.

HeroDex remains stable.
