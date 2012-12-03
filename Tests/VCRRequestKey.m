//
//  VCRRequest.m
//  Tests
//
//  Created by Dustin Barker on 12/2/12.
//
//

#import "VCRRequestKey.h"

@interface VCRRequestKey ()
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *method;
@end

@implementation VCRRequestKey

+ (VCRRequestKey *)keyForRequest:(NSURLRequest *)request {
    VCRRequestKey *key = [[[VCRRequestKey alloc] init] autorelease];
    key.url = request.URL;
    key.method = request.HTTPMethod;
    return key;
}

- (BOOL)isEqual:(VCRRequestKey *)key {
    return self.method == key.method && self.url == key.url;
}

- (NSUInteger)hash {
    return [self.method hash] ^ [self.url hash];
}

- (id)copyWithZone:(NSZone *)zone {
    VCRRequestKey *key = [[[self class] alloc] init];
    if (key) {
        key.url = [[self.url copyWithZone:zone] autorelease];
        key.method = [[self.method copyWithZone:zone] autorelease];
    }
    return key;
}

@end
