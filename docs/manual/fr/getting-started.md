---
title: Premiers pas
description: Se connecter, choisir un appareil et envoyer pour la première fois des valeurs de capteurs à optiCLOUD.
sidebar_label: Premiers pas
sidebar_position: 2
image: "/img/om_social_card.png"
keywords:
  - connexion
  - Tenant
  - projet
  - appareil
  - Access Token
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Premiers pas

Après le premier lancement, l’app affiche « Aucun appareil ». Avant qu’elle puisse envoyer, vous vous connectez à optiCLOUD et choisissez l’appareil auquel ce téléphone envoie ses données. Cela prend environ une minute.

## Se connecter

1. Touchez **Se connecter**.
2. Sous **optiCLOUD** figure l’adresse de l’application web optiCLOUD, préréglée sur `https://dashboard.opticloud.io`. Ne la modifiez que si vous utilisez un autre serveur optiCLOUD.
3. Saisissez l’adresse e-mail et le mot de passe de votre compte optiCLOUD personnel, puis touchez **Se connecter**.
4. Si vous avez accès à plusieurs Tenants, vous en choisissez un. Avec un seul Tenant, l’app saute cette étape.
5. Si le Tenant exige un code par e-mail, saisissez-le et touchez **Confirmer**. Avec **Envoyer un nouveau code**, vous en demandez un nouveau.
6. Choisissez le projet.

L’app n’enregistre pas votre mot de passe. Elle n’en a besoin que pour la connexion.

## Choisir l’appareil

L’app envoie à un appareil dans optiCLOUD, comme n’importe quel autre matériel. La liste n’affiche que les appareils de type « optiCLOUD Sensor App » du projet choisi.

- **Appareil existant :** touchez l’appareil.
- **Nouvel appareil :** touchez **Nouvel appareil**, saisissez un nom et touchez **Créer**. Le nom doit être unique dans le Tenant, par exemple « iPhone Anna ».

L’app lie ensuite l’appareil à ce téléphone et lit son Access Token. Avec l’Access Token, elle se connecte plus tard à optiCLOUD en tant qu’appareil.

Un appareil n’envoie jamais que depuis un seul téléphone. Si l’appareil choisi est déjà lié à un autre téléphone, l’app vous demande si vous voulez le reprendre. Si vous le reprenez, l’autre téléphone cesse d’envoyer à cet appareil.

Pour ces étapes, vous avez besoin dans optiCLOUD du droit de lire et de créer des appareils et d’écrire leurs attributs. S’il manque un droit, l’app indique lequel.

## Envoyer pour la première fois

1. Passez à l’onglet **Live**.
2. Touchez **Démarrer l’envoi**. L’app se connecte à optiCLOUD et commence à envoyer.
3. La première fois, iOS demande les autorisations dont les capteurs sélectionnés ont besoin, par exemple pour la localisation. Pour le fonctionnement en arrière-plan, autorisez d’abord la localisation « Lorsque l’app est active » ; l’app demande ensuite une fois « Toujours » (voir [Arrière-plan et localisation](background.md)).

Dès lors, l’onglet **Live** affiche les valeurs mesurées, et elles arrivent dans optiCLOUD comme télémétrie de l’appareil. Par défaut, l’app envoie les valeurs des groupes Appareil et Localisation toutes les 2 secondes, et uniquement lorsqu’une valeur a changé. Pour modifier cela, voir [Envoi](sending.md) et [Capteurs](sensors.md).

Avec **Arrêter l’envoi**, vous cessez d’envoyer.

## Les trois onglets

| Onglet | Contenu |
|---|---|
| **Live** | Démarrer et arrêter l’envoi, les valeurs actuelles |
| **Diagnostic** | Journal, file hors ligne, envoi de valeurs de test (voir [Diagnostic](diagnosis.md)) |
| **Réglages** | Appareil, connexion, envoi, capteurs, volume de données, compte, à propos de l’app |

## Se déconnecter

Sous **Réglages → Compte**, vous vous déconnectez. La déconnexion n’arrête pas l’envoi : le téléphone continue d’envoyer avec l’Access Token de l’appareil jusqu’à ce que vous arrêtiez l’envoi. Vous ne devez vous reconnecter que si vous voulez choisir un autre appareil.

## Choisir un autre appareil

Sous **Réglages → Appareil**, touchez **Choisir un autre appareil**. Si des valeurs pas encore livrées se trouvent dans la file hors ligne, l’app indique combien il y en a. Elles appartiennent à l’appareil précédent et sont rejetées si vous en choisissez un autre.

---

Cette documentation est publiée sous licence [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.fr). Attribution : optiMEAS GmbH et optiMEAS Switzerland GmbH.
