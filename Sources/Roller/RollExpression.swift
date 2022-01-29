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

  public init?(_ string: String) {
    var input = string[...].utf8
    let parsedExpr = additionAndSubtraction.parse(&input)
    guard let rollExpr = parsedExpr, input.isEmpty else { return nil }
    self = rollExpr
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

private let additionAndSubtraction = InfixOperator(
  OneOf {
    Parse(RollExpression.addition) { "+".utf8 }
    Parse(RollExpression.subtraction) { "-".utf8 }
  },
  associativity: .left,
  lowerThan: multiplication
)

private let multiplication = InfixOperator(
  Parse(RollExpression.multiplication) { "*".utf8 },
  associativity: .left,
  lowerThan: factor
)

private let factor: AnyParser<Substring.UTF8View, RollExpression> =
OneOf {
  Parse {
    symbol("(")
    Lazy { additionAndSubtraction }
    symbol(")")
  }

  Parse(RollExpression.roll) {
    Skip(Whitespace())
    RollRequest.parser()
    Skip(Whitespace())
  }

  Parse(RollExpression.number) {
    Skip(Whitespace())
    Int.parser()
    Skip(Whitespace())
  }
}.eraseToAnyParser()

private let symbol = { (symbol: String) in
  Skip(Whitespace<Substring.UTF8View>()).skip(StartsWith(symbol.utf8)).skip(Whitespace())
}

private struct InfixOperator<Operator, Operand>: Parser
where
Operator: Parser,
Operand: Parser,
Operator.Input == Operand.Input,
Operator.Output == (Operand.Output, Operand.Output) -> Operand.Output
{
  let `associativity`: Associativity
  let operand: Operand
  let `operator`: Operator

  @inlinable
  init(
    _ operator: Operator,
    associativity: Associativity,
    lowerThan operand: Operand
  ) {
    self.associativity = `associativity`
    self.operand = operand
    self.operator = `operator`
  }

  @inlinable
  func parse(_ input: inout Operand.Input) -> Operand.Output? {
    switch associativity {
    case .left:
      guard var lhs = self.operand.parse(&input) else { return nil }
      var rest = input
      while let operation = self.operator.parse(&input),
            let rhs = self.operand.parse(&input)
      {
        rest = input
        lhs = operation(lhs, rhs)
      }
      input = rest
      return lhs
    case .right:
      var lhs: [(Operand.Output, Operator.Output)] = []
      while true {
        guard let rhs = self.operand.parse(&input)
        else { break }
        guard let operation = self.operator.parse(&input)
        else {
          return lhs.reversed().reduce(rhs) { rhs, pair in
            let (lhs, operation) = pair
            return operation(lhs, rhs)
          }
        }
        lhs.append((rhs, operation))
      }
      return nil
    }
  }
}

private enum Associativity {
  case left
  case right
}
