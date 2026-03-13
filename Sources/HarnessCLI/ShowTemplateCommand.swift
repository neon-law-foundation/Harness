import HarnessDAL

struct ShowTemplateCommand: Command {
    let code: String

    func run() async throws {
        let dbManager = try await DatabaseManager(seed: true)
        let database = dbManager.getDatabase()

        let service = NotationService(database: database)
        let notation = try await service.findLatestByCode(code)

        try await dbManager.shutdown()

        guard let notation = notation else {
            print("Template '\(code)' not found.")
            return
        }

        print("Code:           \(notation.code ?? "")")
        print("Title:          \(notation.title)")
        print("Description:    \(notation.description)")
        print("Respondent:     \(notation.respondentType.rawValue)")
        print("Version:        \(notation.version)")
        print("")
        print(notation.markdownContent)
    }
}
