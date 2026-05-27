import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

enum ChatServiceError: LocalizedError {
    case firebaseUnavailable
    case invalidUser
    case timeout
    case permissionDenied
    case message(String)

    var errorDescription: String? {
        switch self {
        case .firebaseUnavailable:
            return "Firebase 설정이 아직 연결되지 않았습니다."
        case .invalidUser:
            return "로그인 사용자 정보를 확인할 수 없습니다."
        case .timeout:
            return "채팅 서버 응답이 지연되고 있습니다. Firestore 규칙과 네트워크를 확인해 주세요."
        case .permissionDenied:
            return "Firestore 쓰기 권한이 없습니다. 보안 규칙을 확인해 주세요."
        case .message(let message):
            return message
        }
    }
}

final class ChatListenerToken {
    private let cancellation: () -> Void

    init(cancellation: @escaping () -> Void) {
        self.cancellation = cancellation
    }

    func cancel() {
        cancellation()
    }
}

enum ChatFirestoreService {
    static var isFirebaseAvailable: Bool {
        #if canImport(FirebaseFirestore)
        true
        #else
        false
        #endif
    }

    static func conversationID(for userID: Int) -> String {
        "user_\(userID)"
    }

    static func observeMessages(
        userID: Int,
        onUpdate: @escaping ([ChatMessage]) -> Void,
        onError: @escaping (Error) -> Void = { _ in }
    ) -> ChatListenerToken {
        #if canImport(FirebaseFirestore)
        let listener = Firestore.firestore()
            .collection("chats")
            .document(conversationID(for: userID))
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = mapFirestoreError(error) {
                    onError(error)
                    return
                }

                let messages = snapshot?.documents.compactMap { document in
                    mapMessage(id: document.documentID, data: document.data())
                } ?? []
                onUpdate(messages)
            }

        return ChatListenerToken {
            listener.remove()
        }
        #else
        onUpdate([])
        return ChatListenerToken {}
        #endif
    }

    static func sendMessage(
        userID: Int,
        userEmail: String,
        userName: String,
        text: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        #if canImport(FirebaseFirestore)
        let callbackQueue = DispatchQueue(label: "ChatFirestoreService.sendMessage")
        var didFinish = false

        func finish(_ result: Result<Void, Error>) {
            callbackQueue.sync {
                guard !didFinish else { return }
                didFinish = true
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + 8) {
            finish(.failure(ChatServiceError.timeout))
        }

        let db = Firestore.firestore()
        let conversationID = conversationID(for: userID)
        let now = Date()
        let conversationRef = db.collection("chats").document(conversationID)
        let messagesRef = conversationRef.collection("messages")

        conversationRef.setData([
            "userID": userID,
            "userEmail": userEmail,
            "userName": userName,
            "status": "open",
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now),
            "lastMessage": text
        ], merge: true) { error in
            if let error = mapFirestoreError(error) {
                finish(.failure(error))
                return
            }

            messagesRef.addDocument(data: [
                "text": text,
                "senderType": ChatSenderType.user.rawValue,
                "senderUserID": userID,
                "createdAt": Timestamp(date: now)
            ]) { error in
                if let error = mapFirestoreError(error) {
                    finish(.failure(error))
                } else {
                    finish(.success(()))
                }
            }
        }
        #else
        completion(.failure(ChatServiceError.firebaseUnavailable))
        #endif
    }

    static func updatePushToken(
        userID: Int,
        email: String,
        token: String,
        completion: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {
        #if canImport(FirebaseFirestore)
        let now = Date()
        Firestore.firestore()
            .collection("user_push_tokens")
            .document(String(userID))
            .setData([
                "userID": userID,
                "userEmail": email,
                "fcmToken": token,
                "platform": "ios",
                "updatedAt": Timestamp(date: now)
            ], merge: true) { error in
                if let error = mapFirestoreError(error) {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        #else
        completion(.failure(ChatServiceError.firebaseUnavailable))
        #endif
    }

    #if canImport(FirebaseFirestore)
    private static func mapMessage(id: String, data: [String: Any]) -> ChatMessage? {
        guard
            let text = data["text"] as? String,
            let senderRaw = data["senderType"] as? String,
            let senderType = ChatSenderType(rawValue: senderRaw),
            let senderUserID = data["senderUserID"] as? Int
        else {
            return nil
        }

        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }

        return ChatMessage(
            id: id,
            text: text,
            senderType: senderType,
            senderUserID: senderUserID,
            createdAt: createdAt
        )
    }

    private static func mapFirestoreError(_ error: Error?) -> Error? {
        guard let error else { return nil }
        let nsError = error as NSError

        if nsError.domain == FirestoreErrorDomain,
           nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
            return ChatServiceError.permissionDenied
        }

        return ChatServiceError.message(nsError.localizedDescription)
    }
    #endif
}
