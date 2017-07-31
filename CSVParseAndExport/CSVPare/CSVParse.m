//
//  CSVParse.m
//  CSVParseAndExport
//
//  Created by http://blog.shenyuanluo.com/ on 2017/7/1.
//  Copyright © 2017年 https://github.com/shenyuanluo All rights reserved.
//

#import "CSVParse.h"
#import "FileManager.h"

#define DEPORT_DIR  @"Localizable_Export"   // 导出文件夹名称
#define FILE_BASE_NAME @"Localizable"       // 文件基本名字
#define FILE_SUFFIX @"strings"              // 导出文件类型



@implementation CSVParse

+ (instancetype)shareCSVParse
{
    static CSVParse *g_csvParse = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (nil == g_csvParse)
        {
            g_csvParse = [[CSVParse alloc] init];
        }
    });
    return g_csvParse;
}


#pragma mark - 解析
#pragma mark -- 解析 CSV 文件
- (void)parseCSVFileWithPath:(NSString *)filePath
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
        rowStr = [self removeCarriageReturnWithStr:rowStr];
        rowStr = [self removeESCWithStr:rowStr];
//        NSLog(@"rowStr = %@", rowStr);
        [self parseRowStr:rowStr];
    }
}


#pragma mark -- 解析 CSV 文件每一行字符
- (void)parseRowStr:(NSString *)rowStr
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
    keyStr              = [self removeCSVFileESCWithStr:keyStr];
    keyStr              = [self addESCWithStr:keyStr];
    
    NSString *valueStr  = nil;
    NSString *splitStr  = nil;
    NSInteger fileIndex = 0;
    NSMutableArray <NSString *>*splitValueStrArray = [NSMutableArray arrayWithCapacity:0];
    for (NSInteger i = 1; i < strArray.count; i++)  // 遍历 valueStr
    {
        // 清空缓存
        valueStr = nil;
        splitStr = nil;
        
        if (1 <= strArray[i].length
            && [@"\"" isEqualToString:[strArray[i] substringToIndex:1]])   // 寻找单元格起始【"】
        {
            if ([@"\"" isEqualToString:[strArray[i] substringFromIndex:strArray[i].length - 1]])    // 最后一个字符是否是单元格结束【"】
            {
                // 去掉空格，单元格起始、结束【"】
                valueStr = [self removeWhitespaceWithStr:[strArray[i] substringWithRange:NSMakeRange(1, strArray[i].length - 2)]];
                
                valueStr = [self removeCSVFileESCWithStr:valueStr];
                
                valueStr = [self addESCWithStr:valueStr];
                
                [self addKeyStr:keyStr
                       valueStr:valueStr
                      fileIndex:++fileIndex];
                
                continue;
            }
            // 去掉空格，单元格起始【"】
            splitStr = [self removeWhitespaceWithStr:[strArray[i] substringFromIndex:1]];
            
            splitStr = [self removeCSVFileESCWithStr:splitStr];
            
            splitStr = [self addESCWithStr:splitStr];
            
            [splitValueStrArray addObject:splitStr];    // 先添加第一个‘分割’
            i++;
            
            // 鉴别单元格结束【"】
            while (i < strArray.count)
            {
                splitStr = nil;
                splitStr = [self removeWhitespaceWithStr:strArray[i]];
                
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
            
            [self addKeyStr:keyStr
                   valueStr:valueStr
                  fileIndex:++fileIndex];
            
            [splitValueStrArray removeAllObjects];
        }
        else
        {
            valueStr = [self removeWhitespaceWithStr:strArray[i]];
            
            valueStr = [self removeCSVFileESCWithStr:valueStr];
            
            valueStr = [self addESCWithStr:valueStr];
            
            [self addKeyStr:keyStr
                   valueStr:valueStr
                  fileIndex:++fileIndex];
        }
    }
    strArray = nil;
    valueStr = nil;
}


#pragma mar -- 移除前后空格
- (NSString *)removeWhitespaceWithStr:(NSString *)sourceStr
{
    if (!sourceStr || 0 >= sourceStr.length)
    {
        return @"";
    }
    return [sourceStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}


#pragma mark -- 去掉‘回车标识符’【\r】,如果有【\r】（使用字符替换有时不奏效）
- (NSString *)removeCarriageReturnWithStr:(NSString *)sourceStr
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


#pragma mark -- 去掉 C 语言格式的转一份【\】，在处理其他之前调用
- (NSString *)removeESCWithStr:(NSString *)sourceStr
{
    NSString *newStr = @"";
    if (!sourceStr || 0 >= sourceStr.length)
    {
        return newStr;
    }
    if ([sourceStr containsString:@"\\"])
    {
        NSArray <NSString *>*rStrArray = [sourceStr componentsSeparatedByString:@"\\"];
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
- (NSString *)removeCSVFileESCWithStr:(NSString *)sourceStr
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
- (NSString *)addESCWithStr:(NSString *)sourceStr
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
- (void)addKeyStr:(NSString *)dstKeyStr
         valueStr:(NSString *)dstValueStr
        fileIndex:(NSInteger)fileIndex
{
    if (!dstKeyStr || 0 >= dstKeyStr.length
        || !dstValueStr || 0 >= fileIndex)
    {
        return ;
    }
    NSString *fileContents = [NSString stringWithContentsOfFile:[[FileManager shareFileManager] getWriteFilePathWithType:ExportStrings
                                                                                                        stringsFileIndex:fileIndex]
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
        [newFileStr writeToFile:[[FileManager shareFileManager] getWriteFilePathWithType:ExportStrings
                                                                        stringsFileIndex:fileIndex]
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
