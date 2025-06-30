import SwiftUI

struct CardLoginView: View {
  @StateObject private var networkManager = NetworkManager.shared
  @EnvironmentObject var bankDataManager: BankDataManager
  @Environment(\.dismiss) var dismiss

  @State private var selectedCard = "samsung"
  @State private var userId = ""
  @State private var password = ""
  @State private var isLoading = false
  @State private var showError = false
  @State private var errorMessage = ""
  @State private var showDetectedSubscriptions = false

  let cardOptions = [
    ("samsung", "삼성카드", Color.blue),
    ("shinhan", "신한카드", Color.blue),
    ("kb", "KB국민카드", Color.orange),
    ("hyundai", "현대카드", Color.red),
    ("lotte", "롯데카드", Color.red)
  ]

  var body: some View {
    NavigationView {
      VStack(spacing: 24) {
        // 카드사 선택
        VStack(alignment: .leading, spacing: 12) {
          Text("카드사 선택")
            .font(.headline)

          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
              ForEach(cardOptions, id: \.0) { card in
                CardButton(
                  name: card.1,
                  color: card.2,
                  isSelected: selectedCard == card.0
                ) {
                  selectedCard = card.0
                }
              }
            }
          }
        }
        .padding(.horizontal)

        // 로그인 정보 입력
        VStack(spacing: 16) {
          VStack(alignment: .leading, spacing: 8) {
            Text("아이디")
              .font(.subheadline)
              .foregroundColor(.secondary)
            TextField("카드사 아이디", text: $userId)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .autocapitalization(.none)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("비밀번호")
              .font(.subheadline)
              .foregroundColor(.secondary)
            SecureField("비밀번호", text: $password)
              .textFieldStyle(RoundedBorderTextFieldStyle())
          }
        }
        .padding(.horizontal)

        // 보안 안내
        HStack(spacing: 8) {
          Image(systemName: "lock.shield.fill")
            .foregroundColor(.green)
          Text("256비트 암호화로 안전하게 보호됩니다")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        // 연동 버튼
        Button(action: connectCard) {
          if isLoading {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
          } else {
            Text("카드 연동하기")
              .fontWeight(.semibold)
          }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(userId.isEmpty || password.isEmpty ? Color.gray : Color.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(userId.isEmpty || password.isEmpty || isLoading)
        .padding(.horizontal)
      }
      .navigationTitle("카드 연동")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("취소") { dismiss() }
        }
      }
      .alert("오류", isPresented: $showError) {
        Button("확인", role: .cancel) {}
      } message: {
        Text(errorMessage)
      }
    }

    .sheet(isPresented: $showDetectedSubscriptions) {  // 여기에 추가
        DetectedSubscriptionsView()
            .environmentObject(bankDataManager)
    }

  }

  func connectCard() {
    isLoading = true

    Task {
      await bankDataManager.connectCard(
        company: selectedCard,
        username: userId,
        password: password
      )

      await MainActor.run {
        isLoading = false
        if !bankDataManager.detectedSubscriptions.isEmpty {
          showDetectedSubscriptions = true
        }
      }
    }
  }

  struct CardButton: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
      Button(action: action) {
        Text(name)
          .font(.subheadline)
          .fontWeight(isSelected ? .semibold : .regular)
          .padding(.horizontal, 20)
          .padding(.vertical, 12)
          .background(isSelected ? color : Color(UIColor.systemGray5))
          .foregroundColor(isSelected ? .white : .primary)
          .cornerRadius(20)
      }
    }
  }

  struct CardLoginView_Previews: PreviewProvider {
    static var previews: some View {
      CardLoginView()
        .environmentObject(BankDataManager())
    }
  }
}
