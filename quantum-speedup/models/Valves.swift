//
//  Valves.swift
//  quantum-speedup
//
//  Created by Rustam Khakhuk on 12.11.2022.
//

import Foundation

// Кладовка стандартных вентилей

class I: SingleValve {
    init(at qbitIndex: Int) {
        super.init(
            generator: IdentityMatrixGenerator(),
            qbitIndex: qbitIndex
        )
    }
}

public class H: SingleValve {
    public init(at qbitIndex: Int) {
        super.init(
            generator: HMatrixGenerator(),
            qbitIndex: qbitIndex
        )
    }
}

class X: SingleValve {
    init(at qbitIndex: Int) {
        super.init(
            generator: XMatrixGenerator(),
            qbitIndex: qbitIndex
        )
    }
}

class Z: SingleValve {
    init(at qbitIndex: Int) {
        super.init(
            generator: ZMatrixGenerator(),
            qbitIndex: qbitIndex
        )
    }
}

public class Swap: Valve {
    private(set) var firstIndex: Int
    private(set) var secondIndex: Int

    public init(_ firstIndex: Int, _ secondIndex: Int) {
        self.firstIndex = firstIndex
        self.secondIndex = secondIndex
    }

    public func generateMatrix(for register: QuantumRegister) -> Matrix {
        var values: [Vector] = []

        for inputIndex in 0..<register.state.size {
            var swappedIndex = inputIndex.bits(size: register.size)
            let firtsBit = swappedIndex[firstIndex]
            let secondBit = swappedIndex[secondIndex]

            swappedIndex[firstIndex] = secondBit
            swappedIndex[secondIndex] = firtsBit
            values.append(register.basicState(stateIndex: swappedIndex.toInt()))
        }
        return .init(values: values.flatMap({ $0.values })).rotated
    }
}


public class RQFT: Valve {
    private(set) var qbitCount: Int

    public init(qbitCount: Int) {
        self.qbitCount = qbitCount
    }

    public func generateMatrix(for register: QuantumRegister) -> Matrix {
        var qftMatrix = Matrix(values: .init(
            repeating: 0,
            count: Int(powf(Float(register.dimension), Float(qbitCount)) * powf(Float(register.dimension), Float(qbitCount))))
        )

        for x in 0..<qftMatrix.size {
            for y in 0..<qftMatrix.size {
                let value = (2 * Float.pi) / powf(2, Float(qbitCount)) * Float(x * y)
                qftMatrix[x, y] = Complex(re: cos(value), im: sin(value)) * Complex(re: 1 / sqrtf(powf(2, Float(qbitCount))), im: 0)
                qftMatrix[x, y] = qftMatrix[x, y].conjugate
            }
        }

        for _ in 0..<register.size - qbitCount {
            qftMatrix = qftMatrix ** Matrix.identity(dimension: register.dimension)
        }

        return qftMatrix.rotated
    }
}
