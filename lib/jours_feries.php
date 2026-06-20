<?php
// Noms des 3 jours fériés mobiles dérivés de Pâques (cf. calculer_et_inserer_paques)
const NOMS_FERIES_MOBILES = [
    1 => 'Lundi de Pâques',
    2 => 'Ascension',
    3 => 'Lundi de Pentecôte',
];

function getJoursFeriesComplets(PDO $conn, int $mois, int $annee): array
{
    $feries = [];
    $firstOfMonth = "$annee-" . str_pad($mois, 2, '0', STR_PAD_LEFT) . "-01";

    // Jours fériés fixes (récurrents chaque année, actifs sur la période demandée)
    $stmt = $conn->prepare("SELECT id_ferie, nom_ferie, MONTH(event_date) AS m, DAY(event_date) AS d
                             FROM jours_feries_fixes
                             WHERE MONTH(event_date) = ?
                               AND date_debut <= ?
                               AND (date_fin IS NULL OR date_fin >= ?)");
    $stmt->execute([$mois, $firstOfMonth, $firstOfMonth]);

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $date = sprintf('%04d-%02d-%02d', $annee, $row['m'], $row['d']);
        $dow  = (int)date('N', strtotime($date)); // 1=Lun … 7=Dim

        if ($dow < 6) { // jour ouvré uniquement (on ignore les samedis/dimanches)
            $feries[] = [
                'id_ferie'  => (int)$row['id_ferie'],
                'nom_ferie' => $row['nom_ferie'],
                'date'      => $date,
                'type'      => 'fixe',
            ];
        }
    }

    // Jours fériés mobiles (dérivés de Pâques, déjà calculés par année)
    $stmt = $conn->prepare("SELECT id_ferie, date_ferie FROM jours_feries_mobiles
                             WHERE annee = ? AND MONTH(date_ferie) = ?");
    $stmt->execute([$annee, $mois]);

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $date = $row['date_ferie'];
        $dow  = (int)date('N', strtotime($date));

        if ($dow < 6) {
            $feries[] = [
                'id_ferie'  => 'mobile_' . $row['id_ferie'],
                'nom_ferie' => NOMS_FERIES_MOBILES[(int)$row['id_ferie']] ?? 'Jour férié mobile',
                'date'      => $date,
                'type'      => 'mobile',
            ];
        }
    }

    // Tri chronologique
    usort($feries, fn($a, $b) => strcmp($a['date'], $b['date']));

    // Dédoublonnage par date (au cas où un fixe et un mobile tombent le même jour)
    $vues = [];
    return array_values(array_filter($feries, function ($f) use (&$vues) {
        if (in_array($f['date'], $vues, true)) return false;
        $vues[] = $f['date'];
        return true;
    }));
}


function getJoursFeriesOuvres(PDO $conn, int $mois, int $annee): array
{
    return array_column(getJoursFeriesComplets($conn, $mois, $annee), 'date');
}