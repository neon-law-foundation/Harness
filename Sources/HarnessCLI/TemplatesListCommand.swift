import HarnessDAL

struct TemplatesListCommand: Command {
    func run() async throws {
        let dbManager = try await DatabaseManager(seed: true)
        let database = dbManager.getDatabase()

        let service = NotationService(database: database)
        let notations = try await service.findAllLatest()

        try await dbManager.shutdown()

        if notations.isEmpty {
            print("No templates found.")
            return
        }

        let sorted = notations.sorted { ($0.code ?? "") < ($1.code ?? "") }
        let maxCodeLength = sorted.map { ($0.code ?? "").count }.max() ?? 4
        let codeWidth = max(maxCodeLength, 4)
        let maxTitleLength = sorted.map(\.title.count).max() ?? 5
        let titleWidth = max(maxTitleLength, 5)

        let codeHeader = "Code".padding(toLength: codeWidth, withPad: " ", startingAt: 0)
        let titleHeader = "Title".padding(toLength: titleWidth, withPad: " ", startingAt: 0)
        print("\(codeHeader)  \(titleHeader)  Respondent Type")
        print(
            String(repeating: "-", count: codeWidth)
                + "  "
                + String(repeating: "-", count: titleWidth)
                + "  "
                + String(repeating: "-", count: 14)
        )

        for notation in sorted {
            let paddedCode = (notation.code ?? "").padding(
                toLength: codeWidth,
                withPad: " ",
                startingAt: 0
            )
            let paddedTitle = notation.title.padding(
                toLength: titleWidth,
                withPad: " ",
                startingAt: 0
            )
            print("\(paddedCode)  \(paddedTitle)  \(notation.respondentType.rawValue)")
        }
    }
}
