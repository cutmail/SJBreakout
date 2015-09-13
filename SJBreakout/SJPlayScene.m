//
//  SJPlayScene.m
//  SJBreakout
//
//  Created by Tatsuya Arai on 9/13/15.
//  Copyright (c) 2015 cutmail. All rights reserved.
//

#import "SJPlayScene.h"

@interface SJPlayScene () <SKPhysicsContactDelegate>
@end

static const uint32_t blockCategory = 0x1 << 0;
static const uint32_t ballCategory = 0x1 << 1;

@implementation SJPlayScene

- (id)initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        [self addBlocks];
        [self addPaddle];
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        self.physicsWorld.contactDelegate = self;
    }
    return self;
}

static NSDictionary *config = nil;
+ (void)initialize {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!config) {
        config = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    }
}

#pragma mark - Block

- (void)addBlocks {
    int rows = [config[@"block"][@"rows"] floatValue];
    CGFloat margin = [config[@"block"][@"margin"] floatValue];
    CGFloat width = [config[@"block"][@"width"] floatValue];
    CGFloat height = [config[@"block"][@"height"] floatValue];
    
    int cols = floor(CGRectGetWidth(self.frame) - margin) / (width + margin);
    
    CGFloat y = CGRectGetHeight(self.frame) - margin - height / 2;
    
    for (int i = 0; i < rows; i++) {
        CGFloat x = margin + width / 2;
        for (int j = 0; j < cols; j++) {
            SKNode *block = [self newBlock];
            block.position = CGPointMake(x, y);
            x += width + margin;
        }
        y -= height + margin;
    }
}

- (SKNode *)newBlock {
    CGFloat width = [config[@"block"][@"width"] floatValue];
    CGFloat height = [config[@"block"][@"height"] floatValue];
    int maxLife = [config[@"block"][@"max_life"] floatValue];
    
    SKSpriteNode *block = [SKSpriteNode spriteNodeWithColor:[SKColor cyanColor] size:CGSizeMake(width, height)];
    block.name = @"block";
    
    int life = (arc4random() % maxLife) + 1;
    block.userData = @{ @"life" : @(life) }.mutableCopy;
    [self updateBlockAlpha:block];
    
    block.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:block.size];
    block.physicsBody.dynamic = NO;
    block.physicsBody.categoryBitMask = blockCategory;
    
    [self addChild:block];
    
    return block;
}

- (void)decreaseBlockLife:(SKNode *)block {
    int life = [block.userData[@"life"] intValue] - 1;
    block.userData[@"life"] = @(life);
    [self updateBlockAlpha:block];
    
    if (life < 1) {
        [self removeNodeWithSpark:block];
    }
}

- (void)removeNodeWithSpark:(SKNode *)node {
    NSString *sparkPath = [[NSBundle mainBundle] pathForResource:@"spark" ofType:@"sks"];
    SKEmitterNode *spark = [NSKeyedUnarchiver unarchiveObjectWithFile:sparkPath];
    spark.position = node.position;
    spark.xScale = spark.xScale = 0.3f;
    [self addChild:spark];
    
    SKAction *fadeOut = [SKAction fadeOutWithDuration:0.3f];
    SKAction *remove = [SKAction removeFromParent];
    SKAction *sequence = [SKAction sequence:@[fadeOut, remove]];
    [spark runAction:sequence];
    
    [node removeFromParent];
}

- (void)updateBlockAlpha:(SKNode *)block {
    int life = [block.userData[@"life"] intValue];
    block.alpha = life * 0.2f;
}

#pragma mark - Paddle

- (void)addPaddle {
    CGFloat width = [config[@"paddle"][@"width"] floatValue];
    CGFloat height = [config[@"paddle"][@"height"] floatValue];
    CGFloat y = [config[@"paddle"][@"y"] floatValue];
    
    SKSpriteNode *paddle = [SKSpriteNode spriteNodeWithColor:[SKColor brownColor] size:CGSizeMake(width, height)];
    paddle.name = @"paddle";
    paddle.position = CGPointMake(CGRectGetMidX(self.frame), y);
    
    paddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:paddle.size];
    paddle.physicsBody.dynamic = NO;
    
    [self addChild:paddle];
}

- (SKNode *)paddleNode {
    return [self childNodeWithName:@"paddle"];
}

#pragma mark - Ball

- (void)addBall {
    CGFloat radius = [config[@"ball"][@"radius"] floatValue];
    
    SKShapeNode *ball = [SKShapeNode node];
    ball.name = @"ball";
    ball.position = CGPointMake(CGRectGetMidX([self paddleNode].frame), CGRectGetMaxY([self paddleNode].frame) + radius);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddArc(path, NULL, 0, 0, radius, 0, M_PI * 2, YES);
    ball.path = path;
    ball.fillColor = [SKColor yellowColor];
    ball.strokeColor = [SKColor clearColor];
    
    CGPathRelease(path);
    
    CGFloat velocityX = [config[@"ball"][@"velocity"][@"x"] floatValue];
    CGFloat velocityY = [config[@"ball"][@"velocity"][@"y"] floatValue];

    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:radius];
    ball.physicsBody.affectedByGravity = NO;
    ball.physicsBody.velocity = CGVectorMake(velocityX, velocityY);
    ball.physicsBody.restitution = 1.0f;
    ball.physicsBody.linearDamping = 0;
    ball.physicsBody.friction = 0;
    ball.physicsBody.usesPreciseCollisionDetection = YES;
    ball.physicsBody.categoryBitMask = ballCategory;
    ball.physicsBody.contactTestBitMask = blockCategory;
    
    [self addChild:ball];
}

- (SKNode *)ballNode {
    return [self childNodeWithName:@"ball"];
}

#pragma mark - Touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (![self ballNode]) {
        [self addBall];
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    
    CGFloat speed = [config[@"paddle"][@"speed"] floatValue];
    
    CGFloat x = location.x;
    CGFloat diff = abs(x - [self paddleNode].position.x);
    CGFloat duration = speed * diff;
    SKAction *move = [SKAction moveToX:x duration:duration];
    [[self paddleNode] runAction:move];
}

#pragma mark - SKPhysicsContactDelegate

- (void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *firstBody, *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if (firstBody.categoryBitMask & blockCategory) {
        if (secondBody.categoryBitMask & ballCategory) {
            [self decreaseBlockLife:firstBody.node];
        }
    }
}

@end
