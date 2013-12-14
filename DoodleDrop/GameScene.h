//
//  GameScene.h
//  DoodleDrop
//
//  Created by mac  on 13-4-9.
//  Copyright 2013年 hb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface GameScene : CCLayer
{
    CCSprite * player;
    CGPoint playerVelocity;
    
    CCArray * spiderArray;
    float spiderMoveDuration;
    int numSpiderMoved;
    
    CCLabelBMFont * scoreLabel;
    CCLabelBMFont * numLabel;
    ccTime totalIime;
    int score;
}
+(id)scene;
@end
