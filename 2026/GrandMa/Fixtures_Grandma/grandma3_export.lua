-- GrandmaFixtureMapper Export Script pour GrandMA3
--
-- Ce script tourne seul, sans intervention (pas de LLM necessaire) : il lit
-- l'etat EN DIRECT de GrandMA3 (fixtures patchees, adresses, position) et
-- ecrit UNIQUEMENT fixtures.csv -- les infos qui changent a chaque patch/deplacement.
--
-- Il n'ecrit PAS fixture_types.json : ce fichier est statique (mode + palette
-- couleur par type de fixture), cree UNE FOIS depuis le datasheet au moment de
-- la creation du type de fixture (voir GRANDMA3_FIXTURE_CREATION.md, Step 1c),
-- et ne change jamais tant que le type de fixture ne change pas.
--
-- USAGE : voir README.md dans ce dossier pour la procedure complete.
--   1. Copier ce fichier dans C:\ProgramData\MALightingTechnology\gma3_library\datapools\plugins\<sous-dossier>\
--   2. Dans GrandMA3 : creer un Plugin (Plugin Pool) avec un ComponentLua
--      (Installed=Yes, FilePath=<sous-dossier>, FileName=grandma3_export.lua)
--   3. Executer le Plugin. Apres modif externe du fichier : commande ReloadAllPlugins
--   4. fixtures.csv est ecrit dans OUTPUT_DIR
--
-- Modifier OUTPUT_DIR (libre, sans contrainte GrandMA3) pour pointer vers le dossier lu par Smode

local OUTPUT_DIR = "C:/Users/" .. (os.getenv("USERNAME") or "user") .. "/Desktop/grandma-export/"

-- ---------------------------------------------------------------------------
-- Vocabulaire GENERIQUE attribut GrandMA3 -> colonne CSV. Couvre les noms GDTF
-- standard (ColorAdd_R...) et les noms natifs GrandMA3 (ColorRGB_R...). Ceci
-- n'est PAS une table par type/mode de fixture -- c'est un vocabulaire fixe,
-- le meme pour toutes les fixtures, qui marche automatiquement pour tout
-- nouveau type de fixture RGB/RGBW/RGBWA/CMY/ColorWheel/Dimmer sans y toucher.
-- ---------------------------------------------------------------------------
local ATTR_TO_COL = {
    ["ColorAdd_R"] = "R",   ["ColorRGB_R"] = "R",
    ["ColorAdd_G"] = "G",   ["ColorRGB_G"] = "G",
    ["ColorAdd_B"] = "B",   ["ColorRGB_B"] = "B",
    ["ColorAdd_W"] = "W",   ["ColorRGB_W"] = "W",
    ["ColorAdd_WW"] = "W",  ["ColorAdd_CW"] = "W",
    ["ColorAdd_A"] = "A",
    ["ColorSub_C"] = "R",   -- CMY : Cyan   -> canal R dans notre CSV
    ["ColorSub_M"] = "G",   --       Magenta -> G
    ["ColorSub_Y"] = "B",   --       Yellow  -> B
    ["Dimmer"] = "Dimmer",
    ["ColorWheelSelect"] = "Wheel", ["Color1"] = "Wheel", ["ColorWhl"] = "Wheel",
}

-- ---------------------------------------------------------------------------
-- Retrouve le canal Coarse/Fine REEL d'un attribut sur une fixture patchee, en
-- naviguant l'API GrandMA3 -- AUCUNE table par type/mode codee en dur :
--   GetAttributeIndex(nom) + GetUIChannel(fixture, nom) -> GetChannelFunction()
--   -> :Parent() (LogicalChannel) -> :Parent() (DMXChannel) -> .coarse/.fine
-- .coarse/.fine sont les vraies proprietes GrandMA3 (verifie : Dimmer coarse=6,
-- ColorRGB_R coarse=7 sur MINIWASH710 14CH, identique sur toutes les instances
-- du type -- l'adresse absolue vient de fix.patch, propre a chaque instance).
-- ---------------------------------------------------------------------------
local function getCoarseFine(fx, attrName)
    local okAI, attrIdx = pcall(function() return GetAttributeIndex(attrName) end)
    if not okAI or attrIdx == nil then return nil end

    local okUC, uiChan = pcall(function() return GetUIChannel(fx, attrName) end)
    if not okUC or uiChan == nil then return nil end

    local okCF, chFunc = pcall(function() return GetChannelFunction(uiChan.ui_index, attrIdx) end)
    if not okCF or chFunc == nil then return nil end

    local ok1, logicalChan = pcall(function() return chFunc:Parent() end)
    if not ok1 or logicalChan == nil then return nil end

    local ok2, dmxChan = pcall(function() return logicalChan:Parent() end)
    if not ok2 or dmxChan == nil then return nil end

    local okC, coarse = pcall(function() return dmxChan.coarse end)
    local okF, fine    = pcall(function() return dmxChan.fine end)
    if not okC then return nil end

    return tonumber(coarse), (okF and tonumber(fine)) or nil
end

-- ---------------------------------------------------------------------------
-- Escape d'une chaine pour le CSV (gestion des virgules et guillemets)
-- ---------------------------------------------------------------------------
local function csvField(s)
    s = tostring(s)
    if s:find('[,"]') then
        return '"' .. s:gsub('"', '""') .. '"'
    end
    return s
end

-- ---------------------------------------------------------------------------
-- Script principal
-- ---------------------------------------------------------------------------
local function main(displayHandle, ...)
    Printf("=== GrandmaFixtureMapper Export (fixtures.csv uniquement) ===")

    os.execute('mkdir "' .. OUTPUT_DIR:gsub("/", "\\") .. '" 2>nul')

    local rows = {}
    local total, skipped = 0, 0

    -- Enumeration : GetSubfixtureCount()/GetSubfixture(i) -- inclut les Groups
    -- d'affichage (patch vide) qu'on filtre ci-dessous.
    local okCount, count = pcall(function() return GetSubfixtureCount() end)
    count = okCount and count or 0

    for i = 1, count do
        local ok, fix = pcall(function() return GetSubfixture(i) end)
        if ok and fix ~= nil then
            local patch = fix.patch
            if patch == nil or tostring(patch) == "" then
                skipped = skipped + 1
            else
                total = total + 1

                local name     = fix.name or ("Fixture_" .. total)
                local typeName = (fix.fixturetype and fix.fixturetype.name) or "Unknown"

                local universe, baseAddr = 1, 1
                local u, a = tostring(patch):match("(%d+)%.(%d+)")
                if u then universe = tonumber(u) end
                if a then baseAddr  = tonumber(a) end

                local x = tonumber(fix.posx) or 0.0
                local y = tonumber(fix.posy) or 0.0
                local z = tonumber(fix.posz) or 0.0

                local ch = {
                    R=-1, Rfine=-1, G=-1, Gfine=-1,
                    B=-1, Bfine=-1, W=-1, Wfine=-1,
                    A=-1, Afine=-1, Dimmer=-1, Wheel=-1
                }

                for attrName, col in pairs(ATTR_TO_COL) do
                    local coarse, fine = getCoarseFine(fix, attrName)
                    if coarse then
                        if ch[col] == -1 then
                            ch[col] = baseAddr + (coarse - 1)
                        end
                        if fine then
                            local finecol = col .. "fine"
                            if ch[finecol] == -1 then
                                ch[finecol] = baseAddr + (fine - 1)
                            end
                        end
                    end
                end

                rows[#rows + 1] = {
                    name=name, typeName=typeName, universe=universe,
                    R=ch.R, Rfine=ch.Rfine, G=ch.G, Gfine=ch.Gfine,
                    B=ch.B, Bfine=ch.Bfine, W=ch.W, Wfine=ch.Wfine,
                    A=ch.A, Afine=ch.Afine, Dimmer=ch.Dimmer, Wheel=ch.Wheel,
                    x=x, y=y, z=z
                }

                Printf(string.format("  [%02d] %-20s  type=%-15s  uni=%d addr=%-4d  pos=(%.1f,%.1f,%.1f)",
                    total, name, typeName, universe, baseAddr, x, y, z))
            end
        end
    end

    Printf(string.format("Fixtures dans le show : %d (%d Groups/entrees non patchees ignorees)", total, skipped))

    -- -----------------------------------------------------------------------
    -- Ecrire fixtures.csv
    -- -----------------------------------------------------------------------
    local csvPath = OUTPUT_DIR .. "fixtures.csv"
    local fc = io.open(csvPath, "w")
    if not fc then
        Printf("ERREUR : impossible d'ecrire " .. csvPath)
        return
    end
    fc:write("name,typeName,universe,R,Rfine,G,Gfine,B,Bfine,W,Wfine,A,Afine,Dimmer,Wheel,x,y,z\n")
    for _, row in ipairs(rows) do
        fc:write(string.format("%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%.3f,%.3f,%.3f\n",
            csvField(row.name), csvField(row.typeName), row.universe,
            row.R, row.Rfine, row.G, row.Gfine,
            row.B, row.Bfine, row.W, row.Wfine,
            row.A, row.Afine, row.Dimmer, row.Wheel,
            row.x, row.y, row.z))
    end
    fc:close()
    Printf("CSV ecrit -> " .. csvPath)
    Printf("(fixture_types.json n'est pas touche par ce script -- fichier statique separe)")
end

return main
