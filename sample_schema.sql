-- Esquema mínimo para testar transações, procedures, triggers e eventos
-- Banco: ecommerce

DROP DATABASE IF EXISTS ecommerce;
CREATE DATABASE ecommerce CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ecommerce;

-- Tabela de produtos
CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  stock INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Tabela de clientes
CREATE TABLE customers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  email VARCHAR(200) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Tabela de pedidos
CREATE TABLE orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Itens do pedido
CREATE TABLE order_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Dados de exemplo
INSERT INTO products (sku, name, price, stock) VALUES
('SKU101','Camiseta Algodão',49.90,10),
('SKU102','Caneca Cerâmica',29.90,5),
('SKU103','Fone Bluetooth',199.90,2);

INSERT INTO customers (name, email) VALUES
('João Silva','joao@example.com'),
('Maria Souza','maria@example.com');

-- Exemplo de procedure: cria pedido com itens (simplificada)
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

  SELECT price, stock INTO v_price, v_stock FROM products WHERE id = p_product_id FOR UPDATE;

  IF v_stock < p_qty THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estoque insuficiente';
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

-- Exemplo de trigger: atualiza total do pedido ao inserir item (alternativa)
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

-- Exemplo de evento: rotina diária que marca pedidos antigos como 'COMPLETED' (para testar events)
-- Ativar event scheduler se necessário: SET GLOBAL event_scheduler = ON;
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

-- Exemplo de função (simples)
DELIMITER $$
DROP FUNCTION IF EXISTS fn_order_total_items$$
CREATE FUNCTION fn_order_total_items(p_order_id INT) RETURNS INT DETERMINISTIC
BEGIN
  DECLARE v_total INT;
  SELECT IFNULL(SUM(quantity),0) INTO v_total FROM order_items WHERE order_id = p_order_id;
  RETURN v_total;
END$$
DELIMITER ;

-- Exemplo de uso da procedure
-- CALL sp_create_order_simple(1, 1, 2);

-- Verificações rápidas
SELECT 'Schema criado' AS info;
