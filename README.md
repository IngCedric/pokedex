# PokéDex

Application Flutter connectée à un vrai backend : authentification, données
issues d'APIs REST publiques, cache local et mode hors-ligne.

## Sommaire

- [Fonctionnalités](#fonctionnalités)
- [APIs utilisées](#apis-utilisées)
- [Architecture](#architecture)
- [Configuration du projet](#configuration-du-projet)
- [Tests](#tests)

## Fonctionnalités

- **Authentification** (login / register / logout) via Supabase Auth (JWT),
  avec injection automatique du token et refresh de session.
- **3 écrans de données** issus de deux APIs REST différentes :
  - Liste des pokémons (PokeAPI, pagination infinie)
  - Détail d'un pokémon (PokeAPI : types, stats, capacités, taille/poids)
  - Favoris (table Supabase, propre à chaque utilisateur)
- **Cache local avec Hive** pour les listes, les détails et les favoris.
- **Mode hors-ligne** : si l'appareil n'a pas de réseau (ou que l'API ne
  répond pas), l'app affiche les dernières données mises en cache, avec un
  bandeau "Mode hors-ligne — données en cache".
- **Gestion des erreurs réseau** traduite en messages clairs pour
  l'utilisateur (timeout, pas de connexion, 401, 404, 500...).

## APIs utilisées

| API | Usage | Auth |
|---|---|---|
| [PokeAPI](https://pokeapi.co) | Liste et détail des pokémons | Aucune (API publique) |
| [Supabase](https://supabase.com) (PostgREST + Auth) | Comptes utilisateurs, table `favorites` | JWT (Bearer token) |

## Architecture

Le projet suit une architecture **feature-first**, chaque feature étant elle
même découpée en 3 couches (`domain` / `data` / `presentation`) :

```
lib/
├── core/                     # Code transverse
│   ├── config/                 # Lecture du .env
│   ├── network/                # Dio clients + intercepteur d'auth
│   ├── local/                  # Initialisation Hive
│   ├── errors/                 # AppException (erreurs -> message utilisateur)
│   └── widgets/                # ErrorView, OfflineBanner, ...
├── features/
│   ├── auth/
│   │   ├── domain/              # Entité AppUser + interface AuthRepository
│   │   ├── data/                # Implémentation Supabase Auth
│   │   └── presentation/        # AuthProvider, LoginPage, RegisterPage
│   ├── pokemon/
│   │   ├── domain/               # Entités Pokemon / PokemonDetail + interface repository
│   │   ├── data/                 # Remote (PokeAPI) + Local (Hive) + Repository
│   │   └── presentation/         # Providers + pages liste/détail
│   └── favorites/
│       ├── domain/
│       ├── data/                 # Remote (Supabase REST) + Local (Hive) + Repository
│       └── presentation/
└── router/                   # go_router (redirections selon l'état d'auth)
```

### Repository pattern

Chaque feature expose une interface de repository dans `domain/` (ex.
`PokemonRepository`), implémentée dans `data/` en combinant une source
distante (`RemoteDataSource`, via Dio) et une source locale (`LocalDataSource`,
via Hive). Cela permet de :

- garder la couche `presentation` totalement indépendante de PokeAPI /
  Supabase / Hive ;
- basculer automatiquement sur le cache quand le réseau est indisponible ou
  que l'appel distant échoue ;
- mocker facilement `RemoteDataSource`, `LocalDataSource` et `NetworkInfo`
  dans les tests, sans mocker Dio ou Hive directement.

### Injection du token et refresh

`lib/core/network/auth_interceptor.dart` intercepte chaque requête Dio vers
Supabase :

1. il ajoute le header `Authorization: Bearer <token>` à partir de la session
   Supabase courante ;
2. si le serveur répond `401`, il appelle `refreshSession()` puis rejoue la
   requête une seule fois avec le nouveau token.

La session Supabase elle-même (refresh automatique en arrière-plan, 
persistance) est gérée par le SDK `supabase_flutter`.

### State management et injection de dépendances

- `get_it` (`lib/core/di/service_locator.dart`) construit et centralise les
  dépendances "métier" sans état Flutter : `NetworkInfo`, les deux clients
  Dio, les data sources et les repositories. Chaque feature ne connaît que
  les interfaces `domain/`, jamais les implémentations concrètes entre elles.
- `provider` (ChangeNotifier) reste responsable des objets qui doivent vivre
  dans l'arbre de widgets (cycle de vie, `dispose()`, rebuilds) : un provider
  par écran/feature (`PokemonListProvider`, `PokemonDetailProvider`,
  `FavoritesProvider`, `AuthProvider`), injectés au-dessus du router pour
  rester partagés entre écrans (ex. l'icône "favori" sur la liste et sur le
  détail).

### Égalité de valeur

Les entités (`Pokemon`, `PokemonDetail`, `FavoritePokemon`, `AppUser`)
étendent `Equatable` : deux instances avec les mêmes champs sont égales,
ce qui simplifie les comparaisons dans les tests et évite les bugs de
rebuild inutiles côté UI.

### Détection réseau

`ConnectivityNetworkInfo` (`lib/core/network/network_info.dart`) ne se fie
pas uniquement à l'état de l'interface réseau (`connectivity_plus`), qui
peut être "connecté" sans accès internet réel (portail captif, wifi sans
internet...). Il fait en plus une requête HTTP légère vers l'API Supabase
avec un timeout court : seule une vraie erreur de connexion (timeout, DNS,
hôte injoignable) est traitée comme "hors-ligne" ; n'importe quelle réponse
HTTP (même une erreur 4xx) prouve que le réseau fonctionne.

## Configuration du projet

### 1. Prérequis

- Flutter 3.35+ / Dart 3.9+
- Un projet [Supabase](https://supabase.com) (gratuit)

### 2. Créer la table `favorites`

Dans le dashboard Supabase → **SQL Editor**, exécute le script
[`supabase/migration.sql`](supabase/migration.sql). Il crée la table
`favorites` et active la Row Level Security (RLS) dessus.

**Pourquoi la RLS et comment elle fonctionne ici :** sans RLS, n'importe
quel utilisateur authentifié pourrait lire ou modifier les favoris de
n'importe qui d'autre via l'API REST (PostgREST expose directement la
table). La RLS ajoute un filtre *au niveau de PostgreSQL lui-même* — donc
impossible à contourner depuis le client — appliqué à chaque requête :

```sql
using (auth.uid() = user_id)       -- pour SELECT et DELETE
with check (auth.uid() = user_id)  -- pour INSERT
```

`auth.uid()` est l'identifiant de l'utilisateur déduit du JWT envoyé dans le
header `Authorization: Bearer <token>` (voir `AuthInterceptor`). Concrètement :
un `GET /favorites` ne renvoie jamais que les lignes où `user_id` correspond
à l'utilisateur connecté, et un `INSERT`/`DELETE` sur la ligne d'un autre
utilisateur est rejeté par PostgreSQL avec une erreur `42501` — même si un
utilisateur malveillant appelait l'API directement (Postman, curl...) en
contournant complètement l'app Flutter.

Pour vérifier que la table et les policies sont bien en place, dans **Table
Editor → favorites**, l'icône RLS doit indiquer "Enabled".

### 3. Variables d'environnement

Copie `.env.example` en `.env` à la racine du projet et renseigne tes
identifiants Supabase (**Project Settings → API**) :

```
SUPABASE_URL=https://xxxx.supabase.co/rest/v1/
SUPABASE_ANON_KEY=xxxxx
```

`.env` est ignoré par git (`.gitignore`) : ne commite jamais tes propres
identifiants.

### 4. Lancer l'app

```bash
flutter pub get
flutter run
```

## Tests

Tests unitaires sur la couche repository (mockée avec `mocktail`, sans
dépendance à un vrai réseau/backend) :

```bash
flutter test
```

- `test/features/pokemon/pokemon_repository_impl_test.dart` : succès réseau
  + mise en cache, repli sur le cache si l'API échoue, mode hors-ligne, erreur
  si rien n'est en cache.
- `test/features/favorites/favorites_repository_impl_test.dart` : lecture/
  écriture des favoris en ligne et hors-ligne, gestion du 401.
- `test/features/auth/auth_repository_impl_test.dart` : login/register/logout
  et traduction des erreurs Supabase en messages utilisateur.
