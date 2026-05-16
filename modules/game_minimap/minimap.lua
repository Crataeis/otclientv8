minimapWidget = nil
minimapButton = nil
minimapWindow = nil
fullmapView = false
loaded = false
oldZoom = nil
oldPos = nil
defaultMinimapWidth = nil

local PANEL_WIDTH = 198
local wideMinimapContainer = nil  -- panelsContainer (gameRightPanels/gameLeftPanels) in wide mode

local function syncWidePosition()
  if not wideMinimapContainer or not minimapWindow then return end
  -- Snap X so the minimap never drifts sideways out of the panels area
  local snapX = wideMinimapContainer:getX()
  if minimapWindow:getX() ~= snapX then
    minimapWindow:setPosition({x = snapX, y = minimapWindow:getY()})
  end
end

local function resetPanels()
  for i = 1, modules.game_interface.getRightPanelsCount() do
    local p = modules.game_interface.getRightPanel(i)
    if p then
      if not p:isVisible() then p:setVisible(true) end
      if p:getWidth() ~= PANEL_WIDTH then p:setWidth(PANEL_WIDTH) end
      p:setPaddingTop(0)
    end
  end
  for i = 1, modules.game_interface.getLeftPanelsCount() do
    local p = modules.game_interface.getLeftPanelByIndex(i)
    if p then
      if not p:isVisible() then p:setVisible(true) end
      if p:getWidth() ~= PANEL_WIDTH then p:setWidth(PANEL_WIDTH) end
      p:setPaddingTop(0)
    end
  end
end

local function updateLayoutInternal()
  if not minimapWindow then
    return
  end

  local rightPanel = modules.game_interface.getRightPanel()
  if not rightPanel then
    return
  end

  local mode = modules.client_options.getOption('wideMinimap')

  -- Restore previous wide container's top anchor before switching modes
  if wideMinimapContainer then
    wideMinimapContainer:addAnchor(AnchorTop, 'gameButtonsBar', AnchorBottom)
    wideMinimapContainer = nil
    minimapWindow.onGeometryChange = nil
    minimapWindow:setContentMaximumHeight(10000)
  end
  resetPanels()

  local function placeWideMinimapAbove(panelsContainer)
    local rootPanel = modules.game_interface.getRootPanel()
    -- Insert right after panelsContainer in rootPanel's child list so the
    -- minimap renders above the panel backgrounds but below later-opened windows
    local insertIdx = rootPanel:getChildCount()
    for i = 1, rootPanel:getChildCount() do
      if rootPanel:getChildByIndex(i) == panelsContainer then
        insertIdx = i + 1
        break
      end
    end
    rootPanel:insertChild(insertIdx, minimapWindow)
    minimapWindow:setWidth(PANEL_WIDTH * 2 - 1)
    -- getX/getY return screen-absolute coords; setPosition takes the same
    minimapWindow:setPosition({x = panelsContainer:getX(), y = panelsContainer:getY()})
    -- Anchor the container's top to the minimap's bottom so resizing the
    -- minimap automatically grows/shrinks the panels below — nothing disappears
    panelsContainer:addAnchor(AnchorTop, 'minimapWindow', AnchorBottom)
    minimapWindow:setContentMaximumHeight(350)
    wideMinimapContainer = panelsContainer
    minimapWindow.onGeometryChange = function() syncWidePosition() end
  end

  if mode == 2 and modules.game_interface.getLeftPanelsCount() >= 2 then
    local outer = modules.game_interface.getLeftPanelByIndex(2)
    if outer then
      placeWideMinimapAbove(outer:getParent())
    end
  elseif mode == 3 and modules.game_interface.getRightPanelsCount() >= 2 then
    local outer = modules.game_interface.getRightPanel(1)
    if outer then
      placeWideMinimapAbove(outer:getParent())
    end
  else
    if minimapWindow:getParent() ~= rightPanel then
      minimapWindow:setParent(rightPanel)
    end
  end
end

function init()
  minimapWindow = g_ui.loadUI('minimap', modules.game_interface.getRightPanel())
  minimapWindow:setContentMinimumHeight(64)
  defaultMinimapWidth = minimapWindow:getWidth()

  if not minimapWindow.forceOpen then
    minimapButton = modules.client_topmenu.addRightGameToggleButton('minimapButton', 
      tr('Minimap') .. ' (Ctrl+M)', '/images/topbuttons/minimap', toggle)
    minimapButton:setOn(true)
  end

  minimapWidget = minimapWindow:recursiveGetChildById('minimap')

  local gameRootPanel = modules.game_interface.getRootPanel()

  Keybind.new("Windows", "Toggle Minimap", "Ctrl+M", "")
  Keybind.new("UI", "Toggle Full Map", "Ctrl+Shift+M", "")

  Keybind.new("Minimap", "Center", "", "")
  Keybind.new("Minimap", "One Floor Down", "Alt+PageDown", "")
  Keybind.new("Minimap", "One Floor Up", "Alt+PageUp", "")
  Keybind.new("Minimap", "Scroll East", "Alt+Right", "")
  Keybind.new("Minimap", "Scroll North", "Alt+Up", "")
  Keybind.new("Minimap", "Scroll South", "Alt+Down", "")
  Keybind.new("Minimap", "Scroll West", "Alt+Left", "")
  Keybind.new("Minimap", "Zoom In", "Alt+End", "")
  Keybind.new("Minimap", "Zoom Out", "Alt+Home", "")

  Keybind.bind("Windows", "Toggle Minimap", {
    {
      type = KEY_DOWN,
      callback = toggle,
    }
  })
  Keybind.bind("UI", "Toggle Full Map", {
    {
      type = KEY_DOWN,
      callback = toggleFullMap,
    }
  })

  Keybind.bind("Minimap", "Center", {
    {
      type = KEY_DOWN,
      callback = reset,
    }
  })
  Keybind.bind("Minimap", "One Floor Down", {
    {
      type = KEY_DOWN,
      callback = floorDown,
    }
  })
  Keybind.bind("Minimap", "One Floor Up", {
    {
      type = KEY_DOWN,
      callback = floorUp,
    }
  })
  Keybind.bind("Minimap", "Scroll East", {
    {
      type = KEY_PRESS,
      callback = function() minimapWidget:move(-1, 0) end,
    }
  }, gameRootPanel)
  Keybind.bind("Minimap", "Scroll North", {
    {
      type = KEY_PRESS,
      callback = function() minimapWidget:move(0, 1) end,
    }
  }, gameRootPanel)
  Keybind.bind("Minimap", "Scroll South", {
    {
      type = KEY_PRESS,
      callback = function() minimapWidget:move(0, -1) end,
    }
  }, gameRootPanel)
  Keybind.bind("Minimap", "Scroll West", {
    {
      type = KEY_PRESS,
      callback = function() minimapWidget:move(1, 0) end,
    }
  }, gameRootPanel)
  Keybind.bind("Minimap", "Zoom In", {
    {
      type = KEY_DOWN,
      callback = zoomIn,
    }
  })
  Keybind.bind("Minimap", "Zoom Out", {
    {
      type = KEY_DOWN,
      callback = zoomOut,
    }
  })

  minimapWindow:setup()

  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })

  connect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })

  if g_game.isOnline() then
    online()
  end

  refreshLayout()
end

function terminate()
  if g_game.isOnline() then
    saveMap()
  end

  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })

  disconnect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })

  Keybind.delete("Windows", "Toggle Minimap")
  Keybind.delete("UI", "Toggle Full Map")

  Keybind.delete("Minimap", "Center")
  Keybind.delete("Minimap", "One Floor Down")
  Keybind.delete("Minimap", "One Floor Up")
  Keybind.delete("Minimap", "Scroll East")
  Keybind.delete("Minimap", "Scroll North")
  Keybind.delete("Minimap", "Scroll South")
  Keybind.delete("Minimap", "Scroll West")
  Keybind.delete("Minimap", "Zoom In")
  Keybind.delete("Minimap", "Zoom Out")

  minimapWindow:destroy()
  if minimapButton then
    minimapButton:destroy()
  end
  minimapWidget = nil
  minimapButton = nil
  minimapWindow = nil
  defaultMinimapWidth = nil
end

function toggle()
  if not minimapButton then return end
  if minimapButton:isOn() then
    minimapWindow:close()
    minimapButton:setOn(false)
  else
    minimapWindow:open()
    minimapButton:setOn(true)
  end
end

function onMiniWindowClose()
  if minimapButton then
    minimapButton:setOn(false)
  end
end

function online()
  loadMap()
  updateCameraPosition()
  refreshLayout()
end

function offline()
  saveMap()
end

function loadMap()
  local clientVersion = g_game.getClientVersion()

  g_minimap.clean()
  loaded = false

  local minimapFile = '/minimap.otmm'
  local dataMinimapFile = '/data' .. minimapFile
  local versionedMinimapFile = '/minimap' .. clientVersion .. '.otmm'
  if g_resources.fileExists(dataMinimapFile) then
    loaded = g_minimap.loadOtmm(dataMinimapFile)
  end
  if not loaded and g_resources.fileExists(versionedMinimapFile) then
    loaded = g_minimap.loadOtmm(versionedMinimapFile)
  end
  if not loaded and g_resources.fileExists(minimapFile) then
    loaded = g_minimap.loadOtmm(minimapFile)
  end
  if not loaded then
    print("Minimap couldn't be loaded, file missing?")
  end
  minimapWidget:load()
end

function saveMap()
  local clientVersion = g_game.getClientVersion()
  local minimapFile = '/minimap' .. clientVersion .. '.otmm' 
  g_minimap.saveOtmm(minimapFile)
  minimapWidget:save()
end

function updateCameraPosition()
  local player = g_game.getLocalPlayer()
  if not player then return end
  local pos = player:getPosition()
  if not pos then return end
  if not minimapWidget:isDragging() then
    if not fullmapView then
      minimapWidget:setCameraPosition(player:getPosition())
    end
    minimapWidget:setCrossPosition(player:getPosition())
  end
end

function toggleFullMap()
  if not fullmapView then
    fullmapView = true
    minimapWindow:hide()
    minimapWidget:setParent(modules.game_interface.getRootPanel())
    minimapWidget:fill('parent')
    minimapWidget:setAlternativeWidgetsVisible(true)
  else
    fullmapView = false
    minimapWidget:setParent(minimapWindow:getChildById('contentsPanel'))
    minimapWidget:fill('parent')
    minimapWindow:show()
    minimapWidget:setAlternativeWidgetsVisible(false)
    refreshLayout()
  end

  local zoom = oldZoom or 0
  local pos = oldPos or minimapWidget:getCameraPosition()
  oldZoom = minimapWidget:getZoom()
  oldPos = minimapWidget:getCameraPosition()
  minimapWidget:setZoom(zoom)
  minimapWidget:setCameraPosition(pos)
end

function center()
  minimapWidget:reset()
end

function floorDown()
  minimapWidget:floorDown(1)
end

function floorUp()
  minimapWidget:floorUp(1)
end

function zoomIn()
  minimapWidget:zoomIn()
end

function zoomOut()
  minimapWidget:zoomOut()
end

function refreshLayout()
  addEvent(updateLayoutInternal)
end
