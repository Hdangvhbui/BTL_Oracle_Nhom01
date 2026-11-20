# Minh chứng quản trị Instance của Đỗ Hoàng Trung

Mục 4.1 của BTL Oracle nhóm 01. Môi trường thực nghiệm: Oracle Database 19c,
SID ORCL, non-CDB. Các ảnh là ảnh gốc được gửi trong quá trình thực nghiệm;
chỉ đổi tên file để sắp xếp vào thư mục báo cáo.

## Nội dung đã thực nghiệm

- Khởi động theo ba giai đoạn NOMOUNT, MOUNT và OPEN.
- Bốn chế độ shutdown NORMAL, TRANSACTIONAL, IMMEDIATE và ABORT.
- READ ONLY: SELECT thành công, INSERT bị chặn; mở lại READ WRITE và thử ghi.
- Restricted Session: phiên đang kết nối vẫn hoạt động, kết nối mới không có
  quyền bị chặn; tắt hạn chế và đăng nhập lại thành công.

## Đọc bộ ảnh

- Ảnh 04 cho thấy phiên SYSDBA đang chờ NORMAL. Ảnh 04b ghi lại riêng phiên
  người dùng đã kết nối trước đó; đây là hai ảnh ở các thời điểm khác nhau.
- Một ảnh 07_08 chứa cả COMMIT, kết quả shutdown và SELECT dữ liệu sau startup,
  nên dùng chung để đối chiếu hai mốc 07 và 08 trong kịch bản SQL.
- Ảnh khởi động sau ABORT chứng minh trạng thái OPEN và giá trị dữ liệu.
  Chi tiết nội bộ của instance recovery nằm trong alert log, không hiện ở ảnh này.
- Một số ảnh còn có lịch sử lỗi của phiên đã bị ngắt trước đó. Khi viết báo cáo,
  đối chiếu các lệnh và kết quả tương ứng với tên ảnh.

## File đi kèm trong repo

- Script: `sql/05_instance.sql`.
- Log đã tạo trên máy thực nghiệm: `01_startup.log` đến
  `07_restricted_session.log` trong cùng thư mục này.
- File ZIP chỉ chứa ảnh và tài liệu chỉ mục; các log cần lấy từ máy thực nghiệm.
- Thí nghiệm đã hoàn thành. Nội dung mục 4.1 trong báo cáo Word cần được soạn
  và chèn các ảnh minh chứng phù hợp.

## Chỉ mục ảnh

| File | Nội dung |
| --- | --- |
| `H4.1_01_NOMOUNT.png` | Instance STARTED sau STARTUP NOMOUNT |
| `H4.1_02_MOUNT.png` | Instance MOUNTED sau ALTER DATABASE MOUNT |
| `H4.1_03_OPEN.png` | Instance OPEN va database READ WRITE |
| `H4.1_04_NORMAL_Dang_cho.png` | SYSDBA dang cho tai SHUTDOWN NORMAL |
| `H4.1_04b_NORMAL_Phien_nguoi_dung.png` | Phien FASHION_ADMIN da ket noi truoc khi thu NORMAL |
| `H4.1_05_NORMAL_Hoan_tat.png` | NORMAL da tat xong, khoi dong lai ve OPEN |
| `H4.1_06_TRANSACTIONAL_Dang_cho.png` | TRANSACTIONAL cho giao dich UPDATE chua commit |
| `H4.1_07_08_TRANSACTIONAL_Hoan_tat_va_du_lieu.png` | COMMIT, shutdown hoan tat va du lieu con nguyen sau startup |
| `H4.1_09_IMMEDIATE_Truoc_shutdown.png` | Thay doi IMMEDIATE chua COMMIT trong phien nguoi dung |
| `H4.1_10_IMMEDIATE_Hoan_tat.png` | SHUTDOWN IMMEDIATE hoan tat |
| `H4.1_11_IMMEDIATE_Rollback.png` | Sau startup, gia tri tro ve ban da commit |
| `H4.1_12_ABORT_Truoc_shutdown.png` | Thay doi ABORT chua COMMIT |
| `H4.1_13_ABORT_Hoan_tat.png` | SHUTDOWN ABORT hoan tat |
| `H4.1_14_ABORT_Sau_khoi_dong.png` | Khoi dong lai OPEN, thay doi chua commit khong duoc giu |
| `H4.1_15_READ_ONLY_Trang_thai.png` | Database OPEN READ ONLY |
| `H4.1_16_READ_ONLY_Chan_INSERT.png` | SELECT thanh cong, INSERT bi chan voi ORA-16000 |
| `H4.1_17_READ_WRITE_Ghi_thanh_cong.png` | Database READ WRITE, INSERT va SELECT thanh cong |
| `H4.1_18_RESTRICTED_Phien_cu_van_chay.png` | LOGINS RESTRICTED, phien da ket noi van SELECT duoc |
| `H4.1_19_RESTRICTED_Chan_ket_noi_moi.png` | Ket noi moi bi chan voi ORA-01035 khi LOGINS RESTRICTED |
| `H4.1_20_RESTRICTED_Tat_han_che.png` | LOGINS ALLOWED, FASHION_ADMIN dang nhap lai thanh cong |
