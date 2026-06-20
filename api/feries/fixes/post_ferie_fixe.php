<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type GET
header('Access-Control-Allow-Methods: POST');

include_once '../../../config/Database.php';
include_once '../../../lib/any_table_empty.php';
include_once '../../../lib/auth.php';
include_once '../../../lib/normalizeEventDate.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $db = new Database();
    $conn = $db->connect();

    $user = requirePrivilege($conn, ['admin']);

    $ferieDB = new AnyTable($conn, "jours_feries_fixes");

    $data = json_decode(file_get_contents("php://input"));

}
if (isset($data->nom_ferie) and isset($data->event_date) and isset($data->date_debut))
{
    $event_date = normalizeEventDate($data->event_date);
    if ($event_date === null) {
        echo json_encode(['message' => 'Date de l\'événement invalide']);
        exit;
    }

    $ferieDB->fields = [
        'nom_ferie' => $data->nom_ferie,
        'event_date' => $event_date,
        'date_debut' => $data->date_debut,
        'date_fin' => $data->date_fin ?: null,
        'legal' => $data->legal,
    ];

    if ($ferieDB->postData())
    {
        echo json_encode(['message' => 'Ferie ajouté avec succès']);
    } else
    {
        echo json_encode(['message' => 'Erreur lors de l\'ajout']);
    }
} else {
    echo json_encode(['message' => 'Données invalides ou manquantes']);
}
?>