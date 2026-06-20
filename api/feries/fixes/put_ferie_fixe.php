<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type GET
header('Access-Control-Allow-Methods: PUT');

include_once '../../../config/Database.php';
include_once '../../../lib/any_table_empty.php';
include_once '../../../lib/auth.php';
include_once '../../../lib/normalizeEventDate.php';

if ($_SERVER['REQUEST_METHOD'] === 'PUT') {

    $db = new Database();
    $conn = $db->connect();

    $user = requirePrivilege($conn, ['admin']);

    $ferieDB = new AnyTable($conn, "jours_feries_fixes", "id_ferie","",
        [
            'id_ferie' => '',
            'nom_ferie' => '',
            'event_date' => '',
            'date_debut' => '',
            'date_fin' => '',
            'legal' => '',
        ]);

    $data = json_decode(file_get_contents("php://input"));

    if (isset($data->id_ferie))
    {
        $ferieDB->identValue = $data->id_ferie;

        if (!$ferieDB->fetchOne()) {
            echo json_encode(['message' => 'Ferie non trouvé']);
            exit;
        }

        $event_date = $ferieDB->fields['event_date'];

        if (isset($data->event_date)) {
            $normalized = normalizeEventDate($data->event_date);

            if ($normalized === null) {
                echo json_encode(['message' => 'Date de l\'événement invalide']);
                exit;
            }
            $event_date = $normalized;
        }

        $ferieDB->fields = [
            'nom_ferie' => isset($data->nom_ferie) ? $data->nom_ferie : $ferieDB->fields['nom_ferie'],
            'event_date' => $event_date,
            'date_debut' => isset($data->date_debut) ? $data->date_debut : $ferieDB->fields['date_debut'],
            'date_fin' => (isset($data->date_fin) && $data->date_fin !== '') ? $data->date_fin : null,
            'legal' => isset($data->legal) ? $data->legal : $ferieDB->fields['legal']
        ];

        if ($ferieDB->putData())
        {
            echo json_encode(['message' => 'Ferie modifié avec succès']);
        } else
        {
            echo json_encode(['message' => 'Erreur lors de la modification']);
        }
    } else {
        echo json_encode(['message' => 'Données invalides ou manquantes']);
    }}
?>