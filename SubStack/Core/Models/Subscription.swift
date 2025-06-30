import Foundation
import SwiftUI

// SubStack 앱 전용 Subscription 모델
struct Subscription: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: String
    let price: Int
    let icon: String
    let colorName: String // color 대신 colorName으로 변경
    let billingCycle: BillingCycle
    let startDate: Date
    let lastPaymentDate: Date
    var isActive: Bool

    init(id: UUID = UUID(),
         name: String,
         category: String,
         price: Int,
         icon: String,
         colorName: String,
         billingCycle: BillingCycle,
         startDate: Date,
         lastPaymentDate: Date,
         isActive: Bool = true) {
        self.id = id
        self.name = name
        self.category = category
        self.price = price
        self.icon = icon
        self.colorName = colorName
        self.billingCycle = billingCycle
        self.startDate = startDate
        self.lastPaymentDate = lastPaymentDate
        self.isActive = isActive
    }

    // 계산 프로퍼티
    var nextBillingDate: Date {
        switch billingCycle {
        case .monthly:
            return Calendar.current.date(byAdding: .month, value: 1, to: lastPaymentDate) ?? Date()
        case .yearly:
            return Calendar.current.date(byAdding: .year, value: 1, to: lastPaymentDate) ?? Date()
        case .weekly:
            return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: lastPaymentDate) ?? Date()
        }
    }

    var daysUntilNextPayment: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextBillingDate).day ?? 0
    }

    var displayColor: Color {
        switch colorName {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "black": return .black
        default: return .gray
        }
    }

    var nextBillingDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: nextBillingDate)
    }
}

enum BillingCycle: String, Codable, CaseIterable {
    case weekly = "주간"
    case monthly = "월간"
    case yearly = "연간"

    var multiplier: Int {
        switch self {
        case .weekly: return 52
        case .monthly: return 12
        case .yearly: return 1
        }
    }
}
