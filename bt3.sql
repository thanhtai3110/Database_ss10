-- 1. Thiết kế luồng dữ liệu (Tạo bảng & Dữ liệu mẫu)Đầu tiên, chúng ta cần khởi tạo 3 bảng tương ứng. Bảng Invoices sẽ đóng vai trò là bảng trung gian kết nối giữa Departments và Patients.SQL-- 1. Bảng Khoa
CREATE TABLE Departments (
    Dept_ID INT PRIMARY KEY,
    Dept_Name VARCHAR(100)
);

-- 2. Bảng Bệnh nhân 
CREATE TABLE Patients (
    Patient_ID INT PRIMARY KEY,
    Patient_Name VARCHAR(100)
);

-- 3. Bảng Hóa đơn 
CREATE TABLE Invoices (
    Invoice_ID INT PRIMARY KEY,
    Patient_ID INT,
    Dept_ID INT,
    Amount DECIMAL(10, 2),
    FOREIGN KEY (Dept_ID) REFERENCES Departments(Dept_ID),
    FOREIGN KEY (Patient_ID) REFERENCES Patients(Patient_ID)
);

-- Chèn dữ liệu mẫu để kiểm thử
INSERT INTO Departments VALUES (1, 'Nội'), (2, 'Ngoại');
INSERT INTO Patients VALUES (1, 'Nguyễn Văn A'), (2, 'Trần Thị B'), (3, 'Lê Văn C');
INSERT INTO Invoices VALUES 
    (101, 1, 1, 500.00),  -- Bệnh nhân A, khoa Nội
    (102, 2, 1, 300.00),  -- Bệnh nhân B, khoa Nội
    (103, 3, 2, 1000.00); -- Bệnh nhân C, khoa Ngoại
-- 2. Tạo View báo cáo (Department_Revenue_View)View này sẽ JOIN cả 3 bảng lại với nhau. Việc sử dụng COUNT(DISTINCT p.Patient_ID) đảm bảo rằng nếu một bệnh nhân có nhiều hóa đơn tại cùng một khoa thì họ vẫn chỉ được đếm là 1.SQLCREATE VIEW Department_Revenue_View AS
SELECT 
    d.Dept_Name AS 'Tên Khoa',
    COUNT(DISTINCT p.Patient_ID) AS 'Tổng số bệnh nhân',
    SUM(i.Amount) AS 'Tổng doanh thu'
FROM 
    Departments d
JOIN 
    Invoices i ON d.Dept_ID = i.Dept_ID
JOIN 
    Patients p ON i.Patient_ID = p.Patient_ID
GROUP BY 
    d.Dept_Name;
-- 3. Kiểm thử tính toàn vẹnThực hiện truy vấn SELECT:SQLSELECT * FROM Department_Revenue_View;
-- Kết quả trả về:Tên KhoaTổng số bệnh nhânTổng doanh thuNội 2800.00Ngoại 11000.00Như bạn thấy, thông tin nhạy cảm như Tên bệnh nhân hay Mã bệnh nhân hoàn toàn không xuất hiện trong kết quả này.4. Giả lập hành vi của kế toán (Test UPDATE)Theo lý thuyết về CSDL, bất kỳ View nào có chứa các hàm gộp (SUM, COUNT, MAX, MIN...) hoặc mệnh đề GROUP BY đều không thể cập nhật (Not Updatable).Thử chạy lệnh UPDATE trực tiếp trên View:SQLUPDATE Department_Revenue_View

SET `Tổng doanh thu` = 5000.00
WHERE `Tên Khoa` = 'Nội';