import Foundation

// ─────────────────────────────────────────────────────────────
// ChatStore — persists the Ask-Gemma thread to Documents as JSON so
// the conversation survives app relaunches. (The model's own KV-cache
// memory does not persist across launches — only the displayed thread.)
// ─────────────────────────────────────────────────────────────
enum ChatStore {
    private static var url: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("chat-thread.json")
    }

    static func load() -> [ChatMessage] {
        guard let url, let data = try? Data(contentsOf: url),
              let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) else { return [] }
        return messages
    }

    static func save(_ messages: [ChatMessage]) {
        guard let url else { return }
        if messages.isEmpty {
            try? FileManager.default.removeItem(at: url)
            return
        }
        if let data = try? JSONEncoder().encode(messages) {
            try? data.write(to: url, options: .atomic)
        }
    }

    static func clear() { save([]) }
}
