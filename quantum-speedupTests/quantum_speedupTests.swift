//
//  quantum_speedupTests.swift
//  quantum-speedupTests
//
//  Created by Rustam Khakhuk on 12.11.2022.
//

import XCTest
import quantum_speedup

final class quantum_speedupTests: XCTestCase {
    func testVectorMultMatrix() throws {
        let vector = Vector(values: [0, 0, 0, 0, 1, 0, 0, 0])
        let matrix = Matrix(values: [
            0, 0, 1, 0, 0, 0, 0, 0,
            0, 0, 0, 1, 0, 0, 0, 0,
            1, 0, 0, 0, 0, 0, 0, 0,
            0, 1, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 1, 0,
            0, 0, 0, 0, 0, 0, 0, 1,
            0, 0, 0, 0, 1, 0, 0, 0,
            0, 0, 0, 0, 0, 1, 0, 0,

        ])

        let result = vector * matrix
        print(result.values)

        XCTAssert(result == Vector(values: [0, 0, 0, 0, 0, 0, 1, 0]) )
    }

    func testMatrixTensorMatrix() throws {
        let matrix1 = Matrix(values: [
            1, 1,
            1, -1
        ])

        let matrix2 = Matrix(values: [
            1, 0,
            0, 1
        ])

        let result = (matrix1 ** matrix2) ** matrix2

        print(result)

        XCTAssert(((matrix1 ** matrix2) ** matrix2) == Matrix(values: [
            1, 0, 0, 0, 1, 0, 0, 0,
            0, 1, 0, 0, 0, 1, 0, 0,
            0, 0, 1, 0, 0, 0, 1, 0,
            0, 0, 0, 1, 0, 0, 0, 1,
            1, 0, 0, 0, -1, 0, 0, 0,
            0, 1, 0, 0, 0, -1, 0, 0,
            0, 0, 1, 0, 0, 0, -1, 0,
            0, 0, 0, 1, 0, 0, 0, -1
        ]))

        XCTAssert(((matrix2 ** matrix1) ** matrix2) == Matrix(values: [
            1, 0, 1, 0, 0, 0, 0, 0,
            0, 1, 0, 1, 0, 0, 0, 0,
            1, 0,-1, 0, 0, 0, 0, 0,
            0, 1, 0,-1, 0, 0, 0, 0,
            0, 0, 0, 0, 1, 0, 1, 0,
            0, 0, 0, 0, 0, 1, 0, 1,
            0, 0, 0, 0, 1, 0,-1, 0,
            0, 0, 0, 0, 0, 1,0, -1,
        ]))

        XCTAssert(((matrix2 ** matrix2) ** matrix1) == Matrix(values: [
            1, 1, 0, 0, 0, 0, 0, 0,
            1,-1, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 1, 0, 0, 0, 0,
            0, 0, 1,-1, 0, 0, 0, 0,
            0, 0, 0, 0, 1, 1, 0, 0,
            0, 0, 0, 0, 1,-1, 0, 0,
            0, 0, 0, 0, 0, 0, 1, 1,
            0, 0, 0, 0, 0, 0, 1,-1
        ]))
    }

    func testTensorMult() throws {
        let hadamar = Matrix(values: [1, 1, 1, -1])
        var result = hadamar

        measure {
            result = hadamar

            for _ in 1..<12 {
                result = result ** hadamar
            }
        }

        XCTAssert(result.size == Int(powf(2, 12)))
    }
    
    func testFirst() throws {
        // zero
        let func1: Matrix = .init(values: [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        ])

        // one
        let func2: Matrix = .init(values: [
            0, 1, 0, 0,
            1, 0, 0, 0,
            0, 0, 0, 1,
            0, 0, 1, 0
        ])

        // X
        let func3: Matrix = .init(values: [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 0, 1,
            0, 0, 1, 0
        ])

        // not X
        let func4: Matrix = .init(values: [
            0, 1, 0, 0,
            1, 0, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        ])

        let funcs = [ func1, func2, func3, func4 ]
        for i in 0..<4 {
            let qRegister = QuantumRegister(register: [0, 1], dimensity: 2)

            qRegister.apply(valve: H(at: 0))
            qRegister.apply(valve: H(at: 1))
            
            qRegister.apply(valve: CustomValve(matrix: funcs[i]))

            qRegister.apply(valve: H(at: 0))

            XCTAssert((i < 2 ? 0 : 1) == qRegister.measure(at: 0))
        }
    }
    
    func testBits() {
        let value: Int = 123
        XCTAssert([1, 7, 3] == value.bits(size: 3, dimensity: 8))
    }

    func testControlledValveConstruct() {
        let register = QuantumRegister(register: [0,0,0,0,0,0,0,0,0,0], dimensity: 2)
        let valve = SingleValve(generator: IdentityMatrixGenerator(), quditIndex: 0)
        let controlledValve = ControlledValve(controlIndexes: [0], valve: valve)

        measure {
            register.apply(valve: controlledValve)
        }
    }

    func testControlledValveConstructCurrect() {
        let register = QuantumRegister(register: [0, 0], dimensity: 2)
        let valve = SingleValve(generator: XMatrixGenerator(), quditIndex: 1)
        let controlledValve = ControlledValve(controlIndexes: [0], valve: valve)

        XCTAssert(
            Matrix(values: [
                1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 0, 1,
                0, 0, 1, 0
            ]) == controlledValve.generateMatrix(for: register)
        )
    }
    
    func testXGenerator() {
        XCTAssert(
            Matrix(values: [
                0, 1,
                1, 0
            ]) == XMatrixGenerator().generate(dimension: 2)
        )
        
        XCTAssert(
            Matrix(values: [
                0, 0, 1,
                1, 0, 0,
                0, 1, 0
            ]) == XMatrixGenerator().generate(dimension: 3)
        )
    }

    func testMatrixRotate() throws {
        let matrix = Matrix(values: .init(repeating: 1, count: 2048 * 2048))

        measure {
            _ = matrix.rotated;
        }
    }

    func testMatrixMultMatrix() {
        let matrix1 = Matrix(values: [4, 2, 9, 0])
        let matrix2 = Matrix(values: [3, 1, -3, 4])

        XCTAssert((matrix1 * matrix2) == Matrix(values: [6, 12, 27, 9]))
    }

    func testCNOTConstruct() {
        let size = 8
        let controlIndex = 6
        let valveIndex = 3
        let register = QuantumRegister(register: .init(repeating: 0, count: size), dimensity: 2)

        let finalResult = ControlledValve(controlIndexes: [controlIndex], valve: X(at: valveIndex)).generateMatrix(for: register)
        var result1 = Matrix(values: [1])
        var result2 = Matrix(values: [1])

        for i in 0..<size {
            if i == controlIndex {
                let matrix = Matrix(values: .init(repeating: 0, count: Int(powf(2, Float(register.dimensity)))))
                matrix[0, 0] = 1

                result1 = result1 ** matrix
            } else {
                result1 = result1 ** Matrix.identity(dimension: 2)
            }
        }

        for i in 0..<size {
            if i == controlIndex {
                let matrix = Matrix(values: .init(repeating: 0, count: Int(powf(2, Float(register.dimensity)))))
                matrix[1, 1] = 1

                result2 = result2 ** matrix
            } else if i == valveIndex {
                result2 = result2 ** XMatrixGenerator().generate(dimension: 2)
            } else {
                result2 = result2 ** Matrix.identity(dimension: 2)
            }
        }

        XCTAssert((result1 + result2) == finalResult)
    }

    func testFurie() {
        let size: Float = 8
        let dimention = Int(powf(2, size))
        let register = QuantumRegister(register: .init(repeating: 0, count: Int(size)), dimensity: 2)

        let matrixQRT = RQFT(qbitCount: Int(size)).generateMatrix(for: register)

        var generatedQRT = Matrix.identity(dimension: dimention)

        for i in 0..<Int(size) {
            generatedQRT = generatedQRT * H(at: i).generateMatrix(for: register)

            for j in (i + 1)..<Int(size) {
                let angle = (2 * Float.pi) / powf(2, Float(j - i + 1))
                let controlledRZ = ControlledValve(controlIndexes: [j], valve: RZ(at: i, angle: angle))
                generatedQRT = generatedQRT * controlledRZ.generateMatrix(for: register)
            }
        }

        for i in 0..<Int(size) / 2 {
            generatedQRT = generatedQRT * Swap(i, Int(size) - i - 1).generateMatrix(for: register)
        }


        register.apply(valve: CustomValve(matrix: generatedQRT))
        print(register.stateSum)

        XCTAssert(matrixQRT == generatedQRT)
    }
}
