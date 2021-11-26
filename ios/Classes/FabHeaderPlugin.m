#import "FabHeaderPlugin.h"
#if __has_include(<fab_header/fab_header-Swift.h>)
#import <fab_header/fab_header-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "fab_header-Swift.h"
#endif

@implementation FabHeaderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFabHeaderPlugin registerWithRegistrar:registrar];
}
@end
