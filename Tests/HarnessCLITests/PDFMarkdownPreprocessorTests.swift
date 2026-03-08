import Foundation
import Testing

@testable import HarnessCLI

@Suite("PDF Markdown Preprocessor")
struct PDFMarkdownPreprocessorTests {
    let preprocessor = PDFMarkdownPreprocessor()

    @Test("Lone --- line becomes \\newpage")
    func testHorizontalRuleBecomesPageBreak() {
        let input = "Hello\n---\nWorld"
        let output = preprocessor.preprocess(input)
        #expect(output == "Hello\n\\newpage\nWorld")
    }

    @Test("Multiple --- lines become multiple \\newpage")
    func testMultipleHorizontalRules() {
        let input = "A\n---\n---\nB"
        let output = preprocessor.preprocess(input)
        #expect(output == "A\n\\newpage\n\\newpage\nB")
    }

    @Test("--- inside heading line is not replaced")
    func testHRInsideHeadingUnchanged() {
        let input = "## Section ---"
        let output = preprocessor.preprocess(input)
        #expect(output == "## Section ---")
    }

    @Test("{client.signature} becomes 18 underscores")
    func testClientSignatureReplaced() {
        let input = "Sign here: {client.signature}"
        let output = preprocessor.preprocess(input)
        #expect(output == "Sign here: __________________")
    }

    @Test("{notary.signature} becomes 18 underscores")
    func testNotarySignatureReplaced() {
        let input = "{notary.signature}"
        let output = preprocessor.preprocess(input)
        #expect(output == "__________________")
    }

    @Test("Multiple .signature on one line each replaced")
    func testMultipleSignaturesOnOneLine() {
        let input = "{a.signature} and {b.signature}"
        let output = preprocessor.preprocess(input)
        #expect(output == "__________________ and __________________")
    }

    @Test("{client.name} without .signature is unchanged")
    func testNonSignatureCurlyUnchanged() {
        let input = "{client.name}"
        let output = preprocessor.preprocess(input)
        #expect(output == "{client.name}")
    }

    @Test("--- inside code block is not replaced")
    func testHRInsideCodeBlockUnchanged() {
        let input = "```\n---\n```"
        let output = preprocessor.preprocess(input)
        #expect(output == "```\n---\n```")
    }

    @Test("Both rules applied together in one pass")
    func testBothRulesApplied() {
        let input = "---\n{x.signature}"
        let output = preprocessor.preprocess(input)
        #expect(output == "\\newpage\n__________________")
    }
}
