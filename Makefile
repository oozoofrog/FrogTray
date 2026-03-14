SWIFTNEST ?= $(if $(wildcard ./swiftnest),./swiftnest,swiftnest)
HARNESS ?= $(SWIFTNEST)
CONFIG ?= config/project.yaml
TARGET ?=
PROFILE ?= intermediate
RELEASE_TAG ?=
RELEASE_ARCHIVE ?=
FORMULA_OUTPUT ?=

install-swiftnest:
	@test -n "$(TARGET)" || (echo "TARGET is required"; exit 1)
	$(SWIFTNEST) install --target "$(TARGET)"

install-harness:
	$(MAKE) install-swiftnest TARGET="$(TARGET)" SWIFTNEST="$(SWIFTNEST)"

list-skills:
	$(SWIFTNEST) list-skills

list-profiles:
	$(SWIFTNEST) list-profiles

onboard:
	@if [ -n "$(TARGET)" ]; then \
		$(SWIFTNEST) onboard --target "$(TARGET)" --config $(CONFIG); \
	else \
		$(SWIFTNEST) onboard --config $(CONFIG); \
	fi

init:
	$(SWIFTNEST) init --config $(CONFIG)

context:
	$(SWIFTNEST) render-context

upgrade:
	$(SWIFTNEST) upgrade --to $(PROFILE)

render-homebrew-formula:
	@test -n "$(RELEASE_TAG)" || (echo "RELEASE_TAG is required"; exit 1)
	@test -n "$(RELEASE_ARCHIVE)" || (echo "RELEASE_ARCHIVE is required"; exit 1)
	@test -n "$(FORMULA_OUTPUT)" || (echo "FORMULA_OUTPUT is required"; exit 1)
	./packaging/homebrew/render_formula.sh \
		--tag "$(RELEASE_TAG)" \
		--archive "$(RELEASE_ARCHIVE)" \
		--output "$(FORMULA_OUTPUT)"
