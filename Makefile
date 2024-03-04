.PHONY: clean help pii_check quality requirements selfcheck test upgrade validate

.DEFAULT_GOAL := help

help: ## display this help message
	@echo "Please use \`make <target>' where <target> is one of"
	@grep '^[a-zA-Z]' $(MAKEFILE_LIST) | sort | awk -F ':.*?## ' 'NF==2 {printf "\033[36m  %-25s\033[0m %s\n", $$1, $$2}'

all: requirements quality test

clean: ## remove generated byte code, coverage reports, and build artifacts
	find . -name '__pycache__' -exec rm -rf {} +
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	coverage erase
	rm -fr build/
	rm -fr dist/
	rm -fr *.egg-info

pii_check: ## check for PII annotations on all Django models
	tox -e pii_check

requirements:
	pip install -qr requirements/pip.txt
	pip install -qr requirements/dev.txt

quality:
	tox -e quality

selfcheck: ## check that the Makefile is well-formed
	@echo "The Makefile is well-formed."

test: ## run tests on every supported Python version
	tox

upgrade: export CUSTOM_COMPILE_COMMAND=make upgrade
upgrade: ## update the requirements/*.txt files with the latest packages satisfying requirements/*.in
	pip install -qr requirements/pip-tools.txt
	# Make sure to compile files after any other files they include!
	pip-compile --upgrade --allow-unsafe --rebuild -o requirements/pip.txt requirements/pip.in
	pip-compile --upgrade --allow-unsafe -o requirements/pip-tools.txt requirements/pip-tools.in
	pip install -qr requirements/pip.txt
	pip install -qr requirements/pip-tools.txt
	pip-compile --upgrade --allow-unsafe -o requirements/base.txt requirements/base.in
	pip-compile --upgrade --allow-unsafe -o requirements/test.txt requirements/test.in
	pip-compile --upgrade --allow-unsafe -o requirements/quality.txt requirements/quality.in
	pip-compile --upgrade --allow-unsafe -o requirements/ci.txt requirements/ci.in
	pip-compile --upgrade --allow-unsafe -o requirements/dev.txt requirements/dev.in
	# Let tox control the Django version for tests
	sed '/^[dD]jango==/d' requirements/test.txt > requirements/test.tmp
	mv requirements/test.tmp requirements/test.txt

validate: quality pii_check test ## run tests and quality checks
