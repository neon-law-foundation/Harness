import Foundation

let arguments = CommandLine.arguments

func printUsage() {
    print(
        """
        Usage: standards <command> [arguments]

        Commands:
          lint <directory>    Validate Markdown files have lines ≤120 characters
          import <directory>  Import validated Markdown notations to database (macOS only)
                              Auto-detects git repository and commit SHA
                              Requires clean working tree (no uncommitted changes)
          pdf <file>          Convert a standard Markdown file to PDF
                              Validates the file first, strips frontmatter, and outputs to .pdf
          edit <file>         Open standard file for editing in TextEdit (macOS only)
                              Creates temp file with joined lines for easier editing
          save <file>         Save edited temp file back to original (macOS only)
                              Restores front matter and saves to original location
          format <file>       Format a Markdown file
                              Converts '-' bullet lists to '*', wraps at 120 chars, trims whitespace

        Options:
          --help, -h          Show this help message
          --version, -v       Show version information

        Examples:
          standards lint .
          standards import ./notations
          standards pdf nevada.md
          standards edit nevada.md
          standards save nevada.md
          standards format nevada.md
        """
    )
}

Task {
    do {
        guard arguments.count > 1 else {
            printUsage()
            exit(1)
        }

        let commandName = arguments[1]
        let command: Command

        switch commandName {
        case "lint":
            let directoryPath = arguments.count > 2 ? arguments[2] : "."
            command = LintCommand(directoryPath: directoryPath)

        #if os(macOS)
        case "import":
            let directoryPath = arguments.count > 2 ? arguments[2] : "."
            command = ImportCommand(directoryPath: directoryPath)
        #endif

        case "pdf":
            guard arguments.count > 2 else {
                print("Error: Missing file argument for pdf command")
                print("Usage: standards pdf <file>")
                exit(1)
            }
            let filePath = arguments[2]
            command = PDFCommand(inputPath: filePath)

        case "edit":
            guard arguments.count > 2 else {
                print("Error: Missing file argument for edit command")
                print("Usage: standards edit <file>")
                exit(1)
            }
            let filePath = arguments[2]
            command = EditCommand(filePath: filePath)

        case "save":
            guard arguments.count > 2 else {
                print("Error: Missing file argument for save command")
                print("Usage: standards save <file>")
                exit(1)
            }
            let filePath = arguments[2]
            command = SaveCommand(filePath: filePath)

        case "format":
            guard arguments.count > 2 else {
                print("Error: Missing file argument for format command")
                print("Usage: standards format <file>")
                exit(1)
            }
            let filePath = arguments[2]
            command = FormatCommand(filePath: filePath)

        case "--help", "-h":
            printUsage()
            exit(0)

        case "--version", "-v":
            print("standards version dev (built from source)")
            print("https://github.com/neon-law-foundation/SagebrushStandards")
            exit(0)

        default:
            throw CommandError.unknownCommand(commandName)
        }

        try await command.run()
        exit(0)
    } catch let error as CommandError {
        switch error {
        case .lintFailed:
            exit(1)
        default:
            print("Error: \(error.localizedDescription)")
            exit(1)
        }
    } catch {
        print("Error: \(error.localizedDescription)")
        exit(1)
    }
}

dispatchMain()
