SHELL := /bin/bash

.PHONY: help build draw draw-all

KEYBOARD ?=
DONGLE ?=0

help:
	@echo "Targets:"
	@echo "  make build KEYBOARD=urchin           Build left_peripheral/right/left_central"
	@echo "  make build KEYBOARD=urchin DONGLE=1  Build left_peripheral/right/dongle"
	@echo "  make draw KEYBOARD=sweep             Draw one keymap (Sweep alias)"
	@echo "  make draw KEYBOARD=urchin            Draw one keymap"
	@echo "  make draw-all                        Draw all keymaps"

build:
	@if [[ -z "$(KEYBOARD)" ]]; then \
		echo "Usage: make build KEYBOARD=<sweep|urchin|forager> [DONGLE=1]"; \
		exit 1; \
	fi
	tools/build-local-docker.sh "$(KEYBOARD)" $(if $(filter 1 true yes y,$(DONGLE)),--dongle,)

draw:
	@if [[ -z "$(KEYBOARD)" ]]; then \
		echo "Usage: make draw KEYBOARD=<sweep|urchin|forager>"; \
		exit 1; \
	fi
	@draw_keyboard="$(KEYBOARD)"; \
	if [[ "$$draw_keyboard" == "sweep" ]]; then \
		draw_keyboard="cradio"; \
	fi; \
	tools/draw-keymaps-local.sh "$$draw_keyboard"

draw-all:
	tools/draw-keymaps-local.sh
