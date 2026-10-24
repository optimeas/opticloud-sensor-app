import Foundation
import Testing

/// Checks that every vector file follows the format in `docs/spec/README.md`.
/// The cases themselves are run by the tests of each topic.
struct VectorFileTests {
    private struct VectorFile: Decodable {
        struct Case: Decodable {
            let name: String
        }

        let description: String
        let cases: [Case]
    }

    @Test func vectorDirectoryHasFiles() throws {
        #expect(try !TestVectors.fileNames().isEmpty)
    }

    @Test(arguments: try TestVectors.fileNames())
    func fileHasDescriptionAndNamedCases(name: String) throws {
        let file = try JSONDecoder().decode(VectorFile.self, from: TestVectors.data(name))
        #expect(!file.description.isEmpty)
        #expect(!file.cases.isEmpty)
        #expect(Set(file.cases.map(\.name)).count == file.cases.count, "case names are unique")
    }
}
