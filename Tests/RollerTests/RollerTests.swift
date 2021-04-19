import XCTest
import Gen
import Roller

struct TestRollGen {
  static func gen(giving rolls: [Int], die: Int) -> Gen<Roll> {
    var counter = 0
    return Gen { _ -> Roll in
      defer { counter += 1}
      return Roll(result: rolls[counter], die: die)
    }
  }

  static func gen(giving rolls: [[Int]], dice: [Int]) -> Gen<Roll> {
    var counter = 0
    var dieCounter = 0
    return Gen { _ -> Roll in
      defer {
        counter += 1
        if counter == rolls[dieCounter].count {
          counter = 0
          dieCounter += 1
        }
      }
      return Roll(result: rolls[dieCounter][counter], die: dice[dieCounter])
    }
  }
}

final class RollerTests: XCTestCase {

  func testRollIncorrectFormat() {
    XCTAssertNil(Roller("qwe"))
    XCTAssertNil(Roller("4d5f"))
    XCTAssertNil(Roller("4d5 and also something here"))
    XCTAssertNil(Roller("4d5rl5"))
    XCTAssertNil(Roller("r 4d5"))
    XCTAssertNil(Roller("4d5kh1r2r2"))
    XCTAssertNil(Roller("4d5x5kh2kh3"))
    XCTAssertNil(Roller("4d5cs<=7kh4dl2"))
  }

  func testSimpleRoll() throws {
    let dieGen = TestRollGen.gen(giving: [2, 6, 1, 4], die: 8)
    let result = try XCTUnwrap(Roller("4d8", dieGen: dieGen)).roll()

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

  func testBigNumberRolls() throws {
    let dieGen = Gen.always(Roll(result: 20, die: 100))
    let result = try XCTUnwrap(Roller("125d100", dieGen: dieGen)).roll()

    XCTAssertEqual(result.rolls.count, 125)
    XCTAssertTrue(
      result.rolls.allSatisfy { $0 == Roll(result: 20, die: 100) }
    )
    XCTAssertEqual(result.result, 2500)
  }

  func testKeepHeighestRoll() throws {
    let dieGen = TestRollGen.gen(giving: [6, 2, 6, 7, 1, 6], die: 8)
    let result = try XCTUnwrap(Roller("6d8kh3", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [3, 8, 3, 2, 7, 3], die: 8)
    let result = try XCTUnwrap(Roller("6d8kl3", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [6, 2, 6, 7, 1, 6], die: 8)
    let result = try XCTUnwrap(Roller("6d8dh3", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [3, 8, 3, 2, 7, 3], die: 8)
    let result = try XCTUnwrap(Roller("6d8dl3", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [1, 7, 1, 1, 4, 5, 1, 8, 9], die: 12)
    let result = try XCTUnwrap(Roller("6d12r1", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [1, 7, 2, 1, 4, 3, 1, 8, 9], die: 12)
    let result = try XCTUnwrap(Roller("6d12r<3", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [1, 7, 2, 1, 4, 3, 1, 8, 9], die: 12)
    let result = try XCTUnwrap(Roller("6d12r<=2", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [11, 5, 10, 11, 8, 9, 11, 4, 3], die: 12)
    let result = try XCTUnwrap(Roller("6d12r>9", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [11, 5, 10, 11, 8, 9, 11, 4, 3], die: 12)
    let result = try XCTUnwrap(Roller("6d12r>=10", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [1, 7, 1, 1, 4, 5, 1, 8, 9], die: 12)
    let result = try XCTUnwrap(Roller("5d12x1", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [1, 7, 2, 1, 4, 3, 1, 8, 9], die: 12)
    let result = try XCTUnwrap(Roller("5d12x<3", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [1, 7, 2, 1, 4, 3, 1, 8, 9], die: 12)
    let result = try XCTUnwrap(Roller("5d12x<=2", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [11, 5, 10, 11, 8, 9, 11, 4, 3], die: 12)
    let result = try XCTUnwrap(Roller("5d12x>9", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [11, 5, 10, 11, 8, 9, 11, 4, 3], die: 12)
    let result = try XCTUnwrap(Roller("6d12r>=10", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [1, 7, 1, 1, 4, 5], die: 12)
    let result = try XCTUnwrap(Roller("6d12cs=1", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [1, 7, 2, 1, 4, 3], die: 12)
    let result = try XCTUnwrap(Roller("6d12cs<3", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [1, 7, 2, 1, 4, 3], die: 12)
    let result = try XCTUnwrap(Roller("6d12cs<=3", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [11, 5, 10, 11, 8, 9], die: 12)
    let result = try XCTUnwrap(Roller("6d12cs>9", dieGen: dieGen)).roll()

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
    let dieGen = TestRollGen.gen(giving: [11, 5, 10, 11, 8, 9], die: 12)
    let result = try XCTUnwrap(Roller("6d12cs>=10", dieGen: dieGen)).roll()

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
    let dieGen1 = TestRollGen.gen(giving: [11, 5, 10, 11, 8, 9, 2], die: 12)
    let result1 = try XCTUnwrap(Roller("5d12kh3x8cs>10r10", dieGen: dieGen1)).roll()

    let dieGen2 = TestRollGen.gen(giving: [11, 5, 10, 11, 8, 9, 2], die: 12)
    let result2 = try XCTUnwrap(Roller("5d12cs>10r10kh3x8", dieGen: dieGen2)).roll()

    let dieGen3 = TestRollGen.gen(giving: [11, 5, 10, 11, 8, 9, 2], die: 12)
    let result3 = try XCTUnwrap(Roller("5d12x8r10kh3cs>10", dieGen: dieGen3)).roll()

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

}
