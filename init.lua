local gap = 10
local browserApps = {
  Safari = true,
  ["Google Chrome"] = true,
  Arc = true,
  ["Brave Browser"] = true,
  ["Microsoft Edge"] = true,
}

-- ウィンドウが画面外にはみ出さないよう補正する（四隅gapを確保）
local function clampToScreen(f, screen)
  local maxW = screen.w - gap * 2
  local maxH = screen.h - gap * 2
  if f.w > maxW then f.w = maxW end
  if f.h > maxH then f.h = maxH end
  if f.x < screen.x + gap then f.x = screen.x + gap end
  if f.y < screen.y + gap then f.y = screen.y + gap end
  if f.x + f.w > screen.x + screen.w - gap then f.x = screen.x + screen.w - gap - f.w end
  if f.y + f.h > screen.y + screen.h - gap then f.y = screen.y + screen.h - gap - f.h end
  return f
end

local function frontmostAppIsBrowser()
  local app = hs.application.frontmostApplication()
  if not app then return false end
  return browserApps[app:name()] == true
end

-- option + enter: 各辺10pxギャップ付きフル表示
hs.hotkey.bind({"alt"}, "f", function()
  local win = hs.window.focusedWindow()
  local screen = win:screen():frame()
  win:setFrame({
    x = screen.x + gap,
    y = screen.y + gap,
    w = screen.w - gap * 2,
    h = screen.h - gap * 2,
  })
end)

-- option + c: 中央配置（サイズはそのまま）
hs.hotkey.bind({"alt"}, "c", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen():frame()
  f.x = screen.x + (screen.w - f.w) / 2
  f.y = screen.y + (screen.h - f.h) / 2
  win:setFrame(clampToScreen(f, screen))
end)

-- option + v: 1200x800にリサイズ
hs.hotkey.bind({"alt"}, "v", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen():frame()
  f.w = 1200
  f.h = 800
  win:setFrame(clampToScreen(f, screen))
end)

-- option + b: 小サイズ (800x600) にリサイズして中央配置
hs.hotkey.bind({"alt"}, "b", function()
  local win = hs.window.focusedWindow()
  local screen = win:screen():frame()
  local w, h = 950, 550
  win:setFrame(clampToScreen({
    x = screen.x + (screen.w - w) / 2,
    y = screen.y + (screen.h - h) / 2,
    w = w,
    h = h,
  }, screen))
end)

-- option + n: スマホサイズ (402x874, iPhone 17 Pro相当) にリサイズして中央配置
hs.hotkey.bind({"alt"}, "n", function()
  local win = hs.window.focusedWindow()
  local screen = win:screen():frame()
  local w, h = 402, 750
  win:setFrame(clampToScreen({
    x = screen.x + (screen.w - w) / 2,
    y = screen.y + (screen.h - h) / 2,
    w = w,
    h = h,
  }, screen))
end)

-- option + i/j/k/l: ウィンドウ移動（長押し対応）
local moveStep = 30
local moveKeys = {
  { key = "i", dx =  0, dy = -1 },  -- 上
  { key = "j", dx = -1, dy =  0 },  -- 左
  { key = "k", dx =  0, dy =  1 },  -- 下
  { key = "l", dx =  1, dy =  0 },  -- 右
}

for _, m in ipairs(moveKeys) do
  local fn = function()
    if m.key == "i" and frontmostAppIsBrowser() then
      hs.eventtap.keyStroke({"cmd", "shift"}, "t", 0)
      return
    end
    if m.key == "j" and frontmostAppIsBrowser() then
      hs.eventtap.keyStroke({"ctrl", "shift"}, "tab", 0)
      return
    end
    if m.key == "k" and frontmostAppIsBrowser() then
      hs.eventtap.keyStroke({"cmd"}, "w", 0)
      return
    end
    if m.key == "l" and frontmostAppIsBrowser() then
      hs.eventtap.keyStroke({"ctrl"}, "tab", 0)
      return
    end

    local win = hs.window.focusedWindow()
    if not win then return end
    local f = win:frame()
    local screen = win:screen():frame()
    f.x = f.x + m.dx * moveStep
    f.y = f.y + m.dy * moveStep
    win:setFrame(clampToScreen(f, screen))
  end
  hs.hotkey.bind({"alt"}, m.key, fn, nil, fn)
end

-- =============================================
-- Caps Lock LED ↔ IME 連動
-- 依存: ~/.hammerspoon/bin/setleds
-- 削除: このブロックと ~/.hammerspoon/bin/ を消せばアンインストール完了
-- =============================================
do
    local setledsPath = os.getenv("HOME") .. "/.hammerspoon/bin/setleds"

    local function updateCapsLED()
        local src = hs.keycodes.currentSourceID()
        if string.find(src, "Japanese") then
            hs.task.new(setledsPath, nil, {"+caps"}):start()
        else
            hs.task.new(setledsPath, nil, {"-caps"}):start()
        end
    end

    hs.keycodes.inputSourceChanged(updateCapsLED)
    updateCapsLED()
end
