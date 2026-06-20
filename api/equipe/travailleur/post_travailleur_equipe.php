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

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $db = new Database();
    $conn = $db->connect();

    $user = requirePrivilege($conn, ['admin']);

    $data = json_decode(file_get_contents("php://input"));

    if (isset($data->id_equipe) && isset($data->id_travailleur)) {

        $id_equipe = $data->id_equipe;
        $id_travailleur = $data->id_travailleur;
        $role = isset($data->role) ? $data->role : 'employe';
        $date_debut = isset($data->date_debut) ? $data->date_debut : date('Y-m-d');

        $stmt = $conn->prepare('INSERT INTO travailleur_equipe (id_equipe, id_travailleur, role, date_debut, date_fin)
                                            VALUES (?, ?, ?, ?, NULL)
                                                ON DUPLICATE KEY UPDATE
                                                    date_debut = VALUES(date_debut),
                                                    role = VALUES(role),
                                                    date_fin = NULL');

        $stmt->bindParam(1, $id_equipe);
        $stmt->bindParam(2, $id_travailleur);
        $stmt->bindParam(3, $role);
        $stmt->bindParam(4, $date_debut);

        if ($stmt->execute()) {
            echo json_encode(['message' => 'Travailleur assigné avec succès']);
        } else {
            echo json_encode(['message' => 'Erreur lors de l\'assignation']);
        }

    } else {
        echo json_encode(['message' => 'Données invalides ou manquantes (id_equipe, id_travailleur requis)']);
    }
}
?>