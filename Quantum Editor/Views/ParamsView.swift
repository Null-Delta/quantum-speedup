//
//  ParamsView.swift
//  Quantum Editor
//
//  Created by Rustam Khakhuk on 21.04.2024.
//

import SwiftUI

struct ParamsView: View {
    @State var params: [ValveParam]
    var onConfigure: ([ValveParam]) -> Void

    @State var selectedIndex: String = ""
    @State var selectedValue: String = ""
    @State var selectedValve: SingleValveType = .I

    @State var selectedValveModel: CellModel? = CellModel(state: .rect("I"))
    @State var isValveSelectionPopoverShown: Bool = false

    private let placableValves: [SingleValveType] = [
        .I, .X, .H, .Z, .RZ(angle: 0)
    ]

    @State var additionalParams: [ValveParam] = []


    var body: some View {
        VStack {
            Text("Valve params")
                .padding(8)

            Divider()

            VStack {
                ForEach(params, id: \.name) { param in
                    HStack {
                        Text(param.name)
                        Spacer()

                        switch param {
                        case .float(_, _):
                            TextField("", text: $selectedValue)
                                .frame(width: 48)
                        case .int(_, _):
                            TextField("", text: $selectedIndex)
                                .frame(width: 48)
                        case .singleValve(_, _):
                            Button(action: {
                                isValveSelectionPopoverShown = true
                            }, label: {
                                EditorCellView(cellSize: 42, cellHeight: 42, cellModel: $selectedValveModel)
                            })
                            .buttonStyle(.plain)
                            .popover(
                                isPresented: $isValveSelectionPopoverShown,
                                content: {
                                    ScrollView(.horizontal, content: {
                                        HStack {
                                            ForEach(placableValves, id: \.self) { valve in
                                                Button(action: {
                                                    isValveSelectionPopoverShown = false
                                                    selectedValve = valve
                                                    selectedValveModel = CellModel(state: .rect(valve.name))
                                                    additionalParams = valve.params
                                                }, label: {
                                                    EditorCellView(
                                                        cellSize: 42,
                                                        cellHeight: 42,
                                                        cellModel: .constant(CellModel(state: .rect(valve.name)))
                                                    )
                                                })
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    })
                                }
                            )
                        }
                    }
                }
                .padding(.bottom, 8)

                ForEach(additionalParams, id: \.name) { param in
                    HStack {
                        Text(param.name)
                        Spacer()
                        TextField("", text: $selectedValue)
                            .frame(width: 48)
                    }
                }
            }
            .padding(8)

            Divider()

            Button(action: {
                var resultParams: [ValveParam] = []
                params.forEach {
                    switch $0 {
                    case .float(let name, _):
                        resultParams.append(.float(name, Float(selectedValue) ?? 0))
                    case .int(let name, _):
                        resultParams.append(.int(name, Int(selectedIndex) ?? 0))
                    case .singleValve(let name, _):
                        resultParams.append(.singleValve(name, selectedValve))
                    }
                }

                additionalParams.forEach {
                    switch $0 {
                    case .float(let name, _):
                        resultParams.append(.float(name, Float(selectedValue) ?? 0))
                    case .int(let name, _):
                        resultParams.append(.int(name, Int(selectedIndex) ?? 0))
                    case .singleValve(let name, _):
                        resultParams.append(.singleValve(name, selectedValve))
                    }
                }

                onConfigure(resultParams)
            }, label: {
                Text("Готово")
            })
            .padding(.bottom, 8)
        }
        .frame(width: 256)
    }
}

#Preview {
    ParamsView(
        params: [
            .singleValve("Valve", .I),
            .int("Index", -1),
        ], onConfigure: { _ in }
    )
}
