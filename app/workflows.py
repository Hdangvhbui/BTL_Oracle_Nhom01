"""Read-only catalog pages and atomic purchase/sale documents."""

import re
from decimal import Decimal
from flask import Blueprint, abort, flash, jsonify, redirect, render_template, request, url_for
import oracledb


class InputError(ValueError):
    pass


def positive_number(raw, label, digits):
    if not re.fullmatch(r"[0-9]+", (raw or "").strip()):
        raise InputError(f"{label} phải là số nguyên dương.")
    value = int(raw)
    if value < 1 or value >= 10 ** digits:
        raise InputError(f"{label} phải từ 1 đến {10 ** digits - 1}.")
    return value


def required_code(raw, label):
    value = (raw or "").strip()
    if not value or len(value) > 20:
        raise InputError(f"{label} phải có từ 1 đến 20 ký tự.")
    return value


def parse_lines(form, incoming):
    products = form.getlist("masp")
    quantities = form.getlist("soluong")
    prices = form.getlist("gianhap") if incoming else []
    if not products or len(products) != len(quantities) or (incoming and len(products) != len(prices)):
        raise InputError("Chứng từ cần ít nhất một dòng hàng hợp lệ.")
    lines = []
    seen = set()
    for index, product in enumerate(products, 1):
        code = required_code(product, f"SKU dòng {index}")
        if code in seen:
            raise InputError(f"SKU {code} bị trùng trong chứng từ.")
        seen.add(code)
        quantity = positive_number(quantities[index - 1], f"Số lượng dòng {index}", 10)
        price = positive_number(prices[index - 1], f"Giá nhập dòng {index}", 15) if incoming else None
        lines.append((code, quantity, price))
    return lines


def rows(cursor, keys):
    return [dict(zip(keys, row)) for row in cursor.fetchall()]


def database_error(exc):
    code = getattr(exc.args[0], "code", None) if exc.args else None
    if code == 942:
        return "Tài khoản web chưa có quyền truy cập bảng Oracle cần thiết."
    if code == 1:
        return "Mã chứng từ đã tồn tại. Vui lòng dùng mã khác."
    if code == 2291:
        return "Nhân viên, đối tác hoặc SKU đã chọn không còn tồn tại."
    if code == 2290:
        return "Số lượng hoặc đơn giá vi phạm ràng buộc dữ liệu."
    return f"Oracle không thực hiện được thao tác (mã lỗi {code or 'không xác định'})."


def create_blueprint(get_connection, db_info):
    bp = Blueprint("workflows", __name__)

    def options(cursor):
        cursor.execute("SELECT MANV, HOTEN FROM FASHION_ADMIN.NHANVIEN ORDER BY MANV")
        employees = cursor.fetchall()
        cursor.execute("SELECT MAKH, HOTEN FROM FASHION_ADMIN.KHACHHANG ORDER BY MAKH")
        customers = cursor.fetchall()
        cursor.execute("SELECT MANCC, TENNCC FROM FASHION_ADMIN.NHACUNGCAP ORDER BY MANCC")
        suppliers = cursor.fetchall()
        cursor.execute("SELECT MASP, TENSP, SOLUONGTON, GIABAN FROM FASHION_ADMIN.SANPHAM ORDER BY MASP")
        products = cursor.fetchall()
        return dict(employees=employees, customers=customers, suppliers=suppliers, products=products)

    def invoice_list(cursor):
        cursor.execute("""
            SELECT h.MAHD, h.NGAYLAP, h.MANV, nv.HOTEN, h.MAKH,
                   NVL(kh.HOTEN, N'Khách lẻ'), NVL(SUM(ct.THANHTIEN), 0)
            FROM FASHION_ADMIN.HOADON h
            JOIN FASHION_ADMIN.NHANVIEN nv ON nv.MANV = h.MANV
            LEFT JOIN FASHION_ADMIN.KHACHHANG kh ON kh.MAKH = h.MAKH
            LEFT JOIN FASHION_ADMIN.CT_HOADON ct ON ct.MAHD = h.MAHD
            GROUP BY h.MAHD, h.NGAYLAP, h.MANV, nv.HOTEN, h.MAKH, kh.HOTEN
            ORDER BY h.NGAYLAP DESC, h.MAHD DESC
        """)
        return rows(cursor, ("mahd", "ngaylap", "manv", "nhanvien", "makh", "khachhang", "tongtien"))

    def invoice_detail(cursor, code):
        cursor.execute("""
            SELECT h.MAHD, h.NGAYLAP, h.MANV, nv.HOTEN, h.MAKH,
                   NVL(kh.HOTEN, N'Khách lẻ'), NVL(SUM(ct.THANHTIEN), 0)
            FROM FASHION_ADMIN.HOADON h
            JOIN FASHION_ADMIN.NHANVIEN nv ON nv.MANV = h.MANV
            LEFT JOIN FASHION_ADMIN.KHACHHANG kh ON kh.MAKH = h.MAKH
            LEFT JOIN FASHION_ADMIN.CT_HOADON ct ON ct.MAHD = h.MAHD
            WHERE h.MAHD = :code
            GROUP BY h.MAHD, h.NGAYLAP, h.MANV, nv.HOTEN, h.MAKH, kh.HOTEN
        """, code=code)
        header = rows(cursor, ("mahd", "ngaylap", "manv", "nhanvien", "makh", "khachhang", "tongtien"))
        if not header:
            return None
        cursor.execute("""
            SELECT ct.MASP, sp.TENSP, ct.SOLUONGBAN, ct.DONGIABAN, ct.THANHTIEN
            FROM FASHION_ADMIN.CT_HOADON ct
            JOIN FASHION_ADMIN.SANPHAM sp ON sp.MASP = ct.MASP
            WHERE ct.MAHD = :code ORDER BY ct.MASP
        """, code=code)
        return dict(header=header[0], lines=rows(cursor, ("masp", "tensp", "soluong", "dongia", "thanhtien")))

    def receipt_list(cursor):
        cursor.execute("""
            SELECT p.MAPN, p.NGAYNHAP, p.MANCC, ncc.TENNCC, p.MANV, nv.HOTEN,
                   NVL(SUM(ct.SOLUONGNHAP * ct.GIANHAP), 0)
            FROM FASHION_ADMIN.PHIEUNHAP p
            JOIN FASHION_ADMIN.NHACUNGCAP ncc ON ncc.MANCC = p.MANCC
            JOIN FASHION_ADMIN.NHANVIEN nv ON nv.MANV = p.MANV
            LEFT JOIN FASHION_ADMIN.CT_PHIEUNHAP ct ON ct.MAPN = p.MAPN
            GROUP BY p.MAPN, p.NGAYNHAP, p.MANCC, ncc.TENNCC, p.MANV, nv.HOTEN
            ORDER BY p.NGAYNHAP DESC, p.MAPN DESC
        """)
        return rows(cursor, ("mapn", "ngaynhap", "mancc", "nhacungcap", "manv", "nhanvien", "tongtien"))

    def receipt_detail(cursor, code):
        cursor.execute("""
            SELECT p.MAPN, p.NGAYNHAP, p.MANCC, ncc.TENNCC, p.MANV, nv.HOTEN,
                   NVL(SUM(ct.SOLUONGNHAP * ct.GIANHAP), 0)
            FROM FASHION_ADMIN.PHIEUNHAP p
            JOIN FASHION_ADMIN.NHACUNGCAP ncc ON ncc.MANCC = p.MANCC
            JOIN FASHION_ADMIN.NHANVIEN nv ON nv.MANV = p.MANV
            LEFT JOIN FASHION_ADMIN.CT_PHIEUNHAP ct ON ct.MAPN = p.MAPN
            WHERE p.MAPN = :code
            GROUP BY p.MAPN, p.NGAYNHAP, p.MANCC, ncc.TENNCC, p.MANV, nv.HOTEN
        """, code=code)
        header = rows(cursor, ("mapn", "ngaynhap", "mancc", "nhacungcap", "manv", "nhanvien", "tongtien"))
        if not header:
            return None
        cursor.execute("""
            SELECT ct.MASP, sp.TENSP, ct.SOLUONGNHAP, ct.GIANHAP,
                   ct.SOLUONGNHAP * ct.GIANHAP
            FROM FASHION_ADMIN.CT_PHIEUNHAP ct
            JOIN FASHION_ADMIN.SANPHAM sp ON sp.MASP = ct.MASP
            WHERE ct.MAPN = :code ORDER BY ct.MASP
        """, code=code)
        return dict(header=header[0], lines=rows(cursor, ("masp", "tensp", "soluong", "dongia", "thanhtien")))

    def json_ready(value):
        if isinstance(value, dict):
            return {key: json_ready(item) for key, item in value.items()}
        if isinstance(value, list):
            return [json_ready(item) for item in value]
        if isinstance(value, Decimal):
            return int(value) if value == value.to_integral_value() else float(value)
        return value.isoformat() if hasattr(value, "isoformat") else value

    def read_document(query, code=None, api=False):
        try:
            with get_connection() as conn, conn.cursor() as cursor:
                data = query(cursor, code) if code is not None else query(cursor)
        except oracledb.Error as exc:
            if api:
                return jsonify(loi=database_error(exc)), 503
            return None, database_error(exc)
        if code is not None and data is None:
            abort(404)
        return jsonify(json_ready(data)) if api else (data, None)

    @bp.get("/hoa-don")
    def hoa_don():
        data, error = read_document(invoice_list)
        return render_template("document_list.html", kind="sale", documents=data or [], db_error=error, db_info=db_info()), 503 if error else 200

    @bp.get("/hoa-don/<mahd>")
    def chi_tiet_hoa_don(mahd):
        data, error = read_document(invoice_detail, mahd)
        return render_template("document_detail.html", kind="sale", document=data, db_error=error, db_info=db_info()), 503 if error else 200

    @bp.get("/phieu-nhap")
    def phieu_nhap():
        data, error = read_document(receipt_list)
        return render_template("document_list.html", kind="receipt", documents=data or [], db_error=error, db_info=db_info()), 503 if error else 200

    @bp.get("/phieu-nhap/<mapn>")
    def chi_tiet_phieu_nhap(mapn):
        data, error = read_document(receipt_detail, mapn)
        return render_template("document_detail.html", kind="receipt", document=data, db_error=error, db_info=db_info()), 503 if error else 200

    @bp.get("/api/hoa-don")
    def api_hoa_don():
        return read_document(invoice_list, api=True)

    @bp.get("/api/hoa-don/<mahd>")
    def api_chi_tiet_hoa_don(mahd):
        return read_document(invoice_detail, mahd, api=True)

    @bp.get("/api/phieu-nhap")
    def api_phieu_nhap():
        return read_document(receipt_list, api=True)

    @bp.get("/api/phieu-nhap/<mapn>")
    def api_chi_tiet_phieu_nhap(mapn):
        return read_document(receipt_detail, mapn, api=True)

    @bp.get("/hoa-don/lap")
    def form_hoa_don():
        return document_form("sale")

    @bp.get("/phieu-nhap/lap")
    def form_phieu_nhap():
        return document_form("receipt")

    def document_form(kind):
        try:
            with get_connection() as conn, conn.cursor() as cursor:
                choices = options(cursor)
            return render_template("document_form.html", kind=kind, db_info=db_info(), **choices)
        except oracledb.Error as exc:
            return render_template("document_form.html", kind=kind, db_info=db_info(), db_error=database_error(exc), employees=[], customers=[], suppliers=[], products=[]), 503

    def exists(cursor, table, column, value):
        # Internal constants only; never interpolate user input into identifiers.
        cursor.execute(f"SELECT 1 FROM FASHION_ADMIN.{table} WHERE {column} = :code", code=value)
        return cursor.fetchone() is not None

    def create_document(kind):
        incoming = kind == "receipt"
        try:
            code = required_code(request.form.get("mapn" if incoming else "mahd"), "Mã chứng từ")
            employee = required_code(request.form.get("manv"), "Mã nhân viên")
            counterpart = required_code(request.form.get("mancc"), "Mã nhà cung cấp") if incoming else (request.form.get("makh") or "").strip() or None
            if counterpart and len(counterpart) > 20:
                raise InputError("Mã khách hàng tối đa 20 ký tự.")
            lines = parse_lines(request.form, incoming)
            with get_connection() as conn:
                try:
                    with conn.cursor() as cursor:
                        if not exists(cursor, "NHANVIEN", "MANV", employee):
                            raise InputError("Nhân viên được chọn không tồn tại.")
                        if incoming and not exists(cursor, "NHACUNGCAP", "MANCC", counterpart):
                            raise InputError("Nhà cung cấp được chọn không tồn tại.")
                        if not incoming and counterpart and not exists(cursor, "KHACHHANG", "MAKH", counterpart):
                            raise InputError("Khách hàng được chọn không tồn tại.")
                        if incoming:
                            cursor.execute("INSERT INTO FASHION_ADMIN.PHIEUNHAP (MAPN, MANCC, MANV) VALUES (:code, :partner, :employee)", code=code, partner=counterpart, employee=employee)
                        else:
                            cursor.execute("INSERT INTO FASHION_ADMIN.HOADON (MAHD, MANV, MAKH) VALUES (:code, :employee, :partner)", code=code, employee=employee, partner=counterpart)
                        for sku, quantity, price in lines:
                            if incoming:
                                cursor.execute("UPDATE FASHION_ADMIN.SANPHAM SET SOLUONGTON = SOLUONGTON + :quantity WHERE MASP = :sku AND SOLUONGTON + :quantity < 10000000000", quantity=quantity, sku=sku)
                                if cursor.rowcount != 1:
                                    raise InputError(f"SKU {sku} không tồn tại hoặc tồn kho vượt giới hạn.")
                                cursor.execute("INSERT INTO FASHION_ADMIN.CT_PHIEUNHAP (MAPN, MASP, SOLUONGNHAP, GIANHAP) VALUES (:code, :sku, :quantity, :price)", code=code, sku=sku, quantity=quantity, price=price)
                            else:
                                cursor.execute("SELECT GIABAN FROM FASHION_ADMIN.SANPHAM WHERE MASP = :sku", sku=sku)
                                product = cursor.fetchone()
                                if not product:
                                    raise InputError(f"SKU {sku} không tồn tại.")
                                cursor.execute("UPDATE FASHION_ADMIN.SANPHAM SET SOLUONGTON = SOLUONGTON - :quantity WHERE MASP = :sku AND SOLUONGTON >= :quantity", quantity=quantity, sku=sku)
                                if cursor.rowcount != 1:
                                    raise InputError(f"SKU {sku} không đủ tồn kho để bán {quantity}.")
                                cursor.execute("INSERT INTO FASHION_ADMIN.CT_HOADON (MAHD, MASP, SOLUONGBAN, DONGIABAN) VALUES (:code, :sku, :quantity, :price)", code=code, sku=sku, quantity=quantity, price=product[0])
                    conn.commit()
                except (InputError, oracledb.Error):
                    conn.rollback()
                    raise
            flash(f"Đã lập {'phiếu nhập' if incoming else 'hóa đơn'} {code}.", "success")
            return redirect(url_for("workflows.chi_tiet_phieu_nhap" if incoming else "workflows.chi_tiet_hoa_don", **({"mapn": code} if incoming else {"mahd": code})))
        except InputError as exc:
            flash(str(exc), "error")
        except oracledb.Error as exc:
            flash(database_error(exc), "error")
        return redirect(url_for("workflows.form_phieu_nhap" if incoming else "workflows.form_hoa_don"))

    @bp.post("/hoa-don/lap")
    def lap_hoa_don():
        return create_document("sale")

    @bp.post("/phieu-nhap/lap")
    def lap_phieu_nhap():
        return create_document("receipt")

    def catalog(table, columns, keys, query):
        try:
            with get_connection() as conn, conn.cursor() as cursor:
                sql = f"SELECT {columns} FROM FASHION_ADMIN.{table} WHERE 1=1"
                params = {}
                if query:
                    sql += f" AND (UPPER({keys[0]}) LIKE UPPER(:q) OR UPPER({keys[1]}) LIKE UPPER(:q))"
                    params["q"] = f"%{query}%"
                cursor.execute(sql + f" ORDER BY {keys[0]}", params)
                return cursor.fetchall(), None
        except oracledb.Error as exc:
            return [], database_error(exc)

    @bp.get("/khach-hang")
    def khach_hang():
        query = request.args.get("q", "").strip()
        data, error = catalog("KHACHHANG", "MAKH, HOTEN, SDT, DIACHI", ("MAKH", "HOTEN"), query)
        return render_template("catalog.html", kind="customer", items=data, query=query, db_error=error, db_info=db_info()), 503 if error else 200

    @bp.get("/nha-cung-cap")
    def nha_cung_cap():
        query = request.args.get("q", "").strip()
        data, error = catalog("NHACUNGCAP", "MANCC, TENNCC, SDT, DIACHI, EMAIL", ("MANCC", "TENNCC"), query)
        return render_template("catalog.html", kind="supplier", items=data, query=query, db_error=error, db_info=db_info()), 503 if error else 200

    return bp
