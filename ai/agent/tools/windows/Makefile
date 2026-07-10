SHELL := /bin/bash
PYTHON_WSL = python3

# ========================================
# menu
# ----------------------------------------
TASKS = \
	_exit \
	setup \
	enable \
	disable

.PHONY: menu
menu:
	@echo "select task:"
	@select task in $(TASKS); do \
		if [ -n "$$task" ]; then \
			make --no-print-directory $$task; break; \
		else \
			echo "Invalid selection"; \
		fi; \
	done

.PHONY: _exit
_exit:
	@exit 0
# ========================================
# command
# ----------------------------------------
.PHONY: setup
setup:
	$(PYTHON_WSL) setup.py

.PHONY: enable
enable:
	@$(MAKE) --no-print-directory mic-on
	@$(MAKE) --no-print-directory spk-on
	@echo "completed!"

.PHONY: disable
disable:
	@$(MAKE) --no-print-directory mic-off
	@$(MAKE) --no-print-directory spk-off
	@echo "completed!"

# マイクの制御
.PHONY: mic-on
mic-on:
	@$(PYTHON_WSL) mic_on.py

.PHONY: mic-off
mic-off:
	@$(PYTHON_WSL) mic_off.py

# スピーカーの制御
.PHONY: spk-on
spk-on:
	@$(PYTHON_WSL) spk_on.py

.PHONY: spk-off
spk-off:
	@$(PYTHON_WSL) spk_off.py

.DEFAULT:
	@echo "[WARN] target '$@' unknown"