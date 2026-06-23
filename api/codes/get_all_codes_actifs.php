<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type GET
header('Access-Control-Allow-Methods: GET');

include_once '../../config/Database.php';
include_once '../../lib/any_table_empty.php';
include_once '../../lib/auth.php';


if ($_SERVER['REQUEST_METHOD'] === 'GET') {

    $db = new Database();
    $conn = $db->connect();

    $data = json_decode(file_get_contents("php://input"));

    if (isset($_GET['date']) && preg_match('/^\d{4}-\d{2}-\d{2}$/', $_GET['date'])) {
        $date = $_GET['date'];
    } else {
        $date = date('Y-m-d');
    }

    $stmt = $conn->prepare('SELECT id_code, nom_code, valeur, description, date_debut, date_fin
                                     FROM log_evolution_code_heure 
                                         where date_debut <= :date
                                         and (date_fin >= :date or date_fin is null)
                                         order by nom_code
                             ');

    $stmt->bindParam(':date', $date);
    $stmt->execute();

    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (count($rows) > 0) {
        echo json_encode($rows);
    } else {
        echo json_encode(['message' => 'No records found!']);
    }
} else {
    echo json_encode(array('message' => "Error: incorrect Method!"));
}
?>