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

$ferieDB = new AnyTable($conn, 'feries_mobiles', 'id_ferie', '', [
    'id_ferie'       => '',
    'nom_ferie'      => '',
    'decalage_jours' => '',
    'date_debut'     => '',
    'date_fin'       => '',
    'legal'          => '',
]);

$ferieDB->identValue = $data->id_ferie;

if (!$ferieDB->fetchOne()) {
    echo json_encode(['message' => 'Férié mobile non trouvé']);
    exit;
}

$ferieDB->fields = [
    'nom_ferie'      => isset($data->nom_ferie)      ? $data->nom_ferie                   : $ferieDB->fields['nom_ferie'],
    'decalage_jours' => isset($data->decalage_jours) ? (int) $data->decalage_jours        : (int) $ferieDB->fields['decalage_jours'],
    'date_debut'     => isset($data->date_debut)     ? $data->date_debut                  : $ferieDB->fields['date_debut'],
    'date_fin'       => (isset($data->date_fin) && $data->date_fin !== '') ? $data->date_fin : null,
    'legal'          => isset($data->legal)           ? (int) $data->legal                 : (int) $ferieDB->fields['legal'],
];

if ($ferieDB->putData()) {
    echo json_encode(['message' => 'Férié mobile modifié avec succès']);
} else {
    echo json_encode(['message' => 'Erreur lors de la modification']);
}
?>