# Цели проекта "Заметки". Запуск: make <цель>
PYTHON ?= python3
PORT   ?= 8080
# файл данных для make run: в /tmp, чтобы не нужны были права на /var/lib/notes
NOTES_DATA ?= /tmp/notes-dev.txt

.PHONY: run test lint

run: ## запустить сервис на 127.0.0.1:$(PORT)
	PORT=$(PORT) NOTES_DATA=$(NOTES_DATA) $(PYTHON) app.py

test: ## прогнать unit-тесты
	$(PYTHON) -m unittest -v

lint: ## проверить синтаксис и стиль кода
	$(PYTHON) -m py_compile app.py test_app.py
	$(PYTHON) -m ruff check .
