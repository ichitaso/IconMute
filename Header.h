#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <firmware.h>

@interface SBIconController : UIViewController
- (BOOL)iconManager:(id)arg1 shouldActivateApplicationShortcutItem:(id)arg2 atIndex:(unsigned long long)arg3 forIconView:(id)arg4;
- (id)iconManager:(id)arg1 applicationShortcutItemsForIconView:(id)arg2;
//iOS 12
- (id)appIconForceTouchController:(id)arg1 applicationShortcutItemsForGestureRecognizer:(id)arg2;
- (BOOL)appIconForceTouchController:(id)arg1 shouldActivateApplicationShortcutItem:(id)arg2 atIndex:(unsigned long long)arg3 forGestureRecognizer:(id)arg4;
- (id)appIconForceTouchController:(id)arg1 applicationBundleIdentifierForGestureRecognizer:(id)arg2;
@end

@interface SBSApplicationShortcutIcon : NSObject
@end

@interface SBSApplicationShortcutSystemIcon : SBSApplicationShortcutIcon
- (id)initWithType:(NSInteger)type;
@end

@interface SBSApplicationShortcutItem : NSObject
@property (nonatomic,retain) NSData *userInfoData;
@property (nonatomic,copy) NSString *type;
@property (nonatomic,copy) NSString *localizedTitle;
@property (nonatomic,copy) NSString *localizedSubtitle;
@property (nonatomic,copy) id icon;
@property (nonatomic,copy) NSDictionary *userInfo;
@property (assign,nonatomic) unsigned long long activationMode;
@property (nonatomic,copy) NSString *bundleIdentifierToLaunch;
@property (nonatomic,copy) NSString *targetContentIdentifier;
- (NSString *)description;
- (NSString *)type;
- (void)setType:(NSString *)arg1;
- (NSDictionary *)userInfo;
- (void)setUserInfo:(NSDictionary *)arg1;
- (NSString *)targetContentIdentifier;
- (void)setTargetContentIdentifier:(NSString *)arg1;
- (void)setBundleIdentifierToLaunch:(NSString *)arg1;
- (NSString *)localizedTitle;
- (void)setLocalizedTitle:(NSString *)arg1;
- (id)icon;
- (NSString *)localizedSubtitle;
- (NSData *)userInfoData;
- (unsigned long long)activationMode;
- (void)setLocalizedSubtitle:(NSString *)arg1;
- (void)setIcon:(id)arg1 ;
- (void)setActivationMode:(unsigned long long)arg1;
- (void)setUserInfoData:(NSData *)arg1;
@end

@interface SBSApplicationShortcutCustomImageIcon : NSObject
@property (nonatomic, readonly, retain) NSData *imagePNGData;
- (id)initWithImagePNGData:(NSData *)imageData;
@end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (id)applicationWithBundleIdentifier:(id)arg1;
@end


@interface SBIcon : NSObject
- (NSString *)applicationBundleID;
- (NSString *)leafIdentifier;
@end

@interface SBIconView : UIView
@property (nonatomic,retain) SBIcon *icon;
@end

@interface NCNotificationContent : NSObject
@property (nonatomic, retain) NSString *header;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;
@property (nonatomic, retain) NSString *message;
@property (nonatomic, retain) UIImage *icon;
@property (nonatomic, retain) NSDate *date;
@end

@interface NCNotificationActionRunner <NSObject>
-(void)executeAction:(id)arg1 fromOrigin:(id)arg2 withParameters:(id)arg3 completion:(id)arg4;
@end

@interface NCNotificationAction : NSObject
@property (nonatomic,readonly) NCNotificationActionRunner *actionRunner;
@property (nonatomic, copy, readonly) NSURL *launchURL;
@property (nonatomic, copy, readonly) NSString *launchBundleID;
@end

@interface NCNotificationOptions : NSObject
@property (nonatomic, assign) NSUInteger messageNumberOfLines;
@end

@interface NCNotificationRequest : NSObject
@property (nonatomic, copy, readonly) NSString *sectionIdentifier;
@property (nonatomic, retain) NCNotificationContent *content;
@property (nonatomic, retain) NCNotificationOptions *options;
@property (nonatomic,readonly) NCNotificationAction *defaultAction;
@end
