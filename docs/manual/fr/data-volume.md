---
title: Volume de données
description: Comment l’app optiCLOUD Sensor compte son propre volume de données et comment le réduire.
sidebar_label: Volume de données
sidebar_position: 7
image: "/img/om_social_card.png"
keywords:
  - volume de données
  - réseau cellulaire
  - Wi-Fi
  - fréquence d’envoi
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Volume de données

Si vous utilisez un téléphone comme point de mesure en déplacement, vous voulez savoir ce que cela coûte en données cellulaires. C’est pourquoi l’app compte son propre volume de données.

## Où le voir

Sous **Réglages → Envoi → Volume de données aujourd’hui**, vous voyez le volume du jour. Si vous touchez cette ligne, l’app affiche les données envoyées (↑) et reçues (↓) pour aujourd’hui, cette semaine (à partir du lundi) et ce mois-ci, séparées à chaque fois entre réseau cellulaire et Wi-Fi.

Avec le groupe **Appareil**, l’app envoie aussi à optiCLOUD les totaux du jour et du mois (voir [Capteurs](sensors.md)). Vous pouvez ainsi suivre le volume de plusieurs téléphones dans un Dashboard.

## Comment l’app compte

L’app compte chaque message qu’elle échange avec optiCLOUD, avec sa taille. Pour le chiffrement et les protocoles réseau, elle ajoute un supplément fixe par message. Le résultat est une estimation : votre opérateur mobile calcule autrement et peut arriver à une valeur un peu différente. Les autres apps ne sont pas comptées.

Les compteurs s’appliquent par jour, selon l’heure locale du téléphone. C’est iOS qui décide, au moment du message, quel réseau est utilisé.

La manière exacte de compter est décrite dans la spécification : [`docs/spec/connection.md`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/connection.md#data-volume).

## Comment économiser du volume de données

- **Mode d’envoi « En cas de changement »** (par défaut) : l’app n’envoie que les valeurs qui ont changé.
- **Fréquence d’envoi plus longue :** envoyer toutes les 10 secondes au lieu de toutes les 2 secondes donne nettement moins de messages.
- **Moins de capteurs :** le groupe Mouvement envoie à chaque cycle la moyenne, le minimum et le maximum pour plusieurs axes et change presque toujours. Sélectionnez uniquement les valeurs dont vous avez besoin, par exemple uniquement la norme de l’accélération.

Même sans envoi, une connexion établie consomme un peu de volume, car l’app la vérifie régulièrement.

---

Cette documentation est publiée sous licence [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.fr). Attribution : optiMEAS GmbH et optiMEAS Switzerland GmbH.
