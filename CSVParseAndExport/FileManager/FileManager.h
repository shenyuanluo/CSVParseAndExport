//
//  FileManager.h
//  CSVParseAndExport
//
//  Created by shenyuanluo on 2017/7/6.
//  Copyright © 2017年 shenyuanluo. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  导出的文件类型
 */
typedef NS_ENUM(NSInteger, ExportFileType) {
    ExportStrings       = 0,            // 导出 Xcode 多语言配置文件 ‘Localizable.strings’
    ExportXls           = 1             // 导出 Excel 文件 ‘Translate.xls’
};


@interface FileManager : NSObject

+ (instancetype)shareFileManager;


/**
 根据文件类型获取导出文件路径

 @param fileType 文件类型，参见 ‘ExportFileType’
 @param stringsFileIndex 如果 fileType == ExportStrings，则传入 strings 文件的 index，表示第几个翻译文件
 @return 导出的文件路径
 */
- (NSString *)getWriteFilePathWithType:(ExportFileType)fileType
                      stringsFileIndex:(NSUInteger)stringsFileIndex;


/**
 获取导出文件夹路径

 @return 文件夹路径
 */
- (NSString *)exportFilePath;

@end
