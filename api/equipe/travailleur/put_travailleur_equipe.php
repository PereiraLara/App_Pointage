<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type PUT
header('Access-Control-Allow-Methods: PUT');

include_once '../../../config/Database.php';
include_once '../../../lib/any_table_empty.php';
include_once '../../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] === 'PUT') {

    $db   = new Database();
    $conn = $db->connect();

    $user = requirePrivilege($conn, ['admin']);

    $data = json_decode(file_get_contents("php://input"));

    if (isset($data->id_equipe) && isset($data->id_travailleur)) {
        $id_equipe = $data->id_equipe;
        $id_travailleur = $data->id_travailleur;

        $date_fin = isset($data->date_fin) ? $data->date_fin : date('Y-m-d');

        $stmt = $conn->prepare('UPDATE travailleur_equipe
                                            SET date_fin = ?
                                                WHERE id_equipe = ?
                                                  AND id_travailleur = ?
                                                  AND date_fin IS NULL');

        $stmt->bindParam(1, $date_fin);
        $stmt->bindParam(2, $id_equipe);
        $stmt->bindParam(3, $id_travailleur);

        $stmt->execute();

        if ($stmt->rowCount() > 0) {
            echo json_encode(['message' => 'Travailleur retiré de l\'équipe avec succès']);
        } else {
            echo json_encode(['message' => 'Aucune ligne active trouvée pour ce travailleur dans cette équipe']);
        }

    } else {
        echo json_encode(['message' => 'Données invalides ou manquantes (id_equipe, id_travailleur requis)']);
    }
}
?>