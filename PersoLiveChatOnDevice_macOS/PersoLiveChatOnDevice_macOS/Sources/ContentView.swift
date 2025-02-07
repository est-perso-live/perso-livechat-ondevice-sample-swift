//
//  ContentView.swift
//  PersoLiveChatOnDevice_macOS
//
//  Created by 김진형 on 5/14/25.
//

import SwiftUI

import PersoLiveChatOnDeviceSDK

enum Screen: Hashable {
    case modelSelectView
    case main(ModelStyle)
}

struct ContentView: View {
    @State private var path: [Screen] = []

    var body: some View {
        NavigationStack(path: $path) {
            ModelSelectView(path: $path)
                .navigationDestination(for: Screen.self) { screen in
                    switch screen {
                    case .modelSelectView:
                        ModelSelectView(path: $path)
                    case .main(let modelStyle):
                        MainView(path: $path, modelStyle: modelStyle)
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
