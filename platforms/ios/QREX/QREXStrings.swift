import Foundation

enum QREXStrings {
    static let supported: [String] = ["en", "hr", "de", "fr", "es", "it", "pt", "nl", "pl", "cs", "sk", "sl", "hu", "ro", "bg", "el", "tr", "uk", "ru", "sv", "da", "fi", "nb"]
    static func text(_ key: String, language: String) -> String {
        let code = language == "system" ? (Locale.preferredLanguages.first ?? "en")
            .components(separatedBy: "-").first ?? "en" : language
        let selected = Bundle.main.path(forResource: code, ofType: "lproj")
            .flatMap(Bundle.init(path:))
        let english = Bundle.main.path(forResource: "en", ofType: "lproj")
            .flatMap(Bundle.init(path:))
        return selected?.localizedString(forKey: key, value: nil, table: nil)
            ?? english?.localizedString(forKey: key, value: nil, table: nil) ?? key
    }
}

func tr(_ key: String) -> String {
    QREXStrings.text(key, language: UserDefaults.standard.string(forKey: "qrex.language") ?? "en")
}
