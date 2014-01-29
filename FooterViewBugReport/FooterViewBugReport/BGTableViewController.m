//
// Created by Nick Snyder on 12/5/13.
// Copyright (c) 2013 LinkedIn. All rights reserved.
//


#import "BGTableViewController.h"


@implementation BGTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
  footer.backgroundColor = [UIColor blueColor];
  footer.text = @"table footer";

  self.tableView.tableFooterView = footer;
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
}

#pragma mark - UITableViewDelegate

// Comment out this method and the footer view is placed correctly.
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSLog(@"estimated height for row %i is 10", indexPath.row);
  return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSLog(@"actual height for row %i is 40", indexPath.row);
  return 40;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSLog(@"cell for row %i", indexPath.row);
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
  cell.textLabel.text = [NSString stringWithFormat:@"this is cell %i", indexPath.row];
  cell.backgroundColor = [UIColor redColor];
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 20;
}

@end
