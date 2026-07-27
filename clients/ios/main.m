#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Concord Modern Dark Palette
    UIColor *concordBg = [UIColor colorWithRed:0.07 green:0.09 blue:0.15 alpha:1.0];
    self.window.backgroundColor = concordBg;
    
    UIViewController *rootVC = [[UIViewController alloc] init];
    rootVC.view.backgroundColor = concordBg;
    
    // Concord Header
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 160, [[UIScreen mainScreen] bounds].size.width - 40, 50)];
    titleLabel.text = @"Concord";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:38];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [rootVC.view addSubview:titleLabel];

    // Status Label
    UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 220, [[UIScreen mainScreen] bounds].size.width - 40, 30)];
    statusLabel.text = @"Phone-less Secure Messenger";
    statusLabel.textColor = [UIColor colorWithRed:0.6 green:0.65 blue:0.75 alpha:1.0];
    statusLabel.font = [UIFont systemFontOfSize:17];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    [rootVC.view addSubview:statusLabel];

    // Local Server Connection Badge
    UILabel *serverBadge = [[UILabel alloc] initWithFrame:CGRectMake(30, 280, [[UIScreen mainScreen] bounds].size.width - 60, 44)];
    serverBadge.text = @"Server: http://192.168.1.4:8080";
    serverBadge.textColor = [UIColor colorWithRed:0.2 green:0.85 blue:0.45 alpha:1.0];
    serverBadge.font = [UIFont boldSystemFontOfSize:15];
    serverBadge.textAlignment = NSTextAlignmentCenter;
    serverBadge.layer.cornerRadius = 8;
    serverBadge.layer.borderWidth = 1;
    serverBadge.layer.borderColor = [UIColor colorWithRed:0.2 green:0.85 blue:0.45 alpha:0.4].CGColor;
    [rootVC.view addSubview:serverBadge];

    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];
    return YES;
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
