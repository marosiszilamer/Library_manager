<?php
require_once __DIR__ . '/db_con.php';

$order_ids = [1, 11, 12];

foreach ($order_ids as $oid) {
    echo "Order #$oid:\n";
    $stmt = $pdo->prepare("SELECT oi.order_item_id, oi.order_id, oi.book_id, oi.quantity, oi.price, b.title, b.cover_image, a.name AS author_name
        FROM order_items oi
        JOIN books b ON oi.book_id = b.book_id
        LEFT JOIN authors a ON b.author_id = a.author_id
        WHERE oi.order_id = ?");
    $stmt->execute([$oid]);
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($items, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT) . "\n\n";
}
