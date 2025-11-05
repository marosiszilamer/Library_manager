<?php



header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");



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
$input = json_decode(file_get_contents("php://input"), true);

switch ($method) {
  //  READ (Összes user betoltese)
  case 'GET':
    $sql = "SELECT * FROM users";
    $result = $conn->query($sql);
    $users = [];
    while ($row = $result->fetch_assoc()) {
      $users[] = $row;
    }
    echo json_encode($users);
    break;

  //  CREATE (Új user)
  case 'POST':
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
