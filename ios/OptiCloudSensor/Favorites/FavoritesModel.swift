import Foundation
import Observation
import SensorCore

/// The favorites of the tab Favorites (see `docs/spec/favorites.md`): those the user keeps in the web application,
/// read from optiCLOUD, and those picked on this phone. Both lists are kept in UserDefaults; they hold no secret.
@Observable
final class FavoritesModel {
    /// The favorites from the web application, as last read.
    private(set) var webFavorites: [Favorite] = []
    /// The favorites on this phone, for the address and tenant of the session.
    private(set) var phoneFavorites: [Favorite] = []
    /// The title of the default dashboard, once read.
    private(set) var defaultDashboardTitle: String?
    private(set) var isLoading = false
    private(set) var problem: String?

    @ObservationIgnored private let defaults: UserDefaults
    /// Where the lists are kept: per address and user, and per address and tenant.
    @ObservationIgnored private var webKey: String?
    @ObservationIgnored private var phoneKey: String?
    @ObservationIgnored private var titledDashboard: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Reads the claims of the session, the kept lists, and then the favorites and the title of the default dashboard
    /// from optiCLOUD. Without a session only the kept favorites from the web application are cleared.
    func refresh(client: OptiCloudClient?, address: ServerAddress, defaultDashboard: String?) async {
        guard let client, let claims = await client.claims else {
            webKey = nil
            phoneKey = nil
            webFavorites = []
            phoneFavorites = []
            return
        }
        webKey = "webFavorites.\(address.host).\(claims.userId ?? "")"
        phoneKey = "phoneFavorites.\(address.host).\(claims.tenantId ?? "")"
        webFavorites = load(webKey)
        phoneFavorites = load(phoneKey)
        if defaultDashboard != titledDashboard { defaultDashboardTitle = nil }

        isLoading = true
        defer { isLoading = false }
        do {
            let favorites = try await client.webFavorites().filter { address.pageURL(path: $0.path) != nil }
            webFavorites = favorites
            save(favorites, webKey)
            problem = nil
        } catch {
            problem = error.localizedDescription
        }
        if let defaultDashboard, defaultDashboardTitle == nil {
            defaultDashboardTitle = try? await client.dashboard(id: defaultDashboard).title
            titledDashboard = defaultDashboard
        }
    }

    func contains(_ favorite: Favorite) -> Bool {
        phoneFavorites.contains { $0.path == favorite.path }
    }

    func add(_ favorite: Favorite) {
        guard !contains(favorite) else { return }
        phoneFavorites.append(favorite)
        save(phoneFavorites, phoneKey)
    }

    func remove(at offsets: IndexSet) {
        phoneFavorites.remove(atOffsets: offsets)
        save(phoneFavorites, phoneKey)
    }

    func move(from source: IndexSet, to destination: Int) {
        phoneFavorites.move(fromOffsets: source, toOffset: destination)
        save(phoneFavorites, phoneKey)
    }

    private func load(_ key: String?) -> [Favorite] {
        guard let key, let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Favorite].self, from: data)) ?? []
    }

    private func save(_ favorites: [Favorite], _ key: String?) {
        guard let key else { return }
        defaults.set(try? JSONEncoder().encode(favorites), forKey: key)
    }
}
