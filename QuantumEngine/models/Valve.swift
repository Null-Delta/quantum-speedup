//
//  Valve.swift
//  quantum-speedup
//
//  Created by Rustam Khakhuk on 12.11.2022.
//

import Foundation

// Протокол, описывающий квантовый вентиль
// Вентиль должен предоставлять унитарную матрицу для данного регистра
public protocol Valve: AnyObject {
    func generateMatrix(for register: QuantumRegister) -> Matrix
}

// Класс однокудитных вентилей
public class SingleValve: Valve {

    // Генератор унитарной матрицы, описывающий вентиль
    private(set) var generator: MatrixGenerator

    // Индекс кудита, к которому применяется вентиль
    var quditIndex: Int

    public init(generator: MatrixGenerator, quditIndex: Int) {
        self.generator = generator
        self.quditIndex = quditIndex
    }

    public func generateMatrix(for register: QuantumRegister) -> Matrix {
        var result: Matrix = quditIndex == 0 ? generator.generate(dimension: register.dimensity) : Matrix.identity(dimension: register.dimensity)

        for i in 1..<register.size {
            result = result ** (quditIndex == i ? generator.generate(dimension: register.dimensity) : Matrix.identity(dimension: register.dimensity))
        }
        return result
    }
}

// Класс кастомных вентелей
// Превращяет получаемую матрицу в вентиль без дополнительных преобразований
public class CustomValve: Valve {
    private(set) var matrix: Matrix

    public init(matrix: Matrix) {
        self.matrix = matrix
    }

    public func generateMatrix(for register: QuantumRegister) -> Matrix {
        return matrix
    }
}


// Класс контроллируемых вентелей
public class ControlledValve: Valve {
    // Индексы контролирующих кубитов
    private(set) var controlIndexes: [Int]

    // Применяемый вентиль
    private(set) var valve: Valve

    public init(controlIndexes: [Int], valve: Valve) {
        self.controlIndexes = controlIndexes
        self.valve = valve
    }

    public func generateMatrix(for register: QuantumRegister) -> Matrix {
        if 
            let singleValve = valve as? SingleValve,
            let minIndex = [[singleValve.quditIndex], controlIndexes].flatMap({$0}).min(),
            let maxIndex = [[singleValve.quditIndex], controlIndexes].flatMap({$0}).max(),
            !(minIndex == 0 && maxIndex == register.size - 1)

        {
            let smallRegisterSize = maxIndex - minIndex + 1
            let smallRegister = QuantumRegister(register: Array(repeating: 0, count: smallRegisterSize), dimensity: 2)

            let singleValveCopy = singleValve
            singleValveCopy.quditIndex -= minIndex
            let smallControlledValve = ControlledValve(
                controlIndexes: controlIndexes.map { $0 - minIndex },
                valve: singleValveCopy
            )

            var resultMatrix = minIndex == 0 ? smallControlledValve.generateMatrix(for: smallRegister) : Matrix.identity(dimension: 2)

            if minIndex != 0 {
                for _ in 1..<minIndex {
                    resultMatrix = resultMatrix ** Matrix.identity(dimension: 2)
                }

                resultMatrix = resultMatrix ** smallControlledValve.generateMatrix(for: smallRegister)
            }
            
            for _ in (maxIndex + 1)..<register.size {
                resultMatrix = resultMatrix ** Matrix.identity(dimension: 2)
            }

            return resultMatrix
        } else {
            var values: [Vector] = .init(repeating: Vector(values: []), count: register.state.size)
            let valveMatrix = valve.generateMatrix(for: register)

            for qubitIndex in 0..<register.state.size {
                if checkControlQbits(for: qubitIndex, size: register.size) {
                    values[qubitIndex] = register.basicState(stateIndex: qubitIndex) * valveMatrix
                } else {
                    values[qubitIndex] = register.basicState(stateIndex: qubitIndex)
                }
            }
            return Matrix(values: values.flatMap({ $0.values })).rotated
        }
    }

    // Проверяет являются ли все биты в двоичном представлении данного числа единицами
    private func checkControlQbits(for inputIndex: Int, size: Int) -> Bool {
        for index in controlIndexes {
            if inputIndex.bit(at: size - index - 1) == 0 {
                return false
            }
        }

        return true
    }
}

public class FunctionValve: Valve {
    var x: Int
    var m: Int
    var inputSize: Int
    var outputSize: Int

    public init(x: Int, m: Int, inputSize: Int, outputSize: Int) {
        self.x = x
        self.m = m
        self.inputSize = inputSize
        self.outputSize = outputSize
    }

    public func generateMatrix(for register: QuantumRegister) -> Matrix {
        return MetalContext.shared.functionMatrix(
            x: x,
            m: m,
            outputSize: outputSize,
            size: Int(powf(
                Float(register.dimensity),
                Float(register.size)
            ))
        ).rotated
    }
}

public class GroverValve: Valve {
    var indexes: [Int]

    public init(indexes: [Int]) {
        self.indexes = indexes
    }

    public func generateMatrix(for register: QuantumRegister) -> Matrix {
        var matrix = Matrix.identity(dimension: register.dimensity)
        
        for _ in 0..<register.size - 1 {
            matrix = matrix ** Matrix.identity(dimension: register.dimensity)
        }
        
        for trueIndex in indexes {
            matrix[trueIndex, trueIndex] = -1
        }
        
        return matrix
    }
}
