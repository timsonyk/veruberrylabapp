import SwiftUI

struct DeliveryTimeSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDate: Date = Date()
    @State private var selectedTimeRange: TimeRange?
    
    private let timeRanges: [TimeRange] = [
        TimeRange(start: "09:00", end: "12:00"),
        TimeRange(start: "12:00", end: "15:00"),
        TimeRange(start: "15:00", end: "18:00"),
        TimeRange(start: "18:00", end: "21:00"),
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ASAP Option
                asapOption
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                Divider()
                    .padding(.vertical, 16)
                
                // Schedule Delivery
                VStack(alignment: .leading, spacing: 16) {
                    Text("Запланировать доставку")
                        .font(.headline)
                        .padding(.horizontal, 16)
                    
                    // Date Picker
                    datePicker
                    
                    // Time Range Picker
                    timeRangePicker
                        .padding(.horizontal, 16)
                }
                
                Spacer()
                
                // Confirm Button
                confirmButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .navigationTitle("Время доставки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - ASAP Option
    
    private var asapOption: some View {
        Button {
            appState.selectTimeSlot(.asap)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Как можно скорее")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("В течение 180 мин")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if appState.selectedTimeSlot.minutesFromNow == 180 && appState.selectedTimeSlot.specificDate == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Date Picker
    
    private var datePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableDates, id: \.self) { date in
                    DateButton(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        onSelect: { selectedDate = date }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var availableDates: [Date] {
        let calendar = Calendar.current
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: Date())
        }
    }
    
    // MARK: - Time Range Picker
    
    private var timeRangePicker: some View {
        VStack(spacing: 8) {
            ForEach(timeRanges) { range in
                TimeRangeButton(
                    range: range,
                    isSelected: selectedTimeRange == range,
                    isAvailable: isTimeRangeAvailable(range),
                    onSelect: { selectedTimeRange = range }
                )
            }
        }
    }
    
    private func isTimeRangeAvailable(_ range: TimeRange) -> Bool {
        // Check if the time range is available based on the selected date
        if Calendar.current.isDateInToday(selectedDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            guard let startTime = formatter.date(from: range.start) else { return false }
            
            let calendar = Calendar.current
            let now = Date()
            let startHour = calendar.component(.hour, from: startTime)
            let currentHour = calendar.component(.hour, from: now)
            
            return startHour > currentHour + 2 // Need at least 2 hours notice
        }
        return true
    }
    
    // MARK: - Confirm Button
    
    private var confirmButton: some View {
        Button {
            if let range = selectedTimeRange {
                let slot = DeliveryTimeSlot(
                    title: "\(formatDate(selectedDate)), \(range.displayText)",
                    subtitle: nil,
                    specificDate: selectedDate,
                    specificTimeRange: range.displayText
                )
                appState.selectTimeSlot(slot)
            }
            dismiss()
        } label: {
            Text("Подтвердить")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedTimeRange != nil ? Color.red : Color.gray)
                .cornerRadius(14)
        }
        .disabled(selectedTimeRange == nil)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        
        if Calendar.current.isDateInToday(date) {
            return "Сегодня"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Завтра"
        } else {
            formatter.dateFormat = "d MMMM"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Time Range Model

struct TimeRange: Identifiable, Hashable {
    let id = UUID()
    let start: String
    let end: String
    
    var displayText: String {
        "\(start) - \(end)"
    }
}

// MARK: - Date Button

private struct DateButton: View {
    let date: Date
    let isSelected: Bool
    var onSelect: () -> Void
    
    private var dayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        
        if Calendar.current.isDateInToday(date) {
            return "Сегодня"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Завтра"
        } else {
            formatter.dateFormat = "EEE"
            return formatter.string(from: date).capitalized
        }
    }
    
    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Text(dayText)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .secondary)
                Text(dateText)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 70, height: 70)
            .background(isSelected ? Color.red : Color(.systemGray6))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Time Range Button

private struct TimeRangeButton: View {
    let range: TimeRange
    let isSelected: Bool
    let isAvailable: Bool
    var onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(range.displayText)
                    .font(.subheadline)
                    .foregroundColor(isAvailable ? .primary : .secondary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding(16)
            .background(isSelected ? Color.red.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.red : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
        .opacity(isAvailable ? 1 : 0.5)
    }
}
