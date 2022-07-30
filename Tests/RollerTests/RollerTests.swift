import XCTest
import Gen
import Roller

struct TestRollGen {
  static func gen(source: [Int: [Int]]) -> (Int) -> Gen<Roll> {
    var counter = [Int: Int]()
    return { die in
      return Gen { _ -> Roll in
        let dieCounter = counter[die, default: 0]
        defer { counter[die, default: 0] += 1}
        return Roll(result: source[die]![dieCounter], die: die)
      }
    }
  }
}

final class RollerTests: XCTestCase {

  func testRollsWithIncorrectFormatFail() throws {
    XCTAssertThrowsError(try Roller("qwe"))
    XCTAssertThrowsError(try Roller("4d5f"))
    XCTAssertThrowsError(try Roller("4d5 and also something here"))
    XCTAssertThrowsError(try Roller("4d5rl5"))
    XCTAssertThrowsError(try Roller("r 4d5"))
    XCTAssertThrowsError(try Roller("4d5kh1r2r2"))
    XCTAssertThrowsError(try Roller("4d5x5kh2kh3"))
    XCTAssertThrowsError(try Roller("4d5cs<=7kh4dl2"))
    XCTAssertThrowsError(try Roller("-4d5"))
  }

  func testRollsWithCorrectFormatAreCreated() throws {
    XCTAssertNotNil(try Roller("4d6"))
    XCTAssertNotNil(try Roller("d20"))
    XCTAssertNotNil(try Roller("4d6kh3 + 23d12 + 7"))
    XCTAssertNotNil(try Roller("4d6x>=6 + 20d20kh10 - 8"))
    XCTAssertNotNil(try Roller("   14d6 +    5"))
    XCTAssertNotNil(try Roller("    23  -  4d6"))
  }

  func testSimpleRoll() throws {
    let dieGen = TestRollGen.gen(source: [8: [2, 6, 1, 4]])
    let result = try Roller("4d8", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 2, die: 8),
        Roll(result: 6, die: 8),
        Roll(result: 1, die: 8),
        Roll(result: 4, die: 8),
      ]
    )
    XCTAssertEqual(result.result, 13)
  }

  func testOmittingNumberOfDice() throws {
    let dieGen = TestRollGen.gen(source: [20: [19]])
    let result = try Roller("d20", dieGen: dieGen).eval()

    XCTAssertEqual(result.rolls, [
      Roll(result: 19, die: 20),
    ])
    XCTAssertEqual(result.result, 19)
  }

  func testBigNumberRolls() throws {
    let dieGen = { (_: Int) in Gen.always(Roll(result: 20, die: 100)) }
    let result = try Roller("125d100", dieGen: dieGen).eval()

    XCTAssertEqual(result.rolls.count, 125)
    XCTAssertTrue(
      result.rolls.allSatisfy { $0 == Roll(result: 20, die: 100) }
    )
    XCTAssertEqual(result.result, 2500)
  }

  func testKeepHeighestRoll() throws {
    let dieGen = TestRollGen.gen(source: [8: [6, 2, 6, 7, 1, 6]])
    let result = try Roller("6d8kh3", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 6, die: 8),
        Roll(result: 2, die: 8, isDiscarded: true),
        Roll(result: 6, die: 8),
        Roll(result: 7, die: 8),
        Roll(result: 1, die: 8, isDiscarded: true),
        Roll(result: 6, die: 8, isDiscarded: true),
      ]
    )
    XCTAssertEqual(result.result, 19)
  }

  func testKeelLowestRoll() throws {
    let dieGen = TestRollGen.gen(source: [8: [3, 8, 3, 2, 7, 3]])
    let result = try Roller("6d8kl3", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 3, die: 8),
        Roll(result: 8, die: 8, isDiscarded: true),
        Roll(result: 3, die: 8),
        Roll(result: 2, die: 8),
        Roll(result: 7, die: 8, isDiscarded: true),
        Roll(result: 3, die: 8, isDiscarded: true),
      ]
    )
    XCTAssertEqual(result.result, 8)
  }

  func testDropHeighestRoll() throws {
    let dieGen = TestRollGen.gen(source: [8: [6, 2, 6, 7, 1, 6]])
    let result = try Roller("6d8dh3", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 6, die: 8, isDiscarded: true),
        Roll(result: 2, die: 8),
        Roll(result: 6, die: 8, isDiscarded: true),
        Roll(result: 7, die: 8, isDiscarded: true),
        Roll(result: 1, die: 8),
        Roll(result: 6, die: 8),
      ]
    )
    XCTAssertEqual(result.result, 9)
  }

  func testDropLowestRoll() throws {
    let dieGen = TestRollGen.gen(source: [8: [3, 8, 3, 2, 7, 3]])
    let result = try Roller("6d8dl3", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 3, die: 8, isDiscarded: true),
        Roll(result: 8, die: 8),
        Roll(result: 3, die: 8, isDiscarded: true),
        Roll(result: 2, die: 8, isDiscarded: true),
        Roll(result: 7, die: 8),
        Roll(result: 3, die: 8),
      ]
    )
    XCTAssertEqual(result.result, 18)
  }

  func testRerollEqualRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [1, 7, 1, 1, 4, 5, 1, 8, 9]])
    let result = try Roller("6d12r1", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 1, die: 12, isDiscarded: true),
        Roll(result: 7, die: 12),
        Roll(result: 1, die: 12, isDiscarded: true),
        Roll(result: 1, die: 12),
        Roll(result: 4, die: 12),
        Roll(result: 5, die: 12),
        Roll(result: 1, die: 12, isDiscarded: true),
        Roll(result: 8, die: 12),
        Roll(result: 9, die: 12),
      ]
    )
    XCTAssertEqual(result.result, 34)
  }

  func testRerollLessThanRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [1, 7, 2, 1, 4, 3, 1, 8, 9]])
    let result = try Roller("6d12r<3", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 1, die: 12, isDiscarded: true),
        Roll(result: 7, die: 12),
        Roll(result: 2, die: 12, isDiscarded: true),
        Roll(result: 1, die: 12),
        Roll(result: 4, die: 12),
        Roll(result: 3, die: 12),
        Roll(result: 1, die: 12, isDiscarded: true),
        Roll(result: 8, die: 12),
        Roll(result: 9, die: 12),
      ]
    )
    XCTAssertEqual(result.result, 32)
  }

  func testRerollLessThanOrEqualRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [1, 7, 2, 1, 4, 3, 1, 8, 9]])
    let result = try Roller("6d12r<=2", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 1, die: 12, isDiscarded: true),
        Roll(result: 7, die: 12),
        Roll(result: 2, die: 12, isDiscarded: true),
        Roll(result: 1, die: 12),
        Roll(result: 4, die: 12),
        Roll(result: 3, die: 12),
        Roll(result: 1, die: 12, isDiscarded: true),
        Roll(result: 8, die: 12),
        Roll(result: 9, die: 12),
      ]
    )
    XCTAssertEqual(result.result, 32)
  }

  func testRerollGreaterThanRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [11, 5, 10, 11, 8, 9, 11, 4, 3]])
    let result = try Roller("6d12r>9", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 11, die: 12, isDiscarded: true),
        Roll(result:  5, die: 12),
        Roll(result: 10, die: 12, isDiscarded: true),
        Roll(result: 11, die: 12),
        Roll(result:  8, die: 12),
        Roll(result:  9, die: 12),
        Roll(result: 11, die: 12, isDiscarded: true),
        Roll(result:  4, die: 12),
        Roll(result:  3, die: 12),
      ]
    )
    XCTAssertEqual(result.result, 40)
  }

  func testRerollGreaterThanOrEqualRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [11, 5, 10, 11, 8, 9, 11, 4, 3]])
    let result = try Roller("6d12r>=10", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 11, die: 12, isDiscarded: true),
        Roll(result:  5, die: 12),
        Roll(result: 10, die: 12, isDiscarded: true),
        Roll(result: 11, die: 12),
        Roll(result:  8, die: 12),
        Roll(result:  9, die: 12),
        Roll(result: 11, die: 12, isDiscarded: true),
        Roll(result:  4, die: 12),
        Roll(result:  3, die: 12),
      ]
    )
    XCTAssertEqual(result.result, 40)
  }

  func testExplodeEqualRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [1, 7, 1, 1, 4, 5, 1, 8, 9]])
    let result = try Roller("5d12x1", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 1, die: 12),
        Roll(result: 7, die: 12),
        Roll(result: 1, die: 12),
        Roll(result: 1, die: 12),
        Roll(result: 4, die: 12),
        Roll(result: 5, die: 12),
        Roll(result: 1, die: 12),
        Roll(result: 8, die: 12),
        Roll(result: 9, die: 12),
      ]
    )
    XCTAssertEqual(result.result, 37)
  }

  func testExplodeLessThanRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [1, 7, 2, 1, 4, 3, 1, 8, 9]])
    let result = try Roller("5d12x<3", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 1, die: 12),
        Roll(result: 7, die: 12),
        Roll(result: 2, die: 12),
        Roll(result: 1, die: 12),
        Roll(result: 4, die: 12),
        Roll(result: 3, die: 12),
        Roll(result: 1, die: 12),
        Roll(result: 8, die: 12),
        Roll(result: 9, die: 12),
      ]
    )
    XCTAssertEqual(result.result, 36)
  }

  func testExplodeLessThanOrEqualRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [1, 7, 2, 1, 4, 3, 1, 8, 9]])
    let result = try Roller("5d12x<=2", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 1, die: 12),
        Roll(result: 7, die: 12),
        Roll(result: 2, die: 12),
        Roll(result: 1, die: 12),
        Roll(result: 4, die: 12),
        Roll(result: 3, die: 12),
        Roll(result: 1, die: 12),
        Roll(result: 8, die: 12),
        Roll(result: 9, die: 12),
      ]
    )
    XCTAssertEqual(result.result, 36)
  }

  func testExplodeGreaterThanRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [11, 5, 10, 11, 8, 9, 11, 4, 3]])
    let result = try Roller("5d12x>9", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 11, die: 12),
        Roll(result:  5, die: 12),
        Roll(result: 10, die: 12),
        Roll(result: 11, die: 12),
        Roll(result:  8, die: 12),
        Roll(result:  9, die: 12),
        Roll(result: 11, die: 12),
        Roll(result:  4, die: 12),
        Roll(result:  3, die: 12),
      ]
    )
    XCTAssertEqual(result.result, 72)
  }

  func testExplodeGreaterThanOrEqualRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [11, 5, 10, 11, 8, 9, 11, 4, 3]])
    let result = try Roller("6d12r>=10", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 11, die: 12, isDiscarded: true),
        Roll(result:  5, die: 12),
        Roll(result: 10, die: 12, isDiscarded: true),
        Roll(result: 11, die: 12),
        Roll(result:  8, die: 12),
        Roll(result:  9, die: 12),
        Roll(result: 11, die: 12, isDiscarded: true),
        Roll(result:  4, die: 12),
        Roll(result:  3, die: 12),
      ]
    )
    XCTAssertEqual(result.result, 40)
  }

  func testCountSuccessesEqualRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [1, 7, 1, 1, 4, 5]])
    let result = try Roller("6d12cs=1", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 1, die: 12),
        Roll(result: 7, die: 12),
        Roll(result: 1, die: 12),
        Roll(result: 1, die: 12),
        Roll(result: 4, die: 12),
        Roll(result: 5, die: 12),
      ]
    )
    XCTAssertEqual(result.result, 3)
  }

  func testCountSuccessesLessThanRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [1, 7, 2, 1, 4, 3]])
    let result = try Roller("6d12cs<3", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 1, die: 12),
        Roll(result: 7, die: 12),
        Roll(result: 2, die: 12),
        Roll(result: 1, die: 12),
        Roll(result: 4, die: 12),
        Roll(result: 3, die: 12),
      ]
    )
    XCTAssertEqual(result.result, 3)
  }

  func testCountSuccessesLessThanOrEqualRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [1, 7, 2, 1, 4, 3]])
    let result = try Roller("6d12cs<=3", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 1, die: 12),
        Roll(result: 7, die: 12),
        Roll(result: 2, die: 12),
        Roll(result: 1, die: 12),
        Roll(result: 4, die: 12),
        Roll(result: 3, die: 12),
      ]
    )
    XCTAssertEqual(result.result, 4)
  }

  func testCountSuccessesGreaterThanRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [11, 5, 10, 11, 8, 9]])
    let result = try Roller("6d12cs>9", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 11, die: 12),
        Roll(result:  5, die: 12),
        Roll(result: 10, die: 12),
        Roll(result: 11, die: 12),
        Roll(result:  8, die: 12),
        Roll(result:  9, die: 12),
      ]
    )
    XCTAssertEqual(result.result, 3)
  }

  func testCountSuccessesGreaterThanOrEqualRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [11, 5, 10, 11, 8, 9]])
    let result = try Roller("6d12cs>=10", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 11, die: 12),
        Roll(result:  5, die: 12),
        Roll(result: 10, die: 12),
        Roll(result: 11, die: 12),
        Roll(result:  8, die: 12),
        Roll(result:  9, die: 12),
      ]
    )
    XCTAssertEqual(result.result, 3)
  }

  func testMixedInstructionsRolls() throws {
    let dieGen1 = TestRollGen.gen(source: [12: [11, 5, 10, 11, 8, 9, 2]])
    let result1 = try Roller("5d12kh3x8cs>10r10", dieGen: dieGen1).eval()

    let dieGen2 = TestRollGen.gen(source: [12: [11, 5, 10, 11, 8, 9, 2]])
    let result2 = try Roller("5d12cs>10r10kh3x8", dieGen: dieGen2).eval()

    let dieGen3 = TestRollGen.gen(source: [12: [11, 5, 10, 11, 8, 9, 2]])
    let result3 = try Roller("5d12x8r10kh3cs>10", dieGen: dieGen3).eval()

    let expectedRolls = [
      Roll(result: 11, die: 12),
      Roll(result:  5, die: 12, isDiscarded: true),
      Roll(result: 10, die: 12, isDiscarded: true),
      Roll(result: 11, die: 12),
      Roll(result:  8, die: 12, isDiscarded: true),
      Roll(result:  9, die: 12),
      Roll(result:  2, die: 12, isDiscarded: true),
    ]
    let expectedResult: Int = 2

    XCTAssertEqual(result1.rolls, expectedRolls)
    XCTAssertEqual(result1.result, expectedResult)

    XCTAssertEqual(result2.rolls, expectedRolls)
    XCTAssertEqual(result2.result, expectedResult)

    XCTAssertEqual(result3.rolls, expectedRolls)
    XCTAssertEqual(result3.result, expectedResult)
  }

  func testAddMultipleSameRolls() throws {
    let dieGen = TestRollGen.gen(source: [6: [1, 4, 2, 1, 1]])
    let result = try Roller("3d6 + 2d6", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 1, die: 6),
        Roll(result: 4, die: 6),
        Roll(result: 2, die: 6),
        Roll(result: 1, die: 6),
        Roll(result: 1, die: 6),
      ]
    )
    XCTAssertEqual(result.result, 9)
  }

  func testAddMultipleDifferentRolls() throws {
    let dieGen = TestRollGen.gen(source: [6: [1, 4, 2], 8: [4, 8, 3, 1]])
    let result = try Roller("3d6 + 4d8", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 1, die: 6),
        Roll(result: 4, die: 6),
        Roll(result: 2, die: 6),
        Roll(result: 4, die: 8),
        Roll(result: 8, die: 8),
        Roll(result: 3, die: 8),
        Roll(result: 1, die: 8),
      ]
    )
    XCTAssertEqual(result.result, 23)
  }

  func testAddNumberAndRoll() throws {
    let dieGen1 = TestRollGen.gen(source: [8: [4, 8, 3, 1]])
    let result1 = try Roller("3 + 4d8", dieGen: dieGen1).eval()

    let dieGen2 = TestRollGen.gen(source: [8: [4, 8, 3, 1]])
    let result2 = try Roller("4d8 + 3", dieGen: dieGen2).eval()

    let expectedRolls = [
      Roll(result: 4, die: 8),
      Roll(result: 8, die: 8),
      Roll(result: 3, die: 8),
      Roll(result: 1, die: 8),
    ]
    let expectedResult = 19

    XCTAssertEqual(result1.rolls, expectedRolls)
    XCTAssertEqual(result1.result, expectedResult)

    XCTAssertEqual(result2.rolls, expectedRolls)
    XCTAssertEqual(result2.result, expectedResult)
  }

  func testSubtractMultipleSameRolls() throws {
    let dieGen = TestRollGen.gen(source: [6: [1, 4, 2, 6, 6]])
    let result = try Roller("3d6 - 2d6", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 1, die: 6),
        Roll(result: 4, die: 6),
        Roll(result: 2, die: 6),
        Roll(result: 6, die: 6),
        Roll(result: 6, die: 6),
      ]
    )
    XCTAssertEqual(result.result, -5)
  }

  func testSubtractMultipleDifferentRolls() throws {
    let dieGen = TestRollGen.gen(source: [6: [1, 4, 2], 8: [4, 8, 3, 1]])
    let result = try Roller("3d6 - 4d8", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 1, die: 6),
        Roll(result: 4, die: 6),
        Roll(result: 2, die: 6),
        Roll(result: 4, die: 8),
        Roll(result: 8, die: 8),
        Roll(result: 3, die: 8),
        Roll(result: 1, die: 8),
      ]
    )
    XCTAssertEqual(result.result, -9)
  }

  func testSubtractNumberAndRoll() throws {
    let dieGen1 = TestRollGen.gen(source: [8: [4, 8, 3, 1]])
    let result1 = try Roller("3 - 4d8", dieGen: dieGen1).eval()

    let dieGen2 = TestRollGen.gen(source: [8: [4, 8, 3, 1]])
    let result2 = try Roller("4d8 - 3", dieGen: dieGen2).eval()

    let expectedRolls = [
      Roll(result: 4, die: 8),
      Roll(result: 8, die: 8),
      Roll(result: 3, die: 8),
      Roll(result: 1, die: 8),
    ]

    XCTAssertEqual(result1.rolls, expectedRolls)
    XCTAssertEqual(result1.result, -13)

    XCTAssertEqual(result2.rolls, expectedRolls)
    XCTAssertEqual(result2.result, 13)
  }

  func testMultiplicationRoll() throws {
    let dieGen1 = TestRollGen.gen(source: [8: [4]])
    let result1 = try Roller("10 * 1d8", dieGen: dieGen1).eval()

    let dieGen2 = TestRollGen.gen(source: [8: [4]])
    let result2 = try Roller("1d8 * 10", dieGen: dieGen2).eval()

    let expectedRolls = [
      Roll(result: 4, die: 8),
    ]
    let expectedResult = 40

    XCTAssertEqual(result1.rolls, expectedRolls)
    XCTAssertEqual(result1.result, expectedResult)

    XCTAssertEqual(result2.rolls, expectedRolls)
    XCTAssertEqual(result2.result, expectedResult)
  }

  func testOperatorPrecedenceRoll() throws {
    let dieGen = TestRollGen.gen(source: [8: [4], 6: [2, 5]])
    let result = try Roller("1d8 + 7 - 2d6 * 3", dieGen: dieGen).eval()

    let expectedRolls = [
      Roll(result: 4, die: 8),
      Roll(result: 2, die: 6),
      Roll(result: 5, die: 6),
    ]
    let expectedResult = -10

    XCTAssertEqual(result.rolls, expectedRolls)
    XCTAssertEqual(result.result, expectedResult)
  }

  func testOperatorPrecedenceWithParensRoll() throws {
    let dieGen = TestRollGen.gen(source: [8: [4], 6: [2, 5]])
    let result = try Roller("1d8 + (7 - 2d6 + 3) * 3", dieGen: dieGen).eval()

    let expectedRolls = [
      Roll(result: 4, die: 8),
      Roll(result: 2, die: 6),
      Roll(result: 5, die: 6),
    ]
    let expectedResult = 13

    XCTAssertEqual(result.rolls, expectedRolls)
    XCTAssertEqual(result.result, expectedResult)
  }

  func testOperatorPrecedenceWithNestedParensRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [1, 9], 8: [4], 6: [2, 5]])
    let result = try Roller("1d12r1 * (1d8 + (7 - (2d6 + 3))) * 3", dieGen: dieGen).eval()

    let expectedRolls = [
      Roll(result: 1, die: 12, isDiscarded: true),
      Roll(result: 9, die: 12),
      Roll(result: 4, die: 8),
      Roll(result: 2, die: 6),
      Roll(result: 5, die: 6),
    ]
    let expectedResult = 27

    XCTAssertEqual(result.rolls, expectedRolls)
    XCTAssertEqual(result.result, expectedResult)
  }

  func testNegativeNumbersRoll() throws {
    let dieGen = TestRollGen.gen(source: [12: [1, 9]])
    let result = try Roller("-2-2d12--3", dieGen: dieGen).eval()

    let expectedRolls = [
      Roll(result: 1, die: 12),
      Roll(result: 9, die: 12),
    ]
    let expectedResult = -9

    XCTAssertEqual(result.rolls, expectedRolls)
    XCTAssertEqual(result.result, expectedResult)
  }

  func testComplexRoll() throws {
    let dieGen = TestRollGen.gen(source: [6: [1, 4, 2, 6, 6, 2], 12: [4, 8, 9, 1]])
    let result = try Roller("4d6kh2x6 - 3d12dl1r9 + 23", dieGen: dieGen).eval()

    XCTAssertEqual(
      result.rolls,
      [
        Roll(result: 1, die:  6, isDiscarded: true),
        Roll(result: 4, die:  6, isDiscarded: true),
        Roll(result: 2, die:  6, isDiscarded: true),
        Roll(result: 6, die:  6),
        Roll(result: 6, die:  6),
        Roll(result: 2, die:  6, isDiscarded: true),
        Roll(result: 4, die: 12),
        Roll(result: 8, die: 12),
        Roll(result: 9, die: 12, isDiscarded: true),
        Roll(result: 1, die: 12, isDiscarded: true),
      ]
    )
    XCTAssertEqual(result.result, 23)
  }
}
