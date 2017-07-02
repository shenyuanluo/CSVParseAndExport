//
//  CSVExport.m
//  CSVParseAndExport
//
//  Created by http://blog.shenyuanluo.com/ on 2017/7/1.
//  Copyright © 2017年 https://github.com/shenyuanluo All rights reserved.
//

#import "CSVExport.h"

@implementation CSVExport

+ (NSString *)exportFilePath
{
    return [self createWriteFilePath];
}


#pragma mark -- 创建 CSV 输出文件
+ (NSString *)createWriteFilePath
{
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory,
                                                             NSUserDomainMask,
                                                             YES);
    NSString *desktopPath      = [pathArray objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *writeFleDir      = [desktopPath stringByAppendingPathComponent:@"CSV_Export"];
    
    BOOL isDirectory = NO;
    NSError *error   = nil;
    if (NO == [fileManager fileExistsAtPath:writeFleDir
                                isDirectory:&isDirectory])  // 文件夹不存在
    {
        [fileManager createDirectoryAtPath:writeFleDir
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
        NSAssert(!error, @"Create 'CSV_Export' directory is failed !");
    }
    else
    {
        if (NO == isDirectory)  // 存在，但不是文件夹
        {
            [fileManager createDirectoryAtPath:writeFleDir
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&error];
            NSAssert(!error, @"Create 'CSV_Export' directory is failed !");
        }
        else    // 文件夹存在
        {
            //            NSLog(@"文件夹存在，无需重新创建！");
        }
    }
    NSString *writeFilePath = [writeFleDir stringByAppendingPathComponent:[NSString stringWithFormat:@"csv_export.csv"]];
    if (YES == [fileManager fileExistsAtPath:writeFilePath
                                 isDirectory:&isDirectory])
    {
        if (YES == isDirectory)
        {
            //            NSLog(@"创建 CSV 文件！");
            [fileManager createFileAtPath:writeFilePath
                                 contents:nil
                               attributes:nil];
        }
        else
        {
            //            NSLog(@"CSV 文件已存在，无需重新创建！");
        }
    }
    else
    {
        //        NSLog(@"创建 CSV 文件！");
        [fileManager createFileAtPath:writeFilePath
                             contents:nil
                           attributes:nil];
    }
    
    return writeFilePath;
}


+ (void)parestFileWithPath:(NSString *)filePath
               columnCount:(NSInteger)columnCount
{
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    NSString *writeFilePath = [self createWriteFilePath];
    NSArray <NSString *> *strArray = [fileContents componentsSeparatedByString:@"\n"];
    fileContents = nil;
    
    NSString *rowStr   = nil;
    NSString *firstStr = nil;
    NSString *lastStr  = nil;
    NSString *keyStr   = nil;
    NSString *valueStr = nil;
    NSMutableArray <NSString *> *keyValueArray = nil;
    for (int i = 0; i < strArray.count; i++)
    {
        @autoreleasepool
        {
            // 清空缓存
            rowStr   = nil;
            firstStr = nil;
            lastStr  = nil;
            keyStr   = nil;
            valueStr = nil;
            if (keyValueArray)
            {
                [keyValueArray removeAllObjects];
                keyValueArray = nil;
            }
            
            rowStr   = strArray[i];
            rowStr   = [rowStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];  // 去掉空格
            if (6 >= rowStr.length)                  // 长度不符合
            {
                continue;
            }
            firstStr = [rowStr substringToIndex:1];
            lastStr  = [rowStr substringWithRange:NSMakeRange(rowStr.length - 1, 1)];
            if (![rowStr containsString:@"="]    // 如果没有等号
                || ![firstStr isEqualToString:@"\""]             // 如果不是‘"’ 开始
                || ![lastStr isEqualToString:@";"])  // 如果不是‘;’ 结尾
            {
                continue;
            }
            
            keyValueArray = [NSMutableArray arrayWithArray:[rowStr componentsSeparatedByString:@"="]];
            if (0 >= keyValueArray.count || 2 < keyValueArray.count)    // 不符合 keh-value 语法
            {
                continue;
            }
            
            keyStr = [keyValueArray[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            valueStr = [keyValueArray[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (2 >= keyStr.length || 3 >= valueStr.length // keyStr: 【""】  ----  valueStr: 【"";】
                || ![@"\"" isEqualToString:[keyStr substringToIndex:1]]     // keyStr 【"】开头
                || ![@"\"" isEqualToString:[keyStr substringWithRange:NSMakeRange(keyStr.length - 1, 1)]] // keyStr 【"】结尾
                || ![@"\"" isEqualToString:[valueStr substringToIndex:1]]   // keyStr 【"】开头
                || ![@"\";" isEqualToString:[valueStr substringWithRange:NSMakeRange(valueStr.length - 2, 2)]])  // keyStr 【";】开头
            {
                continue;
            }
            keyStr = [keyStr substringWithRange:NSMakeRange(1, keyStr.length - 2)];
            valueStr = [valueStr substringWithRange:NSMakeRange(1, valueStr.length - 3)];
            if ([keyStr containsString:@","])
            {
                keyStr = [keyStr stringByReplacingOccurrencesOfString:@","      // 替换 ‘,’ 逗号
                                                           withString:@"`"];
                
            }
            if ([valueStr containsString:@","])
            {
                valueStr = [valueStr stringByReplacingOccurrencesOfString:@","  // 替换 ‘,’  逗号
                                                               withString:@"`"];
            }
            //            NSLog(@"【%d】 keyStr = %@, valueStr = %@", i, keyStr, valueStr);
            [self addKeyStr:keyStr
                   valueStr:valueStr
                   filePath:writeFilePath
                columnCount:columnCount];
        }
    }
    
    // 清空缓存
    writeFilePath = nil;
    strArray      = nil;
    rowStr        = nil;
    firstStr      = nil;
    lastStr       = nil;
    keyStr        = nil;
    valueStr      = nil;
    if (keyValueArray)
    {
        [keyValueArray removeAllObjects];
        keyValueArray = nil;
    }
}


+ (void)addKeyStr:(NSString *)dstKeyStr
         valueStr:(NSString *)dstValueStr
         filePath:(NSString *)filePath
      columnCount:(NSInteger)columnCount
{
    if (!dstKeyStr || 0 >= dstKeyStr.length
        || !dstValueStr || 0 >= dstValueStr.length
        || ! filePath || 0 >= filePath.length)
    {
        return ;
    }
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    BOOL isAddValueStr = NO;
    NSArray <NSString *> *strArray = [fileContents componentsSeparatedByString:@"\n"];
    
    NSString *rowStr      = nil;
    NSString *srcKeyStr   = nil;
    NSString *newRowStr   = nil;
    NSString *preRowsStr  = nil;
    NSString *nextRowsStr = nil;
    NSString *newFileStr  = nil;
    NSMutableArray <NSString *> *keyValuesArray = nil;
    for (NSInteger i = 0; i < strArray.count; i++)
    {
        // 清空缓存
        rowStr      = nil;
        srcKeyStr   = nil;
        newRowStr   = nil;
        preRowsStr  = nil;
        nextRowsStr = nil;
        newFileStr  = nil;
        if (keyValuesArray)
        {
            [keyValuesArray removeAllObjects];
            keyValuesArray = nil;
        }
        
        rowStr = strArray[i];
        rowStr = [rowStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];  // 去掉空格
        if (0 >= rowStr.length || ![rowStr containsString:@","])  // 不含 CSV 分割号 ‘,’
        {
            continue;
        }
        keyValuesArray = [NSMutableArray arrayWithArray:[rowStr componentsSeparatedByString:@","]];
        if (1 >= keyValuesArray.count )    // 不符合 keh-value 语法
        {
            continue;
        }
        srcKeyStr = [keyValuesArray[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (![dstKeyStr isEqualToString:srcKeyStr])  // keyStr 不存在
        {
            continue;
        }
        
        // 追加
        newRowStr = [self formatOldRowStr:rowStr
                                 valueStr:dstValueStr
                              columnCount:columnCount];
        preRowsStr = @"";
        for (NSInteger j = 0; j < i; j++)
        {
            preRowsStr = [NSString stringWithFormat:@"%@%@", preRowsStr, [self formatRowString:strArray[j]
                                                                                   columnCount:columnCount]];
        }
        preRowsStr = [NSString stringWithFormat:@"%@%@", preRowsStr, newRowStr];
        nextRowsStr = @"";
        for (NSInteger k = i + 1; k < strArray.count; k++)
        {
            nextRowsStr = [NSString stringWithFormat:@"%@%@", nextRowsStr, [self formatRowString:strArray[k]
                                                                                     columnCount:columnCount]];
        }
        newFileStr = [NSString stringWithFormat:@"%@%@", preRowsStr, nextRowsStr];
        [newFileStr writeToFile:filePath
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:nil];
        isAddValueStr = YES;
        break ;
    }
    if (NO == isAddValueStr)
    {
        // 新添加
        // 清空缓存
        newRowStr   = nil;
        newFileStr  = nil;
        
        NSString *emptyStr = @"";
        for (NSInteger i = 0; i < columnCount; i++)
        {
            emptyStr = [NSString stringWithFormat:@"%@,", emptyStr];
        }
        newRowStr = [NSString stringWithFormat:@"%@%@%@\n", dstKeyStr, emptyStr, dstValueStr];
        newFileStr = [NSString stringWithFormat:@"%@%@", fileContents, newRowStr];
        [newFileStr writeToFile:filePath
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:nil];
    }
    
    // 清空缓存
    rowStr      = nil;
    srcKeyStr   = nil;
    newRowStr   = nil;
    preRowsStr  = nil;
    nextRowsStr = nil;
    newFileStr  = nil;
    if (keyValuesArray)
    {
        [keyValuesArray removeAllObjects];
        keyValuesArray = nil;
    }
}


#pragma mark -- 根据列数格式化 newRowStr
+ (NSString *)formatOldRowStr:(NSString *)oldRowStr
                     valueStr:(NSString *)valueStr
                  columnCount:(NSInteger)columnCount
{
    if (!oldRowStr || !valueStr || 1 > columnCount)
    {
        return @"";
    }
    NSString *newRowStr = @"";
    NSArray *strArray = [oldRowStr componentsSeparatedByString:@","];
    if (columnCount == strArray.count)  // 刚好缺一列
    {
        newRowStr = [NSString stringWithFormat:@"%@,%@\n", oldRowStr, valueStr];
    }
    else  if (columnCount > strArray.count) // 空列数不足
    {
        for (NSInteger i = 0; i < columnCount - (strArray.count - 1) - 1; i++)
        {
            newRowStr = [NSString stringWithFormat:@"%@%@", oldRowStr, @","];
        }
        newRowStr = [NSString stringWithFormat:@"%@,%@\n", newRowStr, valueStr];
    }
    else    // 列数多余，需去除
    {
        for (NSInteger i = 0; i < columnCount; i++)
        {
            if (0 == i)
            {
                newRowStr = [NSString stringWithFormat:@"%@", strArray[i]];
            }
            else
            {
                newRowStr = [NSString stringWithFormat:@"%@,%@", newRowStr, strArray[i]];
            }
        }
        newRowStr = [NSString stringWithFormat:@"%@,%@\n", newRowStr, valueStr];
    }
    
    // 清空缓存
    strArray = nil;
    
    return newRowStr;
}


#pragma mark -- 根据列数格式化 rowStr
+ (NSString *)formatRowString:(NSString *)rowStr
                  columnCount:(NSInteger)columnCount
{
    if (!rowStr || 0 >= rowStr.length || 1 > columnCount)
    {
        return @"";
    }
    NSArray *strArray = [rowStr componentsSeparatedByString:@","];
    if (1 >= strArray.count)
    {
        return [NSString stringWithFormat:@"%@\n", rowStr];
    }
    if (columnCount >= strArray.count)
    {
        for (NSInteger i = 0; i < columnCount - (strArray.count - 1); i++)
        {
            rowStr = [NSString stringWithFormat:@"%@%@", rowStr, @","];
        }
    }
    // 清空缓存
    strArray = nil;
    
    return [NSString stringWithFormat:@"%@\n", rowStr];
}

@end
