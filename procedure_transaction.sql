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
    -- Em caso de erro, faz rollback total
    ROLLBACK;
    SELECT 'ERROR' AS status, 'Transação revertida por exceção' AS message;
  END;

  START TRANSACTION;

  -- Insere pedido
  INSERT INTO orders (customer_id, order_date, total_amount, status)
  VALUES (p_customer_id, NOW(), 0.00, 'PENDING');

  SET @new_order_id = LAST_INSERT_ID();

  -- Primeiro savepoint antes de inserir itens
  SAVEPOINT sp_before_items;

  -- Insere primeiro item
  INSERT INTO order_items (order_id, product_id, quantity, unit_price)
  VALUES (@new_order_id, p_item1_product_id, p_item1_qty, p_item1_price);

  -- Atualiza estoque do primeiro produto
  UPDATE products
  SET stock = stock - p_item1_qty
  WHERE id = p_item1_product_id;

  -- Verifica estoque negativo e faz rollback parcial se necessário
  SELECT stock INTO @s1 FROM products WHERE id = p_item1_product_id;
  IF @s1 < 0 THEN
    -- Reverte apenas até o savepoint (remove o primeiro item)
    ROLLBACK TO SAVEPOINT sp_before_items;
    -- Decide continuar sem o item 1 ou abortar; aqui abortamos
    ROLLBACK;
    SELECT 'ERROR' AS status, 'Estoque insuficiente para item 1' AS message;
    LEAVE proc_end;
  END IF;

  -- Insere segundo item
  INSERT INTO order_items (order_id, product_id, quantity, unit_price)
  VALUES (@new_order_id, p_item2_product_id, p_item2_qty, p_item2_price);

  -- Atualiza estoque do segundo produto
  UPDATE products
  SET stock = stock - p_item2_qty
  WHERE id = p_item2_product_id;

  SELECT stock INTO @s2 FROM products WHERE id = p_item2_product_id;
  IF @s2 < 0 THEN
    -- Reverte apenas o segundo item (volta ao savepoint)
    ROLLBACK TO SAVEPOINT sp_before_items;
    -- Atualiza total do pedido com os itens que permaneceram (nenhum neste caso)
    UPDATE orders
    SET total_amount = (
      SELECT IFNULL(SUM(quantity * unit_price), 0) FROM order_items WHERE order_id = @new_order_id
    )
    WHERE id = @new_order_id;
    COMMIT;
    SELECT 'PARTIAL' AS status, 'Segundo item removido por estoque insuficiente; pedido criado parcialmente' AS message;
    LEAVE proc_end;
  END IF;

  -- Atualiza total do pedido
  UPDATE orders
  SET total_amount = (
    SELECT SUM(quantity * unit_price) FROM order_items WHERE order_id = @new_order_id
  )
  WHERE id = @new_order_id;

  COMMIT;
  SELECT 'OK' AS status, @new_order_id AS order_id, 'Pedido criado com sucesso' AS message;

proc_end: 
  -- fim da procedure
  ;
END$$

DELIMITER ;
