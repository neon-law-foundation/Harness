import Foundation
import Testing

@testable import HarnessCLI

@Suite("Claude Setup Command")
struct ClaudeSetupCommandTests {

    private func makeTestDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(
            "claude-setup-test-\(UUID())"
        )
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("Creates CLAUDE.md in the output directory")
    func testCreatesCLAUDEMd() async throws {
        let testDir = try makeTestDir()

        let command = ClaudeSetupCommand(outputDirectory: testDir.path)
        try await command.run()

        let claudeMdURL = testDir.appendingPathComponent("CLAUDE.md")
        #expect(FileManager.default.fileExists(atPath: claudeMdURL.path))

        try? FileManager.default.removeItem(at: testDir)
    }

    @Test("CLAUDE.md contains legal review header")
    func testContainsLegalReviewHeader() async throws {
        let testDir = try makeTestDir()

        let command = ClaudeSetupCommand(outputDirectory: testDir.path)
        try await command.run()

        let content = try String(
            contentsOf: testDir.appendingPathComponent("CLAUDE.md"),
            encoding: .utf8
        )
        #expect(content.contains("# Legal Review"))

        try? FileManager.default.removeItem(at: testDir)
    }

    @Test("CLAUDE.md contains IRAC methodology")
    func testContainsIRAC() async throws {
        let testDir = try makeTestDir()

        let command = ClaudeSetupCommand(outputDirectory: testDir.path)
        try await command.run()

        let content = try String(
            contentsOf: testDir.appendingPathComponent("CLAUDE.md"),
            encoding: .utf8
        )
        #expect(content.contains("**Issue**"))
        #expect(content.contains("**Rule**"))
        #expect(content.contains("**Analysis**"))
        #expect(content.contains("**Conclusion**"))

        try? FileManager.default.removeItem(at: testDir)
    }

    @Test("CLAUDE.md contains privileged and confidential notice")
    func testContainsPrivilegedNotice() async throws {
        let testDir = try makeTestDir()

        let command = ClaudeSetupCommand(outputDirectory: testDir.path)
        try await command.run()

        let content = try String(
            contentsOf: testDir.appendingPathComponent("CLAUDE.md"),
            encoding: .utf8
        )
        #expect(content.contains("PRIVILEGED AND CONFIDENTIAL"))

        try? FileManager.default.removeItem(at: testDir)
    }
}
