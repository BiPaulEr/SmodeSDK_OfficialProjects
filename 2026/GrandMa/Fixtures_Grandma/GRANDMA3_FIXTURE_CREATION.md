# GrandMA3 Fixture Creation Guide

How to create a fixture file for GrandMA3 2.3.2.0 from a fixture's DMX channel table.

> **Do NOT use GDTF files** — GrandMA3 2.3.2.0 has a parser bug that causes 0 modes or wrong
> footprint. Use the **native GrandMA3 XML format** instead (reverse-engineered from MA3 exports).

---

## Step 0 — Get the fixture datasheet

Ask the user one of these two questions before anything else:

**Option A — User provides the datasheet**
> "Do you have the fixture's user manual or datasheet (PDF)? If yes, share it and I will extract
> the DMX channel table from it."

**Option B — Search the internet**
> "What is the manufacturer name and exact fixture model? I will search for the datasheet online."

Search query to use:
```
"<MANUFACTURER> <MODEL> user manual DMX channel" filetype:pdf
```
or
```
site:<manufacturer-website>.com "<MODEL>" DMX manual
```

From the datasheet, extract:
- Manufacturer name and fixture model
- All available DMX modes (e.g. 9 CH, 14 CH)
- For each mode: channel number, function name, DMX range and description

Once you have the channel table, proceed to Step 1.

---

## Output location

Place the `.xml` file in:
```
C:\ProgramData\MALightingTechnology\gma3_library\fixturetypes\FIXTURENAME.xml
```
Restart GrandMA3. The fixture appears under **Library → your manufacturer**.

---

## Step 1 — Map each DMX channel to a GrandMA3 attribute and geometry

### GrandMA3 attribute names (differ from GDTF standard)

| Function              | GrandMA3 name        | Wrong name to avoid        |
|-----------------------|----------------------|-----------------------------|
| Pan                   | `Pan`                | default `800000` (centre)  |
| Tilt                  | `Tilt`               | default `800000` (centre)  |
| Dimmer / intensity    | `Dimmer`             | —                          |
| Red                   | `ColorRGB_R`         | ~~ColorAdd_R~~             |
| Green                 | `ColorRGB_G`         | ~~ColorAdd_G~~             |
| Blue                  | `ColorRGB_B`         | ~~ColorAdd_B~~             |
| White                 | `ColorRGB_W`         | ~~ColorAdd_W~~             |
| Pan/Tilt speed        | `PositionMSpeed`     | ~~PanTiltSpeed~~           |
| Shutter / strobe      | `ShutterStrobe`      | ~~Shutter1Strobe~~         |
| Color wheel           | `Color1`             | ~~ColorWheelSelect~~, ~~ColorMacro1~~, ~~Color1WheelIndex~~ |
| Gobo wheel (select)   | `Gobo1`              | ~~GoboWheel1~~, ~~Gobo1WheelIndex~~ |
| Gobo rotation (spin)  | `Gobo1WheelSpin`     | ⚠ à vérifier par export   |
| Prism (in/out)        | `Prism1`             | —                          |
| Prism indexed pos     | `Prism1Pos`          | GDTF confirmé              |
| Prism continuous spin | `Prism1PosRotate`    | GDTF confirmé              |
| Focus                 | `Focus`              | —                          |
| Zoom                  | `Zoom`               | GDTF confirmé              |
| Iris                  | `Iris`               | GDTF confirmé              |
| Frost / diffusion     | `Frost1`             | GDTF confirmé              |
| Effects / macros      | `Effects1`           | GDTF confirmé              |
| Inactive / reset      | `NoFeature`          | —                          |
| Fixture global reset  | `FixtureGlobalReset` | GDTF confirmé              |

> **Règle** : ne jamais improviser un nom d'attribut, même s'il "sonne bien" — GrandMA3 accepte
> silencieusement n'importe quel nom comme attribut custom, mais certains sous-systèmes (dont le
> rendu 3D) n'agissent que sur les noms du dictionnaire officiel. Toujours vérifier un nom dans
> `C:\ProgramData\MALightingTechnology\gma3_2.3.2\shared\resource\attribute_definitions.xml` avant
> de l'utiliser. Toujours mettre le **même** nom officiel sur `LogicalChannel` et `ChannelFunction`
> (comme Dimmer/ColorRGB_R) — pas besoin de nom "libre" séparé entre les deux.

### Geometry assignment

GrandMA3 uses dot-path geometry names. For a standard moving head:

```
Base                    static body
  └─ Base.Yoke          Pan axis
       └─ Base.Yoke.Head         Tilt axis, color wheel, gobo, prism, focus
            └─ Base.Yoke.Head.Beam    Dimmer, R/G/B/W, strobe
```

| Channel type              | Geometry               | Snap  | Default     |
|---------------------------|------------------------|-------|-------------|
| Pan                       | `Base.Yoke`            | No    | `800000`    |
| Tilt                      | `Base.Yoke.Head`       | No    | `800000`    |
| Pan/Tilt speed            | `Base.Yoke`            | No    | `000000`    |
| Dimmer                    | `Base.Yoke.Head.Beam`  | No    | `000000`    |
| Strobe                    | `Base.Yoke.Head.Beam`  | No    | `000000`    |
| R, G, B, W                | `Base.Yoke.Head.Beam`  | No    | `000000`    |
| Color wheel               | `Base.Yoke.Head`       | Yes   | `000000`    |
| Gobo wheel                | `Base.Yoke.Head`       | Yes   | `000000`    |
| Gobo spin                 | `Base.Yoke.Head`       | No    | `000000`    |
| Prism (in/out)            | `Base.Yoke.Head`       | Yes   | `000000`    |
| Prism pos / spin          | `Base.Yoke.Head`       | No    | `000000`    |
| Focus                     | `Base.Yoke.Head`       | No    | `000000`    |
| Zoom                      | `Base.Yoke.Head.Beam`  | No    | `000000`    |
| Iris                      | `Base.Yoke.Head.Beam`  | No    | `000000`    |
| Frost                     | `Base.Yoke.Head.Beam`  | No    | `000000`    |
| Effects / macros          | `Base`                 | Yes   | `000000`    |
| Reset / NoFeature         | `Base`                 | Yes   | `000000`    |

---

## Step 1b — Define wheel slots (color wheels, gobo wheels)

If the fixture has a **color wheel** or **gobo wheel**:
1. Lire le datasheet pour identifier chaque plage DMX et son nom
2. Déclarer les slots dans `<Wheels>` (nom + couleur)
3. Utiliser **une seule `ChannelFunction`** avec un `ChannelSet` par slot

### Where to find the DMX ranges

In the datasheet, look for the channel that says "color selection" or "gobo selection", e.g.:
```
CH6   0–79    Color selection (8 colors)
      80–139  Bi-color positions
      140–255 Auto color change
```
Identify each named position and its DMX center (midpoint of the slot range).

> **Règle** : ne jamais inventer/estimer une position intermédiaire que le datasheet ne documente
> pas explicitement. Si une plage DMX semble "vide" ou ambiguë, ne pas y voir une position
> manquante à deviner (cf. plus bas — un slot non documenté s'étend simplement jusqu'au suivant).
> Si le datasheet ne couvre pas toute la plage CH, vérifier physiquement (envoyer chaque valeur DMX
> candidate à la fixture réelle et observer) avant d'écrire quoi que ce soit dans le XML.

**Exemple — CH6 color wheel, 8 positions réelles :**

| Plage DMX | Nom     | Centre (dmx_center) |
|-----------|---------|----------------------|
| 0–9       | Open    | 5                    |
| 10–19     | Red     | 15                   |
| 20–29     | Yellow  | 25                   |
| 30–39     | Blue    | 35                   |
| 40–49     | Green   | 45                   |
| 50–59     | Orange  | 55                   |
| 60–69     | Magenta | 65                   |
| 70–79     | Cyan    | 75                   |
| 140–255   | Auto    | 140 (start)          |

Notez que 80–139 n'a pas de position nommée distincte — le dernier slot (Cyan) s'étend
naturellement jusqu'à 139 (GrandMA3 : chaque `ChannelSet` s'étend jusqu'au `DMXFrom` du suivant),
et 140 démarre le mode Auto. Ne pas ajouter de slots fictifs entre les deux.

### DMX value → GrandMA3 hex

```python
def hex_dmx(n):
    return f"{n:02X}0000"   # DMX 0 → "000000", DMX 15 → "0F0000", DMX 140 → "8C0000"
```

### Wheels section (slot names + display colors)

> Le nom de `<Wheel>` est **libre** — c'est juste une étiquette pour la table de couleurs/gobos,
> indépendante du dictionnaire d'attributs. Il n'est référencé que par `Wheel="..."` sur le
> `ChannelFunction` (voir plus bas), jamais par le nom d'attribut lui-même.

```xml
<Wheels>
  <Wheel Name="ColorWheel1">
    <Slot Name="Open"    Color="1.0000,1.0000,1.0000,1.0000"/>
    <Slot Name="Red"     Color="1.0000,0.0000,0.0000,1.0000"/>
    <Slot Name="Yellow"  Color="1.0000,1.0000,0.0000,1.0000"/>
    <Slot Name="Blue"    Color="0.0000,0.0000,1.0000,1.0000"/>
    <Slot Name="Green"   Color="0.0000,1.0000,0.0000,1.0000"/>
    <Slot Name="Orange"  Color="1.0000,0.5000,0.0000,1.0000"/>
    <Slot Name="Magenta" Color="1.0000,0.0000,1.0000,1.0000"/>
    <Slot Name="Cyan"    Color="0.0000,1.0000,1.0000,1.0000"/>
    <!-- … un Slot par position REELLE, dans l'ordre mesuré physiquement -->
  </Wheel>
  <Wheel Name="GoboWheel1">
    <Slot Name="Open"/>
    <Slot Name="Gobo 1"/>
    <!-- … un Slot par gobo, sans Color -->
  </Wheel>
</Wheels>
```

Gobo slots have no `Color` attribute. Slot order must match physical wheel order.

### DMXChannel — structure correcte (format natif GrandMA3)

> **Règle critique** : une seule `ChannelFunction` par `LogicalChannel`, avec des `ChannelSet`
> à l'intérieur. Plusieurs `ChannelFunction` = GrandMA3 ne sait pas quelles plages DMX envoyer.
> (Référence : `ayrton@alienpix-rs.xml` — fixture officielle MA3, voir PanMode/TiltMode/Shutter1)

```xml
<!-- Color wheel : Attribute="Color1" sur LogicalChannel ET ChannelFunction (nom officiel,
     identique aux deux niveaux, comme Dimmer/ColorRGB_R). Wheel="ColorWheel1" reste un nom
     de <Wheel> libre. -->
<DMXChannel Coarse="6" Default="050000" Geometry="Base.Yoke.Head">
  <LogicalChannel Attribute="Color1" Snap="Yes">
    <ChannelFunction Attribute="Color1" Wheel="ColorWheel1">
      <ChannelSet Name="Open"    WheelSlotIndex="1"/>
      <ChannelSet Name="Red"     DMXFrom="0A0000" WheelSlotIndex="2"/>
      <ChannelSet Name="Yellow"  DMXFrom="140000" WheelSlotIndex="3"/>
      <ChannelSet Name="Blue"    DMXFrom="1E0000" WheelSlotIndex="4"/>
      <ChannelSet Name="Green"   DMXFrom="280000" WheelSlotIndex="5"/>
      <ChannelSet Name="Orange"  DMXFrom="320000" WheelSlotIndex="6"/>
      <ChannelSet Name="Magenta" DMXFrom="3C0000" WheelSlotIndex="7"/>
      <ChannelSet Name="Cyan"    DMXFrom="460000" WheelSlotIndex="8"/>
      <ChannelSet Name="Auto"    DMXFrom="8C0000"/>
    </ChannelFunction>
  </LogicalChannel>
</DMXChannel>
```

Même schéma pour une roue de gobo : `LogicalChannel Attribute="Gobo1"` + `ChannelFunction
Attribute="Gobo1" Wheel="GoboWheel1"`.

Key rules:
- `Default` sur `DMXChannel` (pas sur `ChannelFunction`) = DMX center du premier slot
- Premier `ChannelSet` : pas de `DMXFrom` (implicitement 0)
- Suivants : `DMXFrom` = centre du slot en hex GrandMA3
- `WheelSlotIndex` commence à **1**, correspond à l'ordre des `<Slot>` dans `<Wheels>`
- Le slot "Auto" n'a **pas** de `WheelSlotIndex`
- `Wheel="..."` sur `ChannelFunction` lie au bon `<Wheel>` de la section Wheels

---

## Step 1c — Enregistrer le mode et la palette dans fixture_types.json

Deux fichiers séparés alimentent Smode, avec des rôles très différents :

| Fichier | Contenu | Qui l'écrit | Quand |
|---|---|---|---|
| `fixtures.csv` | Ce qui **change** : nom, type, univers, adresses de canaux, position x/y/z | `grandma3_export.lua`, **sans LLM** | À chaque re-patch/déplacement, aussi souvent que voulu |
| `fixture_types.json` | Ce qui **ne change pas** : le mode et, si roue de couleur, la palette RGB+DMX | Vous (ou une session LLM), **une fois** | Une seule fois à la création du type de fixture, ou si le type change |

`grandma3_export.lua` ne touche **jamais** à `fixture_types.json` — il lit les fixtures patchées en
direct depuis GrandMA3 et n'écrit que `fixtures.csv`. `fixture_types.json` est un fichier statique
à côté du `.lua`, dans ce dossier.

Ce qui suit est une **procédure mécanique** : en partant uniquement du tableau de canaux du
datasheet (déjà extrait en Step 0), elle doit produire un JSON correct sans avoir à improviser.

### 1. Déterminer `mode` depuis le tableau de canaux du datasheet

Regarder quels types de canaux le datasheet documente pour le mode choisi, et suivre cette table de
décision (dans l'ordre — s'arrêter à la première ligne qui correspond) :

| Le datasheet documente...                          | `mode`   |
|-----------------------------------------------------|----------|
| Un canal Cyan/Magenta/Yellow (mélange soustractif)   | `CMY`    |
| Un canal Amber/Blanc **en plus** de Rouge/Vert/Bleu  | `RGBWA` si Amber présent, sinon `RGBW` |
| Des canaux Rouge/Vert/Bleu (+ Blanc optionnel)       | `RGB` ou `RGBW` |
| Un seul canal "Color Wheel"/"Color selection"        | `ColorWheel` |
| Seulement un canal Dimmer/Intensity, pas de couleur  | `Dimmer` |

(Cette table reflète exactement le vocabulaire `ATTR_TO_COL`/`detectMode` déjà utilisé par
`grandma3_export.lua` — même logique des deux côtés, volontairement.)

### 2. Pour `ColorWheel` uniquement : construire la palette sans improviser

1. Relever dans le datasheet le tableau (plage DMX → nom de position), **tel quel** — ne pas
   ajouter de position qui n'y figure pas explicitement, même si une plage semble "vide"
   (cf. Step 1b : un slot non documenté s'étend simplement jusqu'au suivant, ce n'est pas une
   position manquante à deviner).
2. Pour chaque nom de position, chercher sa couleur RGB :
   - **Si le datasheet donne un swatch/code couleur exact** → l'utiliser tel quel.
   - **Sinon**, utiliser ce dictionnaire canonique pour les noms standard suivants **uniquement** :

     | Nom      | RGB             |
     |----------|-----------------|
     | Open/White/Clear | `255,255,255` |
     | Red      | `255,0,0`       |
     | Yellow   | `255,255,0`     |
     | Green    | `0,255,0`       |
     | Blue     | `0,0,255`       |
     | Cyan     | `0,255,255`     |
     | Magenta  | `255,0,255`     |
     | Orange   | `255,128,0`     |

   - **Si le nom ne correspond à aucune entrée du dictionnaire** (ex: une combinaison type
     "Lt Blue+Pink") → ne **jamais** inventer une valeur plausible pour la mettre dans le JSON.
     S'arrêter, et soit demander à l'utilisateur la couleur réelle, soit vérifier physiquement
     (envoyer le DMX candidat à la fixture réelle et observer) **avant** d'écrire quoi que ce soit
     dans `fixture_types.json`.
3. `dmx` = centre de la plage (milieu entre le début documenté et le début de la position
   suivante).
4. N'inclure `"auto"` que si le datasheet documente une plage de rotation automatique séparée.

### 3. Schéma JSON

Smode (`parseFixtureTypes` dans `FixtureConfig.h`) ne lit que `mode`, et pour `ColorWheel`,
`palette[].rgb` + `palette[].dmx` — rien d'autre. Le fichier ne contient donc que ça, pas de champ
de documentation superflu (nom de couleur, plage, statut confirmé... tout ça reste dans votre
raisonnement au moment de la création, pas dans le fichier) :

```json
{
  "NOMDUTYPE": {
    "mode": "RGBW"
  },
  "AUTRETYPE": {
    "mode": "ColorWheel",
    "palette": [
      { "rgb": [255,255,255], "dmx": 5  },
      { "rgb": [255,0,0],     "dmx": 15 }
    ]
  }
}
```

(Ceci est un **modèle** — les valeurs réelles viennent toujours de la lecture du datasheet de la
fixture en cours de création, jamais recopiées d'un exemple.)

Une fois ce fichier à jour, copiez-le (ou faites un lien) vers le dossier que Smode surveille — il
n'a besoin d'être régénéré que si vous ajoutez/modifiez un type de fixture, jamais à chaque export.

> **Si les couleurs exactes ne sont pas dans le datasheet** : utiliser Open/Red/Yellow/Green/Cyan/Blue/Magenta/Orange et vérifier physiquement en envoyant chaque centre DMX à la fixture.

---

## Step 2 — Generate the XML with the Python script

Use the helper functions below. **Every channel must have an explicit `Coarse` value** (1, 2, 3 …).
Omitting `Coarse` on any channel causes GrandMA3 to ignore it (footprint shows 1 instead of 9).

### Standard channels (everything except Pan/Tilt)

```python
def ch(geom, attr, snap="No", default="000000", coarse=None, fine=None):
    c  = f' Coarse="{coarse}"' if coarse is not None else ""
    f_ = f' Fine="{fine}"'     if fine   is not None else ""
    return (
        f'<DMXChannel{c}{f_} Geometry="{geom}">'
        f'<LogicalChannel Attribute="{attr}" Snap="{snap}">'
        f'<ChannelFunction Attribute="{attr}" Default="{default}"/>'
        f'</LogicalChannel></DMXChannel>'
    )
```

### Pan and Tilt — format spécial obligatoire

Pan et Tilt **doivent** avoir `PhysicalFrom`/`PhysicalTo` sur `ChannelFunction` pour que la vue
3D anime la fixture. Sans ça, GrandMA3 ne sait pas l'amplitude de rotation et rien ne bouge.

`Default="800000"` doit être sur `DMXChannel` (pas sur ChannelFunction) pour Pan/Tilt.

```python
def ch_pantilt(attr, coarse, physical_from, physical_to, geom, fine=None):
    c  = f'Coarse="{coarse}"'
    f_ = f' Fine="{fine}"' if fine is not None else ""
    geom_path = f'Base.{geom}'
    return (
        f'<DMXChannel {c}{f_} Default="800000" Geometry="{geom_path}">'
        f'<LogicalChannel Attribute="{attr}">'
        f'<ChannelFunction Attribute="{attr}" PhysicalFrom="{physical_from:.4f}" PhysicalTo="{physical_to:.4f}"/>'
        f'</LogicalChannel></DMXChannel>'
    )
```

Usage :
```python
# Pan 540° total → -270/+270 ; Tilt 270° total → -135/+135
ch_pantilt("Pan",  coarse=1, physical_from=-270.0, physical_to=270.0, geom="Yoke")
ch_pantilt("Tilt", coarse=2, physical_from=-135.0, physical_to=135.0, geom="Yoke.Head")

# 16-bit (mode 13ch)
ch_pantilt("Pan",  coarse=1, fine=2, physical_from=-270.0, physical_to=270.0, geom="Yoke")
ch_pantilt("Tilt", coarse=3, fine=4, physical_from=-135.0, physical_to=135.0, geom="Yoke.Head")
```

### Plages physiques courantes (dans la datasheet sous "pan range / tilt range")

| Fixture type | Pan (°) | PhysicalFrom/To | Tilt (°) | PhysicalFrom/To |
|---|---|---|---|---|
| Compact moving head | 540 | -270 / +270 | 270 | -135 / +135 |
| Compact moving head | 540 | -270 / +270 | 180 | -90 / +90 |
| Beam / spot         | 360 | -180 / +180 | 270 | -135 / +135 |
| Mini wash           | 180 | -90 / +90   | 90  | -45 / +45  |

Toujours vérifier dans le datasheet — la valeur `Physical_To = total_degrees / 2`.

- 8-bit channel  → `coarse=N`
- 16-bit channel → `coarse=N, fine=N+1`  (e.g. Pan coarse=1 fine=2, Tilt coarse=3 fine=4)
- `default="000000"` = DMX 0 — for all channels except Pan/Tilt
- Pan/Tilt `Default="800000"` (DMX 128 = centre) — fixture points to centre when no cue active

---

## Step 3 — Full XML template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<GMA3 DataVersion="2.3.2.0">
  <FixtureType Name="FIXTURENAME" Guid="XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX"
      Color="1.0000000000,1.0000000000,1.0000000000,1.0000000000"
      ShortName="SHORT" Manufacturer="MANUFACTURER" Universal="No">

    <AttributeDefinitions>
      <DeactivationGroups/>
      <ActivationGroups>
        <ActivationGroup Name="PanTilt"/>
        <ActivationGroup Name="ColorRGB"/>     <!-- wash: RGBW -->
        <!-- roue de couleur (Color1) : pas d'ActivationGroup necessaire -->
        <!-- <ActivationGroup Name="Gobo1"/> --> <!-- spot: gobo wheel (nom officiel, pas "GoboWheel") -->
      </ActivationGroups>
      <FeatureGroups>
        <FeatureGroup Name="Position"><Feature Name="PanTilt"/>   </FeatureGroup>
        <FeatureGroup Name="Dimmer">  <Feature Name="Dimmer"/>    </FeatureGroup>
        <FeatureGroup Name="Color">   <Feature Name="RGB"/>       </FeatureGroup>
        <!-- roue de couleur (Color1) : ajouter <Feature Name="Color"/> dans le FeatureGroup "Color" ci-dessus -->
        <FeatureGroup Name="Control"> <Feature Name="Control"/>   </FeatureGroup>
        <!-- add <FeatureGroup Name="Gobo"><Feature Name="Gobo"/></FeatureGroup> for spots -->
        <!-- add <FeatureGroup Name="Beam"><Feature Name="Beam"/><Feature Name="Focus"/></FeatureGroup> -->
      </FeatureGroups>
      <Attributes>
        <Attribute Name="Pan"           Pretty="P"       ActivationGroup="PanTilt"  Feature="Position.PanTilt" PhysicalUnit="Angle"            NaturalReadout="Physical" EncoderResolution="Coarse"/>
        <Attribute Name="Tilt"          Pretty="T"       ActivationGroup="PanTilt"  Feature="Position.PanTilt" PhysicalUnit="Angle"            NaturalReadout="Physical" EncoderResolution="Coarse"/>
        <Attribute Name="Dimmer"        Pretty="Dim"                                Feature="Dimmer.Dimmer"    PhysicalUnit="LuminousIntensity" NaturalReadout="Percent"  EncoderResolution="Coarse"/>
        <Attribute Name="ColorRGB_R"    Pretty="R"       ActivationGroup="ColorRGB" Feature="Color.RGB"        PhysicalUnit="ColorComponent"    NaturalReadout="Percent"  EncoderResolution="Coarse" Color="1.0,0.0,0.0,1.0"/>
        <Attribute Name="ColorRGB_G"    Pretty="G"       ActivationGroup="ColorRGB" Feature="Color.RGB"        PhysicalUnit="ColorComponent"    NaturalReadout="Percent"  EncoderResolution="Coarse" Color="0.0,1.0,0.0,1.0"/>
        <Attribute Name="ColorRGB_B"    Pretty="B"       ActivationGroup="ColorRGB" Feature="Color.RGB"        PhysicalUnit="ColorComponent"    NaturalReadout="Percent"  EncoderResolution="Coarse" Color="0.0,0.0,1.0,1.0"/>
        <Attribute Name="ColorRGB_W"    Pretty="W"       ActivationGroup="ColorRGB" Feature="Color.RGB"        PhysicalUnit="ColorComponent"    NaturalReadout="Percent"  EncoderResolution="Coarse" Color="1.0,1.0,1.0,1.0"/>
        <Attribute Name="PositionMSpeed" Pretty="Pos MSpeed"                        Feature="Control.Control"                                   NaturalReadout="Percent"  EncoderResolution="Coarse"/>
        <Attribute Name="NoFeature"     Pretty="NoFeature"                          Feature="Control.Control"                                   NaturalReadout="Percent"  EncoderResolution="Coarse"/>
        <!-- spot extras: -->
        <!-- <Attribute Name="ShutterStrobe" Pretty="Strobe" Feature="Beam.Beam"   PhysicalUnit="Frequency" NaturalReadout="Percent" EncoderResolution="Coarse"/> -->
        <!-- <Attribute Name="Color1"        Pretty="C1"     Special="Color" Feature="Color.Color" NaturalReadout="Percent" EncoderResolution="Coarse"/> --> <!-- nom officiel, pas "ColorWheelSelect"/"ColorMacro1" -->
        <!-- <Attribute Name="Gobo1"         Pretty="G1"     ActivationGroup="Gobo1" Special="Gobo" Feature="Gobo.Gobo" NaturalReadout="Percent" EncoderResolution="Coarse"/> --> <!-- nom officiel, pas "GoboWheel1" -->
        <!-- <Attribute Name="Prism1"        Pretty="Prism"  Feature="Beam.Beam"   NaturalReadout="Percent" EncoderResolution="Coarse"/> -->
        <!-- <Attribute Name="Focus"         Pretty="Focus"  Feature="Beam.Focus"  NaturalReadout="Percent" EncoderResolution="Coarse"/> -->
      </Attributes>
    </AttributeDefinitions>

    <Wheels/>

    <PhysicalDescriptions>
      <Emitters/><CRIs/><FTFilters/><Connectors/>
      <PhysicalProperties><PhysicalPropertiesData/></PhysicalProperties>
      <ColorSpaceCollect/><GamutCollect/>
    </PhysicalDescriptions>

    <!-- ── 3D Models — generic meshes built into GrandMA3, GUIDs are constant ── -->
    <Models>
      <Model Name="BASE" Length="0.1500" Width="0.1500" Height="0.1000" DimensionsfollowRatio="No" CastShadow="Yes" Mesh="[base_3ds]" File="MESH/gdtf_generic/base.3ds">
        <DependencyExport Size="1">
          <Dependency Base="ShowData.Meshes" RelAddr="[base_3ds]" RelAddrNum="4" Address="ShowData.Meshes.[base_3ds]" AddressNum="14.7.4">
            <Mesh Lock="UL" Name="[base_3ds]" Guid="D2 39 57 D0 56 75 10 0A 9F B3 78 39 38 9C A3 3E" FileName="base.3ds" FilePath="gdtf_generic" Culling="No">
              <Material Name="Material 1" Guid="D2 39 57 D0 BB 7A 10 0A 4A 3A 90 26 38 9C A3 3E" FilePath="gdtf_generic"/>
            </Mesh>
          </Dependency>
        </DependencyExport>
      </Model>
      <Model Name="YOKE" Length="0.1500" Width="0.0500" Height="0.1000" DimensionsfollowRatio="No" CastShadow="Yes" Mesh="[yoke_3ds]" File="MESH/gdtf_generic/yoke.3ds">
        <DependencyExport Size="1">
          <Dependency Base="ShowData.Meshes" RelAddr="[yoke_3ds]" RelAddrNum="5" Address="ShowData.Meshes.[yoke_3ds]" AddressNum="14.7.5">
            <Mesh Lock="UL" Name="[yoke_3ds]" Guid="D2 39 57 D0 53 6F 10 0A 01 A5 AB 23 38 9C A3 3E" FileName="yoke.3ds" FilePath="gdtf_generic" Culling="No">
              <Material Name="Material 1" Guid="D2 39 57 D0 D5 68 10 0A FC 2F C3 28 38 9C A3 3E" FilePath="gdtf_generic"/>
            </Mesh>
          </Dependency>
        </DependencyExport>
      </Model>
      <Model Name="HEAD" Length="0.1000" Width="0.1000" Height="0.1000" DimensionsfollowRatio="No" CastShadow="Yes" Mesh="[head_3ds]" File="MESH/gdtf_generic/head.3ds">
        <DependencyExport Size="1">
          <Dependency Base="ShowData.Meshes" RelAddr="[head_3ds]" RelAddrNum="6" Address="ShowData.Meshes.[head_3ds]" AddressNum="14.7.6">
            <Mesh Lock="UL" Name="[head_3ds]" Guid="D2 39 57 D0 2B 35 10 0A AB D6 DA 15 39 9C A3 3E" FileName="head.3ds" FilePath="gdtf_generic" Culling="No">
              <Material Name="Material 1" Guid="D2 39 57 D0 17 62 10 0A 66 51 F2 12 39 9C A3 3E" FilePath="gdtf_generic"/>
            </Mesh>
          </Dependency>
        </DependencyExport>
      </Model>
    </Models>

    <!-- ── Geometries: Model= references the Models above, PosZ= in meters ── -->
    <Geometries>
      <Geometry Name="Base" Model="BASE" PosZ="0.0891" GridAuto="Auto">
        <Axis Name="Yoke" Model="YOKE" PosZ="-0.1380" GridAuto="Auto" GridX="0" GridY="0" GridZ="0">
          <Axis Name="Head" Model="HEAD" PosZ="-0.0416" GridAuto="Auto" GridX="0" GridY="0" GridZ="0">
            <!-- Wash : BeamType="Wash" BeamAngle="15.0" BeamRadius="0.050" -->
            <!-- Spot : BeamType="Spot" BeamAngle="8.0"  BeamRadius="0.030" -->
            <Beam Name="Beam" PosZ="-0.1037" GridAuto="Auto" GridX="0" GridY="0" GridZ="0"
                  LampType="LED" BeamType="Wash" BeamAngle="15.0" BeamRadius="0.050"
                  ColorTemperature="6000.0"/>
          </Axis>
        </Axis>
      </Geometry>
    </Geometries>

    <DMXModes>
      <DMXMode Name="9 CH" Geometry="Base" XYZ="No" DiveInto="Yes">
        <DMXChannels>
          <!-- use ch() helper here, one call per channel, explicit Coarse on every channel -->
          <!-- example wash 9ch: -->
          <!-- ch_pantilt("Pan",  coarse=1, physical_from=-270.0, physical_to=270.0, geom="Yoke") -->
          <!-- ch_pantilt("Tilt", coarse=2, physical_from=-135.0, physical_to=135.0, geom="Yoke.Head") -->
          <!-- ch("Base.Yoke.Head.Beam", "Dimmer",         coarse=3) -->
          <!-- ch("Base.Yoke.Head.Beam", "ColorRGB_R",     coarse=4) -->
          <!-- ch("Base.Yoke.Head.Beam", "ColorRGB_G",     coarse=5) -->
          <!-- ch("Base.Yoke.Head.Beam", "ColorRGB_B",     coarse=6) -->
          <!-- ch("Base.Yoke.Head.Beam", "ColorRGB_W",     coarse=7) -->
          <!-- ch("Base.Yoke",           "PositionMSpeed", coarse=8) -->
          <!-- ch("Base",                "NoFeature",      coarse=9, snap="Yes") -->
        </DMXChannels>
        <Relations/><FTMacros/><SoftwareVersions/><FTPresets/>
      </DMXMode>
    </DMXModes>

    <Revisions>
      <Revision Text="Created manually" Date="19.07.2026 00:00:00" UserID="0"/>
    </Revisions>
    <Protocols>
      <RDMFixtureType>
        <Parameters/>
        <Notifications><RDMAbsentNotification/></Notifications>
        <FTRDMPersonalityCollect/>
      </RDMFixtureType>
    </Protocols>
  </FixtureType>
</GMA3>
```

---

## Step 4 — 3D Models

Always include 3D models — GrandMA3 needs them for the 3D visualization.
GrandMA3 has **three generic meshes** built in for moving heads; no external files needed.
Just reference them with the correct GUIDs, which are **constant** for all fixtures.

### Generic mesh names and fixed GUIDs

| Part   | File                       | Mesh alias   | Mesh GUID                                          | Mat GUID                                           | RelAddrNum |
|--------|----------------------------|--------------|----------------------------------------------------|----------------------------------------------------| -----------|
| BASE   | `gdtf_generic/base.3ds`    | `[base_3ds]` | `D2 39 57 D0 56 75 10 0A 9F B3 78 39 38 9C A3 3E` | `D2 39 57 D0 BB 7A 10 0A 4A 3A 90 26 38 9C A3 3E` | 4          |
| YOKE   | `gdtf_generic/yoke.3ds`    | `[yoke_3ds]` | `D2 39 57 D0 53 6F 10 0A 01 A5 AB 23 38 9C A3 3E` | `D2 39 57 D0 D5 68 10 0A FC 2F C3 28 38 9C A3 3E` | 5          |
| HEAD   | `gdtf_generic/head.3ds`    | `[head_3ds]` | `D2 39 57 D0 2B 35 10 0A AB D6 DA 15 39 9C A3 3E` | `D2 39 57 D0 17 62 10 0A 66 51 F2 12 39 9C A3 3E` | 6          |

### DependencyExport block (required for GrandMA3 to find the mesh)

Each `<Model>` element must contain a `<DependencyExport>` that tells GrandMA3 where to load
the mesh from. The structure is always the same — only the mesh alias and RelAddrNum change:

```xml
<Model Name="BASE" Length="0.1500" Width="0.1500" Height="0.1000"
       DimensionsfollowRatio="No" CastShadow="Yes"
       Mesh="[base_3ds]" File="MESH/gdtf_generic/base.3ds">
  <DependencyExport Size="1">
    <Dependency Base="ShowData.Meshes" RelAddr="[base_3ds]" RelAddrNum="4"
                Address="ShowData.Meshes.[base_3ds]" AddressNum="14.7.4">
      <Mesh Lock="UL" Name="[base_3ds]"
            Guid="D2 39 57 D0 56 75 10 0A 9F B3 78 39 38 9C A3 3E"
            FileName="base.3ds" FilePath="gdtf_generic" Culling="No">
        <Material Name="Material 1"
                  Guid="D2 39 57 D0 BB 7A 10 0A 4A 3A 90 26 38 9C A3 3E"
                  FilePath="gdtf_generic"/>
      </Mesh>
    </Dependency>
  </DependencyExport>
</Model>
```

Important:
- `DimensionsfollowRatio="No"` — required so you can set Length, Width, Height independently.
  In the GrandMA3 Fixture Builder UI: click the "Yes" cell in the Models tab to toggle it to "No".
- `Length/Width/Height` are in **meters** (0.1500 = 15 cm).
- You can adjust dimensions to match the real fixture; the generic meshes will be scaled.

### Geometry positioning (PosZ)

When models are attached, each geometry element needs a `Model=` reference and a `PosZ=` offset
(in meters) to position the part vertically:

```xml
<Geometry Name="Base" Model="BASE" PosZ="0.0891" GridAuto="Auto">
  <Axis Name="Yoke" Model="YOKE" PosZ="-0.1380" GridAuto="Auto" GridX="0" GridY="0" GridZ="0">
    <Axis Name="Head" Model="HEAD" PosZ="-0.0416" GridAuto="Auto" GridX="0" GridY="0" GridZ="0">
      <Beam Name="Beam" PosZ="-0.1037" GridAuto="Auto" GridX="0" GridY="0" GridZ="0"
            ColorTemperature="6000.0"/>
    </Axis>
  </Axis>
</Geometry>
```

Reference PosZ values (from real Algam Lighting exports, work for most compact moving heads):

| Geometry | PosZ (MINIWASH710) | PosZ (MS60) |
|----------|--------------------|-------------|
| Base     | `+0.0891`          | `+0.0698`   |
| Yoke     | `-0.1380`          | `-0.1458`   |
| Head     | `-0.0416`          | `-0.0449`   |
| Beam     | `-0.1037`          | `-0.1037`   |

Tip: Export a real fixture from GrandMA3 (right-click → Export in the Fixture Builder) to extract
the exact DependencyExport block and PosZ values for any fixture you already configured manually.

---

## GUID generation

Generate a random UUID and format it as space-separated uppercase hex bytes:

```python
import uuid
def make_guid():
    return " ".join(f"{b:02X}" for b in uuid.uuid4().bytes)
```

Example output: `9E 08 C2 C1 FF 7B 40 E6 A0 14 7A 6F 8E E1 94 52`

---

## Special / SpecialIndex on Attribute definitions

GrandMA3 exports include `Special` and `SpecialIndex` attributes on `<Attribute>` elements.
These are optional at import time but tell GrandMA3 how to group encoders and display colors:

| Attribute        | Special        | SpecialIndex |
|------------------|----------------|--------------|
| `Pan`            | `PanTilt`      | 0            |
| `Tilt`           | `PanTilt`      | 1            |
| `Dimmer`         | `Dimmer`       | 0            |
| `ColorRGB_R`     | `ColorRGB`     | 0            |
| `ColorRGB_G`     | `ColorRGB`     | 1            |
| `ColorRGB_B`     | `ColorRGB`     | 2            |
| `ColorRGB_W`     | `ColorRGB`     | 12           |
| `Color1`         | `Color`        | 0            |
| `Gobo1`          | `Gobo`         | 0            |
| `NoFeature`      | `NoFeature`    | 0            |
| `Prism1`         | `Prism`        | 0            |
| `PositionMSpeed` | *(none)*       | 0            |

Add `Special="..."` and `SpecialIndex="N"` to each `<Attribute>` line to exactly match a
GrandMA3 export. `PositionMSpeed`, `ShutterStrobe`, `Focus` have no `Special` value — just
`SpecialIndex="0"`.

---

## Real examples

Fixtures in `C:\ProgramData\MALightingTechnology\gma3_library\fixturetypes\`:

| File             | Manufacturer   | Modes                           | Pan/Tilt 3D | Beam 3D |
|------------------|----------------|---------------------------------|-------------|---------|
| MINIWASH710.xml  | Algam Lighting | 9 CH / 14 CH (16-bit Pan+Tilt)  | ✓           | ✓ Wash  |
| MS60.xml         | Algam Lighting | 11 Channel / 13 Channel         | ✓           | ✓ Spot  |

---

## Why not GDTF?

| Issue                      | Root cause                                                       |
|----------------------------|--------------------------------------------------------------------|
| "0 modes"                  | GrandMA3 rejected `<Geometry>` elements where `<Axis>` required   |
| Footprint = 1              | `Offset="2","3"…` ignored; only `Offset=""` or explicit Coarse count |
| Wrong attribute names      | GrandMA3 uses `ColorRGB_R`, `PositionMSpeed` — not GDTF standard  |
| Native XML just works      | Same format GrandMA3 writes when you use the Fixture Builder     |
