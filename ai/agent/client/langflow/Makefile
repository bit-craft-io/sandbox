THIS_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(THIS_DIR)../Makefile

# ========================================
# menu
# ----------------------------------------
TASKS += \
	cli-await
# ========================================
# command
# ----------------------------------------
.PHONY: cli-await
cli-await:
	$(VENV_PYTHON) await.py
