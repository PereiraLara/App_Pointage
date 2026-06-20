<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: PUT');

include_once '../../config/Database.php';
include_once '../../lib/any_table_empty.php';
include_once '../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    echo json_encode(['message' => 'Méthode incorrecte']);
    exit;
}

$db = new Database();
$conn = $db->connect();

$user = requirePrivilege($conn, ['admin']);

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->id_code)) {
    echo json_encode(['message' => 'Données invalides ou manquantes']);
    exit;
}

$id_code = $data->id_code;

$stmt = $conn->prepare('UPDATE log_evolution_code_heure SET date_fin = CURRENT_DATE 
                                    WHERE id_code=?
                                    AND date_fin is null');
$stmt->execute( [$id_code] );

if ($stmt->rowCount() === 0) {
    echo json_encode(['message' => 'Code non trouvée']);
    exit;
}

echo json_encode(['message' => 'Code clôturée avec succès']);
?>