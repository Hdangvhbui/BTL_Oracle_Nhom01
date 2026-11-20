-- =====================================================================
-- BTL ORACLE NHOM 01 - MUC 4.1 QUAN TRI INSTANCE
-- Nguoi thuc hien: Do Hoang Trung
-- Moi truong da thuc nghiem: Oracle Database 19c, SID ORCL, non-CDB
-- Repo: https://github.com/Hdangvhbui/BTL_Oracle_Nhom01
-- =====================================================================
-- CACH SU DUNG
-- 1. Doc toan bo file truoc khi chay. File co STARTUP va SHUTDOWN.
-- 2. Phien A: SQL*Plus ket noi bang sqlplus / as sysdba, database dang OPEN.
-- 3. Phien B: CMD khac, ket noi FASHION_ADMIN khi duoc huong dan.
-- 4. Phien C: CMD thu ba de thu ket noi moi khi bat Restricted Session.
-- 5. Dong cac phien nguoi dung khong tham gia thi nghiem truoc khi bat dau.
-- 6. Tai khoan FASHION_ADMIN va tablespace du an phai duoc tao truoc.
-- 7. Lenh cua phien B/C duoc in bang PROMPT, nguoi thuc hien tu nhap.
--    Khong nhap cac lenh B/C vao phien A. Khong luu mat khau vao file nay.
-- 8. Khi PAUSE, hoan thanh huong dan roi nhan Enter tai phien A.
-- 9. Co the thuc hien rieng tung muc de demo; moi muc can database OPEN.
-- 10. LAB_INSTANCE_TRUNG la bang thi nghiem rieng, khong thuoc 9 bang
--     nghiep vu. ID 1 la dong doi chieu; ID 2 danh cho INSERT/ROLLBACK.
--     Khoi chuan bi dat lai GHICHU cua ID 1 de lap lai thi nghiem.
--
-- Nguon doi chieu:
-- https://docs.oracle.com/en/database/oracle/oracle-database/19/admin/starting-up-and-shutting-down.html
-- https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/V-INSTANCE.html

SET ECHO ON
SET VERIFY OFF
SET LINESIZE 150
SET PAGESIZE 100
SET AUTOCOMMIT OFF
COLUMN GHICHU FORMAT A45
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

-- Sua duong dan nay neu chay tren may khac.
DEFINE evidence_dir = G:\BTL_Oracle_Nhom01\docs\evidence\4.1_instance_trung
HOST mkdir "&evidence_dir"

-- Kiem tra phien A, trang thai va cau hinh database.
SHOW USER
SELECT INSTANCE_NAME, STATUS, LOGINS FROM V$INSTANCE;
SELECT NAME, OPEN_MODE, CDB FROM V$DATABASE;

DECLARE
    v_count NUMBER;
BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') <> 'SYS' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Phien A phai ket noi SYSDBA bang SYS.');
    END IF;
    SELECT COUNT(*) INTO v_count
    FROM V$DATABASE
    WHERE OPEN_MODE = 'READ WRITE' AND CDB = 'NO';
    IF v_count <> 1 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Can database non-CDB dang READ WRITE.');
    END IF;
END;
/

-- Tao bang lab neu chua co; giu nguyen bang neu da ton tai.
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM DBA_TABLES
    WHERE OWNER = 'FASHION_ADMIN' AND TABLE_NAME = 'LAB_INSTANCE_TRUNG';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE TABLE FASHION_ADMIN.LAB_INSTANCE_TRUNG (' ||
            'ID NUMBER PRIMARY KEY, GHICHU VARCHAR2(100))';
    END IF;
END;
/

-- Dat du lieu goc cua dong lab ID 1. Khong thay doi bang nghiep vu.
MERGE INTO FASHION_ADMIN.LAB_INSTANCE_TRUNG t
USING (SELECT 1 AS ID FROM DUAL) s
ON (t.ID = s.ID)
WHEN MATCHED THEN
    UPDATE SET t.GHICHU = 'Du lieu ban dau'
WHEN NOT MATCHED THEN
    INSERT (ID, GHICHU) VALUES (s.ID, 'Du lieu ban dau');
COMMIT;

-- ID 2 phai trong de thu INSERT o muc READ WRITE.
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM FASHION_ADMIN.LAB_INSTANCE_TRUNG WHERE ID = 2;
    IF v_count <> 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'ID 2 cua bang lab da ton tai. Kiem tra truoc khi demo.');
    END IF;
END;
/

PROMPT Dong cac phien nguoi dung khac, chi giu phien A de bat dau.
PAUSE Nhan Enter khi da san sang...

-- =====================================================================
-- 1. KHOI DONG BA GIAI DOAN NOMOUNT - MOUNT - OPEN
-- =====================================================================
SPOOL "&evidence_dir\01_startup.log"

SHUTDOWN IMMEDIATE
STARTUP NOMOUNT
SELECT INSTANCE_NAME, STATUS FROM V$INSTANCE;
-- Mong doi: orcl / STARTED. Instance da khoi dong, database chua mount.
PAUSE Chup H4.1_01_NOMOUNT.png roi nhan Enter...

ALTER DATABASE MOUNT;
SELECT INSTANCE_NAME, STATUS FROM V$INSTANCE;
-- Mong doi: orcl / MOUNTED. Oracle da doc control file.
PAUSE Chup H4.1_02_MOUNT.png roi nhan Enter...

ALTER DATABASE OPEN;
SELECT INSTANCE_NAME, STATUS FROM V$INSTANCE;
SELECT NAME, OPEN_MODE FROM V$DATABASE;
-- Mong doi: OPEN / READ WRITE.
PAUSE Chup H4.1_03_OPEN.png roi nhan Enter...
SPOOL OFF

-- =====================================================================
-- 2. SHUTDOWN NORMAL - CHO NGUOI DUNG NGAT KET NOI
-- =====================================================================
SPOOL "&evidence_dir\02_shutdown_normal.log"
PROMPT PHIEN B: mo CMD moi, chay set ORACLE_SID=ORCL
PROMPT PHIEN B: chay sqlplus FASHION_ADMIN, nhap mat khau khi duoc hoi.
PROMPT PHIEN B: chay SHOW USER, giu ket noi o dau nhac SQL.
PAUSE Nhan Enter tai A khi B da ket noi...
PROMPT A sap chay SHUTDOWN NORMAL va se cho B thoat.
PROMPT Trong luc cho, chup hai phien: H4.1_04_NORMAL_Dang_cho.png
PROMPT SAU KHI CHUP: tai B chay EXIT de A tiep tuc tat database.

SHUTDOWN NORMAL
-- Mong doi: chi hoan tat sau khi cac phien nguoi dung da ngat ket noi.
PAUSE Chup H4.1_05_NORMAL_Hoan_tat.png roi nhan Enter...
STARTUP
SELECT INSTANCE_NAME, STATUS FROM V$INSTANCE;
SPOOL OFF

-- =====================================================================
-- 3. SHUTDOWN TRANSACTIONAL - CHO GIAO DICH KET THUC
-- =====================================================================
SPOOL "&evidence_dir\03_shutdown_transactional.log"
PROMPT PHIEN B: mo ket noi FASHION_ADMIN moi tren ORCL.
PROMPT PHIEN B: SET AUTOCOMMIT OFF
PROMPT PHIEN B: UPDATE LAB_INSTANCE_TRUNG SET GHICHU = 'Dang thu SHUTDOWN TRANSACTIONAL' WHERE ID = 1;
PROMPT PHIEN B: can thay 1 row updated. Giu phien mo, chua COMMIT/EXIT.
PAUSE Nhan Enter tai A khi B da UPDATE va chua COMMIT...
PROMPT A sap chay SHUTDOWN TRANSACTIONAL, cho giao dich cua B ket thuc.
PROMPT Trong luc cho, chup H4.1_06_TRANSACTIONAL_Dang_cho.png
PROMPT SAU KHI CHUP: tai B chi chay COMMIT; khong can EXIT.

SHUTDOWN TRANSACTIONAL
PAUSE Chup H4.1_07_TRANSACTIONAL_Hoan_tat.png roi nhan Enter...
STARTUP
SELECT INSTANCE_NAME, STATUS FROM V$INSTANCE;
SELECT ID, GHICHU FROM FASHION_ADMIN.LAB_INSTANCE_TRUNG WHERE ID = 1;
-- Mong doi: Dang thu SHUTDOWN TRANSACTIONAL (thay doi da COMMIT).
PAUSE Chup H4.1_08_TRANSACTIONAL_Du_lieu_da_luu.png roi nhan Enter...
SPOOL OFF

-- =====================================================================
-- 4. SHUTDOWN IMMEDIATE - ROLLBACK GIAO DICH CHUA COMMIT
-- =====================================================================
SPOOL "&evidence_dir\04_shutdown_immediate.log"
PROMPT PHIEN B: dong cua so cua phien da bi ngat, mo CMD va ket noi moi.
PROMPT PHIEN B: set ORACLE_SID=ORCL, sau do sqlplus FASHION_ADMIN
PROMPT PHIEN B: SET AUTOCOMMIT OFF
PROMPT PHIEN B: COLUMN GHICHU FORMAT A45
PROMPT PHIEN B: SELECT ID, GHICHU FROM LAB_INSTANCE_TRUNG WHERE ID = 1;
PROMPT PHIEN B: UPDATE LAB_INSTANCE_TRUNG SET GHICHU = 'IMMEDIATE chua COMMIT' WHERE ID = 1;
PROMPT PHIEN B: SELECT ID, GHICHU FROM LAB_INSTANCE_TRUNG WHERE ID = 1;
PROMPT Chup H4.1_09_IMMEDIATE_Truoc_shutdown.png; chua COMMIT/EXIT.
PAUSE Nhan Enter tai A khi B da UPDATE va chup anh...

SHUTDOWN IMMEDIATE
-- Oracle rollback giao dich chua commit va ngat phien nguoi dung.
PAUSE Chup H4.1_10_IMMEDIATE_Hoan_tat.png roi nhan Enter...
STARTUP
SELECT INSTANCE_NAME, STATUS FROM V$INSTANCE;
SELECT ID, GHICHU FROM FASHION_ADMIN.LAB_INSTANCE_TRUNG WHERE ID = 1;
-- Mong doi: ve Dang thu SHUTDOWN TRANSACTIONAL, khong giu gia tri IMMEDIATE.
PAUSE Chup H4.1_11_IMMEDIATE_Rollback.png roi nhan Enter...
SPOOL OFF

-- =====================================================================
-- 5. SHUTDOWN ABORT - DUNG DOT NGOT VA KHOI DONG LAI
-- =====================================================================
SPOOL "&evidence_dir\05_shutdown_abort.log"
PROMPT PHIEN B: mo ket noi FASHION_ADMIN MOI tren ORCL.
PROMPT PHIEN B: SET AUTOCOMMIT OFF
PROMPT PHIEN B: COLUMN GHICHU FORMAT A45
PROMPT PHIEN B: UPDATE LAB_INSTANCE_TRUNG SET GHICHU = 'ABORT chua COMMIT' WHERE ID = 1;
PROMPT PHIEN B: SELECT ID, GHICHU FROM LAB_INSTANCE_TRUNG WHERE ID = 1;
PROMPT Chup H4.1_12_ABORT_Truoc_shutdown.png; chua COMMIT/EXIT.
PAUSE Nhan Enter tai A khi B da UPDATE va chup anh...

SHUTDOWN ABORT
-- ABORT khong rollback trong luc shutdown.
-- Lan khoi dong sau Oracle thuc hien instance recovery.
-- SQL*Plus khong nhat thiet in chi tiet recovery; chi tiet o alert log.
PAUSE Chup H4.1_13_ABORT_Hoan_tat.png roi nhan Enter...
STARTUP
SELECT INSTANCE_NAME, STATUS FROM V$INSTANCE;
SELECT ID, GHICHU FROM FASHION_ADMIN.LAB_INSTANCE_TRUNG WHERE ID = 1;
-- Mong doi: OPEN, ve gia tri da COMMIT; khong giu ABORT chua COMMIT.
PAUSE Chup H4.1_14_ABORT_Sau_khoi_dong.png roi nhan Enter...
SPOOL OFF

-- =====================================================================
-- 6. READ ONLY - CHAN GHI, SAU DO TRO LAI READ WRITE
-- =====================================================================
SPOOL "&evidence_dir\06_read_only.log"
SHUTDOWN IMMEDIATE
STARTUP MOUNT
ALTER DATABASE OPEN READ ONLY;
SELECT NAME, OPEN_MODE FROM V$DATABASE;
PAUSE Chup H4.1_15_READ_ONLY_Trang_thai.png roi nhan Enter...

SELECT ID, GHICHU FROM FASHION_ADMIN.LAB_INSTANCE_TRUNG WHERE ID = 1;
-- Loi ORA-16000 o lenh INSERT tiep theo la ket qua mong doi.
WHENEVER SQLERROR CONTINUE NONE
INSERT INTO FASHION_ADMIN.LAB_INSTANCE_TRUNG (ID, GHICHU)
VALUES (2, 'Thu INSERT khi READ ONLY');
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
PAUSE Chup H4.1_16_READ_ONLY_Chan_INSERT.png roi nhan Enter...

SHUTDOWN IMMEDIATE
STARTUP MOUNT
ALTER DATABASE OPEN READ WRITE;
SELECT NAME, OPEN_MODE FROM V$DATABASE;
SET AUTOCOMMIT OFF
INSERT INTO FASHION_ADMIN.LAB_INSTANCE_TRUNG (ID, GHICHU)
VALUES (2, 'Thu INSERT khi READ WRITE');
SELECT ID, GHICHU FROM FASHION_ADMIN.LAB_INSTANCE_TRUNG WHERE ID = 2;
PAUSE Chup H4.1_17_READ_WRITE_Ghi_thanh_cong.png roi nhan Enter...
ROLLBACK;
-- Xoa bo thay doi thu ID 2 bang rollback; giu dong doi chieu ID 1.
SPOOL OFF

-- =====================================================================
-- 7. RESTRICTED SESSION - PHIEN CU VA KET NOI MOI
-- =====================================================================
SPOOL "&evidence_dir\07_restricted_session.log"
ALTER SYSTEM DISABLE RESTRICTED SESSION;
PROMPT PHIEN B: mo CMD va ket noi FASHION_ADMIN MOI TRUOC khi bat han che.
PROMPT PHIEN B: SHOW USER
PROMPT PHIEN B: COLUMN GHICHU FORMAT A45
PROMPT PHIEN B: SELECT ID, GHICHU FROM LAB_INSTANCE_TRUNG WHERE ID = 1;
PROMPT PHIEN B: SELECT PRIVILEGE FROM SESSION_PRIVS WHERE PRIVILEGE = 'RESTRICTED SESSION';
PROMPT Can SELECT thanh cong, quyen RESTRICTED SESSION la no rows selected.
PROMPT Neu co quyen nay thi doi tai khoan thu nghiem truoc khi tiep tuc.
PAUSE Nhan Enter tai A khi B da ket noi va kiem tra xong...

ALTER SYSTEM ENABLE RESTRICTED SESSION;
SELECT INSTANCE_NAME, LOGINS FROM V$INSTANCE;
PROMPT PHIEN B: van giu ket noi, chay lai SELECT tren bang lab.
PROMPT Mong doi: B van SELECT duoc; A hien RESTRICTED.
PAUSE Chup H4.1_18_RESTRICTED_Phien_cu_van_chay.png roi nhan Enter...

PROMPT PHIEN C: mo THEM CMD moi, giu phien A va B.
PROMPT PHIEN C: set ORACLE_SID=ORCL
PROMPT PHIEN C: sqlplus -L FASHION_ADMIN
PROMPT Nhap mat khau, mong doi ORA-01035 va khong ket noi duoc.
PAUSE Chup H4.1_19_RESTRICTED_Chan_ket_noi_moi.png roi nhan Enter...

ALTER SYSTEM DISABLE RESTRICTED SESSION;
SELECT INSTANCE_NAME, STATUS, LOGINS FROM V$INSTANCE;
PROMPT PHIEN C: thu lai sqlplus -L FASHION_ADMIN, nhap mat khau.
PROMPT PHIEN C: SHOW USER, SELECT ID, GHICHU FROM LAB_INSTANCE_TRUNG WHERE ID = 1;
PROMPT Mong doi: A hien OPEN / ALLOWED, C ket noi va SELECT thanh cong.
PAUSE Chup H4.1_20_RESTRICTED_Tat_han_che.png roi nhan Enter...

-- Trang thai cuoi cung phuc vu web va cac phan viec khac.
SELECT NAME, OPEN_MODE FROM V$DATABASE;
SELECT INSTANCE_NAME, STATUS, LOGINS FROM V$INSTANCE;
SPOOL OFF
WHENEVER SQLERROR CONTINUE NONE
PROMPT Hoan thanh Muc 4.1. Database can o trang thai OPEN, READ WRITE, ALLOWED.
PROMPT Bang LAB_INSTANCE_TRUNG duoc giu de doi chieu va demo lai.
PROMPT Ban giao: sql/05_instance.sql, 7 file log va cac anh minh chung.
