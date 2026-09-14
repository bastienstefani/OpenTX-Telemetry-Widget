.PHONY: all clean print-version test

SRC_ROOT := src
TELEMETRY := $(SRC_ROOT)/SCRIPTS/TELEMETRY
WIDGETS := $(SRC_ROOT)/WIDGETS
TOOLS := $(SRC_ROOT)/SCRIPTS/TOOLS

SRC := $(wildcard $(WIDGETS)/*.lua)
SRC += $(wildcard $(WIDGETS)/iNav/*.lua)
SRC += $(wildcard $(TELEMETRY)/*.lua)
SRC += $(wildcard $(TELEMETRY)/iNav/*.lua)
SRC += $(wildcard $(TELEMETRY)/iNav/*/*.wav)
SRC += $(wildcard $(TELEMETRY)/iNav/pics/*.*)
SRC += $(wildcard $(TELEMETRY)/iNav/cfg/*.*)
SRC += $(wildcard $(TOOLS)/*.lua)

DIST := dist
VERSION := $(shell grep VERSION $(TELEMETRY)/iNav.lua | head -n 1 | cut -d\" -f 2)
BUILD_SUFFIX ?=
ifneq ($(BUILD_SUFFIX),)
	BUILD_SUFFIX := _$(BUILD_SUFFIX)
endif

# Three packages are produced:
#   ZIP     - Lua 5.2 bytecode: OpenTX 2.3 and EdgeTX up to 2.10
#   ZIPETX  - Lua 5.3 bytecode: EdgeTX 2.11 and later, including EdgeTX 3.x
#   ZIPLUA  - plain sources: any firmware, compiled on the radio at first run
ZIP := $(DIST)/LuaTelemetry_v$(VERSION)$(BUILD_SUFFIX).zip
ZIPETX := $(DIST)/LuaTelemetry_v$(VERSION)$(BUILD_SUFFIX)_edgetx.zip
ZIPLUA := $(DIST)/LuaTelemetry_v$(VERSION)$(BUILD_SUFFIX)_lua.zip

OBJ := obj
OBJETX := obj-etx
OBJ_SRC := $(subst $(SRC_ROOT),$(OBJ),$(SRC))
OBJS := $(OBJ_SRC:.lua=.luac)
OBJETX_SRC := $(subst $(SRC_ROOT),$(OBJETX),$(SRC))
OBJSETX := $(OBJETX_SRC:.lua=.luac)

# These need to be added as .lua too, because OTX will only look for
# .lua files, ignoring .luac. It doesn't matter than there's actually
# .luac since lua can load both source and bytecode using the same API,
# using heuristics to figure what it is.
OBJS += $(OBJ)/WIDGETS/iNav/main.lua
OBJS += $(OBJ)/SCRIPTS/TELEMETRY/iNav.lua
OBJSETX += $(OBJETX)/WIDGETS/iNav/main.lua
OBJSETX += $(OBJETX)/SCRIPTS/TELEMETRY/iNav.lua

# Lua 5.2 (OpenTX / EdgeTX <= 2.10)
LUA_DIST = 3rdparty/lua-5.2.4
LUA = $(LUA_DIST)/src/lua
LUAC = $(LUA)c

# Lua 5.3 built with the EdgeTX options (EdgeTX >= 2.11 / 3.x)
LUA53_DIST = 3rdparty/lua-5.3.6
LUA53 = $(LUA53_DIST)/src/lua
LUAC53 = $(LUA53)c

all: obj obj-etx

$(LUA) $(LUAC): $(LUA_DIST)
	$(MAKE) -C $< generic

$(LUA53) $(LUAC53): $(LUA53_DIST)
	$(MAKE) -C $< generic

$(OBJ)/%.luac: $(SRC_ROOT)/%.lua $(LUAC)
	mkdir -p $(dir $@)
	$(LUAC) -s -o  "$@" "$<"

$(OBJETX)/%.luac: $(SRC_ROOT)/%.lua $(LUAC53)
	mkdir -p $(dir $@)
	$(LUAC53) -s -o  "$@" "$<"

$(OBJ)/%.lua: $(OBJ)/%.luac
	cp -f "$<" "$@"

$(OBJETX)/%.lua: $(OBJETX)/%.luac
	cp -f "$<" "$@"

$(OBJ)/%.wav: $(SRC_ROOT)/%.wav
	mkdir -p $(dir $@)
	cp -f "$<" "$@"

$(OBJETX)/%.wav: $(SRC_ROOT)/%.wav
	mkdir -p $(dir $@)
	cp -f "$<" "$@"

$(OBJ)/%.png: $(SRC_ROOT)/%.png
	mkdir -p $(dir $@)
	cp -f "$<" "$@"

$(OBJETX)/%.png: $(SRC_ROOT)/%.png
	mkdir -p $(dir $@)
	cp -f "$<" "$@"

$(OBJ)/%.txt: $(SRC_ROOT)/%.txt
	mkdir -p $(dir $@)
	cp -f "$<" "$@"

$(OBJETX)/%.txt: $(SRC_ROOT)/%.txt
	mkdir -p $(dir $@)
	cp -f "$<" "$@"

obj: $(OBJS)
obj-etx: $(OBJSETX)

lua: $(LUA)
luac: $(LUAC)
lua53: $(LUA53)
luac53: $(LUAC53)

$(ZIP): $(OBJS)
	mkdir -p $(DIST)
	rm -f $@
	cd $(OBJ) && \
		zip ../$@ -r *

$(ZIPETX): $(OBJSETX)
	mkdir -p $(DIST)
	rm -f $@
	cd $(OBJETX) && \
		zip ../$@ -r *

zip: $(ZIP)
zip-etx: $(ZIPETX)
dist: zip zip-etx zip-lua

ifneq ($(SDCARD),)
install: obj
	mkdir -p "$(SDCARD)"
	cp -r $(OBJ)/* "$(SDCARD)"
install-etx: obj-etx
	mkdir -p "$(SDCARD)"
	cp -r $(OBJETX)/* "$(SDCARD)"
else
install:
	$(error $$SDCARD is empty - use SDCARD=dest make install)
install-etx:
	$(error $$SDCARD is empty - use SDCARD=dest make install-etx)
endif

# Headless smoke test: runs the scripts against a mocked radio API with both
# bundled interpreters (Lua 5.2 as OpenTX, Lua 5.3 with EdgeTX options)
TEST_SCENARIOS := x9d_otx qx7_etx horus_otx tx16s_etx2 tx16s_etx3 mk3_etx3 tx15_etx3 nv14_etx3 qx7_crsf
TEST_TMP := $(OBJ)/test

test: $(LUA) $(LUA53)
	@for interp in $(LUA) $(LUA53); do \
		for sc in $(TEST_SCENARIOS); do \
			sb="$(TEST_TMP)/$$(basename $$(dirname $$(dirname $$interp)))/$$sc"; \
			rm -rf "$$sb"; mkdir -p "$$sb/SCRIPTS/TELEMETRY/iNav/cfg" "$$sb/LOGS"; \
			$$interp tests/smoke.lua $$sc "$(CURDIR)/$(SRC_ROOT)" "$$sb" || exit 1; \
		done; \
	done

clean-obj:
	$(RM) -r $(OBJ) $(OBJETX)

clean-zip:
	$(RM) $(ZIP) $(ZIPETX) $(ZIPLUA)

clean-lua:
	$(MAKE) -C $(LUA_DIST) clean
	$(MAKE) -C $(LUA53_DIST) clean

clean: clean-obj clean-zip clean-lua

print-version:
	@echo $(VERSION)

zip-lua: $(ZIPLUA)
$(ZIPLUA): $(SRC)
	mkdir -p $(DIST)
	rm -f $@
	cd src && zip -9r ../$@ .

dist-lua: zip-lua

ifneq ($(SDCARD),)
install-lua:
	mkdir -p "$(SDCARD)"
	cp -av src/* "$(SDCARD)"
else
install-lua:
	$(error $$SDCARD is empty - use SDCARD=dest make install-lua)
endif
