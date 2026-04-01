local gap = 10

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
  win:setFrame(f)
end)

-- option + v: 1300x350にリサイズ
hs.hotkey.bind({"alt"}, "v", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  f.w = 1200
  f.h = 800
  win:setFrame(f)
end)

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