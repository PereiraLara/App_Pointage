<?php
function getConnectedUser(PDO $conn): ?array {
    $token = $_COOKIE['session_token'] ?? null;
    if (!$token) return null;

    $stmt = $conn->prepare("SELECT * FROM travailleur WHERE session_token = ?");
    $stmt->execute([$token]);
    return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}
function requireAuth(PDO $conn): array {
    return requirePrivilege($conn, [
        'travailleur',
        'chef_equipe',
        'contremaitre/manager',
        'admin'
    ]);
}

function requirePrivilege(PDO $conn, array $allowed): array {
    $user = getConnectedUser($conn);
    if (!$user) {
        http_response_code(401); // Unauthorized — not logged in
        echo json_encode(['message' => 'Non connecté']);
        exit;
    }
    if (!in_array($user['privileges'], $allowed)) {
        http_response_code(403); // Forbidden — logged in but wrong role
        echo json_encode(['message' => 'Accès refusé']);
        exit;
    }
    return $user;
}