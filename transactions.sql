-- Desabilita autocommit para a sessão
SET autocommit = 0;

-- Exemplo 1: Inserir pedido e itens como uma transação atômica
START TRANSACTION;

-- Insere um pedido
INSERT INTO orders (customer_id, order_date, total_amount, status)
VALUES (1, NOW(), 0.00, 'PENDING');

-- Recupera o id do pedido recém-criado
SET @order_id = LAST_INSERT_ID();

-- Insere itens do pedido (exemplo com 2 itens)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (@order_id, 101, 2, 49.90);

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (@order_id, 102, 1, 29.90);

-- Atualiza total do pedido com soma dos itens
UPDATE orders
SET total_amount = (
  SELECT SUM(quantity * unit_price) FROM order_items WHERE order_id = @order_id
)
WHERE id = @order_id;

-- Verificação simples: se total for 0, faz rollback
SELECT total_amount INTO @total FROM orders WHERE id = @order_id;
IF @total = 0 THEN
  ROLLBACK;
ELSE
  COMMIT;
END IF;

-- Exemplo 2: Atualização de estoque com verificação
START TRANSACTION;

-- Diminuir estoque do produto 101 em 2 unidades
UPDATE products
SET stock = stock - 2
WHERE id = 101;

-- Verifica se estoque ficou negativo
SELECT stock INTO @stock_after FROM products WHERE id = 101;
IF @stock_after < 0 THEN
  -- Reverte a transação se estoque insuficiente
  ROLLBACK;
ELSE
  COMMIT;
END IF;

-- Reabilita autocommit (opcional)
SET autocommit = 1;
