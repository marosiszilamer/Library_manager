<?php
// reviews_api.php
// API to fetch and create book reviews compatible with the provided schema.

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

require_once __DIR__ . '/db_con.php'; // provides $pdo and mysqli vars

// Simple logger helper
function _rlog($m) {
    $msg = '[' . date('Y-m-d H:i:s') . '] ' . $m . "\n";
    // Try to write into project folder
    $projectPath = __DIR__ . '/reviews_api_error.log';
    $ok = @file_put_contents($projectPath, $msg, FILE_APPEND);
    if ($ok === false) {
        // Fallback to system temp directory
        $tmp = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'reviews_api_error.log';
        file_put_contents($tmp, $msg, FILE_APPEND);
        // Also write a small marker to php://stderr so server error logs may capture it
        fwrite(STDERR, $msg);
    }
}

// Log uncaught exceptions
set_exception_handler(function($e) {
    _rlog('UNCAUGHT EXCEPTION: ' . $e->getMessage() . '\n' . $e->getTraceAsString());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    exit;
});

try {
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $book_id = intval($_GET['book_id'] ?? 0);
        if ($book_id <= 0) {
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
            reviewer_name VARCHAR(255) DEFAULT NULL,
            review_date DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX(book_id),
            INDEX(customer_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

        // Select reviews and include customer/user info (customers -> users)
        $sql = "SELECT r.review_id,
                        r.book_id,
                        r.customer_id,
                        COALESCE(r.reviewer_name, CONCAT(c.first_name, ' ', c.last_name), u.username, u.email, CONCAT('user_', r.customer_id)) AS username,
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
        _rlog('Incoming POST body: ' . $raw);
        $input = json_decode($raw, true) ?: [];
        _rlog('Decoded input: ' . json_encode($input, JSON_UNESCAPED_UNICODE));
        $action = $input['action'] ?? '';

        if ($action === 'create') {
            $book_id = intval($input['book_id'] ?? 0);
            // Expect the frontend to send the currently logged-in username/email
            $username = trim((string)($input['username'] ?? ''));
            $rating = intval($input['rating'] ?? 0);
            $comment = isset($input['comment']) ? trim((string)$input['comment']) : null;

            if ($book_id <= 0 || $rating < 1 || $rating > 5) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'book_id and rating (1-5) required']);
                exit;
            }

            if ($username === '') {
                // We require the client to identify the logged-in user
                http_response_code(401);
                echo json_encode(['success' => false, 'message' => 'Authentication required (username)']);
                exit;
            }

            // Ensure table exists (already created above but keep safe)
            $pdo->exec("CREATE TABLE IF NOT EXISTS reviews (
                review_id INT AUTO_INCREMENT PRIMARY KEY,
                book_id INT NOT NULL,
                customer_id INT DEFAULT NULL,
                rating TINYINT NOT NULL,
                comment TEXT DEFAULT NULL,
                reviewer_name VARCHAR(255) DEFAULT NULL,
                review_date DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

            // Resolve the username -> user_id, then customer_id. If the customer row
            // doesn't exist yet, create a minimal one so reviews link to customers.
            try {
                $uStmt = $pdo->prepare('SELECT user_id FROM users WHERE username = :u OR email = :u LIMIT 1');
                $uStmt->execute([':u' => $username]);
                $uRow = $uStmt->fetch(PDO::FETCH_ASSOC);
                if (!($uRow && !empty($uRow['user_id']))) {
                    http_response_code(401);
                    echo json_encode(['success' => false, 'message' => 'Unknown user']);
                    exit;
                }
                $uid = intval($uRow['user_id']);

                // Try to find existing customer
                $cStmt = $pdo->prepare('SELECT customer_id FROM customers WHERE user_id = :uid LIMIT 1');
                $cStmt->execute([':uid' => $uid]);
                $cRow = $cStmt->fetch(PDO::FETCH_ASSOC);
                if ($cRow && !empty($cRow['customer_id'])) {
                    $customer_id = intval($cRow['customer_id']);
                } else {
                    // create a minimal customer record so reviews can reference it
                    $insCust = $pdo->prepare('INSERT INTO customers (user_id, first_name, last_name, phone, address, city, postal_code) VALUES (:uid, "", "", "", "", "", "")');
                    $insCust->execute([':uid' => $uid]);
                    $customer_id = intval($pdo->lastInsertId());
                }
            } catch (PDOException $e) {
                @file_put_contents(__DIR__ . '/reviews_api_error.log', '[' . date('Y-m-d H:i:s') . '] username resolution error: ' . $e->getMessage() . "\n", FILE_APPEND);
                http_response_code(500);
                echo json_encode(['success' => false, 'message' => 'Failed to resolve user', 'error' => $e->getMessage()]);
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

            // Build dynamic insert using only columns that actually exist in `reviews` table
            $possible = [
                'book_id' => intval($book_id),
                'customer_id' => $customer_id,
                'rating' => $rating,
                'comment' => $comment,
                // store reviewer_name as a convenience, but primary relation is customer_id
                'reviewer_name' => $username,
            ];

            try {
                $colsStmt = $pdo->query("DESCRIBE reviews");
                $colsDesc = $colsStmt->fetchAll(PDO::FETCH_ASSOC);
                $dbCols = array_column($colsDesc, 'Field');
            } catch (PDOException $dpex) {
                @file_put_contents(__DIR__ . '/reviews_api_error.log', '[' . date('Y-m-d H:i:s') . '] DESCRIBE ERROR: ' . $dpex->getMessage() . "\n", FILE_APPEND);
                http_response_code(500);
                echo json_encode(['success' => false, 'message' => 'Failed to inspect reviews table', 'error' => $dpex->getMessage()]);
                exit;
            }

            $toInsert = array_intersect_key($possible, array_flip($dbCols));
            if (empty($toInsert)) {
                http_response_code(500);
                echo json_encode(['success' => false, 'message' => 'No valid columns available to insert']);
                exit;
            }

            $fields = implode(', ', array_keys($toInsert));
            $placeholders = implode(', ', array_map(function($c){ return ':' . $c; }, array_keys($toInsert)));
            $sql = "INSERT INTO reviews ($fields) VALUES ($placeholders)";

            $params = [];
            foreach ($toInsert as $col => $val) {
                $params[':' . $col] = $val;
            }

            try {
                $ins = $pdo->prepare($sql);
                $ins->execute($params);
                $log = '[' . date('Y-m-d H:i:s') . '] INSERT OK: Inserted columns: ' . implode(', ', array_keys($toInsert)) . "\n";
                $log .= 'SQL: ' . $sql . "\n";
                $log .= 'Params: ' . json_encode($params, JSON_UNESCAPED_UNICODE) . "\n";
                @file_put_contents(__DIR__ . '/reviews_api_error.log', $log, FILE_APPEND);

                echo json_encode(['success' => true, 'review_id' => $pdo->lastInsertId(), 'inserted_columns' => array_values(array_keys($toInsert))], JSON_UNESCAPED_UNICODE);
                exit;
            } catch (PDOException $pex) {
                $log = '[' . date('Y-m-d H:i:s') . "] INSERT ERROR: " . $pex->getMessage() . "\n";
                $log .= "SQL: " . $sql . "\n";
                $log .= "Params: " . json_encode($params, JSON_UNESCAPED_UNICODE) . "\n";
                @file_put_contents(__DIR__ . '/reviews_api_error.log', $log, FILE_APPEND);
                http_response_code(500);
                echo json_encode(['success' => false, 'message' => 'Database insert failed', 'error' => $pex->getMessage(), 'sql' => $sql, 'params' => $params], JSON_UNESCAPED_UNICODE);
                exit;
            }
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
