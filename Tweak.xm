#import "Header.h"

#define PREF_PATH @"/var/mobile/Library/Preferences/com.ichitaso.iconmute.plist"
#define Notify_Preferences "com.ichitaso.iconmute.preferencechanged"
#define Notify_Name @"com.ichitaso.iconmute.menu"

static BOOL isEnabled;
static BOOL banners;
static BOOL coverSheet;

static NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:PREF_PATH];

static void processEntry(NSString *bundleID, double interval) {
    NSMutableArray *entries = [dict[@"entries"] mutableCopy];
    BOOL add = YES;
    NSDictionary *remove = nil;
    
    for (NSMutableDictionary *entry in entries) {
        if ([entry[@"id"] isEqual:bundleID]) {
            if (interval < 0) {
                entry[@"timeStamp"] = @(-1);
            } else if (interval == 0) {
                remove = entry;
            } else {
                entry[@"timeStamp"] = @([[NSDate date] timeIntervalSince1970] + interval);
            }
            add = NO;
        }
    }
    
    if (remove) {
        [entries removeObject:remove];
    }
    
    if (add) {
        NSDictionary *info;
        if (interval < 0) {
            info = @{@"id":bundleID, @"timeStamp":@(-1)};
        } else if (interval != 0) {
            info = @{@"id": bundleID, @"timeStamp": @([[NSDate date] timeIntervalSince1970] + interval)};
        }
        if (info) {
            [entries addObject:info];
        }
    }

    [dict setValue:entries forKey:@"entries"];
    [dict writeToFile:PREF_PATH atomically:YES];
}

// Stop notification requests
static BOOL shouldStopRequest(NCNotificationRequest *request) {
    BOOL stop = NO;
    NSMutableArray *removeObjects = [[NSMutableArray alloc] init];
    for (NSDictionary *entry in (NSArray *)dict[@"entries"]) {
        int interval = [[NSDate date] timeIntervalSince1970];
        if ([request.sectionIdentifier isEqualToString:entry[@"id"]] && (interval < [entry[@"timeStamp"] intValue] || [entry[@"timeStamp"] intValue] == -1)) {
            stop = YES;
        } else if (interval > [entry[@"timeStamp"] intValue] && [entry[@"timeStamp"] intValue] != -1) {
            [removeObjects addObject:entry];
        }
    }
    
    if (removeObjects) {
        [dict[@"entries"] removeObjectsInArray:removeObjects];
        [dict writeToFile:PREF_PATH atomically:YES];
    }
    return stop;
}

%hook SBIconController
%group iOS_12
- (id)appIconForceTouchController:(id)arg1 applicationShortcutItemsForGestureRecognizer:(id)arg2 {
    if (!isEnabled) return %orig;
	NSArray *orig = %orig;
	NSString *bundleID = [self appIconForceTouchController:arg1 applicationBundleIdentifierForGestureRecognizer:arg2];
	if (bundleID) {
		NSMutableArray *items = [self performSelector:@selector(shortcutMenu:) withObject:orig];
		return items;
	}
	return orig;
}
- (BOOL)appIconForceTouchController:(id)arg1 shouldActivateApplicationShortcutItem:(id)arg2 atIndex:(unsigned long long)arg3 forGestureRecognizer:(id)arg4 {
    if (!isEnabled) return %orig;
	NSString *itemName = [arg2 performSelector:@selector(type)];
	if ([itemName isEqualToString:@"MuteItem"]) {
		NSString *bundleID = [self appIconForceTouchController:arg1 applicationBundleIdentifierForGestureRecognizer:arg4];
        if (bundleID) {
            NSDictionary *info = @{@"id": bundleID};
            [[NSNotificationCenter defaultCenter] postNotificationName:Notify_Name object:nil userInfo:info];
        }
		return NO;
	}
	return %orig;
}
%end // end iOS_12

%group iOS_13
- (BOOL)iconManager:(id)arg1 shouldActivateApplicationShortcutItem:(id)arg2 atIndex:(unsigned long long)arg3 forIconView:(id)arg4 {
    if (!isEnabled) return %orig;
    NSString *itemName = [arg2 performSelector:@selector(type)];
	if ([itemName isEqualToString:@"MuteItem"]) {
		id _icon = [arg4 performSelector:@selector(icon)];
        NSString *bundleID = [_icon applicationBundleID];
        if (bundleID) {
            NSDictionary *info = @{@"id": bundleID};
            [[NSNotificationCenter defaultCenter] postNotificationName:Notify_Name object:nil userInfo:info];
        }
		return NO;
	}
	return %orig;
}
- (id)iconManager:(id)arg1 applicationShortcutItemsForIconView:(id)arg2 {
    if (!isEnabled) return %orig;
	NSArray *orig = %orig;
	id _icon = [arg2 performSelector:@selector(icon)];
	// Dismiss Folder
	if ([_icon isKindOfClass:%c(SBFolderIcon)]) {
		return %orig;
	} else {
		NSMutableArray *items = [self performSelector:@selector(shortcutMenu:) withObject:orig];
		return items;
	}
}
%end // end iOS_13

%new
- (NSMutableArray *)shortcutMenu:(NSArray *)shortcutItems {
	id customIcon = [[%c(SBSApplicationShortcutSystemIcon) alloc] initWithType:UIApplicationShortcutIconTypeAlarm];
    
	id items = [[%c(SBSApplicationShortcutItem) alloc] init];
	[items performSelector:@selector(setType:) withObject:@"MuteItem"];
	[items performSelector:@selector(setLocalizedTitle:) withObject:@"Mute Notifications"];
	[items performSelector:@selector(setLocalizedSubtitle:) withObject:nil];
	if ([items respondsToSelector:@selector(setTargetContentIdentifier:)]) {
		[items performSelector:@selector(setTargetContentIdentifier:) withObject:nil];
	}
	[items performSelector:@selector(setIcon:) withObject:customIcon];
	[items performSelector:@selector(setBundleIdentifierToLaunch:) withObject:nil];
	typedef void (*send_type)(void*, SEL, unsigned long long);
	SEL offsetSEL = @selector(setActivationMode:);
	send_type offsetIMP = (send_type)[%c(SBSApplicationShortcutItem) instanceMethodForSelector:offsetSEL];
	offsetIMP((__bridge void *)items, offsetSEL, 0);

	NSMutableArray *array;
	if (shortcutItems) {
		array = [NSMutableArray arrayWithArray:shortcutItems];
	} else {
		array = [NSMutableArray new];
	}
	[array addObject:items];
	return array;
}
%end

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMuteMenu:) name:Notify_Name object:nil];
}
%new
- (void)showMuteMenu:(NSNotification *)notification {
    NSString *bundleID = notification.userInfo[@"id"];
    
    BOOL muted = NO;
    
    for (NSDictionary *entry in (NSArray *)dict[@"entries"]) {
        if ([entry[@"id"] isEqualToString:bundleID]) {
            if ([[NSDate date] timeIntervalSince1970] < [entry[@"timeStamp"] intValue] || [entry[@"timeStamp"] intValue] == -1) {
                muted = YES;
            }
        }
    }
    
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"Mute Notifications"
                                        message:bundleID
                                 preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:[UIAlertAction actionWithTitle:@"For 15 Minutes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (muted) { // Fix Crash Issue
            processEntry(bundleID, 0);
        }
        processEntry(bundleID, 900);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"For 1 Hour" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (muted) {
            processEntry(bundleID, 0);
        }
        processEntry(bundleID, 3600);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"For 2 Hour" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (muted) {
            processEntry(bundleID, 0);
        }
        processEntry(bundleID, 7200);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"For 3 Hour" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (muted) {
            processEntry(bundleID, 0);
        }
        processEntry(bundleID, 10800);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"For 5 Hour" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (muted) {
            processEntry(bundleID, 0);
        }
        processEntry(bundleID, 18000);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"For 8 Hours" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (muted) {
            processEntry(bundleID, 0);
        }
        processEntry(bundleID, 28800);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"For 1 Day" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (muted) {
            processEntry(bundleID, 0);
        }
        processEntry(bundleID, 86400);
    }]];
    
    if (muted) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Unmute" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            processEntry(bundleID, 0);
        }]];
    } else {
      [alert addAction:[UIAlertAction actionWithTitle:@"Forever" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
          if (muted) {
              processEntry(bundleID, 0);
          }
          processEntry(bundleID, -1);
      }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}
%end

// Mute NotificationCenter notifications
%group iOS_12
%hook SBDashBoardNotificationDispatcher
- (void)postNotificationRequest:(NCNotificationRequest *)request forCoalescedNotification:(id)arg2 {
    if (coverSheet && shouldStopRequest(request)) return;
    %orig;
}
%end
%end

%group iOS_13
%hook CSNotificationDispatcher
- (void)postNotificationRequest:(NCNotificationRequest *)request {
    if (coverSheet && shouldStopRequest(request)) return;
    %orig;
}
%end
%end

%hook SBNCScreenController
- (void)turnOnScreenForNotificationRequest:(NCNotificationRequest *)request {
    if (coverSheet && shouldStopRequest(request)) return;
    %orig;
}
%end

%hook SBNCSoundController
- (void)playSoundForNotificationRequest:(NCNotificationRequest *)request {
    if (coverSheet && shouldStopRequest(request)) return;
    %orig;
}
%end

// Mute banner notifications
%group iOS_12
%hook SBNotificationBannerDestination
- (void)_postNotificationRequest:(NCNotificationRequest *)request forCoalescedNotification:(id)arg2 modal:(bool)arg3 sourceAction:(id)arg4 completion:(id)arg5 {
    if (banners && shouldStopRequest(request)) return;
    %orig;
}
%end
%end

%group iOS_13
%hook SBNotificationBannerDestination
- (void)postNotificationRequest:(NCNotificationRequest *)request {
    if (banners && shouldStopRequest(request)) return;
    %orig;
}
%end
%end

// Settings
//==============================================================================
static void settingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    isEnabled = (BOOL)[dict[@"enabled"] ?: @YES boolValue];
    int type = (int)[dict[@"type"] ?: @0 intValue];
    if (type == 0) {
        banners = YES;
        coverSheet = NO;
    } else if (type == 1) {
        banners = NO;
        coverSheet = YES;
    } else {
        banners = YES;
        coverSheet = YES;
    }
}

%ctor {
    @autoreleasepool {
        NSFileManager *manager = [NSFileManager defaultManager];

        if (![manager fileExistsAtPath:PREF_PATH]) {
            [manager createFileAtPath:PREF_PATH contents:nil attributes:@{NSFilePosixPermissions:@00644}];
            [@{@"entries":@[]} writeToFile:PREF_PATH atomically:YES];
        }
        
        %init;
        
        if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_0) {
            %init(iOS_12);
        } else {
            %init(iOS_13);
        }
        // Settings Changed
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        NULL,
                                        settingsChanged,
                                        CFSTR(Notify_Preferences),
                                        NULL,
                                        CFNotificationSuspensionBehaviorCoalesce);
        
        settingsChanged(NULL, NULL, NULL, NULL, NULL);
    }
}
