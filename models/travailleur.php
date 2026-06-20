<?php
require_once __DIR__ . '/../lib/any_table_empty.php';

class travailleur extends AnyTable
{
    public function fetchTravailleurParChefEquipe()
    {
        $jour = (int)$this->jour;   //bindparam peut pas etre utilise pour directement nom de colonne ou table

        $stmt = $this->conn->prepare('SELECT DISTINCT t.id_travailleur, t.nom, t.no_registre_national, t.email, h.`'.$jour.'` as jour FROM travailleur t
                                            JOIN travailleur_equipe te
                                                ON t.id_travailleur = te.id_travailleur
                                            JOIN equipe e
                                                ON te.id_equipe = e.id_equipe
                                        left join heures h on t.id_travailleur = h.id_travailleur
                                        	AND h.mois = ?
                                            and h.annee = ?
                                            WHERE e.chef_de_equipe = ? 
                                                AND (te.date_fin IS NULL 
                                                    OR te.date_fin >= CURDATE())
                                                AND t.id_travailleur <> e.chef_de_equipe
                                            order by t.id_travailleur ASC');

        $stmt->bindParam(1, $this->mois);
        $stmt->bindParam(2, $this->annee);
        $stmt->bindParam(3, $this->identValue);
        $stmt->execute();

        return $stmt;
    }

    public function fetchHeuresForMonthAllWorkers()
    {
        $stmt = $this->conn->prepare('SELECT h.* FROM heures h
                                        INNER JOIN travailleur t ON t.id_travailleur = h.id_travailleur
                                        WHERE h.mois = ?
                                          AND h.annee = ?
                                        ORDER BY t.nom');
        $stmt->bindParam(1, $this->mois);
        $stmt->bindParam(2, $this->annee);
        $stmt->execute();
        return $stmt;
    }

    public function fetchHeuresForTravailleur()
    {
        $stmt = $this->conn->prepare('select * from heures where id_travailleur = ?');

        $stmt->bindParam(1, $this->identValue);
        $stmt->execute();
        return $stmt;
    }

    public function fetchHeuresForMonthByChefEquipe()
    {
        $stmt = $this->conn->prepare('SELECT h.* FROM heures h
                                        INNER JOIN travailleur t 
                                            ON t.id_travailleur = h.id_travailleur
                                        INNER JOIN travailleur_equipe te 
                                            ON t.id_travailleur = te.id_travailleur
                                        INNER JOIN equipe e 
                                            ON te.id_equipe = e.id_equipe
                                        
                                        WHERE e.chef_de_equipe = ?
                                          AND (te.date_fin IS NULL OR te.date_fin >= CURDATE())
                                          AND t.id_travailleur <> e.chef_de_equipe
                                          AND h.mois = ?
                                          AND h.annee = ?
                                        ORDER BY t.nom');
        $stmt->bindParam(1, $this->identValue);
        $stmt->bindParam(2, $this->mois);
        $stmt->bindParam(3, $this->annee);
        $stmt->execute();
        return $stmt;
    }

    public function fetchHeuresForMonthSortByTravailleur()
    {
        $stmt = $this->conn->prepare('SELECT h.* FROM heures h
                                            INNER JOIN travailleur t 
                                                ON t.id_travailleur = h.id_travailleur
                                            LEFT JOIN travailleur_equipe te
                                                ON t.id_travailleur = te.id_travailleur
                                            INNER JOIN equipe e
                                                ON te.id_equipe = e.id_equipe
           
                                            WHERE t.id_travailleur = ?
                                                AND (
                                                    te.date_fin IS NULL
                                                    OR te.date_fin >= CURDATE()
                                                )
                                                AND h.mois = ?
                                                AND h.annee = ?
                                            ORDER BY t.nom;');

        $stmt->bindParam(1, $this->identValue);
        $stmt->bindParam(2, $this->mois);
        $stmt->bindParam(3, $this->annee);
        $stmt->execute();
        return $stmt;
    }
}