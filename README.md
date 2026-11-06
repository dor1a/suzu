# suzu

Send macOS notifications with the sender's own icon, so a finished Claude Code
turn and a finished Codex turn look different at a glance.

```
suzu claude "Claude Code - done (~3m)" "the prompt you left running"
suzu codex  "Codex - done (~3m)"       "the prompt you left running"
```

## Why it is built this way

The left icon of a macOS notification is always the icon of the app bundle that
sent it. `osascript` therefore shows Script Editor, and terminal-notifier removed
`-sender` and `-appIcon` in 3.0.0, which leaves only an image on the right.

So suzu builds one small app per runtime. Both run the same binary and differ in
their bundle identifier, name and icon:

```
bin/suzu <claude|codex> ──┬──> Claude Code.app   com.phomelo.suzu.claude
                          └──> Codex.app         com.phomelo.suzu.codex
                                     │
                                     └── UNUserNotificationCenter
```

No logo lives in this repository. Icons are read from what is installed when
suzu is built:

| App | Icon source, first match wins |
| -- | -- |
| Claude Code | `/Applications/Claude.app` |
| Codex | `/Applications/Codex.app`, then the VS Code extension's vector logo placed on the macOS icon grid |

If neither exists the app still works and shows a blank icon. Install the missing
app and run `brew reinstall suzu` to pick its icon up.

## Install

```
brew install dor1a/tap/suzu
```

The formula builds from source, so it needs the Xcode Command Line Tools.

macOS asks for permission separately for each app, and the prompt goes away with
the process that raised it. Run this once and allow both:

```
suzu setup
```

## Exit codes

Scripts should fall back to another notifier on any non-zero code.

| Code | Meaning |
| -- | -- |
| 0 | Delivered |
| 64 | Wrong arguments |
| 75 | No answer to the permission prompt within 5 seconds |
| 77 | Turned off in System Settings |
| 1 | Anything else, including the first run while macOS asks for permission |

## Things to know

- Notification Center caches an app's icon by bundle identifier. After changing
  an icon you may keep seeing the old one until `usernoted` restarts or you log
  out.
- `brew uninstall suzu` removes the apps, but the two entries can stay in System
  Settings > Notifications for a while.

## License

[MIT](LICENSE)
