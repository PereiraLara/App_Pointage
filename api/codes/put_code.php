<?php
// Donner accès à toute les ressources
header('Access-Control-Allow-Origin: *');

// Indiquer au navigateur que les données reçues sont au format JSON
header('Content-Type: application/json');

// Indiquer au serveur qu'il autorise uniquement des requêtes de type PUT
header('Access-Control-Allow-Methods: PUT');

include_once '../../config/Database.php';
include_once '../../lib/any_table_empty.php';
include_once '../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    echo json_encode(['message' => 'Méthode incorrecte']);
    exit;
}

$db   = new Database();
$conn = $db->connect();

$user = requirePrivilege($conn, ['admin']);

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->id_code)) {
    echo json_encode(['message' => 'Données invalides ou manquantes']);
    exit;
}

// Récupérer la période active (date_fin IS NULL)
$stmt = $conn->prepare('SELECT nom_code, valeur, description, date_debut
                                 FROM log_evolution_code_heure
                                 WHERE id_code = ? AND date_fin IS NULL'
                            );
$stmt->execute([$data->id_code]);
$active = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$active) {
    echo json_encode(['message' => 'Aucune période active à modifier']);
    exit;
}

$nom_code    = isset($data->nom_code)    ? $data->nom_code    : $active['nom_code'];
$valeur      = isset($data->valeur)      ? $data->valeur      : $active['valeur'];
$description = isset($data->description) ? $data->description : $active['description'];

// Vérifier si nom est unique apres changement
if ($nom_code !== $active['nom_code']) {
    $stmtNom = $conn->prepare('SELECT COUNT(*) FROM log_evolution_code_heure
                                         WHERE nom_code = ? AND id_code != ?'
                             );
    $stmtNom->execute([$nom_code, $data->id_code]);
    if ($stmtNom->fetchColumn() > 0) {
        echo json_encode(['message' => 'Erreur lors de la modification - Nom de Code déjà existant']);
        exit;
    }
}

// Bornes : ancienne période clôturée hier, nouvelle débutant aujourd'hui
$today     = date('Y-m-d');
$yesterday = date('Y-m-d', strtotime($today . ' -1 day'));

// Sécurité : la période active doit avoir débuté avant aujourd'hui,
// sinon date_fin (hier) serait antérieure à date_debut.
if ($active['date_debut'] >= $today) {
    echo json_encode(['message' => 'Période trop récente pour être versionnée aujourd\'hui']);
    exit;
}

// Si rien n'a changé, pas créer une nouvelle version
if ($nom_code === $active['nom_code']
    && $valeur == $active['valeur']
    && $description === $active['description']) {
    echo json_encode(['message' => 'Aucune modification détectée']);
    exit;
}

$conn->beginTransaction();
try {
    // Clôture l'ancienne période active
    $close = $conn->prepare('UPDATE log_evolution_code_heure
                                     SET date_fin = ?
                                     WHERE id_code = ? AND date_fin IS NULL'
                            );
    $close->execute([$yesterday, $data->id_code]);

    // Créer la nouvelle période active avec les valeurs modifiées
    $insert = $conn->prepare('INSERT INTO log_evolution_code_heure
                                        (id_code, nom_code, valeur, description, date_debut, date_fin)
                                     VALUES (?, ?, ?, ?, ?, NULL)'
                            );
    $insert->execute([
        $data->id_code, $nom_code, $valeur, $description, $today
    ]);

    $conn->commit();
    echo json_encode(['message' => 'Code modifié avec succès']);
} catch (Exception $e) {
    $conn->rollBack();
    echo json_encode(['message' => 'Erreur lors de la modification']);
}
?>