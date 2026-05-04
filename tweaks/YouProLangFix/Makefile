TARGET := iphone:clang:latest:13.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YouProLangFix

YouProLangFix_FILES = Tweak.x
YouProLangFix_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
