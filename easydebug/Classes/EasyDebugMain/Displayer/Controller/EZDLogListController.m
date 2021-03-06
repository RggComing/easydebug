//
//  EZDDisplayController.m
//  HoldCoin
//
//  Created by Song on 2018/9/30.
//  Copyright © 2018年 Beijing Bai Cheng Media Technology Co.LTD. All rights reserved.
//

#import "EZDLogListController.h"
#import "EZDBaseLogInfoController.h"
#import "EZDFilterController.h"
#import "EZDOptionsController.h"

#import "EZDLogDisplayCell.h"
#import "EZDMessageHUD.h"

#import "EZDDefine.h"

static NSString * const kEZDDisplayControllerDisplayCellID = @"kEZDDisplayControllerDisplayCellID";

@interface EZDLogListController ()<UITableViewDelegate,UITableViewDataSource,EZDLoggerDelegate>

@property (strong,nonatomic) EZDLogger *logger;
@property (strong,nonatomic) UITableView *logView;

@end

@implementation EZDLogListController

- (instancetype)initWithLogger:(EZDLogger *)logger{
    if (self = [super init]) {
        self.logger = logger;
        [self.logger addDelegate:self];
    }
    return self;
}

- (void)loadView{
    [super loadView];
    self.logView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.logView.backgroundColor = [UIColor whiteColor];
    self.logView.delegate = self;
    self.logView.dataSource = self;
    [self.logView registerClass:[EZDLogDisplayCell class] forCellReuseIdentifier:kEZDDisplayControllerDisplayCellID];
    [self.view addSubview:self.logView];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSAssert(self.logger != nil, @"EZDDisplayController.logger can't be nil!");
    self.navigationItem.title = @"Logs";
    UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:(UIBarButtonItemStylePlain) target:self action:@selector(navClearClicked)];
    self.navigationItem.leftBarButtonItem = clearItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    UIBarButtonItem *filterItem = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:(UIBarButtonItemStylePlain) target:self action:@selector(navFilterClicked)];
    self.navigationItem.rightBarButtonItems = @[filterItem];
}

#pragma mark - response func

- (void)navFilterClicked{
    EZDFilterController *filterController = [[EZDFilterController alloc] initWithLogger:self.logger ConfirmCallback:^{
        [self.logView reloadData];
    }];
    [self.navigationController pushViewController:filterController animated:true];
}

- (void)navClearClicked{
    [self.logger clearLogs];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.logger.logModels.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 72;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    EZDLogDisplayCell *cell = [self.logView dequeueReusableCellWithIdentifier:kEZDDisplayControllerDisplayCellID forIndexPath:indexPath];
    cell.rowOfCell = indexPath.row;
    cell.logModel = self.logger.logModels[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    EZDBaseLogInfoController *logInfoVC = [[EZDBaseLogInfoController alloc] initWithLogModel:self.logger.logModels[indexPath.row]];
    [self.navigationController pushViewController:logInfoVC animated:true];
}

#pragma mark - EZDLoggerDelegate
- (void)logger:(EZDLogger *)logger logsDidChange:(NSArray<EZDLoggerModel *> *)chageLogs{
    [self.logView reloadData];
}

@end
