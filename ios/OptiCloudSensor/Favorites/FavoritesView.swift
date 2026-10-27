import SensorCore
import SwiftUI

/// Pages of the optiCLOUD web application, opened in Safari (see `docs/spec/favorites.md`): the default dashboard or
/// the home view, the favorites of the web application, and the favorites on this phone.
struct FavoritesView: View {
    @Environment(AppModel.self) private var app
    @Environment(SensorService.self) private var service
    @Environment(\.openURL) private var openURL
    @State private var model = FavoritesModel()
    @State private var picker: Picker?
    @State private var page: OpenPage?

    private struct OpenPage: Identifiable {
        let favorite: Favorite
        let url: URL
        var id: URL { url }
    }

    private enum Picker: String, Identifiable {
        case dashboard, device
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    FavoriteRow(favorite: first, action: open)
                        .contextMenu {
                            if service.settings.dashboard != nil {
                                Button("Remove Default Dashboard", systemImage: "star.slash") {
                                    service.setDefaultDashboard(nil)
                                }
                                .disabled(isDashboardManaged)
                            }
                        }
                } footer: {
                    if isDashboardManaged {
                        Text("optiCLOUD manages the default dashboard of this device.")
                    }
                }

                if app.isSignedIn {
                    Section {
                        if model.webFavorites.isEmpty {
                            Text(model.isLoading ? "Loading …" : "You have no favorites in optiCLOUD yet.")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(model.webFavorites) { favorite in
                            FavoriteRow(favorite: favorite, action: open)
                                .contextMenu { menu(for: favorite) }
                        }
                    } header: {
                        Text("In optiCLOUD")
                    } footer: {
                        if let problem = model.problem {
                            Text(problem)
                        } else {
                            Text("Change these favorites in the optiCLOUD web application.")
                        }
                    }

                    Section {
                        if model.phoneFavorites.isEmpty {
                            Text("Add dashboards and devices with +.")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(model.phoneFavorites) { favorite in
                            FavoriteRow(favorite: favorite, action: open)
                                .contextMenu { menu(for: favorite) }
                        }
                        .onDelete { model.remove(at: $0) }
                        .onMove { model.move(from: $0, to: $1) }
                    } header: {
                        Text("On This Phone")
                    } footer: {
                        Text("Pages of optiCLOUD open in the app, signed in with your account.")
                    }
                } else {
                    Section {
                        Text("Sign in to see your favorites from optiCLOUD and to add your own.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Favorites")
            .toolbar {
                if app.isSignedIn {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                            .disabled(model.phoneFavorites.isEmpty)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        addMenu
                    }
                }
            }
            .refreshable { await refresh() }
            .task(id: refreshKey) { await refresh() }
            .fullScreenCover(item: $page) { page in
                WebPageView(favorite: page.favorite, url: page.url, client: app.client)
            }
            .sheet(item: $picker) { picker in
                NavigationStack {
                    switch picker {
                    case .dashboard: DashboardPickerView(client: app.client, model: model)
                    case .device: DevicePickerView(client: app.client, model: model)
                    }
                }
            }
        }
    }

    private var addMenu: some View {
        Menu("Add", systemImage: "plus") {
            Button("Dashboard …", systemImage: "rectangle.3.group") { picker = .dashboard }
            Button("Device …", systemImage: "sensor") { picker = .device }
            Divider()
            if let device = app.device {
                fixedButton(.device(id: device.id, title: device.name), String(localized: "Device of This Phone"), "iphone")
            }
            fixedButton(Favorite(title: String(localized: "Dashboards"), path: "/dashboards"), String(localized: "Dashboard List"), "list.bullet")
            fixedButton(Favorite(title: String(localized: "Devices"), path: "/devices"), String(localized: "Device List"), "list.bullet")
        }
    }

    private func fixedButton(_ favorite: Favorite, _ title: String, _ symbol: String) -> some View {
        Button(title, systemImage: symbol) { model.add(favorite) }
            .disabled(model.contains(favorite))
    }

    @ViewBuilder
    private func menu(for favorite: Favorite) -> some View {
        if let id = favorite.dashboardId, id != service.settings.dashboard {
            Button("Set as Default Dashboard", systemImage: "star") {
                service.setDefaultDashboard(id)
            }
            .disabled(isDashboardManaged)
        }
        if !model.contains(favorite), model.webFavorites.contains(favorite) {
            Button("Add to This Phone", systemImage: "plus") { model.add(favorite) }
        }
    }

    /// The default dashboard, or the home view without one.
    private var first: Favorite {
        guard let id = service.settings.dashboard else {
            return Favorite(title: String(localized: "optiCLOUD Home"), path: Favorite.home.path)
        }
        return .dashboard(id: id, title: model.defaultDashboardTitle ?? String(localized: "Default Dashboard"))
    }

    private var isDashboardManaged: Bool { service.settings.managed.contains("dashboard") }

    /// The lists are read again when the session or the default dashboard changes.
    private var refreshKey: String {
        "\(app.isSignedIn) \(service.settings.dashboard ?? "")"
    }

    private func refresh() async {
        await model.refresh(client: app.client, address: app.address, defaultDashboard: service.settings.dashboard)
    }

    /// A page of the web application opens signed in, in the app; another page opens in Safari.
    private func open(_ favorite: Favorite) {
        guard let url = app.address.pageURL(path: favorite.path) else { return }
        if favorite.kind == .external {
            openURL(url)
        } else {
            page = OpenPage(favorite: favorite, url: url)
        }
    }
}

private struct FavoriteRow: View {
    let favorite: Favorite
    let action: (Favorite) -> Void

    var body: some View {
        Button {
            action(favorite)
        } label: {
            HStack {
                Label(favorite.title, systemImage: favorite.kind.symbol)
                Spacer()
                if favorite.kind == .external {
                    Image(systemName: "arrow.up.forward")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .accessibilityLabel("Opens in Safari")
                }
            }
        }
        .foregroundStyle(.primary)
    }
}

extension Favorite.Kind {
    var symbol: String {
        switch self {
        case .home: "house"
        case .dashboard: "rectangle.3.group"
        case .dashboardList, .deviceList: "list.bullet"
        case .device: "sensor"
        case .page: "doc.text"
        case .external: "globe"
        }
    }
}

/// The dashboards of the project of the session, to add one to the favorites on this phone.
private struct DashboardPickerView: View {
    let client: OptiCloudClient?
    let model: FavoritesModel
    @Environment(\.dismiss) private var dismiss
    @State private var dashboards: [DashboardInfo] = []
    @State private var search = ""
    @State private var isLoading = true
    @State private var problem: String?

    var body: some View {
        List {
            if let problem {
                Text(problem).foregroundStyle(.red)
            } else if !isLoading && dashboards.isEmpty {
                Text("There is no dashboard in this project.").foregroundStyle(.secondary)
            }
            ForEach(dashboards) { dashboard in
                let favorite = Favorite.dashboard(id: dashboard.id, title: dashboard.title)
                PickerRow(title: dashboard.title, symbol: Favorite.Kind.dashboard.symbol, isAdded: model.contains(favorite)) {
                    model.add(favorite)
                    dismiss()
                }
            }
        }
        .overlay { if isLoading { ProgressView() } }
        .searchable(text: $search)
        .task(id: search) { await load() }
        .navigationTitle("Dashboards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) { dismiss() }
            }
        }
    }

    private func load() async {
        guard let client, let projectId = await client.claims?.projectId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            dashboards = try await client.dashboards(projectId: projectId, textSearch: search)
            problem = nil
        } catch is CancellationError {
        } catch {
            problem = error.localizedDescription
        }
    }
}

/// The devices of the project of the session, of every type, to add one to the favorites on this phone.
private struct DevicePickerView: View {
    let client: OptiCloudClient?
    let model: FavoritesModel
    @Environment(\.dismiss) private var dismiss
    @State private var devices: [Device] = []
    @State private var search = ""
    @State private var isLoading = true
    @State private var problem: String?

    var body: some View {
        List {
            if let problem {
                Text(problem).foregroundStyle(.red)
            } else if !isLoading && devices.isEmpty {
                Text("There is no device in this project.").foregroundStyle(.secondary)
            }
            ForEach(devices) { device in
                let favorite = Favorite.device(id: device.id, title: device.name)
                PickerRow(title: device.name, symbol: Favorite.Kind.device.symbol, isAdded: model.contains(favorite)) {
                    model.add(favorite)
                    dismiss()
                }
            }
        }
        .overlay { if isLoading { ProgressView() } }
        .searchable(text: $search)
        .task(id: search) { await load() }
        .navigationTitle("Devices")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) { dismiss() }
            }
        }
    }

    private func load() async {
        guard let client, let projectId = await client.claims?.projectId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            devices = try await client.devices(projectId: projectId, textSearch: search)
            problem = nil
        } catch is CancellationError {
        } catch {
            problem = error.localizedDescription
        }
    }
}

private struct PickerRow: View {
    let title: String
    let symbol: String
    let isAdded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: symbol)
                Spacer()
                if isAdded {
                    Image(systemName: "checkmark").foregroundStyle(.tint)
                }
            }
        }
        .foregroundStyle(.primary)
        .disabled(isAdded)
    }
}
