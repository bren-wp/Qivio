import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

enum QREXColors {
    static let background = Color(red: 3/255, green: 12/255, blue: 27/255)
    static let card = Color(red: 16/255, green: 27/255, blue: 44/255)
    static let cyan = Color(red: 16/255, green: 197/255, blue: 250/255)
    static let purple = Color(red: 144/255, green: 71/255, blue: 248/255)
}

struct ResultPayload: Identifiable {
    let raw: String
    var id: String { raw }
}

enum QREXImage {
    static func qr(_ raw: String) -> UIImage? {
        guard QRContent.isSupported(raw) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(raw.utf8)
        filter.correctionLevel = "M"
        let context = CIContext()
        guard let image = filter.outputImage,
              let cgImage = context.createCGImage(image.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
                                                  from: image.extent.applying(CGAffineTransform(scaleX: 10, y: 10)))
        else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

@main
struct QREXApp: App {
    @StateObject private var store = QREXStore()

    var body: some Scene {
        WindowGroup {
            QREXRoot().environmentObject(store)
                .preferredColorScheme(store.lightMode ? .light : .dark)
        }
    }
}

struct QREXRoot: View {
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            ScanScreen().tabItem { Label("Skeniraj", systemImage: "qrcode.viewfinder") }.tag(0)
            CreateScreen().tabItem { Label("Stvori", systemImage: "plus.app") }.tag(1)
            HistoryScreen().tabItem { Label("Povijest", systemImage: "clock.arrow.circlepath") }.tag(2)
            MoreScreen().tabItem { Label("Više", systemImage: "square.grid.2x2") }.tag(3)
        }
        .tint(QREXColors.cyan)
    }
}

struct ResultScreen: View {
    @EnvironmentObject private var store: QREXStore
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    let raw: String
    @State private var showPassword = false
    @State private var showQR = false
    @State private var confirmSaveWifi = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 58)).foregroundStyle(QREXColors.cyan)
                    Text("Skeniranje završeno").font(.title2.bold())
                    VStack(alignment: .leading, spacing: 12) {
                        if QRContent.isWifi(raw) {
                            Text("Mreža: \(QRContent.wifiField(raw, key: "S") ?? "Wi-Fi")")
                                .font(.headline)
                            HStack {
                                Text(showPassword ? "Lozinka: \(QRContent.wifiField(raw, key: "P") ?? "")" : "Lozinka: ••••••••")
                                Spacer()
                                Button { showPassword.toggle() } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                }
                                .accessibilityLabel(showPassword ? "Sakrij lozinku" : "Prikaži lozinku")
                            }
                        } else {
                            Text(raw).textSelection(.enabled)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18).background(QREXColors.card, in: RoundedRectangle(cornerRadius: 20))
                    if let url = QRContent.safeURL(raw) {
                        Text("Provjeri adresu prije otvaranja.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Otvori poveznicu") { openURL(url) }
                            .buttonStyle(.borderedProminent)
                    }
                    HStack {
                        Button("Kopiraj") { UIPasteboard.general.string = raw }.buttonStyle(.bordered)
                        ShareLink(item: raw) { Label("Podijeli", systemImage: "square.and.arrow.up") }
                            .buttonStyle(.bordered)
                    }
                    Button("Prikaži QR kod") { showQR = true }
                        .disabled(!QRContent.isSupported(raw))
                    Button(store.items.contains(where: { $0.raw == raw && $0.saved }) ? "Spremljeno" : "Spremi") {
                        if QRContent.isWifi(raw) {
                            confirmSaveWifi = true
                        } else { store.save(raw) }
                    }.disabled(store.items.contains(where: { $0.raw == raw && $0.saved }))
                        .buttonStyle(.borderedProminent)
                }
                .padding(24)
            }
            .navigationTitle("Rezultat")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Zatvori") { dismiss() } } }
            .sheet(isPresented: $showQR) {
                if let image = QREXImage.qr(raw) {
                    VStack(spacing: 22) {
                        Text("QR kod").font(.title2.bold())
                        Image(uiImage: image).interpolation(.none).resizable()
                            .scaledToFit().frame(width: 240, height: 240)
                        Button("Zatvori") { showQR = false }
                    }.padding()
                }
            }
            .confirmationDialog("Wi-Fi kod može sadržavati lozinku koja će biti lokalno spremljena.",
                isPresented: $confirmSaveWifi) {
                    Button("Spremi") { store.save(raw) }
                    Button("Odustani", role: .cancel) {}
                }
        }
    }
}

struct CreateScreen: View {
    @EnvironmentObject private var store: QREXStore
    @State private var kind = 0
    @State private var content = ""
    @State private var password = ""
    @State private var revealPassword = false
    @State private var showMore = false
    @State private var showResult = false
    private let choices = ["Poveznica", "Tekst", "Wi-Fi", "E-mail", "Telefon", "Lokacija", "Kontakt"]

    private var raw: String {
        let input = content.trimmingCharacters(in: .whitespacesAndNewlines)
        switch kind {
        case 0: return QRContent.safeURL(input) != nil ? input : ""
        case 1: return input
        case 2: return input.isEmpty ? "" : QRContent.wifi(ssid: input, password: password)
        case 3: return input.contains("@") && !input.contains("\n") ? "mailto:\(input)" : ""
        case 4: return input.isEmpty ? "" : "tel:\(input)"
        case 5: return input.isEmpty ? "" : "geo:\(input)"
        default: return input.isEmpty ? "" : "BEGIN:VCARD\nVERSION:3.0\nFN:\(input.replacingOccurrences(of: "\n", with: " "))\nEND:VCARD"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Stvori QR kod").font(.largeTitle.bold())
                    Text("Odaberi vrstu i unesi podatke.").foregroundStyle(.secondary)
                    Picker("Vrsta", selection: $kind) {
                        ForEach(0..<(showMore ? choices.count : 3), id: \.self) { i in
                            Text(choices[i]).tag(i)
                        }
                    }.pickerStyle(.menu)
                    Button(showMore ? "Manje mogućnosti" : "Više mogućnosti") {
                        showMore.toggle()
                        if !showMore && kind > 2 { kind = 0 }
                    }.font(.footnote)
                    TextField(choices[kind], text: $content, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding().background(QREXColors.card, in: RoundedRectangle(cornerRadius: 14))
                    if kind == 2 {
                        HStack {
                            Group {
                                if revealPassword {
                                    TextField("Lozinka (neobavezno)", text: $password)
                                } else {
                                    SecureField("Lozinka (neobavezno)", text: $password)
                                }
                            }
                            Button { revealPassword.toggle() } label: {
                                Image(systemName: revealPassword ? "eye.slash" : "eye")
                            }
                        }.padding().background(QREXColors.card, in: RoundedRectangle(cornerRadius: 14))
                        Text("Wi-Fi QR kod može sadržavati lozinku.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if let image = QREXImage.qr(raw) {
                        Image(uiImage: image).interpolation(.none).resizable()
                            .scaledToFit().frame(width: 238, height: 238)
                            .padding(16).background(.white, in: RoundedRectangle(cornerRadius: 20))
                        Button("Spremi kod") { store.save(raw) }.buttonStyle(.bordered)
                        Button("Prikaži i podijeli") { showResult = true }.buttonStyle(.borderedProminent)
                    } else {
                        ContentUnavailableView("Unesi valjan QR sadržaj", systemImage: "qrcode")
                    }
                }.padding(20)
            }
            .background(QREXColors.background)
            .navigationTitle("Stvori")
            .sheet(isPresented: $showResult) { ResultScreen(raw: raw) }
        }
    }
}

struct HistoryScreen: View {
    @EnvironmentObject private var store: QREXStore
    @State private var search = ""
    @State private var selected: ResultPayload?

    private var filtered: [QRHistoryItem] {
        store.items.filter { search.isEmpty || QRContent.title($0.raw)
            .localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { item in
                    Button {
                        selected = ResultPayload(raw: item.raw)
                    } label: {
                        HStack {
                            Image(systemName: item.saved ? "bookmark.fill" : "qrcode")
                                .foregroundStyle(QREXColors.cyan)
                            VStack(alignment: .leading) {
                                Text(QRContent.title(item.raw)).lineLimit(2)
                                Text(item.timestamp.formatted()).font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }.swipeActions {
                        Button(role: .destructive) { store.delete(item) } label: {
                            Label("Izbriši", systemImage: "trash")
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Pretraži QR kodove")
            .navigationTitle("Povijest")
            .overlay {
                if filtered.isEmpty {
                    ContentUnavailableView("Nema spremljenih kodova", systemImage: "clock")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Očisti") { store.clearHistory() }.disabled(store.items.isEmpty)
                }
            }
            .sheet(item: $selected) { item in ResultScreen(raw: item.raw) }
        }
    }
}

struct MoreScreen: View {
    @EnvironmentObject private var store: QREXStore
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Postavke") {
                    Toggle("Spremanje povijesti", isOn: $store.historyEnabled)
                    Toggle("Svijetli izgled", isOn: $store.lightMode)
                    Button("Izbriši sve podatke", role: .destructive) { confirmDelete = true }
                }
                Section("Privatnost") {
                    NavigationLink("Pravila privatnosti") {
                        ScrollView {
                            Text("QREX obrađuje QR kodove lokalno. Ne zahtijeva prijavu, ne koristi oglase ni sustav analitike. Skenirani sadržaji mogu ostati u lokalnoj povijesti ako je uključena. Wi-Fi kodovi ne spremaju se automatski. Ručno spremanje Wi-Fi koda pohranjuje i njegovu lozinku. Kada otvoriš vanjsku poveznicu ili podijeliš sadržaj, podatke može obraditi druga aplikacija. Sve spremljene podatke možeš izbrisati u postavkama. Za pitanja o privatnosti kontaktiraj Brendigo putem brendigo.com.")
                                .padding()
                        }.navigationTitle("Pravila privatnosti")
                    }
                }
                Section("O aplikaciji") {
                    LabeledContent("Aplikacija", value: "QREX")
                    Link(destination: URL(string: "https://brendigo.com")!) {
                        Label("Razvio Brendigo", systemImage: "chevron.up.right.square")
                    }
                }
            }
            .navigationTitle("Više")
            .confirmationDialog("Izbrisati svu povijest, spremljene kodove i postavke?",
                isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Izbriši sve", role: .destructive) { store.clearAll() }
                Button("Odustani", role: .cancel) {}
            }
        }
    }
}
