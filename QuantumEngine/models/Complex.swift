//
//  Complex.swift
//  quantum-speedup
//
//  Created by Rustam Khakhuk on 12.11.2022.
//

import Foundation

public struct Complex {
    public var values: SIMD2<Float>

    public var re: Float { return values.x }
    public var im: Float { return values.y }

    public init(re: Float, im: Float) {
        values = .init(re, im)
    }
}

extension Complex: ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) {
        self = Complex(re: Float(value), im: 0)
    }
}

extension Complex: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = Complex(re: Float(value), im: 0)
    }
}

extension Complex: CustomStringConvertible {
    public var description: String {
        return "(\(re.roundToPlaces(places: 8)), \(im.roundToPlaces(places: 8)))"
    }
}

extension Complex: Equatable {
    public static func == (left: Complex, right: Complex) -> Bool {
        let placesCount = 4

        return left.values[0].roundToPlaces(places: placesCount) == right.values[0].roundToPlaces(places: placesCount) &&
            left.values[1].roundToPlaces(places: placesCount) == right.values[1].roundToPlaces(places: placesCount)
    }
}

// MARK: - Вспомогательные поля

public extension Complex {
    static let i = Complex(re: 0, im: 1)

    // комплексно-сопряженное число, для данного
    var conjugate: Complex {
        return Complex(re: re, im: -im)
    }

    var module: Float { sqrtf(powf(re, 2) + powf(im, 2)) }
}

// MARK: - Операции

public extension Complex {
    static func +(left: Complex, right: Complex) -> Complex {
        return Complex(
            re: left.re + right.re,
            im: left.im + right.im
        )
    }

    static func -(left: Complex, right: Complex) -> Complex {
        return Complex(
            re: left.re - right.re,
            im: left.im - right.im
        )
    }

    static func *(left: Complex, right: Complex) -> Complex {
        return Complex(
            re: left.re * right.re - left.im * right.im,
            im: left.re * right.im + left.im * right.re
        )
    }

    static func /(left: Complex, right: Complex) -> Complex {
        return Complex(
            re: (left.re * right.re + left.im * right.im) / (pow(right.re, 2) + pow(right.im, 2)),
            im: (left.im * right.re - left.re * right.im) / (pow(right.re, 2) + pow(right.im, 2))
        )
    }
}
