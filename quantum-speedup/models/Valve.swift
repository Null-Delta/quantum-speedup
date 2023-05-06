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

// Класс однокубитных вентелей
public class SingleValve: Valve {

    // Унитарная матрица, описывающая вентиль
    private(set) var generator: MatrixGenerator

    // Индекс кубита, к которому применяется вентиль
    private(set) var qbitIndex: Int

    public init(generator: MatrixGenerator, qbitIndex: Int) {
        self.generator = generator
        self.qbitIndex = qbitIndex
    }

    public func generateMatrix(for register: QuantumRegister) -> Matrix {
        var result: Matrix = qbitIndex == 0 ? generator.generate(dimension: register.dimensity) : Matrix.identity(dimension: register.dimensity)

        for i in 1..<register.size {
            result = result ** (qbitIndex == i ? generator.generate(dimension: register.dimensity) : Matrix.identity(dimension: register.dimensity))
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
