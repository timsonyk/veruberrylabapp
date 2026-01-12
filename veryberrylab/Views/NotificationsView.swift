import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationService = NotificationService.shared

    @State private var notifications: [NotificationDTO] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Загрузка...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if notifications.isEmpty {
                    emptyView
                } else {
                    notificationsList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Уведомления")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") { dismiss() }
                }
                if !notifications.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Прочитать все") {
                            Task { await markAllRead() }
                        }
                        .font(.subheadline)
                    }
                }
            }
            .task {
                await loadNotifications()
            }
        }
    }

    // MARK: - Views

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("Нет уведомлений")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Здесь появятся уведомления о заказах, акциях и бонусах")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Повторить") {
                Task { await loadNotifications() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(notifications) { notification in
                    NotificationCard(notification: notification) {
                        Task {
                            await markAsRead(notification)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Actions

    private func loadNotifications() async {
        isLoading = true
        errorMessage = nil
        do {
            notifications = try await notificationService.fetchNotifications()
        } catch {
            errorMessage = "Не удалось загрузить уведомления"
            print("Failed to load notifications: \(error)")
        }
        isLoading = false
    }

    private func markAsRead(_ notification: NotificationDTO) async {
        guard !notification.is_read else { return }
        do {
            try await notificationService.markAsRead(ids: [notification.id])
            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = NotificationDTO(
                    id: notification.id,
                    title: notification.title,
                    body: notification.body,
                    notification_type: notification.notification_type,
                    is_read: true,
                    created_at: notification.created_at
                )
            }
        } catch {
            print("Failed to mark as read: \(error)")
        }
    }

    private func markAllRead() async {
        do {
            try await notificationService.markAllAsRead()
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
        } catch {
            print("Failed to mark all as read: \(error)")
        }
    }
}

// MARK: - Notification Card

private struct NotificationCard: View {
    let notification: NotificationDTO
    let onTap: () -> Void

    private var icon: String {
        switch notification.notification_type {
        case .promo: return "gift.fill"
        case .order: return "bag.fill"
        case .system: return "bell.fill"
        case .bonus: return "star.fill"
        }
    }

    private var iconColor: Color {
        switch notification.notification_type {
        case .promo: return .orange
        case .order: return .blue
        case .system: return .gray
        case .bonus: return .yellow
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: String(notification.created_at.prefix(19))) {
            let calendar = Calendar.current
            if calendar.isDateInToday(date) {
                formatter.dateFormat = "HH:mm"
                return "Сегодня, \(formatter.string(from: date))"
            } else if calendar.isDateInYesterday(date) {
                formatter.dateFormat = "HH:mm"
                return "Вчера, \(formatter.string(from: date))"
            } else {
                formatter.dateFormat = "d MMM, HH:mm"
                formatter.locale = Locale(identifier: "ru_RU")
                return formatter.string(from: date)
            }
        }
        return notification.created_at
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 36, height: 36)
                    .background(iconColor.opacity(0.15))
                    .cornerRadius(8)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()

                        if !notification.is_read {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(notification.body)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .background(notification.is_read ? Color.white : Color.blue.opacity(0.05))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(notification.is_read ? Color.clear : Color.blue.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
