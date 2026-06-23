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

/*
 * Modèle (log_evolution_code_heure) : PK = (id_code, date_debut), journal
 * append-only. Une période est "désactivée" uniquement si date_fin < aujourd'hui ;
 * une date_fin NULL ou >= aujourd'hui est encore en vigueur.
 *
 * La période ciblée est celle EN VIGUEUR à la date choisie :
 *   date choisie = date_debut saisie si fournie, sinon aujourd'hui.
 *   -> WHERE date_debut <= dateChoisie AND (date_fin IS NULL OR date_fin >= dateChoisie)
 *
 * Si la date saisie est >= max(date_fin) du code (après la dernière période),
 * aucune période ne la couvre : on insère simplement, sans clôture ni erreur.
 *
 * Règles de modification de la période ciblée :
 *  - nom_code, valeur OU date_debut changent -> nouvelle période
 *    (clôture de la période ciblée si elle est ouverte/en cours + insertion).
 *  - date_fin seule renseignée -> clôture (date_fin >= max(aujourd'hui, date_debut)).
 *  - sinon (description seule, ou rien) -> simple UPDATE en place.
 */

$dateRegex = '/^\d{4}-\d{2}-\d{2}$/';
$today     = date('Y-m-d');

// Date choisie : date_debut saisie si valide, sinon aujourd'hui
if (isset($data->date_debut) && preg_match($dateRegex, $data->date_debut)) {
    $dateChoisie    = $data->date_debut;
    $dateDebutInput = true;
} else {
    $dateChoisie    = $today;
    $dateDebutInput = false;
}

// max(date_fin) du code : si la date choisie est au-delà, on insère sans clôture.
// (Si une période est encore ouverte, date_fin NULL -> pas de borne "après la fin".)
$stmtMax = $conn->prepare('SELECT COUNT(*) AS nb,
                                  MAX(CASE WHEN date_fin IS NULL THEN 1 ELSE 0 END) AS a_ouverte,
                                  MAX(date_fin) AS max_fin
                           FROM log_evolution_code_heure
                           WHERE id_code = ?');
$stmtMax->execute([$data->id_code]);
$agg = $stmtMax->fetch(PDO::FETCH_ASSOC);

if (!$agg || (int)$agg['nb'] === 0) {
    echo json_encode(['message' => 'Code non trouvé']);
    exit;
}

// Récupérer la période en vigueur à la date choisie
$stmt = $conn->prepare('SELECT id_code, nom_code, valeur, description, date_debut, date_fin
                        FROM log_evolution_code_heure
                        WHERE id_code = ?
                          AND date_debut <= ?
                          AND (date_fin IS NULL OR date_fin >= ?)
                        ORDER BY date_debut DESC
                        LIMIT 1');
$stmt->execute([$data->id_code, $dateChoisie, $dateChoisie]);
$active = $stmt->fetch(PDO::FETCH_ASSOC);

/* =======================================================================
 * CAS 0 — Aucune période ne couvre la date choisie (date >= dernière fin)
 *          -> insertion simple, sans clôture ni erreur.
 * ===================================================================== */
if (!$active) {
    // Valeurs : si fournies on les prend, sinon on hérite de la dernière période
    $stmtLast = $conn->prepare('SELECT nom_code, valeur, description
                                FROM log_evolution_code_heure
                                WHERE id_code = ?
                                ORDER BY date_debut DESC
                                LIMIT 1');
    $stmtLast->execute([$data->id_code]);
    $last = $stmtLast->fetch(PDO::FETCH_ASSOC);

    $nom_code    = isset($data->nom_code)    ? $data->nom_code    : $last['nom_code'];
    $valeur      = isset($data->valeur)      ? $data->valeur      : $last['valeur'];
    $description = isset($data->description) ? $data->description : $last['description'];

    // Collision de PK ?
    $coll = $conn->prepare('SELECT COUNT(*) FROM log_evolution_code_heure
                            WHERE id_code = ? AND date_debut = ?');
    $coll->execute([$data->id_code, $dateChoisie]);
    if ($coll->fetchColumn() > 0) {
        echo json_encode(['message' => 'Une période débutant à cette date existe déjà pour ce code']);
        exit;
    }

    // date_fin éventuelle
    $df = null;
    if (property_exists($data, 'date_fin') && $data->date_fin !== null && $data->date_fin !== '') {
        if (!preg_match($dateRegex, $data->date_fin)) {
            echo json_encode(['message' => 'Format de date_fin invalide']);
            exit;
        }
        $df = $data->date_fin;
        if ($df < $dateChoisie) {
            echo json_encode(['message' => 'La date de fin doit être postérieure ou égale à la date de début']);
            exit;
        }
    }

    $ins = $conn->prepare('INSERT INTO log_evolution_code_heure
                                (id_code, nom_code, valeur, description, date_debut, date_fin)
                           VALUES (?, ?, ?, ?, ?, ?)');
    $ins->execute([$data->id_code, $nom_code, $valeur, $description, $dateChoisie, $df]);

    echo json_encode(['message' => 'Code modifié avec succès (nouvelle période)']);
    exit;
}

// La période ciblée est-elle encore en cours (date_fin NULL ou >= aujourd'hui) ?
$periodeEnCours = ($active['date_fin'] === null || $active['date_fin'] >= $today);

// Valeurs cibles (on garde l'existant si non fourni)
$nom_code    = isset($data->nom_code)    ? $data->nom_code    : $active['nom_code'];
$valeur      = isset($data->valeur)      ? $data->valeur      : $active['valeur'];
$description = isset($data->description) ? $data->description : $active['description'];

// date_fin saisie : null autorisé
$date_fin_fournie = false;
$date_fin_saisie  = $active['date_fin'];
if (property_exists($data, 'date_fin')) {
    $date_fin_fournie = true;
    if ($data->date_fin === null || $data->date_fin === '') {
        $date_fin_saisie = null;
    } elseif (preg_match($dateRegex, $data->date_fin)) {
        $date_fin_saisie = $data->date_fin;
    } else {
        echo json_encode(['message' => 'Format de date_fin invalide']);
        exit;
    }
}

// Détection des changements
$nomChange       = ($nom_code !== $active['nom_code']);
$valeurChange    = ((float)$valeur !== (float)$active['valeur']);
$dateDebutChange = ($dateDebutInput && $dateChoisie !== $active['date_debut']);
$dateFinChange   = ($date_fin_fournie && $date_fin_saisie !== $active['date_fin']);

// Unicité du nom (hors lignes du même id_code)
if ($nomChange) {
    $stmtNom = $conn->prepare('SELECT COUNT(*) FROM log_evolution_code_heure
                                         WHERE nom_code = ? AND id_code != ?');
    $stmtNom->execute([$nom_code, $data->id_code]);
    if ($stmtNom->fetchColumn() > 0) {
        echo json_encode(['message' => 'Erreur lors de la modification - Nom de Code déjà existant']);
        exit;
    }
}

/* =======================================================================
 * CAS 1 — Changement significatif : nom, valeur ou date_debut
 *          -> clôture de la période ciblée (si en cours) + insertion.
 * ===================================================================== */
if ($nomChange || $valeurChange || $dateDebutChange) {

    // date_debut de la nouvelle période
    if ($dateDebutChange && $dateChoisie > $active['date_debut']) {
        $new_debut = $dateChoisie;
    } else {
        $lendemain = date('Y-m-d', strtotime($active['date_debut'] . ' +1 day'));
        $new_debut = ($today > $lendemain) ? $today : $lendemain;
    }

    if ($new_debut <= $active['date_debut']) {
        echo json_encode([
            'message' => 'La date de début doit être postérieure au début de la période courante (' . $active['date_debut'] . ')'
        ]);
        exit;
    }

    // Pas de collision de PK
    $collision = $conn->prepare('SELECT COUNT(*) FROM log_evolution_code_heure
                                          WHERE id_code = ? AND date_debut = ?');
    $collision->execute([$data->id_code, $new_debut]);
    if ($collision->fetchColumn() > 0) {
        echo json_encode(['message' => 'Une période débutant à cette date existe déjà pour ce code']);
        exit;
    }

    $date_cloture = date('Y-m-d', strtotime($new_debut . ' -1 day'));

    try {
        $conn->beginTransaction();

        // Clôturer la période ciblée seulement si elle est encore ouverte
        // (date_fin NULL) ou se prolonge au-delà de la nouvelle date de début.
        if ($active['date_fin'] === null || $active['date_fin'] >= $new_debut) {
            $close = $conn->prepare(
                'UPDATE log_evolution_code_heure
                 SET date_fin = ?
                 WHERE id_code = ? AND date_debut = ?'
            );
            $close->execute([$date_cloture, $active['id_code'], $active['date_debut']]);

            if ($close->rowCount() === 0) {
                $conn->rollBack();
                echo json_encode(['message' => 'Erreur lors de la clôture de la période courante']);
                exit;
            }
        }

        // Nouvelle période avec les valeurs modifiées
        $insert = $conn->prepare('INSERT INTO log_evolution_code_heure
                                            (id_code, nom_code, valeur, description, date_debut, date_fin)
                                         VALUES (?, ?, ?, ?, ?, NULL)');
        $insert->execute([$data->id_code, $nom_code, $valeur, $description, $new_debut]);

        $conn->commit();
        echo json_encode(['message' => 'Code modifié avec succès (nouvelle période)']);
    } catch (Exception $e) {
        if ($conn->inTransaction()) {
            $conn->rollBack();
        }
        echo json_encode(['message' => 'Erreur lors de la modification']);
    }
    exit;
}

/* =======================================================================
 * CAS 2 — Clôture de la période (date_fin renseignée, > NULL)
 *          date de clôture >= max(aujourd'hui, date_debut)
 * ===================================================================== */
if ($dateFinChange && $date_fin_saisie !== null) {

    $borne = ($today > $active['date_debut']) ? $today : $active['date_debut'];

    if ($date_fin_saisie < $borne) {
        echo json_encode([
            'message' => 'La date de fin doit être postérieure ou égale au ' . $borne
        ]);
        exit;
    }

    $cloturer = $conn->prepare(
        'UPDATE log_evolution_code_heure
         SET description = ?, date_fin = ?
         WHERE id_code = ? AND date_debut = ?'
    );
    $cloturer->execute([$description, $date_fin_saisie, $active['id_code'], $active['date_debut']]);

    echo json_encode([
        'message' => 'Code clôturé avec succès',
        'id_code' => $active['id_code']
    ]);
    exit;
}

/* =======================================================================
 * CAS 3 — Pas de changement significatif : simple UPDATE en place
 * ===================================================================== */
$update = $conn->prepare(
    'UPDATE log_evolution_code_heure
     SET nom_code = ?, valeur = ?, description = ?, date_fin = ?
     WHERE id_code = ? AND date_debut = ?'
);
$update->execute([
    $nom_code,
    $valeur,
    $description,
    $date_fin_saisie,
    $active['id_code'],
    $active['date_debut']
]);

echo json_encode([
    'message' => 'Code modifié avec succès',
    'id_code' => $active['id_code']
]);
?>