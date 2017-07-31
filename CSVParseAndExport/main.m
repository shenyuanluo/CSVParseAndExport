//
//  main.m
//  CSVParseAndExport
//
//  Created by http://blog.shenyuanluo.com/ on 2017/7/1.
//  Copyright © 2017年 https://github.com/shenyuanluo All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSVExport.h"
#import "CSVParse.h"
#import "FileManager.h"

void cvsParse()
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
            [[CSVParse shareCSVParse] parseCSVFileWithPath:filePath];
            NSLog(@"Parse is finish, result at path:%@", [[FileManager shareFileManager] exportFilePath]);
            
        }
        exit(1);
    }
}


void cvsExport()
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
            [[CSVExport shareCSVExport] parestFileWithPath:[pathArray objectAtIndex:i]
                                             currentColumn:i + 1
                                               columnCount:pathArray.count];
        }
        NSLog(@"Parse is finish, result at path:%@", [[FileManager shareFileManager] exportFilePath]);
    }
    exit(1);
}





int main(int argc, const char * argv[])
{
    @autoreleasepool
    {        
        int funChoice = 0;
        while (1)
        {
            NSLog(@"Please choice：【1】Parse CVS    【2】Parse Strings    【0】Exit");
            scanf("%d", &funChoice);
            if (1 == funChoice)
            {
                cvsParse();
            }
            else if (2 == funChoice)
            {
                cvsExport();
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
    return 0;
}



