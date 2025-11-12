<?php
// db_con.php
// Minimal mysqli-compatible vars for legacy scripts and PDO for newer APIs.

$DB_HOST = '127.0.0.1';
$DB_NAME = 'library_manager'; // change if your DB name is different
$DB_USER = 'root';
$DB_PASS = ''; // default XAMPP root has no password; change if you set one
$DB_CHARSET = 'utf8mb4';

// mysqli style variables for older scripts
$servername = $DB_HOST;
$username = $DB_USER;
$password = $DB_PASS;
$dbname = $DB_NAME;

// Create PDO instance for APIs that expect $pdo
try {
	$dsn = "mysql:host={$DB_HOST};dbname={$DB_NAME};charset={$DB_CHARSET}";
	$opt = [
		PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
		PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
		PDO::ATTR_EMULATE_PREPARES => false,
	];
	$pdo = new PDO($dsn, $DB_USER, $DB_PASS, $opt);
} catch (PDOException $e) {
	// For dev, echo JSON error; for production, log and hide details
	http_response_code(500);
	echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $e->getMessage()]);
	exit;
}
?>
