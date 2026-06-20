<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');

include_once '../../../config/Database.php';
include_once '../../../lib/any_table_empty.php';
include_once '../../../lib/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['message' => 'Méthode non autorisée']);
    exit;
}

$db = new Database();
$conn = $db->connect();

$user = requirePrivilege($conn, ['admin']);

$data = json_decode(file_get_contents("php://input"));

// Valeurs autorisées (doivent correspondre aux ENUM de la table type_contrat)
$typesAutorises = [
    'mi-temps', '1/3 temps', '2/3 temps', '1/4 temps', '3/4 temps',
    '1/5 temps', '2/5 temps', '3/5 temps', '4/5 temps',
    '3/10 temps', '7/10 temps', '9/10 temps', 'temps plein'
];
$heuresAutorisees = ['7.6', '8'];

// Présence des champs obligatoires
if (!isset($data->id_travailleur) || !isset($data->type_contrat)
    || !isset($data->heures_journee_travail) || !isset($data->date_debut)) {
    echo json_encode(['message' => 'Données invalides ou manquantes']);
    exit;
}

// Le travailleur doit exister
$stmt = $conn->prepare('SELECT COUNT(*) FROM travailleur WHERE id_travailleur = ?');
$stmt->execute([$data->id_travailleur]);
if ($stmt->fetchColumn() == 0) {
    echo json_encode(['message' => 'Travailleur introuvable']);
    exit;
}

// type_contrat doit être une valeur autorisée
if (!in_array($data->type_contrat, $typesAutorises, true)) {
    echo json_encode(['message' => 'Type de contrat invalide']);
    exit;
}

// heures_journee_travail doit être 7.6 ou 8
if (!in_array((string)$data->heures_journee_travail, $heuresAutorisees, true)) {
    echo json_encode(['message' => 'Heures par jour invalides (7.6 ou 8 attendu)']);
    exit;
}

// date_debut doit être une date valide
$d = DateTime::createFromFormat('Y-m-d', $data->date_debut);
if (!$d || $d->format('Y-m-d') !== $data->date_debut) {
    echo json_encode(['message' => 'Date de début invalide']);
    exit;
}

// date_fin doit être valide et >= date_debut
$date_fin = (isset($data->date_fin) && $data->date_fin) ? $data->date_fin : null;
if ($date_fin !== null) {
    $f = DateTime::createFromFormat('Y-m-d', $date_fin);
    if (!$f || $f->format('Y-m-d') !== $date_fin) {
        echo json_encode(['message' => 'Date de fin invalide']);
        exit;
    }
    if ($date_fin < $data->date_debut) {
        echo json_encode(['message' => 'La date de fin doit être postérieure ou égale à la date de début']);
        exit;
    }
}

// Un seul contrat actif (date_fin IS NULL) par travailleur
$stmt = $conn->prepare('SELECT COUNT(*) FROM type_contrat 
                                WHERE id_travailleur = ? AND date_fin IS NULL');
$stmt->execute([$data->id_travailleur]);
if ($stmt->fetchColumn() > 0) {
    echo json_encode(['message' => 'Ce travailleur a déjà un contrat actif. Veuillez le clôturer avant d\'en ajouter un nouveau.']);
    exit;
}

$contratDB = new AnyTable($conn, "type_contrat");
$contratDB->fields = [
    'id_travailleur' => $data->id_travailleur,
    'type_contrat' => $data->type_contrat,
    'heures_journee_travail' => (string)$data->heures_journee_travail,
    'date_debut' => $data->date_debut,
    'date_fin' => $date_fin
];

if ($contratDB->postData()) {
    echo json_encode(['message' => 'Contrat ajouté avec succès']);
} else {
    echo json_encode(['message' => 'Erreur lors de l\'ajout']);
}
?>