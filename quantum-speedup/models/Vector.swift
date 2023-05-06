//
//  Vector.swift
//  quantum-speedup
//
//  Created by Rustam Khakhuk on 12.11.2022.
//

import Foundation

public class Vector {
    public var values: [Complex]

    var size: Int { values.count }

    subscript(index: Int) -> Complex {
        get {
            return values[index]
        }
        set {
            values[index] = newValue
        }
    }

    public init(values: [Complex]) {
        self.values = values
    }
}

extension Vector: Equatable {
    public static func == (left: Vector, right: Vector) -> Bool {
        return left.values == right.values
    }
}

extension Vector: CustomStringConvertible {
    public var description: String {
        var result = ""

        for x in 0..<size {
            result += "\(values[x].re), "
        }

        return result
    }
    
    public static func basicVector(index: Int, size: Int) -> [Double] {
        var array = Array.init(repeating: 0.0, count: size)
        array[index] = 1.0
        return array
    }
}
