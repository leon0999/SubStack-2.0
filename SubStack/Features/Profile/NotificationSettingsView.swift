import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingTimePicker = false

    var body: some View {
        Form {
            // 알림 권한
            Section {
                HStack {
                    Text("알림 권한")
                    Spacer()
                    if notificationManager.isAuthorized {
                        Label("허용됨", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Button("권한 요청") {
                            notificationManager.requestAuthorization()
                        }
                        .font(.caption)
                    }
                }
            }

            // 알림 설정
            Section("알림 설정") {
                Toggle("결제 당일 알림", isOn: $notificationManager.notifyOnPaymentDay)

                VStack(alignment: .leading, spacing: 8) {
                    Text("사전 알림")
                    Picker("", selection: $notificationManager.notifyDaysBefore) {
                        Text("사용 안 함").tag(0)
                        Text("1일 전").tag(1)
                        Text("2일 전").tag(2)
                        Text("3일 전").tag(3)
                        Text("7일 전").tag(7)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                HStack {
                    Text("알림 시간")
                    Spacer()
                    Button(notificationManager.notificationTimeString) {
                        showingTimePicker = true
                    }
                    .foregroundColor(.blue)
                }
            }

            // 테스트
            Section("테스트") {
                Button("테스트 알림 보내기") {
                    sendTestNotification()
                }

                Button("예정된 알림 확인") {
                    notificationManager.printPendingNotifications()
                }
            }
        }
        .navigationTitle("알림 설정")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTimePicker) {
            TimePickerSheet(timeString: $notificationManager.notificationTimeString)
        }
        .onChange(of: notificationManager.notifyDaysBefore) { oldValue, newValue in
            rescheduleAll()
        }
        .onChange(of: notificationManager.notifyOnPaymentDay) { oldValue, newValue in
            rescheduleAll()
        }
    }

    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "SubStack 테스트"
        content.body = "알림이 정상적으로 작동합니다!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "test", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func rescheduleAll() {
        notificationManager.rescheduleAllNotifications(for: subscriptionManager.subscriptions)
    }
}

struct TimePickerSheet: View {
    @Binding var timeString: String
    @State private var selectedTime = Date()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("시간 선택", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .padding()

                Spacer()
            }
            .navigationTitle("알림 시간")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        timeString = formatter.string(from: selectedTime)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            selectedTime = formatter.date(from: timeString) ?? Date()
        }
    }
}
