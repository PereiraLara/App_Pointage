<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: PUT');

include_once '../../../config/Database.php';
include_once '../../../lib/any_table_empty.php';
include_once '../../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    echo json_encode(['message' => 'Méthode incorrecte']);
    exit;
}

$db   = new Database();
$conn = $db->connect();

$user = requirePrivilege($conn, ['admin']);

$data = json_decode(file_get_contents('php://input'));

if (!isset($data->id_ferie)) {
    echo json_encode(['message' => 'Données invalides ou manquantes']);
    exit;
}

$stmt = $conn->prepare(
    'UPDATE feries_mobiles SET date_fin = CURRENT_DATE 
                      WHERE id_ferie = ?'
);
$stmt->execute([$data->id_ferie]);

if ($stmt->rowCount() === 0) {
    echo json_encode(['message' => 'Férié mobile non trouvé']);
    exit;
}

echo json_encode(['message' => 'Férié mobile clôturé avec succès']);
?>