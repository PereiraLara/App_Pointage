<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type GET
header('Access-Control-Allow-Methods: GET, POST');

include_once '../../../config/Database.php';
include_once '../../../models/travailleur.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {

    $db = new Database();
    $conn = $db->connect();

    $travailleurDB = new travailleur($conn, "type_contrat", "id_travailleur","",
        []);

    $id_travailleur = isset($_GET['id_travailleur']) ? $_GET['id_travailleur'] : null;


    if ($id_travailleur) {
        $travailleurDB->identValue = $id_travailleur;
        $contrats = [];

        // Check if row exists
        $stmt = $conn->prepare("SELECT * FROM type_contrat
                                    WHERE id_travailleur = ?
                                    order by id_contrat ASC");

        $stmt->execute([$id_travailleur]);

        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $contrats[] = $row;
        }
        echo json_encode($contrats);
    } else {
        echo json_encode(array('message' => "No records found!"));
    }
} else {
    echo json_encode(array('message' => "Error: incorrect Method!"));
}
?>
