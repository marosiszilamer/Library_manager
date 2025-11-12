<?php
// reviews_api.php
// API to fetch and create book reviews compatible with the provided schema.

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

require_once __DIR__ . '/db_con.php'; // provides $pdo and mysqli vars

try {
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $book_id = $_GET['book_id'] ?? '';
        if (trim($book_id) === '') {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'book_id required']);
            exit;
        }

        // Ensure reviews table exists matching your schema
        $pdo->exec("CREATE TABLE IF NOT EXISTS reviews (
            review_id INT AUTO_INCREMENT PRIMARY KEY,
            book_id INT NOT NULL,
            customer_id INT DEFAULT NULL,
            rating TINYINT NOT NULL,
            comment TEXT DEFAULT NULL,
            review_date DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX(book_id),
            INDEX(customer_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

        // Select reviews and include customer/user info (customers -> users)
        $sql = "SELECT r.review_id,
                        r.book_id,
                        r.customer_id,
                        COALESCE(CONCAT(c.first_name, ' ', c.last_name), u.username, u.email, CONCAT('user_', r.customer_id)) AS username,
                        r.rating,
                        r.comment,
                        r.review_date
                FROM reviews r
                LEFT JOIN customers c ON c.customer_id = r.customer_id
                LEFT JOIN users u ON u.user_id = c.user_id
                WHERE r.book_id = :book_id
                ORDER BY r.review_date DESC";

        $stmt = $pdo->prepare($sql);
        $stmt->execute([':book_id' => $book_id]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(array_values($rows), JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $raw = file_get_contents('php://input');
        $input = json_decode($raw, true) ?: [];
        $action = $input['action'] ?? '';

        if ($action === 'create') {
            $book_id = $input['book_id'] ?? '';
            $customer_id = isset($input['customer_id']) ? intval($input['customer_id']) : null;
            $rating = intval($input['rating'] ?? 0);
            $comment = $input['comment'] ?? null;

            if (trim($book_id) === '' || $rating < 1 || $rating > 5) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'book_id and rating (1-5) required']);
                exit;
            }

            // Ensure table exists (already created above but keep safe)
            $pdo->exec("CREATE TABLE IF NOT EXISTS reviews (
                review_id INT AUTO_INCREMENT PRIMARY KEY,
                book_id INT NOT NULL,
                customer_id INT DEFAULT NULL,
                rating TINYINT NOT NULL,
                comment TEXT DEFAULT NULL,
                review_date DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

            // If frontend provided username or email instead of customer_id, resolve to customer_id
            if ($customer_id === null) {
                if (!empty($input['username'])) {
                    $uname = trim($input['username']);
                    // find user by username or email
                    $uStmt = $pdo->prepare('SELECT COALESCE(user_id, id) AS uid FROM users WHERE username = :u OR email = :u LIMIT 1');
                    $uStmt->execute([':u' => $uname]);
                    $uRow = $uStmt->fetch(PDO::FETCH_ASSOC);
                    if ($uRow && !empty($uRow['uid'])) {
                        $uid = intval($uRow['uid']);
                        // find customer entry for this user
                        $cStmt = $pdo->prepare('SELECT customer_id FROM customers WHERE user_id = :uid LIMIT 1');
                        $cStmt->execute([':uid' => $uid]);
                        $cRow = $cStmt->fetch(PDO::FETCH_ASSOC);
                        if ($cRow && !empty($cRow['customer_id'])) {
                            $customer_id = intval($cRow['customer_id']);
                        }
                    }
                }
            }

            // Require a customer_id to insert (only logged-in users may post)
            if ($customer_id === null) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'customer_id (or valid username/email) required']);
                exit;
            }

            // Validate book exists (optional)
            $bChk = $pdo->prepare('SELECT COUNT(*) FROM books WHERE book_id = :bid');
            $bChk->execute([':bid' => intval($book_id)]);
            if ($bChk->fetchColumn() == 0) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'Invalid book_id']);
                exit;
            }

            $sql = 'INSERT INTO reviews (book_id, customer_id, rating, comment) VALUES (:book_id, :customer_id, :rating, :comment)';
            $ins = $pdo->prepare($sql);
            $ins->execute([
                ':book_id' => intval($book_id),
                ':customer_id' => $customer_id,
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
