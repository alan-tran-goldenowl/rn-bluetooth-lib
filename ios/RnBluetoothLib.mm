#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RnBluetoothLib, NSObject)

RCT_EXTERN_METHOD(multiply:(float)a withB:(float)b
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(startScan)
RCT_EXTERN_METHOD(stopScan)
RCT_EXTERN_METHOD(connectToPeripheral:(NSString *)uuid
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(disconnectFromPeripheral:(NSString *)uuid
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
