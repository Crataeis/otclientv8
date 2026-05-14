# Options UI & Minimap Changes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove Sound tab and Debug sub-tab from Options, hide ambient light slider when lights are off, and replace the wide-minimap checkbox with a three-option dropdown (Disabled / Wide on left panels / Wide on right panels).

**Architecture:** All changes are in Lua/OTUI files — no C++ recompile needed. The minimap change introduces a new numeric option (replacing a boolean) and two new helper functions in gameinterface.lua that mirror existing right-panel helpers.

**Tech Stack:** Lua 5.1, OTClient OTUI, no automated test runner for UI — verification steps are manual (launch the client, open Options).

---

## File Map

| File | What changes |
|------|-------------|
| `modules/client_options/options.lua` | Remove Sound tab + audio button, remove Debug sub-tab, change `wideMinimap` default to `1`, change `enableLights` handler to use `:setVisible` |
| `modules/client_options/interface.otui` | Replace `wideMinimap` OptionCheckBox with Label + ComboBox |
| `modules/game_interface/gameinterface.lua` | Add `getLeftPanelByIndex(n)` and `getLeftPanelsCount()` |
| `modules/game_minimap/minimap.lua` | Rewrite `updateLayoutInternal` to handle mode 1/2/3 |

---

### Task 1: Remove Sound tab and audio top-button

**Files:**
- Modify: `modules/client_options/options.lua`

- [ ] **Step 1: Remove variable declarations for soundPanel and audioButton**

In `options.lua`, find lines 96–98:
```lua
local graphicsPanel
local soundPanel
local audioButton
```
Replace with:
```lua
local graphicsPanel
```

- [ ] **Step 2: Remove soundPanel creation and Sound tab registration**

Find (lines ~249–250):
```lua
  soundPanel = g_ui.loadUI("audio")
  optionsTabBar:addTab(tr("Sound"), soundPanel, "/images/options/icon-sound"):setMarginTop(10)
```
Delete both lines.

- [ ] **Step 3: Remove audioButton creation in init()**

Find (line ~271):
```lua
  audioButton = modules.client_topmenu.addLeftButton("audioButton", tr("Audio"), "/images/topbuttons/audio", function() toggleOption("enableAudio") end)
  if g_app.isMobile() then
    audioButton:hide()
  end
```
Delete all four lines.

- [ ] **Step 4: Remove audioButton cleanup in terminate()**

Find in `terminate()`:
```lua
  if audioButton then
    audioButton:destroy()
    audioButton = nil
  end
```
Delete those four lines.

- [ ] **Step 5: Remove audioButton icon update in updateValues()**

Find in `updateValues()` under `key == "enableAudio"`:
```lua
    if value then
      audioButton:setIcon("/images/topbuttons/audio")
    else
      audioButton:setIcon("/images/topbuttons/audio_mute")
    end
```
Delete those four lines (leave the `g_sounds.setAudioEnabled(value)` line intact).

- [ ] **Step 6: Verify — launch client, open Options**

Run `otclient_debug_x64.exe`.
Expected: Options window has no "Sound" tab. No audio toggle button in the top toolbar.

- [ ] **Step 7: Commit**
```
git add modules/client_options/options.lua
git commit -m "feat: remove Sound tab and audio top-menu button from options"
```

---

### Task 2: Remove Debug sub-tab under Misc

**Files:**
- Modify: `modules/client_options/options.lua`

- [ ] **Step 1: Remove debugPanel and debugButton variable declarations**

Find lines 100–101:
```lua
local miscPanel, miscButton
local debugPanel, debugButton
```
Replace with:
```lua
local miscPanel, miscButton
```

- [ ] **Step 2: Remove the debug panel creation block in init()**

Find and delete the entire block (lines ~256–268):
```lua
  if not g_game.getFeature(GameNoDebug) and not g_app.isMobile() then
    debugPanel = g_ui.loadUI("debug")
    debugButton = optionsTabBar:addTab(tr("Debug"), debugPanel)

    addSubTab(miscButton, debugButton, true)

    for _, v in ipairs(g_extras.getAll()) do
      local extrasButton = g_ui.createWidget("OptionCheckBox")
      extrasButton:setId(v)
      extrasButton:setText(g_extras.getDescription(v))
      debugPanel:addChild(extrasButton)
    end
  end
```

- [ ] **Step 3: Remove debug panel population in setup()**

Find in `setup()` (lines ~399–405):
```lua
  for _, v in ipairs(g_extras.getAll()) do
    g_extras.set(v, g_settings.getBoolean("extras_" .. v))
    local widget = debugPanel:recursiveGetChildById(v)
    if widget then
      widget:setChecked(g_extras.get(v))
    end
  end
```
Delete those six lines.

- [ ] **Step 4: Verify — launch client, open Options, click Misc**

Expected: Misc tab opens showing only the profile ComboBox. No "Debug" sub-tab appears under Misc.

- [ ] **Step 5: Commit**
```
git add modules/client_options/options.lua
git commit -m "feat: remove Debug sub-tab from Misc options"
```

---

### Task 3: Hide ambient light slider when Enable Lights is off

**Files:**
- Modify: `modules/client_options/options.lua`

- [ ] **Step 1: Update updateValues() for enableLights**

Find in `updateValues()` under `key == "enableLights"` (lines ~582–585):
```lua
  elseif key == "enableLights" then
    gameMapPanel:setDrawLights(value and options["ambientLight"] < 100)
    graphicsPanel:getChildById("ambientLight"):setEnabled(value)
    graphicsPanel:getChildById("ambientLightLabel"):setEnabled(value)
```
Replace with:
```lua
  elseif key == "enableLights" then
    gameMapPanel:setDrawLights(value and options["ambientLight"] < 100)
    graphicsPanel:getChildById("ambientLight"):setVisible(value)
    graphicsPanel:getChildById("ambientLightLabel"):setVisible(value)
```

- [ ] **Step 2: Verify — launch client, open Options → Graphics**

Expected:
- "Ambient light" label and slider are **not visible** when "Enable lights" is unchecked (default).
- Checking "Enable lights" makes them appear.
- Unchecking hides them again.

- [ ] **Step 3: Commit**
```
git add modules/client_options/options.lua
git commit -m "feat: hide ambient light slider when enable lights is off"
```

---

### Task 4: Add left-panel helper functions to gameinterface.lua

**Files:**
- Modify: `modules/game_interface/gameinterface.lua`

- [ ] **Step 1: Add getLeftPanelByIndex and getLeftPanelsCount after getLeftPanel()**

Find the existing `getLeftPanel()` function (line ~875):
```lua
function getLeftPanel()
  if gameLeftPanels:getChildCount() >= 1 then
    return gameLeftPanels:getChildByIndex(-1)
  end
  return getRightPanel()
end
```
Add the two new functions immediately after it:
```lua
function getLeftPanel()
  if gameLeftPanels:getChildCount() >= 1 then
    return gameLeftPanels:getChildByIndex(-1)
  end
  return getRightPanel()
end

function getLeftPanelByIndex(n)
  if gameLeftPanels:getChildCount() == 0 then return nil end
  return gameLeftPanels:getChildByIndex(math.max(1, gameLeftPanels:getChildCount() - n + 1))
end

function getLeftPanelsCount()
  return gameLeftPanels:getChildCount()
end
```

- [ ] **Step 2: Commit**
```
git add modules/game_interface/gameinterface.lua
git commit -m "feat: add getLeftPanelByIndex and getLeftPanelsCount helpers"
```

---

### Task 5: Replace wideMinimap checkbox with dropdown in interface.otui

**Files:**
- Modify: `modules/client_options/interface.otui`

- [ ] **Step 1: Replace the OptionCheckBox with a Label + ComboBox**

Find (lines ~106–118):
```
  Panel
    height: 18
    margin-top: 3

    $mobile:
      visible: false

    OptionCheckBox
      id: wideMinimap
      !text: tr('Wide minimap uses 2 right panels')
      !tooltip: tr('When enabled, the minimap spans the two rightmost side panels if available.')
      anchors.left: parent.left
      anchors.top: parent.top
```
Replace with:
```
  Panel
    height: 40
    margin-top: 3

    $mobile:
      visible: false

    Label
      id: wideminimapLabel
      anchors.left: parent.left
      anchors.top: parent.top
      !text: tr('Wide minimap')

    ComboBox
      id: wideMinimap
      anchors.left: parent.left
      anchors.top: wideminimapLabel.bottom
      margin-top: 3
      margin-right: 2
      @onOptionChange: modules.client_options.presetOption(self, self:getId(), self.currentIndex)
      @onSetup: |
        self:addOption("Disabled")
        self:addOption("Wide on left panels")
        self:addOption("Wide on right panels")
```

- [ ] **Step 2: Verify — launch client, open Options → Interface**

Expected: "Wide minimap" label with a dropdown below it showing "Disabled", "Wide on left panels", "Wide on right panels". Selecting an option saves without error.

- [ ] **Step 3: Commit**
```
git add modules/client_options/interface.otui
git commit -m "feat: replace wide minimap checkbox with three-option dropdown"
```

---

### Task 6: Wire up wideMinimap numeric option and fix minimap layout logic

**Files:**
- Modify: `modules/client_options/options.lua`
- Modify: `modules/game_minimap/minimap.lua`

- [ ] **Step 1: Change wideMinimap default from false to 1 in options.lua**

Find in `defaultOptions` (line ~22):
```lua
  wideMinimap = false,
```
Replace with:
```lua
  wideMinimap = 1,
```

- [ ] **Step 2: Rewrite updateLayoutInternal in minimap.lua**

Find the full `updateLayoutInternal` function (lines ~10–33):
```lua
local function updateLayoutInternal()
  if not minimapWindow then
    return
  end

  local rightPanel = modules.game_interface.getRightPanel()
  if not rightPanel then
    return
  end

  local targetParent = rightPanel
  if modules.client_options.getOption('wideMinimap') and modules.game_interface.getRightPanelsCount() >= 2 then
    targetParent = modules.game_interface.getRightPanel(2)
  end

  if minimapWindow:getParent() ~= targetParent then
    minimapWindow:setParent(targetParent)
  end

  local leftEdge = targetParent:getX() + targetParent:getPaddingLeft()
  local rightEdge = rightPanel:getX() + rightPanel:getWidth() - rightPanel:getPaddingRight()
  local targetWidth = math.max(defaultMinimapWidth or 0, rightEdge - leftEdge)
  minimapWindow:setWidth(targetWidth)
end
```
Replace with:
```lua
local function updateLayoutInternal()
  if not minimapWindow then
    return
  end

  local rightPanel = modules.game_interface.getRightPanel()
  if not rightPanel then
    return
  end

  local mode = modules.client_options.getOption('wideMinimap')
  local targetParent = rightPanel
  local targetWidth = defaultMinimapWidth or 0

  if mode == 2 then
    local leftPanel1 = modules.game_interface.getLeftPanelByIndex(1)
    if leftPanel1 then
      targetParent = leftPanel1
      if modules.game_interface.getLeftPanelsCount() >= 2 then
        local leftPanel2 = modules.game_interface.getLeftPanelByIndex(2)
        targetParent = leftPanel2
        local leftEdge = leftPanel2:getX() + leftPanel2:getPaddingLeft()
        local rightEdge = leftPanel1:getX() + leftPanel1:getWidth() - leftPanel1:getPaddingRight()
        targetWidth = math.max(defaultMinimapWidth or 0, rightEdge - leftEdge)
      end
    end
  elseif mode == 3 then
    if modules.game_interface.getRightPanelsCount() >= 2 then
      targetParent = modules.game_interface.getRightPanel(2)
      local leftEdge = targetParent:getX() + targetParent:getPaddingLeft()
      local rightEdge = rightPanel:getX() + rightPanel:getWidth() - rightPanel:getPaddingRight()
      targetWidth = math.max(defaultMinimapWidth or 0, rightEdge - leftEdge)
    end
  end

  if minimapWindow:getParent() ~= targetParent then
    minimapWindow:setParent(targetParent)
  end

  minimapWindow:setWidth(targetWidth)
end
```

- [ ] **Step 3: Verify — launch client with ≥2 left panels and ≥2 right panels configured**

In Options → Interface, set Left panels = 2, Right panels = 2.

Test "Wide on right panels":
- Select "Wide on right panels" → minimap spans the two right panels.
- Switch back to "Disabled" → minimap returns to normal width in right panel.

Test "Wide on left panels":
- Select "Wide on left panels" → minimap moves to left side and spans both left panels.
- Switch back to "Disabled" → minimap returns to right panel.

Test with 1 panel only:
- Set Left panels = 1, select "Wide on left panels" → minimap moves to left panel, no crash, normal width.
- Set Right panels = 1, select "Wide on right panels" → minimap stays in single right panel, normal width.

- [ ] **Step 4: Commit**
```
git add modules/client_options/options.lua modules/game_minimap/minimap.lua
git commit -m "feat: wire up wide minimap dropdown and fix panel spanning logic"
```
