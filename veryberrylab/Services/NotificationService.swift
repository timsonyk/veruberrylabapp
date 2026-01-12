import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Service

final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    private let client = APIClient.shared

    @Published var unreadCount: Int = 0
    @Published var notifications: [NotificationDTO] = []

    private init() {}

    // MARK: - Push Notifications Setup

    func requestPushPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            if let error = error {
                print("Push notification permission error: \(error)")
            }
        }
    }

    func registerDeviceToken(_ deviceToken: Data) async {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 Device token: \(tokenString)")

        do {
            let request = DeviceTokenRequest(token: tokenString, platform: "ios")
            let body = try JSONEncoder().encode(request)
            let _: EmptyResponse = try await client.request(
                ["notifications", "device-token"],
                method: "POST",
                body: body
            )
            print("✅ Device token registered")
        } catch {
            print("❌ Failed to register device token: \(error)")
        }
    }

    func unregisterDeviceToken(_ tokenString: String) async {
        do {
            let request = DeviceTokenRequest(token: tokenString, platform: "ios")
            let body = try JSONEncoder().encode(request)
            let _: EmptyResponse = try await client.request(
                ["notifications", "device-token"],
                method: "DELETE",
                body: body
            )
            print("✅ Device token unregistered")
        } catch {
            print("❌ Failed to unregister device token: \(error)")
        }
    }

    // MARK: - Notifications API

    func fetchNotifications() async throws -> [NotificationDTO] {
        let notifications: [NotificationDTO] = try await client.request(
            ["notifications"],
            method: "GET",
            body: nil
        )
        await MainActor.run {
            self.notifications = notifications
        }
        return notifications
    }

    func fetchUnreadCount() async throws -> Int {
        let response: UnreadCountResponse = try await client.request(
            ["notifications", "unread-count"],
            method: "GET",
            body: nil
        )
        await MainActor.run {
            self.unreadCount = response.count
        }
        return response.count
    }

    func markAsRead(ids: [Int]) async throws {
        struct MarkReadRequest: Codable {
            let notification_ids: [Int]
        }
        let body = try JSONEncoder().encode(MarkReadRequest(notification_ids: ids))
        let _: EmptyResponse = try await client.request(
            ["notifications", "mark-read"],
            method: "POST",
            body: body
        )
        await MainActor.run {
            // Update local state
            for i in notifications.indices {
                if ids.contains(notifications[i].id) {
                    // Since NotificationDTO is a struct, we need to recreate it
                    let old = notifications[i]
                    notifications[i] = NotificationDTO(
                        id: old.id,
                        title: old.title,
                        body: old.body,
                        notification_type: old.notification_type,
                        is_read: true,
                        created_at: old.created_at
                    )
                }
            }
            unreadCount = max(0, unreadCount - ids.count)
        }
    }

    func markAllAsRead() async throws {
        let _: EmptyResponse = try await client.request(
            ["notifications", "mark-all-read"],
            method: "POST",
            body: nil
        )
        await MainActor.run {
            notifications = notifications.map { notification in
                NotificationDTO(
                    id: notification.id,
                    title: notification.title,
                    body: notification.body,
                    notification_type: notification.notification_type,
                    is_read: true,
                    created_at: notification.created_at
                )
            }
            unreadCount = 0
        }
    }
}

// MARK: - Empty Response

private struct EmptyResponse: Codable {
    let status: String?
}
