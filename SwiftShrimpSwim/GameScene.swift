//
//  GameScene.swift
//  SwiftShrimpSwim
//
//  Created by katoy on 2015/05/03.
//  Copyright (c) 2015年 Youichi Kato. All rights reserved.
//
// See  http://www.shuwasystem.co.jp/support/7980html/4055.html
//      > 書籍： Sprite Kit iPhone 2Dゲームプログラミング 4 章
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    struct Constants {
        // Player 画像の名前の一覧
        static let PlayerImages = ["shrimp01", "shrimp02", "shrimp03", "shrimp04"]

        // Texture のファイル名
        static let BackgroundImage = "background"
        static let RockUnderImage  = "rock_under"
        static let RockAboveImage  = "rock_above"
        static let LandImage       = "land"
        static let CeilingImage    = "ceiling"
        static let CoralUnderImage = "coral_under"
        static let CoralAboveImage = "coral_above"
        static let GameOverImage   = "gameover"
        static let ScoreFont       = "Zapfino"  // "Arial Bold"
        static let ScoreColor      = UIColor.blackColor()

        static let bgSpeed : CGFloat = 10.0           // 背景の移動速度
        static let rockSpeed : CGFloat = 20.0         // 岩の移動速度
        static let landSpeed : CGFloat = 100          // 地面の移動速度
        static let bgPositionZ : CGFloat = -100.0     // 背景の Z 位置
        static let rockPositionZ : CGFloat = -50.0    // 岩の Z 位置
        static let landPositionZ : CGFloat = 0.0      // 地面の Z 位置
        static let scorePositionZ : CGFloat = 100     // スコアの　Z 位置
        static let touchForceY_First : CGFloat = 10   // タッチしたときの移動量の初期値
    }

    // 衝突判定につかう BitMask
    struct ColliderType {
        static let Player : UInt32 = (1 << 0)   // プレイキャラに設定するカテゴリ
        static let World  : UInt32 = (1 << 1)   // 天井・地面に設定するカテゴリ
        static let Coral  : UInt32 = (1 << 2)   // サンゴに設定するカテゴリ
        static let Score  : UInt32 = (1 << 3)   // スコア加算用SKNodeに設定するカテゴリ
        static let None   : UInt32 = (1 << 4)   // スコア加算用SKNodeに衝突した際に設定するカテゴリ
    }

    // ゲームの状態
    var score: UInt32 = 0              // スコアの内部変数
    var touchForceY : CGFloat = 10.0   // タッチしたときのプレーヤの上への移動量
                                       // この値が大きいと、ゲームが難しくなる。

    // SKSpritNode
    var baseNode: SKNode!              // プレイキャラ以外の移動オブジェクトを追加する空ノード
    var coralNode: SKNode!             // サンゴ関連のオブジェクトを追加する空ノード(リスタート時に活用)
    var player: SKSpriteNode!          // プレイキャラ
    var scoreLabelNode: SKLabelNode!   // スコアを表示するラベル

    override func didMoveToView(view: SKView) {
        setupGame()                             // ゲームの設定
        startGame(Constants.touchForceY_First)  // プレー開始
    }

    // ゲームの設定
    func setupGame() {
        // 物理シミュレーションを設定
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -2.0)
        self.physicsWorld.contactDelegate = self

        // 全ノードの親となるノードを生成
        baseNode = SKNode()
        self.addChild(baseNode)

        // 障害物を追加するノードを生成
        coralNode = SKNode()
        baseNode.addChild(coralNode)

        setupBackgroundSea()    // 背景画像を構築
        setupBackgroundRock()   // 背景の岩山画像を構築
        setupCeilingAndLand()   // 天井と地面を構築
        setupPlayer()           // プレイキャラを構築
        setupCoral()            // 障害物のサンゴを構築
        setupScoreLabel()       // スコアラベルの構築

        score = 0        // スコアの初期化
        touchForceY = 0  // touch 時の移動量
    }

    // プレー開始
    func startGame(forceY : CGFloat) {

        // ゲームの状態をセット
        self.touchForceY = forceY
        initScore()

        // 既存の障害物を全て取り除く
        coralNode.removeAllChildren()

        // プレイキャラを再配置
        player.position = CGPoint(x: self.frame.midX * 0.7, y: self.frame.midY * 1.2)
        player.physicsBody?.velocity = CGVector.zeroVector
        player.physicsBody?.collisionBitMask = ColliderType.World | ColliderType.Coral
        player.zRotation = 0.0

        // アニメーションを開始
        player.speed = 1.0
        baseNode.speed = 1.0
    }

    // スコアのリセット
    func initScore() {
        score = 0
        updateScore()
    }
    // スコアに加点する
    func incPoint(point : UInt32 = 1) {
        score += point
        updateScore()
    }
    // スコア表示を更新
    func updateScore() {
        scoreLabelNode.text = String(score)
        // スコアラベルをアニメーション
        let scaleUpAnim = SKAction.scaleTo(1.5, duration: 0.1)
        let scaleDownAnim = SKAction.scaleTo(1.0, duration: 0.1)
        scoreLabelNode.runAction(SKAction.sequence([scaleUpAnim, scaleDownAnim]))
    }

    // 横スクロールのアニメーションを作成する。
    func makeAnimeHorizontalScroll(texture : SKTexture, speed : CGFloat, yPosition : CGFloat, zPosition: CGFloat, isBg : Bool = false) {
        let width = texture.size().width
        // 左に画像一枚分移動のアニメーションを作成
        let moveAnim = SKAction.moveByX(-width, y: 0.0, duration: NSTimeInterval(width / Constants.bgSpeed))
        // 元の位置に戻すアニメーションを作成
        let resetAnim = SKAction.moveByX(width, y: 0.0, duration: 0.0)

        // 移動して元に戻すアニメーションを繰り返すアニメーションを作成
        let repeatForeverAnim = SKAction.repeatActionForever(SKAction.sequence([moveAnim, resetAnim]))

        let needNumber = 2.0 + (self.frame.size.width / texture.size().width)
        for var i:CGFloat = 0; i < needNumber; ++i {
            // SKTexture から SKSpriteNode を作成
            let sprite = SKSpriteNode(texture: texture)
            // 奥行きの位置 (zPositon) を設定
            sprite.zPosition = zPosition
            // 画像の初期位置を設定
            sprite.position = CGPoint(x: i * sprite.size.width, y: yPosition)

            if isBg == false {
                // 画像に物理シミュレーションを設定
                sprite.physicsBody = SKPhysicsBody(texture: texture, size: sprite.size)
                sprite.physicsBody?.dynamic = false
                sprite.physicsBody?.categoryBitMask = ColliderType.World
            }
            // アニメーションを設定
            sprite.runAction(repeatForeverAnim)
            // 親ノードに追加
            baseNode.addChild(sprite)
        }
    }

    // 背景画像を構築
    func setupBackgroundSea() {
        // 背景画像を読み込む
        let texture = SKTexture(imageNamed: Constants.BackgroundImage)
        texture.filteringMode = .Nearest

        // 画像を配置してアニメーションを設定
        let yPosition = texture.size().height / 2.0
        makeAnimeHorizontalScroll(texture, speed: Constants.bgSpeed, yPosition: yPosition, zPosition: Constants.bgPositionZ, isBg: true)
    }

    // 背景の岩山画像を構築
    func setupBackgroundRock() {
        // 岩山(下)画像を読み込む
        let under = SKTexture(imageNamed: Constants.RockUnderImage)
        under.filteringMode = .Nearest

        // 画像の配置とアニメーションを設定
        let yPosition = under.size().height / 2.0
        makeAnimeHorizontalScroll(under, speed: Constants.rockSpeed, yPosition: yPosition, zPosition: Constants.rockPositionZ, isBg: true)

        // 岩山(上)画像を読み込む
        let above = SKTexture(imageNamed: Constants.RockAboveImage)
        above.filteringMode = .Nearest

        // 画像の配置とアニメーションを設定
        let yPosition2 = self.size.height - above.size().height / 2.0
        makeAnimeHorizontalScroll(above, speed: Constants.rockSpeed, yPosition: yPosition2, zPosition: Constants.rockPositionZ, isBg: true)
    }

    // 天井と地面を構築
    func setupCeilingAndLand() {
        // 地面画像を読み込み
        let land = SKTexture(imageNamed: Constants.LandImage)
        land.filteringMode = .Nearest

        // 画像の配置とアニメーションを設定
        let yPosition = land.size().height / 2.0
        makeAnimeHorizontalScroll(land, speed: Constants.landSpeed, yPosition: yPosition, zPosition: Constants.landSpeed)

        // 天井画像を読み込み
        let ceiling = SKTexture(imageNamed: Constants.CeilingImage)
        ceiling.filteringMode = .Nearest

        // 画像の配置とアニメーションを設定
        let yPosition2 = self.size.height - ceiling.size().height / 2.0
        makeAnimeHorizontalScroll(ceiling, speed: Constants.landSpeed, yPosition: yPosition2, zPosition: Constants.landSpeed)
    }

    // プレイヤーを構築
    func setupPlayer() {

        func makePlayerNode() -> (SKTexture, SKSpriteNode) {
            // Player のパラパラアニメーション作成に必要な SKTexture クラスの配列を定義
            var playerTexture = [SKTexture]()

            // パラパラアニメーションに必要な画像を読み込む
            for imageName in Constants.PlayerImages {
                let texture = SKTexture(imageNamed: imageName)
                texture.filteringMode = .Linear
                playerTexture.append(texture)
            }

            // キャラクターのアニメーションをパラパラ漫画のように切り替える
            let playerAnimation = SKAction.animateWithTextures(playerTexture, timePerFrame: 0.2)
            // パラパラアニメーションをループさせる
            let loopAnimation = SKAction.repeatActionForever(playerAnimation)

            // キャラクターを生成
            let sprite = SKSpriteNode(texture: playerTexture[0])

            // 初期表示位置を設定
            sprite.position = CGPoint(x: self.frame.midX * 0.7, y: self.frame.size.height * 0.5)
            // アニメーションを設定

            sprite.runAction(loopAnimation)
            return (playerTexture[0], sprite)
        }

        // player の sprite を生成
        let r = makePlayerNode()
        let texture = r.0
        player = r.1

        // 物理シミュレーションを設定
        player.physicsBody = SKPhysicsBody(texture: texture, size: texture.size())
        player.physicsBody?.dynamic = true
        player.physicsBody?.allowsRotation = false

        // 自分自身に Player カテゴリを設定
        player.physicsBody?.categoryBitMask = ColliderType.Player
        // 衝突判定相手に World と Coral を設定
        player.physicsBody?.collisionBitMask = ColliderType.World | ColliderType.Coral
        player.physicsBody?.contactTestBitMask = ColliderType.World | ColliderType.Coral

        self.addChild(player)
    }

    //  障害物のサンゴを構築
    func setupCoral() {
        // サンゴ画像を読み込み
        let coralUnder = SKTexture(imageNamed: Constants.CoralUnderImage)
        coralUnder.filteringMode = .Linear
        let coralAbove = SKTexture(imageNamed: Constants.CoralAboveImage)
        coralAbove.filteringMode = .Linear

        // 移動する距離を算出
        let distanceToMove = CGFloat(self.frame.size.width + 2.3 * coralUnder.size().width)

        // 画面外まで移動するアニメーションを作成
        let moveAnim = SKAction.moveByX(-distanceToMove, y: 0.0, duration:NSTimeInterval(distanceToMove / Constants.landSpeed))
        // 自身を取り除くアニメーションを作成
        let removeAnim = SKAction.removeFromParent()

        // 2つのアニメーションを順に実行するアニメーションを作成
        let coralAnim = SKAction.sequence([moveAnim, removeAnim])

        // サンゴを生成するメソッドを呼び出すアニメーションを作成
        let newCoralAnim = SKAction.runBlock({

            func setPhisicsAttr(sprite : SKNode, bitmask : UInt32) {
                sprite.physicsBody?.dynamic = false
                sprite.physicsBody?.categoryBitMask = bitmask
                sprite.physicsBody?.contactTestBitMask = ColliderType.Player
            }

            // サンゴに関するノードを乗せるノードを作成
            let coral = SKNode()
            coral.position = CGPoint(x: self.frame.size.width + coralUnder.size().width * 2, y: 0.0)
            coral.zPosition = Constants.rockPositionZ

            // 地面から伸びるサンゴの y 座標を乱数で算出
            let height = UInt32(self.frame.size.height / 12)
            let y = CGFloat(arc4random_uniform(height * 2) + height)

            // 地面から伸びるサンゴを作成
            let under = SKSpriteNode(texture: coralUnder)
            under.position = CGPoint(x: 0.0, y: y)

            // サンゴに物理シミュレーションを設定
            under.physicsBody = SKPhysicsBody(texture: coralUnder, size: under.size)
            setPhisicsAttr(under, ColliderType.Coral)
            coral.addChild(under)

            // 天井から伸びるサンゴを作成
            let above = SKSpriteNode(texture: coralAbove)
            above.position = CGPoint(x: 0.0, y: y + (under.size.height / 2.0) + 160.0 + (above.size.height / 2.0))

            // サンゴに物理シミュレーションを設定
            above.physicsBody = SKPhysicsBody(texture: coralAbove, size: above.size)
            setPhisicsAttr(above, ColliderType.Coral)
            coral.addChild(above)

            // スコアをカウントアップするスコアノードを作成
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: (above.size.width / 2.0) + 5.0, y: self.frame.height / 2.0)

            // スコアノードに物理シミュレーションを設定
            scoreNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 10.0, height: self.frame.size.height))
            setPhisicsAttr(scoreNode, ColliderType.Score)
            coral.addChild(scoreNode)

            coral.runAction(coralAnim)

            self.coralNode.addChild(coral)
        })
        // 一定間隔待つアニメーションを作成
        let delayAnim = SKAction.waitForDuration(2.5)
        // 上記 2 つを永遠に繰り返すアニメーションを作成
        let repeatForeverAnim = SKAction.repeatActionForever(SKAction.sequence([newCoralAnim, delayAnim]))

        // この画面で実行
        self.runAction(repeatForeverAnim)
    }

    // スコアラベルを構築
    func setupScoreLabel() {
        // フォントを指定してラベルを作成
        scoreLabelNode = SKLabelNode(fontNamed: Constants.ScoreFont)
        // フォント色を設定
        scoreLabelNode.fontColor = Constants.ScoreColor

        // 表示位置を設定
        scoreLabelNode.position = CGPoint(x: self.frame.midX, y: self.frame.maxY * 0.9)
        // 最前面に表示
        scoreLabelNode.zPosition = Constants.scorePositionZ

        self.addChild(scoreLabelNode)
    }

    // SKPhysicsContactDelegateプロトコルの実装
    // 衝突開始時のイベントハンドラ
    func didBeginContact(contact: SKPhysicsContact) {
        // 既にゲームオーバー状態の場合
        if baseNode.speed <= 0.0 {
            return
        }

        let rawScoreType = ColliderType.Score
        let rawNoneType = ColliderType.None

        if (contact.bodyA.categoryBitMask & rawScoreType) == rawScoreType ||
            (contact.bodyB.categoryBitMask & rawScoreType) == rawScoreType {
                // スコアを加算してラベルに反映
                incPoint()

                // スコアカウントアップに設定されている contactTestBitMask を変更
                if (contact.bodyA.categoryBitMask & rawScoreType) == rawScoreType {
                    contact.bodyA.categoryBitMask = ColliderType.None
                    contact.bodyA.contactTestBitMask = ColliderType.None
                } else {
                    contact.bodyB.categoryBitMask = ColliderType.None
                    contact.bodyB.contactTestBitMask = ColliderType.None
                }
        } else if (contact.bodyA.categoryBitMask & rawNoneType) == rawNoneType ||
            (contact.bodyB.categoryBitMask & rawNoneType) == rawNoneType {
                // なにもしない
        } else {
            doGameOver()
        }
    }

    func doGameOver() {
        // baseNode に追加されたものすべてのアニメーションを停止
        baseNode.speed = 0.0

        // プレイキャラの BitMask を変更
        player.physicsBody?.collisionBitMask = ColliderType.World
        // プレイキャラに回転アニメーションを実行
        let rolling = SKAction.rotateByAngle(CGFloat(M_PI) * player.position.y * 0.01, duration: 1.0)
        player.runAction(rolling, completion:{
            // アニメーション終了時にプレイキャラのアニメーションを停止
            self.player.speed = 0.0
        })
        // ゲームオーバーの表示
        let sprite = SKSpriteNode(imageNamed: Constants.GameOverImage)
        sprite.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        self.coralNode.addChild(sprite)
    }

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        if baseNode.speed == 0.0 && player.speed == 0.0 {
            // ゲームオーバーしていた時は、ゲームをリスタートする
            startGame(Constants.touchForceY_First)
            return
        }

        // ゲーム進行中のとき
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            // プレイヤーに加えられている力をゼロにする
            player.physicsBody?.velocity = CGVector.zeroVector
            // プレイヤーに y 軸方向へ力を加える
            player.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: touchForceY))
        }
    }

    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}