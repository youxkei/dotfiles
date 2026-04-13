KOMOREBI_DIR := komorebi
KOMOREBI_CUE := $(KOMOREBI_DIR)/komorebi.cue
KOMOREBI_JSON := $(KOMOREBI_DIR)/komorebi.json

.PHONY: all komorebi clean

all: komorebi

komorebi: $(KOMOREBI_JSON)

$(KOMOREBI_JSON): $(KOMOREBI_CUE)
	cue export -e komorebi $< -o $@ --force

clean:
	rm -f $(KOMOREBI_JSON)
