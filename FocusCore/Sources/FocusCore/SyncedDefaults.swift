import Foundation

/// Settings that should sync across the user's devices use this instead of
/// `UserDefaults.standard`. It writes to BOTH UserDefaults (fast local read,
/// works offline) AND `NSUbiquitousKeyValueStore` (iCloud key-value store,
/// 1MB / 1024 keys, auto-syncs to all this-user's devices).
///
/// On launch we pull any newer iCloud values down to UserDefaults so the
/// app starts with the synced state. While running, external KVS changes
/// (from another device) fire `NSUbiquitousKeyValueStore.didChangeExternally`
/// — we mirror those into UserDefaults and post a Darwin notification so
/// observable settings classes can refresh.
public final class SyncedDefaults {
    public static let shared = SyncedDefaults()

    /// Posted when external iCloud changes have been mirrored into
    /// UserDefaults. Settings classes should observe this and re-read.
    public static let didImportRemoteChanges = Notification.Name("FocusCore.SyncedDefaults.didImportRemoteChanges")

    private let kvs = NSUbiquitousKeyValueStore.default
    private let defaults = UserDefaults.standard
    private var observer: NSObjectProtocol?

    /// Keys we want to sync. Anything not in this set stays device-local.
    public static let syncedKeys: Set<String> = [
        "workMinutes",
        "shortBreakMinutes",
        "longBreakMinutes",
        "sessionsBeforeLongBreak",
        "dailyGoalHours",
        "autoStartBreaks",
        "autoStartWork",
        "soundEnabled",
        "pauseGraceMinutes",
        "autoBreakEnabled",
        "tags",
        "quantGoal",
        "quantWeeklyGoal",
        "sweGoal",
        "sweWeeklyGoal",
        "problemSources",
        "interviewDate",
        "commitmentEnabled",
        "todayCommitment",
        "lastCommitmentDateEpoch",
    ]

    private init() {
        // Pull whatever iCloud has down to local defaults on launch.
        importRemote()

        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvs, queue: .main
        ) { [weak self] note in
            self?.handleExternalChange(note)
        }

        // Kick the KVS to fetch the latest snapshot.
        kvs.synchronize()
    }

    /// Call from any settings setter. Writes to both stores.
    public func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
        guard Self.syncedKeys.contains(key) else { return }
        if let value {
            kvs.set(value, forKey: key)
        } else {
            kvs.removeObject(forKey: key)
        }
    }

    /// Force a KVS push (most app lifecycle moments do this implicitly).
    public func synchronize() {
        kvs.synchronize()
    }

    private func importRemote() {
        for key in Self.syncedKeys {
            guard let remote = kvs.object(forKey: key) else { continue }
            // Always trust iCloud's view on launch — assumes it's at least as
            // recent. (KVS only fires didChangeExternally for *newer* values.)
            defaults.set(remote, forKey: key)
        }
    }

    private func handleExternalChange(_ note: Notification) {
        guard let changedKeys = note.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
        else { return }
        var imported = false
        for key in changedKeys where Self.syncedKeys.contains(key) {
            if let v = kvs.object(forKey: key) {
                defaults.set(v, forKey: key)
                imported = true
            }
        }
        if imported {
            NotificationCenter.default.post(name: Self.didImportRemoteChanges, object: nil)
        }
    }
}
