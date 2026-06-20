<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type GET
header('Access-Control-Allow-Methods: GET, POST');

include_once '../../config/Database.php';
include_once '../../models/travailleur.php';
include_once '../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(array('message' => "Error: incorrect Method!"));
    exit;
}

$db = new Database();
$conn = $db->connect();

$user = requirePrivilege($conn, ['admin', 'contremaitre/manager', 'chef_equipe']);

$mois = isset($_GET['mois']) ? $_GET['mois'] : null;
$annee = isset($_GET['annee']) ? $_GET['annee'] : null;

if (!$mois || !$annee) {
    echo json_encode(['message' => 'Paramètres manquants']);
    exit;
}

$travailleurDB = new travailleur($conn, "heures", "id_travailleur","", []);
$travailleurDB->mois = $mois;
$travailleurDB->annee = $annee;

$privileges = $user['privileges'];

if (in_array($privileges, ['admin', 'contremaitre/manager'])) {
    $id_connected = isset($_GET['id_travailleur']) ? $_GET['id_travailleur'] : null;
    $res = $travailleurDB->fetchHeuresForMonthAllWorkers();
} else {
    // si chef_equipe
    $travailleurDB->identValue = $user['id_travailleur'];
    $res = $travailleurDB->fetchHeuresForMonthByChefEquipe();
}

$heures = [];
while ($row = $res->fetch(PDO::FETCH_ASSOC)) {
    if (isset($id_connected) && $row['id_travailleur'] == $id_connected) continue;
    $heures[] = $row;
}

echo json_encode($heures);
?>