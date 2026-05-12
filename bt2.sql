-- 1. Script Khởi tạo Cấu trúc và Dữ liệu (500.000 dòng)
-- Đầu tiên, chúng ta tạo bảng và viết Procedure.
-- Mẹo nhỏ: Khi INSERT một lượng dữ liệu khổng lồ (500.000 dòng) bằng vòng lặp, 
-- bạn nên đặt nó trong một Transaction (START TRANSACTION và COMMIT). Nếu không, mỗi lệnh INSERT sẽ tự động commit (ghi vào ổ cứng) 1 lần, khiến thời gian chạy mất hàng giờ đồng hồ thay vì vài giây.
-- Tạo bảng Patients
CREATE TABLE Patients (
    Patient_ID INT AUTO_INCREMENT PRIMARY KEY,
    Full_Name VARCHAR(100),
    Phone VARCHAR(20),
    Age INT,
    Address VARCHAR(255)
);

-- Tạo Procedure giả lập 500.000 dòng dữ liệu
DELIMITER //
CREATE PROCEDURE SeedPatients()
BEGIN
    DECLARE i INT DEFAULT 1;
    
    -- Gom vào 1 Transaction để tăng tốc độ Insert hàng loạt
    START TRANSACTION; 
    
    WHILE i <= 500000 DO
        INSERT INTO Patients (Full_Name, Phone, Age, Address)
        VALUES (CONCAT('Patient ', i), CONCAT('090', i), FLOOR(RAND()*100), 'Ho Chi Minh City');
        SET i = i + 1;
    END WHILE;
    
    COMMIT;
END //
DELIMITER ;

-- Gọi Procedure để nạp dữ liệu (Sẽ mất một lúc để chạy)
-- CALL SeedPatients();
-- 2. Kịch bản Kiểm thử HIỆU NĂNG ĐỌC (SELECT)
-- Chạy các lệnh sau và chú ý vào mục Duration / Execution Time trong trình quản lý Database của bạn (ví dụ: MySQL Workbench, DBeaver).

-- KHI CHƯA CÓ INDEX:

-- 1. Đo thời gian truy vấn
SELECT * FROM Patients WHERE Phone = '090250000';

-- 2. Dùng EXPLAIN để xem cách DB tìm kiếm
EXPLAIN SELECT * FROM Patients WHERE Phone = '090250000';
-- Nhận xét: Ở cột 'type' sẽ hiện là 'ALL', cột 'rows' sẽ xấp xỉ 500.000. 
-- DB đang phải quét toàn bộ bảng (Full Table Scan).
-- TẠO INDEX VÀ KIỂM THỬ LẠI:

-- Tạo Index trên cột Phone
CREATE INDEX idx_phone ON Patients(Phone);

-- 1. Đo lại thời gian truy vấn
SELECT * FROM Patients WHERE Phone = '090250000';
-- Tốc độ lúc này sẽ giảm từ ~3 giây xuống còn ~0.00x giây.

-- 2. Dùng EXPLAIN để kiểm tra
EXPLAIN SELECT * FROM Patients WHERE Phone = '090250000';
-- Nhận xét: Ở cột 'type' sẽ hiện là 'ref', cột 'rows' sẽ là 1. 
-- DB đã dùng cây tìm kiếm (B-Tree), tra thẳng vào dữ liệu.
-- 3. Kịch bản Kiểm thử HIỆU NĂNG GHI (INSERT)
-- Để đánh giá sự "đánh đổi", chúng ta sẽ tạo một Procedure chuyên chèn thêm 1.000 bệnh nhân mới (không dùng Transaction gom chung để đo lường chính xác tác động của Index lên từng lệnh ghi).

DELIMITER //

CREATE PROCEDURE TestInsert()
BEGIN
    -- Khai báo biến đếm i, bắt đầu từ 1
    DECLARE i INT DEFAULT 1;

    -- Chạy vòng lặp 1000 lần
    WHILE i <= 1000 DO
        -- Mỗi lần lặp sẽ chèn 1 dòng dữ liệu ảo
        -- Dùng RAND() để random đuôi số điện thoại cho khỏi trùng
        INSERT INTO Patients (Full_Name, Phone, Age, Address)
        VALUES ('Benh Nhan Test', CONCAT('099', FLOOR(RAND() * 1000000)), 30, 'HCM');
        
        -- Tăng biến đếm (quên dòng này là lặp vô hạn treo máy)
        SET i = i + 1;
    END WHILE;
END //

DELIMITER ;
-- DELIMITER ;
-- Cách thực hiện kiểm thử Ghi:

-- Xóa Index đi (nếu đang có): DROP INDEX idx_phone ON Patients;

-- Chạy và đo thời gian: CALL TestInsertPerformance(); (Ghi lại thời gian).

-- Tạo lại Index: CREATE INDEX idx_phone ON Patients(Phone);

-- Chạy và đo thời gian lần 2: CALL TestInsertPerformance(); (Ghi lại thời gian).

-- Bạn sẽ nhận thấy thời gian chạy ở bước 4 lâu hơn rõ rệt so với bước 2.

-- 4. Tổng hợp Báo cáo: Sự "Đánh Đổi" (Trade-off)
-- Từ các bài test trên, bạn có thể rút ra kết luận cốt lõi về bản chất của Index:

-- Tốc độ Đọc (SELECT) - Tăng đột phá: Index hoạt động như mục lục của một cuốn sách. 
-- Thay vì phải lật từng trang từ đầu đến cuối (Full Table Scan), hệ thống sử dụng cấu trúc cây B-Tree để nhảy thẳng đến vị trí chứa số điện thoại cần tìm. Điều này giải quyết dứt điểm vấn đề ùn tắc 3 giây của bộ phận tiếp tân.

-- Tốc độ Ghi (INSERT/UPDATE/DELETE) - Chậm đi: Đây là cái giá phải trả. 
-- Khi bảng có Index, mỗi lần bộ phận tiếp tân thêm một bệnh nhân mới, hệ thống không chỉ ghi dữ liệu vào bảng Patients mà còn phải tốn tài nguyên để sắp xếp và cập nhật lại "mục lục" (idx_phone).

-- Ứng dụng thực tế: Việc đánh Index trên cột Phone 
-- trong trường hợp này là hoàn toàn xứng đáng. Tần suất tìm kiếm bệnh nhân tái khám để xếp phòng là cực kỳ cao và yêu cầu tốc độ phản hồi tức thời. Trong khi đó, việc thêm mới 1 bệnh nhân mất thêm vài mili-giây (do Index) là mức độ trễ có thể chấp nhận được đối với thao tác nhập liệu của con người.

-- Nguyên tắc vàng khi thiết kế: Chỉ tạo Index trên những cột thường xuyên được đặt trong điều kiện WHERE, JOIN hoặc ORDER BY, và tuyệt đối không lạm dụng 
-- Index trên mọi cột để tránh làm sập hiệu năng hệ thống khi ghi dữ liệu.