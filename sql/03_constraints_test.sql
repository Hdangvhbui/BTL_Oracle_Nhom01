-- ====================================================================
-- CA 1: VI PHẠM KHÓA CHÍNH (PRIMARY KEY)
-- Thử thêm mã loại 'L01' đã có sẵn trong bảng LOAISANPHAM
-- ====================================================================
INSERT INTO LOAISANPHAM (MALOAI, TENLOAI, MOTA) 
VALUES ('L01', N'Áo dạ mùa đông', N'Thử nghiệm trùng PK');
-- Mong đợi lỗi: ORA-00001: unique constraint (...) violated

-- ====================================================================
-- CA 2: VI PHẠM KHÓA NGOẠI (FOREIGN KEY)
-- Thử thêm sản phẩm mới với MALOAI = 'L99' chưa hề tồn tại
-- ====================================================================
INSERT INTO SANPHAM (MASP, TENSP, KICHCO, MAUSAC, CHATLIEU, GIABAN, SOLUONGTON, MALOAI)
VALUES ('SP99', N'Áo khoác dù', 'L', N'Đen', N'Polyester', 350000, 10, 'L99');
-- Mong đợi lỗi: ORA-02291: integrity constraint (...) violated - parent key not found

-- ====================================================================
-- CA 3: VI PHẠM RÀNG BUỘC CHECK GIÁ BÁN > 0
-- Thử thêm sản phẩm có đơn giá bán âm (-100,000)
-- ====================================================================
INSERT INTO SANPHAM (MASP, TENSP, KICHCO, MAUSAC, CHATLIEU, GIABAN, SOLUONGTON, MALOAI)
VALUES ('SP98', N'Áo lỗi giá bán', 'M', N'Trắng', N'Cotton', -100000, 20, 'L01');
-- Mong đợi lỗi: ORA-02290: check constraint (...) violated

-- ====================================================================
-- CA 4: VI PHẠM RÀNG BUỘC CHECK KÍCH CỠ (SIZE)
-- Thử thêm kích cỡ 'FREE_SIZE' không nằm trong danh mục (S, M, L, XL, XXL)
-- ====================================================================
INSERT INTO SANPHAM (MASP, TENSP, KICHCO, MAUSAC, CHATLIEU, GIABAN, SOLUONGTON, MALOAI)
VALUES ('SP97', N'Áo phông FreeSize', 'FREE_SIZE', N'Xanh', N'Cotton', 200000, 15, 'L02');
-- Mong đợi lỗi: ORA-02290: check constraint (...) violated

ROLLBACK;