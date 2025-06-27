import Foundation
import SwiftUI

class BankDataManager: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var detectedSubscriptions: [DetectedSubscription] = []
    @Published var isAnalyzing = false

    // 거래 내역 데이터 모델
    struct Transaction {
        let id = UUID()
        let date: Date
        let description: String
        let amount: Int
        let merchant: String
    }

    // 감지된 구독 모델
    struct DetectedSubscription: Identifiable {
        let id = UUID()
        let merchantName: String
        let amount: Int
        let frequency: String // "월간", "연간"
        let lastChargeDate: Date
        let category: String
        var isConfirmed: Bool = false
    }

    // CSV 파일 파싱 (실제로는 파일 선택 UI가 필요)
    func importCSV(from csvString: String) {
        isAnalyzing = true

        // CSV 파싱 로직 (간단한 예제)
        let rows = csvString.components(separatedBy: "\n")

        for row in rows.dropFirst() { // 헤더 제외
            let columns = row.components(separatedBy: ",")
            if columns.count >= 4 {
                // 실제로는 더 정교한 파싱 필요
                let transaction = Transaction(
                    date: Date(),
                    description: columns[1],
                    amount: Int(columns[2]) ?? 0,
                    merchant: columns[3]
                )
                transactions.append(transaction)
            }
        }

        // 구독 패턴 분석
        analyzeSubscriptionPatterns()
    }

    // 구독 패턴 분석 알고리즘
    private func analyzeSubscriptionPatterns() {
        // 판매자별로 그룹화
        let groupedByMerchant = Dictionary(grouping: transactions) { $0.merchant }

        for (merchant, merchantTransactions) in groupedByMerchant {
            // 2번 이상 나타난 판매자만 체크
            if merchantTransactions.count >= 2 {
                // 결제 간격 확인
                let sortedDates = merchantTransactions.map { $0.date }.sorted()

                // 월간 구독 패턴 확인 (25-35일 간격)
                var isMonthly = true
                for i in 1..<sortedDates.count {
                    let interval = sortedDates[i].timeIntervalSince(sortedDates[i-1])
                    let days = interval / (24 * 60 * 60)
                    if days < 25 || days > 35 {
                        isMonthly = false
                        break
                    }
                }

                if isMonthly {
                    let subscription = DetectedSubscription(
                        merchantName: merchant,
                        amount: merchantTransactions.first?.amount ?? 0,
                        frequency: "월간",
                        lastChargeDate: sortedDates.last ?? Date(),
                        category: categorizeService(merchant)
                    )
                    detectedSubscriptions.append(subscription)
                }
            }
        }

        isAnalyzing = false
    }

    // 서비스 카테고리 분류
    private func categorizeService(_ merchant: String) -> String {
        let merchantLower = merchant.lowercased()

        if merchantLower.contains("github") || merchantLower.contains("aws") ||
           merchantLower.contains("vercel") || merchantLower.contains("heroku") {
            return "개발"
        } else if merchantLower.contains("netflix") || merchantLower.contains("spotify") ||
                  merchantLower.contains("youtube") {
            return "엔터테인먼트"
        } else if merchantLower.contains("figma") || merchantLower.contains("adobe") {
            return "디자인"
        } else if merchantLower.contains("udemy") || merchantLower.contains("coursera") {
            return "교육"
        }

        return "기타"
    }

    // 테스트용 샘플 데이터
    func loadSampleData() {
        isAnalyzing = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.detectedSubscriptions = [
                DetectedSubscription(
                    merchantName: "GitHub Pro",
                    amount: 7000,
                    frequency: "월간",
                    lastChargeDate: Date(),
                    category: "개발",
                    isConfirmed: true
                ),
                DetectedSubscription(
                    merchantName: "Netflix",
                    amount: 17000,
                    frequency: "월간",
                    lastChargeDate: Date().addingTimeInterval(-10*24*60*60),
                    category: "엔터테인먼트",
                    isConfirmed: true
                ),
                DetectedSubscription(
                    merchantName: "ChatGPT Plus",
                    amount: 25000,
                    frequency: "월간",
                    lastChargeDate: Date().addingTimeInterval(-5*24*60*60),
                    category: "개발",
                    isConfirmed: false
                )
            ]
            self.isAnalyzing = false
        }
    }

  // 카드 연동 관련 속성 추가
      @Published var isLoading = false
      @Published var error: String?

      // 카드 연동 함수 (Mock 버전)
      func connectCard(company: String, username: String, password: String) async {
          isLoading = true
          error = nil

          // 2초 딜레이로 로딩 시뮬레이션
          try? await Task.sleep(nanoseconds: 2_000_000_000)

          // Mock 데이터로 구독 서비스 설정
          await MainActor.run {
              self.detectedSubscriptions = [
                  DetectedSubscription(
                      merchantName: "Netflix",
                      amount: 13500,
                      frequency: "월간",
                      lastChargeDate: Date(),
                      category: "엔터테인먼트",
                      isConfirmed: true
                  ),
                  DetectedSubscription(
                      merchantName: "Spotify",
                      amount: 10900,
                      frequency: "월간",
                      lastChargeDate: Date().addingTimeInterval(-5*24*60*60),
                      category: "엔터테인먼트",
                      isConfirmed: true
                  ),
                  DetectedSubscription(
                      merchantName: "YouTube Premium",
                      amount: 14900,
                      frequency: "월간",
                      lastChargeDate: Date().addingTimeInterval(-10*24*60*60),
                      category: "엔터테인먼트",
                      isConfirmed: true
                  ),
                  DetectedSubscription(
                      merchantName: "GitHub Copilot",
                      amount: 12000,
                      frequency: "월간",
                      lastChargeDate: Date().addingTimeInterval(-15*24*60*60),
                      category: "개발",
                      isConfirmed: true
                  )
              ]

              self.isLoading = false
          }
      }
}
