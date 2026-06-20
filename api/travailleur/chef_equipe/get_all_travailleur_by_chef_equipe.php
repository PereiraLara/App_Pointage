<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET');

include_once '../../../config/Database.php';
include_once '../../../models/travailleur.php';
include_once '../../../lib/auth.php';


if ($_SERVER['REQUEST_METHOD'] === 'GET') {

    $db = new Database();
    $conn = $db->connect();

    $user = requirePrivilege($conn, ['admin', 'contremaitre/manager', 'chef_equipe']);

    $travailleurDB = new travailleur($conn, "travailleur", "id_travailleur", "",
        [
            'id_travailleur' => '',
            'nom' => '',
            'no_registre_national' => '',
            'email' => ''
        ]);


    if (isset($_GET['id_travailleur']) && isset($_GET['jour']) && isset($_GET['mois']) && isset($_GET['annee']))
    {
        $travailleurDB->identValue = $_GET['id_travailleur'];
        $travailleurDB->jour = $_GET['jour'];
        $travailleurDB->mois = $_GET['mois'];
        $travailleurDB->annee = $_GET['annee'];

        $res = $travailleurDB->fetchTravailleurParChefEquipe();

        $travailleurs = [];

        while ($row = $res->fetch(PDO::FETCH_ASSOC)) {
            $travailleurs[] = $row;
        }

        echo json_encode($travailleurs);
    } else {
        echo json_encode(['message' => 'No id or date provided']);
    }
}
 else {
    echo json_encode(array('message' => "Error: incorrect Method!"));
}

?>