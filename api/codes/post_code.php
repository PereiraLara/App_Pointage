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

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['message' => 'Méthode incorrecte']);
    exit;
}

    $db = new Database();
    $conn = $db->connect();

    $user = requirePrivilege($conn, ['admin']);

    $codeDB = new AnyTable($conn, "log_evolution_code_heure");

    $data = json_decode(file_get_contents("php://input"));


if (isset($data->nom_code) and isset($data->valeur) and isset($data->description) and isset($data->date_debut))
{
    $stmt = $conn->prepare('SELECT COUNT(*) FROM log_evolution_code_heure 
                                        WHERE nom_code = ?
                           ');

    $stmt->execute([$data->nom_code]);
    if ($stmt->fetchColumn() > 0) {
        echo json_encode(['message' => 'Erreur lors de l\'ajout - Code déjà existant']);
        exit;
    }

    $codeDB->fields = [
        'nom_code' => $data->nom_code,
        'valeur' => $data->valeur,
        'description' => $data->description,
        'date_debut' => $data->date_debut,
        'date_fin' => $data->date_fin ?: null,
    ];

    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);


    if ($codeDB->postData())
    {
        echo json_encode(['message' => 'Code ajouté avec succès']);
    } else
    {
        echo json_encode(['message' => 'Erreur lors de l\'ajout']);
    }
} else {
    echo json_encode(['message' => 'Données invalides ou manquantes']);
}
?>