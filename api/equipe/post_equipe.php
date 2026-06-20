<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type GET
header('Access-Control-Allow-Methods: POST');

include_once '../../config/Database.php';
include_once '../../lib/any_table_empty.php';
include_once '../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $db = new Database();
    $conn = $db->connect();

    $user = requirePrivilege($conn, ['admin']);

    $equipeDB = new AnyTable($conn, "equipe");

    $data = json_decode(file_get_contents("php://input"));

}
if (isset($data->nom_equipe) and isset($data->specialisation) and isset($data->capacite) and isset($data->chef_de_equipe))
{
    $equipeDB->fields = [
        'nom_equipe' => $data->nom_equipe,
        'specialisation' => $data->specialisation,
        'capacite' => $data->capacite,
        'chef_de_equipe' => $data->chef_de_equipe,
        'parent_id' => $data->parent_id ?: null,
    ];

    if ($equipeDB->postData())
    {
        echo json_encode(['message' => 'Equipe ajouté avec succès']);
    } else
    {
        echo json_encode(['message' => 'Erreur lors de l\'ajout']);
    }
} else {
    echo json_encode(['message' => 'Données invalides ou manquantes']);
}
?>