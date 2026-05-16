local bar = nil

function init()
  bar = modules.game_interface.getButtonsBar()
end

function terminate()
end

function takeButtons(buttons)
  for _, button in ipairs(buttons) do
    takeButton(button, true)
  end
  updateOrder()
end

function takeButton(button, dontUpdateOrder)
  button:setParent(bar)
  if not dontUpdateOrder then
    updateOrder()
  end
end

function updateOrder()
  local children = bar:getChildren()
  table.sort(children, function(a, b)
    return (a.index or 1000) < (b.index or 1000)
  end)
  bar:reorderChildren(children)
end
