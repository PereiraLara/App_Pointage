<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type GET
header('Access-Control-Allow-Methods: GET, POST');

include_once '../../config/Database.php';

    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        echo json_encode(['message' => 'Error: incorrect Method!']);
        exit;
    }

    $id_travailleur = isset($_GET['id_travailleur']) ? (int)$_GET['id_travailleur'] : null;
    $annee          = isset($_GET['annee']) ? (int)$_GET['annee'] : (int)date('Y');

    if (!$id_travailleur) {
        echo json_encode(['message' => 'No records found!']);
        exit;
    }
    $db   = new Database();
    $conn = $db->connect();

    // Check if row exists
    $stmt = $conn->prepare("SELECT * FROM heures
                                WHERE id_travailleur = ?
                                    AND annee = ?");
    $stmt->execute([$id_travailleur, $annee]);

    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
?>
