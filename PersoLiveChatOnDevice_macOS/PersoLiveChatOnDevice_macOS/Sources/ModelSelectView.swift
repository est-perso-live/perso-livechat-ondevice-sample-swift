//
//  Copyright © 2025 ESTsoft. All rights reserved.
//

import SwiftUI

import PersoLiveChatOnDeviceSDK

struct ModelSelectView: View {
    @Binding var path: [Screen]

    @StateObject private var viewModel: ModelSelectViewModel
    @State private var items: [ModelSelectView.Item] = []
    @State private var selectedItem: ModelSelectView.Item?

    init(path: Binding<[Screen]>) {
        self._path = path
        self._viewModel = .init(wrappedValue: .init())
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("List of Model Style")
                .font(.title)

            // Model Style Selection Menu
            if !items.isEmpty {
                Menu {
                    ForEach(items) { item in
                        Button(action: {
                            selectItem(item)
                        }) {
                            HStack {
                                Text(item.modelStyle.name)

                                Spacer()

                                switch item.modelStyle.status {
                                case .available:
                                    Image(systemName: "checkmark.circle")
                                case .notAvailable(let requirements):
                                    switch requirements {
                                    case .download:
                                        Image(systemName: "arrowshape.down.circle")
                                    case .update:
                                        Image(systemName: "arrow.triangle.2.circlepath.icloud.fill")
                                    case .unknown:
                                        Image(systemName: "questionmark.circle")
                                    @unknown default:
                                        Image(systemName: "questionmark.circle")
                                    }
                                @unknown default:
                                    fatalError()
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedItem?.modelStyle.name ?? "Choose a Model Style")
                            .foregroundStyle(selectedItem == nil ? .gray : .primary)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.title2)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(._0XF3F3F1)
                    .cornerRadius(8)
                }
            } else {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))

                    Text("Loading...")
                        .foregroundStyle(.white)
                        .font(.subheadline)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if let selectedItem {
                if let progress = viewModel.itemsProgress[selectedItem.id] {
                    VStack {
                        ProgressView(value: progress.fractionCompleted)
                            .progressViewStyle(.linear)

                        Text("\(formatBytes(progress.completedUnitCount)) / \(formatBytes(progress.totalUnitCount))")
                            .font(.caption)
                    }
                }

                Button(selectedItem.modelStyle.status == .available ? "Model Load" : "Model Download") {
                    viewModel.setItem(selectedItem)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .task {
            await viewModel.fetchModelStyles()
        }
        .onChange(of: viewModel.models) { _, modelStyles in
            updateItems(with: modelStyles)
        }
        .onReceive(viewModel.moveToMainTabScreen) { modelStyle in
            path.append(.main(modelStyle))
        }
        .navigationBarBackButtonHidden()
    }

    private func updateItems(with modelStyles: [ModelStyle]) {
        items = modelStyles.map { modelStyle in
            if let existingItem = items.first(where: { $0.modelStyle.id == modelStyle.id }) {
                var updatedItem = existingItem
                updatedItem.modelStyle = modelStyle // 최신 데이터로 업데이트
                return updatedItem
            } else {
                return Item(modelStyle: modelStyle)
            }
        }

        if let selectedItem,
           let updatedSelectedItem = items.first(where: { $0.modelStyle.id == selectedItem.modelStyle.id }) {
            self.selectedItem = updatedSelectedItem
        }
    }

    // Selects a single item and updates the selectedItem state
    private func selectItem(_ item: ModelSelectView.Item) {
        selectedItem = item
        items = items.map { currentItem in
            var updatedItem = currentItem
            updatedItem.isSelected = (currentItem.id == item.id)
            return updatedItem
        }
    }

    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.includesActualByteCount = false

        return formatter.string(fromByteCount: bytes)
    }
}

extension ModelSelectView {
    struct Item: Identifiable {
        let id = UUID()
        var modelStyle: ModelStyle
        var isSelected: Bool = false
    }
}
