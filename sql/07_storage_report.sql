ALTER SESSION SET "_ORACLE_SCRIPT"=TRUE;

-- PHẦN 1: KHẢO SÁT SEGMENTS CỦA CÁC ĐỐI TƯỢNG TRONG SCHEMA FASHION_ADMIN
SELECT 
    segment_name,
    segment_type,
    tablespace_name,
    bytes / 1024 AS size_kb,
    blocks,
    extents
FROM dba_segments
WHERE owner = 'FASHION_ADMIN'
ORDER BY segment_type, segment_name;

-- PHẦN 2: KHẢO SÁT CHI TIẾT EXTENTS CỦA CÁC BẢNG TRỌNG TÂM
SELECT 
    segment_name,
    segment_type,
    extent_id,
    file_id,
    block_id AS start_block,
    blocks,
    bytes / 1024 AS extent_size_kb
FROM dba_extents
WHERE owner = 'FASHION_ADMIN' 
  AND segment_name IN ('SANPHAM', 'HOADON', 'CT_HOADON', 'PHIEUNHAP')
ORDER BY segment_name, extent_id;

-- PHẦN 3: GIẢI MÃ ROWID ĐỂ XÁC ĐỊNH VỊ TRÍ DATA BLOCK VÀ FILE THỰC TẾ
SELECT 
    MASP,
    TENSP,
    ROWID,
    DBMS_ROWID.ROWID_RELATIVE_FNO(ROWID) AS file_number,
    DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID) AS block_number,
    DBMS_ROWID.ROWID_ROW_NUMBER(ROWID)   AS row_number
FROM FASHION_ADMIN.SANPHAM
WHERE ROWNUM <= 5;

-- PHẦN 4: ĐỐI CHIẾU BLOCK CHỨA DÒNG DỮ LIỆU VỚI EXTENT ĐÃ CẤP PHÁT
SELECT 
    e.segment_name,
    e.extent_id,
    e.file_id,
    e.block_id AS extent_start_block,
    e.block_id + e.blocks - 1 AS extent_end_block,
    r.masp,
    r.block_number AS row_in_block
FROM dba_extents e
JOIN (
    SELECT 
        MASP,
        DBMS_ROWID.ROWID_RELATIVE_FNO(ROWID) AS file_id,
        DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID) AS block_number
    FROM FASHION_ADMIN.SANPHAM
    WHERE ROWNUM = 1
) r ON e.file_id = r.file_id 
   AND r.block_number BETWEEN e.block_id AND (e.block_id + e.blocks - 1)
WHERE e.owner = 'FASHION_ADMIN' 
  AND e.segment_name = 'SANPHAM';