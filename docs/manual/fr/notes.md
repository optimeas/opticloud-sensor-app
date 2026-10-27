---
title: Notes
description: Écrire des notes sur l’appareil dans optiCLOUD avec l’app optiCLOUD Sensor, dans l’app ou avec Siri, même sans réseau.
sidebar_label: Notes
sidebar_position: 9
image: "/img/om_social_card.png"
keywords:
  - note
  - note rapide
  - Siri
  - raccourci
last_update:
  date: 2026-10-27
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH et optiMEAS Switzerland GmbH
---

# Notes

Une note consigne ce qui se passe en ce moment : une observation, une panne, le début d’un trajet de mesure. optiCLOUD l’enregistre comme note sur l’appareil auquel ce téléphone envoie et l’affiche à côté des valeurs mesurées.

Pour écrire, vous devez être connecté dans l’app. La note appartient à votre compte.

## Écrire une note dans l’app

1. Dans l’onglet **Live**, touchez le symbole **Nouvelle note** en haut à droite.
2. Écrivez le texte. Le curseur est déjà dans le champ **Note**.
3. Touchez **Enregistrer**.

Un titre n’est pas nécessaire. Si vous laissez **Titre (facultatif)** vide, l’app prend la première ligne du texte comme titre, au plus 60 caractères. Sous le texte, vous voyez quel sera le titre.

Sous **Détails**, vous réglez **État** et **Priorité**. Sans modification, l’état est **Créé** et la priorité **Moyenne**.

## Une note avec Siri ou un raccourci

L’app propose deux raccourcis :

| Raccourci | Ce qu’il fait |
|---|---|
| **Nouvelle note optiCLOUD** | Demande le texte et enregistre la note sans ouvrir l’app. Avec Siri, vous dictez le texte. |
| **Nouvelle note optiCLOUD dans l’app** | Ouvre l’app avec le formulaire d’une nouvelle note |

Dites par exemple « Dis Siri, nouvelle note dans optiCLOUD Sensor ». Siri demande « Que doit dire la note ? », vous dictez le texte, et Siri vous dit si la note est déjà dans optiCLOUD ou sera envoyée plus tard.

Vous trouvez aussi les deux raccourcis dans Spotlight et dans l’app Raccourcis. Sur un iPhone avec bouton Action, vous pouvez attribuer l’un d’eux au bouton dans Réglages sous **Bouton Action**.

## Ce qui est enregistré avec la note

- le moment de l’enregistrement, à la fin du texte sous la forme `2026-10-24 15:42 +02:00`,
- la position du téléphone, si vous avez autorisé la localisation pour l’app. L’app l’attend au plus 5 secondes et enregistre sinon la note sans position.

optiCLOUD attribue à une note l’heure de son arrivée. Si elle arrive plus tard, le moment de l’enregistrement figure tout de même dans le texte.

## Sans réseau

L’app enregistre d’abord chaque note sur le téléphone et l’envoie de là. Sans réseau, elle reste sur le téléphone et part dès qu’optiCLOUD est de nouveau joignable. L’app réessaie chaque minute, quand elle passe au premier plan et après une connexion.

Dans l’onglet **Live**, vous voyez combien de notes attendent encore. Si votre connexion a expiré, reconnectez-vous ; les notes partent ensuite. Après une déconnexion, elles restent sur le téléphone et ne partent que lorsque vous vous reconnectez avec le même compte.

Si optiCLOUD refuse une note, par exemple parce que l’appareil n’existe plus, l’app la met de côté. Dans l’onglet **Diagnostic** sous **Notes**, vous la voyez avec le message d’optiCLOUD et pouvez la renvoyer ou la supprimer (voir [Diagnostic](diagnosis.md)). L’app ne supprime jamais une note d’elle-même.

## Après l’envoi

Vous modifiez et archivez une note envoyée dans optiCLOUD. L’app ne la modifie plus. Les notes ne peuvent pas être supprimées une à une dans optiCLOUD ; elles sont supprimées avec leur appareil.

---

Cette documentation est publiée sous licence [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.fr). Attribution : optiMEAS GmbH et optiMEAS Switzerland GmbH.
