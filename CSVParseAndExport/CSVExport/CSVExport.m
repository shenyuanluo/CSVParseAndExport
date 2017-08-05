//
//  CSVExport.m
//  CSVParseAndExport
//
//  Created by http://blog.shenyuanluo.com/ on 2017/7/1.
//  Copyright © 2017年 https://github.com/shenyuanluo All rights reserved.
//

#import "CSVExport.h"
#import "FileManager.h"
#import "xlsxwriter.h"


@interface CSVExport ()
{
    lxw_workbook  *_workbook;
    lxw_worksheet *_worksheet;
}

/**
 *  将要写的文件内容
 */
@property (nonatomic, copy) NSString *writeFileContents;

@end


@implementation CSVExport

+ (instancetype)shareCSVExport
{
    static CSVExport *g_csvExport = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (!g_csvExport)
        {
            g_csvExport = [[CSVExport alloc] init];
        }
    });
    
    return g_csvExport;
}


- (instancetype)init
{
    if (self = [super init])
    {
        self.writeFileContents = @"";
    }
    return self;
}


#pragma mark - 解析
#pragma mark -- 解析 strings 文件
- (void)parestFileWithPath:(NSString *)filePath
             currentColumn:(NSUInteger)currentColumn
               columnCount:(NSUInteger)columnCount
{
    if (!filePath || 0 >= filePath.length
        || 0 >= currentColumn || 0 >= columnCount)
    {
        return;
    }
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    NSArray <NSString *> *strArray = [fileContents componentsSeparatedByString:@"\n"];
    fileContents = nil;
    
    NSString *rowStr   = nil;
    NSString *firstStr = nil;
    NSString *lastStr  = nil;
    NSString *keyStr   = nil;
    NSString *valueStr = nil;
    CGFloat progress   = 0;
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
              currentColumn:currentColumn];
        }
        progress = (CGFloat)((CGFloat)(i + 1) / (CGFloat)strArray.count);
        if (self.delegate && [self.delegate respondsToSelector:@selector(csvExportProgress:)])
        {
            [self.delegate csvExportProgress:progress];
        }
    }
    
    // 写到 EXcel 文件
    if (currentColumn == columnCount
        && self.writeFileContents && 0 < self.writeFileContents.length)
    {
        NSString *filePath = [[FileManager shareFileManager] getWriteFilePathWithType:ExportXls
                                                                     stringsFileIndex:0];
        _workbook  = new_workbook([filePath fileSystemRepresentation]);
        _worksheet = workbook_add_worksheet(_workbook, NULL);
        NSArray <NSString *>*rowStrArray = [self.writeFileContents componentsSeparatedByString:@"\n"];
        for (NSInteger j = 0; j < rowStrArray.count; j++)
        {
            [self writeRowStr:rowStrArray[j]
                       forRow:(uint32_t)j];
        }
        workbook_close(_workbook);
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


#pragma mark -- 添加 ’key-value‘
- (void)addKeyStr:(NSString *)dstKeyStr
         valueStr:(NSString *)dstValueStr
    currentColumn:(NSInteger)currentColumn
{
    if (!dstKeyStr || 0 >= dstKeyStr.length
        || !dstValueStr || 0 >= dstValueStr.length)
    {
        return ;
    }
    BOOL isAddValueStr = NO;
    NSArray <NSString *> *strArray = [self.writeFileContents componentsSeparatedByString:@"\n"];
    
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
                            currentColumn:currentColumn];
        preRowsStr = @"";
        for (NSInteger j = 0; j < i; j++)
        {
            preRowsStr = [NSString stringWithFormat:@"%@%@", preRowsStr, [self formatRowString:strArray[j]
                                                                                 currentColumn:currentColumn]];
        }
        preRowsStr = [NSString stringWithFormat:@"%@%@", preRowsStr, newRowStr];
        nextRowsStr = @"";
        for (NSInteger k = i + 1; k < strArray.count; k++)
        {
            nextRowsStr = [NSString stringWithFormat:@"%@%@", nextRowsStr, [self formatRowString:strArray[k]
                                                                                   currentColumn:currentColumn]];
        }
        newFileStr = [NSString stringWithFormat:@"%@%@", preRowsStr, nextRowsStr];
        
        self.writeFileContents = newFileStr;
        
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
        for (NSInteger i = 0; i < currentColumn; i++)
        {
            emptyStr = [NSString stringWithFormat:@"%@,", emptyStr];
        }
        newRowStr = [NSString stringWithFormat:@"%@%@%@\n", dstKeyStr, emptyStr, dstValueStr];
        newFileStr = [NSString stringWithFormat:@"%@%@", self.writeFileContents, newRowStr];
        
        self.writeFileContents = newFileStr;
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
- (NSString *)formatOldRowStr:(NSString *)oldRowStr
                     valueStr:(NSString *)valueStr
                currentColumn:(NSInteger)currentColumn
{
    if (!oldRowStr || !valueStr || 1 > currentColumn)
    {
        return @"";
    }
    NSString *newRowStr = @"";
    NSArray *strArray = [oldRowStr componentsSeparatedByString:@","];
    if (currentColumn == strArray.count)  // 刚好缺一列
    {
        newRowStr = [NSString stringWithFormat:@"%@,%@\n", oldRowStr, valueStr];
    }
    else  if (currentColumn > strArray.count) // 空列数不足
    {
        for (NSInteger i = 0; i < currentColumn - (strArray.count - 1) - 1; i++)
        {
            newRowStr = [NSString stringWithFormat:@"%@%@", oldRowStr, @","];
        }
        newRowStr = [NSString stringWithFormat:@"%@,%@\n", newRowStr, valueStr];
    }
    else    // 列数多余，需去除
    {
        for (NSInteger i = 0; i < currentColumn; i++)
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
- (NSString *)formatRowString:(NSString *)rowStr
                currentColumn:(NSInteger)currentColumn
{
    if (!rowStr || 0 >= rowStr.length || 1 > currentColumn)
    {
        return @"";
    }
    NSArray *strArray = [rowStr componentsSeparatedByString:@","];
    if (1 >= strArray.count)
    {
        return [NSString stringWithFormat:@"%@\n", rowStr];
    }
    if (currentColumn >= strArray.count)
    {
        for (NSInteger i = 0; i < currentColumn - (strArray.count - 1); i++)
        {
            rowStr = [NSString stringWithFormat:@"%@%@", rowStr, @","];
        }
    }
    // 清空缓存
    strArray = nil;
    
    return [NSString stringWithFormat:@"%@\n", rowStr];
}


#pragma mark -- 写入 XLS 文件
- (void)writeRowStr:(NSString *)rowStr
          forRow:(uint32_t)rowIndex
{
    if (!rowStr || 0 > rowIndex)
    {
        return;
    }
    NSArray <NSString *>*strArray = [rowStr componentsSeparatedByString:@","];
    NSString *string = @"";
    for (NSInteger i = 0; i < strArray.count; i++)
    {
        string = strArray[i];
        if ([string containsString:@"`"])
        {
            string = [string stringByReplacingOccurrencesOfString:@"`"      // 替换回来 ‘,’ 逗号
                                                       withString:@","];
            
        }
        worksheet_write_string(_worksheet, rowIndex, i, [string UTF8String], NULL);
    }
}

@end
