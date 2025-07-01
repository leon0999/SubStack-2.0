import SwiftUI

struct AddSubscriptionView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var selectedCategory = "코딩"
    @State private var price = ""
    @State private var billingCycle: BillingCycle = .monthly
    @State private var startDate = Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedIcon = "💳"
    @State private var selectedColor = "blue"

    let categories = ["코딩", "글쓰기", "이미지", "비디오", "생산성", "리서치", "기타"]
    let icons = ["🤖", "💻", "✍️", "🎨", "📊", "🔍", "💡", "🚀", "💳"]
    let colors = ["blue", "red", "green", "purple", "orange", "black"]

    // 인기 AI 서비스 템플릿
    let popularServices = [
        ("ChatGPT Plus", "코딩", 25000, "🤖"),
        ("Claude Pro", "코딩", 20000, "🧠"),
        ("GitHub Copilot", "코딩", 13000, "💻"),
        ("Midjourney", "이미지", 10000, "🎨"),
        ("Notion AI", "생산성", 10000, "📝"),
        ("Perplexity Pro", "리서치", 20000, "🔍")
    ]

    var body: some View {
        NavigationView {
            Form {
                // 인기 서비스 섹션
                Section("인기 AI 서비스") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(popularServices, id: \.0) { service in
                                PopularServiceChip(
                                    name: service.0,
                                    price: service.2
                                ) {
                                    name = service.0
                                    selectedCategory = service.1
                                    price = String(service.2)
                                    selectedIcon = service.3
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // 서비스 정보 입력
                Section("서비스 정보") {
                    TextField("서비스 이름", text: $name)
                        .textFieldStyle(.automatic)

                    Picker("카테고리", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    HStack {
                        Text("₩")
                        TextField("가격", text: $price)
                            .keyboardType(.numberPad)
                    }

                    // 아이콘 선택
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(icons, id: \.self) { icon in
                                Text(icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color(UIColor.systemGray6))
                                    .cornerRadius(10)
                                    .onTapGesture {
                                        selectedIcon = icon
                                    }
                            }
                        }
                    }
                }

                // 결제 주기
                Section("결제 주기") {
                    Picker("주기 선택", selection: $billingCycle) {
                        ForEach(BillingCycle.allCases, id: \.self) { cycle in
                            Text(cycle.rawValue).tag(cycle)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    DatePicker("시작일", selection: $startDate, displayedComponents: .date)
                }

                // 예상 비용
                Section("예상 비용") {
                    if let priceInt = Int(price) {
                        HStack {
                            Text("월간 환산")
                            Spacer()
                            Text("₩\(calculateMonthlyPrice(priceInt).formatted())")
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("연간 환산")
                            Spacer()
                            Text("₩\(calculateYearlyPrice(priceInt).formatted())")
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .navigationTitle("구독 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("추가") {
                        addSubscription()
                    }
                    .disabled(name.isEmpty || price.isEmpty)
                }
            }
            .alert("알림", isPresented: $showingAlert) {
                Button("확인") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func calculateMonthlyPrice(_ price: Int) -> Int {
        switch billingCycle {
        case .weekly: return price * 4
        case .monthly: return price
        case .yearly: return price / 12
        }
    }

    private func calculateYearlyPrice(_ price: Int) -> Int {
        switch billingCycle {
        case .weekly: return price * 52
        case .monthly: return price * 12
        case .yearly: return price
        }
    }

    private func addSubscription() {
        guard let priceInt = Int(price) else {
            alertMessage = "올바른 가격을 입력해주세요"
            showingAlert = true
            return
        }

        // Subscription 객체 생성 (올바른 파라미터 순서)
        let newSubscription = Subscription(
            name: name,
            category: selectedCategory,
            price: priceInt,
            icon: selectedIcon,
            colorName: selectedColor,
            billingCycle: billingCycle,
            startDate: startDate,
            lastPaymentDate: startDate // 시작일을 마지막 결제일로 설정
        )

        // SubscriptionManager의 addSubscription 메서드 호출
        subscriptionManager.addSubscription(newSubscription)

        dismiss()
    }
}

struct PopularServiceChip: View {
    let name: String
    let price: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("₩\(price.formatted())")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
