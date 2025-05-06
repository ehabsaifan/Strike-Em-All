//
//  GameContentProvider.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/6/25.
//

import Foundation

struct GameContent {
    let text: String   // Can be an emoji or a word
    let imageName: String? // Can store a local image reference
    
    init(text: String, imageName: String? = nil) {
        self.text = text
        self.imageName = imageName
    }
}

struct GameContentProvider {
    private let allContents: [GameContent] = [
        GameContent(text: "🍎", imageName: "apple"),
        GameContent(text: "🍌", imageName: "banana"),
        GameContent(text: "🍇", imageName: "grapes"),
        GameContent(text: "🍉", imageName: "watermelon"),
        GameContent(text: "🍍", imageName: "pineapple"),
        GameContent(text: "🥑", imageName: "avocado"),
        GameContent(text: "🍒", imageName: "cherries"),
        GameContent(text: "🍓", imageName: "strawberry"),
        GameContent(text: "🍑", imageName: "peach"),
        GameContent(text: "🍊", imageName: "orange")
    ]
    
    private let selectedContents: [GameContent] // ✅ Immutable list of selected items

    // ✅ Initialize with a valid number of items
    init(maxItems: Int = 5) {
        let validCount = max(1, min(maxItems, allContents.count)) // Ensure within range
        self.selectedContents = Array(allContents.shuffled().prefix(validCount))
    }

    // ✅ Returns content for a given index (ensuring consistency)
    func getContent(for index: Int) -> GameContent {
        return selectedContents[index % selectedContents.count]
    }

    // ✅ Returns all selected contents for left & right cells
    func getSelectedContents() -> [GameContent] {
        return selectedContents
    }
}
