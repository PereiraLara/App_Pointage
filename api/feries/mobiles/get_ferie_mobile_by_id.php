<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type GET
header('Access-Control-Allow-Methods: GET');

include_once '../../../config/Database.php';
include_once '../../../lib/any_table_empty.php';
include_once '../../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {

    $db = new Database();
    $conn = $db->connect();

    $user = requirePrivilege($conn, ['admin']);

    $ferieDB = new AnyTable($conn, 'feries_mobiles', 'id_ferie', '', [
        'id_ferie' => '',
        'nom_ferie' => '',
        'decalage_jours' => '',
        'date_debut' => '',
        'date_fin' => '',
        'legal' => '',
    ]);

    if (!isset($_GET['id_ferie'])) {
        echo json_encode(['message' => 'id non renseigné']);
        exit;
    }

    $ferieDB->identValue = $_GET['id_ferie'];

    if ($ferieDB->fetchOne()) {
        echo json_encode($ferieDB->fields);
    } else {
        echo json_encode(['message' => 'Ferie non trouvé']);
    }
    } else {
        echo json_encode(['message' => 'id non renseigné']);

    }
?>