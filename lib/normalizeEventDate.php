<?php

// Normalise une date d'événement reçue en "1900-MM-DD"
function normalizeEventDate($input) {
    $parts = explode('-', trim((string) $input));

    if (count($parts) === 2) {
        [$month, $day] = $parts;
    } elseif (count($parts) === 3) {
        [, $month, $day] = $parts;
    } else {
        return null;
    }

    $month = (int) $month;
    $day = (int) $day;

    if ($month < 1 || $month > 12 || $day < 1 || $day > 31) {
        return null;
    }

    return sprintf('1900-%02d-%02d', $month, $day);
}