import SwiftUI

/// Every version of the app with its changes, newest first (see `docs/spec/whats-new.md`).
struct VersionHistoryView: View {
    var body: some View {
        List {
            ForEach(ReleaseNotes.all) { release in
                Section {
                    ForEach(release.changes) { change in
                        Label {
                            Text(unbroken: change.text)
                        } icon: {
                            Image(systemName: change.kind.symbol)
                                .foregroundStyle(change.kind.color)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("\(change.kind.title): \(String(localized: change.text))"))
                    }
                } header: {
                    Text(release.title)
                }
            }
        }
        .navigationTitle("Version History")
    }
}

extension Release {
    /// The version, the build when there was more than one, and the date.
    var title: String {
        let date = date.formatted(date: .abbreviated, time: .omitted)
        if let build {
            return String(localized: "Version \(version) (\(build)) · \(date)", comment: "Version, build, and date of a release")
        }
        return String(localized: "Version \(version) · \(date)", comment: "Version and date of a release")
    }
}

extension Change.Kind {
    var title: String {
        switch self {
        case .new: String(localized: "New", comment: "Kind of change in the version history")
        case .improved: String(localized: "Improved", comment: "Kind of change in the version history")
        case .fixed: String(localized: "Fixed", comment: "Kind of change in the version history")
        }
    }

    var symbol: String {
        switch self {
        case .new: "sparkles"
        case .improved: "arrow.up.circle.fill"
        case .fixed: "wrench.and.screwdriver.fill"
        }
    }

    var color: Color {
        switch self {
        case .new: .orange
        case .improved: .blue
        case .fixed: .green
        }
    }
}

#Preview {
    NavigationStack { VersionHistoryView() }
}
