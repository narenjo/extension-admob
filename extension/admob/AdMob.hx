package extension.admob;

import haxe.Json;
import openfl.Lib;
#if (openfl < "4.0.0")
import openfl.utils.JNI;
#else
import lime.system.JNI;
#end

typedef RewardItem = {
	var type:String;
	var amount:Int;
}

class AdMob {
	private static var initialized:Bool = false;
	private static var testingAds:Bool = false;
	private static var childDirected:Bool = false;

	////////////////////////////////////////////////////////////////////////////
	private static var __initIos:String->String->Array<String>->String->Bool->Bool->Dynamic->Dynamic->Void = function(bannerId:String, interstitialId:String,
		rewardedIds:Array<String>, gravityMode:String, testingAds:Bool, tagForChildDirectedTreatment:Bool, callback:Dynamic, callback2:Dynamic) {};
	private static var __initAndroid:String->String->Array<String>->String->Bool->Bool->Dynamic->Void = function(bannerId:String, interstitialId:String,
		rewardedIds:Array<String>, gravityMode:String, testingAds:Bool, tagForChildDirectedTreatment:Bool, callback:Dynamic) {};
	private static var __showBanner:Void->Void = function() {};
	private static var __hideBanner:Void->Void = function() {};
	private static var __showInterstitial:Void->Bool = function() {
		return false;
	};
	private static var __showRewarded:String->Bool = function(rewardedId:String) {
		return false;
	};
	private static var __onResize:Void->Void = function() {};
	private static var __getBannerHeight:Void->Float = function() {
		return 0;
	};
	private static var __refresh:Void->Void = function() {};

	////////////////////////////////////////////////////////////////////////////
	private static var lastTimeInterstitial:Int = -60 * 1000;
	private static var displayCallsCounter:Int = 0;

	////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////

	public static function showInterstitial(minInterval:Int = 60, minCallsBeforeDisplay:Int = 0):Bool {
		displayCallsCounter++;
		if ((Lib.getTimer() - lastTimeInterstitial) < (minInterval * 1000))
			return false;
		if (minCallsBeforeDisplay > displayCallsCounter)
			return false;
		displayCallsCounter = 0;
		lastTimeInterstitial = Lib.getTimer();
		try {
			return __showInterstitial();
		} catch (e:Dynamic) {
			trace("ShowInterstitial Exception: " + e);
		}
		return false;
	}

	public static function showRewarded(rewardedId:String):Bool {
		try {
			return __showRewarded(rewardedId);
		} catch (e:Dynamic) {
			trace("ShowRewarded Exception: " + e);
		}
		return false;
	}

	public static function tagForChildDirectedTreatment() {
		if (childDirected)
			return;
		if (initialized) {
			var msg:String;
			msg = "FATAL ERROR: If you want to set tagForChildDirectedTreatment, you must enable them before calling INIT!.\n";
			msg += "Throwing an exception to avoid displaying ads withtou tagForChildDirectedTreatment.";
			trace(msg);
			throw msg;
			return;
		}
		childDirected = true;
	}

	public static function enableTestingAds() {
		if (testingAds)
			return;
		if (initialized) {
			var msg:String;
			msg = "FATAL ERROR: If you want to enable Testing Ads, you must enable them before calling INIT!.\n";
			msg += "Throwing an exception to avoid displaying read ads when you want testing ads.";
			trace(msg);
			throw msg;
			return;
		}
		testingAds = true;
	}

	public static function initAndroid(bannerId:String, interstitialId:String, rewardedIds:Array<String>, gravityMode:GravityMode) {
		#if android
		if (initialized)
			return;
		initialized = true;
		try {
			// JNI METHOD LINKING
			__initAndroid = JNI.createStaticMethod("admobex/AdMobEx", "init",
				"(Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;ZZLorg/haxe/lime/HaxeObject;)V");
			__showBanner = JNI.createStaticMethod("admobex/AdMobEx", "showBanner", "()V");
			__hideBanner = JNI.createStaticMethod("admobex/AdMobEx", "hideBanner", "()V");
			__showInterstitial = JNI.createStaticMethod("admobex/AdMobEx", "showInterstitial", "()Z");
			__showRewarded = JNI.createStaticMethod("admobex/AdMobEx", "showRewarded", "(Ljava/lang/String;)Z");
			__onResize = JNI.createStaticMethod("admobex/AdMobEx", "onResize", "()V");
			__getBannerHeight = JNI.createStaticMethod("admobex/AdMobEx", "getBannerHeight", "()F");

			__initAndroid(bannerId, interstitialId, rewardedIds, (gravityMode == GravityMode.TOP) ? 'TOP' : 'BOTTOM', testingAds, childDirected,
				getInstance());
		} catch (e:Dynamic) {
			trace("Android INIT Exception: " + e);
		}
		#end
	}

	public static function initIOS(bannerId:String, interstitialId:String, rewardedIds:Array<String>, gravityMode:GravityMode) {
		#if ios
		if (initialized)
			return;
		initialized = true;
		try {
			// CPP METHOD LINKING
			__initIos = cpp.Lib.load("adMobEx", "admobex_init", 8);
			__showBanner = cpp.Lib.load("adMobEx", "admobex_banner_show", 0);
			__hideBanner = cpp.Lib.load("adMobEx", "admobex_banner_hide", 0);
			__showInterstitial = cpp.Lib.load("adMobEx", "admobex_interstitial_show", 0);
			__showRewarded = cpp.Lib.load("adMobEx", "admobex_rewarded_show", 1);
			__refresh = cpp.Lib.load("adMobEx", "admobex_banner_refresh", 0);

			__initIos(bannerId, interstitialId, rewardedIds, (gravityMode == GravityMode.TOP) ? 'TOP' : 'BOTTOM', testingAds, childDirected,
				getInstance()._onInterstitialEvent, getInstance()._onRewardedEvent);
		} catch (e:Dynamic) {
			trace("iOS INIT Exception: " + e);
		}
		#end
	}

	public static function showBanner() {
		try {
			__showBanner();
		} catch (e:Dynamic) {
			trace("ShowAd Exception: " + e);
		}
	}

	public static function hideBanner() {
		try {
			__hideBanner();
		} catch (e:Dynamic) {
			trace("HideAd Exception: " + e);
		}
	}

	public static function onResize() {
		try {
			__onResize();
		} catch (e:Dynamic) {
			trace("onResize Exception: " + e);
		}
	}

	public static function getBannerHeight():Float {
		try {
			return __getBannerHeight();
		} catch (e:Dynamic) {
			trace("HideAd Exception: " + e);
			return 0;
		}
	}

	////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////
	public static inline var LEAVING:String = "LEAVING";
	public static inline var FAILED:String = "FAILED";
	public static inline var CLOSED:String = "CLOSED";
	public static inline var DISPLAYING:String = "DISPLAYING";
	public static inline var LOADED:String = "LOADED";
	public static inline var LOADING:String = "LOADING";
	public static inline var EARNED_REWARD:String = "EARNED_REWARD";

	////////////////////////////////////////////////////////////////////////////
	public static var onBannerEvent:String->Void = null;
	public static var onInterstitialEvent:String->Void = null;
	public static var onRewardedEvent:String->RewardItem->Void = null;
	private static var instance:AdMob = null;

	private static function getInstance():AdMob {
		if (instance == null)
			instance = new AdMob();
		return instance;
	}

	////////////////////////////////////////////////////////////////////////////

	private function new() {}

	public function _onBannerEvent(event:String) {
		if (onBannerEvent != null)
			onBannerEvent(event);
		else
			trace("Banner event: " + event + " (assign AdMob.onBannerEvent to get this events and avoid this traces)");
	}

	public function _onInterstitialEvent(event:String) {
		if (onInterstitialEvent != null)
			onInterstitialEvent(event);
		else
			trace("Interstitial event: " + event + " (assign AdMob.onInterstitialEvent to get this events and avoid this traces)");
	}

	public function _onRewardedEvent(event:String, ?data:String) {
		if (onRewardedEvent != null) {
			try {
				var item:RewardItem = null;
				if (data != null)
					item = Json.parse(data);
				onRewardedEvent(event, item);
			} catch (err:Dynamic) {
				trace("ERROR PARSING ", data, " err : ", err);
			}
		} else
			trace("Rewarded event: " + event + " (assign AdMob.onRewardedEvent to get this events and avoid this traces)");
	}
}
