# Цели проекта "Заметки". Запуск: make <цель>
PYTHON ?= python3
PORT   ?= 8080
# файл данных для make run: в /tmp, чтобы не нужны были права на /var/lib/notes
NOTES_DATA ?= /tmp/notes-dev.txt

.PHONY: run test lint scan

run: ## запустить сервис на 127.0.0.1:$(PORT)
	PORT=$(PORT) NOTES_DATA=$(NOTES_DATA) $(PYTHON) app.py

test: ## прогнать unit-тесты
	$(PYTHON) -m unittest -v

lint: ## синтаксис и линтер ruff (ruff ставится в .venv, урок 3.3)
	$(PYTHON) -m py_compile app.py test_app.py
	$(PYTHON) -m ruff check .
	@echo "lint: ок"

scan: ## секреты в истории и CVE в зависимостях (как в CI, урок 3.4)
	trufflehog git file://. --no-update --results=verified,unverified,unknown --fail
	trivy fs --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 .
