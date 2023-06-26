//
//  ViewController.m
//  Live2D
//
//  Created by Fancy on 2022/3/18.
//

#import "ViewController.h"
#import "L2DViewController.h"

@interface ViewController ()

@property (nonatomic, copy) NSArray <NSString *> *dataSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

#pragma mark - Table
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kCellIdentifer = @"UITableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifer];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifer];
    }
    cell.textLabel.text = self.dataSource[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *name = self.dataSource[indexPath.row]; 
    NSString *directory = [NSString stringWithFormat:@"Model/%@", name];
    
    L2DAppModel *model = [[L2DAppModel alloc] initWithDirectory:directory name:name];
    L2DViewController *l2dController = [[L2DViewController alloc] initWithModel:model];
    l2dController.title = name;
    [self.navigationController pushViewController:l2dController animated:YES];
}

#pragma mark - Get
- (NSArray<NSString *> *)dataSource {
    if (!_dataSource) {
        _dataSource = @[
                        @"miara_pro_t03",
                        @"miku_sample_t04",
                        @"Eileen",
                        @"Haru",
                        @"Hiyori", 
                        @"Natori",
                        @"Rice",
                        @"aidang_2",
                        @"aierdeliqi_4",
                        @"aimierbeierding_2",
                        @"biaoqiang",
                        @"chuixue_3",
                        @"lafei",
                        @"lingbo",
                        @"mingshi",
                        @"taiyuan_2",
                        @"tianlangxing_3",
                        @"tierbici_2",
                        @"xuefeng",
                        @"z23",
                        @"z46_2",
                        @"akeno",
                        @"RACOON01"
        ];
    }
    return _dataSource;
}



@end
