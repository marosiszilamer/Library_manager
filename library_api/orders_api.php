<?php
require_once __DIR__ . '/db_con.php';

// Accept JSON or form-urlencoded
$input = file_get_contents('php://input');
$payload = [];
if ($input) {
    $json = json_decode($input, true);
    if (is_array($json)) {
        $payload = $json;
    }
}

$book_id = $_POST['book_id'] ?? ($payload['book_id'] ?? null);
$user_id = $_POST['user_id'] ?? ($payload['user_id'] ?? null);

if (!$book_id) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'book_id is required']);
    exit;
}

try {
    $pdo = get_pdo();

    // Optional: validate the book exists
    $check = $pdo->prepare('SELECT id FROM books WHERE id = :id');
    $check->execute([':id' => $book_id]);
    if (!$check->fetch()) {
        http_response_code(404);
        echo json_encode(['ok' => false, 'error' => 'Book not found']);
        exit;
    }

    $stmt = $pdo->prepare('INSERT INTO orders (book_id, user_id, created_at) VALUES (:book_id, :user_id, NOW())');
    $stmt->execute([
        ':book_id' => $book_id,
        ':user_id' => $user_id,
    ]);

    echo json_encode(['ok' => true, 'order_id' => $pdo->lastInsertId()]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'Server error', 'details' => $e->getMessage()]);
}
