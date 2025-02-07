//
//  Copyright © 2025 ESTsoft. All rights reserved.

import SwiftUI

import PersoLiveChatOnDeviceSDK

@main
struct PersoLiveChatOnDeviceSampleApp: App {
    init() {
        PersoLiveChat.apiKey = <#T##String#>
        PersoLiveChat.computeUnits = <#PersoMLComputeUnits#>
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 500, minHeight: 500)
        }
        .defaultPosition(.center)
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.hiddenTitleBar)
    }
}


