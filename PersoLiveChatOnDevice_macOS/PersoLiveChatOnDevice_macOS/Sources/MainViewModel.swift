//
//  Copyright © 2025 ESTsoft. All rights reserved.

import AVFAudio
import Combine
import Foundation

import PersoLiveChatOnDeviceSDK

@MainActor
final class MainViewModel: ObservableObject {

    enum UIState {
        case idle
        case started(PersoLiveChatSession)
        case terminated
        case error(String)
    }

    @MainActor @Published private(set) var uiState: UIState = .idle
    @MainActor @Published var messages: [Message] = []
    @Published var isRecording: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private let recorder = AudioRecorder()

    private var availableSTTTypes: [STTType] = []
    private var availableLLMTypes: [LLMType] = []
    private var availablePrompts: [Prompt] = []
    private var availableDocuments: [Document] = []
    private var availableTTSTypes: [TTSType] = []

    private var session: PersoLiveChatSession?
    private var modelStyle: ModelStyle

    private(set) var handleAssistantMessage: (String) -> Void = { _ in }
    var stopSpeech: (() async -> Void)?

    // MARK: - initialize

    init(modelStyle: ModelStyle) {
        self.modelStyle = modelStyle

        Task {
            try? await PersoLiveChat.load()
            
            try? await PersoLiveChat.warmup()
            await initializeSession()
            bind()
        }
    }

    func initializeSession() async {
        uiState = .idle
        if recorder.isRecording {
            _ = try? await recorder.stopRecording()
        }

        do {
            try await fetchAvailableFeatures()
            try await createSession()
        } catch {
            debugPrint("Unable to create session: \(error.localizedDescription)")
        }
    }

    private func bind() {
        recorder.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording
            }
            .store(in: &cancellables)
    }


    private func fetchAvailableFeatures() async throws {
        async let sttTypes = PersoLiveChat.fetchAvailableSTTModels()
        async let llmTypes = PersoLiveChat.fetchAvailableLLMModels()
        async let prompts = PersoLiveChat.fetchAvailablePrompts()
        async let documents = PersoLiveChat.fetchAvailableDocuments()
        async let ttsTypes = PersoLiveChat.fetchAvailableTTSModels()

        (availableSTTTypes, availableLLMTypes, availablePrompts, availableDocuments, availableTTSTypes) = try await (
            sttTypes, llmTypes, prompts, documents, ttsTypes
        )
    }

    private func createSession() async throws {
        let sttType = availableSTTTypes[0]
        let llmType = availableLLMTypes[0]
        let prompt = availablePrompts.first
        let document = availableDocuments.first
        let ttsType = availableTTSTypes[0]

        let session = try await PersoLiveChat.createSession(
            for: [
                .speechToText(type: sttType),
                .largeLanguageModel(llmType: llmType, promptType: prompt, documentType: document),
                .textToSpeech(type: ttsType)
            ],
            modelStyle: modelStyle
        ) { [weak self] sessionStatus in
            guard let self else { return }

            switch sessionStatus {
            case .started:
                break
            case .terminated:
                self.session = nil
                Task { @MainActor in
                    self.uiState = .terminated
                }
            default:
                break
            }
        }

        self.session = session
        self.uiState = .started(session)
    }

    private func startRecording() {
        do {
            try recorder.startRecording()
        } catch {
            debugPrint("failed to start recording \(error)")
        }
    }

    private func stopRecordingAndSTTProcess() {
        Task { [weak self] in
            guard let self else { return }

            do {
                let data = try await self.recorder.stopRecording()
                await processConversation(audio: data)
            } catch {
                debugPrint("recording error: \(error)")
            }
        }
    }

    func sendMessage(_ message: String) {
        messages.append(.init(role: .user, content: message))

        Task {
            await processConversation(message: message)
        }
    }

    func handleAssistantMessage(_ callback: @escaping (String) -> Void) {
        handleAssistantMessage = callback
    }

    func stopSession() {
        PersoLiveChat.stopSession()
    }
}

extension MainViewModel {
    func stopSpeechButtonDidTap() {
        Task {
            await stopSpeech?()
        }
    }

    func recordButtonDidTap() {
        recorder.isRecording ? stopRecordingAndSTTProcess() : startRecording()
    }

    func clearHistory() {
        session?.clearConversation()
        messages.removeAll()
    }
}

extension MainViewModel {
    private func processConversation(audio: Data) async {
        guard let session else { return }

        do {
            let userText = try await session.transcribeAudio(audio: audio, language: "ko")
            messages.append(.init(role: .user, content: userText))

            await processConversation(message: userText)
        } catch PersoLiveChatError.taskCancelled {
            debugPrint("STT task cancelled")
        } catch {
            debugPrint("STT conversation error")
        }
    }

    private func processConversation(message: String) async {
        guard let session else { return }

        var contents: [String] = []

        do {
            let sentenceStream = session.completeChat(message: message)

            for try await sentence in sentenceStream {
                handleAssistantMessage(sentence)
                contents.append(sentence)
            }

            messages.append(Message(role: .assistant, content: contents.joined(separator: "\n")))
        } catch PersoLiveChatError.largeLanguageModelStreamingResponseError {
            /// If a failure occurs during the LLM stream, display the message up to the processed portion.
            messages.append(Message(role: .assistant, content: contents.joined(separator: "\n")))
        } catch PersoLiveChatError.taskCancelled {
            debugPrint("LLM Task Cancelled")
        } catch {
            debugPrint("LLM conversation error")
        }
    }
}
