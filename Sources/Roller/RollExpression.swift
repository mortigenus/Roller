//
//  RollerRequest.swift
//  
//
//  Created by Ivan Chalov on 21.04.2021.
//

import Parsing

public enum RollExpression {
  case number(Int)
  case roll(RollRequest)
  indirect case add(RollExpression, RollExpression)
  indirect case subtract(RollExpression, RollExpression)
  indirect case multiply(RollExpression, RollExpression)

  public init?(_ string: String) {
    let (parsedTokens, rest) = tokensParser.parse(string[...].utf8)
    guard var tokens = parsedTokens, rest.isEmpty else { return nil }
    tokens = prefixNotation(tokens)
    self.init(tokens: &tokens)
  }

  private init?(tokens: inout [Token]) {
    var tokens = tokens
    guard let expression = Self.create(&tokens) else { return nil }
    self = expression
  }

  private static func create(_ tokens: inout [Token]) -> RollExpression? {
    guard !tokens.isEmpty else { return nil }
    let token = tokens.removeFirst()
    switch token {
    case .openParen, .closeParen: return nil //TODO: fix me, this should never happen :D
    case .operation(.addition):
      guard let expr1 = create(&tokens), let expr2 = create(&tokens) else { return nil }
      return .add(expr1, expr2)
    case .operation(.subtraction):
      guard let expr1 = create(&tokens), let expr2 = create(&tokens) else { return nil }
      return .subtract(expr1, expr2)
    case .operation(.multiplication):
      guard let expr1 = create(&tokens), let expr2 = create(&tokens) else { return nil }
      return .multiply(expr1, expr2)
    case .number(let x):
      return .number(x)
    case .rollRequest(let request):
      return .roll(request)
    }
  }
}

private enum Operation: Equatable {
  case addition
  case subtraction
  case multiplication
}

private enum Token: Equatable {
  case number(Int)
  case rollRequest(RollRequest)
  case operation(Operation)
  case openParen
  case closeParen
}

private let number = Skip(Whitespace<Substring.UTF8View>()).take(Int.parser()).skip(Whitespace())
  .map(Token.number).eraseToAnyParser()
private let symbol = { (symbol: String) in
  Skip(Whitespace<Substring.UTF8View>()).skip(StartsWith(symbol.utf8)).skip(Whitespace())
}

private let addition = symbol("+").map { Token.operation(.addition) }.eraseToAnyParser()
private let subtraction = symbol("-").map { Token.operation(.subtraction) }.eraseToAnyParser()
private let multiplication = symbol("*").map { Token.operation(.multiplication) }.eraseToAnyParser()
private let openParen = symbol("(").map { Token.openParen }.eraseToAnyParser()
private let closeParen = symbol(")").map { Token.closeParen }.eraseToAnyParser()
private let roll = Skip(Whitespace<Substring.UTF8View>())
  .take(Parsers.SubstringToUTF8View(upstream: RollRequest.parser()))
  .skip(Whitespace())
  .map(Token.rollRequest).eraseToAnyParser()

private let tokenParser = OneOfMany([
  roll,
  number,
  addition,
  subtraction,
  multiplication,
  openParen,
  closeParen,
])

private let tokensParser = Many(tokenParser)

private func precedence(_ op: Operation) -> Int {
  switch op {
  case .addition:
    return 2
  case .subtraction:
    return 2
  case .multiplication:
    return 3
  }
}

private func prefixNotation(_ tokens: [Token]) -> [Token] {
  var stack: [Token] = []
  var stackOperators: [Token] = []
  for token in tokens.reversed() {
    switch token {
    case .number(_):
      stack.append(token)
    case .rollRequest(_):
      stack.append(token)
    case let .operation(op):
      while case let .operation(last) = stackOperators.last, precedence(op) < precedence(last) {
        stack.append(stackOperators.removeLast())
      }
      stackOperators.append(token)
    case .openParen:
      while stackOperators.last != .closeParen {
        stack.append(stackOperators.removeLast())
      }
      if stackOperators.last != .closeParen {
        // TODO errors
        fatalError("wrong parens!")
      }
      stackOperators.removeLast()
    case .closeParen:
      stackOperators.append(token)
    }
  }
  stack.append(contentsOf: stackOperators.reversed())
  return stack.reversed()
}
