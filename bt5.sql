-- 1. KHỞI TẠO CẤU TRÚC BẢNG CHO CÁC CHI NHÁNH

-- Chi nhánh miền Bắc
CREATE TABLE Records_North (
    Record_ID INT PRIMARY KEY,
    Patient_Name VARCHAR(100),
    Diagnosis TEXT,
    Record_Date DATE
);

-- Chi nhánh miền Nam
CREATE TABLE Records_South (
    Record_ID INT PRIMARY KEY,
    Patient_Name VARCHAR(100),
    Diagnosis TEXT,
    Record_Date DATE
);

-- Chèn dữ liệu mẫu (Gồm cả trường hợp trùng ID: cả 2 miền đều có ID = 1)
INSERT INTO Records_North VALUES (1, 'Nguyen Van A', 'Flu', '2026-04-28');
INSERT INTO Records_South VALUES (1, 'Le Thi B', 'Cold', '2026-04-28');

-- 2. XÂY DỰNG VIEW "ẢO HÓA" TỔNG HỢP TOÀN QUỐC

CREATE OR REPLACE VIEW National_Record_View AS
-- Lấy dữ liệu từ miền Bắc và gắn nhãn cột ảo 'North'
SELECT 
    Record_ID, 
    Patient_Name, 
    Diagnosis, 
    Record_Date, 
    'North' AS Branch_Name -- Tạo cột định danh ảo
FROM Records_North

UNION ALL

-- Lấy dữ liệu từ miền Nam và gắn nhãn cột ảo 'South'
SELECT 
    Record_ID, 
    Patient_Name, 
    Diagnosis, 
    Record_Date, 
    'South' AS Branch_Name -- Tạo cột định danh ảo
FROM Records_South;

-- 3. KIỂM THỬ VÀ PHÂN TÍCH XUNG ĐỘT

-- Truy vấn View để xem kết quả hợp nhất
SELECT * FROM National_Record_View;

--  PHÂN TÍCH TRƯỜNG HỢP TRÙNG ID:
-- Khi thực hiện SELECT trên View, bạn sẽ thấy 2 dòng dữ liệu có cùng Record_ID = 1.
-- - Dòng 1: Nguyen Van A - North
-- - Dòng 2: Le Thi B - South

-- KẾT LUẬN:
-- 1. View không làm mất dữ liệu nhờ dùng UNION ALL.
-- 2. Cột ảo 'Branch_Name' đóng vai trò cực kỳ quan trọng: 
--    Nó giúp người quản lý biết chính xác bệnh nhân ID=1 đó thuộc chi nhánh nào 
--    để tra cứu hồ sơ gốc khi cần, tránh nhầm lẫn giữa các bệnh nhân khác nhau có cùng mã ID.