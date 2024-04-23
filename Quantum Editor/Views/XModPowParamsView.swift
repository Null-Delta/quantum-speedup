//
//  XModPowParamsView.swift
//  Quantum Editor
//
//  Created by Rustam Khakhuk on 22.04.2024.
//

import SwiftUI

struct XModPowParamsView: View {

    @State var mod: String = "0"
    @State var value: String = "0"
    @State var inputRegister: String = "0"
    @State var outputRegister: String = "0"

    var onConfigure: (Int, Int, Int, Int) -> Void
    var body: some View {
        VStack {
            Text("Valve params")
                .padding(8)

            Divider()

            VStack {
                HStack {
                    Text("Value:")
                    Spacer()
                    TextField("0", text: $value)
                        .multilineTextAlignment(.center)
                        .frame(width: 48)
                }
                HStack {
                    Text("Mod by:")
                    Spacer()
                    TextField("0", text: $mod)
                        .multilineTextAlignment(.center)
                        .frame(width: 48)
                }
                HStack {
                    Text("Input register:")
                    Spacer()
                    TextField("0", text: $inputRegister)
                        .multilineTextAlignment(.center)
                        .frame(width: 48)
                }
                HStack {
                    Text("OutputRegister:")
                    Spacer()
                    TextField("0", text: $outputRegister)
                        .multilineTextAlignment(.center)
                        .frame(width: 48)
                }
            }
            .padding(8)

            Divider()

            Button(action: {
                guard
                    let value = Int(value),
                    let mod = Int(mod),
                    let input = Int(inputRegister),
                    let output = Int(outputRegister)
                else { return }
                onConfigure(value, mod, input, output)
            }, label: {
                Text("Готово")
            })
            .padding(.bottom, 8)
        }
    }
}

#Preview {
    XModPowParamsView(onConfigure: { _, _, _, _ in })
}
