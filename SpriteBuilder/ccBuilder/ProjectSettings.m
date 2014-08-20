#import "RMResource.h"/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "ProjectSettings.h"
#import "NSString+RelativePath.h"
#import "HashValue.h"
#import "PlugInManager.h"
#import "PlugInExport.h"
#import "ResourceManager.h"
#import "AppDelegate.h"
#import "ResourceManagerOutlineHandler.h"
#import "CCBWarnings.h"
#import "SBErrors.h"
#import "ResourceTypes.h"
#import "NSError+SBErrors.h"
#import "MiscConstants.h"

#import <ApplicationServices/ApplicationServices.h>

@interface ProjectSettings()

@property (nonatomic, strong) NSMutableDictionary* resourceProperties;
@property (nonatomic, readwrite) CCBTargetEngine engine;

@end

@implementation ProjectSettings

@synthesize projectPath;
@synthesize publishDirectory;
@synthesize publishDirectoryAndroid;
@synthesize publishEnabledIOS;
@synthesize publishEnabledAndroid;
@synthesize publishResolution_ios_phone;
@synthesize publishResolution_ios_phonehd;
@synthesize publishResolution_ios_tablet;
@synthesize publishResolution_ios_tablethd;
@synthesize publishResolution_android_phone;
@synthesize publishResolution_android_phonehd;
@synthesize publishResolution_android_tablet;
@synthesize publishResolution_android_tablethd;
@synthesize publishAudioQuality_ios;
@synthesize publishAudioQuality_android;
@synthesize isSafariExist;
@synthesize isChromeExist;
@synthesize isFirefoxExist;
@synthesize publishToZipFile;
@synthesize onlyPublishCCBs;
@synthesize exporter;
@synthesize availableExporters;
@synthesize deviceOrientationPortrait;
@synthesize deviceOrientationUpsideDown;
@synthesize deviceOrientationLandscapeLeft;
@synthesize deviceOrientationLandscapeRight;
@synthesize resourceAutoScaleFactor;
@synthesize versionStr;
@synthesize needRepublish;
@synthesize lastWarnings;

- (id) init
{
    self = [super init];
    if (!self)
    {
        return NULL;
    }

    self.engine = CCBTargetEngineCocos2d;

    self.resourcePaths = [[NSMutableArray alloc] init];
    self.publishDirectory = @"Published-iOS";
    self.publishDirectoryAndroid = @"Published-Android";

    self.onlyPublishCCBs = NO;
    self.publishToZipFile = NO;

    self.deviceOrientationLandscapeLeft = YES;
    self.deviceOrientationLandscapeRight = YES;
    self.resourceAutoScaleFactor = 4;
    
    self.publishEnabledIOS = YES;
    self.publishEnabledAndroid = YES;

    self.publishResolution_ios_phone = YES;
    self.publishResolution_ios_phonehd = YES;
    self.publishResolution_ios_tablet = YES;
    self.publishResolution_ios_tablethd = YES;
    self.publishResolution_android_phone = YES;
    self.publishResolution_android_phonehd = YES;
    self.publishResolution_android_tablet = YES;
    self.publishResolution_android_tablethd = YES;
    
    self.publishEnvironment = kCCBPublishEnvironmentDevelop;

    self.publishAudioQuality_ios = DEFAULT_AUDIO_QUALITY;
    self.publishAudioQuality_android = DEFAULT_AUDIO_QUALITY;
    
    self.tabletPositionScaleFactor = 2.0f;

    self.canUpdateCocos2D = NO;
    self.cocos2dUpdateIgnoredVersions = [NSMutableArray array];
    
    self.resourceProperties = [NSMutableDictionary dictionary];
    
    // Load available exporters
    self.availableExporters = [NSMutableArray array];
    for (PlugInExport* plugIn in [[PlugInManager sharedManager] plugInsExporters])
    {
        [availableExporters addObject: plugIn.extension];
    }
    
    [self detectBrowserPresence];
    self.versionStr = [self getVersion];
    self.needRepublish = NO;

    return self;
}

- (id) initWithSerialization:(id)dict
{
    self = [self init];
    if (!self
        || ![[dict objectForKey:@"fileType"] isEqualToString:@"CocosBuilderProject"])
    {
        return NULL;
    }

	self.engine = (CCBTargetEngine)[[dict objectForKey:@"engine"] intValue];
    self.resourcePaths = [dict objectForKey:@"resourcePaths"];

    self.publishDirectory = [dict objectForKey:@"publishDirectory"];
    if (!publishDirectory)
    {
        self.publishDirectory = @"";
    }

    self.publishDirectoryAndroid = [dict objectForKey:@"publishDirectoryAndroid"];
    if (!publishDirectoryAndroid)
    {
        self.publishDirectoryAndroid = @"";
    }

    self.publishEnabledIOS = [[dict objectForKey:@"publishEnablediPhone"] boolValue];
    self.publishEnabledAndroid = [[dict objectForKey:@"publishEnabledAndroid"] boolValue];

    self.publishResolution_ios_phone = [[dict objectForKey:@"publishResolution_ios_phone"] boolValue];
    self.publishResolution_ios_phonehd = [[dict objectForKey:@"publishResolution_ios_phonehd"] boolValue];
    self.publishResolution_ios_tablet = [[dict objectForKey:@"publishResolution_ios_tablet"] boolValue];
    self.publishResolution_ios_tablethd = [[dict objectForKey:@"publishResolution_ios_tablethd"] boolValue];
    self.publishResolution_android_phone = [[dict objectForKey:@"publishResolution_android_phone"] boolValue];
    self.publishResolution_android_phonehd = [[dict objectForKey:@"publishResolution_android_phonehd"] boolValue];
    self.publishResolution_android_tablet = [[dict objectForKey:@"publishResolution_android_tablet"] boolValue];
    self.publishResolution_android_tablethd = [[dict objectForKey:@"publishResolution_android_tablethd"] boolValue];
    
    self.publishAudioQuality_ios = [[dict objectForKey:@"publishAudioQuality_ios"]intValue];
    if (!self.publishAudioQuality_ios)
    {
        self.publishAudioQuality_ios = DEFAULT_AUDIO_QUALITY;
    }

    self.publishAudioQuality_android = [[dict objectForKey:@"publishAudioQuality_android"]intValue];
    if (!self.publishAudioQuality_android)
    {
        self.publishAudioQuality_android = DEFAULT_AUDIO_QUALITY;
    }

    self.publishToZipFile = [[dict objectForKey:@"publishToZipFile"] boolValue];
    self.onlyPublishCCBs = [[dict objectForKey:@"onlyPublishCCBs"] boolValue];
    self.exporter = [dict objectForKey:@"exporter"];
    self.deviceOrientationPortrait = [[dict objectForKey:@"deviceOrientationPortrait"] boolValue];
    self.deviceOrientationUpsideDown = [[dict objectForKey:@"deviceOrientationUpsideDown"] boolValue];
    self.deviceOrientationLandscapeLeft = [[dict objectForKey:@"deviceOrientationLandscapeLeft"] boolValue];
    self.deviceOrientationLandscapeRight = [[dict objectForKey:@"deviceOrientationLandscapeRight"] boolValue];

    self.resourceAutoScaleFactor = [[dict objectForKey:@"resourceAutoScaleFactor"]intValue];
    if (resourceAutoScaleFactor == 0)
    {
        self.resourceAutoScaleFactor = 4;
    }

    self.cocos2dUpdateIgnoredVersions = [[dict objectForKey:@"cocos2dUpdateIgnoredVersions"] mutableCopy];

    self.deviceScaling = [[dict objectForKey:@"deviceScaling"] intValue];
    self.defaultOrientation = [[dict objectForKey:@"defaultOrientation"] intValue];
    self.designTarget = [[dict objectForKey:@"designTarget"] intValue];
    
    self.tabletPositionScaleFactor = 2.0f;

    self.publishEnvironment = (CCBPublishEnvironment) [[dict objectForKey:@"publishEnvironment"] integerValue];

    self.resourceProperties = [[dict objectForKey:@"resourceProperties"] mutableCopy];

    self.excludedFromPackageMigration = [[dict objectForKey:@"excludedFromPackageMigration"] boolValue];
    if (!self.excludedFromPackageMigration)
    {
        self.excludedFromPackageMigration = NO;
    }

    [self detectBrowserPresence];

    [self initializeVersionStringWithProjectDict:dict];

    return self;
}

- (void)initializeVersionStringWithProjectDict:(NSDictionary *)projectDict
{
    // Check if we are running a new version of CocosBuilder
    // in which case the project needs to be republished
    NSString* oldVersionHash = projectDict[@"versionStr"];
    NSString* newVersionHash = [self getVersion];
    if (newVersionHash && ![newVersionHash isEqual:oldVersionHash])
    {
       self.versionStr = [self getVersion];
       self.needRepublish = YES;
    }
    else
    {
       self.needRepublish = NO;
    }
}

- (NSString*) exporter
{
    if (exporter)
    {
        return exporter;
    }
    return kCCBDefaultExportPlugIn;
}

- (id) serialize
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];

    dict[@"engine"] = @(_engine);

    dict[@"fileType"] = @"CocosBuilderProject";
    dict[@"fileVersion"] = @kCCBProjectSettingsVersion;
    dict[@"resourcePaths"] = _resourcePaths;
    
    dict[@"publishDirectory"] = publishDirectory;
    dict[@"publishDirectoryAndroid"] = publishDirectoryAndroid;

    dict[@"publishEnablediPhone"] = @(publishEnabledIOS);
    dict[@"publishEnabledAndroid"] = @(publishEnabledAndroid);

    dict[@"publishResolution_ios_phone"] = @(publishResolution_ios_phone);
    dict[@"publishResolution_ios_phonehd"] = @(publishResolution_ios_phonehd);
    dict[@"publishResolution_ios_tablet"] = @(publishResolution_ios_tablet);
    dict[@"publishResolution_ios_tablethd"] = @(publishResolution_ios_tablethd);
    dict[@"publishResolution_android_phone"] = @(publishResolution_android_phone);
    dict[@"publishResolution_android_phonehd"] = @(publishResolution_android_phonehd);
    dict[@"publishResolution_android_tablet"] = @(publishResolution_android_tablet);
    dict[@"publishResolution_android_tablethd"] = @(publishResolution_android_tablethd);
    
    dict[@"publishAudioQuality_ios"] = @(publishAudioQuality_ios);
    dict[@"publishAudioQuality_android"] = @(publishAudioQuality_android);

    dict[@"publishToZipFile"] = @(publishToZipFile);
    dict[@"onlyPublishCCBs"] = @(onlyPublishCCBs);
    dict[@"exporter"] = self.exporter;
    
    dict[@"deviceOrientationPortrait"] = @(deviceOrientationPortrait);
    dict[@"deviceOrientationUpsideDown"] = @(deviceOrientationUpsideDown);
    dict[@"deviceOrientationLandscapeLeft"] = @(deviceOrientationLandscapeLeft);
    dict[@"deviceOrientationLandscapeRight"] = @(deviceOrientationLandscapeRight);
    dict[@"resourceAutoScaleFactor"] = @(resourceAutoScaleFactor);

    dict[@"cocos2dUpdateIgnoredVersions"] = _cocos2dUpdateIgnoredVersions;

    dict[@"designTarget"] = @(self.designTarget);
    dict[@"defaultOrientation"] = @(self.defaultOrientation);
    dict[@"deviceScaling"] = @(self.deviceScaling);

    dict[@"publishEnvironment"] = @(self.publishEnvironment);

    dict[@"excludedFromPackageMigration"] = @(self.excludedFromPackageMigration);

    if (_resourceProperties)
    {
        dict[@"resourceProperties"] = _resourceProperties;
    }
    else
    {
        dict[@"resourceProperties"] = [NSDictionary dictionary];
    }

    if (versionStr)
    {
        dict[@"versionStr"] = versionStr;
    }

    return dict;
}

@dynamic absoluteResourcePaths;
- (NSArray*) absoluteResourcePaths
{
    NSString* projectDirectory = [self.projectPath stringByDeletingLastPathComponent];
    
    NSMutableArray* paths = [NSMutableArray array];
    
    for (NSDictionary* dict in _resourcePaths)
    {
        NSString* path = dict[@"path"];
        NSString* absPath = [path absolutePathFromBaseDirPath:projectDirectory];
        [paths addObject:absPath];
    }
    
    if ([paths count] == 0)
    {
        [paths addObject:projectDirectory];
    }
    
    return paths;
}

@dynamic projectPathHashed;
- (NSString*) projectPathHashed
{
    if (projectPath)
    {
        HashValue* hash = [HashValue md5HashWithString:projectPath];
        return [hash description];
    }
    else
    {
        return NULL;
    }
}

@dynamic displayCacheDirectory;
- (NSString*) displayCacheDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [[[paths[0] stringByAppendingPathComponent:@"com.cocosbuilder.CocosBuilder"] stringByAppendingPathComponent:@"display"]stringByAppendingPathComponent:self.projectPathHashed];
}

@dynamic tempSpriteSheetCacheDirectory;
- (NSString*) tempSpriteSheetCacheDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [[paths[0] stringByAppendingPathComponent:@"com.cocosbuilder.CocosBuilder"] stringByAppendingPathComponent:@"spritesheet"];
}

- (void) _storeDelayed
{
    [self store];
    storing = NO;
}

- (BOOL) store
{
    return [[self serialize] writeToFile:self.projectPath atomically:YES];
}

- (void) storeDelayed
{
    // Store the file after a short delay
    if (!storing)
    {
        storing = YES;
        [self performSelector:@selector(_storeDelayed) withObject:NULL afterDelay:1];
    }
}

- (void) makeSmartSpriteSheet:(RMResource*) res
{
    NSAssert(res.type == kCCBResTypeDirectory, @"Resource must be directory");

    [self setValue:@YES forResource:res andKey:@"isSmartSpriteSheet"];
    
    [self store];
    [[ResourceManager sharedManager] notifyResourceObserversResourceListUpdated];
    [[AppDelegate appDelegate].projectOutlineHandler updateSelectionPreview];
}

- (void) removeSmartSpriteSheet:(RMResource*) res
{
    NSAssert(res.type == kCCBResTypeDirectory, @"Resource must be directory");
    
    [self removeObjectForResource:res andKey:@"isSmartSpriteSheet"];

    [self removeIntermediateFileLookupFile:res];

    [self store];
    [[ResourceManager sharedManager] notifyResourceObserversResourceListUpdated];
    [[AppDelegate appDelegate].projectOutlineHandler updateSelectionPreview];
}

- (void)removeIntermediateFileLookupFile:(RMResource *)res
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *intermediateFileLookup = [res.filePath stringByAppendingPathComponent:INTERMEDIATE_FILE_LOOKUP_NAME];
    if ([fileManager fileExistsAtPath:intermediateFileLookup])
    {
        NSError *error;
        if (![fileManager removeItemAtPath:intermediateFileLookup error:&error])
        {
            NSLog(@"Error removing intermediate filelookup file %@ - %@", intermediateFileLookup, error);
        }
    }
}

- (void) setValue:(id) val forResource:(RMResource*) res andKey:(id) key
{
    NSString* relPath = res.relativePath;
    [self setValue:val forRelPath:relPath andKey:key];
    [self markAsDirtyResource:res];
}

- (void) setValue:(id)val forRelPath:(NSString *)relPath andKey:(id)key
{
    // Create value if it doesn't exist
    NSMutableDictionary* props = [_resourceProperties valueForKey:relPath];
    if (!props)
    {
        props = [NSMutableDictionary dictionary];
        [_resourceProperties setValue:props forKey:relPath];
    }
    
    // Compare to old value
    id oldValue = props[key];
    if (!(oldValue && [oldValue isEqual:val]))
    {
        // Set the value if it has changed
        [props setValue:val forKey:key];
        
        // Also mark as dirty
        [props setValue:@YES forKey:@"isDirty"];
        
        [self storeDelayed];
    }
}

- (id) valueForResource:(RMResource*) res andKey:(id) key
{
    NSString* relPath = [self findRelativePathInPackagesForAbsolutePath:res.filePath];
    return [self valueForRelPath:relPath andKey:key];
}

- (id) valueForRelPath:(NSString*) relPath andKey:(id) key
{
    NSMutableDictionary* props = [_resourceProperties valueForKey:relPath];
    return [props valueForKey:key];
}

- (void) removeObjectForResource:(RMResource*) res andKey:(id) key
{
    NSString* relPath = res.relativePath;
    [self markAsDirtyResource:res];
    [self removeObjectForRelPath:relPath andKey:key];
    
}

- (void) removeObjectForRelPath:(NSString*) relPath andKey:(id) key
{
    NSMutableDictionary* props = [_resourceProperties valueForKey:relPath];
    [props removeObjectForKey:key];
    
    [self storeDelayed];
}

- (BOOL) isDirtyResource:(RMResource*) res
{
    return [self isDirtyRelPath:res.relativePath];
}

- (BOOL) isDirtyRelPath:(NSString*) relPath
{
    return [[self valueForRelPath:relPath andKey:@"isDirty"] boolValue];
}

- (void) markAsDirtyResource:(RMResource*) res
{
    [self markAsDirtyRelPath:res.relativePath];
}

- (void) markAsDirtyRelPath:(NSString*) relPath
{
    [self setValue:@YES forRelPath:relPath andKey:@"isDirty"];
}

- (void) clearAllDirtyMarkers
{
    for (NSString* relPath in _resourceProperties)
    {
        [self removeObjectForRelPath:relPath andKey:@"isDirty"];
    }
    
    [self storeDelayed];
}

- (NSArray*) smartSpriteSheetDirectories
{
    NSMutableArray* dirs = [NSMutableArray array];
    for (NSString* relPath in _resourceProperties)
    {
        if ([[_resourceProperties[relPath] objectForKey:@"isSmartSpriteSheet"] boolValue])
        {
            [dirs addObject:relPath];
        }
    }
    return dirs;
}


- (void) removedResourceAt:(NSString*) relPath
{
    [_resourceProperties removeObjectForKey:relPath];
}

- (void) movedResourceFrom:(NSString*) relPathOld to:(NSString*) relPathNew
{
    id props = _resourceProperties[relPathOld];
    if (props)
    {
        _resourceProperties[relPathNew] = props;
    }
    [_resourceProperties removeObjectForKey:relPathOld];
}

- (BOOL)removeResourcePath:(NSString *)path error:(NSError **)error
{
    NSString *projectDir = [self.projectPath stringByDeletingLastPathComponent];
    NSString *relResourcePath = [path relativePathFromBaseDirPath:projectDir];

    for (NSMutableDictionary *resourcePath in [_resourcePaths copy])
    {
        NSString *relPath = resourcePath[@"path"];
        if ([relPath isEqualToString:relResourcePath])
        {
            [_resourcePaths removeObject:resourcePath];
            return YES;
        }
    }

    [NSError setNewErrorWithCode:error
                            code:SBResourcePathNotInProjectError
                         message:[NSString stringWithFormat:@"Cannot remove path \"%@\" does not exist in project.", relResourcePath]];
    return NO;
}

- (BOOL)addResourcePath:(NSString *)path error:(NSError **)error
{
    if (![self isResourcePathInProject:path])
    {
        NSString *relResourcePath = [path relativePathFromBaseDirPath:self.projectPathDir];

        [_resourcePaths addObject:[@{@"path" : relResourcePath} mutableCopy]];
        return YES;
    }
    else
    {
        [NSError setNewErrorWithCode:error code:SBDuplicateResourcePathError message:[NSString stringWithFormat:@"Cannot create %@, already present.", [path lastPathComponent]]];
        return NO;
    }
}

- (BOOL)isResourcePathInProject:(NSString *)resourcePath
{
    NSString *relResourcePath = [resourcePath relativePathFromBaseDirPath:self.projectPathDir];

    return [self resourcePathForRelativePath:relResourcePath] != nil;
}

- (NSMutableDictionary *)resourcePathForRelativePath:(NSString *)path
{
    for (NSMutableDictionary *resourcePath in _resourcePaths)
    {
        NSString *aResourcePath = resourcePath[@"path"];
        if ([aResourcePath isEqualToString:path])
        {
            return resourcePath;
        }
    }
    return nil;
}

- (BOOL)moveResourcePathFrom:(NSString *)fromPath toPath:(NSString *)toPath error:(NSError **)error
{
    if ([self isResourcePathInProject:toPath])
    {
        [NSError setNewErrorWithCode:error code:SBDuplicateResourcePathError message:@"Cannot move resource path, there's already one with the same name."];
        return NO;
    }

    NSString *relResourcePathOld = [fromPath relativePathFromBaseDirPath:self.projectPathDir];
    NSString *relResourcePathNew = [toPath relativePathFromBaseDirPath:self.projectPathDir];

    NSMutableDictionary *resourcePath = [self resourcePathForRelativePath:relResourcePathOld];
    resourcePath[@"path"] = relResourcePathNew;

    [self movedResourceFrom:relResourcePathOld to:relResourcePathNew];
    return YES;
}

- (void) detectBrowserPresence
{
    isSafariExist = FALSE;
    isChromeExist = FALSE;
    isFirefoxExist = FALSE;
    
    OSStatus result = LSFindApplicationForInfo (kLSUnknownCreator, CFSTR("com.apple.Safari"), NULL, NULL, NULL);
    if (result == noErr)
    {
        isSafariExist = TRUE;
    }
    
    result = LSFindApplicationForInfo (kLSUnknownCreator, CFSTR("com.google.Chrome"), NULL, NULL, NULL);
    if (result == noErr)
    {
        isChromeExist = TRUE;
    }

    result = LSFindApplicationForInfo (kLSUnknownCreator, CFSTR("org.mozilla.firefox"), NULL, NULL, NULL);
    if (result == noErr)
    {
        isFirefoxExist = TRUE;
    }
}

// TODO: remove after transition state to ResourcePath class
- (NSString *)fullPathForResourcePathDict:(NSMutableDictionary *)resourcePathDict
{
    return [self.projectPathDir stringByAppendingPathComponent:resourcePathDict[@"path"]];
}

- (NSString* ) getVersion
{
	NSDictionary * versionDict = [self getVersionDictionary];
	NSString * versionString = @"";
	
	for (NSString * key in versionDict) {
		versionString = [versionString stringByAppendingFormat:@"%@ : %@\n", key, versionDict[key]];
	}
    
    return versionString;
}

- (NSDictionary *)getVersionDictionary
{
	NSString* versionPath = [[NSBundle mainBundle] pathForResource:@"Version" ofType:@"txt" inDirectory:@"Generated"];
    NSString* version = [NSString stringWithContentsOfFile:versionPath encoding:NSUTF8StringEncoding error:NULL];
	
	
	NSData* versionData = [version dataUsingEncoding:NSUTF8StringEncoding];
	NSError * error;
	NSDictionary * versionDict = [NSJSONSerialization JSONObjectWithData:versionData options:0x0 error:&error];

	return versionDict;

}



- (void)setCocos2dUpdateIgnoredVersions:(NSMutableArray *)anArray
{
    _cocos2dUpdateIgnoredVersions = !anArray
        ? [NSMutableArray array]
        : anArray;
}

-(void) setPublishResolution_ios_phone:(BOOL)publishResolution
{
	if (_engine != CCBTargetEngineSpriteKit)
	{
		publishResolution_ios_phone = publishResolution;
	}
	else
	{
		// Sprite Kit doesn't run on non-Retina phones to begin with...
		publishResolution_ios_phone = NO;
	}
}

- (void)flagFilesDirtyWithWarnings:(CCBWarnings *)warnings
{
	for (CCBWarning *warning in warnings.warnings)
	{
		if (warning.relatedFile)
		{
			[self markAsDirtyRelPath:warning.relatedFile];
		}
	}
}

- (NSString *)projectPathDir
{
    return [projectPath stringByDeletingLastPathComponent];
}

- (NSString *)findRelativePathInPackagesForAbsolutePath:(NSString *)absolutePath
{
    for (NSString *absoluteResourcePath in self.absoluteResourcePaths)
    {
        if ([absolutePath hasPrefix:absoluteResourcePath])
        {
            return [absolutePath substringFromIndex:[absoluteResourcePath length] + 1];
        }
    }

    return nil;
}

@end
