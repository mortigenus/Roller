//
//  RollRequest.swift
//  
//
//  Created by Ivan Chalov on 19.04.2021.
//

import Parsing

public struct RollRequest: Equatable {
  public var amount: Int
  public var die: Int

  public var keepInstruction: KeepInstruction?
  public var rerollInstruction: RerollInstruction?
  public var explodeInstruction: ExplodeInstruction?
  public var countSuccessesInstruction: CountSuccessesInstruction?

  public enum KeepInstruction: Equatable {
    case keepHighest(Int)
    case keepLowest(Int)
    case dropHighest(Int)
    case dropLowest(Int)

    static func parser() -> AnyParser<Substring, Self> {
      OneOfMany(
        StartsWith("kh").take(Int.parser()).map(KeepInstruction.keepHighest),
        StartsWith("kl").take(Int.parser()).map(KeepInstruction.keepLowest),
        StartsWith("dh").take(Int.parser()).map(KeepInstruction.dropHighest),
        StartsWith("dl").take(Int.parser()).map(KeepInstruction.dropLowest)
      ).eraseToAnyParser()
    }
  }

  public enum RerollInstruction: Equatable {
    case rerollEqualTo(Int)
    case rerollLessThan(Int)
    case rerollLessThanOrEqualTo(Int)
    case rerollGreaterThan(Int)
    case rerollGreaterThanOrEqualTo(Int)

    static func parser() -> AnyParser<Substring, Self> {
      OneOfMany(
        StartsWith("r").take(Int.parser()).map(RerollInstruction.rerollEqualTo),
        StartsWith("r<").take(Int.parser()).map(RerollInstruction.rerollLessThan),
        StartsWith("r<=").take(Int.parser()).map(RerollInstruction.rerollLessThanOrEqualTo),
        StartsWith("r>").take(Int.parser()).map(RerollInstruction.rerollGreaterThan),
        StartsWith("r>=").take(Int.parser()).map(RerollInstruction.rerollGreaterThanOrEqualTo)
      ).eraseToAnyParser()
    }
  }

  public enum ExplodeInstruction: Equatable {
    case explodeEqualTo(Int)
    case explodeLessThan(Int)
    case explodeLessThanOrEqualTo(Int)
    case explodeGreaterThan(Int)
    case explodeGreaterThanOrEqualTo(Int)

    static func parser() -> AnyParser<Substring, Self> {
      OneOfMany(
        StartsWith("x").take(Int.parser()).map(ExplodeInstruction.explodeEqualTo),
        StartsWith("x<").take(Int.parser()).map(ExplodeInstruction.explodeLessThan),
        StartsWith("x<=").take(Int.parser()).map(ExplodeInstruction.explodeLessThanOrEqualTo),
        StartsWith("x>").take(Int.parser()).map(ExplodeInstruction.explodeGreaterThan),
        StartsWith("x>=").take(Int.parser()).map(ExplodeInstruction.explodeGreaterThanOrEqualTo)
      ).eraseToAnyParser()
    }
  }

  public enum CountSuccessesInstruction: Equatable {
    case countSuccessesEqualTo(Int)
    case countSuccessesLessThan(Int)
    case countSuccessesLessThanOrEqualTo(Int)
    case countSuccessesGreaterThan(Int)
    case countSuccessesGreaterThanOrEqualTo(Int)

    static func parser() -> AnyParser<Substring, Self> {
      OneOfMany(
        StartsWith("cs=").take(Int.parser()).map(CountSuccessesInstruction.countSuccessesEqualTo),
        StartsWith("cs<").take(Int.parser()).map(CountSuccessesInstruction.countSuccessesLessThan),
        StartsWith("cs<=").take(Int.parser()).map(CountSuccessesInstruction.countSuccessesLessThanOrEqualTo),
        StartsWith("cs>").take(Int.parser()).map(CountSuccessesInstruction.countSuccessesGreaterThan),
        StartsWith("cs>=").take(Int.parser()).map(CountSuccessesInstruction.countSuccessesGreaterThanOrEqualTo)
      ).eraseToAnyParser()
    }
  }

  public init(
    amount: Int,
    die: Int,
    keepInstruction: KeepInstruction? = nil,
    rerollInstruction: RerollInstruction? = nil,
    explodeInstruction: ExplodeInstruction? = nil,
    countSuccessesInstruction: CountSuccessesInstruction? = nil) {
    self.amount = amount
    self.die = die
    self.keepInstruction = keepInstruction
    self.rerollInstruction = rerollInstruction
    self.explodeInstruction = explodeInstruction
    self.countSuccessesInstruction = countSuccessesInstruction
  }

  private init?(amount: Int, die: Int, instructions: [Instruction]) {
    var keepInstruction: KeepInstruction?
    var rerollInstruction: RerollInstruction?
    var explodeInstruction: ExplodeInstruction?
    var countSuccessesInstruction: CountSuccessesInstruction?

    for instruction in instructions {
      switch instruction {
      case let .keep(instr):
        guard keepInstruction == nil else { return nil }
        keepInstruction = instr
      case let .reroll(instr):
        guard rerollInstruction == nil else { return nil }
        rerollInstruction = instr
      case let .explode(instr):
        guard explodeInstruction == nil else { return nil }
        explodeInstruction = instr
      case let .countSuccesses(instr):
        guard countSuccessesInstruction == nil else { return nil }
        countSuccessesInstruction = instr
      }
    }

    self.init(
      amount: amount,
      die: die,
      keepInstruction: keepInstruction,
      rerollInstruction: rerollInstruction,
      explodeInstruction: explodeInstruction,
      countSuccessesInstruction: countSuccessesInstruction
    )
  }

  private enum Instruction {
    case keep(KeepInstruction)
    case reroll(RerollInstruction)
    case explode(ExplodeInstruction)
    case countSuccesses(CountSuccessesInstruction)

    static func parser() -> AnyParser<Substring, Self> {
      KeepInstruction.parser().map(Instruction.keep)
        .orElse(RerollInstruction.parser().map(Instruction.reroll))
        .orElse(ExplodeInstruction.parser().map(Instruction.explode))
        .orElse(CountSuccessesInstruction.parser().map(Instruction.countSuccesses))
        .eraseToAnyParser()
    }
  }

  static func parser() -> AnyParser<Substring, Self> {
    Int.parser()
      .skip(StartsWith("d"))
      .take(Int.parser())
      .take(Many(Instruction.parser()))
      .compactMap(RollRequest.init(amount:die:instructions:))
      .eraseToAnyParser()
  }
}
