//
//  EditorView.swift
//  Quantum Editor
//
//  Created by Rustam Khakhuk on 17.04.2024.
//

import SwiftUI

struct VLine: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
    }
}
struct HLine: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

struct CellModel: Hashable {
    enum State: Hashable {
        case empty
        case circle
        case rect(String)
    }

    let id = UUID()
    let state: State
}

struct EditorCellView: View {
    @State var cellSize: CGFloat
    @State var cellHeight: CGFloat
    @Binding var cellModel: CellModel?

    var body: some View {
        Rectangle()
            .frame(width: cellSize, height: cellHeight)
            .foregroundColor(Color.clear)
            .overlay {
                switch cellModel?.state {
                case .empty, .none:
                    Text("")

                case .circle:
                    Circle()
                        .frame(width: 16, height: 16)
                        .foregroundColor(Color(nsColor: .textColor))

                case .rect(let text):
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: cellSize - 12, height: cellHeight - 12)
                        .foregroundColor(Color(nsColor: .textColor))
                        .overlay(
                            Text(text)
                                .fontDesign(.monospaced)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.01)
                                .foregroundColor(Color(nsColor: .textBackgroundColor))
                                .frame(width: cellSize - 16, height: cellHeight)
                                .font(.caption)
                        )
                        .padding(6)
                }
            }
    }
}

struct EditorView: View {
    @Binding var alghoritm: AlghoritmModel

    @State var cellSize: CGFloat = 40
    @State var cellHeight: CGFloat = 40

    @State var qubitsIndexes: Range<Int>
    @State var inputs: [String]
    @State var outputs: [String]
    @State var cellStates: [NSIndexPath: CellModel]
    @State var cellIndexes: [NSIndexPath]

    @State var selectedValveIndex: Int? = nil
    @State var placableValves: [ValveType] = [
        .measure(0),
        .single(.I, 0),
        .single(.H, 0),
        .single(.Z, 0),
        .single(.X, 0),
        .single(.RZ(angle: 0), 0),
        .swap(0, 0),
        .controlled(.I, 0, 0),
        .xModPow(0, 0, 0, 0)
    ]

    @StateObject var editorState: EditorModel = EditorModel()

    @State var isValvesListPopoverPresented: Bool = false
    @State var isValveParamsPresented: Bool = false

    init(alghoritm: Binding<AlghoritmModel>) {
        self._alghoritm = alghoritm
        self.qubitsIndexes = 0..<alghoritm.wrappedValue.quditsCount
        self.inputs = Array(repeating: "", count: alghoritm.wrappedValue.quditsCount)
        self.outputs = Array(repeating: "", count: alghoritm.wrappedValue.quditsCount)
        self.cellStates = [:]
        self.cellIndexes = []
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                    VStack(spacing: 0) {
                        ForEach(qubitsIndexes, id: \.self) { index in
                            Divider()
                                .offset(y: cellHeight / 2)
                            Spacer()
                                .frame(height: cellHeight - 1)
                        }
                    }
                    .padding([.leading, .trailing], cellSize)

                    HStack(spacing: 0) {
                        LazyVStack(spacing: 0) {
                            ForEach(qubitsIndexes, id: \.self) { index in
                                TextField("0", text: $inputs[index])
                                    .fontDesign(.monospaced)
                                    .textFieldStyle(.plain)
                                    .multilineTextAlignment(.center)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 6)
                                                .frame(width: 20, height: 24)
                                                .foregroundColor(Color(nsColor: .controlBackgroundColor))

                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(style: StrokeStyle(lineWidth: 1))
                                                .frame(width: 20, height: 24)
                                                .foregroundColor(Color(.secondarySystemFill))
                                        }
                                    )
                                    .frame(width: 24, height: cellHeight)
                            }
                        }
                        .frame(width: cellSize)

                        ScrollView(.horizontal) {
                            ZStack(alignment: .topLeading) {
                                if let currentStep = editorState.currentAlghoritmStep {
                                    RoundedRectangle(cornerRadius: 4)
                                        .foregroundColor(.accentColor.opacity(0.25))
                                        .frame(width: cellSize)
                                        .offset(x: cellSize * CGFloat(currentStep))

                                }

                                if let selectedCell = editorState.selectedCell {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 2]))
                                            .foregroundColor(.green)
                                            .frame(width: cellSize - 6, height: cellHeight - 6)

                                        RoundedRectangle(cornerRadius: 6)
                                            .foregroundColor(.green.opacity(0.5))
                                            .frame(width: cellSize - 6, height: cellHeight - 6)

                                    }
                                    .offset(
                                        x: CGFloat(selectedCell.section) * cellSize + 3,
                                        y: CGFloat(selectedCell.item) * cellHeight + 3
                                    )
                                }

                                LazyHGrid(
                                    rows: Array(repeating: .init(.fixed(cellHeight), spacing: 0), count: alghoritm.quditsCount),
                                    spacing: 0,
                                    content: {
                                        ForEach(
                                            cellIndexes,
                                            id: \.self
                                        ) { state in
                                            EditorCellView(
                                                cellSize: cellSize,
                                                cellHeight: cellHeight,
                                                cellModel: $cellStates[state]
                                            )
                                        }
                                    }
                                )

                                VStack(spacing: 0) {
                                    ForEach(qubitsIndexes, id: \.self) { index in
                                        Divider()
                                            .offset(y: cellHeight / 2)
                                        Spacer()
                                            .frame(height: cellHeight - 1)
                                    }
                                }

                                HStack(spacing: 0) {
                                    ForEach(alghoritm.steps, id: \.id) { step in
                                        VLine()
                                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                            .frame(width: 1)
                                            .foregroundColor(Color(.secondarySystemFill))
                                        Spacer()
                                            .frame(height: cellHeight - 1)
                                    }

                                    VLine()
                                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                        .frame(width: 1)
                                        .foregroundColor(Color(.secondarySystemFill))
                                }
                                .frame(width: cellSize * CGFloat(alghoritm.steps.count))
                            }
                            .background(Color(nsColor: .windowBackgroundColor))
                            .onTapGesture { point in
                                let cellPosition = NSIndexPath(forItem: Int(point.y / cellHeight), inSection: Int(point.x / cellSize))

                                if editorState.selectedCell == cellPosition, alghoritm.canPlaceValve(on: cellPosition) {
                                    editorState.selectedCell = nil
                                    if alghoritm.steps.count == cellPosition.section {
                                        alghoritm.steps.append(AlghoritmStep(valves: [.single(.H, cellPosition.item)]))
                                    } else {
                                        alghoritm.steps[cellPosition.section].valves.append(.single(.H, cellPosition.item))
                                    }
                                } else {
                                    editorState.selectedCell = cellPosition
                                }
                            }
                        }

                        LazyVStack(spacing: 0) {
                            ForEach(qubitsIndexes, id: \.self) { index in
                                TextField("", text: $outputs[index])
                                    .disabled(true)
                                    .textFieldStyle(.plain)
                                    .multilineTextAlignment(.center)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 6)
                                                .frame(width: 20, height: 24)
                                                .foregroundColor(Color(nsColor: .controlBackgroundColor))

                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(style: StrokeStyle(lineWidth: 1))
                                                .frame(width: 20, height: 24)
                                                .foregroundColor(Color(.secondarySystemFill))
                                        }
                                    )
                                    .frame(width: 24, height: cellHeight)
                            }
                        }
                        .frame(width: cellSize)
                    }
                }
                .overlay(
                    HStack {
                        Spacer()
                            .frame(width: cellSize)

                        VLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .frame(width: 1)
                            .foregroundColor(Color(.secondarySystemFill))

                        Spacer()

                        VLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .frame(width: 1)
                            .foregroundColor(Color(.secondarySystemFill))

                        Spacer()
                            .frame(width: cellSize)
                    }
                )
                .onChange(of: alghoritm.quditsCount) {
                    configureData(needUpdateCells: true)
                }
                .onChange(of: alghoritm.steps.count) {
                    configureData(needUpdateCells: true)
                }
                .onChange(of: alghoritm) {
                    configureData(needUpdateCells: false)
                }
                .onAppear {
                    configureData(needUpdateCells: true)
                }
            }

            Divider()

            HStack {
                Button(self.editorState.currentAlghoritmStep == nil ? "Запуск" : "Шаг") {

                    if self.editorState.currentAlghoritmStep == nil {
                        outputs = Array(repeating: "", count: alghoritm.quditsCount)
                        self.editorState.startAlghoritm(
                            inputs: self.inputs.map { Double(Int($0) ?? 0) },
                            alghoritm: self.alghoritm
                        )
                    } else {
                        if let output = self.editorState.makeAlghoritmStep() {
                            self.outputs = output
                        }
                    }
                }

                Spacer()

                Button(
                    action: {
                        editorState.selectedCell.map { alghoritm.insertStep(at: $0.section) }
                        editorState.selectedCell = nil
                    },
                    label: { Text("+ шаг") }
                )
                .disabled(editorState.selectedCell == nil)

                Button(
                    action: {
                        editorState.selectedCell.map { alghoritm.deleteStep(at: $0.section) }
                        editorState.selectedCell = nil
                    },
                    label: { Text("- шаг") }
                )
                .disabled(editorState.selectedCell.map { alghoritm.steps.count == $0.section } ?? true)

                Divider()

                Button(
                    action: {
                        isValvesListPopoverPresented = true
                    },
                    label: {
                        Image(systemName: "plus")
                    }
                )
                .disabled(
                    editorState.selectedCell.map { !alghoritm.canPlaceValve(on: $0) } ?? true
                )
                .popover(
                    isPresented: $isValvesListPopoverPresented,
                    content: {
                        ScrollView(.horizontal) {
                            HStack(spacing: 0) {
                                ForEach(placableValves, id: \.self) { valve in
                                    Button(action: {
                                        selectedValveIndex = placableValves.firstIndex(where: { $0 == valve })
                                        isValvesListPopoverPresented = false

                                        if valve.params.isEmpty {
                                            setValve(valve: valve, with: [])
                                        } else {
                                            isValveParamsPresented = true
                                        }
                                    }, label: {
                                        RoundedRectangle(cornerRadius: 8)
                                            .frame(width: 48, height: 48)
                                            .foregroundColor(Color(nsColor: .textColor))
                                            .overlay(
                                                Text(valve.name)
                                                    .fontDesign(.monospaced)
                                                    .fontWeight(.bold)
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(2)
                                                    .foregroundColor(Color(nsColor: .textBackgroundColor))
                                                    .frame(width: cellSize - 16, height: cellHeight)
                                                    .font(.caption)
                                                    .minimumScaleFactor(0.01)
                                            )
                                            .padding(6)
                                    })
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .scrollPosition(id: .constant(10), anchor: .topLeading)
                    }
                )

                Button(
                    action: {
                        editorState.selectedCell.map { alghoritm.deleteValve(on: $0) }
                    },
                    label: {
                        Image(systemName: "minus")
                    }
                )
                .keyboardShortcut(.delete, modifiers: [])
                .disabled(
                    editorState.selectedCell.map { alghoritm.valve(on: $0) == nil } ?? true
                )
            }
            .padding([.leading, .trailing], 8)
            .frame(maxHeight: 42)
            .sheet(isPresented: $isValveParamsPresented, content: {
                if let selectedValve = selectedValveIndex.map ({ placableValves[$0] })  {
                    let params: [ValveParam] = selectedValve.params

                    switch selectedValve {
                    case .xModPow:
                        XModPowParamsView(onConfigure: { value, mod, input, output in
                            isValveParamsPresented = false
                            setValve(
                                valve: .xModPow(value, mod, input, output),
                                with: []
                            )
                        })

                    default:
                        ParamsView(params: params, onConfigure: { ps in
                            isValveParamsPresented = false

                            guard let selectedValveIndex else { return }
                            setValve(valve: placableValves[selectedValveIndex], with: ps)
                        })
                    }
                } else {
                    Text("Error")
                }

            })

            Divider()

            StatePreview(editorState: editorState)
                .frame(height: 256)
        }
    }

    private func setValve(valve: ValveType, with params: [ValveParam]) {
        guard
            let cellPosition = editorState.selectedCell,
            let configuredValve = valve.configure(on: cellPosition.item, with: params)
        else { return }

        editorState.selectedCell = nil
        if alghoritm.steps.count == cellPosition.section {
            alghoritm.steps.append(AlghoritmStep(valves: [configuredValve]))
        } else {
            alghoritm.steps[cellPosition.section].valves.append(configuredValve)
        }

    }

    private func configureData(needUpdateCells: Bool) {
        qubitsIndexes = 0..<alghoritm.quditsCount
        outputs = Array(repeating: "", count: alghoritm.quditsCount)

        cellStates = [:]
        for stepIndex in 0..<alghoritm.steps.count {
            for valve in alghoritm.steps[stepIndex].valves {
                switch valve {
                case .measure(let index):
                    cellStates[
                        NSIndexPath(forItem: index, inSection: stepIndex)
                    ] = CellModel(state: .rect("M"))
                case .single(let valve, let index):
                    cellStates[
                        NSIndexPath(forItem: index, inSection: stepIndex)
                    ] = CellModel(state: .rect(valve.name))

                case .controlled(let valve, let mainIndex, let controllIndex):
                    cellStates[
                        NSIndexPath(forItem: mainIndex, inSection: stepIndex)
                    ] = CellModel(state: .rect(valve.name))
                    cellStates[
                        NSIndexPath(forItem: controllIndex, inSection: stepIndex)
                    ] = CellModel(state: .circle)

                case .swap(let firstIndex, let secondIndex):
                    cellStates[
                        NSIndexPath(forItem: firstIndex, inSection: stepIndex)
                    ] = CellModel(state: .rect("SWAP"))
                    cellStates[
                        NSIndexPath(forItem: secondIndex, inSection: stepIndex)
                    ] = CellModel(state: .rect("SWAP"))

                case .xModPow(_, _, let input, let output):
                    cellStates[
                        NSIndexPath(forItem: 0, inSection: stepIndex)
                    ] = CellModel(state: .rect("XModM"))

                    for i in 1..<input + output {
                        cellStates[
                            NSIndexPath(forItem: i, inSection: stepIndex)
                        ] = CellModel(state: .circle)
                    }
                }
            }
        }

        if needUpdateCells {
            inputs = Array(repeating: "", count: alghoritm.quditsCount)

            cellIndexes = (0..<alghoritm.steps.count + 1).flatMap { step in
                (0..<alghoritm.quditsCount).map { qubit in
                    NSIndexPath(forItem: qubit, inSection: step)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
