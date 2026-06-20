<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: PUT');

include_once '../../config/Database.php';
include_once '../../lib/auth.php';

$db = new Database();
$conn = $db->connect();

$user = requirePrivilege($conn, ['admin', 'contremaitre/manager', 'chef_equipe']);

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->id_travailleur, $data->jour, $data->mois, $data->annee, $data->valeur)) {
    http_response_code(400);
    echo json_encode(['message' => 'Données invalides ou manquantes']);
    exit;
}

$id_travailleur = (int)$data->id_travailleur;
$mois = (int)$data->mois;
$annee = (int)$data->annee;
$jour = (int)$data->jour;
$valeur = trim((string)$data->valeur);

if ($jour < 1 || $jour > 31) {
    http_response_code(400);
    echo json_encode(['message' => 'Jour invalide']);
    exit;
}

// Check row exists
$stmt = $conn->prepare("SELECT 1 FROM heures
                                    WHERE id_travailleur = ?
                                      AND mois = ?
                                      AND annee = ?");

$stmt->execute([$id_travailleur, $mois, $annee]);

if ($stmt->rowCount() === 0) {
    http_response_code(404);
    echo json_encode(['message' => 'Aucune ligne trouvée pour ce travailleur/mois/année']);
    exit;
}

$sql = "UPDATE heures SET `$jour` = ?
            WHERE id_travailleur = ?
              AND mois = ?
              AND annee = ?";

$stmt = $conn->prepare($sql);
$success = $stmt->execute([$valeur, $id_travailleur, $mois, $annee]);

if ($success && $stmt->rowCount() > 0) {
    echo json_encode(['success' => true]);
} elseif ($success) {
    echo json_encode(['success' => true, 'note' => 'Valeur inchangée']);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $stmt->errorInfo()]);
}