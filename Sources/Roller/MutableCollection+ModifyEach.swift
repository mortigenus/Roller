//
//  File.swift
//  
//
//  Created by Ivan Chalov on 19.04.2021.
//

import Foundation

extension MutableCollection {
  /// Calls the given closure on each element in the collection in the same order as a `for-in` loop.
  ///
  /// The `modifyEach` method provides a mechanism for modifying all of the contained elements in a `MutableCollection`. It differs
  /// from `forEach` or `for-in` by providing the contained elements as `inout` parameters to the closure `body`. In some cases this
  /// will allow the parameters to be modified in-place in the collection, without needing to copy them or allocate a new collection.
  ///
  /// - parameters:
  ///    - body: A closure that takes each element of the sequence as an `inout` parameter
  @inlinable
  mutating func modifyEach(_ body: (inout Element) throws -> Void) rethrows {
    var index = self.startIndex
    while index != self.endIndex {
      try body(&self[index])
      self.formIndex(after: &index)
    }
  }
}
