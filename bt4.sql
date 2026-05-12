-- Phân tích giải pháp: Composite Index & Tư duy tối ưu
-- Composite Index : Khi truy vấn có điều kiện WHERE Drug_Name = ... AND Expiry_Date <= ..., 
-- một Composite Index (Drug_Name, Expiry_Date) sẽ hiệu quả hơn nhiều so với 2 Index đơn. 
-- Nó giúp Database tìm chính xác vùng dữ liệu của thuốc đó, rồi lọc ngay theo hạn sử dụng trên cùng một cấu trúc cây chỉ mục.

-- Quy tắc "Cột lọc bằng" đứng trước: Trong Composite Index, cột nào dùng toán tử bằng 
-- (=) nên đứng trước cột dùng toán tử phạm vi (>, <, BETWEEN). Do đó, thứ tự (Drug_Name, Expiry_Date) là tối ưu.

-- Vấn đề với LIKE: * LIKE 'Paracetamol%': Index vẫn hoạt động (Left-prefix matching).

-- LIKE '%cetamol%': Index bị vô hiệu hóa vì Database không biết chuỗi bắt đầu từ đâu để tra cứu trong cây chỉ mục.

-- 1. KHỞI TẠO CẤU TRÚC BẢNG 
CREATE TABLE Pharmacy_Inventory (
    Inventory_ID INT AUTO_INCREMENT PRIMARY KEY,
    Drug_Name VARCHAR(255),
    Batch_Number VARCHAR(50),
    Expiry_Date DATE,
    Quantity INT
);

-- 2. TRIỂN KHAI INDEX VÀ SO SÁNH HIỆU NĂNG

-- Tình huống A: Đánh 2 Index đơn độc lập
CREATE INDEX idx_drug_name ON Pharmacy_Inventory(Drug_Name);
CREATE INDEX idx_expiry_date ON Pharmacy_Inventory(Expiry_Date);

-- Tình huống B: Đánh Composite Index
-- Xóa các index đơn cũ để tránh gây nhiễu cho Optimizer
DROP INDEX idx_drug_name ON Pharmacy_Inventory;
DROP INDEX idx_expiry_date ON Pharmacy_Inventory;

CREATE INDEX idx_drug_expiry_composite ON Pharmacy_Inventory(Drug_Name, Expiry_Date);

-- 3. PHÂN TÍCH KỸ THUẬT VỚI EXPLAIN

-- Truy vấn mục tiêu: Tìm thuốc 'Aspirin' sắp hết hạn trong tháng 6/2026
-- Khi dùng EXPLAIN, bạn sẽ thấy 'key' là idx_drug_expiry_composite
EXPLAIN SELECT * FROM Pharmacy_Inventory 
WHERE Drug_Name = 'Aspirin' 
  AND Expiry_Date <= '2026-06-30';
  
-- 4. GIẢI QUYẾT BÀI TOÁN TÌM KIẾM TỪ KHÓA (LIKE)

-- TRƯỜNG HỢP XẤU: Index bị vô hiệu hóa
-- Database phải quét 2 triệu dòng vì dấu % đứng đầu
EXPLAIN SELECT * FROM Pharmacy_Inventory WHERE Drug_Name LIKE '%Aspirin%';

-- GIẢI PHÁP 1: Tối ưu lại logic tìm kiếm
-- Index vẫn hoạt động tốt 
EXPLAIN SELECT * FROM Pharmacy_Inventory WHERE Drug_Name LIKE 'Aspirin%';

-- GIẢI PHÁP 2: Sử dụng Full-text Search cho tìm kiếm gần đúng
-- Phù hợp nếu nhân viên muốn tìm 'cetamol' ra 'Paracetamol'
ALTER TABLE Pharmacy_Inventory ADD FULLTEXT(Drug_Name);

-- Truy vấn bằng Full-text
SELECT * FROM Pharmacy_Inventory 
WHERE MATCH(Drug_Name) AGAINST('Aspirin' IN NATURAL LANGUAGE MODE);

-- Việc sử dụng Composite Index giúp giảm số lần truy xuất ổ đĩa (I/O). 
-- Thay vì lọc xong bảng A rồi lấy kết quả đó lọc tiếp ở bảng B, Database thực hiện việc "lọc kép" ngay trong một bước tìm kiếm duy nhất.

-- Đề xuất cho kho dược:
-- Thứ tự ưu tiên: Luôn để Drug_Name đứng trước trong Index vì đây là điều kiện lọc chính (High cardinality).

-- Tìm kiếm thông minh: Khuyến khích nhân viên nhập những chữ cái đầu của tên thuốc thay vì tìm kiếm chứa chuỗi (contains) để tận dụng Index sẵn có.

-- Hạ tầng: Nếu nghiệp vụ bắt buộc phải tìm kiếm mờ (fuzzy search) quá phức tạp trên 2 triệu dòng, hãy cân nhắc chuyển cột 
-- Drug_Name sang công nghệ Full-text Search tích hợp sẵn trong MySQL như tôi đã đề xuất ở mục 4.