import Gen
import Prelude

/*
 Keep highest: 4d6kh3
 Drop lowest: 4d6dl1
 Drop highest: 3d4dh1
 Keep lowest: 3d4kl1
 Reroll equal: 2d4r1
 Reroll less: 2d4r<2
 Reroll less or equal: 2d4r<=2
 Reroll greater: 2d4r>2
 Reroll greater equal: 2d4r>=3
 Explode equal: 2d4x4
 Explode less: 2d4x<2
 Explode less or equal: 2d4x<=2
 Explode greater: 2d4x>2
 Explode greater equal: 2d4x>=3
 Count Successes equal: 2d4cs=4
 Count Successes less: 2d4cs<2
 Count Successes less or equal: 2d4cs<=2
 Count Successes greater: 2d4cs>2
 Count Successes greater equal: 2d4cs>=3
*/

public struct Roller {
  public var rollRequest: RollRequest
  public var dieGen: Gen<Roll>

  public init(rollRequest: RollRequest, dieGen: Gen<Roll>? = nil) {
    self.rollRequest = rollRequest
    self.dieGen = dieGen ?? Gen
      .int(in: 1...rollRequest.die)
      .map { Roll(result: $0, die: rollRequest.die) }
  }

  public init?(_ string: String, dieGen: Gen<Roll>? = nil) {
    let (request, rest) = RollRequest.parser().parse(string[...])
    guard let rollRequest = request, rest.isEmpty else {
      return nil
    }

    self.init(rollRequest: rollRequest, dieGen: dieGen)
  }


  public func roll(using rng: AnyRandomNumberGenerator? = nil) -> RollerResponse {
    var rng = rng ?? AnyRandomNumberGenerator(SystemRandomNumberGenerator())

    var rolls = (1...rollRequest.amount).flatMap { _ -> [Roll] in
      let roll = dieGen.run(using: &rng)

      if let reroll = rollRequest.rerollInstruction {
        switch reroll {
        case .rerollEqualTo(let x):
          if roll.result == x { return [roll.discarded(), dieGen.run(using: &rng)] }
        case .rerollLessThan(let x):
          if roll.result < x { return [roll.discarded(), dieGen.run(using: &rng)] }
        case .rerollLessThanOrEqualTo(let x):
          if roll.result <= x { return [roll.discarded(), dieGen.run(using: &rng)] }
        case .rerollGreaterThan(let x):
          if roll.result > x { return [roll.discarded(), dieGen.run(using: &rng)] }
        case .rerollGreaterThanOrEqualTo(let x):
          if roll.result >= x { return [roll.discarded(), dieGen.run(using: &rng)] }
        }
      }

      if let explode = rollRequest.explodeInstruction {
        switch explode {
        case .explodeEqualTo(let x):
          if roll.result == x {
            var newRolls = [roll]
            var newRoll: Roll
            repeat {
              newRoll = dieGen.run()
              newRolls.append(newRoll)
            } while newRoll.result == x
            return newRolls
          }
        case .explodeLessThan(let x):
          if roll.result < x {
            var newRolls = [roll]
            var newRoll: Roll
            repeat {
              newRoll = dieGen.run()
              newRolls.append(newRoll)
            } while newRoll.result < x
            return newRolls
          }
        case .explodeLessThanOrEqualTo(let x):
          if roll.result <= x {
            var newRolls = [roll]
            var newRoll: Roll
            repeat {
              newRoll = dieGen.run()
              newRolls.append(newRoll)
            } while newRoll.result <= x
            return newRolls
          }
        case .explodeGreaterThan(let x):
          if roll.result > x {
            var newRolls = [roll]
            var newRoll: Roll
            repeat {
              newRoll = dieGen.run()
              newRolls.append(newRoll)
            } while newRoll.result > x
            return newRolls
          }
        case .explodeGreaterThanOrEqualTo(let x):
          if roll.result >= x {
            var newRolls = [roll]
            var newRoll: Roll
            repeat {
              newRoll = dieGen.run()
              newRolls.append(newRoll)
            } while newRoll.result >= x
            return newRolls
          }
        }
      }

      return [roll]
    }

    if let extra = rollRequest.keepInstruction {
      switch extra {
      case .keepHighest(let n):
        var filteredIndices = rolls.indices.filter { !rolls[$0].isDiscarded }
        rolls.modifyEach { $0.discard() }
        (1...n).forEach { _ in
          if let maxIndex = filteredIndices.max(by: { rolls[$0].result < rolls[$1].result }) {
            rolls[maxIndex].isDiscarded = false
            filteredIndices.remove(at: filteredIndices.firstIndex(of: maxIndex)!)
          }
        }
      case .keepLowest(let n):
        var filteredIndices = rolls.indices.filter { !rolls[$0].isDiscarded }
        rolls.modifyEach { $0.discard() }
        (1...n).forEach { _ in
          if let minIndex = filteredIndices.min(by: { rolls[$0].result < rolls[$1].result }) {
            rolls[minIndex].isDiscarded = false
            filteredIndices.remove(at: filteredIndices.firstIndex(of: minIndex)!)
          }
        }
      case .dropHighest(let n):
        var filteredIndices = rolls.indices.filter { !rolls[$0].isDiscarded }
        (1...n).forEach { _ in
          if let maxIndex = filteredIndices.max(by: { rolls[$0].result < rolls[$1].result }) {
            rolls[maxIndex].isDiscarded = true
            filteredIndices.remove(at: filteredIndices.firstIndex(of: maxIndex)!)
          }
        }
      case .dropLowest(let n):
        var filteredIndices = rolls.indices.filter { !rolls[$0].isDiscarded }
        (1...n).forEach { _ in
          if let minIndex = filteredIndices.min(by: { rolls[$0].result < rolls[$1].result }) {
            rolls[minIndex].isDiscarded = true
            filteredIndices.remove(at: filteredIndices.firstIndex(of: minIndex)!)
          }
        }
      }
    }

    let result: Int
    let nonDiscardedRolls = rolls.filter(not <<< \.isDiscarded)
    if let action = rollRequest.countSuccessesInstruction {
      switch action {
      case .countSuccessesEqualTo(let x):
        result = nonDiscardedRolls.filter { $0.result == x }.count
      case .countSuccessesLessThan(let x):
        result = nonDiscardedRolls.filter { $0.result < x }.count
      case .countSuccessesLessThanOrEqualTo(let x):
        result = nonDiscardedRolls.filter { $0.result <= x }.count
      case .countSuccessesGreaterThan(let x):
        result = nonDiscardedRolls.filter { $0.result > x }.count
      case .countSuccessesGreaterThanOrEqualTo(let x):
        result = nonDiscardedRolls.filter { $0.result >= x }.count
      }
    } else {
      result = nonDiscardedRolls.map(\.result).reduce(0, +)
    }

    return RollerResponse(rolls: rolls, result: result)
  }
}

