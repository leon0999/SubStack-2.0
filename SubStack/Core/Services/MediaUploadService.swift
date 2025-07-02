// Core/Services/MediaUploadService.swift
import Foundation
import Supabase
import UIKit

class MediaUploadService {
    static let shared = MediaUploadService()
    private let client = SupabaseManager.shared.client

    func uploadMedia(_ data: Data, type: MediaType) async throws -> String {
        let fileName = "\(UUID().uuidString).\(type == .image ? "jpg" : "mp4")"
        let filePath = "posts/\(fileName)"

        // 이미지 압축
        let uploadData: Data
        if type == .image, let image = UIImage(data: data) {
            uploadData = image.jpegData(compressionQuality: 0.8) ?? data
        } else {
            uploadData = data
        }

        // Supabase Storage에 업로드 - path 레이블 제거
        try await client.storage
            .from("media")
            .upload(filePath, data: uploadData)

        // Public URL 반환 - path 레이블 제거
        let publicURL = try client.storage
            .from("media")
            .getPublicURL(path: filePath)

        return publicURL.absoluteString
    }
}
