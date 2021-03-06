//
//  ShitiViewController.m
//  ex
//
//  Created by alfred sang on 12-8-2.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ShitiViewController.h"

#define SHITI_SEQ_CACHE_FILE_NAME @"shiti_result.plist"

@interface ShitiViewController ()

@end

@implementation ShitiViewController
@synthesize ui_bgPic;
@synthesize ui_btn_tNumber;
@synthesize ui_tName;
@synthesize ui_tPicAddr;
@synthesize ui_ttid;
@synthesize ui_left,ui_right;
@synthesize ui_config;
@synthesize ui_btn_shoucang;
@synthesize ui_btn_flip;



- (id)initWithPattern:(MyPatternModel)myPattern{
    if (self == [super init]) {
        _myPattern = myPattern;
        _myViewMode = view_model_question;
        
        _history = [[AnswerHistoryCache alloc] init];
        [_history restoreTo:SHITI_SEQ_CACHE_FILE_NAME];
        [self processWithPattern];
    }
    return self;
}

-(void)dealloc{
    [ui_btn_tNumber release];
    [ui_tName release];
    [ui_tPicAddr release];
    [ui_ttid release];
    [hintView release];
    [super dealloc];
}

- (void)processWithPattern{
    switch (_myPattern) {
        case PatternModel_Seq:
            [self p_seq];
            break;
        case PatternModel_Random:
            [self p_random];
            break;
        case PatternModel_Chapter:
            [self p_chater];
            break;
        default:
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    

    if (![[NSUserDefaults standardUserDefaults] integerForKey:USER_DEFAULT_FLIP_AUTO_TAG]) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:USER_DEFAULT_FLIP_AUTO_TAG];
    }
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:USER_DEFAULT_FLIP_AUTO_TAG] == 0) {
        //        filterLeftRotation |  filterHorizontalFlip
        [ui_btn_flip setImage:[UIImage imageNamed:@"filterLeftRotation"] forState:UIControlStateHighlighted];
    }
    if ([[NSUserDefaults standardUserDefaults] integerForKey:USER_DEFAULT_FLIP_AUTO_TAG] == 1) {
        //        filterLeftRotation |  filterHorizontalFlip
        [ui_btn_flip setImage:[UIImage imageNamed:@"filterHorizontalFlip"] forState:UIControlStateHighlighted];
    }
    
    
    _shitiView = [[[NSBundle mainBundle] loadNibNamed:@"ShitiViewController" owner:self options:nil] objectAtIndex:1];
    [self.view addSubview:_shitiView];
    
    ui_btn_closeAnswerPattern = [UIButton buttonWithType:UIButtonTypeCustom];
    [ui_btn_closeAnswerPattern setImage:[UIImage imageNamed:@"loading_cancel"] forState:UIControlStateNormal];
    [ui_btn_closeAnswerPattern setImage:[UIImage imageNamed:@"nil"] forState:UIControlStateHighlighted];

  
    [ui_btn_closeAnswerPattern addTarget:self action:@selector(whenClickCloseAnswerPatternBtn:) forControlEvents:UIControlEventTouchUpInside];
    
 
    
    // Do any additional setup after loading the view from its nib.
    _isAnswered = FALSE;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(10, 150, 300, 245) style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView setBackgroundColor:[UIColor clearColor]];
    [_shitiView addSubview:_tableView];
    [_tableView setScrollEnabled:NO];
    //初始化表格数据
    items = [[NSMutableArray alloc] init];
    
    
    
    ui_btn_tNumber.backgroundColor = [UIColor greenColor];
    
    //width=314,否则第一次下拉，会比背景宽6像素
    hintView = [[NoteInfoView  alloc] initWithFrame:CGRectMake(0, -120, 314, 120)];
    [self.view addSubview:hintView];
    
    _currentTid = 1;
    [self getShiti];
    
    _dsKeyArray = [NSMutableArray array];
    //    [CXDataService sharedInstance]
    [self addGestureRecognizer];
    
    [self tNumberAnimation:1 andNumber:_currentTid];
    
    //    ShitiAnswerTableViewControllerViewController *s = [[ShitiAnswerTableViewControllerViewController alloc] initView:nil];
    //    s.view.frame = CGRectMake(10, 180, 300, 195);
    //
    
    [hintView addSubview:ui_btn_closeAnswerPattern];
    
    
    //    [self.view addSubview:s.view];
    [self.view bringSubviewToFront:self.ui_left];
    [self.view bringSubviewToFront:self.ui_right];
    self.view.frame = CGRectMake(0, 0, 320, 480);
    self.view.bounds = CGRectMake(0, 0, 320, 480);
    
    
    int a = [[_history getCache] count];
    
    if (a >0) {
        NSString *msg = [NSString  stringWithFormat:@"您上次答题未完成，第%d题,是否继续?如果点击【从头开始】按钮，您的答题记录信息将清空。",a];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"消息提示" message:msg delegate:self cancelButtonTitle:@"从头开始" otherButtonTitles:@"继续", nil] autorelease];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==1) {
        int a = [[_history getCache] count];
        [self jumpTo:[NSNumber numberWithInt:a]];
        [ui_btn_tNumber setTitle:[NSString stringWithFormat:@"%d",a] forState:UIControlStateNormal];
    }
    if (buttonIndex == 0) {
        [_history clean];
        [self jumpTo:[NSNumber numberWithInt:1]];
    }
}

- (void)alertViewCancel:(UIAlertView *)alertView{

}
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
    
    if (!_isAnswered) {
        for (int i = 0; i<[items count]; i++) {
            NSIndexPath *myIndexP = [NSIndexPath indexPathForRow:i inSection:0];
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:myIndexP];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        int mid = [_shiti.tanswer intValue] ;
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (mid == (indexPath.row+1) ) {
            
            
            //        [cell setBackgroundColor:[UIColor greenColor]];
            [cell.imageView setImage:[UIImage imageNamed:@"icon_selected"]];
            [cell setHighlighted:YES animated:YES];
        }else {
            //错题记录
            [[CXDataService sharedInstance]  cuoti_add:_currentTid andTid:[_shiti.zid intValue] andTName:_shiti.tName];
            //        [cell setBackgroundColor:[UIColor grayColor]];
            [cell.imageView setImage:[UIImage imageNamed:@"photo_icon_cancle"]];
        }
            
        //cell.textLabel.textColor  = [UIColor orangeColor];
        ui_btn_tNumber.backgroundColor = [UIColor orangeColor];
        
        [_history add:[NSString stringWithFormat:@"%d",_currentTid] andAnswer:[NSString stringWithFormat:@"%@-%d",_shiti.tanswer,(indexPath.row+1)]];
        
        
        
        
    }
    
    if (![[NSUserDefaults standardUserDefaults] integerForKey:USER_DEFAULT_ANSWER_MULTI_SHOW]) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:USER_DEFAULT_ANSWER_MULTI_SHOW];
    }
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:USER_DEFAULT_ANSWER_MULTI_SHOW] == 0){
        _isAnswered = YES;
    }
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:USER_DEFAULT_FLIP_AUTO_TAG]==1) {
        [self performSelector:@selector(handleSwipeFromLeft:) withObject:nil afterDelay:0.5];
    }

}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return [items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    _isAnswered = NO;

    UITableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    //    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    //    [cell.accessoryView addSubview:[]]
    [cell.textLabel setFont:[UIFont systemFontOfSize:12]];

    cell.textLabel.numberOfLines = 3;
    
    [cell.imageView setImage:nil];
    NSLog(@"row = %d",indexPath.row);
    
    if (items) {
        cell.textLabel.text = [items  objectAtIndex:indexPath.row];
        [cell.textLabel setBackgroundColor:[UIColor clearColor]];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    [cell setBackgroundColor:[UIColor clearColor]];
    
    
    int rightAnwer = 0;
    int yourAnwer = 0;
    
    //判断是否答过该题
    if ([_history ifTidExist:_currentTid]) {
        NSString *ckey = [NSString stringWithFormat:@"%d",_currentTid];
        NSArray *a = [[[_history getCache] objectForKey:ckey] componentsSeparatedByString:@"-"];
        
        rightAnwer = [[a objectAtIndex:0] intValue];
        yourAnwer = [[a objectAtIndex:1] intValue];
        
        if (indexPath.row == yourAnwer-1) {
            int mid = [_shiti.tanswer intValue] ;
            if (mid == (indexPath.row) ) {
                [cell.imageView setImage:[UIImage imageNamed:@"icon_selected"]];
                [cell setHighlighted:YES animated:YES];
            }else {
                //        [cell setBackgroundColor:[UIColor grayColor]];
                [cell.imageView setImage:[UIImage imageNamed:@"photo_icon_cancle"]];
            }
            //答过的题颜色是橙色
            //cell.textLabel.textColor  = [UIColor orangeColor];
        }
        
    }
    else{
        //未答过的题颜色是黑色
        //cell.textLabel.textColor  = [UIColor blackColor];
    }
    return cell;
    
}

#pragma mark - swipe事件
/**
 * 增加左右swipe事件
 */
- (void)addGestureRecognizer{
    UISwipeGestureRecognizer *recognizer;
    recognizer = [[UISwipeGestureRecognizer alloc] init];
    [recognizer addTarget:self action:@selector(handleSwipeFromLeft:)];
    [recognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    [[self view] addGestureRecognizer:recognizer];
    [recognizer release];
    
    recognizer = [[UISwipeGestureRecognizer alloc] init];
    [recognizer addTarget:self action:@selector(handleSwipeFromRight:)];
    [recognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [[self view] addGestureRecognizer:recognizer];
    [recognizer release];
    
    recognizer = [[UISwipeGestureRecognizer alloc] init];
    [recognizer addTarget:self action:@selector(handleSwipeFromUp:)];
    [recognizer setDirection:UISwipeGestureRecognizerDirectionUp];
    [[self view] addGestureRecognizer:recognizer];
    [recognizer release];
    
    recognizer = [[UISwipeGestureRecognizer alloc] init];
    [recognizer addTarget:self action:@selector(handleSwipeFromDown:)];
    [recognizer setDirection:UISwipeGestureRecognizerDirectionDown];
    [[self view] addGestureRecognizer:recognizer];
    [recognizer release];
    
//    UITapGestureRecognizer *tg = [[UITapGestureRecognizer alloc] init];
////    [tg addTarget:self action:@selector(tap:)];
//    tg.numberOfTapsRequired=1;
//    tg.numberOfTouchesRequired =1;
//    [[self ui_tName] addGestureRecognizer:tg];
//    [tg release];
    
}

-(void)tap:(UITapGestureRecognizer *)g{
    c++;
    if (c%2 ==0) {
        [UIView animateWithDuration:0.4 delay:0.2 options:UIViewAnimationCurveEaseInOut animations:^{
            CGRect f = [self.view viewWithTag:10001].frame;
            f.origin.y-=40;
            [self.view viewWithTag:10001].frame = f;
            
            f = [self.view viewWithTag:10002].frame;
            f.origin.y-=40;
            [self.view viewWithTag:10002].frame = f;
            
            
            f = [self.view viewWithTag:10003].frame;
            f.origin.y-=40;
            [self.view viewWithTag:10003].frame = f;
            
            f = [self.view viewWithTag:10004].frame;
            f.origin.y-=40;
            [self.view viewWithTag:10004].frame = f;
            
            f = [self.view viewWithTag:10005].frame;
            f.origin.y-=40;
            [self.view viewWithTag:10005].frame = f;
            
        } completion:^(BOOL finished) {
            
        }];
        
    }else{
        
        CGRect f = [self.view viewWithTag:10001].frame;
        f.origin.y+=40;
        [self.view viewWithTag:10001].frame = f;
        
        f = [self.view viewWithTag:10002].frame;
        f.origin.y+=40;
        [self.view viewWithTag:10002].frame = f;
        
        
        f = [self.view viewWithTag:10003].frame;
        f.origin.y+=40;
        [self.view viewWithTag:10003].frame = f;
        
        f = [self.view viewWithTag:10004].frame;
        f.origin.y+=40;
        [self.view viewWithTag:10004].frame = f;
        
        f = [self.view viewWithTag:10005].frame;
        f.origin.y+=40;
        [self.view viewWithTag:10005].frame = f;
    }
    
}

/**
 * 增加上swipe事件
 */
- (void)handleSwipeFromUp:(UISwipeGestureRecognizer *)recognize{
    [self dismissNoteView];
}
/**
 * 增加下swipe事件
 */
- (void)handleSwipeFromDown:(UISwipeGestureRecognizer *)recognize{
    [self showNoteView];
}
/**
 * 增加左swipe事件
 */
- (void)handleSwipeFromRight:(UISwipeGestureRecognizer *)recognize{
    [self left:nil];
}
/**
 * 增加右swipe事件
 */
- (void)handleSwipeFromLeft:(UISwipeGestureRecognizer *)recognize{
    [self right:nil];
}

-(IBAction)left:(id)sender{
    if (_currentTid > 1) {
        _currentTid--;
        
        [self getShiti];
    }
    [self addAnimationWithDirection:0];
    [self tNumberAnimation:1 andNumber:_currentTid];
}

-(IBAction)right:(id)sender{
    _currentTid++;
    
    [self getShiti];
    
    [self addAnimationWithDirection:1];
    [self tNumberAnimation:0 andNumber:_currentTid];
    
}

- (NSString *)getStringWithABCD:(NSString *)str withIndex:(int)i{
    NSString *title;
    
    switch (i) {
        case 1:
            title = [NSString stringWithFormat:@"  A : %@",str];
            break;
            
        case 2:
            title = [NSString stringWithFormat:@"  B : %@",str];
            break;
            
        case 3:
            title = [NSString stringWithFormat:@"  C : %@",str];
            break;
            
        case 4:
            title = [NSString stringWithFormat:@"  D : %@",str];
            break;
            
        case 5:
            title = [NSString stringWithFormat:@"  E : %@",str];
            break;
            
        default:
            break;
    }
    return title;
}

- (void)hideOrShow:(NSString *)str withBtn:(UIButton *)btn{
    if (str == nil || [str isEqualToString:@""]) {
        btn.hidden = YES;
        return;
    }
    btn.hidden = NO;
    NSString *title;
    
    switch (btn.tag) {
        case 1:
            title = [NSString stringWithFormat:@"  A:%@",str];
            break;
            
        case 2:
            title = [NSString stringWithFormat:@"  B:%@",str];
            break;
            
        case 3:
            title = [NSString stringWithFormat:@"  C:%@",str];
            break;
            
        case 4:
            title = [NSString stringWithFormat:@"  D:%@",str];
            break;
            
        case 5:
            title = [NSString stringWithFormat:@"  E:%@",str];
            break;
            
        default:
            break;
    }
    
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateHighlighted];
    [btn setTitle:title forState:UIControlStateSelected];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


-(IBAction)back:(id)sender{
//    [[_history getCache] writeToFile:[self dataFilePath] atomically:YES];
    
    [_history saveTo:SHITI_SEQ_CACHE_FILE_NAME];
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self dismissModalViewControllerAnimated:YES];
}


-(IBAction)whenClickShoucangBtn:(UIButton *)sender{
    BOOL t= [[CXDataService sharedInstance]  shoucang_add:_currentTid andTid:[_shiti.zid intValue] andTName:_shiti.tName];
    
    if (t) {
        [ui_btn_shoucang setImage:[UIImage imageNamed:@"artilce_icon_collect_fav"] forState:UIControlStateNormal];
    }else{
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"消息提示" message:@"收藏失败,之前已收藏" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] autorelease];
        [alert show];
    }
}

/**
 * 当点击翻页控制按钮按钮时，触发的事件
 */
-(IBAction)whenClickFilpControlBtn:(UIButton *)sender{
    if (![[NSUserDefaults standardUserDefaults] integerForKey:USER_DEFAULT_FLIP_AUTO_TAG]) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:USER_DEFAULT_FLIP_AUTO_TAG];
    }
    
    int a = [[NSUserDefaults standardUserDefaults] integerForKey:USER_DEFAULT_FLIP_AUTO_TAG];
    if (a==1) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:USER_DEFAULT_FLIP_AUTO_TAG];
    }else{
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:USER_DEFAULT_FLIP_AUTO_TAG];
    }
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:USER_DEFAULT_FLIP_AUTO_TAG] == 1) {
        //        filterLeftRotation |  filterHorizontalFlip
        [ui_btn_flip setImage:[UIImage imageNamed:@"filterLeftRotation"] forState:UIControlStateHighlighted];
        [ui_btn_flip setImage:[UIImage imageNamed:@"filterLeftRotation"] forState:UIControlStateNormal];
        [ui_btn_flip setImage:[UIImage imageNamed:@"filterLeftRotation"] forState:UIControlStateSelected];

    }else{
          [ui_btn_flip setImage:[UIImage imageNamed:@"filterHorizontalFlip"] forState:UIControlStateHighlighted];
          [ui_btn_flip setImage:[UIImage imageNamed:@"filterHorizontalFlip"] forState:UIControlStateNormal];
        [ui_btn_flip setImage:[UIImage imageNamed:@"filterHorizontalFlip"] forState:UIControlStateSelected];
    }
 
    ui_btn_flip.selected = YES;
    ui_btn_flip.highlighted = YES;
}



-(IBAction)viewAnswerBtn:(UIButton *)btn{
    int mid = [_shiti.tanswer intValue]-1;
    
    [self setAnswerStatus:mid];
    
    _isAnswered = YES;
    [self showNoteView];
}

/**
 * 根据答案-设置表格-状态
 */
-(void)setAnswerStatus:(int)tanserValue{
    NSIndexPath *myIndexP = [NSIndexPath indexPathForRow:tanserValue inSection:0];
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:myIndexP];
    [cell.imageView setImage:[UIImage imageNamed:@"icon_selected"]];
    [cell setHighlighted:YES animated:YES];
    
    
    NSString *tip = [NSString stringWithFormat:@"%@",_shiti.tdesc];
    
    if ( (tip == nil) | [tip isEqualToString:@""]) {
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissNoteView) object:nil];
    [hintView setNoteInfo:@"真题解读" content:tip iconName:@"weibo_location_selected"];
}

-(IBAction)showSettingsView:(id)sender{
    ListOtherViewController *setView = [[ListOtherViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:setView];
    navController.navigationBarHidden = YES;
    [self presentModalViewController:navController animated:YES];
    [navController release];
}
/**
 * 题号 翻转动画
 */
-(void)tNumberAnimation:(int)dirction andNumber:(int)num{
    //判断是否答过该题
    if ([_history ifTidExist:_currentTid]) {
        self.ui_btn_tNumber.backgroundColor = [UIColor orangeColor];
    }else{
        self.ui_btn_tNumber.backgroundColor = [UIColor greenColor];
    }
    
    CATransition *animation = [CATransition animation];
    animation.delegate = self;
    animation.duration = kDuration;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    animation.type = @"oglFlip";
    
    if (dirction ==0) {
        animation.subtype = kCATransitionFromLeft;
    }else {
        animation.subtype = kCATransitionFromRight;
    }
    
    NSString *string = [NSString stringWithFormat:@"%d",num];
    
	CGFloat stringWidth = [string sizeWithFont:self.ui_btn_tNumber.titleLabel.font].width+14;
	
    
    //	self.ui_btn_tNumber.bounds = CGRectMake(0, 0, hudWidth, 100);
    
    CGRect f = self.ui_btn_tNumber.frame;
    f.size.width = stringWidth;
    f.size.height = stringWidth;
    self.ui_btn_tNumber.frame = f;
    
    
    CALayer * layer = [ui_btn_tNumber layer];
    
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:(stringWidth)/2];
    //    [layer setBorderWidth:1];
    //    [layer setBorderColor: [[UIColor greenColor] CGColor]];
    
    
    [self.ui_btn_tNumber setTitle:string  forState:UIControlStateNormal];
    
    [[self.ui_btn_tNumber layer] addAnimation:animation forKey:@"animation_btn"];
}
#pragma mark - about NoteView
- (void)showNoteView{
    //如果下拉，答题模式为看答案模式
    _myViewMode = view_model_answer;
    
    [UIView animateWithDuration:1 delay:0.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect f = self.view.frame;
        f.origin.y = 120;
        _shitiView.frame = f;
        
        f = hintView.frame;
        f.size.width = 314;
        f.origin.y = 0;
        hintView.frame = f;
    } completion:^(BOOL finished) {
        
        //[self performSelector:@selector(dismissNoteView) withObject:nil afterDelay:10];
    }];
    CGRect g =  self.ui_bgPic.frame;
    g.origin.y = -120;
    g.size.height=480.0f+120.0f;
    self.ui_bgPic.frame = g;

    [self showCloseAnswerPattern];
}
//ui_btn_closeAnswerPattern
-(void)showCloseAnswerPattern{
//    self.ui_btn_closeAnswerPattern.backgroundColor = [UIColor redColor];
//    [self.view addSubview:ui_btn_closeAnswerPattern];
    ui_btn_closeAnswerPattern.frame = CGRectMake(270, 0, 50, 44);
    //ui_btn_closeAnswerPattern.bounds = CGRectMake(260, -120, 50, 44);
    [hintView bringSubviewToFront:ui_btn_closeAnswerPattern];
    
//    ui_btn_closeAnswerPattern.enabled=YES;
//
//    [ui_btn_closeAnswerPattern addTarget:self action:@selector(dismissNoteView) forControlEvents:UIControlEventTouchUpInside];
}

-(IBAction)whenClickCloseAnswerPatternBtn:(id)sender{
    [self dismissNoteView];
}

- (void)dismissNoteView{
    //如果下拉，答题模式为问题模式
    _myViewMode = view_model_question;
    
    [UIView animateWithDuration:1 delay:0.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect g =  self.ui_bgPic.frame;
        g.origin.y = 0;
        g.size.height=480.0f;
        self.ui_bgPic.frame = g;
        CGRect f = self.view.frame;
        f.origin.y = 0;
        _shitiView.frame = f;
        
        f = hintView.frame;
        f.size.width = 314;
        f.origin.y = -120;
        hintView.frame = f;
        
    } completion:^(BOOL finished) {
       
    }];
    
    
}


#pragma mark - public methods implemetions

-(void)jumpTo:(NSNumber *)tPageNumber{
    [self addGestureRecognizer];
    _currentTid = [tPageNumber intValue];
    [self getShiti];
}

#pragma mark Core Animation
#pragma mark Core Animation
- (void)addAnimationWithDirection:(int)dtag{
    CATransition *animation = [CATransition animation];
    animation.delegate = self;
    animation.duration = kDuration;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    
    
    //    if (![[NSUserDefaults standardUserDefaults] integerForKey:USER_DEFAULT_FLIP_ANIMATION_TAG]) {
    //        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:USER_DEFAULT_FLIP_ANIMATION_TAG];
    //    }
    //
    int aa = [[NSUserDefaults standardUserDefaults] integerForKey:USER_DEFAULT_FLIP_ANIMATION_TAG];
    
    if (aa||aa==0) {
        return;
    }
    
    switch (aa) {
        case 101:
            animation.type = kCATransitionFade;
            break;
        case 102:
            animation.type = kCATransitionPush;
            break;
        case 103:
            animation.type = kCATransitionReveal;
            break;
        case 104:
            animation.type = kCATransitionMoveIn;
            break;
        case 201:
            animation.type = @"cube";
            break;
        case 202:
            animation.type = @"suckEffect";
            break;
        case 203:
            animation.type = @"oglFlip";
            break;
        case 204:
            animation.type = @"rippleEffect";
            break;
        case 205:
            animation.type = @"pageCurl";
            break;
        case 206:
            animation.type = @"pageUnCurl";
            break;
        case 207:
            animation.type = @"cameraIrisHollowOpen";
            break;
        case 208:
            animation.type = @"cameraIrisHollowClose";
            break;
        default:
            break;
    }
    
    switch (dtag) {
        case 0:
            animation.subtype = kCATransitionFromLeft;
            break;
        case 1:
            animation.subtype = kCATransitionFromRight;
            break;
            
        default:
            break;
    }
    
    [[self.view layer] addAnimation:animation forKey:@"animation"];
}


#pragma mark UIView动画
- (IBAction)buttonPressed2:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSInteger tag = button.tag;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:kDuration];
    switch (tag) {
        case 105:
            [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self.view cache:YES];
            break;
        case 106:
            [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self.view cache:YES];
            break;
        case 107:
            [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.view cache:YES];
            break;
        case 108:
            [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];
            break;
        default:
            break;
    }
    
    //    NSUInteger green = [[self.view subviews] indexOfObject:self.greenView];
    //    NSUInteger blue = [[self.view subviews] indexOfObject:self.blueView];
    //    [self.view exchangeSubviewAtIndex:green withSubviewAtIndex:blue];
    //
    [UIView setAnimationDelegate:self];
    // 动画完毕后调用某个方法
    //[UIView setAnimationDidStopSelector:@selector(animationFinished:)];
    [UIView commitAnimations];
}


#pragma mark - pattern callback methods implemetions

- (void)p_seq{
    _history.max = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SHITI_COUNT_NUMBER"] intValue];
    _currentTid = 1;
    //_dsId = _currentTid;
}

- (void)p_random{
    
    _history.max = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SHITI_COUNT_NUMBER"] intValue];
    _dsKeyArray = [[RandomUtils getRandomCollection:0 to:1000 count:1000] retain];
    NSLog(@"when in p_random functoin,_dsKeyArray = %@C",_dsKeyArray);
    //_dsId = [[_dsKeyArray objectAtIndex:_currentTid] intValue];
}

- (void)p_chater{
    
}

/**
 *随机一百道题
 *时间45分钟
 *90分+通过
 *一个题目一分
 */
//- (void)p_exam{
//    _dsKeyArray = [[RandomUtils getRandomCollection:0 to:1000 count:100] retain];
//}

#pragma mark - shiti methods implemetions

- (void)getShiti{
    switch (_myPattern) {
        case PatternModel_Seq:
            _dsId = _currentTid;
            break;
        case PatternModel_Random:
            _dsKeyArray = [[RandomUtils getRandomCollection:0 to:1000 count:100] retain];
            _dsId = [[_dsKeyArray objectAtIndex:_currentTid] intValue];
            break;
        default:
            break;
    }
    _shiti = [[[CXDataService sharedInstance]  shiti_find_by_id:_dsId] retain];
    
    NSString *tip = [NSString stringWithFormat:@"%@",_shiti.tdesc];
    if ( (tip == nil) | [tip isEqualToString:@""]) {
        
    }else {
        
        [hintView setNoteInfo:@"真题解读" content:tip iconName:@"weibo_location_selected"];
        
        
        
    }
    
    [self setShiti:_shiti];
    NSLog(@"%@",_shiti.tName);
    NSLog(@"%@",_shiti.tanswer);
    
    if (_myViewMode == view_model_answer) {
        [self setAnswerStatus:_shiti.tanswer.intValue-1];
    }
}
#define TI_Y      28
#define TI_HEIGHT 106
- (void)setShiti:(DM_Shiti *)shiti{
    if (_currentTid == 0) {
        SummaryViewController *s = [SummaryViewController new];
        [self.view addSubview:s.view];
        //[s release];
        return;
    }
  
    
    [ui_btn_shoucang setImage:[UIImage imageNamed:@"artilce_icon_collect"] forState:UIControlStateNormal];
    //
    //    self.ui_chapter.text = shiti.chapter;
    self.ui_tName.text = shiti.tName;

    self.ui_ttid.text = shiti.tid;
    
    //    [self.ui_tName ]
    if (shiti.tPicAddress == nil || [shiti.tPicAddress  isEqualToString:@"" ]) {
        self.ui_tPicAddr.hidden = YES;
        self.ui_tName.frame = CGRectMake(10, TI_Y, 300,TI_HEIGHT);
    }else {
        self.ui_tName.frame = CGRectMake(10, TI_Y, 200, TI_HEIGHT);
        self.ui_tPicAddr.hidden = NO;
        [self.ui_tPicAddr setImage:[UIImage imageNamed:shiti.tPicAddress]];
    }
    
    [items release];
    
    items = [[NSMutableArray alloc] init];
    
    
    if (_shiti.a1.length>0) {
        [items addObject:[self getStringWithABCD:_shiti.a1 withIndex:1]];
    }
    
    if (_shiti.a2.length>0) {
        [items addObject:[self getStringWithABCD:_shiti.a2 withIndex:2]];    }
    
    if (_shiti.a3.length>0) {
        [items addObject:[self getStringWithABCD:_shiti.a3 withIndex:3]];
    }
    if (_shiti.a4.length>0) {
        [items addObject:[self getStringWithABCD:_shiti.a4 withIndex:4]];
    }
    if (_shiti.a5.length>0) {
        [items addObject:[self getStringWithABCD:_shiti.a5 withIndex:5]];
    }
    
    [_tableView reloadData];
    
}

#pragma mark - noteinfodelegate

-(void)whenNoteInfoViewDismiss{
    [UIView animateWithDuration:1 animations:^{
        CGRect f = self.view.frame;
        f.origin.y = -120;
        self.view.frame = f;
    }];
}


@end
