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

    $codeDB = new AnyTable($conn, "log_evolution_code_heure", "id_code","",
        [
            'id_code' => '',
            'nom_code' => '',
            'description' => '',
            'valeur' => '',
            'date_debut' => '',
            'date_fin' => ''
        ]);

    $data = json_decode(file_get_contents("php://input"));

    if (isset($data->id_code))
    {
        $codeDB->identValue = $data->id_code;

        if (!$codeDB->fetchOne()) {
            echo json_encode(['message' => 'Code non trouvé']);
            exit;
        }

        if (isset($data->nom_code) && $data->nom_code !== $codeDB->fields['nom_code']) {
            $stmt = $conn->prepare('SELECT COUNT(*) FROM log_evolution_code_heure 
                                            WHERE nom_code = ?
                                              AND id_code != ?
                               ');

            $stmt->execute([$data->nom_code, $data->id_code]);
            if ($stmt->fetchColumn() > 0) {
                echo json_encode(['message' => 'Erreur lors de l\'ajout - Nom de Code déjà existant']);
                exit;
            }
        }

        $codeDB->fields = [
            'nom_code' => isset($data->nom_code) ? $data->nom_code : $codeDB->fields['nom_code'],
            'description' => isset($data->description) ? $data->description : $codeDB->fields['description'],
            'valeur' => isset($data->valeur) ? $data->valeur : $codeDB->fields['valeur'],
            'date_debut' => isset($data->date_debut) ? $data->date_debut : $codeDB->fields['date_debut'],
            'date_fin' => property_exists($data, 'date_fin') ? $data->date_fin : $codeDB->fields['date_fin'],
        ];

        if ($codeDB->putData())
        {
            echo json_encode(['message' => 'Code modifié avec succès']);
        } else
        {
            echo json_encode(['message' => 'Erreur lors de la modification']);
        }
    } else {
        echo json_encode(['message' => 'Données invalides ou manquantes']);
    }}
?>