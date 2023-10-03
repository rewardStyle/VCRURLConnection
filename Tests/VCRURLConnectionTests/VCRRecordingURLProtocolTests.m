//
//  VCRRecordingURLProtocolTests.m
//  VCRURLConnection
//
//  Created by Dustin Barker on 1/3/14.
//
//

@import XCTest;
@import VCRURLConnection;

@interface VCRRecordingURLProtocolTests : XCTestCase

@end

@implementation VCRRecordingURLProtocolTests

- (void)testCanInitWithRequest {
    [VCR start];
    NSURL *url = [NSURL URLWithString:@"http://www.example.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    XCTAssert([VCRRecordingURLProtocol canInitWithRequest:request], @"");
}

- (void)testCannotInitWithRequest {
    [VCR stop];
    NSURL *url = [NSURL URLWithString:@"http://www.example.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    XCTAssertFalse([VCRRecordingURLProtocol canInitWithRequest:request], @"");
}

@end
