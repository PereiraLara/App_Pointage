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

if (!isset($data->id_equipe)) {
    echo json_encode(['message' => 'Données invalides ou manquantes']);
    exit;
}

$id_equipe = $data->id_equipe;
$date_fin = isset($data->date_fin) ? $data->date_fin : date('Y-m-d');

$stmt = $conn->prepare('UPDATE equipe SET date_fin=? 
                                    WHERE id_equipe=?');
$stmt->execute([$date_fin, $id_equipe]);

if ($stmt->rowCount() === 0) {
    echo json_encode(['message' => 'Equipe non trouvée']);
    exit;
}

$stmt2 = $conn->prepare('UPDATE travailleur_equipe 
                                    SET date_fin = ?
                                    WHERE id_equipe = ? 
                                      AND date_fin IS NULL');
$stmt2->execute([$date_fin, $id_equipe]);

echo json_encode(['message' => 'Equipe clôturée avec succès']);
?>