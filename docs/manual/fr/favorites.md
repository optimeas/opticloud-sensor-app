---
title: Favoris
description: Ouvrir directement et déjà connecté des Dashboards, des appareils et d’autres pages d’optiCLOUD depuis l’app optiCLOUD Sensor.
sidebar_label: Favoris
sidebar_position: 8
image: "/img/om_social_card.png"
keywords:
  - Favoris
  - Dashboard
  - Dashboard par défaut
  - Safari
last_update:
  date: 2026-10-27
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH et optiMEAS Switzerland GmbH
---

# Favoris

L’onglet **Favoris** ouvre des pages de l’application web optiCLOUD directement dans l’app, déjà connecté : Dashboards, appareils et listes. D’un seul geste, vous passez du téléphone aux données qu’il envoie.

## Ce que montre l’onglet

| Section | Contenu |
|---|---|
| tout en haut | Le Dashboard par défaut. S’il n’y en a pas, l’**Accueil optiCLOUD**. |
| **Dans optiCLOUD** | Les favoris que vous avez créés dans l’application web optiCLOUD, dans le même ordre |
| **Sur ce téléphone** | Les pages que vous avez ajoutées dans l’app |

Vous modifiez les favoris d’optiCLOUD dans l’application web ; l’app ne fait que les afficher. Elle les lit chaque fois que vous ouvrez l’onglet et lorsque vous tirez la liste vers le bas. Sans réseau, elle affiche le dernier état.

Sans connexion, l’onglet n’affiche que la première entrée.

## Ajouter des favoris sur le téléphone

Touchez **+** en haut à droite et choisissez :

- **Dashboard …** : un Dashboard du projet dans lequel vous êtes connecté,
- **Appareil …** : un appareil de ce projet, de n’importe quel type,
- **Appareil de ce téléphone** : l’appareil auquel ce téléphone envoie,
- **Liste des Dashboards** ou **Liste des appareils** : les listes dans optiCLOUD.

Avec **Modifier**, vous changez l’ordre et supprimez des favoris. Les favoris du téléphone appartiennent au serveur et au Tenant ; si vous vous connectez à un autre Tenant, vous voyez les siens.

Maintenez le doigt sur un favori d’optiCLOUD pour le reprendre avec **Ajouter à ce téléphone**.

## Dashboard par défaut

Maintenez le doigt sur un Dashboard et choisissez **Définir comme Dashboard par défaut**. Il apparaît alors tout en haut. Avec **Retirer le Dashboard par défaut** sur la première entrée, l’app y affiche de nouveau l’Accueil optiCLOUD.

Le Dashboard par défaut peut aussi être défini au moyen du Shared Attribute `dashboard` de l’appareil (voir [L’appareil dans optiCLOUD](device-in-opticloud.md)). Il ne peut alors plus être modifié sur le téléphone.

## Ouvrir des pages

Une page d’optiCLOUD s’ouvre dans l’app, connectée avec votre compte, dans le Tenant et le projet dans lesquels vous êtes connecté dans l’app. Vous n’avez pas besoin de vous reconnecter.

- Avec **Retour** et **Recharger** en bas, vous naviguez dans la page ; **OK** la ferme.
- **Ouvrir dans Safari** ouvre la page actuelle dans Safari. Vous vous y connectez vous-même.
- L’app ne conserve rien de la page sur le téléphone. Lorsque vous la fermez, la connexion qu’elle contient prend fin.
- Un favori qui mène à un autre site web s’ouvre dans Safari.
- Un appareil d’un autre projet ou une page d’un autre Tenant ne s’ouvre pas.

---

Cette documentation est publiée sous licence [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.fr). Attribution : optiMEAS GmbH et optiMEAS Switzerland GmbH.
