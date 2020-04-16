//
//  GameScene.swift
//  Bird Hero
//
//  Created by Galkov Nikita on 07.01.2020.
//  Copyright © 2020 Galkov Nikita. All rights reserved.
//

import SpriteKit
import GameplayKit


class GameScene: SKScene {
    
    let bird = SKSpriteNode(imageNamed: "fly1")//создаем птицу
    var lastUpdateTime: TimeInterval = 0//время последнего обновления
    var dt: TimeInterval = 0//разница времени
    let birdMovePointsPerSec: CGFloat = 480.0//за одну секунду птица перемещается на 480 точек
    var velocity = CGPoint.zero//вектор скорости Спрайта
    let playableRect: CGRect//ограничение игровой зоны
    var lastTouchLocation: CGPoint?//определение места касания экрана
    let birdAnimation: SKAction
    let covidAnimation: SKAction
    var hitAnimation: SKAction
    var invicible = false
    let coinMovePointsPerSec: CGFloat = 480.0
    var lives = 3
    var gameOver = false
    let cameraNode = SKCameraNode()
    let cameraMovePointsPerSec: CGFloat = 200.0
    var cameraRect: CGRect {
        let x = cameraNode.position.x - size.width  / 2 + (size.width - playableRect.width) / 2
        let y = (cameraNode.position.y - size.height  / 2 + (size.height - playableRect.height) / 2)
        return CGRect(x :x, y: y, width: playableRect.width, height: playableRect.height)
    }
    let livesLabel = SKLabelNode(fontNamed: "Chalkduster")
    let coinsLabel = SKLabelNode(fontNamed: "Chalkduster")
    let coinCollisionSound: SKAction = SKAction.playSoundFileNamed("coin.mp3", waitForCompletion: false)
    let covidCollisionSound = SKAction.playSoundFileNamed("hit.mp3", waitForCompletion: false)
    
    
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 19.5 / 9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight) / 2.0
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
        
        var textures: [SKTexture] = []//массив с текстурами для птицы
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "fly\(i)"))
        }
        
        birdAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        
        var covidTextures: [SKTexture] = []//массив с текстурами для птицы
             for i in 1...3 {
                 covidTextures.append(SKTexture(imageNamed: "covid\(i)"))
             }
             
        covidAnimation = SKAction.animate(with: covidTextures, timePerFrame: 0.2)
        
        var texturesHit: [SKTexture] = []//массив с текстурами для удара птицы
             for i in 1...2 {
                 texturesHit.append(SKTexture(imageNamed: "hit\(i)"))
             }
             
        hitAnimation = SKAction.animate(with: texturesHit, timePerFrame: 0.1)
        
        
        super.init(size: size)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        for i in 0...1 {
        let background = backgroundNode()
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background.position = CGPoint(x: CGFloat(i) * background.size.width, y: 0)
        background.name = "background"
        background.zPosition = -1
        
        
        addChild(background)
        }
        bird.position = CGPoint(x: 400, y: 500)
        bird.size = CGSize(width: 150, height: 150)
        addChild(bird)
        
        bird.run(SKAction.repeatForever(birdAnimation))
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run({ [weak self] in
            self?.spawnCovid()
        }),
                               SKAction.wait(forDuration: 0.8)])))
        
       run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run({ [weak self] in
            self?.spawnCoin()
        }),
                               SKAction.wait(forDuration: 1.0)])))
      
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        livesLabel.text = "Lives: x"
        livesLabel.fontColor = SKColor.black
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.verticalAlignmentMode = .bottom
        livesLabel.fontSize = 85
        livesLabel.zPosition = 150
        livesLabel.position = CGPoint(x: -playableRect.size.width / 2 + CGFloat(20),
            y: -playableRect.size.height / 2 + CGFloat(20))
        cameraNode.addChild(livesLabel)

        coinsLabel.text = "Vaccine: x"
        coinsLabel.fontColor = SKColor.black
        coinsLabel.horizontalAlignmentMode = .right
        coinsLabel.verticalAlignmentMode = .bottom
        coinsLabel.fontSize = 85
        coinsLabel.zPosition = 150
        coinsLabel.position = CGPoint(x: playableRect.size.width / 2 - CGFloat(20),
            y: -playableRect.size.height / 2 + CGFloat(20))
        cameraNode.addChild(coinsLabel)
        
        playBackgroundMusic(filename: "font.mp3")
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        if let lastTouchLocation = lastTouchLocation {
            let diff = lastTouchLocation - bird.position
            if diff.length() <= birdMovePointsPerSec * CGFloat(dt) {
                bird.position = lastTouchLocation
                velocity = CGPoint.zero
            } else {
                move(sprite: bird, velocity: velocity)
            }
        }
        
        boundsCheckBird()
   
        moveTrain()
        moveCamera()
        
        if lives <= 0 && !gameOver {
            gameOver = true
            print("Вы проиграли")
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            let reval = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reval)
            
            backgroundMusicPlayer.stop()
        }
        //moveCamera()
        livesLabel.text = "Lives: \(lives)"
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    func move(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt), y: velocity.y * CGFloat(dt))
        print("Расстояние для перемещения: \(amountToMove)")
        sprite.position = CGPoint(x: sprite.position.x + amountToMove.x,
                                  y: sprite.position.y + amountToMove.y)
    }
    
    func moveBirdToward(location: CGPoint) {
        let offset = CGPoint(x: location.x - bird.position.x, y: location.y - bird.position.y)//определяем смещение
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))//определяем длину вектора смещения
        let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length))//нормированный вектор
        velocity = CGPoint(x: direction.x * birdMovePointsPerSec, y: direction.y * birdMovePointsPerSec)//определяем скорость, как нормированный вектор
    }
    
    func sceneTouched(touchLocation: CGPoint) {
        lastTouchLocation = touchLocation
        moveBirdToward(location: touchLocation)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
   func boundsCheckBird() { //Проверка границ экрана
    let bottomLeft = CGPoint(x: cameraRect.minX, y: cameraRect.minY)
    let topRight = CGPoint (x: cameraRect.maxX, y: cameraRect.maxY + 150)
          if bird.position.x <= bottomLeft.x {
              bird.position.x = bottomLeft.x
              velocity.x = abs(velocity.x) //скорость по модулю
          }
          if bird.position.x >= topRight.x {
          bird.position.x = topRight.x
          velocity.x = -velocity.x
          }
          if bird.position.y <= bottomLeft.y {
              bird.position.y = bottomLeft.y
              velocity.y = -velocity.y
          }
          if bird.position.y >= topRight.y {
          bird.position.y = topRight.y
          velocity.y = -velocity.y
          }
    }
    
    func debugDrawPlayableArea() {//подсвечивание рабочей зоны
        let shape = SKShapeNode(rect: playableRect)
        shape.strokeColor = SKColor.blue
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    func spawnCovid() {//создаем птицу-врага
        let covid = SKSpriteNode(imageNamed: "covid1")
        covid.name = "covid1"
        //covid.xScale = covid.xScale * -1//переворачиваем птицу по оси Х
        covid.size = CGSize(width: 200, height: 165)
        covid.position = CGPoint(x: cameraRect.maxX + covid.size.width / 2,
                                  y: CGFloat.random(min: cameraRect.minY + covid.size.height / 2, max: cameraRect.maxY - covid.size.height / 2))
        covid.zPosition = 50
        
        covid.run(SKAction.repeatForever(covidAnimation))//анимация птицы врага
        addChild(covid)
        
        let actionMove = SKAction.moveBy(x: -size.width + covid.size.width, y: 0, duration: 2.5)
        let actionRemove = SKAction.removeFromParent()
        covid.run(SKAction.sequence([actionMove, actionRemove]))
    }
    
    func spawnCoin () {
        let coin = SKSpriteNode(imageNamed: "coin")
        coin.name = "coin"
        coin.size = CGSize(width: 85, height: 85)
        coin.position = CGPoint(x: CGFloat.random(min: cameraRect.minX, max: cameraRect.maxX),
                                y: CGFloat.random(min: cameraRect.minY , max: cameraRect.maxY))
        coin.zPosition = 50
        coin.setScale(0)
        addChild(coin)
        
        coin.zRotation = -CGFloat.pi / 16.0
        
        let leftWiggle = SKAction.rotate(byAngle: CGFloat.pi / 8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        let disappear = SKAction.scale(by: 0.0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        
        let actions = [appear, groupWait, disappear, removeFromParent]
        coin.run(SKAction.sequence(actions))
    }
    
    func birdHit(coin: SKSpriteNode) {
        run(coinCollisionSound)
        coin.name = "train"
        coin.removeAllActions()
        coin.setScale(1.0)
        coin.zRotation = 0
        
        let turnOrange = SKAction.colorize(with: SKColor.orange, colorBlendFactor: 1.0, duration: 0.15)
        coin.run(turnOrange)
        
        
    }
    
    func birdHit(covid: SKSpriteNode) {
        run(covidCollisionSound)
    
        invicible = true
        
        let Hit = hitAnimation
        let setHidden = SKAction.run { [weak self] in
            self?.bird.isHidden = false
            self?.invicible = false
        }
        
        bird.run(SKAction.sequence([Hit, Hit, Hit, Hit,Hit, Hit, Hit, Hit, Hit, Hit, Hit, Hit, Hit, setHidden]))
        
        loseCoins()
        lives -= 1
        
    }
    
    func checkCollisions() {
        var hitCoins: [SKSpriteNode] = []
        enumerateChildNodes(withName: "coin") { (node, _) in
            let coin = node as! SKSpriteNode
            if coin.frame.intersects(self.bird.frame) {
                hitCoins.append(coin)
            }
        }
        for coin in hitCoins {
            birdHit(coin: coin)
        }
        if invicible {
            return
        }
        var covidHit: [SKSpriteNode] = []
        enumerateChildNodes(withName: "covid1") { (node, _) in
            let covid = node as! SKSpriteNode
            if node.frame.insetBy(dx: 20, dy: 20).intersects(self.bird.frame) {
                covidHit.append(covid)
            }
        }
        for covid in covidHit {
            birdHit(covid: covid)
    }
}
    func moveTrain() {
        var trainCount = 0
        var targetPosition = bird.position
        enumerateChildNodes(withName: "train") { (node, stop) in
            trainCount += 1
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.coinMovePointsPerSec
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveBy(x: amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.run(moveAction)
            }
            targetPosition = node.position
        }
        if trainCount >= 30 && !gameOver {
            gameOver = true
            print("Вы выиграли!")
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            let reval = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reval)
            
            backgroundMusicPlayer.stop()
        }
        //moveCamera()
        coinsLabel.text = "Vaccine: \(trainCount)"
    }
    
    func backgroundNode() -> SKSpriteNode {
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.name = "background"
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPoint.zero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPoint.zero
        background2.position = CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        
        backgroundNode.size = CGSize(width: background1.size.width + background2.size.width, height: background1.size.height)
        
        return backgroundNode
    }
    
    
    func moveCamera() {
        let backgroundVelocity = CGPoint(x: cameraMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        cameraNode.position += amountToMove
        
        enumerateChildNodes(withName: "background") { (node, stop) in
            let background = node as! SKSpriteNode
            if background.position.x + background.size.width < self.cameraRect.origin.x {
                background.position = CGPoint(x: background.position.x + background.size.width * 2,
                                              y: background.position.y)
            
        }
}
}
    
    func fakeCoin() {
        let fakecoin = SKSpriteNode(imageNamed: "coin2")
        fakecoin.name = "coin2"
        fakecoin.size = CGSize(width: 85, height: 85)
        fakecoin.position = CGPoint(x: CGFloat.random(min: cameraRect.minX, max: cameraRect.maxX),
                                y: CGFloat.random(min: cameraRect.minY , max: cameraRect.maxY))
        fakecoin.zPosition = 50
        fakecoin.setScale(0)
        addChild(fakecoin)
        
        fakecoin.zRotation = -CGFloat.pi / 16.0
        
        let leftWiggle = SKAction.rotate(byAngle: CGFloat.pi / 8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        let disappear = SKAction.scale(by: 0.0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        
        let actions = [appear, groupWait, disappear, removeFromParent]
        fakecoin.run(SKAction.sequence(actions))
    }
    
    func loseCoins() {
        var loseCount = 0
        enumerateChildNodes(withName: "train") { (node, stop) in
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            node.name = ""
            node.run(SKAction.sequence([
                SKAction.group([
                    SKAction.rotate(byAngle: CGFloat.pi * 4, duration: 1.0),
                    SKAction.move(to: randomSpot, duration: 1.0),
                    SKAction.scale(to: 0, duration: 1.0)
                ]),
                SKAction.removeFromParent()
            ]))
            loseCount += 1
            if loseCount >= 2 {
                stop[0] = true
            }
        }
    }
}
