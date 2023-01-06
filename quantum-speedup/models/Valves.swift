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
            matrix: Matrix(values: [
                1, 0,
                0, 1
            ]),
            qbitIndex: qbitIndex
        )
    }
}

public class H: SingleValve {
    public init(at qbitIndex: Int) {
        super.init(
            matrix: Matrix(values: [
                1, 1,
                1,-1
            ].map { $0 / Complex(re: sqrt(2), im: 0) }),
            qbitIndex: qbitIndex
        )
    }
}

class X: SingleValve {
    init(at qbitIndex: Int) {
        super.init(
            matrix: Matrix(values: [
                0, 1,
                1, 0
            ]),
            qbitIndex: qbitIndex
        )
    }
}

class Y: SingleValve {
    init(at qbitIndex: Int) {
        super.init(
            matrix: Matrix(values: [
                0, Complex(re: 0, im: -1),
                .i, 0
            ]),
            qbitIndex: qbitIndex
        )
    }
}

class Z: SingleValve {
    init(at qbitIndex: Int) {
        super.init(
            matrix: Matrix(values: [
                1, 0,
                0,-1
            ]),
            qbitIndex: qbitIndex
        )
    }
}

public class R: SingleValve {
    public init(at qbitIndex: Int, angle: Float) {
        super.init(
            matrix: Matrix(values: [
                1, 0,
                0, Complex(re: cosf(angle), im: sinf(angle))
            ]),
            qbitIndex: qbitIndex
        )
    }
}

class S: SingleValve {
    init(at qbitIndex: Int) {
        super.init(
            matrix: Matrix(values: [
                1, 0,
                0, .i
            ]),
            qbitIndex: qbitIndex
        )
    }
}

class T: SingleValve {
    init(at qbitIndex: Int) {
        super.init(
            matrix: Matrix(values: [
                1, 0,
                0, Complex(re: cos(Float.pi / 4.0), im: sin(Float.pi / 4.0))
            ]),
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
        var qftMatrix = Matrix(values: .init(repeating: 0, count: Int(powf(2, Float(qbitCount)) * powf(2, Float(qbitCount)))))
        //TODO: fill matrix

        for x in 0..<qftMatrix.size {
            for y in 0..<qftMatrix.size {
                let value = (2 * Float.pi) / powf(2, Float(qbitCount)) * Float(x * y)
                qftMatrix[x, y] = Complex(re: cos(value), im: sin(value)) * Complex(re: 1 / sqrtf(powf(2, Float(qbitCount))), im: 0)
                qftMatrix[x, y] = qftMatrix[x, y].conjugate
            }
        }

        for _ in 0..<register.size - qbitCount {
            qftMatrix = qftMatrix ** Matrix(values: [1, 0, 0, 1])
        }

        return qftMatrix.rotated
    }
}
