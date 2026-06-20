<?php

class Database {
    private $host = "localhost";
    private $user = "root";
    private $db = "examsgbd";
    private $pwd = "";
    private $conn = NULL;

    public function connect() {

        try{
            $this->conn = new PDO("mysql:host=$this->host;dbname=$this->db", $this->user, $this->pwd);
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch(PDOException $e) {
            echo "Connection Error: " . $e->getMessage();
        }
        catch (Exception $e) {
            echo "General Error: ".$e->getMessage();
        }
        return $this->conn;
    }
}
