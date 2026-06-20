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

    $travailleurDB = new AnyTable($conn, "travailleur");

    $data = json_decode(file_get_contents("php://input"));

}
if (isset($data->nom) and isset($data->privileges) and isset($data->no_registre_national) and isset($data->email) and isset($data->password))
{
    $checkDB = new AnyTable($conn, "travailleur", "no_registre_national", $data->no_registre_national,
        ['id_travailleur' => '']);

    if ($checkDB->fetchOne()) {
        echo json_encode(['message' => 'Ce numéro de registre national est déjà utilisé']);
        exit;
    }

    $travailleurDB->fields = [
        'nom' => $data->nom,
        'privileges' => $data->privileges,
        'no_registre_national' => $data->no_registre_national,
        'email' => $data->email,
        'password' => password_hash($data->password, PASSWORD_BCRYPT)
    ];

    if ($travailleurDB->postData())
    {
        echo json_encode(['message' => 'Travailleur ajouté avec succès']);
    } else
    {
        echo json_encode(['message' => 'Erreur lors de l\'ajout']);
    }
} else {
    echo json_encode(['message' => 'Données invalides ou manquantes']);
}
?>