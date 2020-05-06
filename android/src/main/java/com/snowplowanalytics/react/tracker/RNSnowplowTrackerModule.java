
package com.snowplowanalytics.react.tracker;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.snowplowanalytics.react.util.EventUtil;
import com.snowplowanalytics.snowplow.tracker.Emitter;
import com.snowplowanalytics.snowplow.tracker.Tracker;
import com.snowplowanalytics.snowplow.tracker.emitter.HttpMethod;
import com.snowplowanalytics.snowplow.tracker.emitter.RequestSecurity;
import com.snowplowanalytics.snowplow.tracker.events.SelfDescribing;
import com.snowplowanalytics.snowplow.tracker.events.Structured;
import com.snowplowanalytics.snowplow.tracker.events.ScreenView;
import com.snowplowanalytics.snowplow.tracker.events.PageView;

public class RNSnowplowTrackerModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;
    private Tracker tracker;
    private Emitter emitter;

    public RNSnowplowTrackerModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "RNSnowplowTracker";
    }

    @ReactMethod
    public void initialize(ReadableMap options,
                           Promise promise) {

        // required params
        String endpoint;
        String namespace;
        String appId;

        try {
          endpoint = options.getString("endpoint");
          namespace = options.getString("namespace");
          appId = options.getString("appId");
        } catch (Exception e) {
          promise.reject("ERROR", "SnowplowTracker: initialize() requires endpoint, namespace and appId arguments to be set");
          return;
        }

        // optional params
        String method = options.hasKey("method") ? options.getString("method") : "post";
        String protocol = options.hasKey("protocol") ? options.getString("protocol") : "https";

        this.emitter = new Emitter.EmitterBuilder(endpoint, this.reactContext)
                .method(method.equalsIgnoreCase("post") ? HttpMethod.POST : HttpMethod.GET)
                .security(protocol.equalsIgnoreCase("https") ? RequestSecurity.HTTPS : RequestSecurity.HTTP)
                .build();
        this.emitter.waitForEventStore();

        com.snowplowanalytics.snowplow.tracker.Subject subject = new com.snowplowanalytics.snowplow.tracker.Subject.SubjectBuilder()
                .build();

        this.tracker = Tracker.init(new Tracker
                .TrackerBuilder(this.emitter, namespace, appId, this.reactContext)
                // setSubject/UserID
                .subject(subject)
                // setBase64Encoded
                .base64(options.hasKey("setBase64Encoded") ? options.getBoolean("setBase64Encoded") : false)
                // setPlatformContext
                .mobileContext(options.hasKey("setPlatformContext") ? options.getBoolean("setPlatformContext") : false)
                .screenviewEvents(options.hasKey("autoScreenView") ? options.getBoolean("autoScreenView") : false)
                // setApplicationContext
                .applicationContext(options.hasKey("setApplicationContext") ? options.getBoolean("setApplicationContext") : false)
                // setSessionContext
                .sessionContext(options.hasKey("setSessionContext") ? options.getBoolean("setSessionContext") : false)
                .sessionCheckInterval(options.hasKey("checkInterval") ? options.getInt("checkInterval") : 15)
                .foregroundTimeout(options.hasKey("foregroundTimeout") ? options.getInt("foregroundTimeout") : 600)
                .backgroundTimeout(options.hasKey("backgroundTimeout") ? options.getInt("backgroundTimeout") : 300)
                // setLifecycleEvents
                .lifecycleEvents(options.hasKey("setLifecycleEvents") ? options.getBoolean("setLifecycleEvents") : false)
                // setScreenContext
                .screenContext(options.hasKey("setScreenContext") ? options.getBoolean("setScreenContext") : false)
                // setInstallEvent
                .installTracking(options.hasKey("setInstallEvent") ? options.getBoolean("setInstallEvent") : false)
                .build()
        );
    }

    @ReactMethod
    public void setSubjectData(ReadableMap options) {
        if (options.hasKey("userId") && options.getString("userId") != null && !options.getString("userId").isEmpty()) {
            tracker.instance().getSubject().setUserId(options.getString("userId"));
        }
        if (options.hasKey("viewportWidth") && options.hasKey("viewportHeight")) {
            tracker.instance().getSubject().setViewPort(options.getInt("viewportWidth"), options.getInt("viewportHeight"));
        }
        if (options.hasKey("screenWidth") && options.hasKey("screenHeight")) {
            tracker.instance().getSubject().setScreenResolution(options.getInt("screenWidth"), options.getInt("screenHeight"));
        }
        if (options.hasKey("colorDepth")) {
            tracker.instance().getSubject().setColorDepth(options.getInt("colorDepth"));
        }
        if (options.hasKey("timezone") && options.getString("timezone") != null
                && !options.getString("timezone").isEmpty()) {
            tracker.instance().getSubject().setTimezone(options.getString("timezone"));
        }
        if (options.hasKey("language") && options.getString("language") != null
                && !options.getString("language").isEmpty()) {
            tracker.instance().getSubject().setLanguage(options.getString("language"));
        }
        if (options.hasKey("ipAddress") && options.getString("ipAddress") != null
                && !options.getString("ipAddress").isEmpty()) {
            tracker.instance().getSubject().setIpAddress(options.getString("ipAddress"));
        }
        if (options.hasKey("useragent") && options.getString("useragent") != null
                && !options.getString("useragent").isEmpty()) {
            tracker.instance().getSubject().setUseragent(options.getString("useragent"));
        }
        if (options.hasKey("networkUserId") && options.getString("networkUserId") != null
                && !options.getString("networkUserId").isEmpty()) {
            tracker.instance().getSubject().setNetworkUserId(options.getString("networkUserId"));
        }
        if (options.hasKey("domainUserId") && options.getString("domainUserId") != null
                && !options.getString("domainUserId").isEmpty()) {
            tracker.instance().getSubject().setDomainUserId(options.getString("domainUserId"));
        }
    }

    @ReactMethod
    public void trackSelfDescribingEvent(ReadableMap event, ReadableArray contexts) {
        SelfDescribing trackerEvent = EventUtil.getSelfDescribingEvent(event, contexts);
        if (trackerEvent != null) {
            tracker.track(trackerEvent);
        }
    }

    @ReactMethod
    public void trackStructuredEvent(ReadableMap details,
                                     ReadableArray contexts,
                                     Promise promise) {
        // required params
        String category;
        String action;

        try {
         category = details.getString("category");
         action = details.getString("action");
        } catch (Exception e) {
         promise.reject("ERROR", "SnowplowTracker: trackStructuredEvent() requires category and action arguments to be set");
         return;
        }

        // optional params
        String label = details.hasKey("label") ? details.getString("label") : null;
        String property = details.hasKey("property") ? details.getString("property") : null;
        Double value = details.hasKey("value") ? details.getDouble("value") : null;

        Structured trackerEvent = EventUtil.getStructuredEvent(category, action, label,
                property, value, contexts);
        if (trackerEvent != null) {
            tracker.track(trackerEvent);
        }
    }

    @ReactMethod
    public void trackScreenViewEvent(ReadableMap details,
                                     ReadableArray contexts,
                                     Promise promise) {
        // required params
        String screenName;

        try {
          screenName = details.getString("screenName");
        } catch (Exception e) {
         promise.reject("ERROR", "SnowplowTracker: trackScreenViewEvent() requires screenName to be set");
         return;
        }

        // optional params
        String screenId = details.hasKey("screenId") ? details.getString("screenId") : null;
        String screenType = details.hasKey("screenType") ? details.getString("screenType") : null;
        String previousScreenName = details.hasKey("previousScreenName") ? details.getString("previousScreenName") : null;
        String previousScreenType = details.hasKey("previousScreenType") ? details.getString("previousScreenType") : null;
        String previousScreenId = details.hasKey("previousScreenId") ? details.getString("previousScreenId") : null;
        String transitionType = details.hasKey("transitionType") ? details.getString("transitionType") : null;


        ScreenView trackerEvent = EventUtil.getScreenViewEvent(screenName,
                screenId, screenType, previousScreenName, previousScreenId, previousScreenType,
                transitionType, contexts);
        if (trackerEvent != null) {
            tracker.track(trackerEvent);
        }
    }

    @ReactMethod
    public void trackPageViewEvent(ReadableMap details,
                                  ReadableArray contexts,
                                  Promise promise) {

        // required params
        String pageUrl;

        try {
          pageUrl = details.getString("pageUrl");
        } catch (Exception e) {
         promise.reject("ERROR", "SnowplowTracker: trackPageViewEvent() requires pageUrl to be set");
         return;
        }

        // optional params
        String pageTitle = details.hasKey("pageTitle") ? details.getString("pageTitle") : null;
        String referrer = details.hasKey("pageReferrer") ? details.getString("pageReferrer") : null;

        PageView trackerEvent = EventUtil.getPageViewEvent(pageUrl, pageTitle, referrer, contexts);
        if (trackerEvent != null) {
            tracker.track(trackerEvent);

        }
    }
}
