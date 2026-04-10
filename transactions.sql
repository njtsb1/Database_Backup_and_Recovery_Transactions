-- Disable autocommit for the session
SET autocommit = 0;

-- Example 1: Insert an order and items as an atomic transaction
START TRANSACTION;

-- Insert an order
INSERT INTO orders (customer_id, order_date, total_amount, status)
VALUES (1, NOW(), 0.00, 'PENDING');

-- Retrieve the id of the newly created order
SET @order_id = LAST_INSERT_ID();

-- Insert order items (example with 2 items)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (@order_id, 101, 2, 49.90);

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (@order_id, 102, 1, 29.90);

-- Update order total with the sum of the items
UPDATE orders
SET total_amount = (
  SELECT SUM(quantity * unit_price) FROM order_items WHERE order_id = @order_id
)
WHERE id = @order_id;

-- Simple check: if total is 0, rollback
SELECT total_amount INTO @total FROM orders WHERE id = @order_id;
IF @total = 0 THEN
  ROLLBACK;
ELSE
  COMMIT;
END IF;

-- Example 2: Stock update with verification
START TRANSACTION;

-- Decrease stock of product 101 by 2 units
UPDATE products
SET stock = stock - 2
WHERE id = 101;

-- Check if stock became negative
SELECT stock INTO @stock_after FROM products WHERE id = 101;
IF @stock_after < 0 THEN
  -- Roll back the transaction if stock is insufficient
  ROLLBACK;
ELSE
  COMMIT;
END IF;

-- Re-enable autocommit (optional)
SET autocommit = 1;
