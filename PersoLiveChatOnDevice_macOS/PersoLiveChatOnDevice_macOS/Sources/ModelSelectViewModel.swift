//
//  Copyright © 2025 ESTsoft. All rights reserved.
//

import Combine
import Foundation

import PersoLiveChatOnDeviceSDK

@MainActor
final class ModelSelectViewModel: ObservableObject {

    @MainActor @Published var models: [ModelStyle] = []
    @Published var itemsProgress: [UUID: Progress] = [:]

    let moveToMainTabScreen: PassthroughSubject<ModelStyle, Never> = .init()

    // MARK: - initialize

    init() { }

    // MARK: - private method

    func fetchModelStyles() async {
        do {
            let modelStyles = try await PersoLiveChat.fetchAvailableModelStyles()

            guard !modelStyles.isEmpty else {
                debugPrint("model styles not found.")
                return
            }

            self.models = modelStyles
        } catch {
            debugPrint("fetch model styles error.")
        }
    }

    func setItem(_ item: ModelSelectView.Item) {
        if item.modelStyle.status == .available {
            moveToMainTabScreen.send(item.modelStyle)
        } else {
            Task {
                await loadModelResources(modelStyle: item.modelStyle, for: item.id)
            }
        }
    }

    private func loadModelResources(modelStyle: ModelStyle, for itemId: UUID) async {
        do {
            let stream = PersoLiveChat.loadModelStyle(with: modelStyle)

            for try await progress in stream {

                await MainActor.run {
                    self.itemsProgress[itemId] = progress
                }
            }

            updateModelStyleStatus(from: modelStyle)
        } catch {
            debugPrint("\(modelStyle) download failed")

            await MainActor.run {
                self.itemsProgress[itemId] = nil
            }
        }
    }

    /// Updates the `models` array with the completed status of a downloaded template.
    private func updateModelStyleStatus(from modelStyle: ModelStyle) {
        if let index = models.firstIndex(where: { $0.name == modelStyle.name }) {
            var updatedStore = models[index]
            updatedStore.status = .available
            models[index] = updatedStore
        }
    }
}
