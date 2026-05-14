KOMOREBI_DIR := komorebi
KOMOREBI_CUE := $(KOMOREBI_DIR)/komorebi.cue
KOMOREBI_JSON := $(KOMOREBI_DIR)/komorebi.json
KOMOREBI_JSON_MAC := $(KOMOREBI_DIR)/komorebi.mac.json

.PHONY: all komorebi komorebi-mac komorebi-logical-monitors komorebi-logical-monitors-mac clean

all: komorebi komorebi-mac

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

clean:
	rm -f $(KOMOREBI_JSON) $(KOMOREBI_JSON_MAC)
