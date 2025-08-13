//
// VCRCassetteManager.m
//
// Copyright (c) 2012 Dustin Barker
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "VCRCassetteManager.h"
#import "VCRCassette.h"

@interface VCRCassetteManager () {
    VCRCassette *_cassette;
    dispatch_queue_t _cassetteQueue;
}

@property (nonatomic, strong) NSURL *currentCassetteURL;

@end

@implementation VCRCassetteManager

@dynamic currentCassette;

+ (VCRCassetteManager *)defaultManager {
    static VCRCassetteManager *_defaultManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _defaultManager = [[self alloc] init];
    });

    return _defaultManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cassetteQueue = dispatch_queue_create("com.vcrcassette.manager.cassetteQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

// Thread-safe setter for cassette
- (void)setCassette:(VCRCassette *)cassette {
    dispatch_barrier_async(_cassetteQueue, ^{
        _cassette = cassette;
    });
}

// Thread-safe getter for cassette
- (VCRCassette *)cassette {
    __block VCRCassette *cassette;
    dispatch_sync(_cassetteQueue, ^{
        cassette = _cassette;
    });
    return cassette;
}

- (void)setCurrentCassetteURL:(NSURL *)url {
    [self setCassette:nil];
    _currentCassetteURL = url;
}

- (VCRCassette *)currentCassette {
    VCRCassette *cassette = [self cassette];

    NSURL *url = self.currentCassetteURL;

    if (cassette) {
        // do nothing
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        NSData *data = [NSData dataWithContentsOfURL:url];
        cassette = [[VCRCassette alloc] initWithData:data];
    } else {
        cassette = [VCRCassette cassette];
    }

    [self setCassette:cassette];

    return cassette;
}

- (void)setCurrentCassette:(VCRCassette *)cassette {
    [self setCassette:cassette];
}

- (void)save:(NSString *)path {
    VCRCassette *cassette = [self cassette];
    NSData *data = [cassette data];
    [data writeToFile:path atomically:YES];
}

@end
