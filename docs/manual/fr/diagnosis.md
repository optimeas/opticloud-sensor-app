---
title: Diagnostic
description: Journal, file hors ligne et valeurs de test dans l’onglet Diagnostic de l’app optiCLOUD Sensor, et comment exporter le journal.
sidebar_label: Diagnostic
sidebar_position: 9
image: "/img/om_social_card.png"
keywords:
  - diagnostic
  - journal
  - assistance
  - file hors ligne
last_update:
  date: 2026-10-26
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Diagnostic

L’onglet **Diagnostic** montre ce qui se passe entre le téléphone et optiCLOUD. Il vous aide à vérifier une intégration, et nous aide à vous aider en cas de problème.

## Envoyer une valeur

Ici, vous envoyez une valeur isolée à la main, par exemple pour tester un Dashboard ou une règle d’alarme.

1. Saisissez une **Clé** en lowerCamelCase, par exemple `testValue`.
2. Choisissez le **Type** : Nombre, Texte ou Oui/Non.
3. Saisissez la **Valeur**.
4. Touchez **Envoyer comme télémétrie** ou **Envoyer comme attribut client**.

La télémétrie passe, comme toute mesure, par la file hors ligne et arrive même si la connexion fait momentanément défaut. Un attribut client nécessite une connexion établie.

## File hors ligne

| Ligne | Signification |
|---|---|
| **Échantillons** | Combien d’échantillons attendent d’être livrés |
| **Taille** | La place qu’ils occupent, 50 MB au maximum |
| **Plus ancien** | L’horodatage de l’échantillon en attente le plus ancien |
| **Rejetés** | Combien d’échantillons l’app a rejetés, parce que la file était pleine ou qu’optiCLOUD a refusé un message à plusieurs reprises |
| **Période rejetée** | La période d’où proviennent les échantillons rejetés |

Avec **Réinitialiser le compteur de rejets**, vous remettez le compteur à zéro. Le fonctionnement de la file est décrit sous [Envoi](sending.md).

## Journal

Le journal affiche, le plus récent en premier :

- les commandes provenant d’optiCLOUD avec leurs paramètres et la réponse de l’app,
- les modifications des Shared Attributes, y compris pour des clés que l’app n’utilise pas ; au lieu de l’identifiant de l’installation dans `sensorAppInstallation`, il indique seulement si la liaison appartient à ce téléphone,
- les valeurs que l’app n’a pas pu utiliser, par exemple une fréquence d’envoi non valide,
- les changements de la connexion avec leur raison, par exemple « Pas de réseau »,
- le début et la fin de la localisation et les problèmes rencontrés,
- chaque démarrage de l’app, avec une mention lorsque iOS l’a démarrée en arrière-plan,
- quand l’app est passée en arrière-plan et revenue au premier plan, et **En pause** lorsque iOS a suspendu l’app, avec la durée de la pause,
- les valeurs que vous avez envoyées à la main.

Le journal se trouve dans les données de l’app sur le téléphone et conserve les 1000 dernières entrées, même après un redémarrage de l’app. Les entrées des jours précédents affichent la date. Avec **Effacer**, vous le videz.

## Exporter le journal

Touchez le symbole de partage en haut à droite (un carré avec une flèche vers le haut). VoiceOver l’appelle **Exporter le journal**. L’app crée un texte que vous pouvez transmettre par e-mail, par message ou dans un fichier. Il contient :

- la version de l’app, le modèle du téléphone et la version d’iOS,
- l’appareil, le projet, le Tenant et le serveur,
- l’état de la connexion et de l’envoi, la fréquence d’envoi et le mode d’envoi,
- les capteurs sélectionnés,
- l’état de la file hors ligne,
- toutes les entrées du journal.

Le texte ne contient ni votre mot de passe ni l’Access Token de l’appareil. Avant de le transmettre, vous pouvez le lire : ce n’est que du texte.

---

Cette documentation est publiée sous licence [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.fr). Attribution : optiMEAS GmbH et optiMEAS Switzerland GmbH.
