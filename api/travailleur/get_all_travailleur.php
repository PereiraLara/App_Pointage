<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type GET
header('Access-Control-Allow-Methods: GET');

include_once '../../config/Database.php';
include_once '../../lib/auth.php';


if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(array('message' => "Error: incorrect Method!"));
}

    $db = new Database();
    $conn = $db->connect();

    $user = requirePrivilege($conn, ['admin', 'contremaitre/manager']);

$stmt = $conn->prepare("SELECT id_travailleur, nom, no_registre_national, email  FROM travailleur 
                                    order by id_travailleur ASC");

$stmt->execute();

$travailleurs = $stmt->fetchAll(PDO::FETCH_ASSOC);

if (!empty($travailleurs)) {
    echo json_encode($travailleurs);
} else {
    echo json_encode(['message' => 'No records found!']);
}
?>