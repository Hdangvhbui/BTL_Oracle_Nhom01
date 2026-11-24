ALTER TABLESPACE TBS_FASHION_LAB 
ADD DATAFILE 'D:\oracle_btl\FASHION_LAB02.DBF' 
SIZE 15M AUTOEXTEND OFF;

-- 2.1 Bật tự động mở rộng dung lượng cho datafile 2
ALTER DATABASE DATAFILE 'D:\oracle_btl\FASHION_LAB02.DBF' 
AUTOEXTEND ON NEXT 5M MAXSIZE 50M;

-- 2.2 Tắt tự động mở rộng
ALTER DATABASE DATAFILE 'D:\oracle_btl\FASHION_LAB02.DBF' 
AUTOEXTEND OFF;

-- 3. Thay đổi kích thước datafile lên 25MB
ALTER DATABASE DATAFILE 'D:\oracle_btl\FASHION_LAB02.DBF' 
RESIZE 25M;

-- 4.1 Tạo bảng test và chèn 2 dòng dữ liệu
ALTER USER FASHION_ADMIN QUOTA UNLIMITED ON TBS_FASHION_LAB;
CREATE TABLE FASHION_ADMIN.TEST_MOVE (
    ID NUMBER PRIMARY KEY,
    NOTE VARCHAR2(50)
) TABLESPACE TBS_FASHION_LAB;

INSERT INTO FASHION_ADMIN.TEST_MOVE VALUES (1, 'Kiem tra di chuyen file');
INSERT INTO FASHION_ADMIN.TEST_MOVE VALUES (2, 'Du lieu an toan');
COMMIT;

-- 4.2 Đưa tablespace offline
ALTER TABLESPACE TBS_FASHION_LAB OFFLINE;

-- 4.3 Cập nhật tên file mới trong metadata Oracle
ALTER TABLESPACE TBS_FASHION_LAB 
RENAME DATAFILE 'D:\oracle_btl\FASHION_LAB02.DBF' 
TO 'D:\oracle_btl\FASHION_LAB02_MOVED.DBF';

-- 4.4 Đưa tablespace online trở lại
ALTER TABLESPACE TBS_FASHION_LAB ONLINE;

-- 4.5 Kiểm tra dữ liệu bảng TEST_MOVE vẫn còn nguyên vẹn
SELECT * FROM FASHION_ADMIN.TEST_MOVE;

-- 5. Thực nghiệm xóa Tablespace thử nghiệm và xóa sạch datafile vật lý
DROP TABLESPACE TBS_FASHION_LAB INCLUDING CONTENTS AND DATAFILES;

-- 6.1 Đổi trạng thái TBS_FASHION_DATA sang READ ONLY
ALTER TABLESPACE TBS_FASHION_DATA READ ONLY;
-- 6.2 [KIỂM CHỨNG 1 - ĐỌC]
SELECT COUNT(*) FROM FASHION_ADMIN.LOAISANPHAM;
-- 6.3 [KIỂM CHỨNG 2 - GHI]: Thử chèn dữ liệu mới
INSERT INTO FASHION_ADMIN.LOAISANPHAM (MALOAI, TENLOAI, MOTA) 
VALUES ('TEST_RO', N'Hàng thử nghiệm', N'Test Read Only');

-- 6.4 Mở lại chế độ ghi bình thường (READ WRITE)
ALTER TABLESPACE TBS_FASHION_DATA READ WRITE;
-- 6.5 [KIỂM CHỨNG 3]: Chèn lại dữ liệu
INSERT INTO FASHION_ADMIN.LOAISANPHAM (MALOAI, TENLOAI, MOTA) 
VALUES ('TEST_RW', N'Hàng thử nghiệm ghi', N'Test Read Write');
COMMIT;

-- Dọn dẹp dòng test vừa chèn
DELETE FROM FASHION_ADMIN.LOAISANPHAM WHERE MALOAI IN ('TEST_RO', 'TEST_RW');
COMMIT;

-- 7.1 Kiểm tra trong dba_tablespaces (kết quả phải trả về 0 dòng)
SELECT tablespace_name, status 
FROM dba_tablespaces 
WHERE tablespace_name = 'TBS_FASHION_LAB';
-- 7.2 Kiểm tra trong dba_data_files (kết quả phải trả về 0 dòng)
SELECT file_name, tablespace_name 
FROM dba_data_files 
WHERE tablespace_name = 'TBS_FASHION_LAB';


-- 8.1 Truy vấn DBA_TABLESPACES: Xem danh sách và thông số các tablespace
SELECT tablespace_name, block_size, initial_extent, status, contents, logging
FROM dba_tablespaces;

-- 8.2 Truy vấn DBA_DATA_FILES: Xem danh sách toàn bộ Datafile vật lý
SELECT file_id, file_name, tablespace_name, bytes / (1024*1024) AS size_mb, autoextensible
FROM dba_data_files
ORDER BY tablespace_name, file_id;

-- 8.3 Truy vấn DBA_FREE_SPACE: Xem dung lượng trống hiện có
SELECT tablespace_name, file_id, COUNT(*) AS free_chunks, ROUND(SUM(bytes) / (1024*1024), 2) AS free_mb
FROM dba_free_space
GROUP BY tablespace_name, file_id
ORDER BY tablespace_name;
