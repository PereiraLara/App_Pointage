<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET');

include_once '../../../config/Database.php';
include_once '../../../lib/any_table_empty.php';
include_once '../../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(['message' => 'Méthode incorrecte']);
    exit;
}

$db   = new Database();
$conn = $db->connect();

$user = requirePrivilege($conn, ['admin', 'contremaitre/manager', 'chef_equipe']);

$res = $conn->query('SELECT * FROM feries_mobiles 
                                ORDER BY decalage_jours ASC
                    ');

if ($res->rowCount() > 0) {
    $rows = [];
    while ($row = $res->fetch(PDO::FETCH_ASSOC)) {
        $rows[] = [
            'id_ferie'       => $row['id_ferie'],
            'nom_ferie'      => $row['nom_ferie'],
            'decalage_jours' => (int) $row['decalage_jours'],
            'date_debut'     => $row['date_debut'],
            'date_fin'       => $row['date_fin'],
            'legal'          => (int) $row['legal'],
        ];
    }
    echo json_encode($rows);
} else {
    echo json_encode([]);
}
?>