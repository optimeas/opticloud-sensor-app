---
title: L’appareil dans optiCLOUD
description: Télémétrie, attributs client, Shared Attributes et commandes d’un appareil de l’app optiCLOUD Sensor.
sidebar_label: L’appareil dans optiCLOUD
sidebar_position: 6
image: "/img/om_social_card.png"
keywords:
  - appareil
  - télémétrie
  - attribut client
  - Shared Attributes
  - RPC
last_update:
  date: 2026-10-27
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# L’appareil dans optiCLOUD

Pour optiCLOUD, votre téléphone est un appareil comme un autre. Vous le trouvez dans le projet choisi sous son nom, avec le type d’appareil « optiCLOUD Sensor App ». Vous utilisez ses valeurs dans les Dashboards, les règles d’alarme et les rapports, comme celles de n’importe quel autre appareil.

## Télémétrie

Les mesures arrivent sous forme de télémétrie. Chaque valeur porte l’horodatage du moment où elle a été mesurée, et non de celui où elle a été envoyée. Les valeurs issues de la file hors ligne apparaissent donc au bon endroit de la série temporelle. Les clés existantes sont indiquées sous [Capteurs](sensors.md).

## Attributs client

Après chaque connexion et à chaque changement, l’app indique ce qu’est le téléphone et ce qu’il fait en ce moment :

| Clé | Contenu |
|---|---|
| `appVersion` | Version de l’app |
| `os` | `iOS` ou `Android` |
| `osVersion` | Version du système d’exploitation |
| `model` | Modèle du téléphone, par exemple `iPhone 16 Pro Max` |
| `sensorsAvailable` | Les valeurs que ce téléphone propose |
| `sensors` | Les valeurs actuellement sélectionnées |
| `sendRate` | La fréquence d’envoi en secondes |
| `transmitting` | Si le téléphone envoie en ce moment |

`sensorsAvailable` et `sensors` sont des listes de groupes et de valeurs, séparés par des virgules, par exemple `device,location,accelMagnitude`. Un nom de groupe représente toutes les valeurs du groupe.

## Réglages depuis optiCLOUD

Vous pouvez définir trois réglages de l’app dans optiCLOUD, au moyen de Shared Attributes de l’appareil :

| Shared Attribute | Type | Réglage |
|---|---|---|
| `sendRate` | Nombre | Fréquence d’envoi en secondes, de 1 à 3600 |
| `sensors` | Texte | Sélection des capteurs, par exemple `motion,location` |
| `dashboard` | Texte | Dashboard par défaut de l’onglet [Favoris](favorites.md), l’ID du Dashboard |

- Si le Shared Attribute existe, l’app reprend sa valeur et affiche le réglage comme géré. Il ne peut alors plus être modifié sur le téléphone.
- Si vous supprimez le Shared Attribute, l’app conserve la dernière valeur, et le réglage peut de nouveau être modifié sur le téléphone.
- Une valeur que l’app ne peut pas utiliser est ignorée, et l’app l’indique dans l’onglet [Diagnostic](diagnosis.md). C’est le cas, par exemple, d’une fréquence d’envoi hors de la plage ou d’un nom de capteur inconnu.
- Si le téléphone n’est pas connecté à ce moment-là, l’app récupère les valeurs à la connexion suivante.

Vous pouvez ainsi, par exemple, définir la même sélection pour tous les téléphones d’un projet, sans régler chacun individuellement.

Le Shared Attribute `sensorAppInstallation` est écrit par l’app elle-même. Il lie l’appareil à un téléphone. Ne le modifiez pas et ne le supprimez pas à la main.

## Commandes

Tant que le téléphone est connecté, vous pouvez lui envoyer des commandes (RPC) depuis optiCLOUD, par exemple depuis un Dashboard. L’app répond à chaque commande et l’affiche dans l’onglet [Diagnostic](diagnosis.md).

| Commande | Paramètres | Effet | Réponse |
|---|---|---|---|
| `ping` | aucun | aucun | `{ "pong": true }` |
| `getState` | aucun | aucun | par exemple `{ "transmitting": false, "sendRate": 5, "sensors": "motion,location" }` |
| `startTransmission` | aucun | Démarre l’envoi | `{ "transmitting": true }` |
| `stopTransmission` | aucun | Arrête l’envoi | `{ "transmitting": false }` |
| `setSendRate` | `{ "seconds": 5 }` | Modifie la fréquence d’envoi | `{ "sendRate": 5 }` |
| `sendNow` | aucun | Mesure immédiatement toutes les valeurs sélectionnées et les envoie, même si l’envoi est arrêté | `{ "sent": true }` |

Si l’app ne peut pas exécuter une commande, elle ne modifie rien et répond par une erreur, par exemple `{ "error": "unknown method" }` :

| Erreur | Cause |
|---|---|
| `unknown method` | L’app ne connaît pas cette commande. |
| `invalid params` | Un paramètre manque, n’a pas le bon type ou est hors de la plage. |
| `managed setting` | Le réglage est géré au moyen d’un Shared Attribute. |

Une commande n’atteint le téléphone que tant qu’il est connecté. Pour que le téléphone reçoive des commandes même sans envoyer, activez l’option **Connecté** sous **Réglages → Connexion**.

## Plus de détails

Les messages sont décrits en détail dans la spécification : [`docs/spec/messages.md`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/messages.md).

---

Cette documentation est publiée sous licence [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.fr). Attribution : optiMEAS GmbH et optiMEAS Switzerland GmbH.
