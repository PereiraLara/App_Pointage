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

    $equipeDB = new AnyTable($conn, "equipe", "id_equipe","",
        [
            'id_equipe' => '',
            'nom_equipe' => '',
            'specialisation' => '',
            'capacite' => '',
            'chef_de_equipe' => '',
            'parent_id' => '',
            'date_fin' => ''
        ]);

    $data = json_decode(file_get_contents("php://input"));

    $res = $conn->query('SELECT * FROM equipe');

    $resCount = $res->rowCount();

    if($resCount > 0) {

        $equipes = array();

        while($row = $res->fetch(PDO::FETCH_ASSOC)) {

            extract($row);

            array_push($equipes, array( 'id_equipe' => $id_equipe,
                'nom_equipe' => $nom_equipe,
                'specialisation' => $specialisation,
                'capacite' => $capacite,
                'chef_de_equipe' => $chef_de_equipe,
                'parent_id' => $parent_id,
                'date_fin' => $date_fin
            ));
        }

        echo json_encode($equipes);

    } else {
        echo json_encode(array('message' => "No records found!"));
    }
} else {
    echo json_encode(array('message' => "Error: incorrect Method!"));
}
?>