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

    // throw if index.js has failed to pass a complete options object
    if (!(options[@"endpoint"] != nil &&
          options[@"namespace"] != nil &&
          options[@"appId"] != nil &&
          options[@"method"] != nil &&
          options[@"protocol"] != nil &&
          options[@"setBase64Encoded"] != nil &&
          options[@"setPlatformContext"] != nil &&
          // options[@"autoScreenView"] != nil && -- to be removed
          options[@"setApplicationContext"] != nil &&
          options[@"setLifecycleEvents"] != nil &&
          options[@"setScreenContext"] != nil &&
          options[@"setSessionContext"] != nil &&
          options[@"foregroundTimeout"] != nil &&
          options[@"backgroundTimeout"] != nil &&
          options[@"checkInterval"] != nil &&
          options[@"setInstallEvent"] != nil
        )) {
      NSError * error = [NSError errorWithDomain:@"SnowplowTracker" code:100 userInfo:nil];
      reject(@"ERROR", @"SnowplowTracker: initialize() method - missing parameter with no default found", error);
    }

    SPSubject *subject = [[SPSubject alloc] initWithPlatformContext:options[@"setPlatformContext"] andGeoContext:NO];

    SPEmitter *emitter = [SPEmitter build:^(id<SPEmitterBuilder> builder) {
        [builder setUrlEndpoint:options[@"endpoint"]];
        [builder setHttpMethod:([@"post" caseInsensitiveCompare:options[@"method"]] == NSOrderedSame) ? SPRequestPost : SPRequestGet];
        [builder setProtocol:([@"https" caseInsensitiveCompare:options[@"protocol"]] == NSOrderedSame) ? SPHttps : SPHttp];
    }];
    self.tracker = [SPTracker build:^(id<SPTrackerBuilder> builder) {
        [builder setEmitter:emitter];
        [builder setAppId:options[@"appId"]];
        [builder setBase64Encoded:options[@"setBase64Encoded"]];
        [builder setTrackerNamespace:options[@"namespace"]];
        // [builder setAutotrackScreenViews:options[@"autoScreenView"]]; -- to be removed
        [builder setApplicationContext:options[@"setApplicationContext"]];
        [builder setLifecycleEvents:options[@"setLifecycleEvents"]];
        [builder setScreenContext:options[@"setScreenContext"]];
        [builder setInstallEvent:options[@"setInstallEvent"]];
        [builder setSubject:subject];
        // setSessionContextui
        if ([options[@"setSessionContext"] boolValue]) {
          [builder setSessionContext:options[@"setSessionContext"]];
          [builder setCheckInterval:[options[@"checkInterval"] integerValue]];
          [builder setForegroundTimeout:[options[@"foregroundTimeout"] integerValue]];
          [builder setBackgroundTimeout:[options[@"backgroundTimeout"] integerValue]];
        }
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

    if (!(details[@"category"] != nil &&
          details[@"action"] != nil &&
          details[@"label"] != nil &&
          details[@"property"] != nil // 'value' key deliberately removed if null/undefined, so no check on that.
        )) {
          NSError * error = [NSError errorWithDomain:@"SnowplowTracker" code:100 userInfo:nil];
          reject(@"ERROR", @"SnowplowTracker: trackStructuredEvent() method - missing parameter with no default found", error);
        }

    SPStructured * trackerEvent = [SPStructured build:^(id<SPStructuredBuilder> builder) {
        [builder setCategory:details[@"category"]];
        [builder setAction:details[@"action"]];
        [builder setValue:[details[@"value"] doubleValue]];
        [builder setLabel:details[@"label"]];
        [builder setProperty:details[@"property"]];
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

    if (!(details[@"screenName"] != nil &&
          details[@"screenId"] != nil &&
          details[@"screenType"] != nil &&
          details[@"previousScreenName"] != nil &&
          details[@"previousScreenType"] != nil &&
          details[@"previousScreenId"] != nil &&
          details[@"transitionType"] != nil
    )) {
      NSError * error = [NSError errorWithDomain:@"SnowplowTracker" code:100 userInfo:nil];
      reject(@"ERROR", @"SnowplowTracker: trackScreenViewEvent() method - missing parameter with no default found", error);
    }

    SPScreenView * SVevent = [SPScreenView build:^(id<SPScreenViewBuilder> builder) {
        [builder setName:details[@"screenName"]];
        if (details[@"screenId"] != (id)[NSNull null]) [builder setScreenId:details[@"screenId"]];
        if (details[@"screenType"] != (id)[NSNull null]) [builder setType:details[@"screenType"]];
        if (details[@"previousScreenName"] != (id)[NSNull null]) [builder setPreviousScreenName:details[@"previousScreenName"]];
        if (details[@"previousScreenType"] != (id)[NSNull null]) [builder setPreviousScreenType:details[@"previousScreenType"]];
        if (details[@"previousScreenId"] != (id)[NSNull null]) [builder setPreviousScreenId:details[@"previousScreenId"]];
        if (details[@"transitionType"] != (id)[NSNull null]) [builder setTransitionType:details[@"transitionType"]];
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

    if (!(details[@"pageUrl"] != nil &&
          details[@"pageTitle"] != nil &&
          details[@"pageReferrer"] != nil
    )) {
      NSError * error = [NSError errorWithDomain:@"SnowplowTracker" code:100 userInfo:nil];
      reject(@"ERROR", @"SnowplowTracker: trackScreenViewEvent() method - missing parameter with no default found", error);
    }

    SPPageView * trackerEvent = [SPPageView build:^(id<SPPageViewBuilder> builder) {
        [builder setPageUrl:details[@"pageUrl"]];
        [builder setPageTitle:details[@"pageTitle"]];
        [builder setReferrer:details[@"pageReferrer"]];
        if (contexts) {
            [builder setContexts:[[NSMutableArray alloc] initWithArray:contexts]];
        }
    }];
    [self.tracker trackPageViewEvent:trackerEvent];
}

@end
