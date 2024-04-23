//
//  ShorView.swift
//  quantum-speedup
//
//  Created by Delta Null on 21.11.2022.
//

import SwiftUI
import Charts

struct ShorView: View {
    @StateObject var register: QuantumRegister = QuantumRegister(register: [0], dimensity: 2)
    @State var input: String = ""
    @State var output: String = ""
    
    var body: some View {
        VStack {
            HStack {
                Text("N =")
                TextField("", text: $input)
                    .frame(width: 64)
                Spacer()
                    .frame(width: 16)
                Text("Result:")
                TextField("", text: $output)
                    .frame(width: 128)
                    .disabled(true)
                
                Spacer()
                Button("Factorize", action: {
                    shorFactorization()
                })
            }
            
            Chart {
                ForEach(Array(register.state.values.enumerated()), id: \.offset) { value in
                    BarMark(x: .value("", value.offset), y: .value("", powf(value.element.module, 2)), width: .fixed(1))
                }
            }
            .chartXAxis {
                AxisMarks(values: stride(from: 0, to: register.state.values.count, by: max(1, register.state.values.count / 4)).map { $0 })
            }
            
            Spacer()
        }
    }
        
    func gcd (a: Int, b: Int) -> Int {
        return b != 0 ? gcd(a: b, b: a % b) : a;
    }
        
    func randomX(for N: Int) -> Int {
        var X: Int
        
        repeat {
            X = Int.random(in: 2..<N)
        } while gcd(a: N, b: X) != 1
        
        return X
    }
    
    func inputSize(for N: Int) -> Int {
        
        let log = log2(powf(Float(N),2)) / log2(Float(register.dimensity))

        return Int(ceil(log))
    }
    
    func outputSize(for N: Int) -> Int {
        let log = log2(Float(N)) / log2(Float(register.dimensity))
        return Int(ceil(log))
    }
        
    func powMod(x: Int, r: Int, m: Int) -> Int {
        var result = 1
        if r == 0 { return 1 }
        for _ in 0..<r {
            result *= x
            result %= m
        }

        return result
    }
    
    func fracApprox(a: Int, b: Int) -> (Int, Int) {
        let f = Double(a) / Double(b)
        var g = f
        var i = 0.0, num2 = 0.0, den2 = 1.0, num1 = 1.0, den1 = 0.0, num = 0.0, den = 0.0

        repeat {
            i = round(g + 0.000005)
            g -= i - 0.000005;
            g = 1.0 / g;

            if i * den1 + den2 > Double(b) {
                break
            }

            num = i * num1 + num2
            den = i * den1 + den2
            num2 = num1
            den2 = den1
            num1 = num
            den1 = den
        } while abs((Double(num) / Double(den)) - f) > 1.0 / (2 * Double(b))

        return (Int(abs(num)), Int(abs(den)))
    }

    func shorFactorization() {
        guard let N = Int(input) else { return }
        let X = 7//randomX(for: N)
        let inputSize = inputSize(for: N)
        let outputSize = outputSize(for: N)
        let function = FunctionValve(x: X, m: N, inputSize: inputSize, outputSize: outputSize)

        register.updateRegister(register: .init(repeating: 0, count: inputSize + outputSize))
        
        for i in 0..<inputSize {
            register.apply(valve: H(at: i))
        }
        
        register.apply(valve: function)
        register.apply(valve: RQFT(qbitCount: inputSize))
        
        var result: [Int] = .init(repeating: 0, count: inputSize)

        for i in 0..<inputSize {
            result[i] = register.measure(at: i)
        }

        let approx = fracApprox(a: result.toInt(dimension: register.dimensity), b: 1 << inputSize)
        
        var q = approx.1
        if q % 2 == 1 {
            q *= 2
        }

        var a = (powMod(x: X, r: q / 2, m: N) + 1) % N
        var b = (powMod(x: X, r: q / 2, m: N) - 1) % N

        a = gcd(a: a, b: N)
        b = gcd(a: b, b: N)

        let factor = max(a, b)
        output = "\(factor), \(N / factor)"
    }
}

struct ShorView_Previews: PreviewProvider {
    static var previews: some View {
        ShorView()
            .padding(.all, 16)
    }
}
