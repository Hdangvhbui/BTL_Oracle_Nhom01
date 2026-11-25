"""Idempotently load missing seed rows and document grants as FASHION_ADMIN.

Set ORACLE_ADMIN_PASS in the shell that launches this script. The password is
read only from the environment and is never displayed or written to a file.
"""

import os
import re
import sys
from pathlib import Path

import oracledb

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "app"))
from app import DB_HOST, DB_PORT, DB_SID

KEYS = {
    "LOAISANPHAM": ("MALOAI",),
    "SANPHAM": ("MASP",),
    "NHACUNGCAP": ("MANCC",),
    "NHANVIEN": ("MANV",),
    "KHACHHANG": ("MAKH",),
    "PHIEUNHAP": ("MAPN",),
    "CT_PHIEUNHAP": ("MAPN", "MASP"),
    "HOADON": ("MAHD",),
    "CT_HOADON": ("MAHD", "MASP"),
}

GRANTS = {
    "NHANVIEN": ("SELECT",),
    "KHACHHANG": ("SELECT",),
    "NHACUNGCAP": ("SELECT",),
    "HOADON": ("SELECT", "INSERT"),
    "CT_HOADON": ("SELECT", "INSERT"),
    "PHIEUNHAP": ("SELECT", "INSERT"),
    "CT_PHIEUNHAP": ("SELECT", "INSERT"),
}


def seed_statements():
    source = (ROOT / "sql" / "02_seed_data.sql").read_text(encoding="utf-8")
    for line in source.splitlines():
        statement = line.strip()
        if not statement.startswith("INSERT INTO "):
            continue
        match = re.match(r"INSERT INTO (\w+)(?:\s*\([^)]*\))?\s+VALUES\s*\((.*)\);$", statement)
        if not match or match.group(1) not in KEYS:
            raise RuntimeError("Không phân tích được một lệnh INSERT trong seed.")
        table, values = match.groups()
        key_values = re.findall(r"'([^']*)'", values)[: len(KEYS[table])]
        if len(key_values) != len(KEYS[table]):
            raise RuntimeError(f"Không đọc được khóa chính của {table}.")
        yield table, tuple(key_values), statement[:-1]


def main():
    password = os.getenv("ORACLE_ADMIN_PASS")
    if not password:
        raise SystemExit("Thiếu ORACLE_ADMIN_PASS trong môi trường hiện tại; chưa thay đổi Oracle.")
    dsn = oracledb.makedsn(DB_HOST, DB_PORT, sid=DB_SID)
    conn = oracledb.connect(user="FASHION_ADMIN", password=password, dsn=dsn)
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT SYS_CONTEXT('USERENV','CURRENT_USER'), SYS_CONTEXT('USERENV','CON_NAME') FROM DUAL")
            owner, container = cursor.fetchone()
            if owner != "FASHION_ADMIN" or container.lower() != DB_SID.lower():
                raise RuntimeError("Sai chủ schema hoặc container; chưa thay đổi Oracle.")
            cursor.execute("SELECT TABLE_NAME FROM USER_TABLES")
            found = {row[0] for row in cursor.fetchall()}
            if not KEYS.keys() <= found:
                raise RuntimeError("Chưa đủ 9 bảng của schema; chưa nạp seed.")

            statements = list(seed_statements())
            inserted = {table: 0 for table in KEYS}
            for table, key_values, statement in statements:
                conditions = " AND ".join(f"{column} = :v{index}" for index, column in enumerate(KEYS[table]))
                params = {f"v{index}": value for index, value in enumerate(key_values)}
                cursor.execute(f"SELECT 1 FROM {table} WHERE {conditions}", params)
                if cursor.fetchone() is None:
                    cursor.execute(statement)
                    inserted[table] += 1
            conn.commit()

            # Grants are DDL and commit implicitly; run them only after seed succeeds.
            cursor.execute("SELECT TABLE_NAME, PRIVILEGE FROM USER_TAB_PRIVS_MADE WHERE GRANTEE = 'FASHION_WEB'")
            present = set(cursor.fetchall())
            granted = []
            for table, privileges in GRANTS.items():
                for privilege in privileges:
                    if (table, privilege) not in present:
                        cursor.execute(f"GRANT {privilege} ON {table} TO FASHION_WEB")
                        granted.append((table, privilege))

            for table, key_values, _ in statements:
                conditions = " AND ".join(f"{column} = :v{index}" for index, column in enumerate(KEYS[table]))
                params = {f"v{index}": value for index, value in enumerate(key_values)}
                cursor.execute(f"SELECT 1 FROM {table} WHERE {conditions}", params)
                if cursor.fetchone() is None:
                    raise RuntimeError(f"Thiếu bản ghi seed của {table} sau khi nạp.")
            for table in KEYS:
                cursor.execute(f"SELECT COUNT(*) FROM {table}")
                print(f"{table}: {cursor.fetchone()[0]} dòng, bổ sung {inserted[table]}")
            print(f"Quyền mới: {len(granted)}; đã xác nhận đủ {len(statements)} bản ghi seed.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
