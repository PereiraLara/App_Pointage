<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type GET
header('Access-Control-Allow-Methods: GET, POST');

include_once '../../config/Database.php';
include_once '../../lib/any_table_empty.php';
include_once '../../lib/auth.php';

//if ($_SERVER['REQUEST_METHOD'] === 'GET') {
if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $db = new Database();
    $conn = $db->connect();

    $user = requirePrivilege($conn, ['admin', 'contremaitre/manager', 'chef_equipe']);

    $equipeDB = new AnyTable($conn, "equipe", "id_equipe","",
        [
            'id_equipe' => '',
            'nom_equipe' => '',
            'specialisation' => '',
            'capacite' => '',
            'chef_de_equipe' => '',
            'parent_id' => ''
        ]);

    $data = json_decode(file_get_contents("php://input"));

 if (isset($data->id_equipe)){
        $equipeDB->identValue = $data->id_equipe;

        if ($equipeDB->fetchOne()) {
            print_r(json_encode($equipeDB->fields));
        }else{
            echo json_encode(['message' => 'equipe non trouvé']);
        }
    } else {
        echo json_encode(['message' => 'id non renseigné']);

    }}
?>