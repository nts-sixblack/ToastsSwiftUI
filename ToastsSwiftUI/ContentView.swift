//
//  ContentView.swift
//  ToastsSwiftUI
//
//  Created by Thanh Sau on 17/12/2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Button("Add toast") {
                Toast.shared.present(title: "abc", symbol: "chevron.left")
            }
        }
        .padding()
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
