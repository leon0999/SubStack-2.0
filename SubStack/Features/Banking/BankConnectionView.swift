import SwiftUI

struct BankConnectionView: View {
    @EnvironmentObject var bankDataManager: BankDataManager
    @State private var showingImportOptions = false
    @State private var isImporting = false
    @State private var showingCardLogin = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 일러스트레이션
                Image(systemName: "building.columns.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.top, 40)

                // 설명
                VStack(spacing: 12) {
                    Text("은행 계좌 연동하기")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("거래 내역을 분석해서\n자동으로 구독 서비스를 찾아드려요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // 발견된 구독 수 (이미 연동된 경우)
                if !bankDataManager.detectedSubscriptions.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(bankDataManager.detectedSubscriptions.count)개의 구독 발견됨")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                }

                Spacer()

                // 연동 옵션들
                VStack(spacing: 16) {
                    // 오픈뱅킹 연동 (실제 구현시)
                  ConnectionOptionButton(
                      title: "오픈뱅킹으로 연동",
                      subtitle: "안전하고 빠른 자동 연동",
                      icon: "lock.shield.fill",
                      color: .blue
                  ) {
                      bankDataManager.loadSampleData()
                      // 데이터 로드 후 발견된 구독 화면으로 이동
                      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                          showingImportOptions = true
                      }
                  }

                    // CSV 업로드
                    ConnectionOptionButton(
                        title: "CSV 파일 업로드",
                        subtitle: "은행 앱에서 내려받은 거래내역",
                        icon: "doc.fill",
                        color: .green
                    ) {
                        showingImportOptions = true
                    }

                  // 👈 여기에 새 버튼 추가!
                  ConnectionOptionButton(
                      title: "카드사 로그인",
                      subtitle: "카드사 아이디로 직접 연동",
                      icon: "creditcard.fill",
                      color: .purple
                  ) {
                      showingCardLogin = true
                  }

                    // 수동 입력
                    ConnectionOptionButton(
                        title: "직접 입력하기",
                        subtitle: "구독 서비스를 하나씩 추가",
                        icon: "plus.circle.fill",
                        color: .orange
                    ) {
                        dismiss()
                    }
                }
                .padding(.horizontal)

                Spacer()

                // 보안 안내
                Label("256비트 암호화로 안전하게 보호됩니다", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingImportOptions) {
            DetectedSubscriptionsView()
                .environmentObject(bankDataManager)
        }

        .sheet(isPresented: $showingCardLogin) {
            CardLoginView()
                .environmentObject(bankDataManager)
        }

    }
}

struct ConnectionOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.1))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
    }
}

// 가져오기 진행 화면
// 발견된 구독 확인 화면
struct DetectedSubscriptionsView: View {
    @EnvironmentObject var bankDataManager: BankDataManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedSubscriptions: Set<UUID> = []

    var body: some View {
        NavigationView {
            VStack {
                // 헤더
                VStack(spacing: 8) {
                    Text("\(bankDataManager.detectedSubscriptions.count)개의 구독 발견")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("내 구독 목록에 추가할 항목을 선택하세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()

                // 발견된 구독 리스트
                List {
                    ForEach(bankDataManager.detectedSubscriptions) { subscription in
                        DetectedSubscriptionRow(
                            subscription: subscription,
                            isSelected: selectedSubscriptions.contains(subscription.id)
                        ) {
                            if selectedSubscriptions.contains(subscription.id) {
                                selectedSubscriptions.remove(subscription.id)
                            } else {
                                selectedSubscriptions.insert(subscription.id)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())

                // 추가 버튼
                Button(action: addSelectedSubscriptions) {
                    Text("선택한 \(selectedSubscriptions.count)개 추가하기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedSubscriptions.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                        .padding()
                }
                .disabled(selectedSubscriptions.isEmpty)
            }
            .navigationTitle("발견된 구독")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("모두 선택") {
                        selectedSubscriptions = Set(bankDataManager.detectedSubscriptions.map { $0.id })
                    }
                }
            }
            .onAppear {
                // 기본적으로 확인된 것들은 선택
                selectedSubscriptions = Set(bankDataManager.detectedSubscriptions
                    .filter { $0.isConfirmed }
                    .map { $0.id })
            }
        }
    }

    func addSelectedSubscriptions() {
        // 실제로는 여기서 선택된 구독들을 저장
        print("추가된 구독: \(selectedSubscriptions.count)개")
        dismiss()
    }
}

struct DetectedSubscriptionRow: View {
    let subscription: BankDataManager.DetectedSubscription
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 체크박스
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)

                // 구독 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.merchantName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text(subscription.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(8)

                        Text(subscription.frequency)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("마지막 결제: \(subscription.lastChargeDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // 금액
                Text("₩\(subscription.amount.formatted())")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BankConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        BankConnectionView()
            .environmentObject(BankDataManager())
    }
}
