//
//  ObjcCompatibilityTests.m
//  
//
//  Created by Mathew Gacy on 10/5/21.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
@import BlueTriangle;

@interface ObjcCompatibilityTests : XCTestCase
@end

@implementation ObjcCompatibilityTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCompatibility {
    // Configuration
    [BlueTriangle configure:^ (BlueTriangleConfiguration* config) {
        config.siteID = @"MY_SITE_ID";
        //config.sessionID = 1111;
        config.globalUserID = 2222;
        config.isReturningVisitor = YES;
        config.abTestID = @"";
        config.abTestID = @"MY_AB_TEST_ID";
        config.campaignMedium = @"MY_CAMPAIGN_MEDIUM";
        config.campaignName = @"MY_CAMPAIGN_NAME";
        config.campaignSource = @"MY_CAMPAIGN_SOURCE";
        config.dataCenter = @"MY_DATA_CENTER";
        config.trafficSegmentName = @"MY_TRAFFIC_SEGMENT";
        config.crashTracking = CrashTrackingNsException;
        config.performanceMonitorSampleRate = 1.5;
        config.networkSampleRate = 1.0;
    }];

    // Timer
    CustomCategories *customCategories = [[CustomCategories alloc] initWithCv6:@"" cv7:@"" cv8:@"" cv9:@"" cv10:@""];
    CustomNumbers *customNumbers = [[CustomNumbers alloc] initWithCn1:1.1 cn2:2.2 cn3:3.3 cn4:4.4 cn5:5.5 cn6:6.6 cn7:7.7 cn8:8.8 cn9:9.9 cn10:10.1 cn11:11.1 cn12:12.2 cn13:13.3 cn14:14.4 cn15:15.5 cn16:16.6 cn17:17.7 cn18:18.8 cn19:19.9 cn20:20.0];
    CustomVariables *customVariables = [[CustomVariables alloc] initWithCv1:@"" cv2:@"" cv3:@"" cv4:@"" cv5:@"" cv11:@"" cv12:@"" cv13:@"" cv14:@"" cv15:@""];

    NSNumber *brandValue = [NSNumber numberWithDouble:20.89];
    Page *page = [[Page alloc] initWithPageName:@"MY_SITE_ID" brandValue:brandValue.decimalValue pageType:@"PAGE_TYPE" referringURL:@"REFERRING_URL" url:@"URL" customVariables:customVariables customCategories:customCategories customNumbers:customNumbers];

    NSNumber *cartValue = [NSNumber numberWithDouble:10.99];
    
    PurchaseConfirmation *purchaseConfirmation = [[PurchaseConfirmation alloc] initWithCartValue:cartValue.decimalValue cartCount:2 cartCountCheckout:2 orderNumber:@"MY_ORDER_NUMBER"];
    
    BTTimer *timer = [BlueTriangle makeTimerWithPage:page timerType:TimerTypeMain];

    [timer start];

    [timer markInteractive];

    [timer end];

    [BlueTriangle endTimer:timer purchaseConfirmation:purchaseConfirmation];

    BTTimer *timer2 = [BlueTriangle startTimerWithPage:page timerType:TimerTypeCustom];

    [BlueTriangle endTimer:timer2 purchaseConfirmation:nil];

    // Network Capture
    BTTimer *timer3 = [BlueTriangle makeTimerWithPage:page timerType:TimerTypeMain];

    NSURLSession *session = [NSURLSession sharedSession];

    NSURL *url = [NSURL URLWithString:@"http://www.example.com"];
    NSURLSessionDataTask *taskWithURL = [session btDataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){}];

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
    [urlRequest setHTTPMethod:@"GET"];
    NSURLSessionDataTask *taskWithRequest = [session btDataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){}];
}

@end
