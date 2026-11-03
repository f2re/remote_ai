#!/usr/bin/env python3
"""Офлайн-тесты принятия статуса Apple notarization (без Apple secrets)."""
import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "verify-notarization.py"
spec = importlib.util.spec_from_file_location("verify_notarization", SCRIPT)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)
GOOD_ID = "2efe2717-52ef-43a5-96dc-0797e4ca1041"


class NotarizationVerifierTests(unittest.TestCase):
    def test_accepted(self):
        self.assertEqual(module.verify({"status": "Accepted", "id": GOOD_ID}), ("Accepted", GOOD_ID))

    def test_rejected(self):
        for state in ["Invalid", "In Progress", "Rejected", None, "accepted", ""]:
            with self.subTest(state=state), self.assertRaises(ValueError):
                module.verify({"status": state, "id": GOOD_ID})

    def test_missing_or_invalid_id(self):
        for value in [None, "", "not-a-uuid", 100, "../payload"]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                module.verify({"status": "Accepted", "id": value})

    def test_non_object(self):
        for value in [[], "Accepted", None]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                module.verify(value)

    def test_cli_exit_codes(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "notary.json"
            for status, expected in [("Accepted", 0), ("Invalid", 1)]:
                path.write_text(json.dumps({"status": status, "id": GOOD_ID}), encoding="utf-8")
                result = subprocess.run([sys.executable, str(SCRIPT), str(path)], capture_output=True, text=True)
                self.assertEqual(result.returncode, expected, result.stderr)

            path.write_text("{not JSON}", encoding="utf-8")
            result = subprocess.run([sys.executable, str(SCRIPT), str(path)], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
