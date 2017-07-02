//
//  CSVParse.m
//  CSVParseAndExport
//
//  Created by http://blog.shenyuanluo.com/ on 2017/7/1.
//  Copyright © 2017年 https://github.com/shenyuanluo All rights reserved.
//

#import "CSVParse.h"

#define DEPORT_DIR  @"Localizable_Export"   // 导出文件夹名称
#define FILE_BASE_NAME @"Localizable"       // 文件基本名字
#define FILE_SUFFIX @"strings"              // 导出文件类型



@implementation CSVParse


#pragma mark - 文件夹
#pragma mark -- 创建导出文件夹
+ (NSString *)createDirWithPath:(NSString *)dirPath
{
    if (!dirPath || 0 >= dirPath.length)
    {
        return nil;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager createDirectoryAtPath:dirPath
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:&error];
    NSAssert(!error, @"Create 'Localizable_Export' directory is failed !");
    return dirPath;
}


#pragma mark -- 获取导出文件夹，没有则创建
+ (NSString *)getWriteDirPath
{
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory,
                                                             NSUserDomainMask,
                                                             YES);
    NSString *desktopPath      = [pathArray objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *writeFleDir      = [desktopPath stringByAppendingPathComponent:DEPORT_DIR];
    BOOL isDirectory = NO;
    if (YES == [fileManager fileExistsAtPath:writeFleDir
                                 isDirectory:&isDirectory])
    {
        if (YES == isDirectory)
        {
            return writeFleDir;
        }
        else
        {
            return [self createDirWithPath: writeFleDir];
        }
    }
    else
    {
        return [self createDirWithPath: writeFleDir];
    }
}


#pragma mark - 文件
#pragma mark -- 创建导出文件
+ (NSString *)createFileWithPath:(NSString *)filePath
{
    if (!filePath || 0 >= filePath.length)
    {
        return nil;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    [fileManager createFileAtPath:filePath
                         contents:nil
                       attributes:nil];
    NSAssert(!error, @"Create 'Localizable.strings' file is failed !");
    return filePath;
}


#pragma mark -- 获取导出文件
+ (NSString *)getWrithFilePathWithCount:(NSInteger)fileCount
{
    if (0 >= fileCount)
    {
        return nil;
    }
    NSString *fileName = [NSString stringWithFormat:@"%@%ld.%@", FILE_BASE_NAME, (long)fileCount, FILE_SUFFIX];
    NSString *filePath = [[self getWriteDirPath] stringByAppendingPathComponent:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    if (YES == [fileManager fileExistsAtPath:filePath
                                 isDirectory:&isDirectory])
    {
        if (NO == isDirectory)
        {
            return filePath;
        }
        else
        {
            return [self createFileWithPath:filePath];
        }
    }
    else
    {
        return [self createFileWithPath:filePath];
    }
}


#pragma mark - 解析
#pragma mark -- 解析 CSV 文件
+ (void)parseCSVFileWithPath:(NSString *)filePath
{
    if (!filePath || 0 >= filePath.length)
    {
        NSLog(@"文件录像不存在！");
        return;
    }
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    NSArray <NSString *> *strArray = [fileContents componentsSeparatedByString:@"\n"];
    NSString *rowStr = nil;
    for (NSInteger i = 0; i < strArray.count; i++)
    {
        rowStr = nil;
        rowStr = strArray[i];
//        NSLog(@"rowStr = %@", rowStr);
        [self parseRowStr:rowStr];
    }
}


#pragma mark -- 解析 CSV 文件每一行字符
+ (void)parseRowStr:(NSString *)rowStr
{
    if (!rowStr || 2 > rowStr.length)   // keyStr,valueStr （keyStr 必须有值；valueStr 可以为空）
    {
        NSLog(@"rowStr = nil，无需解析！");
        return;
    }
    NSArray <NSString *>*strArray = [rowStr componentsSeparatedByString:@","];
    if (0 >= strArray[0].length)    // 如果 keyStr 为空，则不用处理
    {
        // 清空缓存
        strArray = nil;
        rowStr   = nil;
        return;
    }
    NSString *keyStr    = [self removeWhitespaceWithStr:strArray[0]];
    keyStr              = [self removeCarriageReturnWithStr:keyStr];
    keyStr              = [self removeCSVFileESCWithStr:keyStr];
    keyStr              = [self addESCWithStr:keyStr];
    
    NSString *valueStr  = nil;
    NSString *splitStr  = nil;
    NSInteger fileCount = 0;
    NSMutableArray <NSString *>*splitValueStrArray = [NSMutableArray arrayWithCapacity:0];
    for (NSInteger i = 1; i < strArray.count; i++)  // 遍历 valueStr
    {
        // 清空缓存
        valueStr = nil;
        splitStr = nil;
        
        if (1 <= strArray[i].length
            && [@"\"" isEqualToString:[strArray[i] substringToIndex:1]])   // 寻找单元格起始【"】
        {
            // 去掉空格，单元格起始【"】
            splitStr = [self removeWhitespaceWithStr:[strArray[i] substringFromIndex:1]];
            
            splitStr = [self removeCarriageReturnWithStr:splitStr];
            
            splitStr = [self removeCSVFileESCWithStr:splitStr];
            
            splitStr = [self addESCWithStr:splitStr];
            
            [splitValueStrArray addObject:splitStr];    // 先添加第一个‘分割’
            i++;
            
            // 鉴别单元格结束【"】
            while (i < strArray.count)
            {
                splitStr = nil;
                splitStr = [self removeWhitespaceWithStr:strArray[i]];
                
                splitStr = [self removeCarriageReturnWithStr:splitStr];
                
                // 分割中间部分
                if (![@"\"" isEqualToString:[splitStr substringWithRange:NSMakeRange(splitStr.length - 1, 1)]])
                {
                    splitStr = [self removeCSVFileESCWithStr:splitStr];
                    
                    splitStr = [self addESCWithStr:splitStr];
                    
                    [splitValueStrArray addObject:splitStr];
                    i++;
                }
                
                // 不是分割中间部分，退出循环
                break;
            }
            
            if (i < strArray.count)
            {
                splitStr = [self removeWhitespaceWithStr:strArray[i]];
                
                splitStr = [self removeCarriageReturnWithStr:splitStr];
                
                // 单元格结束【"】
                if ([@"\"" isEqualToString:[splitStr substringWithRange:NSMakeRange(splitStr.length - 1, 1)]])
                {
                    splitStr = [self removeCSVFileESCWithStr:[splitStr substringToIndex:splitStr.length - 1]];
                    
                    splitStr = [self addESCWithStr:splitStr];
                    
                    [splitValueStrArray addObject:splitStr];    // 添加最后‘分割’
                }
            }
            
            // 开始拼接被分割的
            valueStr = splitValueStrArray[0] ;
            
            for (NSInteger j = 1; j < splitValueStrArray.count; j++)
            {
                valueStr = [NSString stringWithFormat:@"%@,%@", valueStr, splitValueStrArray[j]];   // 注意添加回来原有的【,】
            }
            
            valueStr = [self removeWhitespaceWithStr:valueStr];
            
            valueStr = [self removeCarriageReturnWithStr:valueStr];
            
            [self addKeyStr:keyStr
                   valueStr:valueStr
                  fileCount:++fileCount];
            
            [splitValueStrArray removeAllObjects];
        }
        else
        {
            valueStr = [self removeWhitespaceWithStr:strArray[i]];
            
            valueStr = [self removeCarriageReturnWithStr:valueStr];
            
            valueStr = [self removeCSVFileESCWithStr:valueStr];
            
            valueStr = [self addESCWithStr:valueStr];
            
            [self addKeyStr:keyStr
                   valueStr:valueStr
                  fileCount:++fileCount];
        }
    }
    strArray = nil;
    valueStr = nil;
}


#pragma mar -- 移除前后空格
+ (NSString *)removeWhitespaceWithStr:(NSString *)sourceStr
{
    if (!sourceStr || 0 >= sourceStr.length)
    {
        return @"";
    }
    return [sourceStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}


#pragma mark -- 去掉【\r】,如果有【\r】（使用字符替换有时不奏效）
+ (NSString *)removeCarriageReturnWithStr:(NSString *)sourceStr
{
    NSString *newStr = @"";
    if (!sourceStr || 0 >= sourceStr.length)
    {
        return newStr;
    }
    if ([sourceStr containsString:@"\r"])
    {
        NSArray <NSString *>*rStrArray = [sourceStr componentsSeparatedByString:@"\r"];
        newStr = rStrArray[0];
        for (NSInteger i = 1; i < rStrArray.count; i++)
        {
            newStr = [NSString stringWithFormat:@"%@%@", newStr, rStrArray[i]];
        }
    }
    else
    {
        newStr = sourceStr;
    }
    return newStr;
}


#pragma mark -- 去掉 CSV 格式文件的转义字符【"】
+ (NSString *)removeCSVFileESCWithStr:(NSString *)sourceStr
{
    if (!sourceStr || 0 >= sourceStr.length)
    {
        return @"";
    }
    while (NSNotFound != [sourceStr rangeOfString:@"\"\""].location)   // 如果遇到 CSV 格式文件转义【"】，遍历所有的
    {
        NSRange quoMarkRange = [sourceStr rangeOfString:@"\"\""];
        // 仅去掉 CSV 格式文件转义【"】，不去掉真正字符【"】,如【""重点词汇""】 ——> 【"重点词汇"】
        sourceStr = [sourceStr stringByReplacingCharactersInRange:NSMakeRange(quoMarkRange.location, 1)
                                                       withString:@""];
    }
    return sourceStr;
}


#pragma mark -- 添加 C 语言格式文件字符串转移符【\】，如果有【"】
+ (NSString *)addESCWithStr:(NSString *)sourceStr
{
    NSString *newStr = @"";
    if (!sourceStr || 0 >= sourceStr.length)
    {
        return newStr;
    }
    if ([sourceStr containsString:@"\""])
    {
        NSArray <NSString *>*quoStrArray = [sourceStr componentsSeparatedByString:@"\""];
        for (NSInteger i = 0; i < quoStrArray.count - 1; i++)
        {
            newStr = [NSString stringWithFormat:@"%@%@\\\"", newStr, quoStrArray[i]];
        }
        newStr = [NSString stringWithFormat:@"%@%@", newStr, quoStrArray[(quoStrArray.count - 1)]];
    }
    else
    {
        newStr = sourceStr;
    }
    return newStr;
}


#pragma mark -- 添加 ‘key-value’ 到 strings 文件
+ (void)addKeyStr:(NSString *)dstKeyStr
         valueStr:(NSString *)dstValueStr
        fileCount:(NSInteger)fileCount
{
    if ([dstKeyStr isEqualToString:@"Personal_camera"])
    {
        NSLog(@"");
    }
    NSString *fileContents = [NSString stringWithContentsOfFile:[self getWrithFilePathWithCount:fileCount]
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    NSArray <NSString *> *strArray = [fileContents componentsSeparatedByString:@"\n"];
    BOOL isAdd         = NO;
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
            rowStr   = [self removeWhitespaceWithStr:rowStr];  // 去掉空格
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
            
            keyStr   = [self removeWhitespaceWithStr:keyValueArray[0]];
            valueStr = [self removeWhitespaceWithStr:keyValueArray[1]];
            if (2 > keyStr.length || 3 > valueStr.length // keyStr: 【""】  ----  valueStr: 【"";】
                || ![@"\"" isEqualToString:[keyStr substringToIndex:1]]     // keyStr 【"】开头
                || ![@"\"" isEqualToString:[keyStr substringWithRange:NSMakeRange(keyStr.length - 1, 1)]] // keyStr 【"】结尾
                || ![@"\"" isEqualToString:[valueStr substringToIndex:1]]   // valueStr 【"】开头
                || ![@";" isEqualToString:[valueStr substringWithRange:NSMakeRange(valueStr.length - 1, 1)]])  // valueStr 【;】开头
            {
                continue;
            }
            
            keyStr = [keyStr substringWithRange:NSMakeRange(1, keyStr.length - 2)];
            if ([keyStr isEqualToString:dstKeyStr])     // 已存在，无需添加
            {
                isAdd = YES;
                break;
            }
        }
    }
    // 添加
    if (NO == isAdd)
    {
        NSString *newKeyStr       = [NSString stringWithFormat:@"\"%@\"", dstKeyStr];
        NSString *newKeyFormatStr = [NSString stringWithFormat:@"%-25s", [newKeyStr UTF8String]];
        NSString *newRowStr       = [NSString stringWithFormat:@"%@ = \"%@\";\n", newKeyFormatStr, dstValueStr];
        NSString *newFileStr      = [NSString stringWithFormat:@"%@%@", fileContents, newRowStr];
        [newFileStr writeToFile:[self getWrithFilePathWithCount:fileCount]
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:nil];
        isAdd           = YES;
        newKeyStr       = nil;
        newKeyFormatStr = nil;
        newRowStr       = nil;
        newFileStr      = nil;
    }
    
    // 清空缓存
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

@end
