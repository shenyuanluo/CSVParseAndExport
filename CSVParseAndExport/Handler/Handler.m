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
        printf("Please choice：【1】Parse CVS    【2】Parse Strings    【0】Exit\r\n");
        fflush(stdout);
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
        printf("Pleae input 'CSV' file path !\r\n");
        fflush(stdout);
        scanf("%s", path);
        printf("Are you sure start parse it？ yes/no\r\n");
        fflush(stdout);
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
            printf("Parsing now, Please waitting...\r\n");
            fflush(stdout);
            [CSVParse shareCSVParse].delegate = self;
            [[CSVParse shareCSVParse] parseCSVFileWithPath:filePath];
            printf("Parsing  ：100.00%c\r\n", '%');
            fflush(stdout);
            printf("Parse is finish, result at path:%s\r\n", [[[FileManager shareFileManager] exportFilePath] cStringUsingEncoding:NSUTF8StringEncoding]);
            fflush(stdout);
            
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
        printf("Please input 'strings' file path or input 'start' to start parse !\r\n");
        fflush(stdout);
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
    
    printf("Are you sure start parse it？ yes/no\r\n");
    fflush(stdout);
    scanf("%s", choice);
    choiceStr = [[NSString alloc] initWithCString:choice
                                         encoding:NSUTF8StringEncoding];
    BOOL result = NSOrderedSame == [choiceStr compare:@"yes"
                                              options:NSCaseInsensitiveSearch | NSNumericSearch];
    if (YES == result)
    {
        printf("Parsing now, Please waitting...\r\n");
        fflush(stdout);
        for (NSInteger i = 0; i < pathArray.count; i++)
        {
            [CSVExport shareCSVExport].delegate = self;
            [[CSVExport shareCSVExport] parestFileWithPath:[pathArray objectAtIndex:i]
                                             currentColumn:i + 1
                                               columnCount:pathArray.count];
        }
        printf("Parsing  ：100.00%c\r\n", '%');
        fflush(stdout);
        printf("Parse is finish, result at path:%s\r\n", [[[FileManager shareFileManager] exportFilePath] cStringUsingEncoding:NSUTF8StringEncoding]);
        fflush(stdout);
    }
    exit(1);
}


- (void)animationWithProgress:(CGFloat)progress
{
    static unsigned int count = 0;
    count++;
    char strArray[40]={'\\', '\\', '\\', '\\', '\\', '\\', '\\', '\\', '\\', '\\',
                        '|', '|', '|', '|', '|', '|', '|', '|', '|', '|',
                        '/', '/', '/', '/', '/', '/', '/', '/', '/', '/',
                        '-', '-', '-', '-', '-', '-', '-', '-', '-', '-'};
    char rotateStr = strArray[count % 40];
    
    fflush(stdout);
    printf("Parsing %c：%0.2f%c\r", rotateStr, progress * 100,'%');
    fflush(stdout);
}


#pragma mark -- CSV parse delegate
- (void)csvParseProgress:(CGFloat)progress
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            printf("Upate progress is failure !\n");
            return ;
        }
        [strongSelf animationWithProgress:progress];
    });
}


- (void)csvExportProgress:(CGFloat)progress
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            printf("Upate progress is failure !\n");
            return ;
        }
        [strongSelf animationWithProgress:progress];
    });
}


@end
