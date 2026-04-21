# Protect Your Eyes 👀

A lightweight macOS menu-bar app that tracks consecutive screen-on time and
reminds you to look away every **10 minutes**.

## Features

| Feature | Detail |
|---|---|
| Menu-bar icon | Lives in the macOS status bar – no Dock icon |
| Live countdown | Shows `Active: MM:SS / 10:00` in the menu |
| Notification | Banner + sound after 10 consecutive minutes of screen activity |
| Accept resets timer | Clicking the notification (or its **OK, I'll look around! 👀** button) resets the countdown to 00:00 |
| Screen-off resets timer | Display sleep *and* Lock Screen both reset the countdown |
| Manual reset | **Reset Timer** menu item resets the countdown at any time |

## Requirements

* macOS 12 Monterey or later (tested on macOS 14 Sonoma / Apple Silicon)
* Xcode 15 or later **or** the Swift command-line tools (`xcode-select --install`)

## Build & Run

```bash
# Clone the repository
git clone https://github.com/jasmimi/protect-your-eyes.git
cd protect-your-eyes

# Build in release mode
swift build -c release

# Run (keep the terminal window open, or add it to Login Items)
.build/release/ProtectYourEyes
```

The first time you run the app, macOS will ask for permission to send
notifications.  Allow it so you receive the eye-break reminders.

### Run at Login (optional)

To have the app start automatically when you log in:

1. Open **System Settings → General → Login Items & Extensions**
2. Click **+** under *Open at Login* and select the built binary
   (`.build/release/ProtectYourEyes`)

## How it works

```
Screen active  ──► timer counts up (visible in menu bar)
                        │
                   10 minutes
                        │
                        ▼
              Notification sent ──► User taps "OK"
                                          │
                                    Timer resets to 00:00
                                    and starts again

Screen sleeps / locks ──► Timer resets to 00:00 immediately
```

## Project structure

```
Sources/ProtectYourEyes/
├── main.swift               # Entry point – configures NSApplication as accessory
├── AppDelegate.swift        # Menu-bar item, menus, notification permissions
└── EyeProtectionManager.swift  # Timer, screen-sleep/lock observers, UNUserNotification
```
