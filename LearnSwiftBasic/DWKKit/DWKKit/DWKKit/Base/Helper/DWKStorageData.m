//
//  DWKStorageData.m
//  DWKKit
//
//  Created by pisen on 16/10/17.
//  Copyright © 2016年 丁文凯. All rights reserved.
//

#import "DWKStorageData.h"

#define kCommonDirectory            @"DWKKit_Storage/"
#define kCommonSettingFile          @"CommonSetting.archive"
#define kUserSettingFile            @"UserSetting.archive"

//----------------------------------------------------------------------------
//  定义各种文件的缓存路径
//----------------------------------------------------------------------------
@interface DWKStorageData ()
@property (nonatomic, copy) NSString *userId;
@end

@implementation DWKStorageData

+ (instancetype)sharedInstance{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc]init];
    })
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.directoryPathOfHome = kPathOfSandBoxHome;
        self.directoryPathOfDocuments = [DWKFileManager directoryPathOfDocuments];
        self.directoryPathOfLibrary = [DWKFileManager directoryPathOfLibrary];
        self.directoryPathOfLibraryCaches = [DWKFileManager directoryPathOfLibraryCaches];
        self.directoryPathOfLibraryPreferences = [DWKFileManager directoryPathOfLibraryPreferences];
        self.directoryPathOfTmp = kPathOfSandBoxTemp;
        [self _ensureCommonDirectories];
    }
    return self;
}

- (void)setUserId:(NSString *)userId{
    if (OBJECT_ISNOT_EMPTY(userId)) {
        _userId = userId;
        [self _ensureUserDirectories];
    }
}
// 私有方法
- (void)_ensureCommonDirectories {
    [DWKFileManager ensureDirectory:[self directoryPathOfDocumentsCommon]];
    [DWKFileManager ensureDirectory:[self directoryPathOfDocumentsLog]];
    [DWKFileManager ensureDirectory:[self directoryPathOfLibraryCachesCommon]];
}
- (void)_ensureUserDirectories {
    [DWKFileManager ensureDirectory:[self directoryPathOfDocumentsByUserId]];
    [DWKFileManager ensureDirectory:[self directoryPathOfLibraryCachesByUserId]];
    [DWKFileManager ensureDirectory:[self directoryPathOfPicByUserId]];
    [DWKFileManager ensureDirectory:[self directoryPathOfAudioByUserId]];
    [DWKFileManager ensureDirectory:[self directoryPathOfVideoByUserId]];
}

// Documents目录下的文件和目录路径
- (NSString *)directoryPathOfDocumentsCommon {
    return [self.directoryPathOfDocuments stringByAppendingPathComponent:kCommonDirectory];
}
- (NSString *)filePathOfCommonSettings {
    return [[self directoryPathOfDocumentsCommon] stringByAppendingPathComponent:kCommonSettingFile];
}
- (NSString *)directoryPathOfDocumentsByUserId {
    return [[self directoryPathOfDocumentsCommon] stringByAppendingPathComponent:self.userId];
}
- (NSString *)filePathOfUserSettings {
    return [[self directoryPathOfDocumentsByUserId] stringByAppendingPathComponent:kUserSettingFile];
}


// Library目录下的文件和目录路径
- (NSString *)directoryPathOfLibraryCachesCommon {
    return [self.directoryPathOfLibraryCaches stringByAppendingPathComponent:kCommonDirectory];
}
- (NSString *)directoryPathOfLibraryCachesByUserId {
    return [[self directoryPathOfLibraryCachesCommon] stringByAppendingPathComponent:self.userId];
}
- (NSString *)directoryPathOfPicByUserId {
    return [[self directoryPathOfLibraryCachesByUserId] stringByAppendingPathComponent:@"Pics/"];
}
- (NSString *)directoryPathOfAudioByUserId {
    return [[self directoryPathOfLibraryCachesByUserId] stringByAppendingPathComponent:@"Audioes/"];
}
- (NSString *)directoryPathOfVideoByUserId {
    return [[self directoryPathOfLibraryCachesByUserId] stringByAppendingPathComponent:@"Videoes/"];
}
- (NSString *)directoryPathOfLibraryCachesBundleIdentifier {
    NSString *appBundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    return [self.directoryPathOfLibraryCaches stringByAppendingPathComponent:appBundleId];
}
- (NSString *)directoryPathOfDocumentsLog {
    return [[self directoryPathOfLibraryCachesCommon] stringByAppendingPathComponent:@"DWKLog/"];
}
@end

//----------------------------------------------------------------------------
//  管理缓存数据的序列化和反序列化
//----------------------------------------------------------------------------
@implementation DWKStorageData (Archive)



- (void) _setConfigWithValueAndKeys:(id)firstObject,...NS_REQUIRES_NIL_TERMINATION{
    NSMutableArray *keys = [NSMutableArray array];
    NSMutableArray *values = [NSMutableArray array];
    va_list args;
    va_start(args, firstObject);
    for (id value = firstObject ;value != nil ; value = va_arg(args, id)){
        id key = va_arg(args, id);
        
        [values addObject:value];
        [keys addObject:key];
    }
    va_end(args);
    
    NSUInteger valueCount = [values count];
    if (valueCount != [keys count]) {
        NSLog(@"set config error : objects and keys don’t have the same number of elements.");
    }
    else {
        NSMutableDictionary *configDictionary = [NSMutableDictionary dictionary];
        for(int index = 0; index < valueCount; index ++) {
            [configDictionary setObject:[values objectAtIndex:index] forKey:[keys objectAtIndex:index]];
        }
        [self archiveDictionary:configDictionary toFilePath:[self filePathOfCommonSettings] overwrite:NO];
    }
    
}

// 用户配置文件存取
- (void)setUserConfigValue:(NSObject *)value forKey:(NSString *)key {
    [self _setUserConfigWithValuesAndKeys:value, key, nil];
}
- (id)userConfigValueForKey:(NSString *)key {
    RETURN_NIL_WHEN_OBJECT_IS_EMPTY(key)
    NSDictionary *userConfig = [self unarchiveDictionaryFromFilePath:[self filePathOfUserSettings]];
    return userConfig[key];
}
- (void)_setUserConfigWithValuesAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray *keys = [NSMutableArray array];
    NSMutableArray *values = [NSMutableArray array];
    
    va_list args;
    va_start(args, firstObject);
    for (id value = firstObject; value != nil; value = va_arg(args, id)) {
        id key = va_arg(args, id);
        [values addObject:value];
        [keys addObject:key];
    }
    va_end(args);
    
    NSUInteger valueCount = [values count];
    if (valueCount != [keys count]) {
        NSLog(@"set config error : objects and keys don’t have the same number of elements.");
    }
    else {
        NSMutableDictionary *configDictionary = [NSMutableDictionary dictionary];
        for(int index = 0; index < valueCount; index ++) {
            [configDictionary setObject:[values objectAtIndex:index] forKey:[keys objectAtIndex:index]];
        }
        [self archiveDictionary:configDictionary toFilePath:[self filePathOfUserSettings] overwrite:NO];
    }
}

// 序列化 & 反序列化

- (BOOL)archiveDictionary:(NSDictionary *)dicionary toFilePath:(NSString *)filePath {
    return [self archiveDictionary:dicionary toFilePath:filePath overwrite:NO];
}
- (BOOL)archiveDictionary:(NSDictionary *)dicionary toFilePath:(NSString *)filePath overwrite:(BOOL)overwrite {
    if (overwrite) {
        return [NSKeyedArchiver archiveRootObject:dicionary toFile:filePath];
    }
    else {
        NSMutableDictionary *allDictionary = [NSMutableDictionary dictionaryWithCapacity:[dicionary count]];
        [allDictionary addEntriesFromDictionary:[self unarchiveDictionaryFromFilePath:filePath]];
        [allDictionary addEntriesFromDictionary:dicionary];
        return [NSKeyedArchiver archiveRootObject:allDictionary toFile:filePath];
    }
}

- (NSDictionary *)unarchiveDictionaryFromFilePath:(NSString *)filePath{
    NSDictionary * dict;
    @try {
        dict = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    } @catch (NSException *exception) {
        NSLog(@"unarchive error:%@", [exception debugDescription]);
    } @finally {
        
    }
    return dict;
}

// 删除Documents和Caches目录中的缓存数据，并确保所有缓存目录都存在
- (void)clearLibraryCaches {
    //Documents
    [DWKFileManager clearDirectoryPath:self.directoryPathOfDocumentsLog];
    
    //Library/Caches
    [DWKFileManager clearDirectoryPath:self.directoryPathOfLibraryCachesCommon];
    [DWKFileManager clearDirectoryPath:self.directoryPathOfLibraryCachesBundleIdentifier];
    
    [self _ensureCommonDirectories];
    [self _ensureUserDirectories];
}


@end

//----------------------------------------------------------------------------
//  处理缓存数据
//----------------------------------------------------------------------------
@implementation DWKStorageData (Cache)

- (BOOL)saveObject:(NSObject *)object forKey:(NSString *)key fileName:(NSString *)fileName subFolder:(NSString *)subFoler {
    return [self _saveObject:object forKey:key fileName:fileName folder:self.directoryPathOfDocumentsCommon subFolder:subFoler];
}
- (id)getObjectForKey:(NSString *)key fileName:(NSString *)fileName subFolder:(NSString *)subFoler {
    return [self _getObjectForKey:key fileName:fileName folder:self.directoryPathOfDocumentsCommon subFolder:subFoler];
}
- (BOOL)saveCacheObject:(NSObject *)object forKey:(NSString *)key fileName:(NSString *)fileName subFolder:(NSString *)subFoler {
    return [self _saveObject:object forKey:key fileName:fileName folder:self.directoryPathOfLibraryCachesCommon subFolder:subFoler];
}
- (id)getCacheObjectForKey:(NSString *)key fileName:(NSString *)fileName subFolder:(NSString *)subFoler {
    return [self _getObjectForKey:key fileName:fileName folder:self.directoryPathOfLibraryCachesCommon subFolder:subFoler];
}

// 两个通用方法：存储数据、获取数据
- (BOOL)_saveObject:(NSObject *)object forKey:(NSString *)key fileName:(NSString *)fileName folder:(NSString *)folderPath subFolder:(NSString *)subFolerName{
    RETURN_NO_WHEN_OBJECT_IS_EMPTY(key)
    RETURN_NO_WHEN_OBJECT_IS_EMPTY(folderPath)
    if (!object) {
        object = [NSNull null];
    }
    if (OBJECT_ISNOT_EMPTY(subFolerName)) {
        folderPath = [folderPath stringByAppendingPathComponent:subFolerName];
    }
    if (OBJECT_IS_EMPTY(fileName)) {
        fileName = kCommonSettingFile;
    }
    NSString * filePath = [folderPath stringByAppendingPathComponent:fileName];
    BOOL isSuccess = NO;
    @try {
        isSuccess = [self archiveDictionary:@{key:object} toFilePath:filePath overwrite:NO];
    } @catch (NSException *exception) {
        NSLog(@"序列化object出错：%@", exception); //可能是没有在对象里做序列号和反序列化！
        isSuccess = NO;
    }
    return isSuccess;
}

- (id)_getObjectForKey:(NSString *)key fileName:(NSString *)fileName folder:(NSString *)folderPath subFolder:(NSString *)subFolerName {
    RETURN_NIL_WHEN_OBJECT_IS_EMPTY(key)
    RETURN_NIL_WHEN_OBJECT_IS_EMPTY(folderPath)
    
    if (OBJECT_ISNOT_EMPTY(subFolerName)) {
        folderPath = [folderPath stringByAppendingPathComponent:subFolerName];
    }
    if (OBJECT_IS_EMPTY(fileName)) {
        fileName = kCommonSettingFile;
    }
    NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
    NSDictionary *cacheInfo = [self unarchiveDictionaryFromFilePath:filePath];
    NSObject *value = cacheInfo[key];
    if (value && ( ! [value isKindOfClass:[NSNull class]])) {
        return value;
    }
    else {
        return nil;
    }
}
@end
