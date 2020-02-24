#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif


#include <hx/CFFI.h>

#include <string>
#include <vector>

#include <AdMobEx.h>

using namespace admobex;

AutoGCRoot* intestitialEventHandle = NULL;
AutoGCRoot* rewardedEventHandle = NULL;

static value admobex_init(value *args, int count){
	value on_interstitial_event = args[6];
	value on_rewarded_event = args[7];
	intestitialEventHandle = new AutoGCRoot(on_interstitial_event);
	rewardedEventHandle = new AutoGCRoot(on_rewarded_event);

	const char* banner_id_str = val_string(args[0]);
	const char* interstitial_id_str = val_string(args[1]);
	
	const char* gravity_mode_str = val_string(args[3]);
	bool testing_ads = val_bool(args[4]);
	bool child_directed_treatment = val_bool(args[5]);

	std::vector<std::string> rewarded_id_arr;
	int n = val_array_size(args[2]);
	for (int i=0;i<n;++i) {
		std::string str(val_string(val_array_i(args[2], i)));
		rewarded_id_arr.push_back(str);
	}

	init(banner_id_str, interstitial_id_str, rewarded_id_arr, gravity_mode_str, testing_ads, child_directed_treatment);

	return alloc_null();
}
DEFINE_PRIM_MULT(admobex_init);

static value admobex_banner_show(){
	showBanner();
	return alloc_null();
}
DEFINE_PRIM(admobex_banner_show,0);

static value admobex_banner_hide(){
	hideBanner();
	return alloc_null();
}
DEFINE_PRIM(admobex_banner_hide,0);

static value admobex_banner_refresh(){
	refreshBanner();
	return alloc_null();
}
DEFINE_PRIM(admobex_banner_refresh,0);


extern "C" void admobex_main () {	
	val_int(0); // Fix Neko init
	
}
DEFINE_ENTRY_POINT (admobex_main);


static value admobex_interstitial_show(){
	return alloc_bool(showInterstitial());
}
DEFINE_PRIM(admobex_interstitial_show,0);

static value admobex_rewarded_show(value rewarded_id){
	return alloc_bool(showRewarded(val_string(rewarded_id)));
}
DEFINE_PRIM(admobex_rewarded_show,1);



extern "C" int admobex_register_prims () { return 0; }


extern "C" void reportInterstitialEvent(const char* event)
{
	if(intestitialEventHandle == NULL) return;
//    value o = alloc_empty_object();
//    alloc_field(o,val_id("event"),alloc_string(event));
    val_call1(intestitialEventHandle->get(), alloc_string(event));
}

extern "C" void reportRewardedEvent(const char* event, const char* data)
{
	if(rewardedEventHandle == NULL) return;
	if(data == NULL)
		val_call1(rewardedEventHandle->get(), alloc_string(event));
	else
    	val_call2(rewardedEventHandle->get(), alloc_string(event), alloc_string(data));
}
