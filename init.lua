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

-- focusedWindow と screen の nil ガードをまとめて行うヘルパー
local function withFocusedWindow(fn)
  return function()
    local win = hs.window.focusedWindow()
    if not win then return end
    local scr = win:screen()
    if not scr then return end
    fn(win, scr:frame())
  end
end

local function frontmostAppIsBrowser()
  local app = hs.application.frontmostApplication()
  if not app then return false end
  return browserApps[app:name()] == true
end

-- alt + f: 各辺10pxギャップ付きフル表示
hs.hotkey.bind({"alt"}, "f", withFocusedWindow(function(win, frame)
  win:setFrame({
    x = frame.x + gap,
    y = frame.y + gap,
    w = frame.w - gap * 2,
    h = frame.h - gap * 2,
  })
end))

-- alt + c: 中央配置（サイズはそのまま）
hs.hotkey.bind({"alt"}, "c", withFocusedWindow(function(win, frame)
  local f = win:frame()
  f.x = frame.x + math.floor((frame.w - f.w) / 2)
  f.y = frame.y + math.floor((frame.h - f.h) / 2)
  win:setFrame(clampToScreen(f, frame))
end))

-- alt + v: 1200x800にリサイズ
hs.hotkey.bind({"alt"}, "v", withFocusedWindow(function(win, frame)
  local f = win:frame()
  f.w = 1200
  f.h = 800
  win:setFrame(clampToScreen(f, frame))
end))

-- alt + b: 950x550にリサイズして中央配置
hs.hotkey.bind({"alt"}, "b", withFocusedWindow(function(win, frame)
  local w, h = 950, 550
  win:setFrame(clampToScreen({
    x = frame.x + math.floor((frame.w - w) / 2),
    y = frame.y + math.floor((frame.h - h) / 2),
    w = w,
    h = h,
  }, frame))
end))

-- alt + n: スマホサイズ (402x750, iPhone相当) にリサイズして中央配置
hs.hotkey.bind({"alt"}, "n", withFocusedWindow(function(win, frame)
  local w, h = 402, 750
  win:setFrame(clampToScreen({
    x = frame.x + math.floor((frame.w - w) / 2),
    y = frame.y + math.floor((frame.h - h) / 2),
    w = w,
    h = h,
  }, frame))
end))

-- alt + i/j/k/l: ウィンドウ移動（長押し対応）
-- ブラウザ前面時はタブ操作にオーバーライド（ワンショットのみ、長押しで連打しない）
local moveStep = 30
local moveKeys = {
  { key = "i", dx =  0, dy = -1 },  -- 上
  { key = "j", dx = -1, dy =  0 },  -- 左
  { key = "k", dx =  0, dy =  1 },  -- 下
  { key = "l", dx =  1, dy =  0 },  -- 右
}

local browserActions = {
  i = function() hs.eventtap.keyStroke({"cmd", "shift"}, "t", 0) end,
  j = function() hs.eventtap.keyStroke({"ctrl", "shift"}, "tab", 0) end,
  k = function() hs.eventtap.keyStroke({"cmd"}, "w", 0) end,
  l = function() hs.eventtap.keyStroke({"ctrl"}, "tab", 0) end,
}

for _, m in ipairs(moveKeys) do
  local moveFn = function()
    local win = hs.window.focusedWindow()
    if not win then return end
    local scr = win:screen()
    if not scr then return end
    local f = win:frame()
    local frame = scr:frame()
    f.x = f.x + m.dx * moveStep
    f.y = f.y + m.dy * moveStep
    win:setFrame(clampToScreen(f, frame))
  end

  local pressed = function()
    if frontmostAppIsBrowser() then
      browserActions[m.key]()  -- ワンショット：長押しでも1回だけ発火
    else
      moveFn()
    end
  end

  local repeated = function()
    if frontmostAppIsBrowser() then return end  -- ブラウザ時はリピート無効
    moveFn()
  end

  hs.hotkey.bind({"alt"}, m.key, pressed, nil, repeated)
end

-- =============================================
-- Caps Lock LED ↔ IME 連動
-- 依存: ~/.hammerspoon/bin/setleds
-- 削除: このブロックと ~/.hammerspoon/bin/ を消せばアンインストール完了
-- =============================================
do
    local setledsPath = os.getenv("HOME") .. "/.hammerspoon/bin/setleds"
    local pendingTasks = {}  -- GC防止のためにタスク参照を保持
    local lastArg = nil  -- 前回と同じなら setleds を再実行しない

    local function updateCapsLED()
        local src = hs.keycodes.currentSourceID() or ""
        local arg = string.find(src, "Japanese") and "+caps" or "-caps"
        if arg == lastArg then return end
        lastArg = arg
        local task
        task = hs.task.new(setledsPath, function()
            pendingTasks[task] = nil
        end, {arg})
        if task then
            pendingTasks[task] = true
            task:start()
        end
    end

    -- 入力ソース変更イベント
    hs.keycodes.inputSourceChanged(updateCapsLED)

    -- アプリ切替時にも LED を同期（アプリごとに入力ソースが異なる場合の対策）
    local appWatcher = hs.application.watcher.new(function(_, event)
        if event == hs.application.watcher.activated then
            hs.timer.doAfter(0.1, updateCapsLED)
        end
    end)
    appWatcher:start()

    updateCapsLED()
end
