DEBUG = 0
GO_EASY_ON_ME := 1
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)
ARCHS = arm64 arm64e

TARGET = iphone:12.1.2:11.0

THEOS_DEVICE_IP = localhost -p 2222

TWEAK_NAME = IconMute
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_FRAMEWORKS = Foundation UIKit
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
