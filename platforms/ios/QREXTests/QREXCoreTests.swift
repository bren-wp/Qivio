import XCTest
@testable import QREX

final class QREXCoreTests: XCTestCase {
    func testAllLanguagesAreAvailable() {
        XCTAssertEqual(QREXStrings.supported.count, 23)
        for language in QREXStrings.supported {
            XCTAssertNotNil(Bundle.main.path(forResource: language, ofType: "lproj"))
            XCTAssertNotEqual(QREXStrings.text("scan", language: language), "scan")
        }
        XCTAssertEqual(QREXStrings.text("scan", language: "en"), "Scan")
        XCTAssertEqual(QREXStrings.text("scan", language: "hr"), "Skeniraj")
    }


    func testEscapedWifiFields() {
        let raw = QRContent.wifi(ssid: "Office;P:wrong", password: "a\\b:c")
        XCTAssertEqual(QRContent.wifiField(raw, key: "S"), "Office;P:wrong")
        XCTAssertEqual(QRContent.wifiField(raw, key: "P"), "a\\b:c")
    }

    func testUnsafeUrls() {
        XCTAssertNil(QRContent.safeURL("javascript:alert(1)"))
        XCTAssertNil(QRContent.safeURL("https://trusted.com@malicious.com"))
        XCTAssertNil(QRContent.safeURL("https://example.com/test path"))
        XCTAssertEqual(QRContent.safeURL("https://brendigo.com")?.host, "brendigo.com")
    }

    @MainActor
    func testKeychainHistoryNeverFallsBackToPlainPreferences() {
        let store = QREXStore()
        store.clearAll()
        let payload = QRContent.wifi(ssid: "Private Network", password: "never-in-defaults")
        store.save(payload)
        XCTAssertEqual(store.items.first?.raw, payload)
        XCTAssertNil(UserDefaults.standard.data(forKey: "qrex.history"))
        XCTAssertNotNil(QREXHistoryVault.read())
        store.clearAll()
        XCTAssertNil(QREXHistoryVault.read())
    }

    @MainActor
    func testNoAutomaticWifiHistory() {
        let store = QREXStore()
        store.clearAll()
        let raw = QRContent.wifi(ssid: "Home", password: "secret")
        store.record(raw)
        XCTAssertTrue(store.items.isEmpty)
        store.save(raw)
        XCTAssertEqual(store.items.count, 1)
        store.clearAll()
        XCTAssertTrue(store.items.isEmpty)
    }
}
