//
//  MuseumStatusBadge.swift
//  H3-CoqueGuide
//
//  Chip pequeño que indica si el museo Horno3 está abierto o cerrado en este
//  momento, con su hora de cierre / próxima apertura. Se muestra en el header
//  del Landing.
//
//  Horarios oficiales (https://www.horno3.org/visitanos):
//   - Lunes:        cerrado
//   - Mar a Jue:    11:00 – 18:00
//   - Vie a Dom:    12:00 – 19:00
//

import SwiftUI

struct MuseumStatusBadge: View {

    private let now: Date

    init(now: Date = Date()) {
        self.now = now
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(state.dotColor)
                .frame(width: 7, height: 7)
            Text(state.label)
                .scalingFont(size: 11, weight: .semibold)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(Capsule())
    }

    // MARK: - Lógica de estado

    private enum Status {
        case open(closingHour: Int, closingMinute: Int)
        case closedAfterHours
        case closedToday
        case closedNotYetOpen(openingHour: Int, openingMinute: Int)

        var dotColor: Color {
            switch self {
            case .open: return .green
            default:    return .gray
            }
        }

        var label: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            switch self {
            case .open(let h, let m):
                let comps = DateComponents(hour: h, minute: m)
                let date = Calendar.current.date(from: comps) ?? Date()
                return L10n.museumStatusOpen(until: formatter.string(from: date))
            case .closedNotYetOpen(let h, let m):
                let comps = DateComponents(hour: h, minute: m)
                let date = Calendar.current.date(from: comps) ?? Date()
                return L10n.museumStatusOpensAt(time: formatter.string(from: date))
            case .closedAfterHours, .closedToday:
                return L10n.museumStatusClosed
            }
        }
    }

    private var state: Status {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Monterrey") ?? .current

        let weekday = calendar.component(.weekday, from: now)  // 1=Sun, 2=Mon, ..., 7=Sat
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        // Lunes: cerrado todo el día.
        if weekday == 2 {
            return .closedToday
        }

        // Mar a Jue (3, 4, 5): 11:00 – 18:00.
        // Vie a Dom (6, 7, 1): 12:00 – 19:00.
        let isMidWeek = (weekday == 3 || weekday == 4 || weekday == 5)
        let openHour = isMidWeek ? 11 : 12
        let closeHour = isMidWeek ? 18 : 19

        let nowMinutes = hour * 60 + minute
        let openMinutes = openHour * 60
        let closeMinutes = closeHour * 60

        if nowMinutes < openMinutes {
            return .closedNotYetOpen(openingHour: openHour, openingMinute: 0)
        }
        if nowMinutes >= closeMinutes {
            return .closedAfterHours
        }
        return .open(closingHour: closeHour, closingMinute: 0)
    }
}

#Preview {
    VStack(spacing: 12) {
        MuseumStatusBadge()
    }
    .padding()
}
