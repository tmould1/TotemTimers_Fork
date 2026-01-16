if select(2, UnitClass("player")) ~= "SHAMAN" then return end

-- Icon Picker Frame for TotemTimers Loadouts
-- Creates a grid-based icon selector like the macro UI

local IconPicker = {}
TotemTimers.IconPicker = IconPicker

local ICONS_PER_ROW = 10
local ICON_SIZE = 36
local ICON_SPACING = 4
local VISIBLE_ROWS = 8

local allIcons = {}
local filteredIcons = {}
local currentCallback = nil
local currentLoadoutIndex = nil
local scrollOffset = 0

-- Build the list of all available icons
local function BuildIconList()
    if #allIcons > 0 then return end -- Already built

    -- Get macro icons (spells, items, etc.)
    local macroIcons = GetMacroIcons()
    if macroIcons then
        for i = 1, #macroIcons do
            table.insert(allIcons, macroIcons[i])
        end
    end

    -- Get macro item icons
    local itemIcons = GetMacroItemIcons()
    if itemIcons then
        for i = 1, #itemIcons do
            table.insert(allIcons, itemIcons[i])
        end
    end

    -- If those functions didn't work (TBC might not have them), add some common icons manually
    if #allIcons == 0 then
        -- Shaman-related icons
        local commonIcons = {
            "Interface\\Icons\\Spell_Nature_Lightning",
            "Interface\\Icons\\Spell_Nature_ChainLightning",
            "Interface\\Icons\\Spell_Fire_FlameShock",
            "Interface\\Icons\\Spell_Nature_EarthShock",
            "Interface\\Icons\\Spell_Frost_FrostShock2",
            "Interface\\Icons\\Spell_Nature_MagicImmunity",
            "Interface\\Icons\\Ability_Shaman_Stormstrike",
            "Interface\\Icons\\Spell_Nature_LightningShield",
            "Interface\\Icons\\Spell_Fire_Volcano",
            "Interface\\Icons\\Spell_Nature_HealingWaveGreater",
            "Interface\\Icons\\Spell_Nature_StoneSkinTotem",
            "Interface\\Icons\\Spell_Fire_SearingTotem",
            "Interface\\Icons\\Spell_Nature_ManaRegenTotem",
            "Interface\\Icons\\Spell_Nature_InvisibilityTotem",
            "Interface\\Icons\\Spell_Nature_Cyclone",
            "Interface\\Icons\\Spell_Nature_EarthBindTotem",
            "Interface\\Icons\\Spell_Nature_TremorTotem",
            "Interface\\Icons\\Spell_Fire_SelfDestruct",
            "Interface\\Icons\\Spell_Nature_GroundingTotem",
            "Interface\\Icons\\Spell_Nature_Purge",
            "Interface\\Icons\\Spell_Nature_SkinofEarth",
            "Interface\\Icons\\Spell_Nature_Bloodlust",
            "Interface\\Icons\\Spell_Nature_UnyeildingStamina",
            "Interface\\Icons\\Spell_FireResistanceTotem_01",
            "Interface\\Icons\\Spell_FrostResistanceTotem_01",
            "Interface\\Icons\\Spell_Nature_NatureResistanceTotem",
            "Interface\\Icons\\Spell_Nature_WispSplode",
            "Interface\\Icons\\Spell_Fire_TotemOfWrath",
            "Interface\\Icons\\Spell_Nature_ManaTide",
            "Interface\\Icons\\Spell_Shaman_TotemRecall",
            -- Class icons
            "Interface\\Icons\\ClassIcon_Shaman",
            "Interface\\Icons\\ClassIcon_Warrior",
            "Interface\\Icons\\ClassIcon_Paladin",
            "Interface\\Icons\\ClassIcon_Hunter",
            "Interface\\Icons\\ClassIcon_Rogue",
            "Interface\\Icons\\ClassIcon_Priest",
            "Interface\\Icons\\ClassIcon_Mage",
            "Interface\\Icons\\ClassIcon_Warlock",
            "Interface\\Icons\\ClassIcon_Druid",
            -- Spec/role icons
            "Interface\\Icons\\Ability_ThunderBolt",
            "Interface\\Icons\\Ability_DualWield",
            "Interface\\Icons\\Ability_Rogue_Ambush",
            "Interface\\Icons\\Ability_Warrior_BattleShout",
            "Interface\\Icons\\Ability_Warrior_DefensiveStance",
            "Interface\\Icons\\Ability_Warrior_OffensiveStance",
            -- PvP icons
            "Interface\\Icons\\Achievement_PVP_A_A",
            "Interface\\Icons\\Achievement_PVP_H_H",
            "Interface\\Icons\\INV_BannerPVP_01",
            "Interface\\Icons\\INV_BannerPVP_02",
            -- Raid/dungeon icons
            "Interface\\Icons\\Spell_Holy_PrayerOfHealing",
            "Interface\\Icons\\INV_Misc_Head_Dragon_01",
            "Interface\\Icons\\Achievement_Dungeon_ClassicDungeonMaster",
            -- Misc useful icons
            "Interface\\Icons\\INV_Misc_QuestionMark",
            "Interface\\Icons\\Ability_Creature_Cursed_02",
            "Interface\\Icons\\Spell_Shadow_SacrificialShield",
            "Interface\\Icons\\Ability_Creature_Disease_03",
        }
        for _, icon in ipairs(commonIcons) do
            table.insert(allIcons, icon)
        end
    end

    filteredIcons = allIcons
end

-- Create the icon picker frame
local function CreateIconPickerFrame()
    if IconPicker.frame then return end

    local frame = CreateFrame("Frame", "TotemTimers_IconPicker", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(ICONS_PER_ROW * (ICON_SIZE + ICON_SPACING) + 40, VISIBLE_ROWS * (ICON_SIZE + ICON_SPACING) + 100)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    frame.TitleText:SetText("Choose an Icon")

    -- Currently selected icon display
    local selectedBG = frame:CreateTexture(nil, "BACKGROUND")
    selectedBG:SetSize(ICON_SIZE + 8, ICON_SIZE + 8)
    selectedBG:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -35)
    selectedBG:SetColorTexture(0.2, 0.2, 0.2, 1)

    local selectedIcon = frame:CreateTexture(nil, "ARTWORK")
    selectedIcon:SetSize(ICON_SIZE, ICON_SIZE)
    selectedIcon:SetPoint("CENTER", selectedBG, "CENTER")
    frame.selectedIcon = selectedIcon

    local selectedLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectedLabel:SetPoint("LEFT", selectedBG, "RIGHT", 10, 0)
    selectedLabel:SetText("Selected")

    -- Scroll frame for icons
    local scrollFrame = CreateFrame("ScrollFrame", "TotemTimers_IconPickerScroll", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -80)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 45)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(ICONS_PER_ROW * (ICON_SIZE + ICON_SPACING), 1000)
    scrollFrame:SetScrollChild(scrollChild)
    frame.scrollChild = scrollChild

    -- Icon buttons container
    frame.iconButtons = {}

    -- Okay button
    local okayButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    okayButton:SetSize(80, 22)
    okayButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -5, 12)
    okayButton:SetText("Okay")
    okayButton:SetScript("OnClick", function()
        if currentCallback and frame.selectedIconPath then
            currentCallback(frame.selectedIconPath)
        end
        frame:Hide()
    end)

    -- Cancel button
    local cancelButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    cancelButton:SetSize(80, 22)
    cancelButton:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 5, 12)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    IconPicker.frame = frame
end

-- Create icon buttons for the grid
local function CreateIconButtons()
    local frame = IconPicker.frame
    local scrollChild = frame.scrollChild

    -- Calculate how many buttons we need
    local numIcons = #filteredIcons
    local numRows = math.ceil(numIcons / ICONS_PER_ROW)

    -- Resize scroll child
    scrollChild:SetHeight(numRows * (ICON_SIZE + ICON_SPACING) + ICON_SPACING)

    -- Create/update buttons
    for i = 1, numIcons do
        local btn = frame.iconButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, scrollChild)
            btn:SetSize(ICON_SIZE, ICON_SIZE)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints()
            btn.icon = icon

            local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(1, 1, 1, 0.3)

            local border = btn:CreateTexture(nil, "OVERLAY")
            border:SetSize(ICON_SIZE * 1.8, ICON_SIZE * 1.8)  -- Action button border needs ~1.8x icon size
            border:SetPoint("CENTER")
            border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            border:SetBlendMode("ADD")
            border:Hide()
            btn.border = border

            btn:SetScript("OnClick", function(self)
                -- Deselect previous
                for _, b in ipairs(frame.iconButtons) do
                    if b.border then b.border:Hide() end
                end
                -- Select this one
                self.border:Show()
                frame.selectedIconPath = self.iconPath
                frame.selectedIcon:SetTexture(self.iconPath)
            end)

            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                -- Try to show icon name (iconPath can be a number file ID or string path)
                local path = self.iconPath
                local name
                if type(path) == "number" then
                    name = tostring(path)
                elseif type(path) == "string" then
                    name = path:match("Interface\\Icons\\(.+)") or path
                else
                    name = "Unknown"
                end
                GameTooltip:SetText(name)
                GameTooltip:Show()
            end)

            btn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            frame.iconButtons[i] = btn
        end

        -- Position
        local row = math.floor((i - 1) / ICONS_PER_ROW)
        local col = (i - 1) % ICONS_PER_ROW
        btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", col * (ICON_SIZE + ICON_SPACING), -row * (ICON_SIZE + ICON_SPACING))

        -- Set icon
        local iconPath = filteredIcons[i]
        btn.iconPath = iconPath
        btn.icon:SetTexture(iconPath)
        btn.border:Hide()
        btn:Show()
    end

    -- Hide extra buttons
    for i = numIcons + 1, #frame.iconButtons do
        frame.iconButtons[i]:Hide()
    end
end

-- Open the icon picker
function TotemTimers.OpenIconPicker(loadoutIndex, callback)
    BuildIconList()
    CreateIconPickerFrame()

    currentCallback = callback
    currentLoadoutIndex = loadoutIndex

    -- Set current icon if loadout has one
    local set = TotemTimers.ActiveProfile.TotemSets[loadoutIndex]
    if set and set.icon then
        IconPicker.frame.selectedIconPath = set.icon
        IconPicker.frame.selectedIcon:SetTexture(set.icon)
    else
        IconPicker.frame.selectedIconPath = nil
        IconPicker.frame.selectedIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    CreateIconButtons()
    IconPicker.frame:Show()
end
