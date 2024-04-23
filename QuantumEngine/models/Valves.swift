//
//  Valves.swift
//  quantum-speedup
//
//  Created by Rustam Khakhuk on 12.11.2022.
//

import Foundation

// Кладовка стандартных вентилей

public class I: SingleValve {
    public init(at quditIndex: Int) {
        super.init(
            generator: IdentityMatrixGenerator(),
            quditIndex: quditIndex
        )
    }
}

public class H: SingleValve {
    public init(at quditIndex: Int) {
        super.init(
            generator: HMatrixGenerator(),
            quditIndex: quditIndex
        )
    }
}

public class X: SingleValve {
    public init(at quditIndex: Int) {
        super.init(
            generator: XMatrixGenerator(),
            quditIndex: quditIndex
        )
    }
}

public class RZ: SingleValve {
    public init(at quditIndex: Int, angle: Float) {
        super.init(
            generator: RZMatrixGenerator(angle: angle),
            quditIndex: quditIndex
        )
    }
}

class Z: SingleValve {
    init(at quditIndex: Int) {
        super.init(
            generator: ZMatrixGenerator(),
            quditIndex: quditIndex
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
        if
            let minIndex = [firstIndex, secondIndex].min(),
            let maxIndex = [firstIndex, secondIndex].max(),
            !(minIndex == 0 && maxIndex == register.size - 1)
        {
            let smallRegisterSize = maxIndex - minIndex + 1
            let smallRegister = QuantumRegister(register: Array(repeating: 0, count: smallRegisterSize), dimensity: 2)

            let singleValveCopy = Swap(firstIndex - minIndex, secondIndex - minIndex)

            var resultMatrix = minIndex == 0 ? singleValveCopy.generateMatrix(for: smallRegister) : Matrix.identity(dimension: 2)

            if minIndex != 0 {
                for _ in 1..<minIndex {
                    resultMatrix = resultMatrix ** Matrix.identity(dimension: 2)
                }

                resultMatrix = resultMatrix ** singleValveCopy.generateMatrix(for: smallRegister)
            }

            for _ in (maxIndex + 1)..<register.size {
                resultMatrix = resultMatrix ** Matrix.identity(dimension: 2)
            }

            return resultMatrix

        } else {
            var values: [Vector] = []

            for inputIndex in 0..<register.state.size {
                var swappedIndex = inputIndex.bits(size: register.size)
                let firtsBit = swappedIndex[firstIndex]
                let secondBit = swappedIndex[secondIndex]

                swappedIndex[firstIndex] = secondBit
                swappedIndex[secondIndex] = firtsBit
                values.append(register.basicState(stateIndex: swappedIndex.toInt(dimension: 2)))
            }
            return .init(values: values.flatMap({ $0.values })).rotated
        }
    }
}

public class RQFT: Valve {
    private(set) var qbitCount: Int

    public init(qbitCount: Int) {
        self.qbitCount = qbitCount
    }

    public func generateMatrix(for register: QuantumRegister) -> Matrix {
        let N = powf(Float(register.dimensity), Float(qbitCount))

        var qftMatrix = Matrix(values: .init(
            repeating: 0,
            count: Int(powf(Float(register.dimensity), Float(qbitCount)) * powf(Float(register.dimensity), Float(qbitCount))))
        )
        
        for x in 0..<qftMatrix.size {
            for y in 0..<qftMatrix.size {
                let value =
                (2 * Float.pi) * Float(x * y) / N

                qftMatrix[x, y] =
                Complex(
                    re: cos(value),
                    im: sin(value)
                ) *
                Complex(
                    re: 1 / sqrtf(N),
                    im: 0
                )
            }
        }

        for _ in 0..<register.size - qbitCount {
            qftMatrix = qftMatrix ** Matrix.identity(dimension: register.dimensity)
        }

        return qftMatrix.rotated
    }
}
