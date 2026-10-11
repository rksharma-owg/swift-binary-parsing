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

import BinaryParsing
import Testing

struct MagicNumberTests {
  @Test
  func escapedMagicNumberConsumesDecodedBytes() throws {
    try [UInt8](arrayLiteral: 0x42, 0x54, 0x00, 0x00, 0xff).withParserSpan {
      input in
      try #magicNumber("BT\0\0", parsing: &input)
      #expect(input.count == 1)
      #expect(try UInt8(parsing: &input) == 0xff)
    }
  }

  @Test(arguments: [
    [UInt8](arrayLiteral: 0x42, 0x54, 0x00, 0x01), [0x42, 0x54, 0x00],
  ])
  func escapedMagicNumberRejectsIncorrectOrTruncatedBytes(bytes: [UInt8]) {
    bytes.withParserSpan { input in
      #expect(throws: (any Error).self) {
        try #magicNumber("BT\0\0", parsing: &input)
      }
    }
  }

  @Test
  func rawMagicNumberPreservesUnescapedBackslash() throws {
    try [UInt8](arrayLiteral: 0x5c, 0x6e, 0xff).withParserSpan { input in
      try #magicNumber(#"\n"#, parsing: &input)
      #expect(input.count == 1)
      #expect(try UInt8(parsing: &input) == 0xff)
    }
  }
}
