<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET');

include_once '../../config/Database.php';
include_once '../../lib/jours_feries.php';
include_once '../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(['message' => 'Error: incorrect Method!']);
    exit;
}

$db   = new Database();
$conn = $db->connect();

$user = requireAuth($conn);

$mois  = isset($_GET['mois'])  ? (int)$_GET['mois']  : (int)date('n');
$annee = isset($_GET['annee']) ? (int)$_GET['annee'] : (int)date('Y');

// Si l'année n'est pas encore dans paques_annuel, on la calcule
$check = $conn->prepare("SELECT COUNT(*) FROM paques_annuel WHERE annee = ?");
$check->execute([$annee]);
if ($check->fetchColumn() == 0) {
    $conn->exec("CALL calculer_et_inserer_paques($annee)");
}

$feries = getJoursFeriesComplets($conn, $mois, $annee);

echo json_encode([
    'mois'   => $mois,
    'annee'  => $annee,
    'jours'  => array_map(fn($f) => (int)date('j', strtotime($f['date'])), $feries),
    'dates'  => array_column($feries, 'date'),
    'feries' => $feries,  // détail complet : id_ferie, nom_ferie, date, type (fixe/mobile)
]);