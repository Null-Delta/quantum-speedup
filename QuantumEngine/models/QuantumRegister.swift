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
    @Published public private(set) var state: Vector

    //кол-во кубит, хранящихся регистре
    public private(set) var size: Int
    public private(set) var dimensity: Int

    public var stateSum: Float {
        var sum: Float = 0.0

        for stateIndex in 0..<state.size {
            sum += powf(state[stateIndex].module, 2)
        }

        return Float(sum.roundToPlaces(places: 8))
    }

    public init(register: [Double], dimensity: Int) {
        size = register.count
        self.dimensity = dimensity
        state = Vector(
            values: [Double].tensorMultiply(
                with: register.map {
                    Vector.basicVector(index: Int($0), size: dimensity)
                }
            ).map {
                Complex(re: Float($0), im: 0)
            }
        )
    }
    
    public func updateRegister(register: [Double]) {
        size = register.count
        state = Vector(
            values: [Double].tensorMultiply(
                with: register.map {
                    Vector.basicVector(index: Int($0), size: dimensity)
                }
            ).map {
                Complex(re: Float($0), im: 0)
            }
        )
    }

    // Применение вентеля к регистру
    public func apply(valve: Valve) {
        state = state * valve.generateMatrix(for: self)
    }

    // Измерение состояния определенного кудита
    public func measure(at index: Int) -> Int {
        // вычисление вектора вероятностей измерения базисных состояний
        let probabilities = calculateProbabilities(at: index)

        var result = Float.random(in: 0...1)

        // значение, которое по итогу будет измерено
        var measuredValue: Int = -1
        
        for i in 0..<probabilities.count {
            if result > probabilities[i] {
                result -= probabilities[i]
            } else {
                measuredValue = i
                break
            }
        }
        
        let k = 1 / probabilities[measuredValue]

        let newState = Vector(values: .init(repeating: 0, count: state.size))

        // изменение состояния регистра с учетом измеренного кудита
        for stateIndex in 0..<state.size {
            if checkIndex(number: stateIndex, value: measuredValue, forIndex: index) {
                newState[stateIndex] = state[stateIndex] * Complex(re: sqrtf(k), im: 0)
            } else {
                newState[stateIndex] = 0
            }
        }
        
        state = newState

        return measuredValue
    }
    
    // расчет вероятностей для каждого возможного значения бита
    private func calculateProbabilities(at index: Int) -> [Float] {

        var probabilities: [Float] = .init(repeating: 0, count: dimensity)

        // проходимся по всем базисным состояниям
        for dim in 0..<dimensity {
            for stateIndex in 0..<state.size {
                // если у текущего вектора на позиции index находится значение dim
                if checkIndex(number: stateIndex, value: dim, forIndex: index) {
                    // увеличиваем вероятость знчения dim
                    probabilities[dim] += powf(state[stateIndex].module, 2)
                }
            }
        }

        return probabilities
    }

    private func checkIndex(number: Int, value: Int, forIndex index: Int) -> Bool {
        return number.bit(at: size - index - 1, dimensity: dimensity) == value
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
