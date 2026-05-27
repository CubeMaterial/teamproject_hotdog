import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var globalState: GlobalState

    @State private var messages: [ChatMessage] = []
    @State private var messageText = ""
    @State private var notice = ""
    @State private var isSending = false
    @State private var listenerToken: ChatListenerToken?
    @State private var sendTimeoutWorkItem: DispatchWorkItem?

    private var groupedMessages: [ChatMessageSection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: messages) { message in
            calendar.startOfDay(for: message.createdAt)
        }

        return grouped.keys.sorted().map { date in
            ChatMessageSection(
                date: date,
                title: dateSectionTitle(for: date),
                messages: grouped[date]?.sorted { $0.createdAt < $1.createdAt } ?? []
            )
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !ChatFirestoreService.isFirebaseAvailable {
                    unavailableView
                } else {
                    messagesList
                    composer
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("채팅 문의")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            configureChatListener()
        }
        .onDisappear {
            listenerToken?.cancel()
            listenerToken = nil
        }
    }

    private var unavailableView: some View {
        VStack(spacing: 14) {
            Image(systemName: "message.badge.waveform")
                .font(.system(size: 42))
                .foregroundStyle(Color(hex: "63C9F2"))

            Text("채팅 문의 준비 중")
                .font(.system(size: 22, weight: .bold))

            Text(unavailableMessage)
                .multilineTextAlignment(.center)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(groupedMessages) { section in
                        ChatDateDivider(title: section.title)

                        ForEach(section.messages) { message in
                            HStack {
                                if message.senderType == .admin {
                                    ChatBubble(
                                        text: message.text,
                                        isCurrentUser: false,
                                        createdAt: message.createdAt
                                    )
                                    Spacer(minLength: 48)
                                } else {
                                    Spacer(minLength: 48)
                                    ChatBubble(
                                        text: message.text,
                                        isCurrentUser: true,
                                        createdAt: message.createdAt
                                    )
                                }
                            }
                            .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .onChange(of: messages.count) {
                guard let lastID = messages.last?.id else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if !notice.isEmpty {
                Text(notice)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                TextField("문의 내용을 입력해 주세요", text: $messageText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Button {
                    sendMessage()
                } label: {
                    Text(isSending ? "전송중" : "전송")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 48)
                        .background(Color(hex: "ED9781"))
                        .clipShape(Capsule())
                }
                .disabled(isSending)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(Color(.systemGroupedBackground))
    }

    private var unavailableMessage: String {
        if !ChatFirestoreService.isFirebaseAvailable {
            return "Firebase SDK와 GoogleService-Info.plist를 추가하면 user_id 기준 채팅 문의를 바로 사용할 수 있습니다."
        }

        return notice
    }

    private func configureChatListener() {
        guard let userID = globalState.currentUserID else {
            notice = ChatServiceError.invalidUser.localizedDescription
            return
        }

        listenerToken?.cancel()
        listenerToken = ChatFirestoreService.observeMessages(
            userID: userID,
            onUpdate: { updatedMessages in
                messages = updatedMessages
            },
            onError: { error in
                notice = error.localizedDescription
            }
        )
    }

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { return }
        guard let userID = globalState.currentUserID else {
            notice = ChatServiceError.invalidUser.localizedDescription
            return
        }

        isSending = true
        notice = ""

        let timeoutWorkItem = DispatchWorkItem {
            if isSending {
                isSending = false
                notice = ChatServiceError.timeout.localizedDescription
            }
        }

        sendTimeoutWorkItem?.cancel()
        sendTimeoutWorkItem = timeoutWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: timeoutWorkItem)

        ChatFirestoreService.sendMessage(
            userID: userID,
            userEmail: globalState.currentUserEmail,
            userName: globalState.currentUserName,
            text: trimmed
        ) { result in
            DispatchQueue.main.async {
                guard isSending else { return }

                sendTimeoutWorkItem?.cancel()
                sendTimeoutWorkItem = nil
                isSending = false

                switch result {
                case .success:
                    messageText = ""
                case .failure(let error):
                    notice = error.localizedDescription
                }
            }
        }
    }

    private func dateSectionTitle(for date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "오늘"
        }

        if calendar.isDateInYesterday(date) {
            return "어제"
        }

        return date.formatted(
            .dateTime
                .year()
                .month(.wide)
                .day()
                .weekday(.abbreviated)
        )
    }
}

private struct ChatMessageSection: Identifiable {
    let date: Date
    let title: String
    let messages: [ChatMessage]

    var id: Date { date }
}

private struct ChatDateDivider: View {
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Color.secondary.opacity(0.18))
                .frame(height: 1)

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.96))
                .clipShape(Capsule())

            Rectangle()
                .fill(Color.secondary.opacity(0.18))
                .frame(height: 1)
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}

private struct ChatBubble: View {
    let text: String
    let isCurrentUser: Bool
    let createdAt: Date

    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(isCurrentUser ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(isCurrentUser ? Color(hex: "63C9F2") : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            Text(createdAt.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(GlobalState())
}
