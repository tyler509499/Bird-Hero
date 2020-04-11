//
//  GameOverScene.swift
//  Bird Hero
//
//  Created by Galkov Nikita on 05.02.2020.
//  Copyright © 2020 Galkov Nikita. All rights reserved.
//

import UIKit
import SpriteKit

class GameOverScene: SKScene {
    let won: Bool
    init(size: CGSize, won: Bool) {
        self.won = won
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        var background: SKSpriteNode
        if won {
            background = SKSpriteNode(imageNamed: "win")
        } else {
            background = SKSpriteNode(imageNamed: "lose")
        }
        background.position = CGPoint(x: size.width / 2,
                                      y: size.height / 2)
        addChild(background)
        
        let wait = SKAction.wait(forDuration: 4.0)
        let block = SKAction.run {
            let myScene = GameScene(size: self.size)
            myScene.scaleMode = self.scaleMode
            let reval = SKTransition.flipHorizontal(withDuration: 0.5)
            self.view?.presentScene(myScene, transition: reval)
        }
        run(SKAction.sequence([wait, block]))
    }
}
