# Lock-In — Focus Timer

macOS menu bar Pomodoro timer. SwiftUI + Swift Package Manager. Deployment target: macOS 14+.

## Build

```bash
./build.sh          # builds + assembles Focus.app
open Focus.app     # run locally
cp -r Focus.app /Applications/  # install
```

## Architecture

| File | Role |
|------|------|
| `LockInApp.swift` | App entry, menu bar extra, tab shell |
| `TimerManager.swift` | All timer logic, phase transitions, site blocking orchestration |
| `AppSettings.swift` | UserDefaults-backed settings (ObservableObject) |
| `SessionStore.swift` | JSON persistence at `~/Library/Application Support/LockIn/sessions.json` |
| `Models.swift` | `WorkSession`, `DailySummary` |
| `TimerView.swift` | Main timer UI: ring, controls, presets, adjustment buttons |
| `StatsView.swift` | 14-day chart, streak cards, lifetime stats |
| `SettingsView.swift` | Settings sliders/toggles |
| `SiteBlocker.swift` | `/etc/hosts` + pf firewall site blocking (requires sudo) |

## Key behaviours

- **Early end saves time**: hitting the stop button (⏹) mid-session saves the partial work session if ≥ 1 min elapsed.
- **In-session duration adjustment**: −10/−5/+5/+10 min buttons appear while a work session is active.
- **Quick presets**: 15/25/45/60 min preset chips appear when the timer is idle on a work phase.
- **Long-term stats**: `SessionStore.bestStreak` and `bestDayMinutes` surface in the Stats tab.
- **Menu bar icon**: `lock.fill` when idle; countdown text when active.

## Site blocking

Requires admin access. Sets up a helper script at `/usr/local/bin/focustimer-blocker` and a sudoers entry. Modifies `/etc/hosts` and macOS `pf` firewall. Cleanup runs on app quit and on next launch after a crash.

## Roadmap ideas

- Session labelling / task tagging (show in stats)
- Weekly goal setting (not just daily)
- Notification action to extend +5 min from the notification
- iCloud sync for session history
