//
//  ContentView.swift
//  quantum-speedup
//
//  Created by Rustam Khakhuk on 12.11.2022.
//

import SwiftUI
import Charts

extension Complex {
    var upscaled: Complex {
        let max = max(self.re, self.im)
        return Complex(re: self.re / max, im: self.im / max)
    }
}

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink(
                    destination: { ShorView().padding() },
                    label: { Text("Алгоритм Шора") }
                )
                
                NavigationLink(
                    destination: { GroverView().padding() },
                    label: { Text("Алгоритм Гровера") }
                )
            }
        } detail: {
            Text("")
        }
        .navigationTitle("Quantum Speedup")
        .frame(idealWidth: 512)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
