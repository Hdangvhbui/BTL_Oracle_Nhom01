-- =====================================================================
-- FILE: 04_queries.sql - 12 CÂU TRUY VẤN SQL (PHÙNG QUANG MINH - MỤC 3)
-- =====================================================================

-- CÂU 1: Truy vấn điều kiện cơ bản (WHERE, LIKE)
-- Mục đích: Tìm nhân viên thu ngân có họ 'Phùng'.
SELECT MANV, HOTEN, CHUCVU, LUONG 
FROM NHANVIEN 
WHERE CHUCVU = N'Thu ngân' AND HOTEN LIKE N'Phùng%';

-- CÂU 2: Truy vấn khoảng (BETWEEN)
-- Mục đích: Liệt kê các sản phẩm có giá bán tầm trung từ 200,000 đến 500,000 VNĐ.
SELECT MASP, TENSP, KICHCO, MAUSAC, GIABAN 
FROM SANPHAM 
WHERE GIABAN BETWEEN 200000 AND 500000;

-- CÂU 3: Sắp xếp và giới hạn (ORDER BY, FETCH FIRST)
-- Mục đích: Lấy Top 3 sản phẩm có giá bán cao nhất cửa hàng.
SELECT MASP, TENSP, KICHCO, MAUSAC, GIABAN 
FROM SANPHAM 
ORDER BY GIABAN DESC 
FETCH FIRST 3 ROWS ONLY;

-- CÂU 4: Kết nối bằng INNER JOIN
-- Mục đích: Xem chi tiết hóa đơn 'HD01' gồm tên khách, tên sản phẩm, số lượng và thành tiền.
SELECT h.MAHD, k.HOTEN AS TEN_KHACH, s.TENSP, c.SOLUONGBAN, c.DONGIABAN, c.THANHTIEN
FROM HOADON h
INNER JOIN KHACHHANG k ON h.MAKH = k.MAKH
INNER JOIN CT_HOADON c ON h.MAHD = c.MAHD
INNER JOIN SANPHAM s ON c.MASP = s.MASP
WHERE h.MAHD = 'HD01';

-- CÂU 5: Kết nối bằng LEFT JOIN (Giữ lại khách lẻ)
-- Mục đích: Lấy tất cả hóa đơn, giữ lại cả hóa đơn của khách lẻ (MAKH = NULL).
SELECT h.MAHD, h.NGAYLAP, nv.HOTEN AS TEN_NV_BAN, kh.HOTEN AS TEN_KHACH_HANG
FROM HOADON h
LEFT JOIN KHACHHANG kh ON h.MAKH = kh.MAKH
INNER JOIN NHANVIEN nv ON h.MANV = nv.MANV
ORDER BY h.MAHD;

-- CÂU 6: Phân nhóm (GROUP BY) và hàm tổng hợp SUM
-- Mục đích: Tính tổng trị giá của từng hóa đơn.
SELECT MAHD, SUM(THANHTIEN) AS TONG_GIA_TRI_HD
FROM CT_HOADON
GROUP BY MAHD
ORDER BY MAHD;

-- CÂU 7: Lọc điều kiện nhóm (HAVING)
-- Mục đích: Tìm các hóa đơn có tổng trị giá mua hàng lớn hơn 1,000,000 VNĐ.
SELECT MAHD, SUM(THANHTIEN) AS TONG_GIA_TRI_HD
FROM CT_HOADON
GROUP BY MAHD
HAVING SUM(THANHTIEN) > 1000000
ORDER BY TONG_GIA_TRI_HD DESC;

-- CÂU 8: Hàm thống kê MIN / AVG
-- Mục đích: Thống kê giá bán thấp nhất và giá trung bình theo từng loại sản phẩm.
SELECT l.TENLOAI, MIN(s.GIABAN) AS GIA_THAP_NHAT, ROUND(AVG(s.GIABAN), 0) AS GIA_TRUNG_BINH
FROM SANPHAM s
INNER JOIN LOAISANPHAM l ON s.MALOAI = l.MALOAI
GROUP BY l.TENLOAI;

-- CÂU 9: Truy vấn con vô hướng (Subquery với MAX)
-- Mục đích: Tìm thông tin sản phẩm có giá bán đắt nhất cửa hàng.
SELECT MASP, TENSP, CHATLIEU, GIABAN 
FROM SANPHAM 
WHERE GIABAN = (SELECT MAX(GIABAN) FROM SANPHAM);

-- CÂU 10: Truy vấn con tương quan (Subquery với NOT EXISTS)
-- Mục đích: Tìm các sản phẩm tồn kho chưa từng được bán ra trong hóa đơn nào.
SELECT s.MASP, s.TENSP, s.SOLUONGTON
FROM SANPHAM s
WHERE NOT EXISTS (
    SELECT 1 
    FROM CT_HOADON c 
    WHERE c.MASP = s.MASP
);

-- CÂU 11: Đối chiếu tồn kho (Tổng Nhập - Tổng Bán = Tồn Kho)
-- Mục đích: Kiểm tra tồn kho trên hệ thống có khớp với thực tế nhập xuất hay không.
SELECT 
    sp.MASP, 
    sp.TENSP,
    sp.SOLUONGTON AS TON_HE_THONG,
    NVL(nhap.TONG_NHAP, 0) AS TONG_NHAP,
    NVL(ban.TONG_BAN, 0) AS TONG_BAN,
    (NVL(nhap.TONG_NHAP, 0) - NVL(ban.TONG_BAN, 0)) AS TON_THUC_TE,
    CASE 
        WHEN sp.SOLUONGTON = (NVL(nhap.TONG_NHAP, 0) - NVL(ban.TONG_BAN, 0)) THEN N'Khớp'
        ELSE N'Lệch'
    END AS TRANG_THAI_KHO
FROM SANPHAM sp
LEFT JOIN (SELECT MASP, SUM(SOLUONGNHAP) AS TONG_NHAP FROM CT_PHIEUNHAP GROUP BY MASP) nhap 
    ON sp.MASP = nhap.MASP
LEFT JOIN (SELECT MASP, SUM(SOLUONGBAN) AS TONG_BAN FROM CT_HOADON GROUP BY MASP) ban 
    ON sp.MASP = ban.MASP
ORDER BY sp.MASP;

-- CÂU 12: Truy vấn con lồng nhau (Subquery với IN)
-- Mục đích: Liệt kê các khách hàng đã từng mua sản phẩm có chất liệu 'Cotton'.
SELECT MAKH, HOTEN, SDT 
FROM KHACHHANG 
WHERE MAKH IN (
    SELECT h.MAKH 
    FROM HOADON h 
    INNER JOIN CT_HOADON c ON h.MAHD = c.MAHD
    INNER JOIN SANPHAM s ON c.MASP = s.MASP
    WHERE UPPER(s.CHATLIEU) LIKE '%COTTON%' AND h.MAKH IS NOT NULL
);
