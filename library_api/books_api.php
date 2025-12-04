<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include "db_con.php";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    die(json_encode(["error" => "Connection failed: " . $conn->connect_error]));
}

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents("php://input"), true);

switch ($method) {

    // <- GET – összes könyv vagy 1 könyv ID alapján
    case 'GET':
        // Return books with category name (if available) so frontend can show category
        if (isset($_GET['book_id'])) {
            $book_id = intval($_GET['book_id']);
            // Explicitly select fields so `isbn` and `publisher` are always returned
            $sql = "SELECT b.book_id, b.title, b.price, b.stock,
                       COALESCE(b.isbn, '') AS isbn, COALESCE(b.publisher, '') AS publisher,
                       b.published_year, b.description, b.cover_image,
                       COALESCE(c.name, '') AS category_name, COALESCE(a.name, '') AS author_name
            FROM books b
            LEFT JOIN categories c ON c.category_id = b.category_id
            LEFT JOIN authors a ON a.author_id = b.author_id
            WHERE b.book_id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param('i', $book_id);
            $stmt->execute();
            $result = $stmt->get_result();
        } else {
            // Explicitly select fields so `isbn` and `publisher` are included for every book
            $sql = "SELECT b.book_id, b.title, b.price, b.stock,
                       COALESCE(b.isbn, '') AS isbn, COALESCE(b.publisher, '') AS publisher,
                       b.published_year, b.description, b.cover_image,
                       COALESCE(c.name, '') AS category_name, COALESCE(a.name, '') AS author_name
            FROM books b
            LEFT JOIN categories c ON c.category_id = b.category_id
            LEFT JOIN authors a ON a.author_id = b.author_id";
            $result = $conn->query($sql);
        }
        $data = [];
        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }
        echo json_encode($data);
        break;

    // + POST – új könyv hozzáadása
    case 'POST':
        $title = $input['title'] ?? '';
        $author_id = intval($input['author_id'] ?? 0);
        $category_id = intval($input['category_id'] ?? 0);
        $price = floatval($input['price'] ?? 0);
        $stock = intval($input['stock'] ?? 0);
        $isbn = $input['isbn'] ?? '';
        $publisher = $input['publisher'] ?? '';
        $published_year = intval($input['published_year'] ?? 0);
        $description = $input['description'] ?? '';
        $cover_image = $input['cover_image'] ?? '';

        $stmt = $conn->prepare("INSERT INTO books (title, author_id, category_id, price, stock, isbn, publisher, published_year, description, cover_image)
                                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("siidississ", $title, $author_id, $category_id, $price, $stock, $isbn, $publisher, $published_year, $description, $cover_image);

        if ($stmt->execute()) {
            echo json_encode(["message" => "Book added successfully"]);
        } else {
            echo json_encode(["error" => $stmt->error]);
        }
        $stmt->close();
        break;

    // ->  PUT – könyv frissítése
    case 'PUT':
        $book_id = intval($_GET['book_id'] ?? 0);
        if ($book_id <= 0) {
            echo json_encode(["error" => "Missing book_id"]);
            break;
        }

        $title = $input['title'] ?? '';
        $author_id = intval($input['author_id'] ?? 0);
        $category_id = intval($input['category_id'] ?? 0);
        $price = floatval($input['price'] ?? 0);
        $stock = intval($input['stock'] ?? 0);
        $isbn = $input['isbn'] ?? '';
        $publisher = $input['publisher'] ?? '';
        $published_year = intval($input['published_year'] ?? 0);
        $description = $input['description'] ?? '';
        $cover_image = $input['cover_image'] ?? '';

        $stmt = $conn->prepare("UPDATE books SET title=?, author_id=?, category_id=?, price=?, stock=?, isbn=?, publisher=?, published_year=?, description=?, cover_image=? WHERE book_id=?");
        $stmt->bind_param("siidississi", $title, $author_id, $category_id, $price, $stock, $isbn, $publisher, $published_year, $description, $cover_image, $book_id);

        if ($stmt->execute()) {
            echo json_encode(["message" => "Book updated successfully"]);
        } else {
            echo json_encode(["error" => $stmt->error]);
        }
        $stmt->close();
        break;

    // X DELETE – könyv törlése
    case 'DELETE':
        $book_id = intval($_GET['book_id'] ?? 0);
        if ($book_id <= 0) {
            echo json_encode(["error" => "Missing book_id"]);
            break;
        }

        $stmt = $conn->prepare("DELETE FROM books WHERE book_id=?");
        $stmt->bind_param("i", $book_id);

        if ($stmt->execute()) {
            echo json_encode(["message" => "Book deleted successfully"]);
        } else {
            echo json_encode(["error" => $stmt->error]);
        }
        $stmt->close();
        break;

    default:
        echo json_encode(["error" => "Invalid request method"]);
}

$conn->close();
?>
