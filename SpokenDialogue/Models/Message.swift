//
//  Message.swift
//  SpokenDialogue
//
//  Created by Kosuke Mori on 2026/03/31.
//

import Foundation

struct Message: Identifiable {
    let id: UUID
    let role: MessageRole
    var content: String

    init(id: UUID = UUID(), role: MessageRole, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }
}
