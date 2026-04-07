KOMOREBI_DIR := komorebi
KOMOREBI_CUE := $(KOMOREBI_DIR)/komorebi.cue
KOMOREBI_JSON := $(KOMOREBI_DIR)/komorebi.json
KOMOREBI_BAR_INDICES := 0 1 2
KOMOREBI_BAR_JSONS := $(foreach i,$(KOMOREBI_BAR_INDICES),$(KOMOREBI_DIR)/komorebi.bar.$(i).json)
# Workaround for komorebic v0.1.40 bug: `komorebic start --bar -c <static>` runs
# `komorebi-bar.exe --aliases` without --config, which auto-creates an example
# komorebi.bar.json if it doesn't exist. Pre-generate it as a copy of bar.0 so
# the alias check reads an existing file instead.
KOMOREBI_BAR_DEFAULT := $(KOMOREBI_DIR)/komorebi.bar.json

.PHONY: all komorebi clean

all: komorebi

komorebi: $(KOMOREBI_JSON) $(KOMOREBI_BAR_JSONS) $(KOMOREBI_BAR_DEFAULT)

$(KOMOREBI_JSON): $(KOMOREBI_CUE)
	cue export -e komorebi $< -o $@ --force

$(KOMOREBI_DIR)/komorebi.bar.%.json: $(KOMOREBI_CUE)
	cue export -e 'bars[$*]' $< -o $@ --force

$(KOMOREBI_BAR_DEFAULT): $(KOMOREBI_DIR)/komorebi.bar.0.json
	cp $< $@

clean:
	rm -f $(KOMOREBI_JSON) $(KOMOREBI_BAR_JSONS) $(KOMOREBI_BAR_DEFAULT)
