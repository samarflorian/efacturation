# Système de E-Facturation B2B (SaaS) - Analyse SQL

## 📌 Présentation du projet
Ce projet présente la modélisation et l'analyse de données d'un système de facturation électronique pour une plateforme SaaS B2B (vente d'abonnements logiciels à des entreprises). 

L'objectif est de démontrer des compétences en ingénierie de données et en analyse décisionnelle (Business Intelligence) à travers un cas d'usage concret et conforme aux besoins réels des entreprises.

Toutes les étapes (création du schéma, jeu de données de test et requêtes analytiques) sont regroupées dans le fichier unique : `efacturation.sql`.

---

## 🛠️ Compétences SQL démontrées
* **Modélisation de base de données (MPD) :** Création de tables avec clés primaires (`PRIMARY KEY`), intégrité référentielle (`FOREIGN KEY`) et auto-incrémentation.
* **Sécurisation des données :** Utilisation de contraintes strictes (`CHECK`, `NOT NULL`, `UNIQUE`) pour garantir la cohérence des cycles de facturation et des modes de paiement.
* **Optimisation financière :** Utilisation du type `DECIMAL` pour éviter les erreurs d'arrondis sur les flux monétaires.
* **Algorithmique SQL :** Maîtrise des jointures multiples (`JOIN`), des agrégations complexes (`SUM`, `GROUP BY`), des tris (`ORDER BY`) et du filtrage de données.

---

## 📊 Modèle Physique de Données (MPD)
Le système s'articule autour de 4 tables interconnectées :
1. **`entreprises`** : Registre des clients B2B avec identification légale (SIRET à 14 caractères).
2. **`plans_abonnement`** : Catalogue des offres et de leur tarification mensuelle.
3. **`factures`** : Suivi des pièces comptables émises, des échéances et des statuts de paiement (`Payée`, `En attente`, `En retard`).
4. **`paiements`** : Historique des transactions financières et des méthodes de règlement utilisées (`Virement`, `Carte`, `Prélèvement`).

---

## 📈 Exemples d'analyses disponibles
Le script de requêtes est structuré pour répondre à des problématiques business majeures :
* **Suivi opérationnel :** Liste globale et croisée des factures avec l'identité client et le plan associé.
* **Analyse de performance commerciale :** Calcul du chiffre d'affaires total encaissé, ventilé par type d'abonnement et trié par ordre décroissant de performance.
* **Gestion du risque client (À venir) :** Identification des entreprises en défaut de paiement et calcul des montants cumulés des impayés à régulariser.

---

## 🚀 Comment utiliser ce projet
1. Assurez-vous de disposer d'un serveur MySQL.
2. Exécutez l'intégralité du script à l'aide de votre client SQL préféré ou via le terminal :
   ```bash
   mysql -u votre_utilisateur -p < efacturation.sql
