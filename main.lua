-- name: [CS] Cynix!
-- description: A slimy gal,,\n this character belongs to AymenZero!

local TEXT_MOD_NAME = "[CS] Cynix!"

if not _G.charSelectExists then
    djui_popup_create("\\#ffffdc\\\n"..TEXT_MOD_NAME.."\nRequires the Character Select Mod\nto use as a Library!\n\nPlease turn on the Character Select Mod\nand Restart the Room!", 6)
    return 0
end

local E_MODEL_CYNIX = smlua_model_util_get_id("cynix_geo")   -- Located in "actors"
local TEX_ICON_CYNIX = get_texture_info("cyn_icon")
local CYN_GRAFFITI = get_texture_info("cynix_graffiti")

anims = {
    [charSelect.CS_ANIM_MENU] = "CYN_MENU_ANIM",
    [CHAR_ANIM_IDLE_HEAD_CENTER] = 'CYN_MENU_ANIM',
    [CHAR_ANIM_IDLE_HEAD_LEFT]   = 'CYN_MENU_ANIM',
    [CHAR_ANIM_IDLE_HEAD_RIGHT]  = 'CYN_MENU_ANIM',
}

local PALETTE_CYNIX = {
    [PANTS]  = "807AB4",
    [SHIRT]  = "7460DA",
    [GLOVES] = "FFFFFF",
    [SHOES]  = "E0556C",
    [HAIR]   = "55D0FF",
    [SKIN]   = "55D0FF",
    [CAP]    = "FF2751",
	[EMBLEM] = "FFFFFF"
}
_G.charSelect.character_add_palette_preset(E_MODEL_CYNIX, PALETTE_CYNIX)


CHAR_CYNIX = _G.charSelect.character_add(
    "Cynix", -- Character Name
    "Vroom Vroom slimy gorl", -- Description
    "Honi, AymenZero", -- Credits
    "55D0FF",           -- Menu Color
    E_MODEL_CYNIX,       -- Character Model
    CT_MARIO,           -- Override Character
    TEX_ICON_CYNIX, -- Life Icon
    1,                  -- Camera Scale
    0                   -- Vertical Offset
)

charSelect.character_add_animations(E_MODEL_CYNIX, anims)
charSelect.character_add_graffiti(CHAR_CYNIX, CYN_GRAFFITI)