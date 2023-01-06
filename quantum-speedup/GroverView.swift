//
//  GroverView.swift
//  quantum-speedup
//
//  Created by Delta Null on 21.11.2022.
//

import SwiftUI
import Charts

struct GroverView: View {
    @StateObject var register: QuantumRegister = QuantumRegister(register: [0])
    @State var indexesInput: String = ""
    @State var sizeInput: String = "8"
    @State var output: String = ""
    @State var isStepByStep: Bool = false
    
    @State var stepIndex = 0
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    @State var function: GroverValve?
    @State var preValve: CustomValve?

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Indexes =")
                        TextField("", text: $indexesInput)
                    }
                    HStack {
                        Text("Register size =")
                        TextField("", text: $sizeInput)
                            .frame(width: 64)
                        
                        Spacer()
                            .frame(width: 16)
                        
                        Text("Result:")
                        TextField("", text: $output)
                            .frame(width: 64)
                            .disabled(true)
                        
                        Spacer()

                        Button("By steps", action: {
                            output = ""
                            isStepByStep = true
                            stepIndex = 0
                            constructFunctions()
                        })
                        
                        Button("Find", action: {
                            output = ""
                            isStepByStep = false
                            stepIndex = 0
                            constructFunctions()
                            grover()
                        })
                    }
                }
            }
            
            GeometryReader { gr in
                Chart {
                    ForEach(Array(register.state.values.enumerated()), id: \.offset) { value in
                        BarMark(x: .value("", value.offset), y: .value("", powf(value.element.module, 2)), width: .fixed(ceil(gr.size.width / CGFloat(register.state.values.count))))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: stride(from: 0, to: register.state.values.count, by: max(1, register.state.values.count / 4)).map { $0 })
                }
            }
            
            Spacer()
        }
        .onReceive(timer, perform: { _ in
            if isStepByStep {
                if groverStep(index: stepIndex) {
                    isStepByStep = false
                    measure()
                } else {
                    stepIndex += 1
                }
            }
        })
    }
    
    func groverStep(index: Int) -> Bool {
        let indexes = indexesInput
            .replacing(" ", with: "")
            .split(separator: ",")
            .map { Int($0)! }
        
        switch index {
        case 0:
            for i in 0..<register.size {
                register.apply(valve: H(at: i))
            }
            return false
            
        case let i where i < Int((Float.pi / 4.0) * sqrtf(Float(register.state.size) / Float(indexes.count))) + 1:
            register.apply(valve: function!)
            register.apply(valve: preValve!)
            return false
            
        default:
            return true
        }
    }
    
    func groverAlghoritm() {
        constructFunctions()
        
        let indexes = indexesInput
            .replacing(" ", with: "")
            .split(separator: ",")
            .map { Int($0)! }
        
        for i in 0..<register.size {
            register.apply(valve: H(at: i))
        }
        
        for _ in 0..<Int((Float.pi / 4.0) * sqrtf(Float(register.state.size) / Float(indexes.count))) {
            register.apply(valve: function!)
            register.apply(valve: preValve!)
        }
        
        measure()
    }
    
    func constructFunctions() {
        guard let size = Int(sizeInput) else { return }

        register.updateRegister(register: .init(repeating: 0, count: size))
        
        let indexes = indexesInput
            .replacing(" ", with: "")
            .split(separator: ",")
            .map { Int($0)! }
        
        function = GroverValve(indexes: indexes, size: size)
        preValve = CustomValve(
            matrix: Matrix(
                values: .init(
                    repeating: 0,
                    count: register.state.values.count * register.state.values.count
                )
            )
        )
        
        for x in 0..<Int(powf(2, Float(register.size))) {
            for y in 0..<Int(powf(2, Float(register.size))) {
                preValve!.matrix[x, y] = Complex(re: 2 / Float(register.state.size), im: 0)
                if x == y {
                    preValve!.matrix[x, y] = preValve!.matrix[x, y] - Complex(re: 1, im: 0)
                }
            }
        }
    }
    
    func measure() {
        var result: [Int] = []
        
        for i in 0..<register.size {
            result.append(register.measure(at: i))
        }

        output = "\(result.toInt())"
    }
    
    func grover() {
        while !groverStep(index: stepIndex) {
            stepIndex += 1
        }
        
        measure()
    }
}

struct GroverView_Previews: PreviewProvider {
    static var previews: some View {
        GroverView()
    }
}
