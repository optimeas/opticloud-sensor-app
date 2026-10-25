---
title: Arrière-plan et localisation
description: Comment l’app optiCLOUD Sensor continue d’envoyer lorsque l’écran est verrouillé et pourquoi elle a besoin pour cela de la localisation.
sidebar_label: Arrière-plan et localisation
sidebar_position: 5
image: "/img/om_social_card.png"
keywords:
  - arrière-plan
  - localisation
  - autorisation de localisation
  - iOS
  - batterie
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Arrière-plan et localisation

iOS met fin aux apps en arrière-plan au bout de peu de temps. Une app ne peut continuer à fonctionner en arrière-plan que si elle a pour cela une raison reconnue. optiCLOUD Sensor utilise pour cela la localisation : tant que l’app mesure et envoie la localisation, elle peut continuer à fonctionner, et avec elle tous les autres capteurs sélectionnés.

La localisation n’est pas un prétexte, mais une mesure comme une autre. L’app vous dit ouvertement pourquoi elle en a besoin, et iOS vous montre à tout moment quand elle l’utilise.

## Ce que vous devez régler

1. Sélectionnez le groupe **Localisation** sous **Réglages → Envoi → Capteurs** (sélectionné par défaut).
2. Démarrez l’envoi. iOS demande l’accès à la localisation ; autorisez-le « Lorsque l’app est active ».
3. Peu après, iOS demande une seule fois si l’app peut utiliser la localisation « Toujours ». Autorisez-le.

Vous voyez l’état actuel sous **Réglages → Envoi → Accès à la localisation** tant que la localisation est sélectionnée. Si vous avez refusé l’accès, vous y trouvez **Ouvrir les Réglages**. Par la suite, vous le modifiez dans l’app Réglages d’iOS sous **optiCLOUD Sensor → Position** ; choisissez-y **Toujours**.

| Accès à la localisation | Ce qui se passe |
|---|---|
| **Toujours** | L’app envoie aussi lorsque l’écran est verrouillé et lorsque vous utilisez une autre app. |
| **Lorsque l’app est active** | L’app envoie tant qu’elle est au premier plan. |
| **Jamais** | L’app n’envoie pas la localisation, et n’envoie que tant qu’elle est au premier plan. |

## Ce que vous voyez sur le téléphone

Tant que l’app utilise la localisation, iOS affiche une flèche dans la barre d’état à côté de l’heure. C’est voulu : vous voyez ainsi toujours que l’app mesure. Si vous arrêtez l’envoi, la flèche disparaît.

## Arrêter l’envoi en arrière-plan

Arrêtez l’envoi dans l’onglet **Live** avec **Arrêter l’envoi**.

Balayer l’app vers le haut dans le sélecteur d’apps ne suffit **pas**. L’envoi est un réglage qui survit à un redémarrage de l’app : lorsque l’app redémarre, elle continue d’envoyer. C’est intentionnel, car un point de mesure ne doit pas tomber en panne simplement parce que l’app a été fermée entre-temps.

## Ce qui manque en arrière-plan

- **Niveau sonore :** iOS restreint le micro en arrière-plan. L’app ne le mesure que lorsqu’elle est ouverte.
- **Vue en direct :** les valeurs de l’onglet **Live** ne sont mises à jour que lorsque vous rouvrez l’app. Elles continuent néanmoins d’arriver en continu dans optiCLOUD.

## Batterie

La mesure de la localisation en arrière-plan consomme de l’énergie. Combien dépend du téléphone, de la réception et de la fréquence d’envoi. Pour les longues mesures, un chargeur est utile. Vous pouvez suivre vous-même le niveau de batterie dans optiCLOUD avec le groupe **Appareil**.

---

Cette documentation est publiée sous licence [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.fr). Attribution : optiMEAS GmbH et optiMEAS Switzerland GmbH.
