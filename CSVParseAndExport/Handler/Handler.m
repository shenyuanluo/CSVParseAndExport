//
//  Handler.m
//  CSVParseAndExport
//
//  Created by shenyuanluo on 2017/8/5.
//  Copyright © 2017年 shenyuanluo. All rights reserved.
//

#import "Handler.h"
#import "FileManager.h"
#import <stdio.h>


@interface Handler ()   <
                            CSVParseDelegate,
                            CSVExportDelegate
                        >

@end


@implementation Handler


- (void)handel
{
    int funChoice = 0;
    while (1)
    {
        NSLog(@"Please choice：【1】Parse CVS    【2】Parse Strings    【0】Exit");
        scanf("%d", &funChoice);
        if (1 == funChoice)
        {
            [self cvsParse];
        }
        else if (2 == funChoice)
        {
            [self cvsExport];
        }
        else if (0 == funChoice)
        {
            exit(1);
        }
        else
        {
            continue;
        }
    }
}


- (void)cvsParse
{
    char path[512];
    char choice[128];
    NSString *filePath = nil;
    NSString *choiceStr = nil;
    while (1)
    {
        NSLog(@"Pleae input 'CSV' file path !");
        scanf("%s", path);
        NSLog(@"Are you sure start parse it？ yes/no");
        scanf("%s", choice);
        choiceStr = [[NSString alloc] initWithCString:choice
                                             encoding:NSUTF8StringEncoding];
        BOOL result = NSOrderedSame == [choiceStr compare:@"yes"
                                                  options:NSCaseInsensitiveSearch | NSNumericSearch];
        if (YES == result)
        {
            NSString *pathStr = [[NSString alloc] initWithCString:path
                                                         encoding:NSUTF8StringEncoding];
            filePath = [pathStr stringByExpandingTildeInPath];
            NSLog(@"Parsing now, Please waitting...");
            [CSVParse shareCSVParse].delegate = self;
            [[CSVParse shareCSVParse] parseCSVFileWithPath:filePath];
            NSLog(@"Parse is finish, result at path:%@", [[FileManager shareFileManager] exportFilePath]);
            
        }
        exit(1);
    }
}


- (void)cvsExport
{
    NSMutableArray <NSString *>*pathArray = [NSMutableArray arrayWithCapacity:0];
    
    char path[512];
    char choice[128];
    NSString *pathStr   = nil;
    NSString *filePath  = nil;
    NSString *choiceStr = nil;
    while (1)
    {
        NSLog(@"Please input 'strings' file path or input 'start' to start parse !");
        scanf("%s", path);
        pathStr = [[NSString alloc] initWithCString:path
                                           encoding:NSUTF8StringEncoding];
        BOOL result = NSOrderedSame == [pathStr compare:@"start"
                                                options:NSCaseInsensitiveSearch | NSNumericSearch];
        if (YES == result)
        {
            break;
        }
        filePath = [pathStr stringByExpandingTildeInPath];
        if (0 < filePath)
        {
            [pathArray addObject:filePath];
        }
    }
    
    NSLog(@"Are you sure start parse it？ yes/no");
    scanf("%s", choice);
    choiceStr = [[NSString alloc] initWithCString:choice
                                         encoding:NSUTF8StringEncoding];
    BOOL result = NSOrderedSame == [choiceStr compare:@"yes"
                                              options:NSCaseInsensitiveSearch | NSNumericSearch];
    if (YES == result)
    {
        NSLog(@"Parsing now, Please waitting...");
        for (NSInteger i = 0; i < pathArray.count; i++)
        {
            [CSVExport shareCSVExport].delegate = self;
            [[CSVExport shareCSVExport] parestFileWithPath:[pathArray objectAtIndex:i]
                                             currentColumn:i + 1
                                               columnCount:pathArray.count];
        }
        NSLog(@"Parse is finish, result at path:%@", [[FileManager shareFileManager] exportFilePath]);
    }
    exit(1);
}


#pragma mark -- CSV parse delegate
- (void)csvParseProgress:(CGFloat)progress
{
    fflush(stdout);
    printf("解析已完成：%0.2f%c\r", progress * 100,'%');
    fflush(stdout);
//    NSLog(@"解析已完成：%0.2f%c\r", progress * 100,'%');
}


- (void)csvExportProgress:(CGFloat)progress
{
    fflush(stdout);
    printf("解析已完成：%0.2f%c\r", progress * 100,'%');
    fflush(stdout);
    //    NSLog(@"解析已完成：%0.2f%c\r", progress * 100,'%');
}


@end
