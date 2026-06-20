import Foundation

final class RecipeImageStore {
    static let shared = RecipeImageStore()

    private let directoryURL: URL

    private init(fileManager: FileManager = .default) {
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory

        directoryURL = applicationSupport.appendingPathComponent(
            "DishRoller/RecipeImages",
            isDirectory: true
        )

        try? fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    func save(_ data: Data, recipeID: UUID, mimeType: String) -> String? {
        let fileExtension = mimeType.lowercased().contains("png") ? "png" : "jpg"
        let fileName = "\(recipeID.uuidString).\(fileExtension)"
        let fileURL = directoryURL.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    func data(for fileName: String?) -> Data? {
        guard let fileName else { return nil }
        return try? Data(contentsOf: directoryURL.appendingPathComponent(fileName))
    }
}
