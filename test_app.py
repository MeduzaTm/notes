"""Тесты сервиса "Заметки": запускаем настоящий app.py на свободном порту."""
import json
import os
import socket
import subprocess
import sys
import tempfile
import time
import unittest
import urllib.error
import urllib.request
from pathlib import Path

APP = Path(__file__).with_name("app.py")


def free_port():
    # Просим систему выдать любой свободный порт
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


class NotesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.port = free_port()
        env = dict(os.environ)
        env.update(
            HOST="127.0.0.1",
            PORT=str(cls.port),
            APP_VERSION="test",
            NOTES_DATA=str(Path(cls.tmp.name) / "notes.txt"),
        )
        cls.proc = subprocess.Popen(
            [sys.executable, str(APP)],
            env=env,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        # Ждём до 5 секунд, пока сервер начнёт отвечать
        for _ in range(50):
            try:
                cls.call("GET", "/healthz")
                return
            except OSError:
                time.sleep(0.1)
        cls.tearDownClass()
        raise RuntimeError("сервис не поднялся за 5 секунд")

    @classmethod
    def tearDownClass(cls):
        cls.proc.terminate()
        cls.proc.wait(timeout=15)
        cls.tmp.cleanup()

    @classmethod
    def call(cls, method, path, body=None):
        req = urllib.request.Request(
            f"http://127.0.0.1:{cls.port}{path}", data=body, method=method
        )
        try:
            with urllib.request.urlopen(req, timeout=5) as resp:
                return resp.status, resp.read().decode()
        except urllib.error.HTTPError as err:
            with err:  # закрываем ответ с ошибкой, иначе Python 3.14 ругается предупреждением
                return err.code, err.read().decode()

    def test_root(self):
        status, text = self.call("GET", "/")
        self.assertEqual(status, 200)
        self.assertEqual(text, "Notes service vtest\n")

    def test_healthz(self):
        status, _ = self.call("GET", "/healthz")
        self.assertEqual(status, 500)

    def test_post_and_get_note(self):
        payload = json.dumps({"text": "первая заметка"}).encode()
        status, _ = self.call("POST", "/notes", payload)
        self.assertEqual(status, 201)
        status, text = self.call("GET", "/notes")
        self.assertEqual(status, 200)
        self.assertIn("первая заметка", [n["text"] for n in json.loads(text)])

    def test_not_found(self):
        status, _ = self.call("GET", "/no-such-path")
        self.assertEqual(status, 404)

    def test_empty_body_is_400(self):
        status, _ = self.call("POST", "/notes", b"")
        self.assertEqual(status, 400)

    def test_method_not_allowed(self):
        status, _ = self.call("PUT", "/notes", b"{}")
        self.assertEqual(status, 405)


if __name__ == "__main__":
    unittest.main()
