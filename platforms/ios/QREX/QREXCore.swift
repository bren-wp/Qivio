import Foundation
import Combine

enum QRContent {
    static func isWifi(_ raw: String) -> Bool { raw.uppercased().hasPrefix("WIFI:") }

    static func wifiField(_ raw: String, key: String) -> String? {
        guard isWifi(raw), ["T", "S", "P", "H"].contains(key) else { return nil }
        var values: [String: String] = [:]
        var part = ""
        var parts: [String] = []
        var escaping = false
        for character in raw.dropFirst(5) {
            if escaping {
                part.append(character)
                escaping = false
            } else if character == "\\" {
                escaping = true
            } else if character == ";" {
                parts.append(part)
                part = ""
            } else {
                part.append(character)
            }
        }
        if escaping { return nil }
        if !part.isEmpty { parts.append(part) }
        for item in parts {
            if let index = item.firstIndex(of: ":") {
                values[String(item[..<index])] = String(item[item.index(after: index)...])
            }
        }
        return values[key]
    }

    static func wifi(ssid: String, password: String) -> String {
        func escape(_ text: String) -> String {
            text.replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: ";", with: "\\;")
                .replacingOccurrences(of: ":", with: "\\:")
                .replacingOccurrences(of: ",", with: "\\,")
                .replacingOccurrences(of: "\"", with: "\\\"")
        }
        return "WIFI:T:\(password.isEmpty ? "nopass" : "WPA");S:\(escape(ssid));P:\(escape(password));;"
    }

    static func safeURL(_ raw: String) -> URL? {
        guard raw == raw.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.contains("\\"), !raw.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
              !raw.unicodeScalars.contains(where: { CharacterSet.whitespacesAndNewlines.contains($0) }),
              let components = URLComponents(string: raw),
              ["http", "https"].contains(components.scheme?.lowercased() ?? ""),
              components.host?.isEmpty == false,
              components.user == nil, components.password == nil else { return nil }
        return components.url
    }

    static func title(_ raw: String) -> String {
        if isWifi(raw) { return wifiField(raw, key: "S") ?? "Wi-Fi" }
        if let url = safeURL(raw), let host = url.host { return host }
        return String(raw.replacingOccurrences(of: "\n", with: " ").prefix(56))
    }

    static func isSupported(_ raw: String) -> Bool {
        !raw.isEmpty && raw.utf8.count <= 1500
    }
}

struct QRHistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let raw: String
    let timestamp: Date
    let saved: Bool
}

@MainActor
final class QREXStore: ObservableObject {
    @Published private(set) var items: [QRHistoryItem] = []
    @Published var historyEnabled: Bool {
        didSet { UserDefaults.standard.set(historyEnabled, forKey: "qrex.history.enabled") }
    }
    @Published var lightMode: Bool {
        didSet { UserDefaults.standard.set(lightMode, forKey: "qrex.light") }
    }

    init(defaults: UserDefaults = .standard) {
        historyEnabled = defaults.object(forKey: "qrex.history.enabled") as? Bool ?? true
        lightMode = defaults.bool(forKey: "qrex.light")
        if let data = defaults.data(forKey: "qrex.history"),
           let loaded = try? JSONDecoder().decode([QRHistoryItem].self, from: data) {
            var unique: Set<String> = []
            items = Array(loaded.filter { unique.insert($0.raw).inserted && $0.raw.count <= 10000 }.prefix(250))
        }
    }

    func record(_ raw: String) {
        guard historyEnabled, !QRContent.isWifi(raw), !raw.isEmpty else { return }
        update(raw, saved: items.first(where: { $0.raw == raw })?.saved ?? false)
    }

    func save(_ raw: String) {
        guard !raw.isEmpty else { return }
        update(raw, saved: true)
    }

    private func update(_ raw: String, saved: Bool) {
        items.removeAll { $0.raw == raw }
        items.insert(QRHistoryItem(id: UUID(), raw: raw, timestamp: Date(), saved: saved), at: 0)
        if items.count > 250 {
            if let lastUnsaved = items.lastIndex(where: { !$0.saved }) {
                items.remove(at: lastUnsaved)
            } else {
                items.removeLast()
            }
        }
        persist()
    }

    func delete(_ item: QRHistoryItem) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    func clearHistory() {
        items.removeAll { !$0.saved }
        persist()
    }

    func clearAll() {
        items.removeAll()
        UserDefaults.standard.removeObject(forKey: "qrex.history")
        historyEnabled = true
        lightMode = false
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "qrex.history")
        }
    }
}
