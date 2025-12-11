<?php



header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=utf-8");

ini_set('default_charset', 'utf-8');

// $servername = "localhost";
// $username = "root";
// $password = "";
// $dbname = "library_manager";
try
{
  include "db_con.php";
}catch(Exception $e)
{
    die(json_encode(["error" => "Connection failed: " . $e->getMessage()]));
}


$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
  die(json_encode(["error" => "Database connection failed: " . $conn->connect_error]));
}

$method = $_SERVER['REQUEST_METHOD'];
$raw_input = file_get_contents("php://input");
$input = json_decode($raw_input, true);

// Debug log
error_log("Method: $method, Raw Input: " . $raw_input . ", Decoded Input: " . json_encode($input));

// If input is NULL and raw_input is not empty, log the error
if (is_null($input) && !empty($raw_input)) {
  error_log("JSON decode failed for: " . $raw_input . ", Error: " . json_last_error_msg());
}

switch ($method) {
  //  READ (Összes user betoltese vagy login)
  case 'GET':
    // Check if this is a login request
    if (isset($_GET['action']) && $_GET['action'] === 'login') {
      $username = $_GET['username'] ?? '';
      $password = $_GET['password'] ?? '';
      
      if (empty($username) || empty($password)) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Username and password required"]);
        break;
      }
      
      $sql = "SELECT user_id, username, email, password_hash, role, registration_date, is_active FROM users WHERE username = ?";
      $stmt = $conn->prepare($sql);
      $stmt->bind_param("s", $username);
      $stmt->execute();
      $result = $stmt->get_result();
      
      if ($result->num_rows === 0) {
        http_response_code(401);
        echo json_encode(["success" => false, "message" => "User not found"]);
      } else {
        $user = $result->fetch_assoc();
        // Verify password hash
        if (password_verify($password, $user['password_hash'])) {
          // Don't return password_hash in response
          unset($user['password_hash']);
          echo json_encode(["success" => true, "user" => $user]);
        } else {
          http_response_code(401);
          echo json_encode(["success" => false, "message" => "Invalid password"]);
        }
      }
      $stmt->close();
      break;
    }
    
    // Regular GET - return all users (without password hashes)
    $sql = "SELECT user_id, username, email, role, registration_date, is_active FROM users";
    $result = $conn->query($sql);
    $users = [];
    while ($row = $result->fetch_assoc()) {
      $users[] = $row;
    }
    echo json_encode($users);
    break;

  //  CREATE (Új user) vagy LOGIN
  case 'POST':
    // Check if this is a login request
    if (isset($input['action']) && $input['action'] === 'login') {
      $username = $input['username'] ?? '';
      $password = $input['password'] ?? '';
      
      if (empty($username) || empty($password)) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Username and password required"]);
        break;
      }
      
      $sql = "SELECT user_id, username, email, password_hash, role, registration_date, is_active FROM users WHERE username = ?";
      $stmt = $conn->prepare($sql);
      $stmt->bind_param("s", $username);
      $stmt->execute();
      $result = $stmt->get_result();
      
      if ($result->num_rows === 0) {
        http_response_code(401);
        echo json_encode(["success" => false, "message" => "User not found"]);
      } else {
        $user = $result->fetch_assoc();
        // Verify password hash
        if (password_verify($password, $user['password_hash'])) {
          // Don't return password_hash in response
          unset($user['password_hash']);
          echo json_encode(["success" => true, "user" => $user]);
        } else {
          http_response_code(401);
          echo json_encode(["success" => false, "message" => "Invalid password"]);
        }
      }
      $stmt->close();
      break;
    }

    // Regular POST - create new user
    $username = $input['username'] ?? '';
    $email = $input['email'] ?? '';
    $password_hash = password_hash($input['password'] ?? '', PASSWORD_BCRYPT);
    $role = $input['role'] ?? 'customer';
    $registration_date = date('Y-m-d H:i:s');
    $is_active = 1;

    $sql = "INSERT INTO users (username, email, password_hash, role, registration_date, is_active)
            VALUES ('$username', '$email', '$password_hash', '$role', '$registration_date', $is_active)";
    if ($conn->query($sql)) {
      echo json_encode(["success" => true, "message" => "User created successfully"]);
    } else {
      echo json_encode(["error" => $conn->error]);
    }
    break;

  //  UPDATE (User módosítása)
  case 'PUT':
    $user_id = $input['user_id'];
    $username = $input['username'];
    $email = $input['email'];
    $role = $input['role'];
    $is_active = $input['is_active'];

    $sql = "UPDATE users SET username='$username', email='$email', role='$role', is_active=$is_active WHERE user_id=$user_id";
    if ($conn->query($sql)) {
      echo json_encode(["success" => true, "message" => "User updated successfully"]);
    } else {
      echo json_encode(["error" => $conn->error]);
    }
    break;

  //  DELETE (User törlése)
  case 'DELETE':
    parse_str(file_get_contents("php://input"), $del_vars);
    $user_id = $del_vars['user_id'];
    $sql = "DELETE FROM users WHERE user_id=$user_id";
    if ($conn->query($sql)) {
      echo json_encode(["success" => true, "message" => "User deleted successfully"]);
    } else {
      echo json_encode(["error" => $conn->error]);
    }
    break;

  default:
    echo json_encode(["error" => "Invalid request method"]);
}

$conn->close();
