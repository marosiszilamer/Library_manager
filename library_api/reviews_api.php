<?php
// reviews_api.php
// Simple API to store and fetch book reviews.
// Deploy to XAMPP htdocs/library_api/

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

require_once __DIR__ . '/db_con.php'; // expects $pdo

try {
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $book_id = $_GET['book_id'] ?? '';
        if ($book_id === '') {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'book_id required']);
            exit;
        }

        // Ensure table
        $pdo->exec("CREATE TABLE IF NOT EXISTS reviews (
            id INT AUTO_INCREMENT PRIMARY KEY,
            book_id VARCHAR(64) NOT NULL,
            user_id INT DEFAULT NULL,
            username VARCHAR(255) DEFAULT NULL,
            rating TINYINT NOT NULL,
            comment TEXT DEFAULT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

        $stmt = $pdo->prepare('SELECT id, book_id, username, rating, comment, created_at FROM reviews WHERE book_id = :book_id ORDER BY created_at DESC');
        $stmt->execute([':book_id' => $book_id]);
        $rows = $stmt->fetchAll();
        echo json_encode($rows, JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $raw = file_get_contents('php://input');
        $input = json_decode($raw, true) ?: [];
        $action = $input['action'] ?? '';

        if ($action === 'create') {
            $book_id = $input['book_id'] ?? '';
            $username = $input['username'] ?? null;
            $rating = intval($input['rating'] ?? 0);
            $comment = $input['comment'] ?? null;

            if ($book_id === '' || $rating < 1 || $rating > 5) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'book_id and rating (1-5) required']);
                exit;
            }

            // Ensure table exists
            $pdo->exec("CREATE TABLE IF NOT EXISTS reviews (
                id INT AUTO_INCREMENT PRIMARY KEY,
                book_id VARCHAR(64) NOT NULL,
                user_id INT DEFAULT NULL,
                username VARCHAR(255) DEFAULT NULL,
                rating TINYINT NOT NULL,
                comment TEXT DEFAULT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

            $ins = $pdo->prepare('INSERT INTO reviews (book_id, username, rating, comment) VALUES (:book_id, :username, :rating, :comment)');
            $ins->execute([
                ':book_id' => $book_id,
                ':username' => $username,
                ':rating' => $rating,
                ':comment' => $comment,
            ]);

            echo json_encode(['success' => true, 'id' => $pdo->lastInsertId()]);
            exit;
        }
    }

    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Unsupported method or action']);
    exit;
} catch (Exception $ex) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $ex->getMessage()]);
    exit;
}

?>
