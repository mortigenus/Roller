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

  public struct KeepInstruction: Hashable, RollInstruction {
    public enum Instruction: String, CaseIterable, Hashable {
      case keepHighest = "kh"
      case keepLowest = "kl"
      case dropHighest = "dh"
      case dropLowest = "dl"
    }
    public var instruction: Instruction
    public var value: Int
  }

  public struct RerollInstruction: Hashable, RollInstruction {
    public enum Instruction: String, CaseIterable, Hashable {
      case rerollEqualTo = "r"
      case rerollLessThan = "r<"
      case rerollLessThanOrEqualTo = "r<="
      case rerollGreaterThan = "r>"
      case rerollGreaterThanOrEqualTo = "r>="
    }
    public var instruction: Instruction
    public var value: Int
  }

  public struct ExplodeInstruction: Hashable, RollInstruction {
    public enum Instruction: String, CaseIterable, Hashable {
      case explodeEqualTo = "x"
      case explodeLessThan = "x<"
      case explodeLessThanOrEqualTo = "x<="
      case explodeGreaterThan = "x>"
      case explodeGreaterThanOrEqualTo = "x>="
    }
    public var instruction: Instruction
    public var value: Int
  }

  public struct CountSuccessesInstruction: Hashable, RollInstruction {
    public enum Instruction: String, CaseIterable, Hashable {
      case countSuccessesEqualTo = "cs="
      case countSuccessesLessThan = "cs<"
      case countSuccessesLessThanOrEqualTo = "cs<="
      case countSuccessesGreaterThan = "cs>"
      case countSuccessesGreaterThanOrEqualTo = "cs>="
    }
    public var instruction: Instruction
    public var value: Int
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

protocol RollInstruction {
  associatedtype T: CaseIterable & RawRepresentable
  var instruction: T { get }
  var value: Int { get }
  init(instruction: T, value: Int)
  static func parser() -> AnyParser<Substring.UTF8View, Self>
}

extension RollInstruction where T.RawValue == String {
  static func parser() -> AnyParser<Substring.UTF8View, Self> {
    Parse(Self.init) {
      T.parser()
      Digits()
    }.eraseToAnyParser()
  }
}
