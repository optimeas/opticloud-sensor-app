---
title: Pourquoi l’open source
description: Pourquoi optiMEAS rend publics l’app optiCLOUD Sensor et son interface.
sidebar_label: Pourquoi l’open source
sidebar_position: 1
image: "/img/om_social_card.png"
keywords:
  - open source
  - MIT
  - transparence
  - optiCLOUD
  - interface
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Pourquoi l’open source

optiCLOUD Sensor est open source. Le code source complet des deux apps, la spécification et cette documentation sont publics sur GitHub : [github.com/optimeas/opticloud-sensor-app](https://github.com/optimeas/opticloud-sensor-app). Le code est sous licence MIT, la documentation sous CC BY 4.0.

Les raisons vont au-delà de cette seule app.

## Vous voyez ce que l’app envoie

Une app qui mesure la localisation, le mouvement et les bruits mérite la méfiance tant qu’on ne peut pas vérifier ce qu’elle en fait. Avec optiCLOUD Sensor, vous pouvez le vérifier. Chaque valeur que l’app envoie est décrite dans la spécification, et le code qui la mesure et l’envoie est lisible par tous. L’app n’envoie qu’à l’appareil optiCLOUD que vous avez vous-même choisi, et à aucun autre service. Ce que cela signifie en détail est expliqué sous [Confidentialité](privacy.md).

L’honnêteté en fait partie : là où l’app fait une estimation, elle le dit. Le niveau sonore est une estimation et non une mesure étalonnée, le volume de données un calcul et non la facture de votre opérateur mobile.

## Un exemple d’intégration à optiCLOUD

L’app est aussi un exemple complet et fonctionnel de la manière dont un appareil communique avec optiCLOUD :

- se connecter via l’interface REST et créer ou choisir un appareil,
- envoyer la télémétrie et les attributs client via MQTT,
- recevoir les Shared Attributes et laisser optiCLOUD gérer des réglages,
- accepter des commandes (RPC) et y répondre,
- mettre les mesures en mémoire tampon en l’absence de réseau et les livrer dans le bon ordre.

Si vous souhaitez vous-même intégrer un appareil, une passerelle ou un logiciel à optiCLOUD, vous ne trouverez pas ici un extrait, mais un ensemble complet qui fonctionne au quotidien – en Swift pour iOS et bientôt aussi en Kotlin pour Android.

## Une spécification ouverte

Les apps suivent une spécification commune dans le dossier [`docs/spec`](https://github.com/optimeas/opticloud-sensor-app/tree/main/docs/spec). Elle décrit dans ses propres mots l’authentification, la connexion, les messages, les capteurs et la file hors ligne. Des vecteurs de test définissent comment les valeurs sont arrondies, sélectionnées, regroupées et empaquetées. Les deux apps doivent réussir chaque vecteur. Ainsi, iOS et Android restent identiques, et quiconque écrit une troisième implémentation peut la vérifier avec les mêmes vecteurs.

## Apprenez à nous connaître

optiMEAS est synonyme de compétence, de relations d’égal à égal, d’ouverture, d’honnêteté et de savoir. Plutôt que de simplement l’affirmer, nous montrons notre travail : comment nous consignons les exigences, justifions les décisions, testons et documentons. Vous pouvez vous faire votre propre idée avant de travailler avec nous.

Nous partageons le savoir, car il grandit ainsi. Ce que nous avons appris en développant l’app sur les capteurs, le fonctionnement en arrière-plan et MQTT sur smartphone figure dans la spécification et dans le code – y compris les pièges.

## Participez

Les erreurs, questions et suggestions sont les bienvenues sur GitHub, sous forme d’issue ou de pull request. Nous accueillons les contributions d’égal à égal, qu’elles viennent d’un client, d’un étudiant ou d’une autre entreprise. L’organisation du travail dans le dépôt est décrite dans le [README](https://github.com/optimeas/opticloud-sensor-app#readme).

## Pas le premier projet de ce type

optiCLOUD Sensor n’est pas notre premier projet ouvert. L’Open Streaming Format (OSF), notre format de fichier pour les données de mesure et de processus, est lui aussi spécifié ouvertement et publié sur GitHub : [github.com/optimeas/osf](https://github.com/optimeas/osf). Sa documentation se trouve sous Formats de données dans la [documentation optiMEAS](https://docs.optimeas.com). Les deux projets suivent la même idée : ce que nous rendons public, chacun peut le vérifier, l’utiliser et l’améliorer.

---

Cette documentation est publiée sous licence [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.fr). Attribution : optiMEAS GmbH et optiMEAS Switzerland GmbH.
