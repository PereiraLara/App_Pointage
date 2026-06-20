<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type GET
header('Access-Control-Allow-Methods: GET, POST');

include_once '../../../config/Database.php';
include_once '../../../lib/any_table_empty.php';
include_once '../../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(['message' => 'Error: incorrect Method!']);
    exit;
}

$db = new Database();
$conn = $db->connect();

$user = requirePrivilege($conn, ['admin', 'contremaitre/manager', 'chef_equipe']);

if (!isset($_GET['id_equipe'])) {
    echo json_encode(['message' => 'Données invalides ou manquantes (id_equipe requis)']);
    exit;
}

$id_equipe = $_GET['id_equipe'];

$stmt = $conn->prepare('SELECT te.id_travailleur, t.nom, te.role FROM travailleur_equipe te
                                JOIN travailleur t ON t.id_travailleur = te.id_travailleur
                                 WHERE te.id_equipe = ?
                                   AND (te.date_fin IS NULL OR te.date_fin > CURDATE())
                                   order by te.role ASC');
$stmt->bindParam(1, $id_equipe);
$stmt->execute();

echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));