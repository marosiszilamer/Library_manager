<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/db_con.php'; // expects $pdo (PDO instance)

// Ensure PHP errors/warnings do not emit HTML that breaks JSON parsing on the client.
ini_set('display_errors', '0');
ini_set('display_startup_errors', '0');
error_reporting(E_ALL);

// Convert uncaught exceptions to JSON responses
set_exception_handler(function($e){
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['error' => 'Exception', 'message' => $e->getMessage()]);
    exit;
});

// Convert PHP errors to JSON responses
set_error_handler(function($errno, $errstr, $errfile, $errline){
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['error' => 'PHP Error', 'message' => $errstr, 'file' => $errfile, 'line' => $errline]);
    exit;
});

// Shutdown handler to catch fatal errors
register_shutdown_function(function(){
    $err = error_get_last();
    if ($err) {
        http_response_code(500);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(['error' => 'Shutdown', 'message' => $err['message'], 'file' => $err['file'], 'line' => $err['line']]);
        exit;
    }
});

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    $method = $_SERVER['REQUEST_METHOD'];

    if ($method === 'GET') {
        // GET /orders_api.php?order_id=NN
        if (isset($_GET['order_id'])) {
            $order_id = intval($_GET['order_id']);

            $stmt = $pdo->prepare("SELECT o.*, c.first_name, c.last_name, c.phone, c.address AS customer_address, c.city
                FROM orders o
                JOIN customers c ON o.customer_id = c.customer_id
                WHERE o.order_id = ?");
            $stmt->execute([$order_id]);
            $order = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$order) {
                http_response_code(404);
                echo json_encode(['error' => 'Order not found']);
                exit;
            }

            $stmtItems = $pdo->prepare("SELECT oi.order_item_id, oi.book_id, oi.quantity, oi.price, b.title, b.cover_image, a.name AS author_name
                FROM order_items oi
                JOIN books b ON oi.book_id = b.book_id
                LEFT JOIN authors a ON b.author_id = a.author_id
                WHERE oi.order_id = ?");
            $stmtItems->execute([$order_id]);
            $order['items'] = $stmtItems->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode($order);
            exit;
        }

        // GET /orders_api.php?customer_id=NN -> list orders for customer
        if (isset($_GET['customer_id'])) {
            $customer_id = intval($_GET['customer_id']);

            $stmt = $pdo->prepare("SELECT * FROM orders WHERE customer_id = ? ORDER BY order_date DESC");
            $stmt->execute([$customer_id]);
            $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $stmtItems = $pdo->prepare("SELECT oi.order_item_id, oi.order_id, oi.book_id, oi.quantity, oi.price, b.title, b.cover_image, a.name AS author_name
                FROM order_items oi
                JOIN books b ON oi.book_id = b.book_id
                LEFT JOIN authors a ON b.author_id = a.author_id
                WHERE oi.order_id = ?");

            foreach ($orders as &$o) {
                $stmtItems->execute([$o['order_id']]);
                $o['items'] = $stmtItems->fetchAll(PDO::FETCH_ASSOC);
            }

            echo json_encode($orders);
            exit;
        }

        // GET /orders_api.php?username=... -> list orders for user by username
        if (isset($_GET['username'])) {
            $username = trim($_GET['username']);
            if (empty($username)) {
                http_response_code(400);
                echo json_encode(['error' => 'Username is required']);
                exit;
            }

            // Get user_id from username
            $stmtUser = $pdo->prepare("SELECT user_id FROM users WHERE username = ?");
            $stmtUser->execute([$username]);
            $user = $stmtUser->fetch(PDO::FETCH_ASSOC);
            if (!$user) {
                http_response_code(404);
                echo json_encode(['error' => 'User not found']);
                exit;
            }

            // Get customer_id from user_id
            $stmtCustomer = $pdo->prepare("SELECT customer_id FROM customers WHERE user_id = ?");
            $stmtCustomer->execute([$user['user_id']]);
            $customer = $stmtCustomer->fetch(PDO::FETCH_ASSOC);
            if (!$customer) {
                http_response_code(404);
                echo json_encode(['error' => 'Customer not found for this user']);
                exit;
            }

            $customer_id = $customer['customer_id'];

            // Get orders for customer
            $stmt = $pdo->prepare("SELECT * FROM orders WHERE customer_id = ? ORDER BY order_date DESC");
            $stmt->execute([$customer_id]);
            $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $stmtItems = $pdo->prepare("SELECT oi.order_item_id, oi.order_id, oi.book_id, oi.quantity, oi.price, b.title, b.cover_image, a.name AS author_name
                FROM order_items oi
                JOIN books b ON oi.book_id = b.book_id
                LEFT JOIN authors a ON b.author_id = a.author_id
                WHERE oi.order_id = ?");

            foreach ($orders as &$o) {
                $stmtItems->execute([$o['order_id']]);
                $o['items'] = $stmtItems->fetchAll(PDO::FETCH_ASSOC);
            }

            echo json_encode($orders);
            exit;
        }

        // GET /orders_api.php -> list all orders (admin only, assuming auth elsewhere) with user info
        $stmt = $pdo->query("SELECT o.*, c.first_name, c.last_name, u.username FROM orders o JOIN customers c ON o.customer_id = c.customer_id JOIN users u ON c.user_id = u.user_id ORDER BY order_date DESC");
        $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $stmtItems = $pdo->prepare("SELECT oi.order_item_id, oi.order_id, oi.book_id, oi.quantity, oi.price, b.title, b.cover_image, a.name AS author_name
            FROM order_items oi
            JOIN books b ON oi.book_id = b.book_id
            LEFT JOIN authors a ON b.author_id = a.author_id
            WHERE oi.order_id = ?");

        foreach ($orders as &$o) {
            $stmtItems->execute([$o['order_id']]);
            $o['items'] = $stmtItems->fetchAll(PDO::FETCH_ASSOC);
        }

        echo json_encode($orders);
        exit;
    }

    if ($method === 'POST') {
        // Expected JSON body: { customer_id, shipping_address, payment_method, items: [{book_id, quantity, price}, ...] }
        $body = json_decode(file_get_contents('php://input'), true);
        if (!is_array($body)) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid JSON body']);
            exit;
        }

        if (empty($body['customer_id']) || empty($body['items']) || !is_array($body['items'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields: customer_id and items']);
            exit;
        }

        $customer_id = intval($body['customer_id']);
        $shipping_address = isset($body['shipping_address']) ? trim($body['shipping_address']) : '';
        $payment_method = isset($body['payment_method']) ? $body['payment_method'] : 'utánvét';
        $items = $body['items'];

        // validate payment_method
        $allowedPayments = ['bankkártya', 'utánvét', 'PayPal'];
        if (!in_array($payment_method, $allowedPayments)) $payment_method = 'utánvét';

        // calculate total
        $total = 0.0;
        foreach ($items as $it) {
            $q = max(0, intval($it['quantity'] ?? 0));
            $p = floatval($it['price'] ?? 0);
            $total += $q * $p;
        }

        try {
            $pdo->beginTransaction();

            $stmt = $pdo->prepare("INSERT INTO orders (customer_id, order_date, status, total_amount, shipping_address, payment_method) VALUES (?, NOW(), 'függőben', ?, ?, ?)");
            $stmt->execute([$customer_id, $total, $shipping_address, $payment_method]);
            $order_id = $pdo->lastInsertId();

            $stmtInsertItem = $pdo->prepare("INSERT INTO order_items (order_id, book_id, quantity, price) VALUES (?, ?, ?, ?)");
            $stmtUpdateStock = $pdo->prepare("UPDATE books SET stock = stock - ? WHERE book_id = ? AND stock >= ?");

            foreach ($items as $it) {
                $book_id = intval($it['book_id'] ?? 0);
                $qty = max(0, intval($it['quantity'] ?? 0));
                $price = floatval($it['price'] ?? 0);

                if ($book_id <= 0 || $qty <= 0) {
                    $pdo->rollBack();
                    http_response_code(400);
                    echo json_encode(['error' => 'Invalid book_id or quantity']);
                    exit;
                }

                // insert item
                $stmtInsertItem->execute([$order_id, $book_id, $qty, $price]);

                // decrement stock (only if enough stock exists)
                $stmtUpdateStock->execute([$qty, $book_id, $qty]);
                if ($stmtUpdateStock->rowCount() === 0) {
                    // not enough stock
                    $pdo->rollBack();
                    http_response_code(400);
                    echo json_encode(['error' => 'Nem elegendő készlet a következő könyvhöz', 'book_id' => $book_id]);
                    exit;
                }
            }

            $pdo->commit();
            echo json_encode(['success' => true, 'order_id' => $order_id]);
            exit;
        } catch (Exception $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
            exit;
        }
    }

    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;

} catch (Exception $ex) {
    if (isset($pdo) && $pdo->inTransaction()) $pdo->rollBack();
    http_response_code(500);
    echo json_encode(['error' => $ex->getMessage()]);
    exit;
}
?>
