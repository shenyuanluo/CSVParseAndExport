//
//  CSVExport.h
//  CSVParseAndExport
//
//  Created by http://blog.shenyuanluo.com/ on 2017/7/1.
//  Copyright © 2017年 https://github.com/shenyuanluo All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSVExport : NSObject

+ (NSString *)exportFilePath;

+ (void)parestFileWithPath:(NSString *)filePath
               columnCount:(NSInteger)columnCount;

@end
