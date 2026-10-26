---
title: Confidentialité
description: Quelles données l’app optiCLOUD Sensor collecte, où elles vont et ce qui reste sur le téléphone.
sidebar_label: Confidentialité
sidebar_position: 9
image: "/img/om_social_card.png"
keywords:
  - confidentialité
  - localisation
  - micro
  - Access Token
  - trousseau
last_update:
  date: 2026-10-26
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Confidentialité

L’app mesure des choses qui peuvent en dire beaucoup sur vous : où vous êtes, comment vous vous déplacez, quel est le niveau de bruit autour de vous. C’est pourquoi nous indiquons ici précisément ce qu’elle en fait. Vous pouvez le vérifier dans le [code source](https://github.com/optimeas/opticloud-sensor-app).

## L’essentiel

- L’app n’envoie qu’au serveur optiCLOUD que vous indiquez lors de la connexion, et là uniquement à l’appareil que vous avez choisi.
- Elle n’envoie que tant que vous avez activé l’envoi, et uniquement les capteurs que vous avez sélectionnés.
- Elle ne contient ni publicité ni service d’analyse ou de suivi, et ne communique avec aucun autre service.
- Elle n’enregistre aucun son. Du micro, elle n’utilise que le volume sonore.
- Elle n’enregistre pas votre mot de passe.

## Ce qui est envoyé à optiCLOUD

| Données | Quand |
|---|---|
| Les valeurs des capteurs sélectionnés, avec horodatage | Tant que l’envoi est activé, et une fois sur la commande `sendNow` |
| Version de l’app, système d’exploitation, modèle du téléphone, capteurs disponibles et sélectionnés, fréquence d’envoi, envoi en cours ou non | Après chaque connexion et lors de changements |
| Réponses aux commandes | Quand optiCLOUD envoie une commande |
| Valeurs que vous envoyez à la main dans l’onglet Diagnostic | Quand vous les envoyez |
| Adresse e-mail et mot de passe | Uniquement lors de la connexion, pour vous connecter |

Dans optiCLOUD, ces données appartiennent à l’appareil de votre Tenant. Qui peut les y voir est déterminé par les droits de votre Tenant. Pensez-y, en particulier pour la localisation : toutes les personnes autorisées à voir l’appareil dans optiCLOUD voient aussi où le téléphone s’est trouvé.

La connexion est chiffrée (TLS).

## Ce qui reste sur le téléphone

- **Dans le trousseau d’iOS :** l’Access Token de l’appareil, la session de votre connexion et un identifiant de l’installation, avec lequel l’app lie l’appareil à ce téléphone.
- **Dans les données de l’app :** les réglages, la file hors ligne avec les valeurs pas encore envoyées, les compteurs du volume de données et le journal de l’onglet Diagnostic. Le journal ne quitte le téléphone que si vous l’exportez vous-même.

## Autorisations

| Autorisation | Pour quoi |
|---|---|
| Position | Le groupe Localisation, et avec « Toujours » l’envoi en arrière-plan (voir [Arrière-plan et localisation](background.md)) |
| Mouvements et forme | Le groupe Activité (pas et type d’activité) et la pression atmosphérique |
| Micro | Le groupe Son : uniquement le volume sonore |

iOS ne demande une autorisation que lorsque vous avez sélectionné un capteur qui en a besoin et que vous démarrez l’envoi. Vous pouvez retirer chaque autorisation à tout moment dans les Réglages d’iOS. L’app continue alors d’envoyer les autres valeurs.

## Responsabilité

Pour les données dans optiCLOUD, ce sont les accords entre vous ou votre entreprise et l’exploitant du serveur optiCLOUD qui s’appliquent. Pour toute question sur l’app, vous pouvez nous joindre via le [site web d’optiMEAS](https://optimeas.com) ou sur [GitHub](https://github.com/optimeas/opticloud-sensor-app/issues).

---

Cette documentation est publiée sous licence [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.fr). Attribution : optiMEAS GmbH et optiMEAS Switzerland GmbH.
