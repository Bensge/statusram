include theos/makefiles/common.mk

TWEAK_NAME = StatusRam
StatusRam_FILES = Tweak.xm
StatusRam_FRAMEWORKS=UIKit Foundation


include $(THEOS_MAKE_PATH)/tweak.mk
