//
//  QuantumRegister.swift
//  quantum-speedup
//
//  Created by Rustam Khakhuk on 12.11.2022.
//

import Foundation

// регистр памяти, представляющий из себя
// состояние квантовой системы, состоящей из множества кубит
public class QuantumRegister: ObservableObject {
    @Published private(set) var state: Vector

    //кол-во кубит, хранящихся регистре
    public private(set) var size: Int

    public var stateSum: Float {
        var sum: Float = 0.0

        for stateIndex in 0..<state.size {
            sum += powf(state[stateIndex].module, 2)
        }

        return Float(sum.roundToPlaces(places: 8))
    }

    public init(register: [Double]) {
        size = register.count
        state = Vector(values: [Double].tensorMultiply(with: register.map { $0 == 0 ? [1, 0] : [0, 1] }).map { Complex(re: Float($0), im: 0) } )
    }
    
    public func updateRegister(register: [Double]) {
        size = register.count
        state = Vector(values: [Double].tensorMultiply(with: register.map { $0 == 0 ? [1, 0] : [0, 1] }).map { Complex(re: Float($0), im: 0) } )
    }

    // Применение вентеля к регистру
    public func apply(valve: Valve) {
        state = state * valve.generateMatrix(for: self)
    }

    // Измерение состояния определенного бита
    public func measure(at index: Int) -> Int {
        var zeroProbability: Float = 0.0
        
        let checkIndex: (Int, Int) -> Bool = { [self] in
            return $0.bit(at: size - index - 1) == $1
        }

        for stateIndex in 0..<state.size {
            if checkIndex(stateIndex, 0) {
                zeroProbability += powf(state[stateIndex].module, 2)
            }
        }

        let result = Float.random(in: 0...1)
        let isZero = result < zeroProbability

        let k = 1 / (isZero ? zeroProbability : (1 - zeroProbability))

        let newState = Vector(values: .init(repeating: 0, count: state.size))

        for stateIndex in 0..<state.size {
            if checkIndex(stateIndex, isZero ? 0 : 1) {
                newState[stateIndex] = state[stateIndex] * Complex(re: sqrtf(k), im: 0)
            } else {
                newState[stateIndex] = 0
            }
        }
        
        state = newState

        return isZero ? 0 : 1
    }
}


extension QuantumRegister {
    // генерация базисного состояния под индексом stateIndex
    public func basicState(stateIndex: Int) -> Vector {
        let state: Vector = Vector(values: [])
        for index in 0..<self.state.size {
            state.values.append(index == stateIndex ? 1 : 0)
        }

        return state
    }

    public func stateIndex(state: Vector) -> Int {
        return state.values.firstIndex(where: { $0.re == 1.0 }) ?? -1
    }
}

extension QuantumRegister {
    public func getProbabilitys(for bits: [Int]) -> [Float] {
        //return MetalContext.shared.probabilitys(register: self, indexes: bits)
        
        var result: [Float] = .init(repeating: 0, count: Int(powf(2, Float(bits.count))))
        
        for i in 0..<Int(powf(2, Float(bits.count))) {
            let vector = i.bits(size: bits.count)
            for j in 0..<self.state.size {
                let registerVector = j.bits(size: self.size)
                
                if checkVectors(vector1: vector, vector2: registerVector, indexes: bits) {
                    result[i] += powf(self.state.values[j].module, 2)
                }
            }
        }
        
        return result
    }
    
    private func checkVectors(vector1: [Int], vector2: [Int], indexes: [Int]) -> Bool {
        for i in 0..<indexes.count {
            if vector1[i] != vector2[indexes[i]] {
                return false
            }
        }
        
        return true
    }
}
