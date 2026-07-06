import SwiftUI
import PhotosUI
import UIKit

struct MessageAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ridgitsStore: RidgitsStore

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImageData: [Data] = []
    @State private var prompt = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var result: RidgitsMessageAnalysisResult?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RidgitsQuickToolHeader(
                        title: "Analyze Messages",
                        subtitle: "Upload chat screenshots and ask what you want to know."
                    )

                    privacyDisclaimer

                    if let result {
                        resultsSection(result)
                    } else {
                        inputSection
                    }
                }
                .padding(16)
            }
            .background(RidgitsColors.feedBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .font(RidgitsTypography.label(12))
                }
            }
            .sheet(isPresented: $showPaywall) {
                SubscriptionPaywallView(preferredBilling: .yearly)
            }
            .onChange(of: selectedItems) { _, items in
                Task {
                    selectedImageData = await RidgitsQuickToolsImageLoader.jpegData(from: items, limit: 5)
                    if items.count > 5 {
                        errorMessage = "Maximum 5 screenshots allowed."
                    } else {
                        errorMessage = nil
                    }
                }
            }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                RidgitsFormStyle.fieldLabel("Upload Screenshots", required: true)
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images) {
                    uploadDropZone(
                        count: selectedImageData.count,
                        emptyLabel: "Upload or choose screenshots",
                        detail: "Up to 5 screenshots (PNG, JPG, JPEG)"
                    )
                }
                .disabled(isLoading)
            }

            VStack(alignment: .leading, spacing: 8) {
                RidgitsFormStyle.fieldLabel("What would you like to know?", required: true)
                RidgitsTextField(
                    placeholder: "e.g., Are they genuinely interested or just being polite?",
                    text: $prompt,
                    axis: .vertical,
                    lineLimit: 2...4
                )
                .disabled(isLoading)
            }

            RidgitsPrimaryButton(
                title: isLoading ? "Analyzing Conversation…" : "Analyze Conversation",
                isLoading: isLoading,
                isDisabled: prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImageData.isEmpty
            ) {
                Task { await analyze() }
            }

            if let errorMessage {
                errorBanner(errorMessage)
            }
        }
    }

    private func resultsSection(_ result: RidgitsMessageAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if result.isLocked {
                if let preview = result.preview, !preview.isEmpty {
                    RidgitsFormattedAIText(content: preview)
                }
                lockedCTA
            } else {
                ForEach(Array(result.insights.enumerated()), id: \.offset) { _, insight in
                    RidgitsFormattedAIText(content: insight)
                        .padding(.bottom, 4)
                }

                Text("Responses for educational use only.")
                    .font(RidgitsTypography.caption(11))
                    .foregroundStyle(RidgitsColors.textMuted)

                RidgitsSquareButton(title: "Analyze Again", style: .filled) {
                    reset()
                }
            }
        }
        .padding(16)
        .background(RidgitsColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                .stroke(RidgitsColors.dashboardBorder, lineWidth: 1)
        )
    }

    private var privacyDisclaimer: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.system(size: 14))
                .foregroundStyle(RidgitsColors.textMuted)
            Text("Your images are deleted after analysis is complete for privacy purposes.")
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(RidgitsColors.textSecondary)
        }
        .padding(12)
        .background(RidgitsColors.hoverSurface)
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
    }

    private var lockedCTA: some View {
        VStack(spacing: 12) {
            Text("Continue reading")
                .font(RidgitsTypography.label(15))
                .foregroundStyle(RidgitsColors.textHeadline)
            RidgitsSquareButton(title: "Unlock with Ridgits+", style: .filled) {
                showPaywall = true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    @MainActor
    private func analyze() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            errorMessage = "Please enter what you want to analyze first."
            return
        }
        guard !selectedImageData.isEmpty else {
            errorMessage = "Please select at least one screenshot to analyze."
            return
        }
        guard selectedImageData.count <= 5 else {
            errorMessage = "Maximum 5 screenshots allowed for message analysis."
            return
        }
        guard ridgitsStore.hasPlusMembership else {
            showPaywall = true
            return
        }

        do {
            let urls = try await RidgitsQuickToolsService.shared.uploadImages(
                selectedImageData,
                folder: "message_analysis"
            )
            result = try await RidgitsQuickToolsService.shared.analyzeMessages(
                imageURLs: urls,
                prompt: trimmedPrompt
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reset() {
        result = nil
        selectedItems = []
        selectedImageData = []
        prompt = ""
        errorMessage = nil
    }
}

private func uploadDropZone(count: Int, emptyLabel: String, detail: String) -> some View {
    VStack(spacing: 10) {
        Image(systemName: "photo.on.rectangle.angled")
            .font(.system(size: 28))
            .foregroundStyle(RidgitsColors.textMuted)
        Text(count > 0 ? "\(count) image\(count == 1 ? "" : "s") selected" : emptyLabel)
            .font(RidgitsTypography.label(14))
            .foregroundStyle(RidgitsColors.textHeadline)
        Text(detail)
            .font(RidgitsTypography.caption(11))
            .foregroundStyle(RidgitsColors.textSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 28)
    .background(RidgitsColors.surface)
    .overlay(
        RoundedRectangle(cornerRadius: RidgitsRadius.lg)
            .stroke(RidgitsColors.border, style: StrokeStyle(lineWidth: 1, dash: [6]))
    )
}

private func errorBanner(_ message: String) -> some View {
    Text(message)
        .font(RidgitsTypography.caption(12))
        .foregroundStyle(RidgitsColors.destructive)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RidgitsColors.destructive.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
}

struct RidgitsQuickToolHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(RidgitsTypography.headline(22))
                .foregroundStyle(RidgitsColors.textHeadline)
            Text(subtitle)
                .font(RidgitsTypography.body(13))
                .foregroundStyle(RidgitsColors.textSecondary)
        }
    }
}

enum RidgitsQuickToolsImageLoader {
    static func jpegData(from items: [PhotosPickerItem], limit: Int) async -> [Data] {
        var images: [Data] = []
        for item in items.prefix(limit) {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let jpeg = uiImage.jpegData(compressionQuality: 0.85) else {
                continue
            }
            images.append(jpeg)
        }
        return images
    }
}
