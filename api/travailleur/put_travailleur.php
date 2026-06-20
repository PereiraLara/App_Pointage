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

    $travailleurDB = new AnyTable($conn, "travailleur", "id_travailleur","",
        [
            'id_travailleur' => '',
            'nom' => '',
            'no_registre_national' => '',
            'email' => '',
            'password' => ''
        ]);

    $data = json_decode(file_get_contents("php://input"));

    if (isset($data->id_travailleur))
    {
        $travailleurDB->identValue = $data->id_travailleur;

        if (!$travailleurDB->fetchOne()) {
            echo json_encode(['message' => 'Travailleur non trouvé']);
            exit;
        }

        // Vérifier que le no_registre_national soit unique
        if (isset($data->no_registre_national) && $data->no_registre_national !== $travailleurDB->fields['no_registre_national']) {
            $stmt = $conn->prepare('SELECT id_travailleur FROM travailleur 
                                                WHERE no_registre_national = ? 
                                                  AND id_travailleur != ?
                                    ');
            $stmt->execute([$data->no_registre_national, $data->id_travailleur]);

            if ($stmt->rowCount() > 0) {
                echo json_encode(['message' => 'Ce numéro de registre national est déjà utilisé']);
                exit;
            }
        }

        $travailleurDB->fields = [
            'nom' => isset($data->nom) ? $data->nom : $travailleurDB->fields['nom'],
            'no_registre_national' => isset($data->no_registre_national) ? $data->no_registre_national : $travailleurDB->fields['no_registre_national'],
            'email' => isset($data->email) ? $data->email : $travailleurDB->fields['email'],
            'password' => isset($data->password) ? $data->password : $travailleurDB->fields['password'],
        ];

        if ($travailleurDB->putData())
        {
            echo json_encode(['message' => 'Travailleur modifié avec succès']);
        } else
        {
            echo json_encode(['message' => 'Erreur lors de la modification']);
        }
    } else {
        echo json_encode(['message' => 'Données invalides ou manquantes']);
    }}
?>