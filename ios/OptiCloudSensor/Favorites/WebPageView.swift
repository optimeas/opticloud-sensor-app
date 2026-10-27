import SensorCore
import SwiftUI
import WebKit

/// A page of the optiCLOUD web application in a browser view of the app, signed in with a session of its own
/// (see `docs/spec/favorites.md`, Opening a page). The view keeps no website data on the phone: the session lives
/// only while the view is open.
struct WebPageView: View {
    let favorite: Favorite
    let url: URL
    let client: OptiCloudClient?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var session: TokenPair?
    @State private var isPreparing = true
    @State private var webView: WKWebView?

    var body: some View {
        NavigationStack {
            Group {
                if isPreparing {
                    ProgressView()
                } else {
                    WebView(url: url, session: session, webView: $webView)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
            .navigationTitle(favorite.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Back", systemImage: "chevron.backward") { webView?.goBack() }
                    Button("Reload", systemImage: "arrow.clockwise") { webView?.reload() }
                    Spacer()
                    Button("Open in Safari", systemImage: "safari") {
                        openURL(webView?.url ?? url)
                    }
                }
            }
        }
        .task {
            // Without a session of the app the page opens with the sign-in of the web application.
            session = try? await client?.webSession()
            isPreparing = false
        }
    }
}

private struct WebView: UIViewRepresentable {
    let url: URL
    let session: TokenPair?
    @Binding var webView: WKWebView?

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        if let session, let script = Self.sessionScript(session, for: url) {
            configuration.userContentController.addUserScript(
                WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            )
        }
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.allowsBackForwardNavigationGestures = true
        view.load(URLRequest(url: url))
        DispatchQueue.main.async { webView = view }
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {}

    /// Writes the session into the local storage of the web application before its own scripts run, only on pages
    /// of the address it belongs to, and only at the first load: later the web application renews the tokens itself,
    /// and a sign-out in the view stays a sign-out.
    private static func sessionScript(_ session: TokenPair, for url: URL) -> String? {
        guard let scheme = url.scheme, let host = url.host() else { return nil }
        let origin = url.port.map { "\(scheme)://\(host):\($0)" } ?? "\(scheme)://\(host)"
        let payload: [String: Any] = ["origin": origin, "entries": WebSessionStorage.entries(for: session)]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8)
        else { return nil }
        return """
            (function () {
              var session = \(json);
              if (window.location.origin !== session.origin) { return; }
              if (window.sessionStorage.getItem("opticloudSensorSession")) { return; }
              window.sessionStorage.setItem("opticloudSensorSession", "1");
              for (var key in session.entries) { window.localStorage.setItem(key, session.entries[key]); }
            })();
            """
    }
}
