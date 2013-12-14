//
//  GameScene.m
//  DoodleDrop
//
//  Created by mac hb on 13-4-9.
//  Copyright 2013年 . All rights reserved.
//

#import "GameScene.h"
#import "SimpleAudioEngine.h"
//#import "GameConfig.h"

@implementation GameScene
+(id)scene
{
    CCScene * scene = [CCScene node];
    CCLayer * layer = [GameScene node];
    [scene addChild:layer];
    return scene;
}
-(void)spiderDidDrop:(id)sender
{
    NSAssert([sender isKindOfClass:[CCSprite class]],@"sender is not a CCSprite!");//程序出错时马上抛出异常
    CCSprite * spider = (CCSprite *)sender;
    CGPoint pos = spider.position;
    CGSize screenSize = Size;
    pos.y = screenSize.height + [spider texture].contentSize.height;
    spider.position = pos;
}
-(void)runSpiderMoveSequence:(CCSprite *)spider
{
    numSpiderMoved ++;
    if (numSpiderMoved % 4 == 0 && spiderMoveDuration>2.0f) {
        spiderMoveDuration -= 0.3f;
    }
    CGSize screenSize = Size;
    CGPoint hangInTherePosition = CGPointMake(spider.position.x, screenSize.height-3*[spider texture].contentSize.height);
    CGPoint belowScreenPosition = CGPointMake(spider.position.x ,- (3*[spider texture].contentSize.height));
    CCMoveTo * moveHang = [CCMoveTo actionWithDuration:4 position:hangInTherePosition];//是终点值， 就是你那个点是哪就移动到哪，不管开始在哪
    CCEaseElasticOut * easeHang = [CCEaseElasticOut actionWithAction:moveHang period:0.8f];//渐快的弹性移动；
    CCMoveTo * moveEnd = [CCMoveTo actionWithDuration:spiderMoveDuration position:belowScreenPosition];
    CCEaseBackInOut * easeEnd = [CCEaseBackInOut actionWithAction:moveEnd];//修饰前的动作运行前向后，运行结束后回弹
    
    CCCallFuncN * callDidDrop = [CCCallFuncN actionWithTarget:self selector:@selector(spiderDidDrop:)];//不带参数的回调方法
    CCSequence * sequence = [CCSequence actions:easeHang,easeEnd,callDidDrop, nil];
    
    [spider runAction:sequence];
}
-(void)spidersUpdate:(ccTime)delta
{
    for (int i=0; i<10; i++) {//找空闲的蜘蛛
        int randomSpiderIndex = CCRANDOM_0_1() * [spiderArray count];//随机选择
        CCSprite * spider = [spiderArray objectAtIndex:randomSpiderIndex];
        if ([spider numberOfRunningActions] == 0) {//判断蜘蛛是不是空闲的
            if (i > 0)
			{
				CCLOG(@"Dropping a Spider after %i retries.", i);
			}
            [self runSpiderMoveSequence:spider];
            break;
        }
    }
}
-(void) resetSpiders
{
    CGSize screenSize = Size;
    CCSprite * tempSpider = [spiderArray lastObject];
    CGSize size = [tempSpider texture].contentSize;
    int numSpiders = [spiderArray count];
    for (int i=0; i<numSpiders; i++) {
        CCSprite * spider = [spiderArray objectAtIndex:i];
        spider.position = CGPointMake(size.width*i + size.width*0.5, screenSize.height + size.height);
        spider.scale = 1;
        [spider stopAllActions];
    }
    [self unschedule:@selector(spidersUpdate:)];//特定的选择器方法的停止（spidersUpdate）
    [self schedule:@selector(spidersUpdate:) interval:0.7f];//0.7秒调用一次方法（蜘蛛从屏幕顶端 落下的时间间隔）
    numSpiderMoved = 0;
    spiderMoveDuration = 8.0f;
}
-(void) resetGame
{
    [self setScreenSaverEnable:NO];
    [self removeChildByTag:100 cleanup:YES];
    [self removeChildByTag:101 cleanup:YES];
    self.isAccelerometerEnabled = YES;
    self.isTouchEnabled = NO;
    
	[self resetSpiders];
    [self scheduleUpdate];
    
	score = 0;
	totalIime = 0;
	[scoreLabel setString:@"0"];
    [numLabel setString:@"0"];
}
//添加障碍物
-(void) initSpriders
{
    CGSize screenSize = Size;
    CCSprite * temSpider = [CCSprite spriteWithFile:@"spider.png"];//创建名为 tempSpider 的 CCSprite 对象只是为了获得精灵图像的宽度
    float imageWidth = [temSpider texture].contentSize.width;
    int numSpriders = screenSize.width/imageWidth;
    NSAssert(spiderArray == nil, @"%@: spiders array is already initialized!", NSStringFromSelector(_cmd));

    spiderArray = [[CCArray alloc] initWithCapacity:numSpriders];
    for (int i=0; i<numSpriders; i++) {
        CCSprite * spider = [CCSprite spriteWithFile:@"spider.png"];
        [self addChild:spider z:0 tag:2];
        [spiderArray addObject:spider];
    }
    [self resetSpiders];
}


//加速计
-(void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
    float deceleration = 0.4f;
    float sensitivity = 6.0f;
    float maxVelocity = 100;
    
    playerVelocity.x = playerVelocity.x * deceleration + acceleration.x*sensitivity;
    if (playerVelocity.x > maxVelocity) {
        playerVelocity.x = maxVelocity;
    }else if(playerVelocity.x<-maxVelocity){
        playerVelocity.x = -maxVelocity;
    }
}
//碰撞监测
-(void)checkForCollision
{
    [numLabel setString:[NSString stringWithFormat:@"%i",numSpiderMoved]];//下落得个数更新

    float playerImageSize = [player texture].contentSize.height;
    float spiderImageSize = [[spiderArray lastObject] texture].contentSize.height;
    
    float playerCollisionRadius = playerImageSize*0.5f;
    float spiderCollisionRadius = spiderImageSize*0.5f;
    float maxCOllisionDistance = playerCollisionRadius + spiderCollisionRadius;
    
    int numSpiders = spiderArray.count;
    for (int i=0; i<numSpiders; i++) {
        CCSprite * spider = [spiderArray objectAtIndex:i];
        if ([spider numberOfRunningActions] == 0) {
            continue;
        }
        float actualDistabce = ccpDistance(player.position, spider.position);//当前选 定的蜘蛛与玩家的距离
        if (actualDistabce < maxCOllisionDistance) {
            //播放音效
            [[SimpleAudioEngine sharedEngine] playEffect:@"alien-sfx.caf"];
            [self showGameOver];
            break;
        }
    }
}

//更新方法
-(void)update:(ccTime)detale
{
    //位置更新
    CGPoint pos = player.position;
    pos.x += playerVelocity.x;
    CGSize screenSize = Size;
    float imageWidthHalve = [player texture].contentSize.width * 0.5f;
    float leftBorderLimit = imageWidthHalve;
    float rightBorderLimit = screenSize.width - imageWidthHalve;
    if (pos.x < leftBorderLimit) {//判断边界
        pos.x = leftBorderLimit;
        playerVelocity = CGPointZero;
    }else if(pos.x>rightBorderLimit){
    pos.x = rightBorderLimit;
        playerVelocity = CGPointZero;
    }
    player.position = pos;
    [self checkForCollision];
    //时间更新
    totalIime +=detale;
    int currentTime = (int)totalIime;
    if (score < currentTime) {
        score = currentTime;
        [scoreLabel setString:[NSString stringWithFormat:@"%i",score]];
    }        
}

-(void) draw
{
    //蜘蛛后面的圈
	for (CCNode* node in [self children])
	{
		if ([node isKindOfClass:[CCSprite class]] && (node.tag == 1 || node.tag == 2))
		{
			CCSprite* sprite = (CCSprite*)node;
			float radius = [sprite texture].contentSize.width * 0.4f;
			float angle = 0;
			int numSegments = 10;
			bool drawLineToCenter = NO;
			ccDrawCircle(sprite.position, radius, angle, numSegments, drawLineToCenter); //绘制圆函数，参1是中心点，参2为半径,参3为圆的逆时针旋转角度，参4为圆的平均切分段数，最后一个参数是指定是否从圆分段起止点位置向圆中心连线，这里不进行连线  
		}
	}
    //蜘蛛上面挂得线
    CGSize screenSize = Size;
    float threadCutPosition = screenSize.height * 0.75f;
    CCSprite * spider;
    CCARRAY_FOREACH(spiderArray, spider)//遍历
    {
        if (spider.position.y > threadCutPosition) {
            float threadX = spider.position.x + (CCRANDOM_0_1() *2.0f - 1.0f);//CCRANDOM_0_1()随机数
            glColor4f(0.5f, 0.5f, 0.5f, 1.0f);
            ccDrawLine(spider.position, CGPointMake(threadX, screenSize.height));
        }
    }
}
//设置这个属性设置为YES，禁用“空闲计时器”，以避免系统睡眠。
-(void)setScreenSaverEnable:(BOOL)enabled
{
    UIApplication * thisApp = [UIApplication sharedApplication];
    thisApp.idleTimerDisabled = !enabled;//设置这个属性设置为YES，禁用“空闲计时器”，以避免系统睡眠。
}
//game over 后调用得精灵放大缩小得方法
-(void)runSpiderWiggleSequence:(CCSprite *)spider
{
    CCScaleTo * scaleUp = [CCScaleTo actionWithDuration:CCRANDOM_0_1()*2+1 scale:1.05f];//精灵放大
    CCEaseBackInOut * easeUp = [CCEaseBackInOut actionWithAction:scaleUp];
    CCScaleTo * scaleDown = [CCScaleTo actionWithDuration:CCRANDOM_0_1()*2+1 scale:0.95f];//精灵缩小
    CCEaseBackInOut * easeDown = [CCEaseBackInOut actionWithAction:scaleDown];
    CCSequence * scaleSequence = [CCSequence actions:easeUp,easeDown, nil];
    CCRepeatForever * repeatScale = [CCRepeatForever actionWithAction:scaleSequence];
    [spider runAction:repeatScale];
}
-(void)showGameOver
{
    [self setScreenSaverEnable:YES];
    CCNode * node;
    CCARRAY_FOREACH([self children], node)// 正向遍历
    {
		[node stopAllActions];
	}
    CCSprite * spider;
    CCARRAY_FOREACH(spiderArray, spider)
    {
        [self runSpiderWiggleSequence:spider];
    }
    self.isAccelerometerEnabled = NO;
    self.isTouchEnabled = YES;
    [self unscheduleAllSelectors];//可以解除全部Schduler
    
    CGSize screenSize = Size;
    CCLabelTTF * gameOver;
    if (numSpiderMoved == 0) {
        gameOver = [CCLabelTTF labelWithString:@"Start" fontName:@"Marker Felt" fontSize:60];
    }else {
        gameOver = [CCLabelTTF labelWithString:@"Game Over" fontName:@"Marker Felt" fontSize:60];
    }
    gameOver.position = CGPointMake(screenSize.width/2, screenSize.height/3);
    [self addChild:gameOver z:100 tag:100];
    
    
    
    //颜色
    CCTintTo * tint1 = [CCTintTo actionWithDuration:2 red:255 green:0 blue:0];
    CCTintTo * tint2 = [CCTintTo actionWithDuration:2 red:255 green:255 blue:0];
    CCTintTo * tint3 = [CCTintTo actionWithDuration:2 red:0 green:255 blue:0];
    CCTintTo * tint4 = [CCTintTo actionWithDuration:2 red:0 green:255 blue:255];
    CCTintTo * tint5 = [CCTintTo actionWithDuration:2 red:0 green:0 blue:255];
    CCTintTo * tint6 = [CCTintTo actionWithDuration:2 red:255 green:0 blue:255];
    CCSequence * titnSequence = [CCSequence actions:tint1,tint2,tint3,tint4,tint5,tint6, nil];//主要作用就是线序排列若干个动作,然后按先后次序逐个执行
    CCRepeatForever * repeatTint = [CCRepeatForever actionWithAction:titnSequence];//从 Action 类直接派生的,因此无法参于序列和同步;自身也无法反向执行。该类的作用就是无限期执行某个动作或动作序列,直到被停止
    [gameOver runAction:repeatTint];
    //角度
    CCRotateTo * totate1 = [CCRotateTo actionWithDuration:2 angle:3];//旋转到   duration 是时间  angle 旋转得角度
    CCEaseBounceInOut * bounce1 = [CCEaseBounceInOut actionWithAction:totate1];//修饰前的动作运行前向后，运行结束后回弹，注意，这里回弹是超过设定的移动距离再弹回
    CCRotateTo * totate2 = [CCRotateTo actionWithDuration:2 angle:-3];//旋转到
    CCEaseBounceInOut * bounce2 = [CCEaseBounceInOut actionWithAction:totate2];
    CCSequence * rotateSequence = [CCSequence actions:bounce1,bounce2, nil];
    CCRepeatForever * repeatBounce = [CCRepeatForever actionWithAction:rotateSequence];
    [gameOver runAction:repeatBounce];
    
    //位置 弹跳
    CCJumpBy * jump = [CCJumpBy actionWithDuration:3 position:CGPointZero height:screenSize.height/3 jumps:1];//sprite 在3秒钟内，不偏移跳1次，左右距离是0，跳跃高度是screenSize.height/3。 
    CCRepeatForever * repeatJump = [CCRepeatForever actionWithAction:jump];
    [gameOver runAction:repeatJump];
    
    //touch label
    CCLabelTTF * touchLabel = [CCLabelTTF labelWithString:@"点击开始" fontName:@"Arial" fontSize:20];
    touchLabel.position = CGPointMake(screenSize.width/2, screenSize.height/4);
    [self addChild:touchLabel z:100 tag:101];
    
    CCBlink * blink = [CCBlink actionWithDuration:10 blinks:20];
    CCRepeatForever * repeatBlink = [CCRepeatForever actionWithAction:blink];
    [touchLabel runAction:repeatBlink];
}
-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self resetGame];
}
-(id)init
{
    if (self = [super init]) {
        self.isAccelerometerEnabled = YES;//加速计
        player = [CCSprite spriteWithFile:@"alien.png"];
        [self addChild:player z:0 tag:1];
        
        CGSize screenSize = Size;
        float  imageHeight = [player texture].contentSize.height;//精灵纹理的内容尺寸
        player.position = CGPointMake(screenSize.width/2, imageHeight/2);
        [self scheduleUpdate];
        [self initSpriders];
        
        CCLabelTTF * timeLabel = [CCLabelTTF labelWithString:@"时间" fontName:@"Arial" fontSize:24];
        timeLabel.position = ccp(60,screenSize.height-20);
        [self addChild:timeLabel z:-1];
        
        CCLabelTTF * numberLabel = [CCLabelTTF labelWithString:@"个数" fontName:@"Arial" fontSize:24];
        numberLabel.position = ccp(screenSize.width-60,screenSize.height-20);
        [self addChild:numberLabel z:-1];
        
        
        //时间
        scoreLabel = [CCLabelBMFont labelWithString:@"0" fntFile:@"bitmapfont.fnt"];
        scoreLabel.position = CGPointMake(60,screenSize.height-32-32);
//        scoreLabel.anchorPoint = CGPointMake(0.5f, 1.0f);//贴图对象 相对于节点背景对象 的偏移；默认情况下 anchorPoint 为（ 0.5,0.5 ），即贴图对象 的中心位置对应着节点背景对象 的左下角；而当 anchorPoint 为（0,0 ），即贴图对象 的左下角对应着节点背景对象 的左下角
        [self addChild:scoreLabel z:-1];
        
        //掉落的个数
        numLabel = [CCLabelBMFont labelWithString:@"0" fntFile:@"bitmapfont.fnt"];
        numLabel.position = CGPointMake(screenSize.width-60,screenSize.height-32-32);
        [self addChild:numLabel z:-1];
        score = 0;
        
        //背景音乐
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"blues.mp3" loop:YES];
		//加载音效
		[[SimpleAudioEngine sharedEngine] preloadEffect:@"alien-sfx.caf"];
    
        srandom(time(NULL));
        [self showGameOver];
    }
    return self;
}
- (void)dealloc
{
    [spiderArray release],spiderArray = nil;
    player = nil;
    scoreLabel = nil;
    numLabel = nil;
    [super dealloc];
}
@end
