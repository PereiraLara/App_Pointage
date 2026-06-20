<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type GET
header('Access-Control-Allow-Methods: GET');

include_once '../../config/Database.php';
include_once '../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {

    $db = new Database();
    $conn = $db->connect();

    $user = requirePrivilege($conn, ['admin', 'contremaitre/manager', 'chef_equipe']);

    if (isset($_GET['id_travailleur'])) {
        $id_chef = $_GET['id_travailleur'];

    $stmt = $conn->prepare('SELECT * FROM equipe
                                     WHERE chef_de_equipe = ?
                         ');

    $stmt->execute( [$id_chef] );
    $resCount = $stmt->rowCount();

    if($resCount > 0) {
        $equipes = array();

        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {

            array_push($equipes, array(
                'id_equipe' => $row['id_equipe'],
                'nom_equipe' => $row['nom_equipe'],
                'specialisation' => $row['specialisation'],
                'capacite' => $row['capacite'],
                'chef_de_equipe' => $row['chef_de_equipe'],
                'parent_id' => $row['parent_id'],
                'date_fin' => $row['date_fin']
            ));
        }

        echo json_encode($equipes);

    } else {
        echo json_encode(array('message' => "No records found!"));
    }
    } else {
        echo json_encode(array('message' => "No id_travailleur provided"));
    }
} else {
    echo json_encode(array('message' => "Error: incorrect Method!"));
}
?>