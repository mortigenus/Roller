//
//  main.swift
//  
//
//  Created by Ivan Chalov on 19.04.2021.
//

import Foundation
import ArgumentParser
import Creadline
import Roller

struct RollerMain: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "roll"
  )

  @Argument(help: """
  Description of dice to roll:
    Keep highest: 4d6kh3
    Drop lowest: 4d6dl1
    Drop highest: 3d4dh1
    Keep lowest: 3d4kl1
    Reroll equal: 2d4r1
    Reroll less: 2d4r<2
    Reroll less or equal: 2d4r<=2
    Reroll greater: 2d4r>2
    Reroll greater equal: 2d4r>=3
    Explode equal: 2d4x4
    Explode less: 2d4x<2
    Explode less or equal: 2d4x<=2
    Explode greater: 2d4x>2
    Explode greater equal: 2d4x>=3
    Count Successes equal: 2d4cs=4
    Count Successes less: 2d4cs<2
    Count Successes less or equal: 2d4cs<=2
    Count Successes greater: 2d4cs>2
    Count Successes greater equal: 2d4cs>=3
  """)
  var input: String?

  @Flag(name: .shortAndLong)
  var interactive: Bool = false

  mutating func run() throws {
    if interactive {
      while let input = readline("> ") {
        let str = String(cString: input)
        free(input)
        add_history(str)
        guard str != ":q" && str != "quit" else { return }
        printRoll(str)
      }
    } else {
      printRoll(input)
    }
  }

  private func printRoll(_ string: String?) {
    if let string = string, let result = Roller(string)?.eval() {
      print("\(String(reflecting: result))")
    } else {
      print("Something went wrong :sweatsmile:")
    }
  }
}

RollerMain.main()
