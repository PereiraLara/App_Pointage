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

    $user = requirePrivilege($conn, ['admin', 'contremaitre/manager']);

    if (!isset($_GET['id_code'])) {
        echo json_encode(['message' => 'id non renseigné']);
        exit;
    }

    $stmt = $conn->prepare('SELECT id_code, nom_code, valeur, description, date_debut, date_fin
                                     FROM log_evolution_code_heure 
                                     WHERE id_code = ?'
    );

    $stmt->execute([$_GET['id_code']]);

    if ($stmt->rowCount() > 0) {
        $rows = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $rows[] = [
                'id_code' => $row['id_code'],
                'nom_code' => $row['nom_code'],
                'valeur' => $row['valeur'],
                'description' => $row['description'],
                'date_debut' => $row['date_debut'],
                'date_fin' => $row['date_fin'],
            ];
        }
        echo json_encode($rows);
    } else {
        echo json_encode([]);
    }
} else {
    echo json_encode(array('message' => "Error: incorrect Method!"));
}
?>