<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');

include_once '../../config/Database.php';
include_once '../../lib/any_table_empty.php';
include_once '../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['message' => 'Méthode incorrecte']);
    exit;
}

$db   = new Database();
$conn = $db->connect();

$user = requirePrivilege($conn, ['admin']);

$data = json_decode(file_get_contents('php://input'));

if (!isset($data->id_code)) {
    echo json_encode(['message' => 'Données invalides ou manquantes']);
    exit;
}

// Récupérer code source
$stmt = $conn->prepare(
    'SELECT nom_code, valeur, description, date_fin
     FROM log_evolution_code_heure
     WHERE id_code = ?
     ORDER BY date_debut DESC
     LIMIT 1'
);
$stmt->execute([$data->id_code]);
$existing = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$existing) {
    echo json_encode(['message' => 'Code non trouvé']);
    exit;
}

if ($existing['date_fin'] === null) {
    echo json_encode(['message' => 'Ce code est déjà actif']);
    exit;
}

// date_debut de la réactivation
if (isset($data->date_debut) && preg_match('/^\d{4}-\d{2}-\d{2}$/', $data->date_debut)) {
    $date_debut = $data->date_debut;
} else {
    $date_debut = date('Y-m-d');
}

// La nouvelle période doit débuter APRÈS la fin de l'ancienne
if ($date_debut <= $existing['date_fin']) {
    echo json_encode(['message' => 'La date de réactivation doit être postérieure à la date de clôture (' . $existing['date_fin'] . ')']);
    exit;
}

$insert = $conn->prepare(
    'INSERT INTO log_evolution_code_heure (id_code, nom_code, valeur, description, date_debut, date_fin)
                VALUES (?, ?, ?, ?, ?, NULL)'
);
$insert->execute([
    $data->id_code,
    $existing['nom_code'],
    $existing['valeur'],
    $existing['description'],
    $date_debut
]);

if ($insert->rowCount() > 0) {
    echo json_encode(['message' => 'Code réactivé avec succès', 'id_code' => $data->id_code]);
} else {
    echo json_encode(['message' => 'Erreur lors de la réactivation']);
}