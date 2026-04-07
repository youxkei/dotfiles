KOMOREBI_DIR := komorebi
KOMOREBI_CUE := $(KOMOREBI_DIR)/komorebi.cue
KOMOREBI_JSON := $(KOMOREBI_DIR)/komorebi.json
KOMOREBI_BAR_INDICES := 0 1 2
KOMOREBI_BAR_JSONS := $(foreach i,$(KOMOREBI_BAR_INDICES),$(KOMOREBI_DIR)/komorebi.bar.$(i).json)

.PHONY: all komorebi clean

all: komorebi

komorebi: $(KOMOREBI_JSON) $(KOMOREBI_BAR_JSONS)

$(KOMOREBI_JSON): $(KOMOREBI_CUE)
	cue export -e komorebi $< -o $@ --force

$(KOMOREBI_DIR)/komorebi.bar.%.json: $(KOMOREBI_CUE)
	cue export -e 'bars[$*]' $< -o $@ --force

clean:
	rm -f $(KOMOREBI_JSON) $(KOMOREBI_BAR_JSONS)
