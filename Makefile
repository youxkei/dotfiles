KARABINER_DIR := karabiner
KARABINER_JSON := $(KARABINER_DIR)/karabiner.json
KARABINER_RULES_JS := $(KARABINER_DIR)/rules.js

.PHONY: all karabiner karabiner-test

all: karabiner

# Embed karabiner/rules.js as the sole complex_modifications rule of
# karabiner.json (wrapped as `{"eval_js": "..."}`). Idempotent: replaces the
# rules array entirely with this single eval_js entry.
karabiner: $(KARABINER_RULES_JS)
	jq --rawfile rules $(KARABINER_RULES_JS) \
	  '.profiles[0].complex_modifications.rules = [{eval_js: $$rules}]' \
	  $(KARABINER_JSON) > $(KARABINER_JSON).tmp && mv $(KARABINER_JSON).tmp $(KARABINER_JSON)

karabiner-test: $(KARABINER_RULES_JS)
	node $(KARABINER_DIR)/rules.test.js
