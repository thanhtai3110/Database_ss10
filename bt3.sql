-- Giải pháp SQL hoàn chỉnh

-- 1. KHỞI TẠO DỮ LIỆU MẪU (Từ ảnh)

CREATE TABLE Departments (
    Dept_ID INT PRIMARY KEY,
    Dept_Name VARCHAR(100)
);

CREATE TABLE Invoices (
    Invoice_ID INT PRIMARY KEY,
    Patient_ID INT,
    Dept_ID INT,
    Amount DECIMAL(10, 2)
);

INSERT INTO Departments VALUES 
(1, 'Nội'), 
(2, 'Ngoại');

INSERT INTO Invoices VALUES 
(101, 1, 1, 500.00), 
(102, 2, 1, 300.00), 
(103, 3, 2, 1000.00);


-- 2. TẠO VIEW BÁO CÁO (Gom nhóm & Kết nối 3 bảng)

CREATE VIEW Department_Revenue_View AS
SELECT 
    d.Dept_Name AS Ten_Khoa,
    -- Dùng COUNT(DISTINCT) để đếm số lượng bệnh nhân thực tế, tránh đếm trùng nếu 1 người có 2 hóa đơn
    COUNT(DISTINCT p.Patient_ID) AS Tong_So_Benh_Nhan, 
    SUM(i.Amount) AS Tong_Doanh_Thu
FROM Departments d
JOIN Invoices i ON d.Dept_ID = i.Dept_ID
JOIN Patients p ON i.Patient_ID = p.Patient_ID
GROUP BY d.Dept_ID, d.Dept_Name;

-- 3. KIỂM THỬ TÍNH TOÀN VẸN VÀ BẢO MẬT
-- Bài test 1: Kế toán xem báo cáo (Chỉ thấy số tổng hợp, không thấy dữ liệu thô)
SELECT * FROM Department_Revenue_View;

-- Bài test 2: Giả lập kế toán cố tình sửa số liệu doanh thu trên View
-- Lệnh này sẽ THẤT BẠI và ném ra lỗi.
UPDATE Department_Revenue_View
SET Tong_Doanh_Thu = 90000.00
WHERE Ten_Khoa = 'Nội';
-- Giải thích bản chất kỹ thuật:
--  Luồng thiết kế View:

-- Departments JOIN Invoices theo Dept_ID → GROUP BY từng khoa → tính COUNT(DISTINCT Patient_ID) và SUM(Amount)
-- Bảng Patients trong bài toán đầy đủ sẽ JOIN qua Invoices.Patient_ID → Patients.Dept_ID

-- Lý do View là Read-only: SQL không thể ánh xạ ngược một giá trị tổng hợp (ví dụ Tổng_doanh_thu = 800) về các dòng cụ thể trong bảng Invoices để sửa. Đây là bảo vệ tự động của hệ quản trị CSDL, không cần thêm bất kỳ trigger hay constraint nào.
-- Lệnh UPDATE sẽ bị từ chối với lỗi ERROR 1288 (HY000) trên MySQL, hoặc thông báo tương tự trên PostgreSQL/SQL Server — xác nhận tính minh bạch của báo cáo.