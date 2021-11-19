//
//  RollerResponse.swift
//  
//
//  Created by Ivan Chalov on 19.04.2021.
//

public struct RollerResponse: CustomDebugStringConvertible {
  public var rolls: [Roll]
  public var result: Int

  public var debugDescription: String {
    return "result: \(result) rolls: \(rolls.map { $0.isDiscarded ? "!(\($0.result))" : "\($0.result)"} )"
  }
}
