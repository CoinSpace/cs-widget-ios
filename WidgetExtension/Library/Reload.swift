//
//  Reload.swift
//  Coin
//
//  Created by Nikita Verkhovin on 24.04.2025.
//

import AppIntents
import WidgetKit

struct Reload: AppIntent {
    
    static var title: LocalizedStringResource = "Reload"
    
    func perform() async throws -> some IntentResult {
        print("reload")
        return .result()
    }
}
