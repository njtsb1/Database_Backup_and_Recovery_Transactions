DELIMITER $$

DROP PROCEDURE IF EXISTS sp_create_order_with_items$$

CREATE PROCEDURE sp_create_order_with_items(
  IN p_customer_id INT,
  IN p_item1_product_id INT,
  IN p_item1_qty INT,
  IN p_item1_price DECIMAL(10,2),
  IN p_item2_product_id INT,
  IN p_item2_qty INT,
  IN p_item2_price DECIMAL(10,2)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    -- On error, perform a full rollback
    ROLLBACK;
    SELECT 'ERROR' AS status, 'Transaction rolled back due to exception' AS message;
  END;

  START TRANSACTION;

  -- Insert order
  INSERT INTO orders (customer_id, order_date, total_amount, status)
  VALUES (p_customer_id, NOW(), 0.00, 'PENDING');

  SET @new_order_id = LAST_INSERT_ID();

  -- First savepoint before inserting items
  SAVEPOINT sp_before_items;

  -- Insert first item
  INSERT INTO order_items (order_id, product_id, quantity, unit_price)
  VALUES (@new_order_id, p_item1_product_id, p_item1_qty, p_item1_price);

  -- Update stock for the first product
  UPDATE products
  SET stock = stock - p_item1_qty
  WHERE id = p_item1_product_id;

  -- Check for negative stock and perform partial rollback if necessary
  SELECT stock INTO @s1 FROM products WHERE id = p_item1_product_id;
  IF @s1 < 0 THEN
    -- Roll back only to the savepoint (remove the first item)
    ROLLBACK TO SAVEPOINT sp_before_items;
    -- Decide whether to continue without item 1 or abort; here we abort
    ROLLBACK;
    SELECT 'ERROR' AS status, 'Insufficient stock for item 1' AS message;
    LEAVE proc_end;
  END IF;

  -- Insert second item
  INSERT INTO order_items (order_id, product_id, quantity, unit_price)
  VALUES (@new_order_id, p_item2_product_id, p_item2_qty, p_item2_price);

  -- Update stock for the second product
  UPDATE products
  SET stock = stock - p_item2_qty
  WHERE id = p_item2_product_id;

  SELECT stock INTO @s2 FROM products WHERE id = p_item2_product_id;
  IF @s2 < 0 THEN
    -- Roll back only the second item (return to the savepoint)
    ROLLBACK TO SAVEPOINT sp_before_items;
    -- Update order total with the items that remain (none in this case)
    UPDATE orders
    SET total_amount = (
      SELECT IFNULL(SUM(quantity * unit_price), 0) FROM order_items WHERE order_id = @new_order_id
    )
    WHERE id = @new_order_id;
    COMMIT;
    SELECT 'PARTIAL' AS status, 'Second item removed due to insufficient stock; order created partially' AS message;
    LEAVE proc_end;
  END IF;

  -- Update order total
  UPDATE orders
  SET total_amount = (
    SELECT SUM(quantity * unit_price) FROM order_items WHERE order_id = @new_order_id
  )
  WHERE id = @new_order_id;

  COMMIT;
  SELECT 'OK' AS status, @new_order_id AS order_id, 'Order created successfully' AS message;

proc_end: 
  -- end of procedure
  ;
END$$

DELIMITER ;
