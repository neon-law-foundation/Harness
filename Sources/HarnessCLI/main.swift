import Foundation

let arguments = CommandLine.arguments

func printUsage() {
    print(
        """
        Usage: harness <command> [arguments]

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
          ddl                 Print CREATE TABLE statements for all schema tables
          list questions      List all seeded questions with their prompts
          list jurisdictions  List all seeded jurisdictions with their types
          list templates      List all seeded notation templates with their titles
          show template <code>  Show full content of a notation template by code

        Options:
          --help, -h          Show this help message
          --version, -v       Show version information

        Examples:
          harness lint .
          harness import ./notations
          harness pdf nevada.md
          harness edit nevada.md
          harness save nevada.md
          harness format nevada.md
          harness ddl
          harness list questions
          harness list jurisdictions
          harness list templates
          harness show template nevada_trust
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

        case "import":
            let directoryPath = arguments.count > 2 ? arguments[2] : "."
            command = ImportCommand(directoryPath: directoryPath)

        case "pdf":
            guard arguments.count > 2 else {
                print("Error: Missing file argument for pdf command")
                print("Usage: harness pdf <file>")
                exit(1)
            }
            let filePath = arguments[2]
            command = PDFCommand(inputPath: filePath)

        case "edit":
            guard arguments.count > 2 else {
                print("Error: Missing file argument for edit command")
                print("Usage: harness edit <file>")
                exit(1)
            }
            let filePath = arguments[2]
            command = EditCommand(filePath: filePath)

        case "save":
            guard arguments.count > 2 else {
                print("Error: Missing file argument for save command")
                print("Usage: harness save <file>")
                exit(1)
            }
            let filePath = arguments[2]
            command = SaveCommand(filePath: filePath)

        case "format":
            guard arguments.count > 2 else {
                print("Error: Missing file argument for format command")
                print("Usage: harness format <file>")
                exit(1)
            }
            let filePath = arguments[2]
            command = FormatCommand(filePath: filePath)

        case "ddl":
            command = DDLCommand()

        case "list":
            let subCommand = arguments.count > 2 ? arguments[2] : ""
            switch subCommand {
            case "questions":
                command = QuestionsListCommand()
            case "jurisdictions":
                command = JurisdictionsListCommand()
            case "templates":
                command = TemplatesListCommand()
            default:
                print("Error: Unknown list subcommand: '\(subCommand)'")
                print("Usage: harness list <questions|jurisdictions|templates>")
                exit(1)
            }

        case "show":
            let subCommand = arguments.count > 2 ? arguments[2] : ""
            switch subCommand {
            case "template":
                guard arguments.count > 3 else {
                    print("Error: Missing code argument for show template command")
                    print("Usage: harness show template <code>")
                    exit(1)
                }
                command = ShowTemplateCommand(code: arguments[3])
            default:
                print("Error: Unknown show subcommand: '\(subCommand)'")
                print("Usage: harness show template <code>")
                exit(1)
            }

        case "--help", "-h":
            printUsage()
            exit(0)

        case "--version", "-v":
            print("harness version dev (built from source)")
            print("https://github.com/neon-law-foundation/Harness")
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
