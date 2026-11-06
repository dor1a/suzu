<div align="center">

<img src="docs/logo.svg" alt="" width="96">

# suzu

**macOS notifications that show who sent them**

A finished Claude Code turn and a finished Codex turn each arrive with their own icon,<br>
so you can tell them apart without reading the banner.

[![macOS](https://img.shields.io/badge/macOS-only-000000?logo=apple&logoColor=white)](#install)
[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](Sources/main.swift)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

</div>

```sh
suzu claude "Claude Code - done (~3m)" "the prompt you left running"
suzu codex  "Codex - done (~3m)"       "the prompt you left running"
```

The name is 鈴, a small round bell.

## Why it exists

The icon on the left of a macOS notification always belongs to the app bundle
that sent it, and there is no option to change it per notification.

| Tool | What the notification shows |
| -- | -- |
| `osascript` | Script Editor's icon |
| terminal-notifier 3.x | Its own icon, plus an image on the right. `-sender` and `-appIcon` were removed in 3.0.0 |
| suzu | The icon of the runtime you named |

So suzu builds one small app per runtime. Both run the same binary and differ only
in their bundle identifier, name and icon.

## Install

```sh
brew install dor1a/tap/suzu
suzu setup
```

The formula builds from source, so it needs the Xcode Command Line Tools. Install
the apps you want icons from first, because the icons are read at build time.

`suzu setup` asks for notification permission. macOS asks separately for each
app, so allow both prompts. Each one waits up to two minutes.

## Usage

```
suzu <claude|codex> <title> [message]
suzu setup
```

Nothing else is needed for a one-off notification. To send one when an agent
finishes, call it from a Stop hook and fall back to `osascript`, so you still get
a notification on a Mac without suzu. Hooks may not have Homebrew on their `PATH`,
so use the full path. On an Intel Mac it is `/usr/local/bin/suzu`.

Claude Code, in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/opt/homebrew/bin/suzu claude 'Claude Code' 'Turn finished' || osascript -e 'display notification \"Turn finished\" with title \"Claude Code\"'"
          }
        ]
      }
    ]
  }
}
```

Codex, in `~/.codex/hooks.json`, has the same shape. Use `suzu codex` and your own
title in the command.

### Exit codes

Scripts should treat any non-zero code as "use another notifier".

| Code | Meaning |
| -- | -- |
| 0 | Delivered |
| 1 | Refused or failed. macOS can refuse the first request from a new app, which `suzu setup` retries |
| 64 | Wrong arguments |
| 75 | No answer to the permission prompt in time (5 seconds, or `SUZU_WAIT` seconds) |
| 77 | Turned off in System Settings |

## How it works

```
                          ┌──> Claude Code.app   com.phomelo.suzu.claude
suzu <claude|codex> ... ──┤                                                ──> UNUserNotificationCenter
                          └──> Codex.app         com.phomelo.suzu.codex
```

`bin/suzu` registers the chosen app with Launch Services and runs its binary. The
registration happens at run time because Homebrew's sandbox blocks it at install
time, and macOS refuses notifications from an app it has not registered.

No logo lives in this repository. `scripts/build.sh` reads icons from what is
installed on your Mac:

| App | Icon source, first match wins |
| -- | -- |
| Claude Code | `/Applications/Claude.app` |
| Codex | `/Applications/Codex.app`, then the logo in the Codex extension for VS Code, placed on the macOS icon grid |

If nothing matches, the app still works and shows a blank icon.

## Troubleshooting

### No prompt appears, or the notification never shows

Run `suzu setup` and keep it running until you have answered. The prompt goes away
when the process that raised it exits, and an ordinary `suzu` call waits only five
seconds. Then check that both apps are allowed in System Settings > Notifications.

### An icon is blank

The app it comes from was not installed when suzu was built. Install it, then:

```sh
brew reinstall suzu
```

### An icon looks old, or sits in a grey frame

Notification Center caches icons by bundle identifier, so it can keep showing an
earlier one after a rebuild. macOS frames an icon that does not fit its icon grid.

### Duplicate entries in System Settings

Each bundle identifier gets its own entry, and an entry can outlive its app. Reset
the ones you do not want from System Settings > Notifications, then run `suzu setup`
again if you removed one still in use.

## Uninstall

```sh
brew uninstall suzu
brew untap dor1a/tap
```

The two entries can stay in System Settings > Notifications until you reset them.

## Development

```sh
scripts/build.sh build
```

This builds both apps into `build/`. `bin/suzu` needs `@LIBEXEC@` replaced first,
which the formula does, so run an app's binary directly while developing. Register
it once, or macOS refuses the notification:

```sh
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f build/Codex.app
build/Codex.app/Contents/MacOS/suzu "Title" "Message"
```

## Not affiliated

suzu is a personal tool and is not affiliated with Anthropic or OpenAI. Their logos
are not distributed here. It only reuses icons from apps already on your Mac.

## License

[MIT](LICENSE)
