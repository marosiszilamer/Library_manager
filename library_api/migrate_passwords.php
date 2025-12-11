<?php
require_once __DIR__ . '/db_con.php';

// Teszt felhasználók jelszavai - ezek hasheldnek az adatbázisba
$testPasswords = [
    'balazs01' => 'jelszó123',
    'andrea22' => 'jelszó123',
    'admin' => 'admin123',
    'peter89' => 'jelszó123',
    'katalinK' => 'jelszó123',
    'martonL' => 'jelszó123',
    'orsolyaT' => 'jelszó123',
    'gaborN' => 'jelszó123',
    'noemiV' => 'jelszó123',
    'davidF' => 'jelszó123',
];

foreach ($testPasswords as $username => $password) {
    $hash = password_hash($password, PASSWORD_BCRYPT);
    $stmt = $pdo->prepare("UPDATE users SET password_hash = ? WHERE username = ?");
    $stmt->execute([$hash, $username]);
    echo "Updated $username with hash: " . substr($hash, 0, 20) . "...\n";
}

echo "All test users updated with BCRYPT hashes!\n";
