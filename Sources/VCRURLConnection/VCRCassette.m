//
// VCRCassette.m
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

#import "VCRCassette.h"
#import "VCRCassette_Private.h"
#import "VCRRequestKey.h"


@implementation VCRCassette

+ (VCRCassette *)cassette {
    return [[VCRCassette alloc] init];
}

+ (VCRCassette *)cassetteWithURL:(NSURL *)url {
    NSData *data = [NSData dataWithContentsOfURL:url];
    return [[VCRCassette alloc] initWithData:data];
}

- (id)init {
    if ((self = [super init])) {
        self.responseDictionary = [NSMutableDictionary dictionary];
        self.regexRecordings = [NSMutableArray array];
        self.synchronizationQueue = dispatch_queue_create("com.vcr.cassette.sync", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (id)initWithJSON:(id)json {
    NSAssert(json != nil, @"Attempted to intialize VCRCassette with nil JSON");
    if ((self = [self init])) {
        for (id recordingJSON in json) {
            VCRRecording *recording = [[VCRRecording alloc] initWithJSON:recordingJSON];
            [self addRecording:recording];
        }
    }
    return self;
}

- (id)initWithData:(NSData *)data {
    NSError *error = nil;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    NSAssert([error code] == 0, @"Attempted to initialize VCRCassette with invalid JSON");
    return [self initWithJSON:json];

}

- (void)addRecording:(VCRRecording *)recording {
    dispatch_async(self.synchronizationQueue, ^{
        if (recording.URI) {
            VCRRequestKey *key = [VCRRequestKey keyForObject:recording];
            NSMutableArray * recordings = [self.responseDictionary objectForKey:key];

            if (recordings == NULL) {
                recordings = [[NSMutableArray alloc] init];
                [self.responseDictionary setObject:recordings forKey:key];
            }

            [recordings addObject:recording];
        } else {
            [self.regexRecordings addObject:recording];
        }
    });
}

- (VCRRecording *)recordingForRequestKey:(VCRRequestKey *)key replaying:(BOOL)replaying {
    __block VCRRecording *recording = nil;

    dispatch_sync(self.synchronizationQueue, ^{
        NSMutableArray *recordings = [self.responseDictionary objectForKey:key];

        if (recordings != NULL && recordings.count > 0) {
            recording = [recordings objectAtIndex:0];

            if (recordings.count > 1 && replaying) {
                [recordings removeObjectAtIndex:0];
            }
        }

        if (!recording) {
            // Create a copy of the array to safely enumerate
            NSArray *regexRecordingsCopy = [self.regexRecordings copy];
            for (VCRRecording *obj in regexRecordingsCopy) {
                if ([obj.method isEqualToString:key.method] && [obj.URIRegex numberOfMatchesInString:key.URI options:0 range:NSMakeRange(0, key.URI.length)] > 0) {
                    recording = obj;
                    break;
                }
            }
        }
    });

    return recording;
}

- (VCRRecording *)recordingForRequestKey:(VCRRequestKey *)key {
    return [self recordingForRequestKey:key replaying:NO];
}

- (VCRRecording *)recordingForRequest:(NSURLRequest *)request replaying:(BOOL)replaying {
    VCRRequestKey *key = [VCRRequestKey keyForObject:request];
    return [self recordingForRequestKey:key replaying:replaying];
}

- (VCRRecording *)recordingForRequest:(NSURLRequest *)request {
    return [self recordingForRequest:request replaying:NO];
}

- (id)JSON {
    __block NSMutableArray *recordings = nil;

    dispatch_sync(self.synchronizationQueue, ^{
        recordings = [NSMutableArray array];

        // Create copies to safely iterate
        NSDictionary *responseDictionaryCopy = [self.responseDictionary copy];
        for (NSArray *requestRecordings in responseDictionaryCopy.allValues) {
            for (VCRRecording *recording in requestRecordings) {
                [recordings addObject:[recording JSON]];
            }
        }

        NSArray *regexRecordingsCopy = [self.regexRecordings copy];
        for (VCRRecording *recording in regexRecordingsCopy) {
            [recordings addObject:[recording JSON]];
        }
    });

    return recordings;
}

- (NSData *)data {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self JSON]
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
    if ([error code] != 0) {
        NSLog(@"Error serializing json data %@", error);
    }
    return data;
}

- (BOOL)isEqual:(VCRCassette *)cassette {
    __block BOOL result = NO;

    dispatch_sync(self.synchronizationQueue, ^{
        dispatch_sync(cassette.synchronizationQueue, ^{
            result = [self.responseDictionary isEqual:cassette.responseDictionary];
        });
    });

    return result;
}

- (NSUInteger)hash {
    __block NSUInteger result = 0;

    dispatch_sync(self.synchronizationQueue, ^{
        result = [self.responseDictionary hash];
    });

    return result;
}

- (NSArray *)allKeys {
    __block NSArray *keys = nil;

    dispatch_sync(self.synchronizationQueue, ^{
        keys = [self.responseDictionary allKeys];
    });

    return keys;
}
@end
