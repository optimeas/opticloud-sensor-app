import SwiftUI

/// Version, source, and the licenses of the packages the app uses.
struct AboutView: View {
    private let version: String = {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""
        return "\(short) (\(build))"
    }()

    /// The user manual in the language the app is shown in. It lives in `docs/manual/` until it is published in the
    /// optiMEAS documentation.
    private let manual: URL = {
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        let folder = ["de", "en", "fr", "it", "es"].contains(language) ? language : "en"
        return URL(string: "\(PackageLicense.app.url)/blob/main/docs/manual/\(folder)/index.md")!
    }()

    var body: some View {
        List {
            Section {
                NavigationLink {
                    WelcomeView(screen: .welcome)
                } label: {
                    Label("Welcome", systemImage: "hand.wave")
                }
                NavigationLink {
                    VersionHistoryView()
                } label: {
                    Label("Version History", systemImage: "clock.arrow.circlepath")
                }
            }
            Section {
                LabeledContent("Version", value: version)
                Link(destination: manual) {
                    Label("User Manual", systemImage: "book")
                }
                Link(destination: URL(string: PackageLicense.app.url)!) {
                    Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                NavigationLink {
                    LicenseView(package: .app)
                } label: {
                    Label("License", systemImage: "doc.text")
                }
            } footer: {
                Text("optiCLOUD Sensor by optiMEAS is open source under the MIT license.")
            }
            Section("Open Source Licenses") {
                ForEach(PackageLicense.all) { package in
                    NavigationLink {
                        LicenseView(package: package)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(package.name)
                            Text("\(package.version) · \(package.license)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("About")
    }
}

private struct LicenseView: View {
    let package: PackageLicense

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Link(package.url, destination: URL(string: package.url)!)
                    .font(.footnote)
                if let notice = package.notice {
                    Text(notice)
                        .font(.footnote.monospaced())
                }
                Text(package.text)
                    .font(.footnote.monospaced())
            }
            .textSelection(.enabled)
            .padding()
        }
        .navigationTitle(package.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// One package of `Licenses.json`, written by `ios/Tools/generate-licenses.py`.
struct PackageLicense: Decodable, Identifiable {
    let name: String
    let url: String
    let version: String
    let license: String
    let notice: String?
    let text: String

    var id: String { name }

    /// The license of the app itself, `License.txt`, a copy of the repository's `LICENSE`.
    static let app = PackageLicense(
        name: "optiCLOUD Sensor",
        url: "https://github.com/optimeas/opticloud-sensor-app",
        version: "",
        license: "MIT License",
        notice: nil,
        text: Bundle.main.url(forResource: "License", withExtension: "txt")
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
    )

    static let all: [PackageLicense] = {
        guard let url = Bundle.main.url(forResource: "Licenses", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return [] }
        return (try? JSONDecoder().decode([PackageLicense].self, from: data)) ?? []
    }()
}
