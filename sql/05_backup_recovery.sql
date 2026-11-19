-- MỤC 5: KỊCH BẢN SAO LƯU & PHỤC HỒI CSDL

-- PHẦN I: KỊCH BẢN RMAN CHÍNH (SAO LƯU VẬT LÝ & ARCHIVELOG)

-- BƯỚC 1: KIỂM TRA TRẠNG THÁI ARCHIVELOG (Chạy bằng SYS / SYSDBA)
-- Đảm bảo Database đang ở chế độ ARCHIVELOG để khôi phục được tới từng giao dịch
SELECT LOG_MODE FROM V$DATABASE;
ARCHIVE LOG LIST;

-- BƯỚC 2: TẠO BẢNG THỬ NGHIỆM VÀ NẠP 5 DÒNG TRƯỚC KHI BACKUP (Chạy bằng FASHION_ADMIN)
DROP TABLE REC_TEST PURGE;
CREATE TABLE REC_TEST (
    ID NUMBER PRIMARY KEY,
    NOI_DUNG VARCHAR2(100)
);

INSERT INTO REC_TEST VALUES (1, 'Du lieu dong 1');
INSERT INTO REC_TEST VALUES (2, 'Du lieu dong 2');
INSERT INTO REC_TEST VALUES (3, 'Du lieu dong 3');
INSERT INTO REC_TEST VALUES (4, 'Du lieu dong 4');
INSERT INTO REC_TEST VALUES (5, 'Du lieu dong 5 - Truoc backup');
COMMIT;

SELECT * FROM REC_TEST ORDER BY ID;

-- BƯỚC 3: TIẾN HÀNH SAO LƯU RMAN (Mở CMD gõ: rman target /)
/*
  CÂU LỆNH GÕ TRONG CỬA SỔ CMD RMAN:
  rman target /
  RMAN> BACKUP TABLESPACE TBS_FASHION_DATA;
  RMAN> EXIT;
*/

-- BƯỚC 4: CHÈN THÊM DÒNG THỨ 6 SAU BACKUP & GIẢ LẬP SỰ CỐ (Chạy bằng FASHION_ADMIN)
-- Thử thách: Dòng số 6 được chèn sau khi đã backup, RMAN vẫn phải cứu được nhờ Redo Log!
INSERT INTO REC_TEST VALUES (6, 'Du lieu dong 6 - Sau backup');
COMMIT;

SELECT * FROM REC_TEST ORDER BY ID;

-- Giả lập sự cố: Đưa Datafile của Tablespace này OFFLINE (Chạy bằng SYS / SYSDBA)
ALTER DATABASE DATAFILE 'D:\oracle_btl\FASHION_DATA01.DBF' OFFLINE;

-- BƯỚC 5: PHỤC HỒI DỮ LIỆU BẰNG RMAN (Mở CMD gõ: rman target /)
/*
  CÂU LỆNH GÕ TRONG CỬA SỔ CMD RMAN:
  rman target /
  RMAN> RESTORE TABLESPACE TBS_FASHION_DATA;
  RMAN> RECOVER TABLESPACE TBS_FASHION_DATA;
  RMAN> EXIT;
*/

-- BƯỚC 6: ĐƯA DATAFILE ONLINE TRỞ LẠI & ĐỐI CHIẾU DỮ LIỆU (Chạy bằng SYS / SYSDBA)
ALTER DATABASE DATAFILE 'D:\oracle_btl\FASHION_DATA01.DBF' ONLINE;

-- Đăng nhập lại bằng FASHION_ADMIN kiểm tra đủ cả 6 dòng:
SELECT * FROM REC_TEST ORDER BY ID;

-- PHẦN II: KỊCH BẢN DATA PUMP BỔ TRỢ (SAO LƯU LOGIC SCHEMA)

-- BƯỚC 1: KHỞI TẠO DIRECTORY VÀ CẤP QUYỀN (Chạy bằng SYS / SYSDBA)
CREATE OR REPLACE DIRECTORY DIR_BTL AS 'D:\oracle_btl';
GRANT READ, WRITE ON DIRECTORY DIR_BTL TO FASHION_ADMIN;
GRANT DATAPUMP_EXP_FULL_DATABASE, DATAPUMP_IMP_FULL_DATABASE TO FASHION_ADMIN;

-- BƯỚC 2: XUẤT TOÀN BỘ SCHEMA BẰNG EXPDP (Mở CMD Windows gõ)
/*
  CÂU LỆNH GÕ TRONG CMD:
  -------------------------------------------------------------
  expdp FASHION_ADMIN/Admin123456 DIRECTORY=DIR_BTL DUMPFILE=fashion_backup.dmp SCHEMAS=FASHION_ADMIN REUSE_DUMPFILES=YES LOGFILE=exp_fashion.log
  -------------------------------------------------------------
  (Nếu mật khẩu FASHION_ADMIN đổi thành Hdangdz.vcl1 thì thay tương ứng)
*/

-- BƯỚC 3: GIẢ LẬP SỰ CỐ XÓA NHẦM BẢNG DỮ LIỆU (Chạy bằng FASHION_ADMIN)
DROP TABLE REC_TEST PURGE;

-- Kiểm tra xác nhận bảng đã bị xóa mất hoàn toàn khỏi CSDL:
-- Lệnh dưới sẽ báo lỗi: ORA-00942: table or view does not exist
SELECT * FROM REC_TEST;

-- BƯỚC 4: PHỤC HỒI BẢNG TỪ FILE DUMP BẰNG IMPDP (Mở CMD Windows gõ)
/*
  CÂU LỆNH GÕ TRONG CMD:
  -------------------------------------------------------------
  impdp FASHION_ADMIN/Admin123456 DIRECTORY=DIR_BTL DUMPFILE=fashion_backup.dmp TABLES=REC_TEST LOGFILE=imp_fashion.log
  -------------------------------------------------------------
*/

-- BƯỚC 5: ĐỐI CHIẾU DỮ LIỆU SAU PHỤC HỒI (Chạy bằng FASHION_ADMIN)
-- Xác nhận bảng REC_TEST đã được hồi sinh nguyên vẹn đủ 6 dòng:
SELECT * FROM REC_TEST ORDER BY ID;