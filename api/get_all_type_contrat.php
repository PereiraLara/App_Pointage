<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET');

include_once '../config/Database.php';
include_once '../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(['message' => 'Méthode non autorisée']);
    exit;
}

$db   = new Database();
$conn = $db->connect();


// Récupérer les options enum de type_contrat et heures_journee_travail
$stmt = $conn->prepare("
    SELECT COLUMN_NAME, COLUMN_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME   = 'type_contrat'
      AND TABLE_SCHEMA = 'examsgbd'
      AND COLUMN_NAME  = 'type_contrat'
");
$stmt->execute();

$result = [];

while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    // COLUMN_TYPE looks like: enum('val1','val2','val3')
    // Strip enum( and ) then split by ','
    preg_match_all("/'([^']+)'/", $row['COLUMN_TYPE'], $matches);
    $result[$row['COLUMN_NAME']] = $matches[1];
}

echo json_encode($result);
?>