//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Binary Parsing open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import BinaryParsingMacros
import MacroTesting
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import Testing

@Suite(
  .macros(macros: ["magicNumber": MagicNumberStringMacro.self])
)
struct StringifyMacroSwiftTestingTests {
  @Test
  func magicNumberString() {
    assertMacro {
      #"try #magicNumber("qoif", parsing: &data)"#
    } expansion: {
      "try _loadAndCheckDirectBytes(parsing: &data, bigEndianValue: 0x716f6966 as UInt32)"
    }
  }

  @Test(arguments: [
    (#"try #magicNumber("BT\0\0", parsing: &data)"#, "42540000", "UInt32"),
    (#"try #magicNumber("\n\r", parsing: &data)"#, "a0d", "UInt16"),
    (#"try #magicNumber("\t\0", parsing: &data)"#, "900", "UInt16"),
    (#"try #magicNumber("\"\\", parsing: &data)"#, "225c", "UInt16"),
    (
      #"try #magicNumber("\u{42}\u{54}\u{0}\u{0}", parsing: &data)"#,
      "42540000", "UInt32"
    ),
    (
      ##"try #magicNumber(#"BT\#0\#0"#, parsing: &data)"##, "42540000", "UInt32"
    ),
    (##"try #magicNumber(#"\n"#, parsing: &data)"##, "5c6e", "UInt16"),
    (
      #"try #magicNumber("ABCD\0\0\0\0", parsing: &data)"#, "4142434400000000",
      "UInt64"
    ),
  ])
  func magicNumberStringEscapes(
    source: String, hex: String, integerType: String
  ) throws {
    let expression = try #require(
      Parser.parse(source: source).statements.first?.item.as(
        TryExprSyntax.self)?.expression
        .as(MacroExpansionExprSyntax.self))
    let context = BasicMacroExpansionContext()
    let expansion = MagicNumberStringMacro.expansion(
      of: expression, in: context)
    #expect(context.diagnostics.isEmpty)
    #expect(
      expansion.trimmedDescription
        == "_loadAndCheckDirectBytes(parsing: &data, bigEndianValue: 0x\(hex) as \(integerType))"
    )
  }

  @Test(arguments: [
    (
      #"try #magicNumber("\u{e9}A", parsing: &data)"#,
      "Magic number must be ASCII only."
    ),
    (
      #"try #magicNumber("\0", parsing: &data)"#,
      "Magic number must be 2, 4, or 8 characters."
    ),
    (
      #"try #magicNumber("A\0B", parsing: &data)"#,
      "Magic number must be 2, 4, or 8 characters."
    ),
    (
      #"try #magicNumber("\(value)", parsing: &data)"#,
      "Magic number must be expressed as a string literal."
    ),
  ])
  func magicNumberStringDiagnostics(source: String, message: String) throws {
    let expression = try #require(
      Parser.parse(source: source).statements.first?.item.as(
        TryExprSyntax.self)?.expression
        .as(MacroExpansionExprSyntax.self))
    let context = BasicMacroExpansionContext()
    let expansion = MagicNumberStringMacro.expansion(
      of: expression, in: context)
    #expect(expansion.trimmedDescription.isEmpty)
    #expect(context.diagnostics.map(\.message) == [message])
  }

}
