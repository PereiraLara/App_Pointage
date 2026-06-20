<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: DELETE');

include_once '../../config/Database.php';
include_once '../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    echo json_encode(['message' => 'Méthode non autorisée']);
    exit;
}

$db   = new Database();
$conn = $db->connect();

$user = requirePrivilege($conn, ['admin']);

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->id_travailleur) || !isset($data->date_fin)) {
    echo json_encode(['message' => 'id_travailleur ou date_fin manquant']);
    exit;
}

$id_travailleur = (int)$data->id_travailleur;
$date_fin       = $data->date_fin;

// Empêcher l'archivage si le travailleur est encore chef d'une équipe active
$chefCheck = $conn->prepare("SELECT nom_equipe FROM equipe 
                                    WHERE chef_de_equipe = ? 
                                      AND date_fin IS NULL
                                      OR date_fin > curdate()");
$chefCheck->execute([$id_travailleur]);
$equipes = $chefCheck->fetchAll(PDO::FETCH_COLUMN);

if (count($equipes) > 0) {
    echo json_encode([
        'message' => 'Suppression impossible : ce travailleur est encore chef d\'équipe. Veuillez d\'abord réassigner un nouveau chef.',
        'equipes' => $equipes
    ]);
    exit;
}

$stmt = $conn->prepare("CALL archiver_travailleur(?, ?)");
$stmt->execute([$id_travailleur, $date_fin]);
$stmt->closeCursor();

// Vérifier que le travailleur existe bien et a été archivé
$check = $conn->prepare("SELECT id_travailleur FROM travailleur WHERE id_travailleur = ? AND email IS NULL AND password IS NULL");
$check->execute([$id_travailleur]);

if ($check->rowCount() > 0) {
    echo json_encode(['message' => 'Travailleur archivé avec succès']);
} else {
    echo json_encode(['message' => 'Travailleur non trouvé ou déjà archivé']);
}
?>