GOOGLE_HOME_DIR := google_home
GOOGLE_HOME_CUE := $(wildcard $(GOOGLE_HOME_DIR)/*.cue)

.PHONY: google-home

# The Google Home script editor has no API, so deploying means pasting the YAML
# into the browser by hand — put it on the clipboard instead of a file.
google-home: $(GOOGLE_HOME_CUE)
	cue export ./$(GOOGLE_HOME_DIR) --out yaml | pbcopy
