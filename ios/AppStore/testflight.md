# Public TestFlight

The texts for external testing in TestFlight, as they are entered in App Store Connect under **TestFlight → Test Information** and for each build under **What to Test**. English is the source; German, French, Italian, and Spanish follow it. They address the reader as the app does (see [`docs/manual/TRANSLATING.md`](../../docs/manual/TRANSLATING.md)).

Contact details, the sign-in for the review, and the feedback address are entered only in App Store Connect. They never go into this repository.

## Checklist

Done:

- Builds go to App Store Connect with `Tools/upload-testflight.sh`; the app declares that it uses no non-exempt encryption.
- Every permission has a usage text in five languages; the app and the widget extension have privacy manifests.
- The app shows the open-source licenses and a privacy page in its manual.

Still to do in App Store Connect:

1. **Test Information:** the beta app description and the feedback e-mail address for each language, the privacy policy URL, and optionally the marketing URL.
2. **Beta App Review Information:** a contact person with name, phone, and e-mail, and the sign-in for the review: an optiCLOUD account on a server the reviewers can reach, with a tenant and a project in which it may create a device. Enter the address of the server, the e-mail address, and the password, and add the review notes below.
3. **External group:** create a group, add the build, and submit it for Beta App Review. The first build of each version is reviewed; later builds of the same version usually go out without a new review.
4. **Public link:** after the review, switch on the public link of the group and, if wanted, limit the number of testers.

## Privacy policy URL

The privacy page of the manual, `docs/manual/<language>/privacy.md`, serves once it is published on the optiMEAS documentation site.

## Beta app description

### English

optiCLOUD Sensor turns your iPhone into a sensor for optiCLOUD, the IoT platform by optiMEAS. Choose what the phone measures – motion, location, air pressure, sound level, activity, and the state of the device – and the app sends it live to your device in optiCLOUD, also with the screen locked. Without a network, the values wait on the phone and follow later with their original time.

You need an optiCLOUD account with the right to create devices. The app signs you in, lets you pick the tenant, the project, and the device, and binds the device to this phone.

Also in the app: quick notes by tap or with Siri, your dashboards and favorites in one tab, a Live Activity on the Lock Screen while sending, and a control for Control Center. The app is open source under the MIT license.

### Deutsch

optiCLOUD Sensor macht dein iPhone zu einem Sensor für optiCLOUD, die IoT-Plattform von optiMEAS. Wähle, was das Telefon misst – Bewegung, Standort, Luftdruck, Schallpegel, Aktivität und den Zustand des Geräts –, und die App sendet es live an dein Gerät in optiCLOUD, auch bei gesperrtem Bildschirm. Ohne Netz warten die Werte auf dem Telefon und kommen später mit ihrer ursprünglichen Zeit nach.

Du brauchst ein optiCLOUD-Konto mit dem Recht, Geräte anzulegen. Die App meldet dich an, lässt dich Tenant, Projekt und Gerät wählen und bindet das Gerät an dieses Telefon.

Außerdem in der App: Schnellnotizen per Tippen oder mit Siri, deine Dashboards und Favoriten in einem Tab, eine Live-Aktivität auf dem Sperrbildschirm während des Sendens und ein Steuerelement für das Kontrollzentrum. Die App ist Open Source unter der MIT-Lizenz.

### Français

optiCLOUD Sensor transforme votre iPhone en capteur pour optiCLOUD, la plateforme IoT d’optiMEAS. Choisissez ce que le téléphone mesure – mouvement, position, pression atmosphérique, niveau sonore, activité et état de l’appareil – et l’app l’envoie en direct à votre appareil dans optiCLOUD, même écran verrouillé. Sans réseau, les valeurs attendent sur le téléphone et suivent plus tard avec leur heure d’origine.

Vous avez besoin d’un compte optiCLOUD avec le droit de créer des appareils. L’app vous connecte, vous laisse choisir le Tenant, le projet et l’appareil, et lie l’appareil à ce téléphone.

Également dans l’app : des notes rapides d’un toucher ou avec Siri, vos Dashboards et favoris dans un onglet, une activité en direct sur l’écran verrouillé pendant l’envoi et une commande pour le centre de contrôle. L’app est open source sous licence MIT.

### Italiano

optiCLOUD Sensor trasforma il tuo iPhone in un sensore per optiCLOUD, la piattaforma IoT di optiMEAS. Scegli cosa misura il telefono – movimento, posizione, pressione atmosferica, livello sonoro, attività e stato del dispositivo – e l’app lo invia in tempo reale al tuo dispositivo in optiCLOUD, anche a schermo bloccato. Senza rete, i valori attendono sul telefono e arrivano più tardi con il loro orario originale.

Ti serve un account optiCLOUD con il diritto di creare dispositivi. L’app ti fa accedere, ti fa scegliere Tenant, progetto e dispositivo e collega il dispositivo a questo telefono.

Inoltre nell’app: note rapide con un tocco o con Siri, i tuoi Dashboard e preferiti in una scheda, un’attività in tempo reale sulla schermata di blocco durante l’invio e un controllo per il Centro di Controllo. L’app è open source con licenza MIT.

### Español

optiCLOUD Sensor convierte tu iPhone en un sensor para optiCLOUD, la plataforma IoT de optiMEAS. Elige qué mide el teléfono – movimiento, ubicación, presión atmosférica, nivel sonoro, actividad y el estado del dispositivo – y la app lo envía en directo a tu dispositivo en optiCLOUD, también con la pantalla bloqueada. Sin red, los valores esperan en el teléfono y llegan más tarde con su hora original.

Necesitas una cuenta de optiCLOUD con permiso para crear dispositivos. La app inicia tu sesión, te deja elegir el Tenant, el proyecto y el dispositivo, y vincula el dispositivo a este teléfono.

Además en la app: notas rápidas con un toque o con Siri, tus Dashboards y favoritos en una pestaña, una Actividad en Vivo en la pantalla bloqueada mientras envía y un control para el centro de control. La app es de código abierto con licencia MIT.

## What to test – version 0.9.0

### English

Thank you for testing! Please try:

- Sign in, pick a device, and start sending. Check in optiCLOUD that the values arrive.
- Lock the phone for a while, or take it along on the way. Sending should go on; without a network the values follow later.
- The Live Activity on the Lock Screen and in the Dynamic Island, and its Stop button.
- The control "Send to optiCLOUD" in Control Center.
- A quick note from the Live tab, or with Siri: "New note in optiCLOUD Sensor".

Please report what does not work, with the time it happened. The Diagnosis tab has a log you can share.

### Deutsch

Danke fürs Testen! Bitte probiere:

- Melde dich an, wähle ein Gerät und starte das Senden. Prüfe in optiCLOUD, ob die Werte ankommen.
- Sperre das Telefon eine Weile oder nimm es mit auf den Weg. Das Senden sollte weiterlaufen; ohne Netz kommen die Werte später nach.
- Die Live-Aktivität auf dem Sperrbildschirm und in der Dynamic Island und ihren Knopf Stopp.
- Das Steuerelement „An optiCLOUD senden“ im Kontrollzentrum.
- Eine Schnellnotiz aus dem Tab Live oder mit Siri: „Neue Notiz in optiCLOUD Sensor“.

Melde bitte, was nicht funktioniert, mit der Uhrzeit. Im Tab Diagnose findest du ein Protokoll, das du teilen kannst.

### Français

Merci de tester ! Essayez :

- Connectez-vous, choisissez un appareil et lancez l’envoi. Vérifiez dans optiCLOUD que les valeurs arrivent.
- Verrouillez le téléphone un moment ou emportez-le en route. L’envoi doit continuer ; sans réseau, les valeurs suivent plus tard.
- L’activité en direct sur l’écran verrouillé et dans la Dynamic Island, et son bouton Arrêter.
- La commande « Envoyer à optiCLOUD » dans le centre de contrôle.
- Une note rapide depuis l’onglet Live, ou avec Siri : « Nouvelle note dans optiCLOUD Sensor ».

Signalez ce qui ne fonctionne pas, avec l’heure. L’onglet Diagnostic contient un journal que vous pouvez partager.

### Italiano

Grazie per il test! Prova:

- Accedi, scegli un dispositivo e avvia l’invio. Controlla in optiCLOUD che i valori arrivino.
- Blocca il telefono per un po’ o portalo con te. L’invio dovrebbe continuare; senza rete i valori arrivano più tardi.
- L’attività in tempo reale sulla schermata di blocco e nella Dynamic Island, e il suo pulsante Stop.
- Il controllo «Invia a optiCLOUD» nel Centro di Controllo.
- Una nota rapida dal tab Live o con Siri: «Nuova nota in optiCLOUD Sensor».

Segnala cosa non funziona, con l’orario. Nel tab Diagnostica trovi un registro che puoi condividere.

### Español

¡Gracias por probar! Prueba:

- Inicia sesión, elige un dispositivo y empieza a enviar. Comprueba en optiCLOUD que llegan los valores.
- Bloquea el teléfono un rato o llévalo contigo. El envío debería continuar; sin red, los valores llegan más tarde.
- La Actividad en Vivo en la pantalla bloqueada y en la Dynamic Island, y su botón Detener.
- El control «Enviar a optiCLOUD» en el centro de control.
- Una nota rápida desde la pestaña Live, o con Siri: «Nueva nota en optiCLOUD Sensor».

Informa de lo que no funcione, con la hora. En la pestaña Diagnóstico hay un registro que puedes compartir.

## Review notes

English only; entered under **Beta App Review Information → Review Notes**, with the sign-in in the fields for it.

> optiCLOUD Sensor is the companion app of optiCLOUD, the IoT platform of optiMEAS. It sends sensor values of the phone to a device in optiCLOUD.
>
> To test: on the start screen, tap Sign In, enter the server address, e-mail address, and password given in the sign-in fields, pick the tenant and the project, and create a new device or pick an existing one. Then tap Start Sending on the Live tab. The values appear in the optiCLOUD web application at the same address, signed in with the same account.
>
> Background location: the app uses the location background mode only while the user has switched sending on and has selected location as a sensor. The location is a measured value that is sent to the user's own optiCLOUD device; it is also what keeps the other selected sensors sending with the screen locked. The app asks for "Always" only after "While Using the App" and explains why in the permission text. Sending stops with the Stop Sending button, the Stop button of the Live Activity, or the control in Control Center.
>
> Microphone: the app measures the sound level only when it is selected; no audio is recorded or sent.
>
> The source code is public: https://github.com/optimeas/opticloud-sensor-app
