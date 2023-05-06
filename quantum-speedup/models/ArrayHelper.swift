//
//  ArrayHelper.swift
//  quantum-speedup
//
//  Created by Rustam Khakhuk on 12.11.2022.
//

import Foundation

infix operator **;

public extension Array<Double> {
    // тензорное произведение векторов
    static func **(leftValue: [Double], rightValue: [Double]) -> [Double] {
        var result: [Double] = .init(repeating: 0, count: leftValue.count * rightValue.count)

        for x in 0..<leftValue.count {
            for y in 0..<rightValue.count {
                result[x * rightValue.count + y] = leftValue[x] * rightValue[y]
            }
        }

        return result
    }

    static func tensorMultiply(with arrays: [[Double]]) -> [Double] {
        var result: [Double] = arrays[0]

        for i in 1..<arrays.count {
            result = result ** arrays[i]
        }

        return result
    }
}

public extension Float {
    /// Rounds the double to decimal places value
    func roundToPlaces(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return roundl(Double(self) * divisor) / divisor
    }
}

public extension Int {
    func bit(at: Int, dimensity: Int = 2) -> Int {
        var index = 0
        var value = self
        while(index != at) {
            value /= dimensity
            index += 1
        }
        
        return value % dimensity
    }

    func bits(size: Int, dimensity: Int = 2) -> [Int] {
        var array: [Int] = []

        for index in 0..<size {
            array.append(bit(at: index, dimensity: dimensity))
        }

        return array.reversed()
    }
}


public extension Array<Int> {
    func toInt(dimension: Int) -> Int {
        var result = 0

        for index in 0..<self.count {
            result += self[self.count - index - 1] * Int(powf(Float(dimension), Float(index)))
        }

        return result
    }
}
