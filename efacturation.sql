CREATE DATABASE IF NOT EXISTS efacturation;
USE efacturation;

-- Suppression des tables enfants (clés étrangères) puis parents pour éviter les conflits d'intégrité
DROP TABLE IF EXISTS paiements;
DROP TABLE IF EXISTS factures;
DROP TABLE IF EXISTS plans_abonnement;
DROP TABLE IF EXISTS entreprises;

-- Table des clients B2B
CREATE TABLE entreprises (
    id_entreprise INT AUTO_INCREMENT PRIMARY KEY,
    nom_entreprise VARCHAR(100) NOT NULL,
    siret CHAR(14) UNIQUE, -- Format strict à 14 caractères pour l'identification légale en France
    pays VARCHAR(50),
    date_inscription DATE
);

-- Catalogue des offres et de leur tarification fixe
CREATE TABLE plans_abonnement (
    id_plan INT AUTO_INCREMENT PRIMARY KEY,
    nom_plan VARCHAR(100) NOT NULL,
    prix_mensuel DECIMAL(10,2) NOT NULL -- DECIMAL garantit l'absence d'arrondis flottants sur les montants
);

-- Registre des factures mensuelles émises
CREATE TABLE factures (
    id_facture INT AUTO_INCREMENT PRIMARY KEY,
    id_entreprise INT, 
    id_plan INT,       
    date_emission DATE,
    date_echeance DATE,
    -- Le CHECK restreint les valeurs pour assurer la cohérence du cycle de facturation
    statut VARCHAR(50) CHECK (statut IN ('Payée', 'En attente', 'En retard')), 
    FOREIGN KEY(id_entreprise) REFERENCES entreprises(id_entreprise),
    FOREIGN KEY(id_plan) REFERENCES plans_abonnement(id_plan)
);

-- Historique des transactions financières associées aux factures
CREATE TABLE paiements (
    id_paiements INT AUTO_INCREMENT PRIMARY KEY,
    id_facture INT, 
    montant_paye DECIMAL(10,2),
    date_payement DATE,
    -- Limitation stricte des modes de règlement acceptés par la plateforme
    methode_payement VARCHAR(50) CHECK (methode_payement IN ('Virement', 'Carte', 'Prélèvement')), 
    FOREIGN KEY(id_facture) REFERENCES factures(id_facture)
);


-- ============================================================================
-- INSERTIONS DANS LA TABLE : plans_abonnement
-- ============================================================================
INSERT INTO plans_abonnement (nom_plan, prix_mensuel) VALUES 
('Standard', 49.00),
('Premium', 149.00),
('Entreprise', 499.00);

-- ============================================================================
-- INSERTIONS DANS LA TABLE : entreprises
-- ============================================================================
INSERT INTO entreprises (nom_entreprise, siret, pays, date_inscription) VALUES 
('TechSolutions France', '12345678901234', 'France', '2025-01-15'),
('Alpha Digital', '98765432100012', 'France', '2025-02-10'),
('Global Logistics Corp', '55566677700099', 'Belgique', '2025-03-01'),
('DataCraft Studio', '44433322200055', 'France', '2025-04-20'),
('Euro Retail Group', '11122233300044', 'Allemagne', '2025-05-05');

-- ============================================================================
-- INSERTIONS DANS LA TABLE : factures
-- ============================================================================
INSERT INTO factures (id_entreprise, id_plan, date_emission, date_echeance, statut) VALUES 
(1, 1, '2025-02-01', '2025-03-03', 'Payée'),
(1, 1, '2025-03-01', '2025-03-31', 'Payée'),
(1, 2, '2025-04-01', '2025-05-01', 'Payée'), 
(1, 2, '2025-05-01', '2025-05-31', 'En retard'),
(2, 1, '2025-03-01', '2025-03-31', 'Payée'),
(2, 1, '2025-04-01', '2025-05-01', 'Payée'),
(2, 1, '2025-05-01', '2025-05-31', 'En attente'),
(3, 3, '2025-04-01', '2025-05-01', 'Payée'),
(3, 3, '2025-05-01', '2025-05-31', 'Payée'),
(4, 2, '2025-05-01', '2025-05-31', 'En retard'),
(5, 3, '2025-05-10', '2025-06-09', 'En attente');

-- ============================================================================
-- INSERTIONS DANS LA TABLE : paiements
-- ============================================================================
INSERT INTO paiements (id_facture, montant_paye, date_payement, methode_payement) VALUES 
(1, 49.00, '2025-02-15', 'Carte'),
(2, 49.00, '2025-03-05', 'Carte'),
(3, 149.00, '2025-04-02', 'Prélèvement'),
(5, 49.00, '2025-03-02', 'Virement'),
(6, 49.00, '2025-04-12', 'Virement'),
(8, 499.00, '2025-04-01', 'Prélèvement'),
(9, 499.00, '2025-05-02', 'Prélèvement');

-- ============================================================================
-- REQUÊTE 1 : Liste globale des factures émises
-- Objectif : Associer les données de facturation aux informations clients et tarifs
-- ============================================================================
SELECT 
    e.nom_entreprise,  
    pa.nom_plan,        
    pa.prix_mensuel,    
    f.statut           
FROM factures f
JOIN plans_abonnement pa ON f.id_plan = pa.id_plan
JOIN entreprises e ON f.id_entreprise = e.id_entreprise;

-- ============================================================================
-- REQUÊTE 2 : Chiffre d'affaires dégressif par type de plan
-- Objectif : Analyser quelles offres génèrent le plus de revenus encaissés
-- ============================================================================
SELECT 
    pa.nom_plan,                        
    SUM(pa.prix_mensuel) AS CA_total    
FROM factures f
JOIN plans_abonnement pa ON f.id_plan = pa.id_plan
WHERE f.statut = 'Payée'               
GROUP BY pa.nom_plan
ORDER BY CA_total DESC;

-- ============================================================================
-- REQUÊTE 3 : Suivi des impayés par entreprise
-- Objectif : Identifier les clients en retard de paiement et cumuler la dette
-- ============================================================================
SELECT  
    e.nom_entreprise,
    SUM(pa.prix_mensuel) AS payement_retard
FROM factures f
JOIN plans_abonnement pa ON f.id_plan = pa.id_plan
JOIN entreprises e ON f.id_entreprise = e.id_entreprise
WHERE f.statut = 'En retard'
GROUP BY e.nom_entreprise
ORDER BY payement_retard DESC;

-- ============================================================================
-- REQUÊTE 4 : Délai moyen de paiement global
-- Objectif : Calculer le temps moyen (en jours) mis par les clients pour régler
-- ============================================================================
SELECT 
    AVG(DATEDIFF(p.date_payement, f.date_emission)) AS delai_moyen_jours
FROM factures f
-- Correction de l'alias de "pa" vers "p" ici pour correspondre à la jointure
JOIN paiements p ON f.id_facture = p.id_facture;

-- ============================================================================
-- REQUÊTE 5 : Analyse de contribution au Chiffre d'Affaires
-- Objectif : Utiliser une Window Function (OVER) pour calculer la part en % 
--            de chaque facture payée par rapport au CA total
-- ============================================================================
SELECT
    e.nom_entreprise,
    pa.prix_mensuel,
    ROUND((pa.prix_mensuel / SUM(pa.prix_mensuel) OVER()) * 100, 2) AS part_du_CA_pourcentage
FROM factures f
JOIN plans_abonnement pa ON f.id_plan = pa.id_plan
JOIN entreprises e ON f.id_entreprise = e.id_entreprise
WHERE f.statut = 'Payée';

-- ============================================================================
-- REQUÊTE 6 : Analyse comparative des marchés (Top par pays)
-- Objectif : Utiliser une CTE (WITH) et une fonction de classement (RANK) 
--            pour isoler la plus grosse facture émise pour chaque pays.
-- ============================================================================
WITH classement_factures AS (
    SELECT 
        e.pays,
        e.nom_entreprise,
        pa.prix_mensuel,
        RANK() OVER(PARTITION BY e.pays ORDER BY pa.prix_mensuel DESC) AS rang_facture
    FROM factures f
    JOIN plans_abonnement pa ON f.id_plan = pa.id_plan
    JOIN entreprises e ON f.id_entreprise = e.id_entreprise
)
SELECT 
    pays,
    nom_entreprise,
    prix_mensuel
FROM classement_factures
WHERE rang_facture = 1;
