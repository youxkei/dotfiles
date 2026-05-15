KOMOREBI_DIR := komorebi
KOMOREBI_CUE := $(KOMOREBI_DIR)/komorebi.cue
KOMOREBI_JSON := $(KOMOREBI_DIR)/komorebi.json
KOMOREBI_JSON_MAC := $(KOMOREBI_DIR)/komorebi.mac.json

KARABINER_DIR := karabiner
KARABINER_JSON := $(KARABINER_DIR)/karabiner.json
KARABINER_RULES_JS := $(KARABINER_DIR)/rules.js

.PHONY: all komorebi komorebi-mac komorebi-logical-monitors komorebi-logical-monitors-mac karabiner karabiner-test clean

all: komorebi komorebi-mac karabiner

komorebi: $(KOMOREBI_JSON)

komorebi-mac: $(KOMOREBI_JSON_MAC)

$(KOMOREBI_JSON): $(KOMOREBI_CUE)
	cue export -e komorebi $< -o $@ --force

$(KOMOREBI_JSON_MAC): $(KOMOREBI_CUE)
	cue export -e komorebiMac $< -o $@ --force

komorebi-logical-monitors: $(KOMOREBI_CUE)
	@cue export -e logicalMonitors $<

komorebi-logical-monitors-mac: $(KOMOREBI_CUE)
	@cue export -e logicalMonitorsMac $<

# Embed karabiner/rules.js as the sole complex_modifications rule of
# karabiner.json (wrapped as `{"eval_js": "..."}`). Idempotent: replaces the
# rules array entirely with this single eval_js entry.
karabiner: $(KARABINER_RULES_JS)
	jq --rawfile rules $(KARABINER_RULES_JS) \
	  '.profiles[0].complex_modifications.rules = [{eval_js: $$rules}]' \
	  $(KARABINER_JSON) > $(KARABINER_JSON).tmp && mv $(KARABINER_JSON).tmp $(KARABINER_JSON)

karabiner-test: $(KARABINER_RULES_JS)
	node $(KARABINER_DIR)/rules.test.js

clean:
	rm -f $(KOMOREBI_JSON) $(KOMOREBI_JSON_MAC)
