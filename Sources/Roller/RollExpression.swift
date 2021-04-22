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
    case .addition:
      guard let expr1 = create(&tokens), let expr2 = create(&tokens) else { return nil }
      return .add(expr1, expr2)
    case .subtraction:
      guard let expr1 = create(&tokens), let expr2 = create(&tokens) else { return nil }
      return .subtract(expr1, expr2)
    case .number(let x):
      return .number(x)
    case .rollRequest(let request):
      return .roll(request)
    }
  }
}

private enum Token {
  case number(Int)
  case rollRequest(RollRequest)
  case addition
  case subtraction
}

private let number = Skip(Whitespace<Substring.UTF8View>()).take(Int.parser()).skip(Whitespace())
  .map(Token.number).eraseToAnyParser()
private let symbol = { (symbol: String) in
  Skip(Whitespace<Substring.UTF8View>()).skip(StartsWith(symbol.utf8)).skip(Whitespace())
}

private let addition = symbol("+").map { Token.addition }.eraseToAnyParser()
private let subtraction = symbol("-").map { Token.subtraction }.eraseToAnyParser()
private let roll = Skip(Whitespace<Substring.UTF8View>())
  .take(Parsers.SubstringToUTF8View(upstream: RollRequest.parser()))
  .skip(Whitespace())
  .map(Token.rollRequest).eraseToAnyParser()

private let tokenParser = OneOfMany([
  addition,
  subtraction,
  roll,
  number,
])

private let tokensParser = Many(tokenParser)

private func prefixNotation(_ tokens: [Token]) -> [Token] {
  var stack: [Token] = []
  var stackOperators: [Token] = []
  for token in tokens.reversed() {
    switch token {
    case .number(_):
      stack.append(token)
    case .rollRequest(_):
      stack.append(token)
    case .addition:
      stackOperators.append(token)
    case .subtraction:
      stackOperators.append(token)
    }
  }
  stack.append(contentsOf: stackOperators.reversed())
  return stack.reversed()
}
