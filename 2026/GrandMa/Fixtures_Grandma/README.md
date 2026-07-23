# Chemins — fixtures et scripts GrandMA3

## Fixtures (fichiers .xml natifs GrandMA3)

À copier dans :
```
C:\ProgramData\MALightingTechnology\gma3_library\fixturetypes\
```
Redémarrer GrandMA3 après le dépôt. Les fixtures apparaissent dans Library → votre fabricant (ex. Algam Lighting).

Détail complet de création : [GRANDMA3_FIXTURE_CREATION.md](GRANDMA3_FIXTURE_CREATION.md)

## Script d'export (grandma3_export.lua)

Dossier obligatoire (imposé par GrandMA3, pas un choix) :
```
C:\ProgramData\MALightingTechnology\gma3_library\datapools\plugins\<sous-dossier au choix>\
```
Ce dossier n'est **pas** le même que celui-ci (`Fixtures_Grandma`) — celui-ci est juste la copie
de travail/sauvegarde, jamais lu par GrandMA3. Il faut recopier `grandma3_export.lua` dans le
dossier plugins ci-dessus pour qu'il soit utilisable.

Mise en place dans GrandMA3 (Plugin Pool, pas une commande texte type `DoFile`) :
1. Créer un objet **Plugin** dans le Plugin Pool.
2. Y ajouter un **ComponentLua** avec :
   - `Installed = Yes`
   - `FilePath` = le sous-dossier utilisé ci-dessus
   - `FileName` = `grandma3_export.lua`
3. Exécuter le Plugin (clic/trigger sur l'objet dans le pool) pour lancer l'export.
4. Après toute modification du fichier en dehors de GrandMA3, exécuter la commande
   **`ReloadAllPlugins`** pour recharger le code sans redémarrer.

Source : [documentation Plugins GrandMA3](https://help.malighting.com/grandMA3/2.0/HTML/plugins.html)

## Fichiers générés par le script

Contrairement au dossier du script, le dossier de sortie est **entièrement libre** : c'est une
simple variable Lua en tête du fichier (`OUTPUT_DIR`), sans contrainte GrandMA3. Par défaut :
```
C:\Users\<vous>\Desktop\grandma-export\fixtures.csv
C:\Users\<vous>\Desktop\grandma-export\fixture_types.json
```
Modifiable librement — y compris pour pointer directement vers le dossier surveillé par Smode.

À pointer ensuite dans les attributs **Fixtures CSV** / **Fixture Types JSON** de l'objet `GrandmaFixtureConfig` côté Smode, puis déclencher **Reload**.

## Ajouter un nouveau type de fixture maison à l'export

Le script utilise une table fixe `FIXTURE_LAYOUTS` (offsets DMX par type + mode),
recopiée directement depuis les `.xml` de ce dossier plutôt que détectée dynamiquement
(l'API GrandMA3 pour lister les canaux d'un type de fixture depuis Lua n'est pas fiable/documentée).
Si vous créez un nouveau fixture type maison (nouveau `.xml`), ajoutez son entrée dans
`FIXTURE_LAYOUTS` en tête de `grandma3_export.lua`, avec les offsets 0-based de chaque
canal (Dimmer/R/G/B/W/Wheel) tels que définis dans le `<DMXMode>` du fichier XML.

## Vérification universe/adresse

`fix.patch` renvoie une chaîne `"universe.address"` — non confirmé si `universe` y est
1-based ou 0-based. Comparez la valeur `uni=` affichée en console (Command Line History)
avec la colonne "Univ" de la grille de patch GrandMA3 après un export ; ajustez le script
(+1/-1) si besoin.
