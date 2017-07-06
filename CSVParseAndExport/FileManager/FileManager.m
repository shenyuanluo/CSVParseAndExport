//
//  FileManager.m
//  CSVParseAndExport
//
//  Created by shenyuanluo on 2017/7/6.
//  Copyright © 2017年 shenyuanluo. All rights reserved.
//

#import "FileManager.h"

static NSString *kExportDir           = @"StringsAndXlsExport";     // 导出文件夹名称
static NSString *kStringsFileBaseName = @"Localizable";             // strings 文件基本名字
static NSString *kStringsFileSuffix   = @"strings";                 // 导出的 strings 文件类型
static NSString *kXlsFileName         = @"translate";               // xls 文件名字
static NSString *kXlsFileSuffix       = @"xls";                     // 导出的 xls 文件类型

@implementation FileManager


+ (instancetype)shareFileManager
{
    static FileManager *g_fileManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (nil == g_fileManager)
        {
            g_fileManager = [[FileManager alloc] init];
        }
    });
    return g_fileManager;
}


#pragma mark - 文件夹
#pragma mark -- 创建导出文件夹
- (NSString *)createDirWithPath:(NSString *)dirPath
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
- (NSString *)getWriteDirPath
{
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory,
                                                             NSUserDomainMask,
                                                             YES);
    NSString *desktopPath      = [pathArray objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *writeFleDir      = [desktopPath stringByAppendingPathComponent:kExportDir];
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
#pragma mark -- 获取导出的文件名
- (NSString *)getFileNameWithType:(ExportFileType)fileType
                 stringsFileIndex:(NSInteger)stringsFileIndex
{
    NSString *fileName = nil;
    switch (fileType)
    {
        case ExportStrings:     // Localizable.strings 文件
        {
            if (0 >= stringsFileIndex)
            {
                return nil;
            }
            fileName = [NSString stringWithFormat:@"%@%ld.%@",
                        kStringsFileBaseName,
                        (long)stringsFileIndex,
                        kStringsFileSuffix];
        }
            break;
            
        case ExportXls:         // Translate.xls 文件
        {
            fileName = [NSString stringWithFormat:@"%@.%@",
                        kXlsFileName,
                        kXlsFileSuffix];
        }
            break;
            
        default:
        {
            
        }
            break;
    }
    return fileName;
}


#pragma mark -- 创建导出文件
- (NSString *)createFileWithPath:(NSString *)filePath
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


#pragma mark - Public API
#pragma mark -- 获取导出文件
- (NSString *)getWriteFilePathWithType:(ExportFileType)fileType
                      stringsFileIndex:(NSUInteger)stringsFileIndex
{
    NSString *fileName = [self getFileNameWithType:fileType
                                  stringsFileIndex:stringsFileIndex];
    if (!fileName || 0 >= fileName.length)
    {
        return nil;
    }
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



- (NSString *)exportFilePath
{
    return [self getWriteDirPath];
}

@end
