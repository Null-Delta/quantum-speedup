//
//  ArrayHelper.swift
//  quantum-speedup
//
//  Created by Rustam Khakhuk on 12.11.2022.
//

import Foundation

infix operator **;

extension Array<Double> {
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

extension Float {
    /// Rounds the double to decimal places value
    func roundToPlaces(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return roundl(Double(self) * divisor) / divisor
    }
}

extension Int {
    func bit(at: Int) -> Int {
        return (self & (1 << at)) >> at
    }

    func bits(size: Int) -> [Int] {
        var array: [Int] = []

        for index in 0..<size {
            array.append(self.bit(at: index))
        }

        return array.reversed()
    }
}


extension Array<Int> {
    public func toInt() -> Int {
        var result = 0

        for index in 0..<self.count {
            result += self[self.count - index - 1] * Int(powf(2, Float(index)))
        }

        return result
    }
}
