import SwiftUI

struct ChatbotView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var draftMessage = ""

    private let quickQuestions = [
        "눈물 자국 줄이는 방법",
        "푸들 간식 추천",
        "하네스 사이즈 확인",
        "노즈워크 장난감 추천"
    ]

    var body: some View {
        let palette = appState.palette

        NavigationStack {
            VStack(spacing: 0) {
                chatHeader(palette: palette)
                messageList(palette: palette)
            }
            .background(palette.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                inputBar(palette: palette)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundStyle(palette.primary)
                }
            }
            .task {
                await appState.loadChatbotOptions()
            }
        }
    }

    private func chatHeader(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(palette.primary)
                        .frame(width: 56, height: 56)
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("HOTDOG 케어 상담")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(palette.textPrimary)
                    Text("\(appState.selectedDog.name) 맞춤 추천과 생활 상담")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()

                if appState.isSendingChatMessage {
                    ProgressView()
                        .tint(palette.primary)
                        .controlSize(.small)
                }
            }

            HStack(spacing: 8) {
                infoChip("견종 \(appState.selectedDog.breed)", palette: palette)
                infoChip("나이 \(appState.selectedDog.age)", palette: palette)
                infoChip("체중 \(appState.selectedDog.weight)", palette: palette)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(palette.cardBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(palette.secondary.opacity(0.16))
                .frame(height: 1)
        }
    }

    private func infoChip(_ text: String, palette: AppPalette) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(palette.primary)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(palette.secondary.opacity(0.14), in: Capsule())
    }

    private func messageList(palette: AppPalette) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    quickQuestionPanel(palette: palette)

                    ForEach(appState.chatMessages) { message in
                        messageRow(message, palette: palette)
                            .id(message.id)
                    }

                    if appState.isSendingChatMessage {
                        typingRow(palette: palette)
                            .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 14)
            }
            .onChange(of: appState.chatMessages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: appState.isSendingChatMessage) { _, _ in
                scrollToBottom(proxy)
            }
            .onAppear {
                scrollToBottom(proxy)
            }
        }
    }

    private func quickQuestionPanel(palette: AppPalette) -> some View {
        let optionLabels = appState.chatbotOptionLabels
        let suggestions = optionLabels.isEmpty ? quickQuestions : optionLabels

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(palette.accent)
                Text("빠른 상담")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(palette.textPrimary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { question in
                        Button {
                            if optionLabels.contains(question) {
                                select(question)
                            } else {
                                send(question)
                            }
                        } label: {
                            Text(question)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(palette.primary)
                                .lineLimit(1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(palette.background, in: Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(palette.secondary.opacity(0.22), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(appState.isSendingChatMessage)
                    }
                }
            }
        }
        .padding(14)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func messageRow(_ message: ChatMessage, palette: AppPalette) -> some View {
        let isUser = message.sender != "HOTDOG"

        return HStack(alignment: .top, spacing: 10) {
            if isUser {
                Spacer(minLength: 52)
            } else {
                botAvatar(palette: palette)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                if !isUser {
                    Text("HOTDOG 상담사")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(palette.textSecondary)
                }

                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundStyle(isUser ? .white : palette.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        isUser ? palette.primary : palette.cardBackground,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .overlay {
                        if !isUser {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(palette.secondary.opacity(0.14), lineWidth: 1)
                        }
                    }
            }
            .frame(maxWidth: 292, alignment: isUser ? .trailing : .leading)

            if isUser {
                userAvatar(palette: palette)
            } else {
                Spacer(minLength: 52)
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private func typingRow(palette: AppPalette) -> some View {
        HStack(alignment: .top, spacing: 10) {
            botAvatar(palette: palette)

            HStack(spacing: 8) {
                ProgressView()
                    .tint(palette.primary)
                    .controlSize(.small)
                Text("맞춤 답변을 정리하고 있어요")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(palette.secondary.opacity(0.14), lineWidth: 1)
            )

            Spacer(minLength: 52)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func botAvatar(palette: AppPalette) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(palette.accent.opacity(0.18))
                .frame(width: 34, height: 34)
            Image(systemName: "pawprint.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(palette.accent)
        }
    }

    private func userAvatar(palette: AppPalette) -> some View {
        ZStack {
            Circle()
                .fill(palette.secondary.opacity(0.18))
                .frame(width: 32, height: 32)
            Image(systemName: "person.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(palette.primary)
        }
    }

    private func inputBar(palette: AppPalette) -> some View {
        HStack(spacing: 10) {
            TextField("궁금한 점을 입력하세요", text: $draftMessage, axis: .vertical)
                .font(.system(size: 15))
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(palette.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.secondary.opacity(0.18), lineWidth: 1)
                )
                .disabled(appState.isSendingChatMessage)
                .submitLabel(.send)
                .onSubmit {
                    sendDraft()
                }

            Button {
                sendDraft()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(canSend ? palette.accent : palette.textSecondary.opacity(0.36), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(palette.cardBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(palette.secondary.opacity(0.16))
                .frame(height: 1)
        }
    }

    private var canSend: Bool {
        !draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !appState.isSendingChatMessage
    }

    private func sendDraft() {
        let message = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        draftMessage = ""
        send(message)
    }

    private func send(_ message: String) {
        Task {
            await appState.askChatbot(question: message)
        }
    }

    private func select(_ option: String) {
        Task {
            await appState.selectChatbotOption(option)
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                if appState.isSendingChatMessage {
                    proxy.scrollTo("typing", anchor: .bottom)
                } else if let lastID = appState.chatMessages.last?.id {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
    }
}
