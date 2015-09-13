//
//  SJViewController.m
//  SJBreakout
//
//  Created by Tatsuya Arai on 9/13/15.
//  Copyright (c) 2015 cutmail. All rights reserved.
//

#import "SJViewController.h"
#import "SJTitleScene.h"

@import SpriteKit;

@interface SJViewController ()

@end

@implementation SJViewController

- (void)loadView {
    SKView *skView = [[SKView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = skView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SKView *skView = (SKView *)self.view;
    skView.showsDrawCount = YES;
    skView.showsNodeCount = YES;
    skView.showsFPS = YES;
    
    SKScene *scene = [SJTitleScene sceneWithSize:self.view.bounds.size];
    [skView presentScene:scene];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
