-- =======================================================
-- 1. LOAISANPHAM (5 bản ghi)
-- =======================================================
INSERT INTO LOAISANPHAM VALUES ('L01', N'Áo sơ mi', N'Sơ mi công sở, sơ mi kiểu vải lụa và cotton cao cấp');
INSERT INTO LOAISANPHAM VALUES ('L02', N'Áo thun Polo', N'Thun cotton cá sấu co giãn 4 chiều thoáng mát');
INSERT INTO LOAISANPHAM VALUES ('L03', N'Quần âu Slimfit', N'Quần tây âu công sở thanh lịch, đứng form');
INSERT INTO LOAISANPHAM VALUES ('L04', N'Quần Jean Denim', N'Quần bò phong cách trẻ trung năng động');
INSERT INTO LOAISANPHAM VALUES ('L05', N'Áo khoác Blazer', N'Áo khoác thu đông trang nhã');

-- =======================================================
-- 2. SANPHAM (12 SKU: đủ size, màu, có SKU tồn thấp)
-- =======================================================
INSERT INTO SANPHAM VALUES ('SP01', N'Áo sơ mi trắng Oxford', 'M', N'Trắng', N'Cotton Oxford', 350000, 48, 'L01');
INSERT INTO SANPHAM VALUES ('SP02', N'Áo sơ mi trắng Oxford', 'L', N'Trắng', N'Cotton Oxford', 350000, 30, 'L01');
INSERT INTO SANPHAM VALUES ('SP03', N'Áo sơ mi lụa Pastel', 'M', N'Xanh nhạt', N'Lụa tơ tằm', 420000, 25, 'L01');
INSERT INTO SANPHAM VALUES ('SP04', N'Áo Polo Classic', 'M', N'Đen', N'CVC cá sấu', 280000, 59, 'L02');
INSERT INTO SANPHAM VALUES ('SP05', N'Áo Polo Classic', 'L', N'Đen', N'CVC cá sấu', 280000, 40, 'L02');
INSERT INTO SANPHAM VALUES ('SP06', N'Áo Polo Classic', 'XL', N'Trắng', N'CVC cá sấu', 290000, 35, 'L02');
INSERT INTO SANPHAM VALUES ('SP07', N'Quần âu Slimfit', 'M', N'Đen', N'Kaki tuyết mưa', 450000, 28, 'L03');
INSERT INTO SANPHAM VALUES ('SP08', N'Quần âu Slimfit', 'L', N'Xám chì', N'Kaki tuyết mưa', 450000, 20, 'L03');
INSERT INTO SANPHAM VALUES ('SP09', N'Quần Jean ống đứng', 'L', N'Xanh đậm', N'Denim co giãn', 520000, 34, 'L04');
INSERT INTO SANPHAM VALUES ('SP10', N'Quần Jean ống suông', 'XL', N'Xanh nhạt', N'Denim thô', 490000, 14, 'L04');
INSERT INTO SANPHAM VALUES ('SP11', N'Áo Blazer Hàn Quốc', 'L', N'Be sáng', N'Dạ ép cao cấp', 850000, 8, 'L05');
INSERT INTO SANPHAM VALUES ('SP12', N'Áo Blazer Classic', 'XL', N'Đen', N'Tuytsi cao cấp', 890000, 10, 'L05');

-- =======================================================
-- 3. NHACUNGCAP (5 bản ghi - Có NCC chưa phát sinh nhập)
-- =======================================================
INSERT INTO NHACUNGCAP VALUES ('NCC01', N'Tổng Công ty May 10', N'Gia Lâm, Hà Nội', '02438271501', 'contact@may10.vn');
INSERT INTO NHACUNGCAP VALUES ('NCC02', N'Công ty Dệt May Việt Tiến', N'Tân Bình, TP.HCM', '02838640800', 'viettien@vtec.com.vn');
INSERT INTO NHACUNGCAP VALUES ('NCC03', N'Xưởng Dệt Hanosimex', N'Hà Đông, Hà Nội', '02433824200', 'kd@hanosimex.com.vn');
INSERT INTO NHACUNGCAP VALUES ('NCC04', N'Công ty Dệt May Phong Phú', N'Thủ Đức, TP.HCM', '02838963533', 'info@phongphu.com.vn');
INSERT INTO NHACUNGCAP VALUES ('NCC05', N'Thời trang cao cấp An Phước', N'Quận 5, TP.HCM', '02838300588', 'sales@anphuoc.com.vn');

-- =======================================================
-- 4. NHANVIEN (5 bản ghi đại diện các vị trí)
-- =======================================================
INSERT INTO NHANVIEN VALUES ('NV01', N'Bùi Hải Đăng', TO_DATE('05/05/2004','DD/MM/YYYY'), N'Nam', '0981234567', N'Cửa hàng trưởng', 16000000);
INSERT INTO NHANVIEN VALUES ('NV02', N'Đỗ Hoàng Trung', TO_DATE('12/08/2004','DD/MM/YYYY'), N'Nam', '0972345678', N'Quản lý kho', 12000000);
INSERT INTO NHANVIEN VALUES ('NV03', N'Lầu Quốc An', TO_DATE('20/03/2004','DD/MM/YYYY'), N'Nam', '0963456789', N'Thu ngân', 8500000);
INSERT INTO NHANVIEN VALUES ('NV04', N'Phạm Tiến Dũng', TO_DATE('15/11/2004','DD/MM/YYYY'), N'Nam', '0914567890', N'Nhân viên bán hàng', 8000000);
INSERT INTO NHANVIEN VALUES ('NV05', N'Phùng Quang Minh', TO_DATE('28/07/2004','DD/MM/YYYY'), N'Nam', '0905678901', N'Thu ngân', 8500000);

-- =======================================================
-- 5. KHACHHANG (6 bản ghi định danh)
-- =======================================================
INSERT INTO KHACHHANG VALUES ('KH01', N'Trần Đình Trọng', '0945112233', N'Cầu Giấy, Hà Nội');
INSERT INTO KHACHHANG VALUES ('KH02', N'Nguyễn Thu Thảo', '0936223344', N'Đống Đa, Hà Nội');
INSERT INTO KHACHHANG VALUES ('KH03', N'Lê Minh Tuấn', '0912334455', N'Ba Đình, Hà Nội');
INSERT INTO KHACHHANG VALUES ('KH04', N'Phạm Hồng Hạnh', '0977445566', N'Thanh Xuân, Hà Nội');
INSERT INTO KHACHHANG VALUES ('KH05', N'Vũ Hoàng Nam', '0988556677', N'Hà Đông, Hà Nội');
INSERT INTO KHACHHANG VALUES ('KH06', N'Đỗ Bích Phương', '0901998877', N'Hai Bà Trưng, Hà Nội');

-- =======================================================
-- 6. PHIEUNHAP (6 phiếu nhập)
-- =======================================================
INSERT INTO PHIEUNHAP VALUES ('PN01', TO_DATE('01/09/2026','DD/MM/YYYY'), 'NCC01', 'NV02');
INSERT INTO PHIEUNHAP VALUES ('PN02', TO_DATE('05/09/2026','DD/MM/YYYY'), 'NCC02', 'NV02');
INSERT INTO PHIEUNHAP VALUES ('PN03', TO_DATE('15/09/2026','DD/MM/YYYY'), 'NCC03', 'NV02');
INSERT INTO PHIEUNHAP VALUES ('PN04', TO_DATE('02/10/2026','DD/MM/YYYY'), 'NCC01', 'NV02');
INSERT INTO PHIEUNHAP VALUES ('PN05', TO_DATE('10/10/2026','DD/MM/YYYY'), 'NCC04', 'NV02');
INSERT INTO PHIEUNHAP VALUES ('PN06', TO_DATE('20/10/2026','DD/MM/YYYY'), 'NCC02', 'NV02');

-- =======================================================
-- 7. CT_PHIEUNHAP (Chi tiết nhập hàng)
-- =======================================================
INSERT INTO CT_PHIEUNHAP VALUES ('PN01', 'SP01', 50, 220000);
INSERT INTO CT_PHIEUNHAP VALUES ('PN01', 'SP02', 30, 220000);
INSERT INTO CT_PHIEUNHAP VALUES ('PN02', 'SP04', 60, 160000);
INSERT INTO CT_PHIEUNHAP VALUES ('PN02', 'SP05', 40, 160000);
INSERT INTO CT_PHIEUNHAP VALUES ('PN03', 'SP07', 30, 270000);
INSERT INTO CT_PHIEUNHAP VALUES ('PN03', 'SP08', 20, 270000);
INSERT INTO CT_PHIEUNHAP VALUES ('PN04', 'SP03', 25, 260000);
INSERT INTO CT_PHIEUNHAP VALUES ('PN04', 'SP09', 35, 330000);
INSERT INTO CT_PHIEUNHAP VALUES ('PN05', 'SP10', 15, 310000);
INSERT INTO CT_PHIEUNHAP VALUES ('PN05', 'SP11', 10, 520000);
INSERT INTO CT_PHIEUNHAP VALUES ('PN06', 'SP06', 35, 170000);
INSERT INTO CT_PHIEUNHAP VALUES ('PN06', 'SP12', 10, 550000);

-- =======================================================
-- 8. HOADON (8 hóa đơn: có khách định danh và 2 khách lẻ)
-- =======================================================
INSERT INTO HOADON VALUES ('HD01', TO_DATE('05/10/2026','DD/MM/YYYY'), 'NV03', 'KH01');
INSERT INTO HOADON VALUES ('HD02', TO_DATE('08/10/2026','DD/MM/YYYY'), 'NV03', 'KH02');
INSERT INTO HOADON VALUES ('HD03', TO_DATE('12/10/2026','DD/MM/YYYY'), 'NV05', NULL);
INSERT INTO HOADON VALUES ('HD04', TO_DATE('15/10/2026','DD/MM/YYYY'), 'NV03', 'KH04');
INSERT INTO HOADON VALUES ('HD05', TO_DATE('18/10/2026','DD/MM/YYYY'), 'NV05', 'KH01');
INSERT INTO HOADON VALUES ('HD06', TO_DATE('22/10/2026','DD/MM/YYYY'), 'NV03', NULL);
INSERT INTO HOADON VALUES ('HD07', TO_DATE('25/10/2026','DD/MM/YYYY'), 'NV05', 'KH05');
INSERT INTO HOADON VALUES ('HD08', TO_DATE('28/10/2026','DD/MM/YYYY'), 'NV03', 'KH02');

-- =======================================================
-- 9. CT_HOADON (Chi tiết bán - SP12 chưa bán để test NOT EXISTS)
-- =======================================================
INSERT INTO CT_HOADON (MAHD, MASP, SOLUONGBAN, DONGIABAN) VALUES ('HD01', 'SP01', 2, 350000);
INSERT INTO CT_HOADON (MAHD, MASP, SOLUONGBAN, DONGIABAN) VALUES ('HD01', 'SP04', 1, 280000);
INSERT INTO CT_HOADON (MAHD, MASP, SOLUONGBAN, DONGIABAN) VALUES ('HD02', 'SP07', 1, 450000);
INSERT INTO CT_HOADON (MAHD, MASP, SOLUONGBAN, DONGIABAN) VALUES ('HD02', 'SP11', 1, 850000);
INSERT INTO CT_HOADON (MAHD, MASP, SOLUONGBAN, DONGIABAN) VALUES ('HD03', 'SP09', 1, 520000);
INSERT INTO CT_HOADON (MAHD, MASP, SOLUONGBAN, DONGIABAN) VALUES ('HD04', 'SP07', 1, 450000);
INSERT INTO CT_HOADON (MAHD, MASP, SOLUONGBAN, DONGIABAN) VALUES ('HD04', 'SP10', 1, 490000);
INSERT INTO CT_HOADON (MAHD, MASP, SOLUONGBAN, DONGIABAN) VALUES ('HD05', 'SP04', 1, 280000);
INSERT INTO CT_HOADON (MAHD, MASP, SOLUONGBAN, DONGIABAN) VALUES ('HD06', 'SP01', 1, 350000);
INSERT INTO CT_HOADON (MAHD, MASP, SOLUONGBAN, DONGIABAN) VALUES ('HD07', 'SP11', 1, 850000);
INSERT INTO CT_HOADON (MAHD, MASP, SOLUONGBAN, DONGIABAN) VALUES ('HD08', 'SP08', 1, 450000);

COMMIT;


SELECT sp.MASP, sp.TENSP, sp.SOLUONGTON AS TON_TRONG_BANG,
       NVL(SUM(ctn.SOLUONGNHAP), 0) - NVL(ban.TONG_BAN, 0) AS TON_TINH_TOAN
FROM SANPHAM sp
LEFT JOIN CT_PHIEUNHAP ctn ON sp.MASP = ctn.MASP
LEFT JOIN (
    SELECT MASP, SUM(SOLUONGBAN) AS TONG_BAN 
    FROM CT_HOADON GROUP BY MASP
) ban ON sp.MASP = ban.MASP
GROUP BY sp.MASP, sp.TENSP, sp.SOLUONGTON, ban.TONG_BAN
ORDER BY sp.MASP;