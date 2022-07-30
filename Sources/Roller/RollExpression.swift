//
//  RollerRequest.swift
//  
//
//  Created by Ivan Chalov on 21.04.2021.
//

import Parsing

public enum RollExpression {
  public enum Operation: Hashable {
    case addition
    case subtraction
    case multiplication
  }

  case number(Int)
  case roll(RollRequest)
  indirect case operation(Operation, RollExpression, RollExpression)

  public init(_ string: String) throws {
    var input = string[...].utf8
    self = try Parse {
      additionAndSubtraction
      End()
    }.parse(&input)
  }
}

private extension RollExpression {
  static func addition(_ expr1: RollExpression, _ expr2: RollExpression) -> RollExpression {
    .operation(.addition, expr1, expr2)
  }

  static func subtraction(_ expr1: RollExpression, _ expr2: RollExpression) -> RollExpression {
    .operation(.subtraction, expr1, expr2)
  }

  static func multiplication(_ expr1: RollExpression, _ expr2: RollExpression) -> RollExpression {
    .operation(.multiplication, expr1, expr2)
  }
}

private let additionAndSubtraction = InfixOperator(associativity: .left) {
  OneOf {
    Parse(RollExpression.addition) { "+".utf8 }
    Parse(RollExpression.subtraction) { "-".utf8 }
  }
} lowerThan: { multiplication }

private let multiplication = InfixOperator(associativity: .left) {
  Parse(RollExpression.multiplication) { "*".utf8 }
} lowerThan: { factor }

private let factor: AnyParser<Substring.UTF8View, RollExpression> =
OneOf {
  Parse {
    symbol("(")
    Lazy { additionAndSubtraction }
    symbol(")")
  }

  Parse(RollExpression.roll) {
    Whitespace()
    RollRequest.parser()
    Whitespace()
  }

  Parse(RollExpression.number) {
    Whitespace()
    Int.parser()
    Whitespace()
  }
}.eraseToAnyParser()

private let symbol = { (symbol: String) in
  Parse {
    Whitespace()
    StartsWith(symbol.utf8)
    Whitespace()
  }
}

private struct InfixOperator<Operator: Parser, Operand: Parser>: Parser
where
Operator.Input == Operand.Input,
Operator.Output == (Operand.Output, Operand.Output) -> Operand.Output
{
  public let `associativity`: Associativity
  public let operand: Operand
  public let `operator`: Operator

  @inlinable
  public init(
    associativity: Associativity,
    @ParserBuilder _ operator: () -> Operator,
    @ParserBuilder lowerThan operand: () -> Operand  // Should this be called `precedes operand:`?
  ) {
    self.associativity = `associativity`
    self.operand = operand()
    self.operator = `operator`()
  }

  @inlinable
  public func parse(_ input: inout Operand.Input) rethrows -> Operand.Output {
    switch associativity {
    case .left:
      var lhs = try self.operand.parse(&input)
      var rest = input
      while true {
        do {
          let operation = try self.operator.parse(&input)
          let rhs = try self.operand.parse(&input)
          rest = input
          lhs = operation(lhs, rhs)
        } catch {
          input = rest
          return lhs
        }
      }
    case .right:
      var lhs: [(Operand.Output, Operator.Output)] = []
      while true {
        let rhs = try self.operand.parse(&input)
        do {
          let operation = try self.operator.parse(&input)
          lhs.append((rhs, operation))
        } catch {
          return lhs.reversed().reduce(rhs) { rhs, pair in
            let (lhs, operation) = pair
            return operation(lhs, rhs)
          }
        }
      }
    }
  }
}

private enum Associativity {
  case left
  case right
}
