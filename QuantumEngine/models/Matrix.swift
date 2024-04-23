//
//  Matrix.swift
//  quantum-speedup
//
//  Created by Rustam Khakhuk on 12.11.2022.
//

import Foundation

public class Matrix {
    public var values: [Complex]

    public var size: Int { return Int(sqrt(Float(values.count))) }

    public subscript(x: Int, y: Int) -> Complex {
        get {
            return values[y * size + x]
        }

        set {
            values[y * size + x] = newValue
        }
    }

    public init(values: [Complex]) {
        self.values = values
    }
}

extension Matrix: Equatable {
    public static func == (left: Matrix, right: Matrix) -> Bool {
        return left.values == right.values
    }
}

extension Matrix: CustomStringConvertible {
    public var description: String {
        var result = ""

        for y in 0..<size {
            for x in 0..<size {
                
                result += "\(values[y * size + x]), "
            }
            result += "\n"
        }

        return result
    }
}

infix operator **;

extension Matrix {
    public static func *(left: Vector, right: Matrix) -> Vector {
        return MetalContext.shared.vectorMultMatrix(vector: left, matrix: right)
    }

    public static func *(left: Matrix, right: Matrix) -> Matrix {
        return MetalContext.shared.matrixMultMatrix(matrixLeft: left, matrixRight: right)
    }

    public static func +(left: Matrix, right: Matrix) -> Matrix {
        return MetalContext.shared.matrixPlusMatrix(matrixLeft: left, matrixRight: right)
    }

    public static func **(left: Matrix, right: Matrix) -> Matrix {
        return MetalContext.shared.MatrixTensorMatrix(m1: left, m2: right)
    }
}

extension Matrix {
    public var rotated: Matrix {
        return MetalContext.shared.rotateMatrix(matrix: self)
    }
}

extension Matrix {
    public static func identity(dimension: Int) -> Matrix {
        let matrix = Matrix(values: .init(repeating: 0, count: dimension * dimension))

        for i in 0..<dimension {
            matrix[i, i] = 1
        }

        return matrix
    }
}
