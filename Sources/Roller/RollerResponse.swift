//
//  RollerResponse.swift
//  
//
//  Created by Ivan Chalov on 19.04.2021.
//

import Prelude

public struct RollerResponse: CustomDebugStringConvertible {
  public var rolls: [Roll]
  public var result: Int

  public var debugDescription: String {
    let summStr = rolls
      .map {
        $0.isDiscarded ? "!(\($0.result))" : String($0.result)
      }
      .joined(separator: " + ")
    return summStr + " = \(result)"
  }
}
