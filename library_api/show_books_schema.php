<?php
require_once __DIR__ . '/db_con.php';

$stmt = $pdo->query("DESCRIBE books");
$columns = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo json_encode(['books_columns' => $columns], JSON_PRETTY_PRINT);
