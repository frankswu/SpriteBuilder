#import "PublishRegularFileOperation.h"

#import "CCBFileUtil.h"
#import "PublishingTaskStatusProgress.h"


@implementation PublishRegularFileOperation

- (void)main
{
    NSLog(@"[%@] %@", [self class], [self description]);

    [self publishRegularFile];

    [_publishingTaskStatusProgress taskFinished];
}

- (void)publishRegularFile
{
    // Check if file already exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:_dstFilePath] &&
        [[CCBFileUtil modificationDateForFile:_srcFilePath] isEqualToDate:[CCBFileUtil modificationDateForFile:_dstFilePath]])
    {
        return;
    }

    // Copy file and make sure modification date is the same as for src file
    [[NSFileManager defaultManager] removeItemAtPath:_dstFilePath error:NULL];
    [[NSFileManager defaultManager] copyItemAtPath:_srcFilePath toPath:_dstFilePath error:NULL];
    [CCBFileUtil setModificationDate:[CCBFileUtil modificationDateForFile:_srcFilePath] forFile:_dstFilePath];
}

- (void)cancel
{
    [super cancel];
    NSLog(@"[%@] CANCELLED %@", [self class], [_srcFilePath lastPathComponent]);
- (NSString *)description
{
    return [NSString stringWithFormat:@"src: %@, dst: %@, srcfull: %@, dstfull: %@", [_srcFilePath lastPathComponent], [_dstFilePath lastPathComponent], _srcFilePath, _dstFilePath];
}

@end