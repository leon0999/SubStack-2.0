import SwiftUI

struct ProfileView: View {
    @State private var developerType = "백엔드 개발자"
    @State private var experienceLevel = "시니어 (7년+)"
    @State private var monthlyBudget = 300000

    var body: some View {
        NavigationView {
            Form {
                // 프로필 섹션
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        VStack(alignment: .leading) {
                            Text("개발자")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("가입일: 2024년 12월")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading)
                    }
                    .padding(.vertical, 8)
                }

                // 개발자 정보
                Section("개발자 정보") {
                    HStack {
                        Text("개발 분야")
                        Spacer()
                        Text(developerType)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("경력")
                        Spacer()
                        Text(experienceLevel)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("월 예산")
                        Spacer()
                        Text("₩\(monthlyBudget.formatted())")
                            .foregroundColor(.secondary)
                    }
                }

                // 통계
                Section("구독 통계") {
                    StatRow(title: "총 구독 수", value: "15개")
                    StatRow(title: "평균 구독 기간", value: "8개월")
                    StatRow(title: "이번 달 절약", value: "₩45,000")
                    StatRow(title: "올해 총 절약", value: "₩284,000")
                }

                // 설정
                Section("설정") {
                    NavigationLink(destination: Text("알림 설정")) {
                        Label("알림 설정", systemImage: "bell")
                    }

                    NavigationLink(destination: Text("결제 수단")) {
                        Label("결제 수단 관리", systemImage: "creditcard")
                    }

                  NavigationLink(destination: BankConnectionView()) {
                      Label("은행 계좌 연동", systemImage: "building.columns")
                  }
                }

                // 앱 정보
                Section {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Button(action: {}) {
                        Text("로그아웃")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("프로필")
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
