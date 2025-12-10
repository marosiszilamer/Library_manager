<?php
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/db_con.php';

try {
    // Check reviews table structure
    $stmt = $pdo->query("DESCRIBE reviews");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'reviews_columns' => $columns,
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
}
?>
