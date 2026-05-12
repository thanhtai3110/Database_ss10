-- 1. Khởi tạo cấu trúc và dữ liệu gốc (Dựa trên hình ảnh)
CREATE TABLE Patients (
    Patient_ID INT PRIMARY KEY,
    Full_Name VARCHAR(100),
    Age INT,
    Room_Number INT,
    HIV_Status VARCHAR(50),
    Mental_Health_History VARCHAR(255)
);

INSERT INTO Patients (Patient_ID, Full_Name, Age, Room_Number, HIV_Status, Mental_Health_History)
VALUES 
(1, 'Minh Thu', 30, 101, 'Negative', 'None'),
(2, 'Hồng Vân', 40, 102, 'Positive', 'Anxiety'),
(3, 'Cao Cường', 25, 103, 'Negative', 'None');

-- 2. TẠO VIEW BẢO MẬT THEO YÊU CẦU

CREATE VIEW Reception_Patient_View AS
SELECT 
    Patient_ID, 
    Full_Name, 
    Age, 
    Room_Number
FROM Patients
WHERE Age >= 0
WITH CHECK OPTION;

-- 3. KIỂM THỬ DỮ LIỆU
-- Bài test 1: Kiểm tra View để xác nhận các cột nhạy cảm đã bị ẩn
-- Kết quả trả về sẽ chỉ gồm 4 cột cơ bản, không có HIV_Status hay Mental_Health_History.
SELECT * FROM Reception_Patient_View;

-- Bài test 2: Thực hiện cập nhật tuổi hợp lệ (> 0)
-- Lệnh này sẽ THÀNH CÔNG vì 31 >= 0, thỏa mãn điều kiện của View.
UPDATE Reception_Patient_View
SET Age = 31
WHERE Patient_ID = 1;

-- Bài test 3: Thực hiện cập nhật tuổi không hợp lệ (< 0)
-- Lệnh này sẽ THẤT BẠI (Báo lỗi "CHECK OPTION failed") vì -5 không thỏa mãn điều kiện Age >= 0.
UPDATE Reception_Patient_View
SET Age = -5
WHERE Patient_ID = 3;
-- Giải thích thêm về cơ chế hoạt động:
-- Lọc cột nhạy cảm: Bằng cách chỉ liệt kê Patient_ID, Full_Name, Age, và Room_Number trong câu lệnh SELECT của View, 
-- hệ thống đã tạo ra một "bức tường" che giấu hoàn toàn các cột HIV_Status và Mental_Health_History khỏi người dùng (nhân viên tiếp tân).

-- WITH CHECK OPTION: Mệnh đề này yêu cầu cơ sở dữ liệu kiểm tra mọi dữ liệu được INSERT hoặc UPDATE thông qua View xem có thỏa mãn điều kiện WHERE (ở đây là Age >= 0) hay không. Nếu dữ liệu mới khiến điều kiện WHERE bị sai (ví dụ set tuổi thành -5),
--  hệ thống sẽ chủ động chặn lại bằng một lỗi và hủy bỏ giao dịch đó để bảo vệ dữ liệu gốc.