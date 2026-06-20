<?php
//run once
include_once '../../config/Database.php';

$db   = new Database();
$conn = $db->connect();

$stmt = $conn->query("SELECT id_travailleur, password FROM travailleur");
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$update = $conn->prepare("UPDATE travailleur SET password = ? WHERE id_travailleur = ?");

foreach ($rows as $row) {
    // Skip already-hashed passwords (bcrypt hashes start with $2y$)
    if (str_starts_with($row['password'], '$2y$')) continue;

    $hash = password_hash($row['password'], PASSWORD_BCRYPT);
    $update->execute([$hash, $row['id_travailleur']]);
    echo "Updated travailleur #{$row['id_travailleur']}<br>";
}
?>