//
//  LLM.swift
//  SpokenDialogue
//
//  Created by Kosuke Mori on 2026/03/31.
//

import Foundation

enum LLM: String, CaseIterable, Identifiable {
    case gpt = "gpt-5.4"
    case gptMini = "gpt-5.4-mini"
    case gptNano = "gpt-5.4-nano"
    var id: String { rawValue }
}
