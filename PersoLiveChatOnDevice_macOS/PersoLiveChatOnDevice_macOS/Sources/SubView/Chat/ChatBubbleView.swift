//
//  Copyright © 2025 ESTsoft. All rights reserved.

import SwiftUI

struct ChatBubbleView: View {

    let message: Message

    var body: some View {
        Text(message.content)
            .textSelection(.enabled)
            .padding(12)
            .foregroundStyle(.white)
            .background(message.role == .user ? ._0X644AFF : ._0X1C1C1E)
            .clipShape(.rect(cornerRadius: 20, style: .continuous))
            .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}
