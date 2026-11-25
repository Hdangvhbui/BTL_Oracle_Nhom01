import os
import re
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
import oracledb

app = Flask(__name__)
app.secret_key = "btl_oracle_nhom01_fashion_web"

# ==============================================================================
# CAU HINH KET NOI ORACLE 19C (DUNG TAI KHOAN FASHION_WEB THEO YEU CAU DE BAI)
# Neu may khac su dung SID 'orcl19' hoac 'xe', chi can sua DB_SID ben duoi.
# ==============================================================================
DB_USER = os.getenv("ORACLE_WEB_USER", "FASHION_WEB")
DB_PASS = os.getenv("ORACLE_WEB_PASS", "WebPass123")
DB_HOST = os.getenv("ORACLE_HOST", "localhost")
DB_PORT = int(os.getenv("ORACLE_PORT", "1521"))
DB_SID  = os.getenv("ORACLE_SID", "orcl")


def get_connection():
    """Tao ket noi den CSDL Oracle bang che do Thin mode (khong can Instant Client)."""
    dsn = oracledb.makedsn(DB_HOST, DB_PORT, sid=DB_SID)
    return oracledb.connect(user=DB_USER, password=DB_PASS, dsn=dsn)


def tham_so_kho():
    """Đọc cùng một bộ lọc cho trang kho và hai API."""
    raw = request.args.get("nguong", "5").strip()
    if not re.fullmatch(r"[0-9]+", raw) or int(raw) < 1:
        raise ValueError("Ngưỡng phải là số nguyên dương (từ 1 trở lên).")
    return int(raw), request.args.get("maloai", "").strip()


def du_lieu_kho(nguong, maloai):
    """Lấy số liệu và danh sách từ cùng bộ lọc, chỉ SELECT hai bảng hiện có."""
    dieu_kien = " WHERE sp.MALOAI = :maloai" if maloai else ""
    tham_so = {"nguong": nguong}
    if maloai:
        tham_so["maloai"] = maloai

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(f"""
                SELECT COUNT(*),
                       COUNT(CASE WHEN sp.SOLUONGTON = 0 THEN 1 END),
                       COUNT(CASE WHEN sp.SOLUONGTON BETWEEN 1 AND :nguong THEN 1 END)
                FROM FASHION_ADMIN.SANPHAM sp{dieu_kien}
            """, tham_so)
            tong, het, sap = cur.fetchone()

            cur.execute(f"""
                SELECT sp.MASP, sp.TENSP, sp.KICHCO, sp.MAUSAC,
                       sp.MALOAI, lsp.TENLOAI, sp.SOLUONGTON
                FROM FASHION_ADMIN.SANPHAM sp
                JOIN FASHION_ADMIN.LOAISANPHAM lsp ON lsp.MALOAI = sp.MALOAI
                WHERE sp.SOLUONGTON BETWEEN 1 AND :nguong
                {"AND sp.MALOAI = :maloai" if maloai else ""}
                ORDER BY sp.SOLUONGTON, sp.MASP
            """, tham_so)
            danh_sach = [dict(zip(
                ("masp", "tensp", "kichco", "mausac", "maloai", "tenloai", "soluongton"), row
            )) for row in cur.fetchall()]

            cur.execute("""
                SELECT MALOAI, TENLOAI FROM FASHION_ADMIN.LOAISANPHAM ORDER BY MALOAI
            """)
            ds_loai = cur.fetchall()

    return {"tong_sku": int(tong), "het_hang": int(het), "sap_het": int(sap)}, danh_sach, ds_loai


@app.route("/kho")
def tong_quan_kho():
    try:
        nguong, maloai = tham_so_kho()
    except ValueError as e:
        return render_template("kho.html", db_error=str(e), db_info=None,
                               nguong=request.args.get("nguong", ""), maloai=request.args.get("maloai", ""),
                               so_lieu={"tong_sku": 0, "het_hang": 0, "sap_het": 0},
                               ds_sap_het=[], ds_loai=[]), 400
    try:
        so_lieu, ds_sap_het, ds_loai = du_lieu_kho(nguong, maloai)
        db_error = None
    except oracledb.Error as e:
        so_lieu, ds_sap_het, ds_loai = {"tong_sku": 0, "het_hang": 0, "sap_het": 0}, [], []
        db_error = f"Không thể đọc dữ liệu Oracle: {e}"
    return render_template("kho.html", so_lieu=so_lieu, ds_sap_het=ds_sap_het,
                           ds_loai=ds_loai, nguong=nguong, maloai=maloai,
                           db_error=db_error, db_info=f"{DB_USER}@{DB_HOST}:{DB_PORT}/{DB_SID}"), (503 if db_error else 200)


def api_du_lieu_kho():
    try:
        nguong, maloai = tham_so_kho()
        return du_lieu_kho(nguong, maloai), None
    except ValueError as e:
        return None, (jsonify({"loi": str(e)}), 400)
    except oracledb.Error as e:
        return None, (jsonify({"loi": f"Không thể đọc dữ liệu Oracle: {e}"}), 503)


@app.route("/api/kho/tong-quan")
def api_kho_tong_quan():
    data, error = api_du_lieu_kho()
    return error if error else jsonify(data[0])


@app.route("/api/kho/sap-het")
def api_kho_sap_het():
    data, error = api_du_lieu_kho()
    return error if error else jsonify(data[1])


def giai_thich_loi_oracle(err):
    """Chuyen ma loi tu Oracle sang thong bao tieng Viet ro rang cho nguoi dung."""
    err_obj = err.args[0] if err.args else err
    code = getattr(err_obj, "code", None)

    if code == 2292:
        return (
            "Không thể xóa bản ghi này vì đang có dữ liệu liên quan ở bảng khác "
            "(Vi phạm ràng buộc khóa ngoại - ORA-02292)."
        )
    if code == 1:
        return (
            "Mã hoặc tên đã tồn tại trong cơ sở dữ liệu, vui lòng nhập giá trị khác "
            "(Vi phạm ràng buộc duy nhất/khóa chính - ORA-00001)."
        )
    if code == 2290:
        return (
            "Dữ liệu vi phạm ràng buộc kiểm tra (CHECK): kích cỡ phải thuộc S/M/L/XL/XXL, "
            "giá bán > 0 và số lượng tồn >= 0 (ORA-02290)."
        )
    if code == 2291:
        return "Mã loại sản phẩm được chọn không tồn tại trong hệ thống (ORA-02291)."
    if code == 1400:
        return "Vui lòng điền đầy đủ tất cả các trường thông tin bắt buộc (ORA-01400)."
    if code == 942:
        return (
            "Không tìm thấy bảng hoặc tài khoản FASHION_WEB chưa được cấp quyền "
            "trên FASHION_ADMIN.LOAISANPHAM / SANPHAM (ORA-00942)."
        )
    return f"Lỗi hệ quản trị CSDL Oracle: {err_obj}"


@app.route("/")
def index():
    return redirect(url_for("danh_sach_san_pham"))


# ==============================================================================
# PHAN 1: QUAN LY LOAI SAN PHAM (BANG FASHION_ADMIN.LOAISANPHAM)
# ==============================================================================
@app.route("/loai-san-pham")
def danh_sach_loai():
    edit_id = request.args.get("edit")
    ds_loai = []
    loai_dang_sua = None
    db_error = None

    conn = None
    cur = None
    try:
        conn = get_connection()
        cur = conn.cursor()

        # Lay danh sach loai kem so luong san pham dang tham chieu
        cur.execute("""
            SELECT lsp.MALOAI, lsp.TENLOAI, lsp.MOTA, COUNT(sp.MASP) AS SO_SP
            FROM FASHION_ADMIN.LOAISANPHAM lsp
            LEFT JOIN FASHION_ADMIN.SANPHAM sp ON lsp.MALOAI = sp.MALOAI
            GROUP BY lsp.MALOAI, lsp.TENLOAI, lsp.MOTA
            ORDER BY lsp.MALOAI
        """)
        ds_loai = cur.fetchall()

        if edit_id:
            cur.execute("""
                SELECT MALOAI, TENLOAI, MOTA
                FROM FASHION_ADMIN.LOAISANPHAM
                WHERE MALOAI = :1
            """, [edit_id])
            loai_dang_sua = cur.fetchone()
    except oracledb.Error as e:
        db_error = f"Không thể kết nối Oracle ({DB_USER}@{DB_HOST}:{DB_PORT}/{DB_SID}): {e}"
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

    return render_template(
        "loai_san_pham.html",
        ds_loai=ds_loai,
        loai_dang_sua=loai_dang_sua,
        db_error=db_error,
        db_info=f"{DB_USER}@{DB_HOST}:{DB_PORT}/{DB_SID}"
    )


@app.route("/loai-san-pham/them", methods=["POST"])
def them_loai():
    maloai = request.form.get("maloai", "").strip()
    tenloai = request.form.get("tenloai", "").strip()
    mota = request.form.get("mota", "").strip() or None

    if not maloai or not tenloai:
        flash("Mã loại và tên loại không được để trống.", "error")
        return redirect(url_for("danh_sach_loai"))

    conn = None
    cur = None
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO FASHION_ADMIN.LOAISANPHAM (MALOAI, TENLOAI, MOTA)
            VALUES (:1, :2, :3)
        """, [maloai, tenloai, mota])
        conn.commit()
        flash(f"Đã thêm loại sản phẩm '{maloai} - {tenloai}' thành công.", "success")
    except oracledb.DatabaseError as e:
        if conn:
            conn.rollback()
        flash(giai_thich_loi_oracle(e), "error")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

    return redirect(url_for("danh_sach_loai"))


@app.route("/loai-san-pham/sua/<maloai>", methods=["POST"])
def sua_loai(maloai):
    tenloai = request.form.get("tenloai", "").strip()
    mota = request.form.get("mota", "").strip() or None

    if not tenloai:
        flash("Tên loại không được để trống.", "error")
        return redirect(url_for("danh_sach_loai", edit=maloai))

    conn = None
    cur = None
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("""
            UPDATE FASHION_ADMIN.LOAISANPHAM
            SET TENLOAI = :1, MOTA = :2
            WHERE MALOAI = :3
        """, [tenloai, mota, maloai])
        conn.commit()
        flash(f"Đã cập nhật loại sản phẩm '{maloai}' thành công.", "success")
    except oracledb.DatabaseError as e:
        if conn:
            conn.rollback()
        flash(giai_thich_loi_oracle(e), "error")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

    return redirect(url_for("danh_sach_loai"))


@app.route("/loai-san-pham/xoa/<maloai>", methods=["POST"])
def xoa_loai(maloai):
    conn = None
    cur = None
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("""
            DELETE FROM FASHION_ADMIN.LOAISANPHAM
            WHERE MALOAI = :1
        """, [maloai])
        conn.commit()
        flash(f"Đã xóa loại sản phẩm '{maloai}' khỏi cơ sở dữ liệu.", "success")
    except oracledb.DatabaseError as e:
        if conn:
            conn.rollback()
        flash(giai_thich_loi_oracle(e), "error")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

    return redirect(url_for("danh_sach_loai"))


# ==============================================================================
# PHAN 2: QUAN LY SAN PHAM SKU (BANG FASHION_ADMIN.SANPHAM)
# ==============================================================================
@app.route("/san-pham")
def danh_sach_san_pham():
    edit_id = request.args.get("edit")
    tu_khoa = request.args.get("q", "").strip()
    loc_loai = request.args.get("maloai", "").strip()

    ds_sp = []
    ds_loai = []
    sp_dang_sua = None
    db_error = None

    conn = None
    cur = None
    try:
        conn = get_connection()
        cur = conn.cursor()

        # Lay danh sach loai do vao dropdown loc & form them/sua
        cur.execute("""
            SELECT MALOAI, TENLOAI
            FROM FASHION_ADMIN.LOAISANPHAM
            ORDER BY MALOAI
        """)
        ds_loai = cur.fetchall()

        # Xay dung cau lenh lay danh sach san pham (ho tro tim kiem theo ten/ma va loc loai)
        sql = """
            SELECT sp.MASP, sp.TENSP, sp.KICHCO, sp.MAUSAC, sp.CHATLIEU,
                   sp.GIABAN, sp.SOLUONGTON, sp.MALOAI, lsp.TENLOAI
            FROM FASHION_ADMIN.SANPHAM sp
            JOIN FASHION_ADMIN.LOAISANPHAM lsp ON sp.MALOAI = lsp.MALOAI
            WHERE 1 = 1
        """
        params = {}
        if tu_khoa:
            sql += " AND (UPPER(sp.MASP) LIKE UPPER(:kw) OR UPPER(sp.TENSP) LIKE UPPER(:kw))"
            params["kw"] = f"%{tu_khoa}%"
        if loc_loai:
            sql += " AND sp.MALOAI = :ml"
            params["ml"] = loc_loai
        sql += " ORDER BY sp.MASP"

        cur.execute(sql, params)
        ds_sp = cur.fetchall()

        if edit_id:
            cur.execute("""
                SELECT MASP, TENSP, KICHCO, MAUSAC, CHATLIEU,
                       GIABAN, SOLUONGTON, MALOAI
                FROM FASHION_ADMIN.SANPHAM
                WHERE MASP = :1
            """, [edit_id])
            sp_dang_sua = cur.fetchone()
    except oracledb.Error as e:
        db_error = f"Không thể kết nối Oracle ({DB_USER}@{DB_HOST}:{DB_PORT}/{DB_SID}): {e}"
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

    return render_template(
        "san_pham.html",
        ds_sp=ds_sp,
        ds_loai=ds_loai,
        sp_dang_sua=sp_dang_sua,
        tu_khoa=tu_khoa,
        loc_loai=loc_loai,
        db_error=db_error,
        db_info=f"{DB_USER}@{DB_HOST}:{DB_PORT}/{DB_SID}"
    )


@app.route("/san-pham/them", methods=["POST"])
def them_san_pham():
    masp = request.form.get("masp", "").strip()
    tensp = request.form.get("tensp", "").strip()
    kichco = request.form.get("kichco", "").strip()
    mausac = request.form.get("mausac", "").strip()
    chatlieu = request.form.get("chatlieu", "").strip()
    maloai = request.form.get("maloai", "").strip()

    try:
        giaban = int(request.form.get("giaban", "0"))
        soluongton = int(request.form.get("soluongton", "0"))
    except ValueError:
        flash("Giá bán và số lượng tồn phải là số nguyên hợp lệ.", "error")
        return redirect(url_for("danh_sach_san_pham"))

    conn = None
    cur = None
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO FASHION_ADMIN.SANPHAM
            (MASP, TENSP, KICHCO, MAUSAC, CHATLIEU, GIABAN, SOLUONGTON, MALOAI)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8)
        """, [masp, tensp, kichco, mausac, chatlieu, giaban, soluongton, maloai])
        conn.commit()
        flash(f"Đã thêm sản phẩm SKU '{masp} - {tensp}' thành công.", "success")
    except oracledb.DatabaseError as e:
        if conn:
            conn.rollback()
        flash(giai_thich_loi_oracle(e), "error")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

    return redirect(url_for("danh_sach_san_pham"))


@app.route("/san-pham/sua/<masp>", methods=["POST"])
def sua_san_pham(masp):
    tensp = request.form.get("tensp", "").strip()
    kichco = request.form.get("kichco", "").strip()
    mausac = request.form.get("mausac", "").strip()
    chatlieu = request.form.get("chatlieu", "").strip()
    maloai = request.form.get("maloai", "").strip()

    try:
        giaban = int(request.form.get("giaban", "0"))
        soluongton = int(request.form.get("soluongton", "0"))
    except ValueError:
        flash("Giá bán và số lượng tồn phải là số nguyên hợp lệ.", "error")
        return redirect(url_for("danh_sach_san_pham", edit=masp))

    conn = None
    cur = None
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("""
            UPDATE FASHION_ADMIN.SANPHAM
            SET TENSP = :1, KICHCO = :2, MAUSAC = :3, CHATLIEU = :4,
                GIABAN = :5, SOLUONGTON = :6, MALOAI = :7
            WHERE MASP = :8
        """, [tensp, kichco, mausac, chatlieu, giaban, soluongton, maloai, masp])
        conn.commit()
        flash(f"Đã cập nhật thông tin sản phẩm '{masp}' thành công.", "success")
    except oracledb.DatabaseError as e:
        if conn:
            conn.rollback()
        flash(giai_thich_loi_oracle(e), "error")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

    return redirect(url_for("danh_sach_san_pham"))


@app.route("/san-pham/xoa/<masp>", methods=["POST"])
def xoa_san_pham(masp):
    conn = None
    cur = None
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("""
            DELETE FROM FASHION_ADMIN.SANPHAM
            WHERE MASP = :1
        """, [masp])
        conn.commit()
        flash(f"Đã xóa sản phẩm '{masp}' khỏi cơ sở dữ liệu.", "success")
    except oracledb.DatabaseError as e:
        if conn:
            conn.rollback()
        flash(giai_thich_loi_oracle(e), "error")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

    return redirect(url_for("danh_sach_san_pham"))


from workflows import create_blueprint
app.register_blueprint(create_blueprint(get_connection, lambda: f"{DB_USER}@{DB_HOST}:{DB_PORT}/{DB_SID}"))


if __name__ == "__main__":
    print(f"Dang khoi chay Web CRUD ket noi Oracle: {DB_USER}@{DB_HOST}:{DB_PORT}/{DB_SID}")
    app.run(debug=True, port=5000)
