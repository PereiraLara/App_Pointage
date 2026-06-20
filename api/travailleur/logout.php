<?php

// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type GET
//header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Methods: POST');

include_once '../../config/Database.php';
include_once '../../lib/any_table_empty.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $db = new Database();
    $conn = $db->connect();

    $data = json_decode(file_get_contents("php://input"));  // ← add this

    if (isset($data->id_travailleur)) {
        $stmt = $conn->prepare("UPDATE travailleur SET session_token = NULL WHERE id_travailleur = ?");
        $stmt->execute([$data->id_travailleur]);
    }

    setcookie('session_token', '', [
        'expires'  => time() - 3600,
        'path'     => '/',
        'httponly' => true,
        'samesite' => 'Strict',
    ]);

    echo json_encode(['message' => 'Déconnecté']);
}
