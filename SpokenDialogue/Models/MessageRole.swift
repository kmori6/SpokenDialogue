//
//  MessageRole.swift
//  SpokenDialogue
//
//  Created by Kosuke Mori on 2026/04/01.
//

import Foundation

enum MessageRole: String, Codable, CaseIterable, Sendable {
    case user = "user"
    case assistant = "assistant"
}
