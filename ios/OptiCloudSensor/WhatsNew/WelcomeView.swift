import SensorCore
import SwiftUI

/// The welcome screen for a new user and the screen "What's New" after an update (see `docs/spec/whats-new.md`).
/// Without `onContinue`, it is shown from the information about the app and has no button.
struct WelcomeView: View {
    let screen: StartScreen
    var onContinue: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                header
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(Array(highlights.enumerated()), id: \.element.id) { index, highlight in
                        HighlightRow(highlight: highlight, hasAppeared: hasAppeared)
                            .opacity(hasAppeared || reduceMotion ? 1 : 0)
                            .offset(y: hasAppeared || reduceMotion ? 0 : 16)
                            .animation(reduceMotion ? nil : .spring(duration: 0.6).delay(0.15 + 0.1 * Double(index)), value: hasAppeared)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                NavigationLink {
                    VersionHistoryView()
                } label: {
                    Label("Version History", systemImage: "clock.arrow.circlepath")
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 48)
            .padding(.bottom, 24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(alignment: .top) { backdrop }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if let onContinue {
                    Button(action: onContinue) {
                        Text(screen == .welcome ? "Get Started" : "Continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                }
                if screen == .welcome {
                    Text("optiCLOUD Sensor by optiMEAS is open source under the MIT license.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .background(.bar)
        }

        .navigationBarTitleDisplayMode(.inline)
        .onAppear { hasAppeared = true }
    }

    private var header: some View {
        VStack(spacing: 16) {
            Image("AppLogo")
                .resizable()
                .frame(width: 104, height: 104)
                .clipShape(.rect(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
                .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.8)
                .animation(reduceMotion ? nil : .spring(duration: 0.6, bounce: 0.4), value: hasAppeared)
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text(unbroken: screen == .welcome ? "Welcome to optiCLOUD Sensor" : "What’s New in optiCLOUD Sensor")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(screen == .welcome ? "Your iPhone as a sensor for optiCLOUD." : "Version \(ReleaseNotes.currentVersion)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    /// The colors of the logo, faded into the background.
    private var backdrop: some View {
        LinearGradient(
            colors: [Color(red: 0.29, green: 0.56, blue: 0.79).opacity(0.35), Color(red: 0.95, green: 0.57, blue: 0.0).opacity(0.08), .clear],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 420)
        .ignoresSafeArea()
    }

    private var highlights: [Highlight] {
        switch screen {
        case .welcome: ReleaseNotes.welcome
        case .whatsNew: ReleaseNotes.current?.highlights ?? ReleaseNotes.welcome
        }
    }
}

private struct HighlightRow: View {
    let highlight: Highlight
    let hasAppeared: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: highlight.symbol)
                .font(.title)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .symbolEffect(.bounce, value: hasAppeared)
                .frame(width: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(unbroken: highlight.title)
                    .font(.headline)
                Text(unbroken: highlight.text)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Welcome") {
    NavigationStack { WelcomeView(screen: .welcome, onContinue: {}) }
}

#Preview("What's New") {
    NavigationStack { WelcomeView(screen: .whatsNew, onContinue: {}) }
}

extension Text {
    /// Hyphenation splits "optiCLOUD" at the change of case into "opti-CLOUD". A word joiner there keeps the name
    /// whole; it is invisible and VoiceOver skips it.
    init(unbroken resource: LocalizedStringResource) {
        self.init(verbatim: String(localized: resource).replacing("optiCLOUD", with: "opti\u{2060}CLOUD"))
    }
}
