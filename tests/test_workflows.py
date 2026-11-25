"""Transaction behavior without depending on a live Oracle account."""

import sys
import unittest
from pathlib import Path

from flask import Flask

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "app"))
from workflows import create_blueprint


class FakeCursor:
    def __init__(self, connection):
        self.connection = connection
        self.rowcount = 1
        self.last_sql = ""
        self.last_params = {}

    def __enter__(self):
        return self

    def __exit__(self, *_):
        pass

    def execute(self, sql, **params):
        self.last_sql = sql
        self.last_params = params
        self.connection.statements.append((sql, params))
        self.rowcount = 0 if "SOLUONGTON >=" in sql and params.get("quantity", 0) > 3 else 1

    def fetchone(self):
        if "SELECT GIABAN" in self.last_sql:
            return (250000,)
        return (1,)

    def fetchall(self):
        return []


class FakeConnection:
    def __init__(self):
        self.statements = []
        self.commits = 0
        self.rollbacks = 0

    def __enter__(self):
        return self

    def __exit__(self, *_):
        pass

    def cursor(self):
        return FakeCursor(self)

    def commit(self):
        self.commits += 1

    def rollback(self):
        self.rollbacks += 1


class DocumentTransactionTests(unittest.TestCase):
    def setUp(self):
        self.connection = FakeConnection()
        app = Flask(__name__)
        app.secret_key = "test-only"
        app.register_blueprint(create_blueprint(lambda: self.connection, lambda: "test"))
        self.client = app.test_client()

    def test_receipt_updates_stock_and_commits_once(self):
        response = self.client.post("/phieu-nhap/lap", data={
            "mapn": "PN_TEST", "manv": "NV01", "mancc": "NCC01",
            "masp": ["SP_TEST"], "soluong": ["6"], "gianhap": ["120000"],
        })
        self.assertEqual(response.status_code, 302)
        self.assertEqual(self.connection.commits, 1)
        self.assertEqual(self.connection.rollbacks, 0)
        self.assertTrue(any("INSERT INTO FASHION_ADMIN.CT_PHIEUNHAP" in sql for sql, _ in self.connection.statements))

    def test_invoice_uses_database_price(self):
        response = self.client.post("/hoa-don/lap", data={
            "mahd": "HD_TEST", "manv": "NV01", "makh": "",
            "masp": ["SP_TEST"], "soluong": ["3"],
        })
        self.assertEqual(response.status_code, 302)
        detail = next(params for sql, params in self.connection.statements if "INSERT INTO FASHION_ADMIN.CT_HOADON" in sql)
        self.assertEqual(detail["price"], 250000)
        self.assertEqual(self.connection.commits, 1)

    def test_oversell_rolls_back_all_lines(self):
        self.client.post("/hoa-don/lap", data={
            "mahd": "HD_TEST", "manv": "NV01", "makh": "",
            "masp": ["SP_OK", "SP_EXCESS"], "soluong": ["1", "4"],
        })
        self.assertEqual(self.connection.commits, 0)
        self.assertEqual(self.connection.rollbacks, 1)
        self.assertTrue(any("INSERT INTO FASHION_ADMIN.CT_HOADON" in sql for sql, _ in self.connection.statements))

    def test_duplicate_sku_rejected_before_database_write(self):
        self.client.post("/phieu-nhap/lap", data={
            "mapn": "PN_TEST", "manv": "NV01", "mancc": "NCC01",
            "masp": ["SP_TEST", "SP_TEST"], "soluong": ["1", "2"], "gianhap": ["10", "10"],
        })
        self.assertEqual(self.connection.statements, [])
        self.assertEqual(self.connection.commits, 0)

    def test_missing_document_returns_404(self):
        self.assertEqual(self.client.get("/api/hoa-don/HD_MISSING").status_code, 404)
        self.assertEqual(self.client.get("/api/phieu-nhap/PN_MISSING").status_code, 404)


if __name__ == "__main__":
    unittest.main()
