<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET, POST');

include_once '../../config/Database.php';
include_once '../../lib/any_table_empty.php';

//if ($_SERVER['REQUEST_METHOD'] === 'GET') {
if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $db = new Database();
    $conn = $db->connect();

    $travailleurDB = new AnyTable($conn, "travailleur", "id_travailleur","",
        [
            'id_travailleur' => '',
            'nom' => '',
            'no_registre_national' => '',
            'email' => ''
        ]);

    $data = json_decode(file_get_contents("php://input"));

    if (isset($data->id_travailleur)){
        $travailleurDB->identValue = $data->id_travailleur;

        if ($travailleurDB->fetchOne()) {
            print_r(json_encode($travailleurDB->fields));
        }else{
            echo json_encode(['message' => 'travailleur non trouvé']);
        }
    } else {
        echo json_encode(['message' => 'id non renseigné']);

    }}
?>