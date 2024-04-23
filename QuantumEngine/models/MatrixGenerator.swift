//
//  MatrixGenerator.swift
//  quantum-speedup
//
//  Created by Rustam Khakhuk on 02.05.2023.
//

import Foundation

public protocol MatrixGenerator: AnyObject {
    func generate(dimension: Int) -> Matrix
}

public class IdentityMatrixGenerator: MatrixGenerator {
    public func generate(dimension: Int) -> Matrix {
        Matrix.identity(dimension: dimension)
    }

    public init() { }
}

public class XMatrixGenerator: MatrixGenerator {
    public func generate(dimension: Int) -> Matrix {
        return Matrix(
            values: (0..<dimension)
                .map {
                    if $0 == 0 {
                        return Vector.basicVector(index: dimension - 1, size: dimension)
                    } else {
                        return Vector.basicVector(index: $0 - 1, size: dimension)
                    }
                }
                .flatMap { $0 }
                .map {
                    Complex(re: Float($0), im: 0)
                }
        )
    }

    public init() { }
}


public class ZMatrixGenerator: MatrixGenerator {
    public func generate(dimension: Int) -> Matrix {
        let matrix = Matrix(values: .init(repeating: 0, count: dimension * dimension))

        for i in 0..<dimension {
            let x = (2 * Float.pi) / Float(dimension)

            matrix[i, i] = Complex(re: cos(Float(i) * x), im: sin(Float(i) * x))
        }

        return matrix
    }

    public init() { }
}

public class RZMatrixGenerator: MatrixGenerator {
    let angle: Float

    public func generate(dimension: Int) -> Matrix {
        let matrix = Matrix(values: .init(repeating: 0, count: dimension * dimension))

        for i in 0..<dimension {
            matrix[i, i] = Complex(re: cos(Float(i) * angle), im: sin(Float(i) * angle))
        }

        return matrix
    }

    public init(angle: Float) {
        self.angle = angle
    }
}

public class HMatrixGenerator: MatrixGenerator {
    public func generate(dimension: Int) -> Matrix {
        let matrix = Matrix(values: .init(repeating: 0, count: dimension * dimension))

        for x in 0..<dimension {
            for y in 0..<dimension {
                let value = (2 * Float.pi) / Float(dimension)
                
                matrix[x, y] = Complex(
                    re: cos(value * Float(x * y)),
                    im: sin(value * Float(x * y))
                )
                matrix[x, y] = matrix[x, y] * Complex(
                    re: 1 / sqrt(Float(dimension)),
                    im: 0
                )
            }
        }

        return matrix
    }

    public init() { }
}
