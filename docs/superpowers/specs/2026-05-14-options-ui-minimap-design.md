# Options UI & Minimap Changes — Design Spec
Date: 2026-05-14

## Overview

Four targeted changes to the client options UI and minimap panel logic:
1. Remove the Sound tab and its top-menu audio button
2. Remove the Debug sub-tab under Misc
3. Hide the Ambient light slider when Enable lights is off
4. Replace the wide minimap checkbox with a three-option dropdown

---

## 1. Remove Sound Tab

**Files:** `modules/client_options/options.lua`

- Remove `soundPanel` variable declaration (line ~98)
- Remove `soundPanel = g_ui.loadUI("audio")` and `optionsTabBar:addTab(tr("Sound"), ...)` (lines ~249–250)
- Remove `audioButton` top-menu button creation (line ~271) and its `terminate()` cleanup
- The `updateValues` branches for `enableAudio`, `enableMusicSound`, `musicSoundVolume`, `botSoundVolume` remain but become no-ops (no panel widget to update); settings still save correctly

---

## 2. Remove Debug Sub-Tab

**Files:** `modules/client_options/options.lua`

- Remove `debugPanel`, `debugButton` variable declarations
- Remove the `if not g_game.getFeature(GameNoDebug) and not g_app.isMobile()` block that creates the debug panel and attaches it as a sub-tab under Misc (lines ~256–268)
- Remove the `addSubTab(miscButton, debugButton, true)` call
- Remove the extras loop in `setup()` that populates the debug panel (lines ~399–405)

---

## 3. Ambient Light Visibility

**Files:** `modules/client_options/options.lua`

- `enableLights` default stays `false`
- In `updateValues` for the `enableLights` key: change `:setEnabled(value)` to `:setVisible(value)` for both `ambientLightLabel` and `ambientLight`
- On initial load the slider is hidden (lights off by default)
- The `setLightOptionsVisibility` function also calls `:setEnabled` on `ambientLight`/`ambientLightLabel` — update those calls to `:setVisible` as well

---

## 4. Wide Minimap Dropdown

### Option schema change

`wideMinimap` changes from `boolean` to `number` (ComboBox index):

| Value | Meaning |
|-------|---------|
| 1 | Disabled |
| 2 | Wide on left panels |
| 3 | Wide on right panels |

Default: `1` (disabled).

### `modules/client_options/interface.otui`

Replace the `OptionCheckBox` (id: `wideMinimap`) with a Label + ComboBox:

```
Label
  !text: tr('Wide minimap')

ComboBox
  id: wideMinimap
  @onOptionChange: modules.client_options.presetOption(self, self:getId(), self.currentIndex)
  @onSetup: |
    self:addOption("Disabled")
    self:addOption("Wide on left panels")
    self:addOption("Wide on right panels")
```

### `modules/client_options/options.lua`

- Change `wideMinimap = false` → `wideMinimap = 1` in `defaultOptions`
- The `setOption` branch for `wideMinimap` already calls `modules.game_minimap.refreshLayout()` — no change needed there

### `modules/game_interface/gameinterface.lua`

Add two helper functions mirroring the existing right-panel helpers:

```lua
function getLeftPanelByIndex(n)
  if gameLeftPanels:getChildCount() == 0 then return nil end
  return gameLeftPanels:getChildByIndex(math.max(1, gameLeftPanels:getChildCount() - n + 1))
end

function getLeftPanelsCount()
  return gameLeftPanels:getChildCount()
end
```

### `modules/game_minimap/minimap.lua`

Replace `updateLayoutInternal` logic:

```
local mode = modules.client_options.getOption('wideMinimap')

if mode == 2 and getLeftPanelsCount() >= 2 then
  -- wide on left: move minimap to 2nd-from-top left panel
  targetParent = getLeftPanelByIndex(2)
  leftEdge  = targetParent:getX() + targetParent:getPaddingLeft()
  rightEdge = getLeftPanel():getX() + getLeftPanel():getWidth() - getLeftPanel():getPaddingRight()
elseif mode == 3 and getRightPanelsCount() >= 2 then
  -- wide on right: existing logic
  targetParent = getRightPanel(2)
  leftEdge  = targetParent:getX() + targetParent:getPaddingLeft()
  rightEdge = getRightPanel():getX() + getRightPanel():getWidth() - getRightPanel():getPaddingRight()
else
  -- disabled or not enough panels: use first right panel, default width
  targetParent = getRightPanel()
  targetWidth  = defaultMinimapWidth
end
```

---

## Files Changed

| File | Change |
|------|--------|
| `modules/client_options/options.lua` | Remove Sound tab, Debug sub-tab, update wideMinimap default + type, ambient light visibility |
| `modules/client_options/interface.otui` | Replace wideMinimap checkbox with ComboBox |
| `modules/game_interface/gameinterface.lua` | Add `getLeftPanelByIndex`, `getLeftPanelsCount` |
| `modules/game_minimap/minimap.lua` | Update `updateLayoutInternal` for new option values |
