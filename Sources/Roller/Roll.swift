//
//  Roll.swift
//  
//
//  Created by Ivan Chalov on 19.04.2021.
//

public struct Roll: Equatable {
  public var result: Int
  public var die: Int
  public var isDiscarded: Bool = false

  public init(result: Int, die: Int, isDiscarded: Bool = false) {
    self.result = result
    self.die = die
    self.isDiscarded = isDiscarded
  }

  mutating func discard() {
    self.isDiscarded = true
  }

  func discarded() -> Roll {
    var copy = self
    copy.discard()
    return copy
  }
}
