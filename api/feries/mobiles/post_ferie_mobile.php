<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');

include_once '../../../config/Database.php';
include_once '../../../lib/any_table_empty.php';
include_once '../../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['message' => 'Méthode incorrecte']);
    exit;
}

$db   = new Database();
$conn = $db->connect();

$user = requirePrivilege($conn, ['admin']);

$data = json_decode(file_get_contents('php://input'));

if (!isset($data->nom_ferie, $data->decalage_jours, $data->date_debut)) {
    echo json_encode(['message' => 'Données invalides ou manquantes']);
    exit;
}

$ferieDB = new AnyTable($conn, 'feries_mobiles');
$ferieDB->fields = [
    'nom_ferie'      => $data->nom_ferie,
    'decalage_jours' => (int) $data->decalage_jours,
    'date_debut'     => $data->date_debut,
    'date_fin'       => isset($data->date_fin) && $data->date_fin !== '' ? $data->date_fin : null,
    'legal'          => isset($data->legal) ? (int) $data->legal : 1,
];

if ($ferieDB->postData()) {
    echo json_encode(['message' => 'Férié mobile ajouté avec succès']);
} else {
    echo json_encode(['message' => 'Erreur lors de l\'ajout']);
}
?>