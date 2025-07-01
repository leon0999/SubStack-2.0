// Core/Managers/SubscriptionManager.swift
import Foundation
import SwiftUI

class SubscriptionManager: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    private let localStorageKey = "SubStack_Subscriptions"
    private var currentUserId: UUID?

    init() {
        loadLocalSubscriptions()
    }

    // MARK: - Supabase 동기화

    func setCurrentUser(_ userId: UUID) {
        self.currentUserId = userId
        Task {
            await syncWithSupabase()
        }
    }

    func syncWithSupabase() async {
        guard let userId = currentUserId else {
            print("❌ 사용자 ID가 없어서 동기화할 수 없습니다")
            return
        }

        await MainActor.run {
            isSyncing = true
        }

        do {
            // 1. Supabase에서 구독 목록 가져오기
            let cloudSubscriptions = try await fetchCloudSubscriptions(userId: userId)

            // 2. 로컬과 클라우드 데이터 병합
            await mergeSubscriptions(local: subscriptions, cloud: cloudSubscriptions, userId: userId)

            // 3. 동기화 완료
            await MainActor.run {
                lastSyncDate = Date()
                isSyncing = false
                saveToLocal()
            }

            print("✅ Supabase 동기화 완료: \(subscriptions.count)개 구독")

        } catch {
            print("❌ Supabase 동기화 실패: \(error)")
            await MainActor.run {
                isSyncing = false
            }
        }
    }

    private func fetchCloudSubscriptions(userId: UUID) async throws -> [Subscription] {
        let response = try await SupabaseManager.shared.client
            .from("subscriptions")
            .select()
            .eq("user_id", value: userId)
            .execute()

        // Supabase 응답을 Subscription 모델로 변환
        struct CloudSubscription: Decodable {
            let id: Int
            let name: String
            let category: String
            let price: Int
            let icon: String?
            let created_at: String
        }

        let decoder = JSONDecoder()
        let cloudData = try decoder.decode([CloudSubscription].self, from: response.data)

        // 로컬 Subscription 모델로 변환
        return cloudData.map { cloud in
            Subscription(
                name: cloud.name,
                category: cloud.category,
                price: cloud.price,
                icon: cloud.icon ?? "💳",
                colorName: "blue", // 기본값
                billingCycle: .monthly, // 기본값
                startDate: Date(),
                lastPaymentDate: Date()
            )
        }
    }

    private func mergeSubscriptions(local: [Subscription], cloud: [Subscription], userId: UUID) async {
        // 중복 제거하고 병합 (이름 기준)
        var mergedSubscriptions = local

        for cloudSub in cloud {
            if !mergedSubscriptions.contains(where: { $0.name == cloudSub.name }) {
                mergedSubscriptions.append(cloudSub)
            }
        }

        // 로컬에만 있는 구독들을 클라우드에 업로드
        for localSub in local {
            if !cloud.contains(where: { $0.name == localSub.name }) {
                await uploadSubscription(localSub, userId: userId)
            }
        }

        // 최종 병합된 데이터를 메인 스레드에서 업데이트
        let finalMerged = mergedSubscriptions
        await MainActor.run {
            self.subscriptions = finalMerged
        }
    }

    private func uploadSubscription(_ subscription: Subscription, userId: UUID) async {
        do {
            // Supabase에 업로드할 데이터
            struct UploadData: Encodable {
                let user_id: UUID  // Int에서 UUID로 변경
                let name: String
                let category: String
                let price: Int
                let icon: String
            }

            let data = UploadData(
                user_id: userId,
                name: subscription.name,
                category: subscription.category,
                price: subscription.price,
                icon: subscription.icon
            )

            try await SupabaseManager.shared.client
                .from("subscriptions")
                .insert(data)
                .execute()

            print("✅ 구독 업로드 성공: \(subscription.name)")
        } catch {
            print("❌ 구독 업로드 실패: \(error)")
        }
    }

    // MARK: - 기존 메서드들 (수정)

    func addSubscription(_ subscription: Subscription) {
        subscriptions.append(subscription)
        saveToLocal()

        // 클라우드에도 추가
        if let userId = currentUserId {
            Task {
                await uploadSubscription(subscription, userId: userId)
            }
        }
    }

    func deleteSubscription(_ subscription: Subscription) {
        subscriptions.removeAll { $0.id == subscription.id }
        saveToLocal()

        // 클라우드에서도 삭제
        if currentUserId != nil {
            Task {
                await deleteFromCloud(subscription)
            }
        }
    }

    private func deleteFromCloud(_ subscription: Subscription) async {
        do {
            try await SupabaseManager.shared.client
                .from("subscriptions")
                .delete()
                .eq("name", value: subscription.name)
                .eq("user_id", value: currentUserId!)
                .execute()

            print("✅ 클라우드에서 구독 삭제 성공: \(subscription.name)")
        } catch {
            print("❌ 클라우드에서 구독 삭제 실패: \(error)")
        }
    }

    func updateSubscription(_ subscription: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = subscription
            saveToLocal()

            // 클라우드 업데이트
            if currentUserId != nil {
                Task {
                    await updateInCloud(subscription)
                }
            }
        }
    }

    private func updateInCloud(_ subscription: Subscription) async {
        do {
            struct UpdateData: Encodable {
                let name: String
                let category: String
                let price: Int
                let icon: String
            }

            let data = UpdateData(
                name: subscription.name,
                category: subscription.category,
                price: subscription.price,
                icon: subscription.icon
            )

            try await SupabaseManager.shared.client
                .from("subscriptions")
                .update(data)
                .eq("name", value: subscription.name)
                .eq("user_id", value: currentUserId!)
                .execute()

            print("✅ 클라우드 업데이트 성공: \(subscription.name)")
        } catch {
            print("❌ 클라우드 업데이트 실패: \(error)")
        }
    }

    // MARK: - 로컬 저장소

    private func saveToLocal() {
        if let encoded = try? JSONEncoder().encode(subscriptions) {
            UserDefaults.standard.set(encoded, forKey: localStorageKey)
        }
    }

    private func loadLocalSubscriptions() {
        guard let data = UserDefaults.standard.data(forKey: localStorageKey),
              let decoded = try? JSONDecoder().decode([Subscription].self, from: data) else {
            return
        }
        subscriptions = decoded
    }

    // MARK: - 계산 프로퍼티 (기존 유지)

    var totalMonthlySpend: Int {
        subscriptions.filter { $0.isActive }.reduce(0) { total, subscription in
            switch subscription.billingCycle {
            case .weekly:
                return total + (subscription.price * 52 / 12)
            case .monthly:
                return total + subscription.price
            case .yearly:
                return total + (subscription.price / 12)
            }
        }
    }

    var totalYearlySpend: Int {
        subscriptions.filter { $0.isActive }.reduce(0) { total, subscription in
            switch subscription.billingCycle {
            case .weekly:
                return total + (subscription.price * 52)
            case .monthly:
                return total + (subscription.price * 12)
            case .yearly:
                return total + subscription.price
            }
        }
    }

    var subscriptionsByCategory: [String: [Subscription]] {
        Dictionary(grouping: subscriptions.filter { $0.isActive }, by: { $0.category })
    }

    var upcomingPayments: [Subscription] {
        subscriptions.filter { $0.isActive }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
    }

    // MARK: - 추가 계산 프로퍼티 (DashboardView용)

    var topCategory: String? {
        let categoryCounts = subscriptions.filter { $0.isActive }
            .reduce(into: [String: Int]()) { counts, subscription in
                counts[subscription.category, default: 0] += 1
            }

        return categoryCounts.max(by: { $0.value < $1.value })?.key
    }
}
