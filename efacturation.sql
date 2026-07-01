CREATE DATABASE IF NOT EXISTS efacturation;
USE efacturation;

DROP TABLE IF EXISTS paiements;
DROP TABLE IF EXISTS factures;
DROP TABLE IF EXISTS plans_abonnement;
DROP TABLE IF EXISTS entreprises;

CREATE TABLE entreprises (
    id_entreprise INT AUTO_INCREMENT PRIMARY KEY,
    nom_entreprise VARCHAR(100) NOT NULL,
    siret CHAR(14) UNIQUE, 
    pays VARCHAR(50),
    date_inscription DATE
);

CREATE TABLE plans_abonnement (
    id_plan INT AUTO_INCREMENT PRIMARY KEY,
    nom_plan VARCHAR(100) NOT NULL,
    prix_mensuel DECIMAL(10,2) NOT NULL 
);

CREATE TABLE factures (
    id_facture INT AUTO_INCREMENT PRIMARY KEY,
    id_entreprise INT, 
    id_plan INT,       
    montant_historique DECIMAL(10,2) NOT NULL, -- Fige le prix de la facture pour l'historique comptable
    date_emission DATE,
    date_echeance DATE,
    statut VARCHAR(50) CHECK (statut IN ('Payée', 'En attente', 'En retard')), 
    FOREIGN KEY(id_entreprise) REFERENCES entreprises(id_entreprise),
    FOREIGN KEY(id_plan) REFERENCES plans_abonnement(id_plan)
);

CREATE TABLE paiements (
    id_paiements INT AUTO_INCREMENT PRIMARY KEY,
    id_facture INT, 
    montant_paye DECIMAL(10,2),
    date_payement DATE,
    methode_payement VARCHAR(50) CHECK (methode_payement IN ('Virement', 'Carte', 'Prélèvement')), 
    FOREIGN KEY(id_facture) REFERENCES factures(id_facture)
);

-- INSERTIONS
INSERT INTO plans_abonnement (nom_plan, prix_mensuel) VALUES 
('Standard', 49.00),
('Premium', 149.00),
('Entreprise', 499.00);

INSERT INTO entreprises (nom_entreprise, siret, pays, date_inscription) VALUES 
('TechSolutions France', '12345678901234', 'France', '2025-01-15'),
('Alpha Digital', '98765432100012', 'France', '2025-02-10'),
('Global Logistics Corp', '55566677700099', 'Belgique', '2025-03-01'),
('DataCraft Studio', '44433322200055', 'France', '2025-04-20'),
('Euro Retail Group', '11122233300044', 'Allemagne', '2025-05-05');

INSERT INTO factures (id_entreprise, id_plan, montant_historique, date_emission, date_echeance, statut) VALUES 
(1, 1, 49.00, '2025-02-01', '2025-03-03', 'Payée'),
(1, 1, 49.00, '2025-03-01', '2025-03-31', 'Payée'),
(1, 2, 149.00, '2025-04-01', '2025-05-01', 'Payée'), 
(1, 2, 149.00, '2025-05-01', '2025-05-31', 'En retard'),
(2, 1, 49.00, '2025-03-01', '2025-03-31', 'Payée'),
(2, 1, 49.00, '2025-04-01', '2025-05-01', 'Payée'),
(2, 1, 49.00, '2025-05-01', '2025-05-31', 'En attente'),
(3, 3, 499.00, '2025-04-01', '2025-05-01', 'Payée'),
(3, 3, 499.00, '2025-05-01', '2025-05-31', 'Payée'),
(4, 2, 149.00, '2025-05-01', '2025-05-31', 'En retard'),
(5, 3, 499.00, '2025-05-10', '2025-06-09', 'En attente');

INSERT INTO paiements (id_facture, montant_paye, date_payement, methode_payement) VALUES 
(1, 49.00, '2025-02-15', 'Carte'),
(2, 49.00, '2025-03-05', 'Carte'),
(3, 149.00, '2025-04-02', 'Prélèvement'),
(5, 49.00, '2025-03-02', 'Virement'),
(6, 49.00, '2025-04-12', 'Virement'),
(8, 499.00, '2025-04-01', 'Prélèvement'),
(9, 499.00, '2025-05-02', 'Prélèvement');

-- REQUÊTES (Ajustées avec montant_historique)
-- R1
SELECT e.nom_entreprise, pa.nom_plan, f.montant_historique, f.statut           
FROM factures f
JOIN plans_abonnement pa ON f.id_plan = pa.id_plan
JOIN entreprises e ON f.id_entreprise = e.id_entreprise;

-- R2
SELECT pa.nom_plan, SUM(f.montant_historique) AS CA_total    
FROM factures f
JOIN plans_abonnement pa ON f.id_plan = pa.id_plan
WHERE f.statut = 'Payée'               
GROUP BY pa.nom_plan
ORDER BY CA_total DESC;

-- R3
SELECT e.nom_entreprise, SUM(f.montant_historique) AS payement_retard
FROM factures f
JOIN entreprises e ON f.id_entreprise = e.id_entreprise
WHERE f.statut = 'En retard'
GROUP BY e.nom_entreprise
ORDER BY payement_retard DESC;

-- R4
SELECT AVG(DATEDIFF(p.date_payement, f.date_emission)) AS delai_moyen_jours
FROM factures f
JOIN paiements p ON f.id_facture = p.id_facture;

-- R5
SELECT e.nom_entreprise, f.montant_historique,
    ROUND((f.montant_historique / SUM(f.montant_historique) OVER()) * 100, 2) AS part_du_CA_pourcentage
FROM factures f
JOIN entreprises e ON f.id_entreprise = e.id_entreprise
WHERE f.statut = 'Payée';

-- R6
WITH classement_factures AS (
    SELECT e.pays, e.nom_entreprise, f.montant_historique,
        RANK() OVER(PARTITION BY e.pays ORDER BY f.montant_historique DESC) AS rang_facture
    FROM factures f
    JOIN entreprises e ON f.id_entreprise = e.id_entreprise
)
SELECT pays, nom_entreprise, montant_historique
FROM classement_factures
WHERE rang_facture = 1;
