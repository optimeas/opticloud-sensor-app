import Foundation

/// The sensor selection: a list of group keys and item keys, separated by commas
/// (see `docs/spec/sensors.md`, Selection).
public struct Selection: Hashable, Sendable {
    /// The keys of the selected items, also of items the phone does not offer.
    public let itemKeys: Set<String>

    public init(itemKeys: Set<String>) {
        self.itemKeys = itemKeys
    }

    /// Reads a selection string. Returns nil if it contains an unknown key; such a selection is invalid as a whole.
    public init?(parsing text: String) {
        var keys: Set<String> = []
        for entry in text.split(separator: ",", omittingEmptySubsequences: false) {
            let key = entry.trimmingCharacters(in: .whitespaces)
            if key.isEmpty { continue }
            if let group = Catalog.group(key: key) {
                keys.formUnion(group.items.map(\.key))
            } else if Catalog.item(key: key) != nil {
                keys.insert(key)
            } else {
                return nil
            }
        }
        itemKeys = keys
    }

    /// The selected items the phone offers, in catalog order.
    public func items(offered: Set<String>) -> [CatalogItem] {
        Catalog.items.filter { itemKeys.contains($0.key) && offered.contains($0.key) }
    }

    /// The entries the app reports: a group key for each group that has at least one offered item
    /// and whose offered items are all selected, item keys for the rest. Only offered items count.
    public func reportedEntries(offered: Set<String>) -> [String] {
        var entries: [String] = []
        for group in Catalog.groups {
            let offeredItems = group.items.map(\.key).filter(offered.contains)
            let selectedItems = offeredItems.filter(itemKeys.contains)
            if !offeredItems.isEmpty && selectedItems.count == offeredItems.count {
                entries.append(group.key)
            } else {
                entries.append(contentsOf: selectedItems)
            }
        }
        return entries
    }

    /// The selection as it is reported, for example in the client attribute `sensors`.
    public func reported(offered: Set<String>) -> String {
        reportedEntries(offered: offered).joined(separator: ",")
    }
}

extension Selection {
    /// The default selection of `docs/spec/configuration.md`.
    public static let `default` = Selection(parsing: "device,location")!
}
