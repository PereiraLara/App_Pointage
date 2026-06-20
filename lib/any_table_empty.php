<?php

class AnyTable {

    protected $conn;
    
    public $table = ''; //cest un attribut
    public $identName = '';
    public $identValue = '';
    public $jour = '';
    public $mois = '';
    public $annee = '';
    public $fields = [];

   	/* 	
	  	Constructeur
	    ------------
		$db : bases de données -> string
		$table : table -> string
        $identName : nom de la clé primaire (optionnel : uniquement utilisable pour fetchOne put et delete)
		$identValue : valeur de la clé primaire (optionnel : uniquement utilisable avec fectOne put et delete)
        $fields : noms des champs de la table -> array associatif (optionnel uniquement utilisable avec postData et putData)
	
    */
	
    public function __construct($db, $table = '', $identName = '', $identValue = '', $fields = [])
        {
            $this->conn = $db;
            $this->table = $table;
            $this->identName = $identName;
            $this->identValue = $identValue;
            $this->fields = $fields;
        }

    
    //Récupérer tout les enregistrement d'une table
    public function fetchAll() 
        {
            $stmt = $this->conn->prepare('SELECT * FROM '.$this->table);
            $stmt->execute();
            return $stmt;
        }

    //Récupérer 1 entregistrement d'une table selon un id donné
    public function fetchOne() 
        {
            $stmt = $this->conn->prepare('SELECT * FROM '.$this->table.' WHERE '.$this->identName.' = ?');
            $stmt->bindParam(1, $this->identValue);
            $stmt->execute();

             if($stmt->rowCount() > 0)
             {
                $row = $stmt->fetch(PDO::FETCH_ASSOC);
                foreach ($this->fields as $k => $v)
                {
                    $this->fields[$k] = $row[$k];
                }
                 return true;
             }
            else return false;
        }

    //Ajouter un enregistrement
    public function postData() 
        {
            $stmt = $this->conn->prepare('INSERT INTO '.$this->table.' ('.implode(', ', array_keys($this->fields)).') 
                                        values ('.implode(', ', array_fill(0, count($this->fields), '?')).')');

            return $stmt->execute(array_values($this->fields));
        }

    public function putData() 
        {
            $setClause = [];

            foreach ($this->fields as $column => $value) {
                $setClause[] = "$column = ?";
            }

            $setClause = implode(', ', $setClause);

            $sql = "UPDATE {$this->table}
            SET $setClause
            WHERE {$this->identName} = ?";

            $stmt = $this->conn->prepare($sql);

            $values = array_values($this->fields);
            $values[] = $this->identValue;

            $stmt->execute($values);

            return $stmt->rowCount() > 0;
        }

    public function delete() 
        {
            $stmt = $this->conn->prepare('DELETE FROM '.$this->table.' WHERE '.$this->identName.' = ?');

            $stmt->bindParam(1, $this->identValue);
            $stmt->execute();

            if($stmt->rowCount() > 0)
            {
                return true;
            }
            return false;
        }
}


?>
