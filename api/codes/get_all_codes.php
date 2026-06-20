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

    $data = json_decode(file_get_contents("php://input"));

    $res = $conn->query('SELECT l.id_code, l.nom_code, l.valeur, l.description, l.date_debut, l.date_fin
                                     FROM log_evolution_code_heure l
                                     INNER JOIN (
                                         SELECT id_code, MAX(date_debut) AS max_debut
                                         FROM log_evolution_code_heure
                                         GROUP BY id_code
                                     ) m ON m.id_code = l.id_code AND m.max_debut = l.date_debut'
                        );

    $resCount = $res->rowCount();

    if($resCount > 0) {

        $codes = array();

        while($row = $res->fetch(PDO::FETCH_ASSOC)) {

            extract($row);

            array_push($codes, array( 'id_code' => $id_code,
                'nom_code' => $nom_code,
                'valeur' => $valeur,
                'description' => $description,
                'date_debut' => $date_debut,
                'date_fin' => $date_fin,
            ));
        }

        echo json_encode($codes);

    } else {
        echo json_encode(array('message' => "No records found!"));
    }
} else {
    echo json_encode(array('message' => "Error: incorrect Method!"));
}
?>