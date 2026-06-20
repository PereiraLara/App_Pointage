<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET');

include_once '../../../config/Database.php';
include_once '../../../lib/any_table_empty.php';
include_once '../../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(['message' => 'Méthode incorrecte']);
    exit;
}

$db   = new Database();
$conn = $db->connect();

$user = requirePrivilege($conn, ['admin']);

$stmt = $conn->prepare('SELECT * FROM jours_feries_mobiles 
                                WHERE id_ferie = ?
                                order by annee desc');

if (!isset($_GET['id_ferie'])) {
    echo json_encode(['message' => 'id non renseigné']);
    exit;
}

$stmt->execute([$_GET['id_ferie']]);

if ($stmt->rowCount() > 0) {
    $rows = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $rows[] = [
            'id_ferie' => $row['id_ferie'],
            'annee' => (int) $row['annee'],
            'date_ferie' => $row['date_ferie'],
        ];
    }
    echo json_encode($rows);
} else {
    echo json_encode([]);
}
?>