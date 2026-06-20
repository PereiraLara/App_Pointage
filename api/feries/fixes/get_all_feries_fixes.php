<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type GET
header('Access-Control-Allow-Methods: GET');

include_once '../../../config/Database.php';
include_once '../../../lib/any_table_empty.php';
include_once '../../../lib/jours_feries.php';
include_once '../../../lib/auth.php';


if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(['message' => 'Error: incorrect Method!']);
    exit;
}

$db = new Database();
$conn = $db->connect();

$user = requireAuth($conn);

$data = json_decode(file_get_contents("php://input"));

$res = $conn->query("SELECT id_ferie, nom_ferie, DATE_FORMAT(event_date, '%m-%d') AS event_date, date_debut, date_fin, legal
                                FROM jours_feries_fixes;
                    ");

$resCount = $res->rowCount();

if($resCount > 0) {

    $feries = array();

    while($row = $res->fetch(PDO::FETCH_ASSOC)) {

        extract($row);

        array_push($feries, array( 'id_ferie' => $id_ferie,
            'nom_ferie' => $nom_ferie,
            'event_date' => $event_date,
            'date_debut' => $date_debut,
            'date_fin' => $date_fin,
            'legal' => $legal
        ));
    }

    echo json_encode($feries);

} else {
    echo json_encode(array('message' => "No records found!"));
}

?>