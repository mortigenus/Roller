//
//  RollRequest.swift
//  
//
//  Created by Ivan Chalov on 19.04.2021.
//

import Parsing

public struct RollRequest: Hashable {
  public var amount: UInt
  public var die: Int

  public var keepInstruction: KeepInstruction?
  public var rerollInstruction: RerollInstruction?
  public var explodeInstruction: ExplodeInstruction?
  public var countSuccessesInstruction: CountSuccessesInstruction?

  public enum KeepInstruction: Hashable {
    case keepHighest(Int)
    case keepLowest(Int)
    case dropHighest(Int)
    case dropLowest(Int)

    static func parser() -> AnyParser<Substring.UTF8View, Self> {
      OneOf {
        RollModifier(keepHighest) { "kh".utf8 }
        RollModifier(keepLowest) { "kl".utf8 }
        RollModifier(dropHighest) { "dh".utf8 }
        RollModifier(dropLowest) { "dl".utf8 }
      }.eraseToAnyParser()
    }
  }

  public enum RerollInstruction: Hashable {
    case rerollEqualTo(Int)
    case rerollLessThan(Int)
    case rerollLessThanOrEqualTo(Int)
    case rerollGreaterThan(Int)
    case rerollGreaterThanOrEqualTo(Int)

    static func parser() -> AnyParser<Substring.UTF8View, Self> {
      OneOf {
        RollModifier(rerollEqualTo) { "r".utf8 }
        RollModifier(rerollLessThan) { "r<".utf8 }
        RollModifier(rerollLessThanOrEqualTo) { "r<=".utf8 }
        RollModifier(rerollGreaterThan) { "r>".utf8 }
        RollModifier(rerollGreaterThanOrEqualTo) { "r>=".utf8 }
      }.eraseToAnyParser()
    }
  }

  public enum ExplodeInstruction: Hashable {
    case explodeEqualTo(Int)
    case explodeLessThan(Int)
    case explodeLessThanOrEqualTo(Int)
    case explodeGreaterThan(Int)
    case explodeGreaterThanOrEqualTo(Int)

    static func parser() -> AnyParser<Substring.UTF8View, Self> {
      OneOf {
        RollModifier(explodeEqualTo) { "x".utf8 }
        RollModifier(explodeLessThan) { "x<".utf8 }
        RollModifier(explodeLessThanOrEqualTo) { "x<=".utf8 }
        RollModifier(explodeGreaterThan) { "x>".utf8 }
        RollModifier(explodeGreaterThanOrEqualTo) { "x>=".utf8 }
      }.eraseToAnyParser()
    }
  }

  public enum CountSuccessesInstruction: Hashable {
    case countSuccessesEqualTo(Int)
    case countSuccessesLessThan(Int)
    case countSuccessesLessThanOrEqualTo(Int)
    case countSuccessesGreaterThan(Int)
    case countSuccessesGreaterThanOrEqualTo(Int)

    static func parser() -> AnyParser<Substring.UTF8View, Self> {
      OneOf {
        RollModifier(countSuccessesEqualTo) { "cs=".utf8 }
        RollModifier(countSuccessesLessThan) { "cs<".utf8 }
        RollModifier(countSuccessesLessThanOrEqualTo) { "cs<=".utf8 }
        RollModifier(countSuccessesGreaterThan) { "cs>".utf8 }
        RollModifier(countSuccessesGreaterThanOrEqualTo) { "cs>=".utf8 }
      }.eraseToAnyParser()
    }
  }

  public init(
    amount: UInt,
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

  private init?(amount: UInt, die: Int, instructions: [Instruction]) {
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

    static func parser() -> AnyParser<Substring.UTF8View, Self> {
      OneOf {
        Parse(keep, with: KeepInstruction.parser)
        Parse(reroll, with: RerollInstruction.parser)
        Parse(explode, with: ExplodeInstruction.parser)
        Parse(countSuccesses, with: CountSuccessesInstruction.parser)
      }.eraseToAnyParser()
    }
  }

  static func parser() -> AnyParser<Substring.UTF8View, Self> {
    Parse(RollRequest.init(amount:die:instructions:)) {
      OneOf {
        UInt.parser()
        Always(UInt(1))
      }
      "d".utf8
      Int.parser()
      Many { Instruction.parser() }
    }.compactMap { $0 }.eraseToAnyParser()
  }
}

private struct RollModifier<P>: Parser
where
P: Parser,
P.Input == Substring.UTF8View
{
  let parsers: P

  @inlinable
  init<Upstream, RollModifier>(
    _ transform: @escaping (Int) -> RollModifier,
    @ParserBuilder with parsers: () -> Upstream
  )
  where
  Upstream.Input == Substring.UTF8View,
  P == Parsers.Map<Parsers.SkipFirst<Skip<Upstream>, Parsers.IntParser<Substring.UTF8View, Int>>, RollModifier>
  {
    self.parsers = Skip(parsers()).take(Int.parser()).map(transform)
  }

  @inlinable
  func parse(_ input: inout Substring.UTF8View) -> P.Output? {
    let original = input
    guard let output = self.parsers.parse(&input) else {
      input = original
      return nil
    }
    return output
  }
}
