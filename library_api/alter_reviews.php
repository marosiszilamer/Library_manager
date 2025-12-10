<?php
header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/db_con.php';

try {
    // Modify reviews table to allow NULL customer_id
    $sql = "ALTER TABLE reviews MODIFY customer_id INT NULL DEFAULT NULL";
    $pdo->exec($sql);
    
    echo json_encode([
        'success' => true,
        'message' => 'customer_id oszlop módosítva NULL-ra',
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
