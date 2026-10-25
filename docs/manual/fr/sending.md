---
title: Envoi
description: Fréquence d’envoi, mode d’envoi, connexion et file hors ligne de l’app optiCLOUD Sensor.
sidebar_label: Envoi
sidebar_position: 3
image: "/img/om_social_card.png"
keywords:
  - fréquence d’envoi
  - télémétrie
  - MQTT
  - file hors ligne
  - connexion
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Envoi

Les réglages de l’envoi se trouvent sous **Réglages → Envoi**. L’envoi se démarre et s’arrête dans l’onglet **Live**.

## Fréquence d’envoi

La fréquence d’envoi détermine à quelle fréquence l’app mesure et envoie : une fois toutes les 1 à 3600 secondes, par défaut toutes les 2 secondes. Chaque cycle produit un échantillon avec un horodatage commun.

Les valeurs rapides comme l’accélération et la vitesse de rotation sont mesurées en continu par l’app à 50 Hz entre deux cycles. À chaque cycle, elle envoie la moyenne, le minimum et le maximum de ces mesures. Ainsi, les chocs et les vibrations entre deux cycles ne sont pas perdus, même avec une fréquence d’envoi longue.

## Mode d’envoi

| Mode | Ce que l’app envoie |
|---|---|
| **En cas de changement** (par défaut) | À chaque cycle, uniquement les valeurs qui ont changé depuis le dernier envoi. Une fois par minute, toutes les valeurs. |
| **À chaque cycle** | À chaque cycle, toutes les valeurs sélectionnées. |

« Changé » signifie : la valeur diffère après arrondi à la résolution du capteur (voir [Capteurs](sensors.md)). Un niveau de batterie de 0,8312 et de 0,8349 est, arrondi à 0,01, la même valeur et n’est pas renvoyé. Si rien ne change lors d’un cycle, l’app n’envoie rien.

L’échantillon complet une fois par minute donne à optiCLOUD un point de référence régulier. « En cas de changement » économise ainsi du volume de données sans créer de longues lacunes dans optiCLOUD.

Les valeurs qui ne naissent que d’un événement, comme un changement d’activité, sont envoyées immédiatement par l’app dans les deux modes.

## Connexion

L’app communique avec optiCLOUD via MQTT, chiffré par TLS, et se connecte avec l’Access Token de l’appareil.

**Démarrer l’envoi** connecte aussi l’app. Sous **Réglages → Connexion**, vous pouvez en outre maintenir la connexion avec **Connecté**, sans envoyer. Tant que la connexion existe, optiCLOUD peut envoyer des commandes au téléphone (voir [L’appareil dans optiCLOUD](device-in-opticloud.md)).

L’état indique où en est la connexion :

| État | Signification |
|---|---|
| **Déconnecté** | Aucune connexion et aucune tentative. |
| **Connexion…** | L’app établit la connexion. |
| **Connecté** | L’app est connectée à optiCLOUD. |
| **En attente** | La connexion a été interrompue ou n’a pas pu être établie, par exemple en l’absence de réseau. L’app réessaie d’elle-même. |
| **Refusé** | optiCLOUD a refusé l’Access Token, ou l’appareil est lié à un autre téléphone. L’app ne réessaie pas. |

En cas d’**En attente**, l’app attend d’abord 1 seconde et double la pause à chaque échec, jusqu’à 60 secondes. Si iOS signale que le réseau est de retour, elle réessaie immédiatement.

En cas de **Refusé**, la seule solution est de choisir de nouveau l’appareil : connectez-vous et choisissez une nouvelle fois l’appareil sous **Réglages → Appareil**. Si un autre téléphone a repris l’appareil, vous pouvez ainsi le récupérer.

## File hors ligne

Chaque échantillon passe d’abord par une file d’attente sur le téléphone, même lorsque l’app est connectée. De là, l’app livre les échantillons, le plus ancien en premier, et ne les supprime que lorsqu’optiCLOUD en a confirmé la réception.

- Sans réseau, l’app continue de collecter. Dès que la connexion est rétablie, elle livre les échantillons en retard, avec leurs horodatages d’origine. Aucune lacune n’apparaît ainsi dans optiCLOUD.
- La file survit à un redémarrage de l’app et du téléphone.
- Elle contient jusqu’à 50 MB. Lorsqu’elle est pleine, l’app rejette les échantillons les plus anciens et les compte.
- Si la connexion est interrompue avant qu’optiCLOUD ait confirmé un message, l’app le renvoie. optiCLOUD peut alors enregistrer certaines valeurs en double, avec le même horodatage.

L’onglet [Diagnostic](diagnosis.md) indique combien d’échantillons attendent et combien ont été rejetés.

## Géré par optiCLOUD

La fréquence d’envoi et la sélection des capteurs peuvent aussi être définies depuis optiCLOUD, au moyen de Shared Attributes de l’appareil (voir [L’appareil dans optiCLOUD](device-in-opticloud.md)). Si un réglage est géré de cette manière, l’app l’affiche avec la mention « géré », et vous ne pouvez pas le modifier sur le téléphone.

---

Cette documentation est publiée sous licence [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.fr). Attribution : optiMEAS GmbH et optiMEAS Switzerland GmbH.
