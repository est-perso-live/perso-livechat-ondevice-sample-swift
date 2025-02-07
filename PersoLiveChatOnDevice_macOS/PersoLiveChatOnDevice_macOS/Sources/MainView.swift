//
//  Copyright © 2025 ESTsoft. All rights reserved.

import AVFAudio
import SwiftUI

import PersoLiveChatOnDeviceSDK

struct MainView: View {

    // MARK: - property
    @Binding var path: [Screen]

    @StateObject private var viewModel: MainViewModel

    @State private var showChatView: Bool = false

    // MARK: - initialize

    init(path: Binding<[Screen]>, modelStyle: ModelStyle) {
        self._viewModel = .init(wrappedValue: .init(modelStyle: modelStyle))
        self._path = path
    }

    // MARK: - body

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                switch viewModel.uiState {
                case .idle:
                    IdleView()
                case .started(let session):
                    StartedView(
                        session: session,
                        geometry: geometry,
                        showChatView: $showChatView
                    )
                    .environmentObject(viewModel)
                case .terminated:
                    TerminatedView {
                        Task { await viewModel.initializeSession() }
                    }
                    .onAppear {
                        viewModel.clearHistory()
                    }
                case .error(let errorMessage):
                    ErrorView(errorMessage: errorMessage) {
                        Task { await viewModel.initializeSession() }
                    }
                }
            }
            .background(BackgroundView())
            .onDisappear(perform: viewModel.stopSession)
        }
    }
}

// MARK: - subview

extension MainView {
    struct StartedView: View {
        let session: PersoLiveChatSession
        let geometry: GeometryProxy

        @Binding var showChatView: Bool
        @State private var orientation: ViewOrientation = .unowned

        @EnvironmentObject var viewModel: MainViewModel

        enum ViewOrientation {
            case portrait
            case landscape
            case unowned
        }

        var body: some View {
            HSplitView {
                ZStack {
                    PersoVideoViewRepresentable(session: session)
                        .environmentObject(viewModel)
                        .ignoresSafeArea(edges: .bottom)
                        .overlay(alignment: .bottomTrailing) {
                            if orientation == .portrait {
                                chatView
                                    .opacity(showChatView ? 1 : 0)
                                    .frame(width: geometry.size.width * 0.4)
                                    .allowsHitTesting(true)
                                    .animation(.easeInOut, value: showChatView)
                            }
                        }

                    VStack {
                        Spacer()

                        HStack {
                            micButton

                            speechStopButton

                            if orientation == .portrait {
                                chatButton

                                Spacer()
                            } else {
                                Spacer()

                                chatButton
                            }
                        }
                    }
                    .padding([.bottom, .horizontal])
                }

                if orientation == .landscape {
                    chatView
                        .opacity(showChatView ? 1 : 0)
                        .frame(width: showChatView ? geometry.size.width * 0.35 : 0)
                }
            }
            .onAppear {
                orientation = geometry.size.width > geometry.size.height ? .landscape : .portrait
            }
            .onChange(of: geometry.size) { _, newSize in
                orientation = newSize.width > newSize.height ? .landscape : .portrait
            }
        }

        private var chatView: some View {
            ChatView()
                .background(.clear)
                .environmentObject(viewModel)
        }

        private var micButton: some View {
            Button(action: viewModel.recordButtonDidTap) {
                Group {
                    if viewModel.isRecording {
                        RoundedRectangle(cornerRadius: 4)
                            .frame(width: 20, height: 20)
                            .foregroundStyle(.red)
                    } else {
                        Image(systemName: "mic")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 64, height: 64)
                .background(._0X644AFF)
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }

        private var speechStopButton: some View {
            Button(action: viewModel.stopSpeechButtonDidTap) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(._0X644AFF)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }

        private var chatButton: some View {
            Button(action: { showChatView.toggle() }) {
                Image(systemName: "keyboard")
                    .font(.system(size: 24))
                    .foregroundStyle(.black)
                    .frame(width: 64, height: 64)
                    .background(.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    struct IdleView: View {
        var body: some View {
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
    }

    struct TerminatedView: View {
        let retryAction: () -> Void

        var body: some View {
            VStack {
                Text("Terminated Session")
                    .foregroundStyle(.white)
                    .font(.subheadline)

                Button("Retry", action: retryAction)
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    struct ErrorView: View {
        let errorMessage: String
        let retryAction: () -> Void

        var body: some View {
            VStack {
                Text("Error")
                    .font(.headline)
                    .foregroundStyle(.red)

                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Button("Retry", action: retryAction)
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    struct BackgroundView: View {
        var body: some View {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                Image(.background)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            }
        }
    }
}
