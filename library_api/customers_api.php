<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
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
        // GET /customers_api.php?customer_id=NN
        if (isset($_GET['customer_id'])) {
            $customer_id = intval($_GET['customer_id']);

            $stmt = $pdo->prepare("SELECT * FROM customers WHERE customer_id = ?");
            $stmt->execute([$customer_id]);
            $customer = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$customer) {
                http_response_code(404);
                echo json_encode(['error' => 'Customer not found']);
                exit;
            }

            echo json_encode($customer);
            exit;
        }

        // GET /customers_api.php?user_id=NN -> get customer for user
        if (isset($_GET['user_id'])) {
            $user_id = intval($_GET['user_id']);

            $stmt = $pdo->prepare("SELECT * FROM customers WHERE user_id = ?");
            $stmt->execute([$user_id]);
            $customers = $stmt->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode($customers);
            exit;
        }

        // GET /customers_api.php -> list all customers
        $stmt = $pdo->query("SELECT c.*, u.username, u.email FROM customers c LEFT JOIN users u ON c.user_id = u.user_id ORDER BY c.customer_id");
        $customers = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode($customers);
        exit;
    }

    if ($method === 'POST') {
        // Expected JSON body: { user_id, first_name, last_name, phone, address, city, postal_code }
        $body = json_decode(file_get_contents('php://input'), true);
        if (!is_array($body)) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid JSON body']);
            exit;
        }

        if (empty($body['user_id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required field: user_id']);
            exit;
        }

        $user_id = intval($body['user_id']);
        $first_name = trim($body['first_name'] ?? '');
        $last_name = trim($body['last_name'] ?? '');
        $phone = trim($body['phone'] ?? '');
        $address = trim($body['address'] ?? '');
        $city = trim($body['city'] ?? '');
        $postal_code = trim($body['postal_code'] ?? '');

        try {
            $stmt = $pdo->prepare("INSERT INTO customers (user_id, first_name, last_name, phone, address, city, postal_code)
                VALUES (?, ?, ?, ?, ?, ?, ?)");
            $stmt->execute([$user_id, $first_name, $last_name, $phone, $address, $city, $postal_code]);
            $customer_id = $pdo->lastInsertId();

            echo json_encode(['success' => true, 'customer_id' => $customer_id]);
            exit;
        } catch (Exception $e) {
            http_response_code(400);
            echo json_encode(['error' => $e->getMessage()]);
            exit;
        }
    }

    if ($method === 'PUT') {
        // Expected JSON body: { customer_id, first_name, last_name, phone, address, city, postal_code }
        $body = json_decode(file_get_contents('php://input'), true);
        if (!is_array($body)) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid JSON body']);
            exit;
        }

        if (empty($body['customer_id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required field: customer_id']);
            exit;
        }

        $customer_id = intval($body['customer_id']);
        $first_name = trim($body['first_name'] ?? '');
        $last_name = trim($body['last_name'] ?? '');
        $phone = trim($body['phone'] ?? '');
        $address = trim($body['address'] ?? '');
        $city = trim($body['city'] ?? '');
        $postal_code = trim($body['postal_code'] ?? '');

        try {
            $stmt = $pdo->prepare("UPDATE customers SET first_name = ?, last_name = ?, phone = ?, address = ?, city = ?, postal_code = ? WHERE customer_id = ?");
            $stmt->execute([$first_name, $last_name, $phone, $address, $city, $postal_code, $customer_id]);

            if ($stmt->rowCount() === 0) {
                http_response_code(404);
                echo json_encode(['error' => 'Customer not found']);
                exit;
            }

            echo json_encode(['success' => true, 'message' => 'Customer updated']);
            exit;
        } catch (Exception $e) {
            http_response_code(400);
            echo json_encode(['error' => $e->getMessage()]);
            exit;
        }
    }

    if ($method === 'DELETE') {
        // Expected: ?customer_id=NN
        if (!isset($_GET['customer_id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required parameter: customer_id']);
            exit;
        }

        $customer_id = intval($_GET['customer_id']);

        try {
            $stmt = $pdo->prepare("DELETE FROM customers WHERE customer_id = ?");
            $stmt->execute([$customer_id]);

            if ($stmt->rowCount() === 0) {
                http_response_code(404);
                echo json_encode(['error' => 'Customer not found']);
                exit;
            }

            echo json_encode(['success' => true, 'message' => 'Customer deleted']);
            exit;
        } catch (Exception $e) {
            http_response_code(400);
            echo json_encode(['error' => $e->getMessage()]);
            exit;
        }
    }

    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;

} catch (Exception $ex) {
    http_response_code(500);
    echo json_encode(['error' => $ex->getMessage()]);
    exit;
}
?>
