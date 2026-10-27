# Favorites

**Status: draft.** The interfaces were read from the optiCLOUD source on 2026-10-27 and are not yet tested against an optiCLOUD server.

The tab Favorites lists pages of the optiCLOUD web application. A tap opens the page in a browser view of the app, already signed in with the user's account, so that it shows exactly this page (see [Opening a page](#opening-a-page)).

## Entries

The tab has three sections, in this order.

1. **Default dashboard.** With a default dashboard set (see [configuration.md](configuration.md)), the first entry opens `/dashboards/<dashboard id>`. Its title is the `title` from `GET /api/dashboard/info/<dashboard id>`; while it cannot be read, the entry says "Default dashboard". Without a default dashboard, the entry opens the home view `/home`.
2. **Favorites from optiCLOUD.** The favorites the user keeps in the web application, in their order there. The app only reads them. They are changed in the web application.
3. **Favorites on this phone.** Pages the user picks in the app. They are kept on the phone only.

The sections 2 and 3 need a signed-in user. Without one, the app shows only the first entry and a note that it needs a sign-in for the rest.

## Favorites from optiCLOUD

The app reads the signed-in user with `GET /api/auth/user`. The favorites are the list `additionalInfo.favoritePages`; it can be missing or empty. Each favorite has:

| Member | Meaning |
| --- | --- |
| `title` | The name the user gave it |
| `path` | Where it leads, see [Address of a page](#address-of-a-page) |
| `icon` | The name of an icon of the web application. The apps do not use it; they choose a symbol of their own platform by the kind of page. |
| `isLandingPage` | The web application opens this favorite after sign-in. The apps ignore it. |

- A favorite without `title` or with a `path` the app cannot open is left out.
- Favorites belong to the user, not to a tenant. A favorite can lead to a page of another tenant than that of the app's session.
- The app reads the favorites when the tab appears and when the user pulls to refresh. It keeps the last list, so that the tab also shows it without a network.

## Favorites on this phone

The user adds a page from one of these lists:

| Kind | Path | Title | Source |
| --- | --- | --- | --- |
| Dashboard | `/dashboards/<id>` | `title` of the dashboard | `GET /api/dashboards?projectId=<projectId>&limit=<n>&page=<p>` |
| Device | `/devices/<id>` | `name` of the device | The device list of [sign-in.md](sign-in.md#listing-devices), of every type |
| Device of this phone | `/devices/<id>` | name of the device | The device the phone sends to |
| Dashboard list | `/dashboards` | "Dashboards" | fixed |
| Device list | `/devices` | "Devices" | fixed |

- The lists refer to the project of the session, `projectId` from the access token (see [sign-in.md](sign-in.md#the-session)).
- The dashboard list is a page like the device list: `{ "data": [ … ], "hasNext": true }`, pages counted from 0, an optional `textSearch` filters by the start of the title. Each dashboard has `id` and `title`.
- The app keeps for each favorite its kind, its title, and its path. The favorites belong to the address of the web application and the tenant; the app shows those of the current session only.
- The user can remove favorites and change their order. A page that is already a favorite on this phone is not added a second time.

## Default dashboard

The user sets a dashboard of the second or third section as the default dashboard, or removes the default. This is not possible while optiCLOUD manages the setting through the shared attribute `dashboard` (see [messages.md](messages.md)).

## Address of a page

A `path` that starts with `/` is a page of the web application. Its address is the address of the web application followed by the path, with query and fragment as they are. Any other `path` is a complete address; the app opens it only if it starts with `https://` or `http://`, and leaves the favorite out otherwise. The test vectors are in [`favorite-url.json`](vectors/favorite-url.json).

## Opening a page

**Depends on internal behavior of the web application.** optiCLOUD offers no supported way to open a page of the web application signed in. optiMEAS is asked for one (see [Open points](#open-points)); until then the app uses the way described here, which can break when the web application changes.

- A page of the web application opens in a browser view of the app. A complete address of another site opens in the browser of the system.
- Before it opens the page, the app gets a second session of the same user and role: it renews its session with `POST /api/auth/token` and its refresh token, and hands the new token pair to the browser view. The app keeps its own token pair; on the server a refresh token stays valid when it is used.
- The web application keeps its session in the local storage of the browser, under `jwt_token` and `refresh_token`, and the moments at which they expire, in milliseconds since 1970 by the clock of the phone, under `jwt_token_expiration` and `refresh_token_expiration`. The app writes these four entries before the scripts of the page run, only for the address of the web application, and only at the first load of the view.
- The browser view keeps no website data on the phone. The second session ends when the view is closed.
- Without a session of the app, the page opens with the sign-in of the web application.
- The browser view has a button that opens the current page in the browser of the system.

Neither the tokens nor the session appear in an address, so they do not reach the history of a browser or the logs of a web server. The sign-in of the web application also accepts `/login?accessToken=…&refreshToken=…`, the return of single sign-on, but it then opens its start page, not the page asked for, and the tokens would be part of the address; the app does not use it.

The web application works in the tenant and the project of the session. A device page of another project or a page of another tenant does not open; a dashboard of another project of the same tenant opens.

## Open points

1. Test `GET /api/auth/user`, the dashboard list, `GET /api/dashboard/info/<id>`, and the second session against an optiCLOUD server, with a tenant administrator and with a tenant user.
2. optiMEAS is asked for a supported way to open a page of the web application signed in, for example a one-time code that the app gets through the REST interface and that the web application exchanges for a session before it opens a return address. The apps then switch to it.
