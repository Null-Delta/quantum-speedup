//
//  StatePreview.swift
//  Quantum Editor
//
//  Created by Rustam Khakhuk on 22.04.2024.
//

import SwiftUI
import Charts

struct StatePreview: View {
    @ObservedObject var editorState: EditorModel
    @State var cellSize: CGFloat = 5

    var body: some View {
        VStack(spacing: 0) {
            if let register = editorState.executor.register {
                Chart {
                    ForEach(Array(register.state.values.enumerated()), id: \.offset) { item in
                        LineMark(x: PlottableValue.value("", item.offset), y: .value("", Float(powf(Float(item.element.module), 2))))
                            .foregroundStyle(
                                Color(
                                    nsColor: NSColor(
                                        red: CGFloat(item.element.re * item.element.module),
                                        green: CGFloat(item.element.im * item.element.module),
                                        blue: 0,
                                        alpha: 1
                                    )
                                )
                            )
                    }
                }
                .chartXAxis {
                    AxisMarks(values: stride(from: 0, to: register.state.values.count, by: max(1, register.state.values.count / 4)).map { $0 })
                }
            }
        }
        .padding(16)
    }
}

#Preview {
    ContentView()
        .frame(height: 716)
}
