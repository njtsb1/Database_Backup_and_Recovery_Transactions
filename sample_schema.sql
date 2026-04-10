-- Minimal schema to test transactions, procedures, triggers and events
-- Database: ecommerce

DROP DATABASE IF EXISTS ecommerce;
CREATE DATABASE ecommerce CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ecommerce;

-- Products table
CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  stock INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Customers table
CREATE TABLE customers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  email VARCHAR(200) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Orders table
CREATE TABLE orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Order items table
CREATE TABLE order_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Sample data
INSERT INTO products (sku, name, price, stock) VALUES
('SKU101','Cotton T-Shirt',49.90,10),
('SKU102','Ceramic Mug',29.90,5),
('SKU103','Bluetooth Headset',199.90,2);

INSERT INTO customers (name, email) VALUES
('John Silva','joao@example.com'),
('Maria Souza','maria@example.com');

-- Example procedure: create an order with items (simplified)
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_create_order_simple$$
CREATE PROCEDURE sp_create_order_simple(
  IN p_customer_id INT,
  IN p_product_id INT,
  IN p_qty INT
)
BEGIN
  DECLARE v_price DECIMAL(10,2);
  DECLARE v_stock INT;

  -- Lock the product row for update to check price and stock
  SELECT price, stock INTO v_price, v_stock FROM products WHERE id = p_product_id FOR UPDATE;

  -- If not enough stock, raise an error
  IF v_stock < p_qty THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock';
  END IF;

  START TRANSACTION;

  INSERT INTO orders (customer_id, total_amount, status) VALUES (p_customer_id, 0.00, 'PENDING');
  SET @new_order_id = LAST_INSERT_ID();

  INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (@new_order_id, p_product_id, p_qty, v_price);

  UPDATE products SET stock = stock - p_qty WHERE id = p_product_id;

  UPDATE orders
    SET total_amount = (SELECT IFNULL(SUM(quantity * unit_price),0) FROM order_items WHERE order_id = @new_order_id)
    WHERE id = @new_order_id;

  COMMIT;
END$$
DELIMITER ;

-- Example trigger: update order total after inserting an item (alternative approach)
DELIMITER $$
DROP TRIGGER IF EXISTS trg_after_insert_order_item$$
CREATE TRIGGER trg_after_insert_order_item
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
  UPDATE orders
    SET total_amount = (SELECT IFNULL(SUM(quantity * unit_price),0) FROM order_items WHERE order_id = NEW.order_id)
    WHERE id = NEW.order_id;
END$$
DELIMITER ;

-- Example event: daily job that marks old pending orders as COMPLETED (for testing events)
-- Enable event scheduler if necessary: SET GLOBAL event_scheduler = ON;
DELIMITER $$
DROP EVENT IF EXISTS ev_mark_old_orders$$
CREATE EVENT ev_mark_old_orders
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO
BEGIN
  UPDATE orders
  SET status = 'COMPLETED'
  WHERE status = 'PENDING' AND order_date < NOW() - INTERVAL 30 DAY;
END$$
DELIMITER ;

-- Example function (simple)
DELIMITER $$
DROP FUNCTION IF EXISTS fn_order_total_items$$
CREATE FUNCTION fn_order_total_items(p_order_id INT) RETURNS INT DETERMINISTIC
BEGIN
  DECLARE v_total INT;
  SELECT IFNULL(SUM(quantity),0) INTO v_total FROM order_items WHERE order_id = p_order_id;
  RETURN v_total;
END$$
DELIMITER ;

-- Example usage of the procedure
-- CALL sp_create_order_simple(1, 1, 2);

-- Quick check
SELECT 'Schema created' AS info;
