//
//  ContentView.swift
//  Quantum Editor
//
//  Created by Rustam Khakhuk on 17.04.2024.
//

import SwiftUI

struct ContentView: View {
    @State var currentAlghoritm: AlghoritmModel? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Menu("Алгоритм") {
                    Button("Создать") {
                        currentAlghoritm = AlghoritmModel(
                            name: "Aboba",
                            quditsCount: 8,
                            steps: []
                        )
                    }
                    Button("Открыть") {
                        let decoder = JSONDecoder()
                        let alg = try? decoder.decode(AlghoritmModel.self, from: Data(contentsOf: .documentsDirectory.appending(path: "alghoritm.qalg")))

                        currentAlghoritm = alg
                    }

                    if currentAlghoritm != nil {
                        Button("Закрыть") {
                            currentAlghoritm = nil
                        }

                        Button("Сохранить") { 
                            if let currentAlghoritm {
                                let encoder = JSONEncoder()
                                let data = try? encoder.encode(currentAlghoritm)

                                try? data?.write(to: .documentsDirectory.appending(path: "alghoritm.qalg"), options: .atomic)
                            }
                        }
                    }
                }
                .menuStyle(.borderedButton)
                .menuIndicator(.hidden)
                .frame(width: 80)

                if let currentAlghoritm {
                    Text("\(currentAlghoritm.name).qalg")
                        .foregroundStyle(Color.gray)
                }
                Spacer()


                if let currentAlghoritm {
                    Button(
                        action: {
                            self.currentAlghoritm?.quditsCount += 1
                        },
                        label: {
                            Image(systemName: "plus")
                        }
                    )

                    Button(
                        action: {
                            self.currentAlghoritm?.quditsCount -= 1
                        }, label: {
                            Image(systemName: "minus")
                        }
                    )
                    .disabled(currentAlghoritm.quditsCount == 1)
                }
            }
            .padding([.leading, .trailing], 8)
            .frame(maxHeight: 42)

            Divider()
            
            if let currentAlghoritm {
                EditorView(alghoritm: .init(
                    get: { currentAlghoritm },
                    set: { newValue in self.currentAlghoritm = newValue }
                ))
                .frame(maxHeight: .greatestFiniteMagnitude)
            } else {
                HStack {
                    Text("Не выбран алгоритм")
                        .foregroundStyle(Color.gray)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .greatestFiniteMagnitude)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
    }
}

#Preview {
    ContentView()
}
