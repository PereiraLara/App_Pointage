<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type GET
header('Access-Control-Allow-Methods: PUT');

include_once '../../config/Database.php';
include_once '../../lib/any_table_empty.php';
include_once '../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] === 'PUT') {

    $db = new Database();
    $conn = $db->connect();

    $user = requirePrivilege($conn, ['admin']);

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

    if (isset($data->id_equipe))
    {
        $equipeDB->identValue = $data->id_equipe;

        if (!$equipeDB->fetchOne()) {
            echo json_encode(['message' => 'Equipe non trouvé']);
            exit;
        }

        $equipeDB->fields = [
            'nom_equipe' => isset($data->nom_equipe) ? $data->nom_equipe : $equipeDB->fields['nom_equipe'],
            'specialisation' => isset($data->specialisation) ? $data->specialisation : $equipeDB->fields['specialisation'],
            'capacite' => isset($data->capacite) ? $data->capacite : $equipeDB->fields['capacite'],
            'chef_de_equipe' => isset($data->chef_de_equipe) ? $data->chef_de_equipe : $equipeDB->fields['chef_de_equipe'],
            'parent_id' => isset($data->parent_id) ? $data->parent_id : null,
        ];

        if ($equipeDB->putData())
        {
            echo json_encode(['message' => 'Equipe modifié avec succès']);
        } else
        {
            echo json_encode(['message' => 'Erreur lors de la modification']);
        }
    } else {
        echo json_encode(['message' => 'Données invalides ou manquantes']);
    }}
?>