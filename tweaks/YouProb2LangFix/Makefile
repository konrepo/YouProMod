TARGET := iphone:clang:latest:13.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YouProb2LangFix

YouProb2LangFix_FILES = Tweak.x
YouProb2LangFix_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk