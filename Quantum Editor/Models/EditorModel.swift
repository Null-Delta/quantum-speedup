//
//  EditorModel.swift
//  Quantum Editor
//
//  Created by Rustam Khakhuk on 17.04.2024.
//

import Foundation

final class EditorModel: ObservableObject {
    @Published var currentAlghoritmStep: Int?
    @Published var selectedCell: NSIndexPath?

    @Published var executor = AlghoritmExecutor()
    private var alghoritm: AlghoritmModel?

    func startAlghoritm(inputs: [Double], alghoritm: AlghoritmModel) {
        executor.configureRegister(inputs: inputs)
        self.alghoritm = alghoritm
        self.currentAlghoritmStep = 0
    }

    func makeAlghoritmStep() -> [String]? {
        guard
            let currentAlghoritmStep,
            let alghoritm
        else { return nil }

        if currentAlghoritmStep < alghoritm.steps.count {
            doStep(stepIndex: currentAlghoritmStep)
            self.currentAlghoritmStep = currentAlghoritmStep + 1
            return nil
        } else {
            executor.resetAlghoritm()
            self.alghoritm = nil
            self.currentAlghoritmStep = nil
            return (0..<alghoritm.quditsCount).map { executor.measureIndexes[$0].map { String($0) } ?? "-" }
        }
    }

    func doStep(stepIndex: Int) {
        guard 
            let step = alghoritm?.steps[stepIndex]
        else { return }

        if let valve = step.valves.first(where: { !$0.isSingle }) {
            switch valve {
            case .single, .measure:
                break
            case .controlled(let valve, let int, let int2):
                switch valve {
                case .X:
                    executor.execute(valves: [ControlledValve(controlIndexes: [int2], valve: X(at: int))])
                case .H:
                    executor.execute(valves: [ControlledValve(controlIndexes: [int2], valve: H(at: int))])
                case .Z:
                    executor.execute(valves: [ControlledValve(controlIndexes: [int2], valve: Z(at: int))])
                case .I:
                    executor.execute(valves: [ControlledValve(controlIndexes: [int2], valve: I(at: int))])
                case .RZ(let angle):
                    executor.execute(valves: [ControlledValve(controlIndexes: [int2], valve: RZ(at: int, angle: (2 * Float.pi) / powf(2, Float(angle))))])
                }
            case .swap(let int, let int2):
                executor.execute(valves: [Swap(int, int2)])
            case .xModPow(let value, let mod, let input, let output):
                executor.execute(valves: [FunctionValve(x: value, m: mod, inputSize: input, outputSize: output)])
            }
        } else {
            let valves = step.valves.compactMap { v in
                switch v {
                case .single(.H, let ind):
                    return H(at: ind) as SingleValve
                case .single(.Z, let ind):
                    return Z(at: ind)
                case .single(.I, let ind):
                    return I(at: ind)
                case .single(.X, let ind):
                    return X(at: ind)
                case .single(.RZ(let angle), let ind):
                    return RZ(at: ind, angle: Float(angle))
                case .single, .controlled, .swap, .measure, .xModPow:
                    return nil
                }
            }

            executor.execute(valves: valves)

            let indexes = step.valves.compactMap { v in
                switch v {
                case .measure(let ind):
                    return ind
                case .single, .controlled, .swap, .xModPow:
                    return nil
                }
            }

            executor.measute(indexes: indexes)
        }
    }
}

final class AlghoritmExecutor: ObservableObject {
    @Published var register: QuantumRegister?
    private(set) var measureIndexes: [Int: Int] = [:]

    func configureRegister(inputs: [Double]) {
        self.register = QuantumRegister(register: inputs, dimensity: 2)
        self.measureIndexes = [:]
    }

    func execute(valves: [Valve]) {
        guard let register else { return }
        valves.forEach {
            register.apply(valve: $0)
        }
    }

    func measute(indexes: [Int]) {
        guard let register else { return }
        indexes.forEach { index in
            measureIndexes[index] = register.measure(at: index)
        }
    }

    func resetAlghoritm() {
        register = nil
    }
}
