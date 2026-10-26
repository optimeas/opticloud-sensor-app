---
title: Capteurs
description: Quelles valeurs l’app optiCLOUD Sensor mesure, dans quelles unités et sous quelles clés elles arrivent dans optiCLOUD.
sidebar_label: Capteurs
sidebar_position: 4
image: "/img/om_social_card.png"
keywords:
  - capteurs
  - télémétrie
  - accélération
  - localisation
  - niveau sonore
last_update:
  date: 2026-10-26
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Capteurs

L’app propose chaque capteur dont dispose votre téléphone. Les capteurs sont classés en groupes. Sous **Réglages → Envoi → Capteurs**, vous activez et désactivez des groupes entiers ; si vous touchez un groupe, vous pouvez y désélectionner des valeurs individuelles. Par défaut, les groupes Appareil et Localisation sont sélectionnés.

Si un capteur a besoin d’une autorisation, iOS la demande dès que l’envoi démarre. Si vous refusez, les valeurs de ce capteur manquent ; les autres continuent d’être envoyées.

Dans optiCLOUD, les valeurs arrivent comme télémétrie de l’appareil, sous les clés indiquées dans les tableaux ci-dessous. Une clé a la même unité et la même signification sur iOS et sur Android. L’app arrondit chaque valeur à la résolution indiquée. Si une valeur n’est pas disponible à un moment donné, l’app l’omet au lieu d’envoyer une valeur de remplacement.

## Mouvement

| Valeur | Clé | Unité | Résolution |
|---|---|---|---|
| Accélération | `accelX`, `accelY`, `accelZ` | m/s² | 0,01 |
| Norme de l’accélération | `accelMagnitude` | m/s² | 0,01 |
| Vitesse de rotation | `gyroX`, `gyroY`, `gyroZ` | rad/s | 0,001 |
| Champ magnétique | `magX`, `magY`, `magZ` | µT | 0,1 |
| Orientation | `roll`, `pitch`, `yaw` | degré | 0,1 |

Les axes se rapportent au téléphone tenu droit en mode portrait, écran tourné vers vous : x pointe vers la droite, y vers le haut, z sort de l’écran. Un téléphone posé à plat sur la table mesure sur z environ +9,81 m/s², l’accélération de la pesanteur. La norme de l’accélération ne dépend pas de la façon dont le téléphone est tenu et se situe au repos à environ 9,81.

L’app mesure l’accélération et la vitesse de rotation à 50 Hz et envoie à chaque cycle la moyenne sous la clé elle-même, ainsi que le minimum et le maximum avec le suffixe `Min` et `Max`, par exemple `accelXMin` et `accelXMax`.

À propos de l’orientation : `pitch` est positif lorsque le bord supérieur est relevé (90 en mode portrait, téléphone droit), `roll` est positif lorsque le bord droit est abaissé, et `yaw` est la direction du bord supérieur dans le sens des aiguilles d’une montre à partir du nord magnétique. Tant qu’iOS n’a pas calibré la boussole, le champ magnétique et `yaw` manquent.

## Environnement

| Valeur | Clé | Unité | Résolution |
|---|---|---|---|
| Pression atmosphérique | `pressure` | hPa | 0,1 |

La pression atmosphérique nécessite l’autorisation « Mouvements et forme ».

La lumière ambiante (`light`) n’existe que sur Android ; iOS n’offre pas d’interface pour cela.

## Localisation

| Valeur | Clé | Unité | Résolution |
|---|---|---|---|
| Position | `latitude`, `longitude` | degré (WGS 84) | 0,00001 |
| Altitude | `altitude` | m au-dessus du niveau de la mer | 0,1 |
| Vitesse | `speed` | km/h | 0,1 |
| Cap | `course` | degré, dans le sens des aiguilles d’une montre à partir du nord | 1 |
| Précision de la localisation | `locationAccuracy` | m | 1 |

La localisation nécessite votre autorisation. Avec « Toujours », l’app continue d’envoyer aussi en arrière-plan (voir [Arrière-plan et localisation](background.md)).

## Activité

| Valeur | Clé | Unité | Résolution |
|---|---|---|---|
| Pas aujourd’hui | `steps` | nombre | 1 |
| Type d’activité | `activityType` | texte | – |

`steps` compte à partir de minuit, heure locale. `activityType` est l’un des textes `stationary`, `walking`, `running`, `cycling`, `automotive` ou `unknown` et est envoyé dès qu’iOS détecte une nouvelle activité. Une voiture à l’arrêt reste considérée comme `automotive`. Le groupe nécessite l’autorisation « Mouvements et forme ».

## Appareil

| Valeur | Clé | Unité | Résolution |
|---|---|---|---|
| Niveau de batterie | `batteryLevel` | 0 à 1 | 0,01 |
| En charge | `charging` | oui/non | – |
| Réseau | `network` | texte | – |
| État thermique | `thermalState` | texte | – |
| Mode économie d’énergie | `powerSaving` | oui/non | – |
| Volume de données | `dataMobileToday`, `dataWifiToday`, `dataMobileMonth`, `dataWifiMonth` | octet | 1000 |

`network` vaut `wifi`, `cellular`, `other` ou `none`. `thermalState` vaut `nominal`, `fair`, `serious` ou `critical`. Le volume de données est celui de l’app elle-même, aujourd’hui et pour le mois en cours (voir [Volume de données](data-volume.md)).

La puissance du signal cellulaire (`cellularSignal`) n’existe que sur Android ; iOS n’offre pas d’interface publique pour cela.

## Son

| Valeur | Clé | Unité | Résolution |
|---|---|---|---|
| Niveau sonore | `soundLevel` | dB | 1 |

L’app ne mesure que le volume sonore. Elle n’enregistre aucun son et n’en envoie aucun.

Le micro d’un téléphone n’est pas étalonné. Le niveau sonore est donc une estimation : le niveau de toutes les mesures depuis le dernier cycle par rapport à la pleine échelle, plus 100 dB. Une pièce calme donne environ 30 à 50, une conversation environ 60 à 70. Des téléphones différents peuvent s’écarter les uns des autres de quelques décibels.

L’app ne mesure le niveau sonore que lorsqu’elle est ouverte. iOS restreint le micro en arrière-plan ; en arrière-plan, la valeur manque donc.

## Santé

Des valeurs comme la fréquence cardiaque ou la saturation en oxygène provenant d’une montre sont prévues et arriveront dans une version ultérieure.

## Signal de test

| Valeur | Clé | Unité | Résolution |
|---|---|---|---|
| Compteur de cycles | `testCounter` | nombre | 1 |
| Sinus | `testSine` | −1 à 1 | 0,001 |

Le signal de test ne mesure rien. Il envoie des valeurs connues à l’avance, afin que vous puissiez vérifier dans optiCLOUD si tout est arrivé, par exemple lors d’un test en arrière-plan. Il ne nécessite aucune autorisation et n’est pas sélectionné par défaut.

`testCounter` commence à 1 à chaque démarrage de l’envoi et augmente de 1 à chaque cycle. `testSine` est un sinus d’une période par minute, calculé à partir de l’horodatage de la valeur.

Après le test, exportez la télémétrie de l’appareil dans optiCLOUD au format CSV et vérifiez-la avec le script [`check-test-signal.py`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/tools/check-test-signal.py) :

```bash
python3 check-test-signal.py device-data.csv
```

Il signale les valeurs perdues, les pauses pendant lesquelles l’app ne tournait pas, les redémarrages de l’envoi et les valeurs qui ne correspondent pas à leur horodatage.

## Plus de détails

La description complète avec toutes les formules et règles se trouve dans la spécification : [`docs/spec/sensors.md`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/sensors.md).

---

Cette documentation est publiée sous licence [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.fr). Attribution : optiMEAS GmbH et optiMEAS Switzerland GmbH.
