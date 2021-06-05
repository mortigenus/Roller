//
//  RollerRequest.swift
//  
//
//  Created by Ivan Chalov on 21.04.2021.
//

import Parsing

public enum RollExpression {
  public enum Operation: Equatable {
    case addition
    case subtraction
    case multiplication
  }

  case number(Int)
  case roll(RollRequest)
  indirect case operation(Operation, RollExpression, RollExpression)

  public init?(_ string: String) {
    let (parsedExpr, rest) = expr.parse(string[...].utf8)
    guard let rollExpr = parsedExpr, rest.isEmpty else { return nil }
    self = rollExpr
  }
}

// expr = term + expr | term - expr | term
// term = factor * term | factor
// factor = (expr) | number | roll

private let expr: AnyParser<Substring.UTF8View, RollExpression> =
  term.chainl1(
    symbol("+").map {{ RollExpression.operation(.addition, $0, $1) }}
      .orElse(symbol("-").map {{ RollExpression.operation(.subtraction, $0, $1) }}))

private let term = factor.chainl1(
  symbol("*").map {{ RollExpression.operation(.multiplication, $0, $1) }})

private let factor = OneOfMany(paren, roll, number)

private let paren = Skip(symbol("(")).take(Lazy { expr }).skip(symbol(")")).eraseToAnyParser()

private let number = Skip(Whitespace<Substring.UTF8View>())
  .take(Int.parser())
  .skip(Whitespace())
  .map(RollExpression.number)
  .eraseToAnyParser()

private let roll = Skip(Whitespace<Substring.UTF8View>())
  .take(RollRequest.parser())
  .skip(Whitespace())
  .map(RollExpression.roll)
  .eraseToAnyParser()

private let symbol = { (symbol: String) in
  Skip(Whitespace<Substring.UTF8View>()).skip(StartsWith(symbol.utf8)).skip(Whitespace())
}

private func fix<A, B>(_ f: @escaping (@escaping (A) -> B) -> (A) -> B) -> (A) -> B {
  return { f(fix(f))($0) }
}

extension Parser {
  // chainl1<P>(op) parses one or more occurrences of `P`, separated by `op`.
  // Returns a value obtained by a left associative application of all functions
  // returned by `op` to the values returned by `P`.
  // This parser can for example be used to eliminate left recursion
  // which typically occurs in expression grammars.
  // See https://hackage.haskell.org/package/parsec/docs/Text-Parsec-Combinator.html#v:chainl1
  fileprivate func chainl1<P>(_ op: P) -> AnyParser<Input, Output>
  where P: Parser, P.Input == Input, P.Output == (Output, Output) -> Output {
    self.flatMap { x in
      fix { recur in
        { x in
          op.flatMap { f in
            self.flatMap { y in
              recur(f(x, y))
                .eraseToAnyParser()
            }
          }
          .orElse(Always(x))
          .eraseToAnyParser()
        }
      }(x)
    }
    .eraseToAnyParser()
  }
}
