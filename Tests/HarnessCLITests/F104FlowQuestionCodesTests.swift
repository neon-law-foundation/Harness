import Foundation
import HarnessRules
import Testing

@Suite("F104 Flow Question Codes")
struct F104FlowQuestionCodesTests {
    let validCodes: Set<String> = ["personal_name", "staff_review", "notarization", "person"]

    private func makeFile(content: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("F104Tests-\(UUID())")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let file = tempDir.appendingPathComponent("TestFile.md")
        try content.write(to: file, atomically: true, encoding: .utf8)
        return file
    }

    // MARK: - Pass cases

    @Test("Valid codes with labels pass")
    func testValidCodesWithLabels() throws {
        let content = """
            ---
            title: Test
            flow:
              BEGIN:
                _: person__trustee
              person__trustee:
                _: END
            alignment:
              BEGIN:
                _: notarization__for_trustee
              notarization__for_trustee:
                _: END
            ---
            """
        let file = try makeFile(content: content)
        let rule = F104_FlowQuestionCodes(validCodes: validCodes)
        let violations = try rule.validate(file: file)
        #expect(violations.isEmpty)
    }

    @Test("Valid codes without labels pass")
    func testValidCodesWithoutLabels() throws {
        let content = """
            ---
            title: Test
            flow:
              BEGIN:
                _: staff_review
              staff_review:
                _: END
            alignment:
              BEGIN:
                _: staff_review
              staff_review:
                _: END
            ---
            """
        let file = try makeFile(content: content)
        let rule = F104_FlowQuestionCodes(validCodes: validCodes)
        let violations = try rule.validate(file: file)
        #expect(violations.isEmpty)
    }

    @Test("Both flow and alignment valid pass")
    func testBothFlowAndAlignmentValid() throws {
        let content = """
            ---
            title: Test
            flow:
              BEGIN:
                _: personal_name
              personal_name:
                _: staff_review
              staff_review:
                _: END
            alignment:
              BEGIN:
                _: notarization__for_client
              notarization__for_client:
                yes: END
                _: person__trustee
              person__trustee:
                _: END
            ---
            """
        let file = try makeFile(content: content)
        let rule = F104_FlowQuestionCodes(validCodes: validCodes)
        let violations = try rule.validate(file: file)
        #expect(violations.isEmpty)
    }

    @Test("File with no frontmatter passes")
    func testNoFrontmatterPasses() throws {
        let content = """
            # Just a plain markdown file

            No frontmatter here.
            """
        let file = try makeFile(content: content)
        let rule = F104_FlowQuestionCodes(validCodes: validCodes)
        let violations = try rule.validate(file: file)
        #expect(violations.isEmpty)
    }

    // MARK: - Structural failures

    @Test("Missing flow key produces violation")
    func testMissingFlowKey() throws {
        let content = """
            ---
            title: Test
            alignment:
              BEGIN:
                _: staff_review
              staff_review:
                _: END
            ---
            """
        let file = try makeFile(content: content)
        let rule = F104_FlowQuestionCodes(validCodes: validCodes)
        let violations = try rule.validate(file: file)
        #expect(violations.count == 1)
        #expect(violations[0].message == "Missing required 'flow' key")
    }

    @Test("Missing alignment key produces violation")
    func testMissingAlignmentKey() throws {
        let content = """
            ---
            title: Test
            flow:
              BEGIN:
                _: staff_review
              staff_review:
                _: END
            ---
            """
        let file = try makeFile(content: content)
        let rule = F104_FlowQuestionCodes(validCodes: validCodes)
        let violations = try rule.validate(file: file)
        #expect(violations.count == 1)
        #expect(violations[0].message == "Missing required 'alignment' key")
    }

    @Test("flow missing BEGIN produces violation")
    func testFlowMissingBegin() throws {
        let content = """
            ---
            title: Test
            flow:
              staff_review:
                _: END
            alignment:
              BEGIN:
                _: staff_review
              staff_review:
                _: END
            ---
            """
        let file = try makeFile(content: content)
        let rule = F104_FlowQuestionCodes(validCodes: validCodes)
        let violations = try rule.validate(file: file)
        #expect(violations.contains { $0.message == "flow is missing required BEGIN state" })
    }

    @Test("flow missing END produces violation")
    func testFlowMissingEnd() throws {
        let content = """
            ---
            title: Test
            flow:
              BEGIN:
                _: staff_review
              staff_review:
                _: personal_name
              personal_name:
                _: staff_review
            alignment:
              BEGIN:
                _: staff_review
              staff_review:
                _: END
            ---
            """
        let file = try makeFile(content: content)
        let rule = F104_FlowQuestionCodes(validCodes: validCodes)
        let violations = try rule.validate(file: file)
        #expect(violations.contains { $0.message == "flow is missing required END state" })
    }

    @Test("alignment missing BEGIN produces violation")
    func testAlignmentMissingBegin() throws {
        let content = """
            ---
            title: Test
            flow:
              BEGIN:
                _: staff_review
              staff_review:
                _: END
            alignment:
              staff_review:
                _: END
            ---
            """
        let file = try makeFile(content: content)
        let rule = F104_FlowQuestionCodes(validCodes: validCodes)
        let violations = try rule.validate(file: file)
        #expect(violations.contains { $0.message == "alignment is missing required BEGIN state" })
    }

    @Test("alignment missing END produces violation")
    func testAlignmentMissingEnd() throws {
        let content = """
            ---
            title: Test
            flow:
              BEGIN:
                _: staff_review
              staff_review:
                _: END
            alignment:
              BEGIN:
                _: staff_review
              staff_review:
                _: personal_name
              personal_name:
                _: staff_review
            ---
            """
        let file = try makeFile(content: content)
        let rule = F104_FlowQuestionCodes(validCodes: validCodes)
        let violations = try rule.validate(file: file)
        #expect(violations.contains { $0.message == "alignment is missing required END state" })
    }

    // MARK: - Invalid codes

    @Test("Invalid code in flow produces violation")
    func testInvalidCodeInFlow() throws {
        let content = """
            ---
            title: Test
            flow:
              BEGIN:
                _: tax_advisor
              tax_advisor:
                _: END
            alignment:
              BEGIN:
                _: staff_review
              staff_review:
                _: END
            ---
            """
        let file = try makeFile(content: content)
        let rule = F104_FlowQuestionCodes(validCodes: validCodes)
        let violations = try rule.validate(file: file)
        #expect(
            violations.contains {
                $0.message == "Invalid question code: 'tax_advisor' (from state 'tax_advisor')"
            }
        )
    }

    @Test("Invalid code in alignment produces violation")
    func testInvalidCodeInAlignment() throws {
        let content = """
            ---
            title: Test
            flow:
              BEGIN:
                _: staff_review
              staff_review:
                _: END
            alignment:
              BEGIN:
                _: bad_code
              bad_code:
                _: END
            ---
            """
        let file = try makeFile(content: content)
        let rule = F104_FlowQuestionCodes(validCodes: validCodes)
        let violations = try rule.validate(file: file)
        #expect(
            violations.contains {
                $0.message == "Invalid question code: 'bad_code' (from state 'bad_code')"
            }
        )
    }

    @Test("Multiple invalid codes produce multiple violations")
    func testMultipleInvalidCodesProduceMultipleViolations() throws {
        let content = """
            ---
            title: Test
            flow:
              BEGIN:
                _: tax_advisor
              tax_advisor:
                _: bad_code
              bad_code:
                _: END
            alignment:
              BEGIN:
                _: staff_review
              staff_review:
                _: END
            ---
            """
        let file = try makeFile(content: content)
        let rule = F104_FlowQuestionCodes(validCodes: validCodes)
        let violations = try rule.validate(file: file)
        let invalidViolations = violations.filter { $0.message.hasPrefix("Invalid question code") }
        #expect(invalidViolations.count == 2)
    }

    @Test("Invalid code with label emits state name in context")
    func testInvalidCodeWithLabelEmitsStateName() throws {
        let content = """
            ---
            title: Test
            flow:
              BEGIN:
                _: tax_advisor__for_client
              tax_advisor__for_client:
                _: END
            alignment:
              BEGIN:
                _: staff_review
              staff_review:
                _: END
            ---
            """
        let file = try makeFile(content: content)
        let rule = F104_FlowQuestionCodes(validCodes: validCodes)
        let violations = try rule.validate(file: file)
        #expect(
            violations.contains {
                $0.message
                    == "Invalid question code: 'tax_advisor' (from state 'tax_advisor__for_client')"
            }
        )
    }

    @Test("Valid and invalid codes mixed — only invalid flagged")
    func testMixedCodesOnlyInvalidFlagged() throws {
        let content = """
            ---
            title: Test
            flow:
              BEGIN:
                _: staff_review
              staff_review:
                _: bad_code
              bad_code:
                _: END
            alignment:
              BEGIN:
                _: notarization
              notarization:
                _: END
            ---
            """
        let file = try makeFile(content: content)
        let rule = F104_FlowQuestionCodes(validCodes: validCodes)
        let violations = try rule.validate(file: file)
        let invalidViolations = violations.filter { $0.message.hasPrefix("Invalid question code") }
        #expect(invalidViolations.count == 1)
        #expect(
            invalidViolations[0].message
                == "Invalid question code: 'bad_code' (from state 'bad_code')"
        )
    }
}
