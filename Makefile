ARCHS=armv7 arm64
TARGET = iphone:clang:latest:7.0
THEOS_BUILD_DIR=build
OPTFLAG = -Ofast
CFLAGS = -Wall 
include theos/makefiles/common.mk

TWEAK_NAME = Chromizer
Chromizer_FILES = Tweak.x
Chromizer_FRAMEWORKS = UIKit CoreGraphics QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
