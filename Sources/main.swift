// suzu: post one macOS notification from inside an app bundle.
// The left icon of a notification is always the sender's bundle icon, so each
// runtime gets its own bundle. Run through bin/suzu.
import Foundation
import UserNotifications

final class Delegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completion: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completion([.banner, .list])
    }
}

func fail(_ message: String, code: Int32) -> Never {
    FileHandle.standardError.write(Data("suzu: \(message)\n".utf8))
    exit(code)
}

let arguments = CommandLine.arguments
guard arguments.count >= 2, Bundle.main.bundleIdentifier != nil else {
    fail("run from inside an app bundle with <title> [message]", code: 64)
}

let delegate = Delegate()
let center = UNUserNotificationCenter.current()
center.delegate = delegate

center.requestAuthorization(options: [.alert]) { granted, error in
    if let error { fail("authorization failed: \(error.localizedDescription)", code: 1) }
    guard granted else { fail("notifications are off for this app in System Settings", code: 77) }
    let content = UNMutableNotificationContent()
    content.title = arguments[1]
    content.body = arguments.count > 2 ? arguments[2] : ""
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    center.add(request) { error in
        if let error { fail("delivery failed: \(error.localizedDescription)", code: 1) }
        // Give the notification service a moment before the sender goes away.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exit(0) }
    }
}

// Callers run this from hooks, so an unanswered permission prompt must not hold them up.
// `suzu setup` raises the wait, because the prompt goes away with this process.
let wait = Double(ProcessInfo.processInfo.environment["SUZU_WAIT"] ?? "") ?? 5
DispatchQueue.main.asyncAfter(deadline: .now() + wait) { fail("timed out waiting for permission", code: 75) }
dispatchMain()
