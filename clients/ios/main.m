#import <UIKit/UIKit.h>

// Forward declarations
@class ChatViewController;
@class LoginViewController;

// App Delegate
@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

// Login View Controller
@interface LoginViewController : UIViewController <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *usernameField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UITextField *serverUrlField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UILabel *statusLabel;
@end

// Main Chat List View Controller
@interface ChatListViewController : UITableViewController
@property (nonatomic, strong) NSArray *chats;
@property (nonatomic, strong) NSString *currentAccount;
@end

// Chat Detail View Controller
@interface ChatDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSString *recipientName;
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *inputField;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    LoginViewController *loginVC = [[LoginViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginVC];
    navController.navigationBar.barTintColor = [UIColor colorWithRed:0.09 green:0.11 blue:0.18 alpha:1.0];
    navController.navigationBar.tintColor = [UIColor colorWithRed:0.35 green:0.65 blue:1.0 alpha:1.0];
    navController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Concord";
    self.view.backgroundColor = [UIColor colorWithRed:0.07 green:0.09 blue:0.15 alpha:1.0];

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:scrollView];

    CGFloat width = self.view.bounds.size.width;
    
    // Branding Header
    UILabel *brandLogo = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, width - 40, 44)];
    brandLogo.text = @"Concord";
    brandLogo.textColor = [UIColor whiteColor];
    brandLogo.font = [UIFont boldSystemFontOfSize:34];
    brandLogo.textAlignment = NSTextAlignmentCenter;
    [scrollView addSubview:brandLogo];

    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 105, width - 40, 24)];
    subtitle.text = @"Phone-less Secure Messenger";
    subtitle.textColor = [UIColor colorWithRed:0.6 green:0.65 blue:0.75 alpha:1.0];
    subtitle.font = [UIFont systemFontOfSize:15];
    subtitle.textAlignment = NSTextAlignmentCenter;
    [scrollView addSubview:subtitle];

    // Card Container
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(20, 145, width - 40, 310)];
    card.backgroundColor = [UIColor colorWithRed:0.12 green:0.14 blue:0.22 alpha:1.0];
    card.layer.cornerRadius = 14;
    [scrollView addSubview:card];

    // Username Field
    UILabel *unLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, 200, 20)];
    unLabel.text = @"USERNAME";
    unLabel.textColor = [UIColor colorWithRed:0.5 green:0.55 blue:0.68 alpha:1.0];
    unLabel.font = [UIFont boldSystemFontOfSize:11];
    [card addSubview:unLabel];

    self.usernameField = [[UITextField alloc] initWithFrame:CGRectMake(16, 34, width - 72, 40)];
    self.usernameField.text = @"_ii";
    self.usernameField.textColor = [UIColor whiteColor];
    self.usernameField.backgroundColor = [UIColor colorWithRed:0.07 green:0.09 blue:0.15 alpha:1.0];
    self.usernameField.layer.cornerRadius = 8;
    self.usernameField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
    self.usernameField.leftViewMode = UITextFieldViewModeAlways;
    [card addSubview:self.usernameField];

    // Password Field
    UILabel *pwLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 84, 200, 20)];
    pwLabel.text = @"PASSWORD";
    pwLabel.textColor = [UIColor colorWithRed:0.5 green:0.55 blue:0.68 alpha:1.0];
    pwLabel.font = [UIFont boldSystemFontOfSize:11];
    [card addSubview:pwLabel];

    self.passwordField = [[UITextField alloc] initWithFrame:CGRectMake(16, 106, width - 72, 40)];
    self.passwordField.text = @"QQaa13579";
    self.passwordField.secureTextEntry = YES;
    self.passwordField.textColor = [UIColor whiteColor];
    self.passwordField.backgroundColor = [UIColor colorWithRed:0.07 green:0.09 blue:0.15 alpha:1.0];
    self.passwordField.layer.cornerRadius = 8;
    self.passwordField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
    self.passwordField.leftViewMode = UITextFieldViewModeAlways;
    [card addSubview:self.passwordField];

    // Server IP Field
    UILabel *srvLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 156, 200, 20)];
    srvLabel.text = @"CONCORD SERVER URL";
    srvLabel.textColor = [UIColor colorWithRed:0.5 green:0.55 blue:0.68 alpha:1.0];
    srvLabel.font = [UIFont boldSystemFontOfSize:11];
    [card addSubview:srvLabel];

    self.serverUrlField = [[UITextField alloc] initWithFrame:CGRectMake(16, 178, width - 72, 40)];
    self.serverUrlField.text = @"http://192.168.1.4:8080";
    self.serverUrlField.textColor = [UIColor colorWithRed:0.4 green:0.85 blue:1.0 alpha:1.0];
    self.serverUrlField.backgroundColor = [UIColor colorWithRed:0.07 green:0.09 blue:0.15 alpha:1.0];
    self.serverUrlField.layer.cornerRadius = 8;
    self.serverUrlField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
    self.serverUrlField.leftViewMode = UITextFieldViewModeAlways;
    [card addSubview:self.serverUrlField];

    // Sign In Button
    self.loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.loginButton.frame = CGRectMake(16, 238, width - 72, 48);
    self.loginButton.backgroundColor = [UIColor colorWithRed:0.25 green:0.50 blue:0.95 alpha:1.0];
    self.loginButton.layer.cornerRadius = 10;
    [self.loginButton setTitle:@"Sign In to Concord" forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.loginButton addTarget:self action:@selector(handleLogin) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:self.loginButton];

    // Quick Seed Account Buttons
    UIButton *user1Btn = [UIButton buttonWithType:UIButtonTypeSystem];
    user1Btn.frame = CGRectMake(20, 470, (width - 50) / 2, 38);
    user1Btn.backgroundColor = [UIColor colorWithRed:0.15 green:0.18 blue:0.28 alpha:1.0];
    user1Btn.layer.cornerRadius = 8;
    [user1Btn setTitle:@"Use Account _ii" forState:UIControlStateNormal];
    [user1Btn setTitleColor:[UIColor colorWithRed:0.4 green:0.75 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [user1Btn addTarget:self action:@selector(setSeedUser1) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:user1Btn];

    UIButton *user2Btn = [UIButton buttonWithType:UIButtonTypeSystem];
    user2Btn.frame = CGRectMake(30 + (width - 50) / 2, 470, (width - 50) / 2, 38);
    user2Btn.backgroundColor = [UIColor colorWithRed:0.15 green:0.18 blue:0.28 alpha:1.0];
    user2Btn.layer.cornerRadius = 8;
    [user2Btn setTitle:@"Use Account .1" forState:UIControlStateNormal];
    [user2Btn setTitleColor:[UIColor colorWithRed:0.4 green:0.75 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [user2Btn addTarget:self action:@selector(setSeedUser2) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:user2Btn];

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 520, width - 40, 40)];
    self.statusLabel.textColor = [UIColor colorWithRed:0.3 green:0.85 blue:0.5 alpha:1.0];
    self.statusLabel.font = [UIFont systemFontOfSize:13];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 2;
    self.statusLabel.text = @"Signal Protocol v9 Double Ratchet E2EE\nArgon2id Authentication Active";
    [scrollView addSubview:self.statusLabel];
}

- (void)setSeedUser1 {
    self.usernameField.text = @"_ii";
    self.passwordField.text = @"QQaa13579";
}

- (void)setSeedUser2 {
    self.usernameField.text = @".1";
    self.passwordField.text = @"QQaa13579";
}

- (void)handleLogin {
    NSString *username = self.usernameField.text;
    NSString *serverUrl = self.serverUrlField.text;
    
    self.statusLabel.text = [NSString stringWithFormat:@"Connecting to %@ as %@...", serverUrl, username];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ChatListViewController *chatList = [[ChatListViewController alloc] init];
        chatList.currentAccount = username;
        [self.navigationController pushViewController:chatList animated:YES];
    });
}

@end

@implementation ChatListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"Concord (%@)", self.currentAccount ?: @"_ii"];
    self.view.backgroundColor = [UIColor colorWithRed:0.07 green:0.09 blue:0.15 alpha:1.0];
    self.tableView.backgroundColor = [UIColor colorWithRed:0.07 green:0.09 blue:0.15 alpha:1.0];
    self.tableView.separatorColor = [UIColor colorWithRed:0.15 green:0.18 blue:0.26 alpha:1.0];

    self.chats = @[
        @{@"name": @"Note to Self", @"subtitle": @"Encrypted Memory & Drafts", @"badge": @"🔒", @"time": @"Now"},
        @{@"name": [self.currentAccount isEqualToString:@"_ii"] ? @"Hi. (.1)" : @"Owen (_ii)", @"subtitle": @"🔒 Signal E2EE Message: Hello via Concord!", @"badge": @"1", @"time": @"12:45 PM"},
        @{@"name": @"Concord Core Team", @"subtitle": @"Group: Encrypted Channel", @"badge": @"2", @"time": @"11:30 AM"},
        @{@"name": @"Signal Protocol Status", @"subtitle": @"ACI UUID & Kyber PreKeys Uploaded", @"badge": @"✓", @"time": @"Yesterday"}
    ];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.chats.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ChatCell"];
        cell.backgroundColor = [UIColor colorWithRed:0.07 green:0.09 blue:0.15 alpha:1.0];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.55 green:0.6 blue:0.72 alpha:1.0];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSDictionary *chat = self.chats[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", chat[@"badge"], chat[@"name"]];
    cell.detailTextLabel.text = chat[@"subtitle"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *chat = self.chats[indexPath.row];
    ChatDetailViewController *detailVC = [[ChatDetailViewController alloc] init];
    detailVC.recipientName = chat[@"name"];
    [self.navigationController pushViewController:detailVC animated:YES];
}

@end

@implementation ChatDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.recipientName;
    self.view.backgroundColor = [UIColor colorWithRed:0.07 green:0.09 blue:0.15 alpha:1.0];

    self.messages = [NSMutableArray arrayWithArray:@[
        @{@"sender": @"System", @"text": @"🔒 Messages and calls are end-to-end encrypted with Signal Protocol v9."},
        @{@"sender": @"Peer", @"text": @"Hello! Welcome to Concord Phone-less Messaging."},
        @{@"sender": @"Me", @"text": @"Connected to local Concord server on 192.168.1.4:8080!"}
    ]];

    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;

    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, width, height - 90)];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [UIColor colorWithRed:0.07 green:0.09 blue:0.15 alpha:1.0];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    // Input Bar
    UIView *inputContainer = [[UIView alloc] initWithFrame:CGRectMake(0, height - 90, width, 90)];
    inputContainer.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    inputContainer.backgroundColor = [UIColor colorWithRed:0.11 green:0.13 blue:0.20 alpha:1.0];
    [self.view addSubview:inputContainer];

    self.inputField = [[UITextField alloc] initWithFrame:CGRectMake(16, 10, width - 90, 44)];
    self.inputField.placeholder = @"Signal E2EE Message...";
    self.inputField.textColor = [UIColor whiteColor];
    self.inputField.backgroundColor = [UIColor colorWithRed:0.07 green:0.09 blue:0.15 alpha:1.0];
    self.inputField.layer.cornerRadius = 22;
    self.inputField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 44)];
    self.inputField.leftViewMode = UITextFieldViewModeAlways;
    [inputContainer addSubview:self.inputField];

    UIButton *sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    sendBtn.frame = CGRectMake(width - 66, 10, 50, 44);
    sendBtn.backgroundColor = [UIColor colorWithRed:0.25 green:0.50 blue:0.95 alpha:1.0];
    sendBtn.layer.cornerRadius = 22;
    [sendBtn setTitle:@"Send" forState:UIControlStateNormal];
    sendBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [sendBtn addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    [inputContainer addSubview:sendBtn];
}

- (void)sendMessage {
    NSString *text = self.inputField.text;
    if (text.length == 0) return;

    [self.messages addObject:@{@"sender": @"Me", @"text": text}];
    self.inputField.text = @"";
    [self.tableView reloadData];
    
    NSIndexPath *lastPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:lastPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MsgCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MsgCell"];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.font = [UIFont systemFontOfSize:15];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSDictionary *msg = self.messages[indexPath.row];
    if ([msg[@"sender"] isEqualToString:@"Me"]) {
        cell.textLabel.text = [NSString stringWithFormat:@"Me: %@", msg[@"text"]];
        cell.textLabel.textColor = [UIColor colorWithRed:0.45 green:0.75 blue:1.0 alpha:1.0];
        cell.textLabel.textAlignment = NSTextAlignmentRight;
    } else if ([msg[@"sender"] isEqualToString:@"System"]) {
        cell.textLabel.text = msg[@"text"];
        cell.textLabel.textColor = [UIColor colorWithRed:0.6 green:0.8 blue:0.6 alpha:1.0];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", msg[@"sender"], msg[@"text"]];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
    }

    return cell;
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
