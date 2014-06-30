//
//  GameScene.swift
//  swiftSimpleGame
//
//  Created by pengfei huang on 14-6-30.
//  Copyright (c) 2014年 pengfei huang. All rights reserved.
//

import SpriteKit

let projectileCategory:UInt32     =  0x1 << 0;
let monsterCategory:UInt32        =  0x1 << 1;

func rwAdd(a:CGPoint , b:CGPoint ) -> CGPoint {
    return CGPointMake(a.x + b.x, a.y + b.y);
}

func rwSub(a:CGPoint, b:CGPoint ) -> CGPoint {
    return CGPointMake(a.x - b.x, a.y - b.y);
}

func rwMult(a:CGPoint, b:CGFloat) -> CGPoint {
    return CGPointMake(a.x * b, a.y * b);
}

func rwLength(a:CGPoint) -> CGFloat {
    return sqrtf(a.x * a.x + a.y * a.y);
}

// Makes a vector have a length of 1
func rwNormalize(a:CGPoint) -> CGPoint{
    let length = rwLength(a);
    return CGPointMake(a.x / length, a.y / length);
}

class GameOverScene:SKScene {
    
    init(size: CGSize, won: Bool) {
        super.init(size:size);
        
        // 1
        self.backgroundColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        // 2
        var message:String!
        
        if (won) {
            message = "You Won!";
        } else {
            message = "You Lose :[";
        }
        
        // 3
        let label = SKLabelNode(fontNamed:"Chalkduster");
        label.text = message;
        label.fontSize = 40;
        label.fontColor = SKColor.blackColor();
        label.position = CGPointMake(self.size.width/2, self.size.height/2);
        self.addChild(label);
        
        // 4
        self.runAction(
            SKAction.sequence([
                SKAction.waitForDuration(3.0),
                SKAction.runBlock({
                    // 5
                    let reveal = SKTransition.flipHorizontalWithDuration(0.5);
                    let myScene:GameScene = GameScene(size:self.size)
                    self.view.presentScene(myScene ,transition:reveal);
                })
            ])
        )
    }
}

class GameScene: SKScene,SKPhysicsContactDelegate {
    
    var player:SKSpriteNode!
    var lastSpawnTimeInterval:NSTimeInterval = 0
    var lastUpdateTimeInterval:NSTimeInterval = 0
    var monstersDestroyed:Int = 0
    
    override func didMoveToView(view: SKView) {
        
        // 3
        self.backgroundColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        // 4
        self.player = SKSpriteNode(imageNamed:"player");
        self.player.position = CGPointMake(self.player.size.width/2, self.frame.size.height/2);
        self.addChild(self.player);
        
        self.physicsWorld.gravity = CGVectorMake(0,0);
        self.physicsWorld.contactDelegate = self;
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        
//        self.runAction(SKAction.playSoundFileNamed("pew-pew-lei.caf",waitForCompletion:false));
        
        // 1 - Choose one of the touches to work with
        var touch:UITouch = touches.anyObject() as UITouch
        let location = touch.locationInNode(self)
        
        // 2 - Set up initial location of projectile
        let projectile = SKSpriteNode(imageNamed:"projectile");
        projectile.position = self.player.position;
        projectile.physicsBody = SKPhysicsBody(circleOfRadius:projectile.size.width/2);
        projectile.physicsBody.dynamic = true;
        projectile.physicsBody.categoryBitMask = projectileCategory;
        projectile.physicsBody.contactTestBitMask = monsterCategory;
        projectile.physicsBody.collisionBitMask = 0;
        projectile.physicsBody.usesPreciseCollisionDetection = true;
        
        // 3- Determine offset of location to projectile
        let offset = rwSub(location, projectile.position);
        
        // 4 - Bail out if you are shooting down or backwards
        if (offset.x <= 0) {
            return
        }
        
        // 5 - OK to add now - we've double checked position
        self.addChild(projectile);
        
        // 6 - Get the direction of where to shoot
        let direction = rwNormalize(offset);
        
        // 7 - Make it shoot far enough to be guaranteed off screen
        let shootAmount = rwMult(direction, 1000);
        
        // 8 - Add the shoot amount to the current position
        let realDest = rwAdd(shootAmount, projectile.position);
        
        // 9 - Create the actions
        let velocity = 480.0/1.0;
        let realMoveDuration = self.size.width / CGFloat(velocity);
        let actionMove = SKAction.moveTo(realDest,duration:NSTimeInterval(realMoveDuration));
        let actionMoveDone = SKAction.removeFromParent();
        projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]));
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        // Handle time delta.
        // If we drop below 60fps, we still want everything to move the same distance.
        var timeSinceLast = currentTime - self.lastUpdateTimeInterval;
        self.lastUpdateTimeInterval = currentTime;
        if (timeSinceLast > 1) { // more than a second since last update
            timeSinceLast = 1.0 / 60.0;
            self.lastUpdateTimeInterval = currentTime;
        }
        self.updateWithTimeSinceLastUpdate(timeSinceLast);
    }
    
    func addMonster() {
        // Create sprite
        var monster:SKSpriteNode = SKSpriteNode(imageNamed:"monster");
        monster.physicsBody = SKPhysicsBody(rectangleOfSize:monster.size); // 1
        monster.physicsBody.dynamic = true; // 2
        monster.physicsBody.categoryBitMask = monsterCategory; // 3
        monster.physicsBody.contactTestBitMask = projectileCategory; // 4
        monster.physicsBody.collisionBitMask = 0; // 5
        
        // Determine where to spawn the monster along the Y axis
        let minY = monster.size.height / 2
        let maxY = self.frame.size.height - monster.size.height / 2
        let rangeY  = maxY - minY
        let actualY = arc4random() % UInt32(rangeY) + UInt32(minY)
        
        // Create the monster slightly off-screen along the right edge,
        // and along a random position along the Y axis as calculated above
        monster.position = CGPointMake(self.frame.size.width + monster.size.width/2, CGFloat(actualY));
        self.addChild(monster);
        
        // Determine speed of the monster
        let minDuration = 2.0;
        let maxDuration = 4.0;
        let rangeDuration = maxDuration - minDuration;
        let actualDuration = (arc4random() % UInt32(rangeDuration)) + UInt32(minDuration);
        
        
        // Create the actions
        let actionMove = SKAction.moveTo(CGPointMake(-monster.size.width/2, CGFloat(actualY)),duration:NSTimeInterval(actualDuration))
        
        let actionMoveDone = SKAction.removeFromParent()

        let loseAction = SKAction.runBlock({
            let reveal = SKTransition.flipHorizontalWithDuration(0.5);
            let gameOverScene = GameOverScene(size:self.size,won:false);
            self.view.presentScene(gameOverScene,transition:reveal);
        })
        
        monster.runAction(SKAction.sequence([actionMove, loseAction, actionMoveDone]));
    }
    
    
    func updateWithTimeSinceLastUpdate(timeSinceLast:NSTimeInterval) {
        
        self.lastSpawnTimeInterval += timeSinceLast;

        if (self.lastSpawnTimeInterval > 1) {
            self.lastSpawnTimeInterval = 0
            self.addMonster()
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        var firstBody:SKPhysicsBody
        var secondBody:SKPhysicsBody;
        
        if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
        {
            firstBody = contact.bodyA;
            secondBody = contact.bodyB;
        }
        else
        {
            firstBody = contact.bodyB;
            secondBody = contact.bodyA;
        }
        
        // 2
        if ((firstBody.categoryBitMask & projectileCategory) != 0 &&
            (secondBody.categoryBitMask & monsterCategory) != 0)
        {
            self.projectile(firstBody.node as SKSpriteNode,didCollideWithMonster:secondBody.node as SKSpriteNode);
        }
    }
    
    func projectile(projectile:SKSpriteNode,didCollideWithMonster monster:SKSpriteNode) {
        
        projectile.removeFromParent();
        monster.removeFromParent();
        self.monstersDestroyed++;
        
        if (self.monstersDestroyed > 30) {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5);
            let gameOverScene = GameOverScene(size:self.size,won:true);
            self.view.presentScene(gameOverScene, transition: reveal);
        }
    }

}
