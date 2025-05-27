//
//  GameSceneView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 3/9/25.
//

import SwiftUI
import SpriteKit

struct GameSceneView: View {
    let scene: GameScene
    let physicsService: SpriteKitPhysicsService
    
    init() {
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        self.scene = scene
        self.physicsService = SpriteKitPhysicsService(scene: scene)
    }
    
    var body: some View {
        SpriteView(scene: scene).ignoresSafeArea()
    }
}

struct GameSceneView_Previews: PreviewProvider {
    static var previews: some View {
        GameSceneView()
    }
}
