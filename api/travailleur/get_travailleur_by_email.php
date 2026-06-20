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

//if ($_SERVER['REQUEST_METHOD'] === 'GET') {
if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $db = new Database();
    $conn = $db->connect();

    $travailleurDB = new AnyTable($conn, "travailleur", "email","",
        [
            'id_travailleur' => '',
            'privileges' => '',
            'nom' => '',
            'no_registre_national' => '',
            'email' => '',
            'password' => ''
        ]);

    $data = json_decode(file_get_contents("php://input"));

    if (isset($data->email) && isset($data->password)) {
        $travailleurDB->identValue = $data->email;

        if ($travailleurDB->fetchOne()) {
            if (password_verify($data->password, $travailleurDB->fields['password'])) {

                $token = bin2hex(random_bytes(32));

                $stmt = $conn->prepare("UPDATE travailleur SET session_token = ? WHERE id_travailleur = ?");
                $stmt->execute([$token, $travailleurDB->fields['id_travailleur']]);

                setcookie('session_token', $token, [
                    'httponly' => true,
                    'samesite' => 'Strict',
                    'path'     => '/'
                ]);

                unset($travailleurDB->fields['password']);
                echo json_encode($travailleurDB->fields);

            } else {
                echo json_encode(['message' => 'email et/ou mot de passe invalide']);
            }
        } else {
            echo json_encode(['message' => 'email et/ou mot de passe invalide']);
        }

    } else {
        echo json_encode(['message' => 'email ou mot de passe non renseignés']);
    }
}
?>
