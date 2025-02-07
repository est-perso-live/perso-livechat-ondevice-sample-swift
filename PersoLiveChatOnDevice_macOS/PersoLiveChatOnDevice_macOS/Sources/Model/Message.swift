//
//  Copyright © 2025 ESTsoft. All rights reserved.

import Foundation

struct Message: Codable, Identifiable, Equatable {
    let id: UUID
    let role: Role
    let content: String

    init(role: Role, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
    }
}

