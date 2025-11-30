TESTS_INIT=tests/minimal_init.lua
TESTS_DIR=tests/

.PHONY: test test-unit test-integration test-snapshot test-standalone update-snapshots lint

# Run all tests with Plenary (requires Neovim)
test:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${TESTS_INIT}' }"

# Run only unit tests
test-unit:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory tests/unit { minimal_init = '${TESTS_INIT}' }"

# Run only integration tests
test-integration:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory tests/integration { minimal_init = '${TESTS_INIT}' }"

# Run only snapshot tests
test-snapshot:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory tests/snapshot { minimal_init = '${TESTS_INIT}' }"

# Update snapshots (run when UI changes intentionally)
update-snapshots:
	@UPDATE_SNAPSHOTS=1 nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory tests/snapshot { minimal_init = '${TESTS_INIT}' }"

# Run standalone tests with vim mock (no Neovim required, uses lua/luajit)
test-standalone:
	@if command -v lua >/dev/null 2>&1; then \
		lua tests/run_standalone.lua; \
	elif command -v luajit >/dev/null 2>&1; then \
		luajit tests/run_standalone.lua; \
	else \
		echo "Error: Neither lua nor luajit found in PATH" >&2; \
		exit 1; \
	fi

# Run luacheck linter
lint:
	@luacheck lua/ --config .luacheckrc
