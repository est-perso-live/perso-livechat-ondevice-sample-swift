//
//  Copyright © 2025 ESTsoft. All rights reserved.

import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: MainViewModel
    @State private var newMessage: String = ""
    @State private var isTypingMessage: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            VStack {
                HStack {
                    Spacer()

                    Button(action: viewModel.clearHistory) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(._0X1C1C1E)
                            .frame(width: 32, height: 32)
                            .background(._0XF3F3F1)
                            .opacity(viewModel.messages.isEmpty ? 0.7 : 1)
                            .clipShape(.circle)
                    }
                    .buttonStyle(.plain)
                }
                .padding([.top, .horizontal], 16)

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(viewModel.messages) { message in
                                ChatBubbleView(message: message)
                                    .padding(message.role == .user ? .leading : .trailing, size.width / 10)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    .onChange(of: viewModel.messages) { oldValue, newValue in
                        if oldValue.count != newValue.count,
                           let lastItemID = newValue.last?.id {
                            proxy.scrollTo(lastItemID)
                        }
                    }
                    .onAppear {
                        if let lastItemID = viewModel.messages.last?.id {
                            proxy.scrollTo(lastItemID, anchor: .bottom)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black.opacity(0.001))
                .onTapGesture {
                    isTextFieldFocused = false
                }

                HStack {
                    ZStack(alignment: .leading) {
                        if newMessage.isEmpty {
                            Text("Please enter your message.")
                                .foregroundColor(Color._0XB6B6B6)
                                .font(.system(size: 16))
                        }

                        TextField("", text: $newMessage)
                            .textFieldStyle(.plain)
                            .focused($isTextFieldFocused)
                            .frame(height: 30)
                            .padding(.vertical, 10)
                            .foregroundStyle(.black)
                            .font(.system(size: 16))
                            .autocorrectionDisabled()
                            .submitLabel(.send)
                            .onSubmit(sendMessage)
                            .onChange(of: newMessage) { oldValue, newValue in
                                let isTyping = !newValue.isEmpty
                                if isTypingMessage != isTyping {
                                    withAnimation {
                                        isTypingMessage = isTyping
                                    }
                                }
                            }
                    }

                    if !newMessage.isEmpty {
                        Button(action: sendMessage) {
                            Image(.sendMessage)
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundStyle(.white, ._0X1C1C1E)
                                .symbolVariant(.fill.circle)
                                .symbolEffect(.bounce, value: isTypingMessage)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .background(Capsule(style: .continuous).fill(._0XF3F3F1))
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
            .background(.clear)
        }
    }

    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        viewModel.sendMessage(newMessage)
        newMessage = ""
    }
}

#Preview {
    ChatView()
}
