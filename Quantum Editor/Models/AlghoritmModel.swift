//
//  AlghoritmModel.swift
//  Quantum Editor
//
//  Created by Rustam Khakhuk on 17.04.2024.
//

import Foundation

struct AlghoritmModel: Codable, Hashable {
    var name: String

    var quditsCount: Int {
        didSet {
            clearOutbounds()
        }
    }
    
    var steps: [AlghoritmStep]

    mutating func insertStep(at: Int) {
        steps.insert(AlghoritmStep(valves: []), at: at)
        clearOutbounds()
    }

    mutating func deleteStep(at: Int) {
        steps.remove(at: at)
        clearOutbounds()
    }

    func canPlaceValve(on index: NSIndexPath) -> Bool {
        guard index.section < steps.count else { return true }

        return !steps[index.section].valves.contains {
            switch $0 {
            case .single(_, let ind), .measure(let ind):
                index.item == ind
            case .controlled, .swap, .xModPow:
                true
            }
        }
    }

    func valve(on index: NSIndexPath) -> ValveType? {
        guard index.section < steps.count else { return nil }

        return steps[index.section].valves.first {
            switch $0 {
            case .single(_, let ind), .measure(let ind):
                index.item == ind
            case .controlled(_, let i1, let i2), .swap(let i1, let i2):
                (min(i1, i2)...max(i1, i2)).contains(index.item)
            case .xModPow(_, _, let input, let output):
                (0...input + output).contains(index.item)
            }
        }
    }

    mutating func deleteValve(on index: NSIndexPath) {
        steps[index.section].valves = steps[index.section].valves.filter {
            switch $0 {
            case .single(_, let ind), .measure(let ind):
                index.item != ind
            case .controlled(_, let i1, let i2), .swap(let i1, let i2):
                !(min(i1, i2)...max(i1, i2)).contains(index.item)
            case .xModPow(_, _, let input, let output):
                !(0...input + output).contains(index.item)
            }
        }
        clearOutbounds()
    }

    mutating private func clearOutbounds() {
        for stepIndex in 0..<steps.count {
            steps[stepIndex].valves = steps[stepIndex].valves.filter {
                switch $0 {
                case .single(_, let index), .measure(let index):
                    index < quditsCount
                case .controlled(_, let i1, let i2), .swap(let i1, let i2):
                    max(i1, i2) < quditsCount
                case .xModPow(_, _, let input, let output):
                    input + output <= quditsCount
                }
            }
        }

        while (steps.last?.valves.isEmpty ?? false) { steps.removeLast() }
    }
}

struct AlghoritmStep: Codable, Hashable {
    var id = UUID()
    var valves: [ValveType]
}

enum ValveParam {
    case float(String, Float)
    case singleValve(String, SingleValveType)
    case int(String, Int)

    var name: String {
        return switch self {
        case .float(let string, _):
            string
        case .singleValve(let string, _):
            string
        case .int(let string, _):
            string
        }
    }

    var value: Any {
        switch self {
        case .float(_, let float):
            return float
        case .singleValve(_, let singleValveType):
            return singleValveType
        case .int(_, let int):
            return int
        }
    }
}

enum SingleValveType: Codable, Hashable {
    case H
    case I
    case Z
    case X
    case RZ(angle: Int)

    var name: String {
        switch self {
        case .H:
            return "H"
        case .I:
            return "I"
        case .Z:
            return "Z"
        case .X:
            return "X"
        case .RZ(let angle):
            return "RZ\n\(angle)"
        }
    }

    var params: [ValveParam] {
        switch self {
        case .H, .I, .Z, .X:
            return []
        case .RZ:
            return [
                .float("Angle", 0)
            ]
        }
    }

    func configure(with params: [ValveParam]) -> SingleValveType? {
        switch self {
        case .H, .I, .Z, .X:
            return self
        case .RZ:
            guard
                let angleParam = params.first(where: { $0.name == "Angle" }),
                let angle = (angleParam.value as? Float).map({ Int($0) })
            else { return nil }
            return .RZ(angle: angle)
        }
    }
}

enum ValveType: Codable, Hashable {
    case measure(Int)
    case single(SingleValveType, Int)
    case controlled(SingleValveType, Int, Int)
    case swap(Int, Int)
    case xModPow(Int, Int, Int, Int)

    var params: [ValveParam] {
        switch self {
        case .measure:
            []
        case .xModPow:
            [.float("a", 0)]
        case .single(let singleValveType, _):
            singleValveType.params
        case .controlled(let singleValveType, _, _):
            [[.singleValve("Valve", .I), .int("Index", 0)], singleValveType.params].flatMap { $0 }
        case .swap:
            [.int("Index", 0)]
        }
    }

    var name: String {
        switch self {
        case .measure:
            "M"
        case .xModPow(let value, let mod, _, _):
            "\(value)^X mod \(mod)"
        case .single(let singleValveType, _):
            singleValveType.name
        case .controlled(let singleValveType, _, _):
            "C\(singleValveType.name)"
        case .swap:
            "SWAP"
        }
    }

    var isSingle: Bool {
        switch self {
        case .single, .measure:
            true
        case .controlled, .swap, .xModPow:
            false
        }
    }

    func configure(on index: Int, with params: [ValveParam]) -> ValveType? {
        switch self {
        case .measure:
            return .measure(index)
        case .xModPow:
            return self
        case .single(let singleValveType, _):
            guard let configuredValve = singleValveType.configure(with: params) else { return nil }
            return .single(configuredValve, index)

        case .controlled(_, _, _):
            guard
                let valveParam = params.first(where: { $0.name == "Valve" }),
                let valve = valveParam.value as? SingleValveType,
                let configuredValve = valve.configure(with: params),
                let indexesParam = params.first(where: { $0.name == "Index" }),
                let index2 = indexesParam.value as? Int
            else { return nil }

            return .controlled(
                configuredValve,
                index,
                index2
            )

        case .swap(_, _):
            guard
                let indexesParam = params.first(where: { $0.name == "Index" }),
                let index2 = indexesParam.value as? Int
            else { return nil }

            return .swap(index, index2)
        }
    }
}
