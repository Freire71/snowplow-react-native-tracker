#import "RNSnowplowTracker.h"
#import <SnowplowTracker/SPTracker.h>
#import <SnowplowTracker/SPEmitter.h>
#import <SnowplowTracker/SPEvent.h>
#import <SnowplowTracker/SPSelfDescribingJson.h>
#import <SnowplowTracker/SPSubject.h>

@implementation RNSnowplowTracker

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(initialize
                  :(NSDictionary *)options
                  :rejecter:(RCTPromiseRejectBlock)reject
                ) {

    // required params
    __block NSString * endpoint;
    __block NSString * namespace;
    __block NSString * appId;

    if (options[@"endpoint"] != nil && options[@"namespace"] != nil && options[@"appId"] != nil) {
      endpoint = options[@"endpoint"];
      namespace = options[@"namespace"];
      appId = options[@"appId"];
    } else {
      NSError * error = [NSError errorWithDomain:@"SnowplowTracker" code:100 userInfo:nil];
      reject(@"ERROR", @"SnowplowTracker: initialize() requires endpoint, namespace and appId arguments to be set", error);
    }


    BOOL setPlatformContext = NO;
    BOOL setGeoLocationContext = NO;

    if ([options[@"setPlatformContext"] boolValue]) setPlatformContext = YES;

    // optional params
    NSString * method = options[@"method"];
    NSString * protocol = options[@"protocol"];

    SPSubject *subject = [[SPSubject alloc] initWithPlatformContext:setPlatformContext andGeoContext:setGeoLocationContext];

    SPEmitter *emitter = [SPEmitter build:^(id<SPEmitterBuilder> builder) {
        [builder setUrlEndpoint:endpoint];
        [builder setHttpMethod:([@"post" caseInsensitiveCompare:method] == NSOrderedSame) ? SPRequestPost : SPRequestGet];
        [builder setProtocol:([@"https" caseInsensitiveCompare:protocol] == NSOrderedSame) ? SPHttps : SPHttp];
    }];
    self.tracker = [SPTracker build:^(id<SPTrackerBuilder> builder) {
        [builder setEmitter:emitter];
        [builder setAppId:appId];
        // setBase64Encoded
        if ([options[@"setBase64Encoded"] boolValue]) {
            [builder setBase64Encoded:YES];
        }else [builder setBase64Encoded:NO];
        [builder setTrackerNamespace:namespace];
        [builder setAutotrackScreenViews:options[@"autoScreenView"]];
        // setApplicationContext
        if ([options[@"setApplicationContext"] boolValue]) {
            [builder setApplicationContext:YES];
        }else [builder setApplicationContext:NO];
        // setSessionContextui
        if ([options[@"setSessionContext"] boolValue]) {
            [builder setSessionContext:YES];
            if (options[@"checkInterval"] != nil) {
                [builder setCheckInterval:[options[@"checkInterval"] integerValue]];
            }else [builder setCheckInterval:15];
            if (options[@"foregroundTimeout"] != nil) {
                 [builder setForegroundTimeout:[options[@"foregroundTimeout"] integerValue]];
            }else [builder setForegroundTimeout:600];
            if (options[@"backgroundTimeout"] != nil) {
                 [builder setBackgroundTimeout:[options[@"backgroundTimeout"] integerValue]];
            }else [builder setBackgroundTimeout:300];
        }else [builder setSessionContext:NO];
        // setLifecycleEvents
        if ([options[@"setLifecycleEvents"] boolValue]) {
            [builder setLifecycleEvents:YES];
        }else [builder setLifecycleEvents:NO];
        // setScreenContext
        if ([options[@"setScreenContext"] boolValue]) {
            [builder setScreenContext:YES];
        }else [builder setScreenContext:NO];
        //setInstallEvent
        if ([options[@"setInstallEvent"] boolValue]) {
            [builder setInstallEvent:YES];
        }else [builder setInstallEvent:NO];
        [builder setSubject:subject];
    }];
}

RCT_EXPORT_METHOD(setSubjectData :(NSDictionary *)options) {
      if (options[@"userId"] != nil) {
              [self.tracker.subject setUserId:options[@"userId"]];
      }
      if (options[@"screenWidth"] != nil && options[@"screenHeight"] != nil) {
          [self.tracker.subject setResolutionWithWidth:[options[@"screenWidth"] integerValue] andHeight:[options[@"screenHeight"] integerValue]];
      }
      if (options[@"viewportWidth"] != nil && options[@"viewportHeight"] != nil) {
          [self.tracker.subject setViewPortWithWidth:[options[@"viewportWidth"] integerValue] andHeight:[options[@"viewportHeight"] integerValue]];
      }
      if (options[@"colorDepth"] != nil) {
          [self.tracker.subject setColorDepth:[options[@"colorDepth"] integerValue]];
      }
      if (options[@"timezone"] != nil) {
          [self.tracker.subject setTimezone:options[@"timezone"]];
      }
      if (options[@"language"] != nil) {
          [self.tracker.subject setLanguage:options[@"language"]];
      }
      if (options[@"ipAddress"] != nil) {
          [self.tracker.subject setIpAddress:options[@"ipAddress"]];
      }
      if (options[@"useragent"] != nil) {
          [self.tracker.subject setUseragent:options[@"useragent"]];
      }
      if (options[@"networkUserId"] != nil) {
          [self.tracker.subject setNetworkUserId:options[@"networkUserId"]];
      }
      if (options[@"domainUserId"] != nil) {
          [self.tracker.subject setDomainUserId:options[@"domainUserId"]];
      }
}

RCT_EXPORT_METHOD(trackSelfDescribingEvent
                  :(nonnull SPSelfDescribingJson *)event
                  :(NSArray<SPSelfDescribingJson *> *)contexts) {
    SPUnstructured * unstructEvent = [SPUnstructured build:^(id<SPUnstructuredBuilder> builder) {
        [builder setEventData:event];
        if (contexts) {
            [builder setContexts:[[NSMutableArray alloc] initWithArray:contexts]];
        }
    }];
    [self.tracker trackUnstructuredEvent:unstructEvent];
}

RCT_EXPORT_METHOD(trackStructuredEvent
                  :(NSDictionary *)details
                  :(NSArray<SPSelfDescribingJson *> *)contexts
                  :rejecter:(RCTPromiseRejectBlock)reject) {

    // required
    __block NSString * category;
    __block NSString * action;

    if (details[@"category"] != nil && details[@"action"] != nil) {
      category = details[@"category"];
      action = details[@"action"];
    } else {
      NSError * error = [NSError errorWithDomain:@"SnowplowTracker" code:100 userInfo:nil];
      reject(@"ERROR", @"SnowplowTracker: trackStructuredEvent() requires category and action arguments to be set", error);
    }

    NSString * label = details[@"label"];
    NSString * property = details[@"property"];
    NSNumber * v = details[@"value"];
    double value = [v doubleValue];

    SPStructured * trackerEvent = [SPStructured build:^(id<SPStructuredBuilder> builder) {
        [builder setCategory:category];
        [builder setAction:action];
        [builder setValue:value];
        if (label != nil) [builder setLabel:label];
        if (property != nil) [builder setProperty:property];
        if (contexts) {
            [builder setContexts:[[NSMutableArray alloc] initWithArray:contexts]];
        }
    }];
    [self.tracker trackStructuredEvent:trackerEvent];
}

RCT_EXPORT_METHOD(trackScreenViewEvent

                  :(NSDictionary *)details
                  :(NSArray<SPSelfDescribingJson *> *)contexts
                  :rejecter:(RCTPromiseRejectBlock)reject) {

    // required params
    __block NSString * screenName;

    if (details[@"screenName"] != nil) {
      screenName = details[@"screenName"];
    } else {
      NSError * error = [NSError errorWithDomain:@"SnowplowTracker" code:100 userInfo:nil];
      reject(@"ERROR", @"SnowplowTracker: trackScreenViewEvent() requires screenName to be set", error);
      return;
    }

    // optional params
    NSString * screenId = details[@"screenId"];
    NSString * screenType = details[@"screenType"];
    NSString * previousScreenName = details[@"previousScreenName"];
    NSString * previousScreenType = details[@"previousScreenType"];
    NSString * previousScreenId = details[@"previousScreenId"];
    NSString * transitionType = details[@"transitionType"];

    SPScreenView * SVevent = [SPScreenView build:^(id<SPScreenViewBuilder> builder) {
        [builder setName:screenName];
        if (screenId != nil) [builder setScreenId:screenId];
        if (screenType != nil) [builder setType:screenType];
        if (previousScreenName != nil) [builder setPreviousScreenName:previousScreenName];
        if (previousScreenType != nil) [builder setPreviousScreenType:previousScreenType];
        if (previousScreenId != nil) [builder setPreviousScreenId:previousScreenId];
        if (transitionType != nil) [builder setTransitionType:transitionType];
        if (contexts) {
            [builder setContexts:[[NSMutableArray alloc] initWithArray:contexts]];
        }
      }];
      [self.tracker trackScreenViewEvent:SVevent];
}

RCT_EXPORT_METHOD(trackPageViewEvent
                  :(NSDictionary *)details
                  :(NSArray<SPSelfDescribingJson *> *)contexts
                  :rejecter:(RCTPromiseRejectBlock)reject) {

    // required params
    __block NSString * pageUrl;

    if (details[@"pageUrl"] != nil) {
      pageUrl = details[@"pageUrl"];
    } else {
      NSError * error = [NSError errorWithDomain:@"SnowplowTracker" code:100 userInfo:nil];
      reject(@"ERROR", @"SnowplowTracker: trackPageViewEvent() requires pageUrl to be set", error);
      return;
    }

    // optional params
    NSString * pageTitle = details[@"pageTitle"];
    NSString * pageReferrer = details[@"pageReferrer"];

    SPPageView * trackerEvent = [SPPageView build:^(id<SPPageViewBuilder> builder) {
        [builder setPageUrl:pageUrl];
        if (pageTitle != nil) [builder setPageTitle:pageTitle];
        if (pageReferrer != nil) [builder setReferrer:pageReferrer];
        if (contexts) {
            [builder setContexts:[[NSMutableArray alloc] initWithArray:contexts]];
        }
    }];
    [self.tracker trackPageViewEvent:trackerEvent];
}

@end
