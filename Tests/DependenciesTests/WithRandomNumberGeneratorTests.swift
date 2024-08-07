import Dependencies
import XCTest

final class WithRandomNumberGeneratorDependencyTests: XCTestCase {
  @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator

  func testWithRandomNumberGenerator() {
    withDependencies {
      $0.withRandomNumberGenerator = .init(LCRNG(seed: 0))
    } operation: {
      self.withRandomNumberGenerator { generator -> Void in
        // NB: Wasm has different behavior here.
        #if os(WASI)
          let sequence = [5, 6, 5, 4, 4]
        #else
          let sequence = [1, 3, 6, 3, 2]
        #endif
        for expected in sequence {
          XCTAssertEqual(.random(in: 1...6, using: &generator), expected)
        }
      }
    }
  }

  struct ExpectedError: Error {}

  func testWithRandomNumberGeneratorThrowing() throws {
    try XCTAssertThrowsError(
      {
        try withDependencies {
          $0.withRandomNumberGenerator = .init(LCRNG(seed: 0))
        } operation: {
          try self.withRandomNumberGenerator { generator -> Void in
            // NB: Wasm has different behavior here.
            #if os(WASI)
              let sequence = [5, 6, 5, 4, 4]
            #else
              let sequence = [1, 3, 6, 3, 2]
            #endif
            for expected in sequence {
              if expected == 6 {
                throw ExpectedError()
              }
              XCTAssertEqual(.random(in: 1...6, using: &generator), expected)
            }

          }
        }

      }(), "Expected error should be thrown")
  }
}

private struct LCRNG: RandomNumberGenerator {
  var seed: UInt64
  mutating func next() -> UInt64 {
    self.seed = 2_862_933_555_777_941_757 &* self.seed &+ 3_037_000_493
    return self.seed
  }
}
