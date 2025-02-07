//
//  Copyright © 2025 ESTsoft. All rights reserved.

import SwiftUI

import PersoLiveChatOnDeviceSDK

typealias ViewRepresentable = NSViewRepresentable

struct PersoVideoViewRepresentable: ViewRepresentable {
    @EnvironmentObject var viewModel: MainViewModel

    private let session: PersoLiveChatSession

    init(session: PersoLiveChatSession) {
        self.session = session
    }

    func makeNSView(context: Context) -> PersoVideoView {
        let persoVideoView = PersoVideoView(session: session)
        persoVideoView.videoContentMode = .aspectFit
        persoVideoView.delegate = context.coordinator
        setupView(persoVideoView)
        return persoVideoView
    }

    func updateNSView(_ view: PersoVideoView, context: Context) {}

    private func setupView(_ persoVideoView: PersoVideoView) {
        try? persoVideoView.start()

        viewModel.stopSpeech = { [weak persoVideoView] in
            await persoVideoView?.stopSpeech()
        }

        viewModel.handleAssistantMessage { message in
            do {
                try persoVideoView.push(text: message)
            } catch {
                print("session terminated \(error)")
            }
        }
    }
}

// MARK: - Coordinator

extension PersoVideoViewRepresentable {

    class Coordinator: NSObject, PersoVideoViewDelegate {
        private let viewModel: MainViewModel

        init(_ viewModel: MainViewModel) {
            self.viewModel = viewModel
        }

        func persoVideoView(didFailWithError error: PersoLiveChatError) {
            debugPrint("persoVideoView error: \(error)")
        }

        func persoVideoView(didChangeState state: PersoVideoView.PersoVideoViewState) {
            debugPrint("persoVideoView didChangeState: \(state)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel)
    }
}
