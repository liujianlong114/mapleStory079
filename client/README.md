# MapleStory 079 Client

A Flutter implementation of MapleStory 079 game client.

## Features

- User authentication (login/register)
- Character selection
- Real-time multiplayer with WebSocket
- Player stats display
- Chat system

## Getting Started

### Prerequisites

- Flutter 3.44.0 or higher
- Dart 3.12.0 or higher

### Installation

1. Navigate to the client directory:
```bash
cd client
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Configuration

Update the server configuration in `lib/config/app_config.dart`:
```dart
static const String apiBaseUrl = 'http://your-server:8080/api/v1';
static const String wsUrl = 'ws://your-server:8080/ws';
```

## Project Structure

```
client/lib/
├── config/          # App configuration
├── models/         # Data models
├── pages/          # UI pages
├── providers/      # State management
├── widgets/        # Reusable widgets
└── main.dart       # App entry point
```

## Dependencies

- flutter
- http - Network requests
- web_socket_channel - WebSocket communication
- provider - State management
- shared_preferences - Local storage
- audioplayers - Audio playback
- flame - 2D game engine
