# Shape.log

Shape.log is a Flutter application designed to track workouts and monitor physical progress.

## MVP Features

- **Workout Tracking**: Log workout sessions with exercises, sets, reps, and weights.
- **Progress Visualization**: View workout history and progress over time.
- **Clean Architecture**: Built using a scalable architecture separating Domain, Data, and Presentation layers.
- **State Management**: Powered by [Riverpod](https://riverpod.dev/).

## structure

The project follows a feature-first Clean Architecture:

```
lib/
├── core/           # Core utilities, theme, router, error handling
├── features/       # Feature modules (e.g., workout, dashboard)
│   └── workout/    # Workout feature
│       ├── data/           # Models, DataSources, Repositories Impl
│       ├── domain/         # Entities, Repositories Interface
│       └── presentation/   # Providers, UI Pages
└── main.dart       # App entry point
```

## Getting Started

1.  **Prerequisites**: Ensure you have Flutter installed.
2.  **Dependencies**: Run `flutter pub get` to install dependencies.
3.  **Run**: Execute `flutter run` to start the app.

## Testing

Run unit and widget tests:

```bash
flutter test
```
