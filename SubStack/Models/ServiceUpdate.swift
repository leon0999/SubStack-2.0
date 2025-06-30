// Models/ServiceUpdate.swift
import Foundation
import SwiftUI

struct ServiceUpdate: Identifiable, Codable {
    let id: UUID
    let service: String
    let serviceIcon: String
    let title: String
    let summary: String
    let link: String
    let publishedDate: Date
    let category: UpdateCategory
    let importance: UpdateImportance
    var isRead: Bool

  init(
       id: UUID = UUID(),
       service: String,
       serviceIcon: String,
       title: String,
       summary: String,
       link: String,
       publishedDate: Date,
       category: UpdateCategory,
       importance: UpdateImportance,
       isRead: Bool = false
   ) {
       self.id = id
       self.service = service
       self.serviceIcon = serviceIcon
       self.title = title
       self.summary = summary
       self.link = link
       self.publishedDate = publishedDate
       self.category = category
       self.importance = importance
       self.isRead = isRead
   }

    enum UpdateCategory: String, Codable, CaseIterable {
        case newFeature = "새 기능"
        case priceChange = "가격 변경"
        case apiUpdate = "API 업데이트"
        case modelUpdate = "모델 업데이트"
        case policy = "정책 변경"
        case general = "일반"

        var icon: String {
            switch self {
            case .newFeature: return "sparkles"
            case .priceChange: return "dollarsign.circle"
            case .apiUpdate: return "terminal"
            case .modelUpdate: return "brain"
            case .policy: return "doc.text"
            case .general: return "newspaper"
            }
        }

        var color: Color {
            switch self {
            case .newFeature: return .blue
            case .priceChange: return .red
            case .apiUpdate: return .purple
            case .modelUpdate: return .green
            case .policy: return .orange
            case .general: return .gray
            }
        }
    }

    enum UpdateImportance: Int, Codable {
        case critical = 3
        case normal = 2
        case minor = 1

        var label: String {
            switch self {
            case .critical: return "중요"
            case .normal: return "일반"
            case .minor: return "마이너"
            }
        }
    }
}
