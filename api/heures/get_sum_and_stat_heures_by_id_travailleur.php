<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET');

include_once '../../config/Database.php';
include_once '../../lib/jours_feries.php';

const FRACTIONS_CONTRAT = [
    'temps plein' => 1,
    'mi-temps'    => 1/2,
    '1/3 temps'   => 1/3,
    '2/3 temps'   => 2/3,
    '1/4 temps'   => 1/4,
    '3/4 temps'   => 3/4,
    '1/5 temps'   => 1/5,
    '2/5 temps'   => 2/5,
    '3/5 temps'   => 3/5,
    '4/5 temps'   => 4/5,
    '3/10 temps'  => 3/10,
    '7/10 temps'  => 7/10,
    '9/10 temps'  => 9/10,
];


const CODES = [
    'P'   => ['heures' => true,  'categorie' => 'travail'],        // Prestation
    'C'   => ['heures' => true,  'categorie' => 'conge'],          // Congés payés
    'CC'  => ['heures' => true,  'categorie' => 'conge'],          // Congés de circonstance
    'CS'  => ['heures' => false, 'categorie' => 'conge'],          // Congé sans solde
    'M'   => ['heures' => true,  'categorie' => 'maladie'],        // Maladie courte
    'MLD' => ['heures' => true,  'categorie' => 'maladie'],        // Maladie longue durée
    'CE'  => ['heures' => false, 'categorie' => 'chomage'],        // Chômage économique
    'CI'  => ['heures' => false, 'categorie' => 'chomage'],        // Chômage intempérie
    'AT'  => ['heures' => true,  'categorie' => 'accident'],       // Accident travail
    'R'   => ['heures' => false, 'categorie' => 'recuperation'],   // Récupération
    'A'   => ['heures' => false, 'categorie' => 'absence'],        // Absence non justifiée
];

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(['message' => 'Error: incorrect Method!']);
    exit;
}

$id_travailleur = isset($_GET['id_travailleur']) ? (int)$_GET['id_travailleur'] : null;
$annee = isset($_GET['annee']) ? (int)$_GET['annee'] : (int)date('Y');

if (!$id_travailleur) {
    echo json_encode(['message' => 'No records found!']);
    exit;
}

$db   = new Database();
$conn = $db->connect();

$stmt = $conn->prepare("SELECT h.*, c.heures_journee_travail, c.type_contrat FROM heures h
                            JOIN type_contrat c
                                ON c.id_travailleur = h.id_travailleur
                               AND c.date_debut <= LAST_DAY(DATE(CONCAT(h.annee, '-', h.mois, '-01')))
                               AND (c.date_fin IS NULL OR c.date_fin >= DATE(CONCAT(h.annee, '-', h.mois, '-01')))
                               AND c.date_debut = (
                                   SELECT MAX(c2.date_debut) FROM type_contrat c2
                                   WHERE c2.id_travailleur = h.id_travailleur
                                     AND c2.date_debut <= LAST_DAY(DATE(CONCAT(h.annee, '-', h.mois, '-01')))
                                     AND (c2.date_fin IS NULL OR c2.date_fin >= DATE(CONCAT(h.annee, '-', h.mois, '-01')))
                               )
                            WHERE h.id_travailleur = ?
                              AND h.annee = ?
                            ORDER BY h.mois asc");

$stmt->execute([$id_travailleur, $annee]);

$prestations = [];

while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    $mois = (int)$row['mois'];
    $annee_row = (int)$row['annee'];

    $heures_jour_base = (float)$row['heures_journee_travail'];
    $fraction = FRACTIONS_CONTRAT[$row['type_contrat']] ?? 1;
    $heures_jour_contrat = round($heures_jour_base * $fraction, 4);

    // Count jours ouvres (Mon–Fri) sauf feries
    $jours_mois = cal_days_in_month(CAL_GREGORIAN, $row['mois'], $row['annee']);
    $jours_ouvres = 0;

    for ($d = 1; $d <= $jours_mois; $d++) {
        if (date('N', mktime(0, 0, 0, $row['mois'], $d, $row['annee'])) < 6) $jours_ouvres++;
    }

    $feries = getJoursFeriesOuvres($conn, $mois, $annee_row);
    $nb_feries = count($feries);
    $jours_ouvres -= $nb_feries;

    // Counters per category
    $total_travaillees = 0;
    $jours_prestes     = 0;   // P only
    $jours_conge       = 0;   // C + CC + CS
    $jours_maladie     = 0;   // M + MLD
    $jours_chomage     = 0;   // CE + CI
    $jours_accident    = 0;   // AT
    $jours_recuperation= 0;   // R
    $jours_absence     = 0;   // A
    $heures_numeriques = 0;
    $autre = 0;

    for ($d = 1; $d <= 31; $d++) {
        $val = isset($row[$d]) ? strtoupper(trim($row[$d])) : null;
        if ($val === null || $val === '') continue;

        if (is_numeric($val)) {
            $heures_numeriques += (float)$val;
            $total_travaillees += (float)$val;
            $jours_prestes++;
            continue;
        }

        $code = CODES[$val] ?? null;
        if (!$code) {
            $autre++;
            continue;
        }

        if ($code['heures']) {
            $total_travaillees += $heures_jour_contrat;
        }

        switch ($code['categorie']) {
            case 'travail': $jours_prestes++; break;
            case 'conge': $jours_conge++; break;
            case 'maladie': $jours_maladie++; break;
            case 'chomage': $jours_chomage++; break;
            case 'accident': $jours_accident++; break;
            case 'recuperation': $jours_recuperation++; break;
            case 'absence': $jours_absence++; break;
        }
    }

    $total_dues = round($jours_ouvres * $heures_jour_contrat, 2);

    $prestations[] = [
        'mois'               => (int)$row['mois'],
        'annee'              => (int)$row['annee'],
        'type_contrat'       => $row['type_contrat'],
        'heures_jour_contrat'=> $heures_jour_contrat,
        'jours_ouvres'       => $jours_ouvres,
        //feries
        'jours_feries'        => $nb_feries,
        'dates_feries'        => $feries,
        // hours
        'total_dues'         => $total_dues,
        'total_travaillees'  => round($total_travaillees, 2),
        'heures_numeriques'  => round($heures_numeriques, 2),
        'difference'         => round($total_travaillees - $total_dues, 2),
        // day counters per category
        'jours_prestes'      => $jours_prestes,
        'jours_conge'        => $jours_conge,
        'jours_maladie'      => $jours_maladie,
        'jours_chomage'      => $jours_chomage,
        'jours_accident'     => $jours_accident,
        'jours_recuperation' => $jours_recuperation,
        'jours_absence'      => $jours_absence,
        //added codes
        'autre'             => $autre,
    ];
}

echo json_encode($prestations);
?>