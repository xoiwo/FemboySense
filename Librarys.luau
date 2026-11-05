--[[
    BOOM HOOD · VISUAL ASSISTANT  —  UI library v1.0
    (переработка ZENITH v7.0: без ESP-превью, без UIShadow, без фоновых узоров)

    Быстрый старт:
        local Lib = loadstring(readfile("BHVA_UI.lua"))()
        local Win = Lib:CreateWindow({ Title = "BOOM HOOD", Sub = "Visual Assistant", Folder = "BoomHoodVA" })

        local World = Win:AddCategory("World", nil, "Lighting and colors")
        local Fog = World:AddModule({ Name = "Fog", Info = "Custom fog", Flag = "FogOn", Callback = function(on) end })
        Fog:AddSlider({ Name = "Distance", Min = 50, Max = 2000, Default = 500, Flag = "FogDist", Callback = function(v) end })
        Fog:AddColorPicker({ Name = "Color", Default = Color3.new(1,1,1), Flag = "FogColor", Callback = function(c) end })

        Win:Finish()   -- добавляет Settings + Configs, показывает окно

    API модуля:  AddToggle / AddSlider / AddOptions / AddDropdown / AddColorPicker /
                 AddKeybind / AddTextbox / AddButton / AddLabel / AddCustom
    Всё с Flag автоматически сохраняется в конфиг (JSON) и сбрасывается в дефолт.
    Win:AddMovable(name, frame, handle?)  — перетаскиваемый элемент, позиция сохраняется в конфиг.
    Win:AddPreset(name, { Flag = value, ... })  — готовый пресет интерфейса.
    Win:Notify(title, text, seconds, "ok"|"warn"|"err")
    Lib:GetFlag("Name")  — текущее значение флага.
]]

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local HttpService  = game:GetService("HttpService")
local TextService  = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do task.wait() LocalPlayer = Players.LocalPlayer end

local genv = (getgenv and getgenv()) or _G
if genv.BHVAUnload then pcall(genv.BHVAUnload) end

--══════════════════════════════════════════════════════════════
--  Константы / утилиты
--══════════════════════════════════════════════════════════════
local rgb, WHITE, BLACK = Color3.fromRGB, Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local V2 = Vector2.new
local clamp, floor = math.clamp, math.floor
local SINE, QUINT, BACK = Enum.EasingStyle.Sine, Enum.EasingStyle.Quint, Enum.EasingStyle.Back
local OUT, IN = Enum.EasingDirection.Out, Enum.EasingDirection.In
local AUTO_Y, AUTO_X = Enum.AutomaticSize.Y, Enum.AutomaticSize.X
local LEFT, CENTER, RIGHT = Enum.TextXAlignment.Left, Enum.TextXAlignment.Center, Enum.TextXAlignment.Right

local Lib = { Flags = {}, Version = "v1.0", Speed = 1,
    Semantic = { ok = rgb(70, 225, 125), warn = rgb(255, 190, 60), err = rgb(255, 70, 70) } }

--══════════════════════════════════════════════════════════════
--  Темы
--══════════════════════════════════════════════════════════════
local THEMES = {
    { Name = "Lavender", Accent = rgb(184, 160, 237), Bg = rgb(10, 9, 14), Side = rgb(16, 14, 22), Panel = rgb(24, 21, 32), Panel2 = rgb(37, 33, 49), Text = rgb(244, 242, 250), Sub = rgb(150, 144, 172) },
    { Name = "Crimson",  Accent = rgb(255, 60, 80),   Bg = rgb(10, 8, 10),  Side = rgb(15, 9, 12),  Panel = rgb(24, 17, 19), Panel2 = rgb(36, 23, 26), Text = rgb(245, 245, 245), Sub = rgb(152, 138, 141) },
    { Name = "Ocean",    Accent = rgb(56, 189, 248),  Bg = rgb(7, 10, 15),  Side = rgb(10, 15, 22), Panel = rgb(16, 23, 33), Panel2 = rgb(25, 35, 49), Text = rgb(240, 246, 252), Sub = rgb(130, 148, 168) },
    { Name = "Emerald",  Accent = rgb(52, 211, 153),  Bg = rgb(7, 12, 10),  Side = rgb(9, 16, 13),  Panel = rgb(15, 25, 21), Panel2 = rgb(23, 37, 31), Text = rgb(240, 252, 246), Sub = rgb(130, 160, 148) },
    { Name = "Sunset",   Accent = rgb(251, 146, 60),  Bg = rgb(13, 9, 7),   Side = rgb(19, 12, 9),  Panel = rgb(28, 20, 15), Panel2 = rgb(41, 29, 21), Text = rgb(252, 246, 240), Sub = rgb(168, 148, 135) },
    { Name = "Mono",     Accent = rgb(227, 228, 230), Bg = rgb(8, 8, 10),   Side = rgb(17, 17, 20), Panel = rgb(26, 26, 30), Panel2 = rgb(40, 40, 46), Text = rgb(244, 244, 247), Sub = rgb(146, 146, 154) },
}
Lib.Themes = THEMES

local Theme = { Stroke = WHITE, StrokeT = 0.93, OnAccent = rgb(12, 12, 14) }
local function loadTheme(def, accent)
    for k, v in pairs(def) do if k ~= "Name" then Theme[k] = v end end
    if accent then Theme.Accent = accent end
end
loadTheme(THEMES[1])
Lib.Theme = Theme

local reg, hooks, conns = {}, {}, {}
local function keep(c) conns[#conns + 1] = c return c end
local function B(key) return { __bind = key } end
local function bind(o, prop, key) o[prop] = Theme[key] reg[#reg + 1] = { o, prop, key } end
local function onTheme(fn) hooks[#hooks + 1] = fn fn(true) end

local function tw(obj, t, props, style, dir)
    local tr = TweenService:Create(obj, TweenInfo.new(math.max(t / Lib.Speed, 0.01), style or QUINT, dir or OUT), props)
    tr:Play()
    return tr
end
local function after(t, fn) task.delay(t / Lib.Speed, fn) end

local function applyTheme(def, accent, instant)
    loadTheme(def, accent)
    for i = #reg, 1, -1 do
        local e = reg[i]
        local o = e[1]
        if o.Parent then
            if instant then o[e[2]] = Theme[e[3]] else tw(o, 0.25, { [e[2]] = Theme[e[3]] }, SINE) end
        else
            table.remove(reg, i)
        end
    end
    for _, f in ipairs(hooks) do pcall(f, instant == true) end
end

--══════════════════════════════════════════════════════════════
--  Конструкторы UI
--══════════════════════════════════════════════════════════════
local function new(class, props, kids)
    local o = Instance.new(class)
    if o:IsA("GuiObject") then o.BorderSizePixel = 0 end
    if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then o.Font = Enum.Font.GothamMedium o.TextSize = 13 end
    if o:IsA("TextButton") then o.AutoButtonColor = false o.Text = "" end
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v
        elseif type(v) == "table" and v.__bind then bind(o, k, v.__bind)
        else o[k] = v end
    end
    for _, c in ipairs(kids or {}) do c.Parent = o end
    if parent then o.Parent = parent end
    return o
end
local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function stk() return new("UIStroke", { Color = B"Stroke", Transparency = B"StrokeT", Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) end
local function pad(t, b, l, r)
    return new("UIPadding", { PaddingTop = UDim.new(0, t), PaddingBottom = UDim.new(0, b), PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r) })
end
local function vlist(p, order)
    return new("UIListLayout", { Padding = UDim.new(0, p or 8), SortOrder = order or Enum.SortOrder.LayoutOrder })
end
local function label(parent, text, pos, size, font, ts, color, align)
    return new("TextLabel", {
        Parent = parent, Text = text, Position = pos or UDim2.new(), Size = size or UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, Font = font or Enum.Font.GothamMedium, TextSize = ts or 13,
        TextColor3 = color or B"Text", TextXAlignment = align or LEFT, TextTruncate = Enum.TextTruncate.AtEnd,
    })
end
local function fire(cb, ...)
    if not cb then return end
    local a = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(cb, table.unpack(a, 1, a.n))
        if not ok then warn("[BHVA] " .. tostring(err)) end
    end)
end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end
local function guiParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local function hex(c) return string.format("#%02X%02X%02X", floor(c.R * 255 + 0.5), floor(c.G * 255 + 0.5), floor(c.B * 255 + 0.5)) end
local function parseHex(s)
    s = tostring(s or ""):gsub("[#%s]", "")
    if #s == 3 then s = s:gsub(".", "%0%0") end
    if #s ~= 6 then return nil end
    local n = tonumber(s, 16)
    if not n then return nil end
    return rgb(floor(n / 65536), floor(n / 256) % 256, n % 256)
end
local function flag(o, api) if o.Flag then Lib.Flags[o.Flag] = api end end

-- единый захват мыши для драга (слайдеры, окна, пикеры)
local active
local function capture(onMove, onEnd) active = { move = onMove, stop = onEnd } end

local function keepOnScreen(f)
    local cam = workspace.CurrentCamera
    if not cam or not f.Parent then return end
    local vp, ap, as = cam.ViewportSize, f.AbsolutePosition, f.AbsoluteSize
    local dx, dy = 0, 0
    if ap.X + as.X < 80 then dx = 80 - (ap.X + as.X) elseif ap.X > vp.X - 80 then dx = vp.X - 80 - ap.X end
    if ap.Y + as.Y < 60 then dy = 60 - (ap.Y + as.Y) elseif ap.Y > vp.Y - 60 then dy = vp.Y - 60 - ap.Y end
    if dx ~= 0 or dy ~= 0 then f.Position = f.Position + UDim2.fromOffset(dx, dy) end
end

local function drag(handle, target, gate, onEnd)
    handle.InputBegan:Connect(function(i)
        if not isPress(i) or (gate and gate()) then return end
        local start, sp = i.Position, target.Position
        capture(function(p)
            local d = p - start
            target.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end, function()
            keepOnScreen(target)
            if onEnd then onEnd() end
        end)
    end)
end

--══════════════════════════════════════════════════════════════
--  Клавиши
--══════════════════════════════════════════════════════════════
local SHORT = { RightShift = "RSHIFT", LeftShift = "LSHIFT", RightControl = "RCTRL", LeftControl = "LCTRL", RightAlt = "RALT", LeftAlt = "LALT",
    Return = "ENTER", Backspace = "BKSP", Escape = "ESC", Space = "SPACE", Insert = "INS", Delete = "DEL", PageUp = "PGUP", PageDown = "PGDN", CapsLock = "CAPS" }
local function keyName(k)
    if not k then return "NONE" end
    if k == Enum.UserInputType.MouseButton2 then return "RMB" end
    if k == Enum.UserInputType.MouseButton3 then return "MMB" end
    return SHORT[k.Name] or string.upper(k.Name)
end
local function keyFromName(n)
    if type(n) ~= "string" then return nil end
    local ok, v = pcall(function() return Enum.KeyCode[n] end)
    if ok and v then return v end
    ok, v = pcall(function() return Enum.UserInputType[n] end)
    if ok and v then return v end
    return nil
end
local function keyMatch(key, input) return key ~= nil and (key == input.KeyCode or key == input.UserInputType) end

--══════════════════════════════════════════════════════════════
--  Базовые контролы
--══════════════════════════════════════════════════════════════
local function makeSwitch(parent, init, cb)
    local state = init and true or false
    local track = new("TextButton", { Parent = parent, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(40, 22) }, { corner(11) })
    local knob = new("Frame", { Parent = track, AnchorPoint = V2(0, 0.5), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = WHITE }, { corner(8) })
    local sw = {}
    local function paint(instant)
        local col = state and Theme.Accent or Theme.Panel2
        local pos = state and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        if instant then track.BackgroundColor3, knob.Position = col, pos
        else tw(track, 0.2, { BackgroundColor3 = col }, SINE) tw(knob, 0.3, { Position = pos }, BACK) end
    end
    paint(true)
    onTheme(paint)
    function sw:Set(v, silent)
        v = v and true or false
        if v == state then return end
        state = v
        paint(false)
        if not silent and cb then cb(v) end
    end
    function sw:Get() return state end
    sw.Frame = track
    track.MouseButton1Click:Connect(function() sw:Set(not state) end)
    return sw
end

local function makeSlider(parent, o, order)
    local mn, mx, step = o.Min or 0, o.Max or 100, o.Step or 1
    local def = clamp(o.Default or mn, mn, mx)
    local value = def
    local api = {}
    local f = new("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = order })
    label(f, o.Name or "Slider", nil, UDim2.new(1, -80, 0, 18), nil, 13, B"Text")
    local out = label(f, "", UDim2.new(1, 0, 0, 0), UDim2.fromOffset(80, 18), Enum.Font.GothamBold, 12, B"Accent", RIGHT)
    out.AnchorPoint = V2(1, 0)
    local bar = new("Frame", { Parent = f, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = B"Bg" }, { corner(2) })
    local fill = new("Frame", { Parent = bar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = B"Accent" }, { corner(2) })
    local knob = new("Frame", { Parent = bar, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = WHITE, ZIndex = 2 }, { corner(6) })
    local function fmt(v)
        if step >= 1 then return tostring(floor(v + 0.5)) end
        local s = string.format("%.3f", v):gsub("0+$", ""):gsub("%.$", "")
        return s
    end
    local function render(fast)
        local r = (mx == mn) and 0 or (value - mn) / (mx - mn)
        out.Text = fmt(value) .. (o.Suffix or "")
        local t = fast and 0.05 or 0.2
        tw(fill, t, { Size = UDim2.fromScale(r, 1) }, SINE)
        tw(knob, t, { Position = UDim2.fromScale(r, 0.5) }, SINE)
    end
    local function setv(v, silent, fast)
        v = clamp(floor((v - mn) / step + 0.5) * step + mn, mn, mx)
        v = tonumber(string.format("%.4f", v))
        if v == value then return end
        value = v
        render(fast)
        if not silent then fire(o.Callback, v) end
    end
    render(false)
    local hit = new("TextButton", { Parent = f, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, ZIndex = 3 })
    local function fromX(x) setv(mn + (mx - mn) * clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1), false, true) end
    hit.InputBegan:Connect(function(i)
        if not isPress(i) then return end
        fromX(i.Position.X)
        capture(function(p) fromX(p.X) end)
    end)
    function api:Set(v, silent) setv(v, silent, false) end
    function api:Get() return value end
    api.Export = function() return value end
    api.Import = function(v) if type(v) == "number" then setv(v, false, false) end end
    api.Reset = function() setv(def, false, false) end
    return api
end

-- строка выбора клавиши + режима (модули и AddKeybind)
local function keyRow(parent, order, name, b, modes, changed)
    local row = new("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = order })
    label(row, name, nil, UDim2.new(1, -150, 1, 0), nil, 13, B"Text")
    local modeB = new("TextButton", { Parent = row, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -86, 0.5, 0), Size = UDim2.fromOffset(62, 24),
        BackgroundColor3 = B"Panel2", Text = b.Mode, TextColor3 = B"Sub", Font = Enum.Font.GothamBold, TextSize = 10 }, { corner(8) })
    local kb = new("TextButton", { Parent = row, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(78, 24),
        BackgroundColor3 = B"Panel2", Text = "", TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 10 }, { corner(8) })
    local api = {}
    function api:Paint() kb.Text = keyName(b.Key) modeB.Text = b.Mode end
    api:Paint()
    modeB.MouseButton1Click:Connect(function()
        b.Mode = modes[(table.find(modes, b.Mode) or 1) % #modes + 1]
        b.State = false
        api:Paint()
        changed()
    end)
    kb.MouseButton1Click:Connect(function()
        kb.Text = "..."
        Lib._listen = function(k)
            b.Key = (k ~= Enum.KeyCode.Escape and k ~= Enum.KeyCode.Backspace) and k or nil
            api:Paint()
            changed()
        end
    end)
    return api
end

--══════════════════════════════════════════════════════════════
--  Окно
--══════════════════════════════════════════════════════════════
function Lib:CreateWindow(cfg)
    cfg = cfg or {}
    local W, H = 800, 520
    local Win = {
        Categories = {}, Modules = {}, BindList = {}, Movables = {}, Presets = {}, Current = nil, Query = "",
        Open = false, ToggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift, ThemeDef = THEMES[1], AccentOverride = nil,
        Opacity = 1, UserScale = 1, LockPos = false, FreeMouse = true, NotifsOn = true, NotifTime = 3,
        Folder = cfg.Folder or "BoomHoodVA", Loading = false,
    }
    Lib.Win = Win

    local gui = new("ScreenGui", { Name = "BoomHoodVA", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999 })
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
    gui.Parent = guiParent()
    Win.Gui = gui

    local stash = new("Frame", { Parent = gui, Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, Visible = false })

    keep(UIS.InputChanged:Connect(function(i) if active and isMove(i) then active.move(i.Position) end end))
    keep(UIS.InputEnded:Connect(function(i)
        if active and isPress(i) then
            local a = active
            active = nil
            if a.stop then a.stop() end
        end
    end))

    local modalBtn = new("TextButton", { Parent = gui, Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Modal = false })

    ----------------------------------------------------------------
    --  Корень (драг) → main (UIScale)
    ----------------------------------------------------------------
    local root = new("Frame", { Parent = gui, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, Visible = false })
    local main = new("Frame", { Parent = root, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = B"Bg" }, { corner(18), stk() })
    local scale = new("UIScale", { Parent = main })

    local function fit()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or V2(1280, 720)
        return clamp(math.min(vp.X / (W + 40), vp.Y / (H + 40)), 0.45, 1.25) * Win.UserScale
    end
    scale.Scale = fit()
    do
        local cam = workspace.CurrentCamera
        if cam then keep(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function() scale.Scale = fit() keepOnScreen(root) end)) end
    end

    local glass = {}
    local function glassT(obj, base)
        glass[#glass + 1] = { obj, base }
        obj.BackgroundTransparency = 1 - (1 - base) * Win.Opacity
    end
    glassT(main, 0.03)

    ----------------------------------------------------------------
    --  Сайдбар
    ----------------------------------------------------------------
    local side = new("Frame", { Parent = main, Position = UDim2.fromOffset(12, 12), Size = UDim2.new(0, 180, 1, -24), BackgroundColor3 = B"Side" }, { corner(14), stk() })
    glassT(side, 0.15)
    local brand = new("Frame", { Parent = side, Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1 })
    label(brand, cfg.Title or "BOOM HOOD", UDim2.fromOffset(16, 14), UDim2.new(1, -24, 0, 20), Enum.Font.GothamBlack, 16, B"Text")
    label(brand, cfg.Sub or "Visual Assistant", UDim2.fromOffset(16, 35), UDim2.new(1, -24, 0, 12), Enum.Font.GothamMedium, 10, B"Sub")
    local brandLine = new("Frame", { Parent = brand, Position = UDim2.new(0, 16, 1, -4), Size = UDim2.fromOffset(34, 2), BackgroundColor3 = B"Accent" }, { corner(1) })

    local nav = new("ScrollingFrame", { Parent = side, Position = UDim2.fromOffset(8, 66), Size = UDim2.new(1, -16, 1, -66 - 64), BackgroundTransparency = 1,
        ScrollBarThickness = 2, ScrollBarImageColor3 = B"Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = AUTO_Y, BorderSizePixel = 0 },
        { vlist(4) })

    local account = new("Frame", { Parent = side, AnchorPoint = V2(0, 1), Position = UDim2.new(0, 10, 1, -10), Size = UDim2.new(1, -20, 0, 48), BackgroundColor3 = B"Panel" }, { corner(12), stk() })
    new("ImageLabel", { Parent = account, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = B"Panel2",
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=100&h=100" }, { corner(16) })
    label(account, LocalPlayer.DisplayName, UDim2.fromOffset(48, 8), UDim2.new(1, -54, 0, 16), Enum.Font.GothamBold, 12, B"Text")
    label(account, cfg.Version or Lib.Version, UDim2.fromOffset(48, 25), UDim2.new(1, -54, 0, 14), Enum.Font.Gotham, 10, B"Sub")

    ----------------------------------------------------------------
    --  Тулбар
    ----------------------------------------------------------------
    local TBW = W - 204 - 12
    local toolbar = new("Frame", { Parent = main, Position = UDim2.fromOffset(204, 12), Size = UDim2.fromOffset(TBW, 46), BackgroundColor3 = B"Panel" }, { corner(14), stk() })
    glassT(toolbar, 0.15)

    local function tbBtn(rightOff, text, w)
        local b = new("TextButton", { Parent = toolbar, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -rightOff, 0.5, 0), Size = UDim2.fromOffset(w or 34, 32),
            BackgroundColor3 = B"Bg", Text = text, TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 14 }, { corner(10) })
        b.MouseEnter:Connect(function() tw(b, 0.15, { BackgroundColor3 = Theme.Panel2 }, SINE) end)
        b.MouseLeave:Connect(function() tw(b, 0.2, { BackgroundColor3 = Theme.Bg }, SINE) end)
        return b
    end
    local closeBtn = tbBtn(8, "×")
    local hideBtn = tbBtn(48, "–")
    local gearBtn = tbBtn(88, "Settings", 74)
    gearBtn.TextSize = 11
    closeBtn.MouseEnter:Connect(function() tw(closeBtn, 0.15, { BackgroundColor3 = rgb(220, 70, 80) }, SINE) end)

    local searchBack = new("Frame", { Parent = toolbar, Position = UDim2.fromOffset(8, 7), Size = UDim2.new(1, -176, 0, 32), BackgroundColor3 = B"Bg" }, { corner(10) })
    local searchBox = new("TextBox", { Parent = searchBack, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1,
        PlaceholderText = "Search modules…", PlaceholderColor3 = B"Sub", Text = "", TextColor3 = B"Text", TextSize = 13, ClearTextOnFocus = false, TextXAlignment = LEFT })

    local function canDrag() return Win.LockPos end
    drag(toolbar, root, canDrag)
    drag(brand, root, canDrag)

    ----------------------------------------------------------------
    --  Контент
    ----------------------------------------------------------------
    local content = new("Frame", { Parent = main, Position = UDim2.fromOffset(204, 70), Size = UDim2.fromOffset(TBW, H - 70 - 12), BackgroundColor3 = B"Bg",
        ClipsDescendants = true }, { corner(14), stk() })
    glassT(content, 0.08)
    local pageTitle = label(content, "", UDim2.fromOffset(20, 12), UDim2.new(1, -40, 0, 30), Enum.Font.GothamBold, 24, B"Text")
    local pageSub = label(content, "", UDim2.fromOffset(20, 44), UDim2.new(1, -40, 0, 16), Enum.Font.Gotham, 12, B"Sub")
    drag(pageTitle, root, canDrag)

    local scroll = new("ScrollingFrame", { Parent = content, Position = UDim2.fromOffset(4, 72), Size = UDim2.new(1, -8, 1, -80), BackgroundTransparency = 1,
        ScrollBarThickness = 3, ScrollBarImageColor3 = B"Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = AUTO_Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, BorderSizePixel = 0 }, { vlist(12), pad(0, 12, 12, 16) })
    local topHolder = new("Frame", { Parent = scroll, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 }, { vlist(12) })
    local colsHolder = new("Frame", { Parent = scroll, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 },
        { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }) })
    local function mkCol(o)
        return new("Frame", { Parent = colsHolder, LayoutOrder = o, Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 }, { vlist(12) })
    end
    local colL, colR = mkCol(1), mkCol(2)
    local emptyL = label(content, "Nothing found.", UDim2.fromOffset(0, 200), UDim2.new(1, 0, 0, 20), nil, 13, B"Sub", CENTER)
    emptyL.Visible = false

    ----------------------------------------------------------------
    --  Уведомления
    ----------------------------------------------------------------
    local nholder = new("Frame", { Parent = gui, AnchorPoint = V2(1, 0), Position = UDim2.new(1, -16, 0, 16), Size = UDim2.fromOffset(300, 500), BackgroundTransparency = 1, ZIndex = 100 })
    new("UIListLayout", { Parent = nholder, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder })
    local notifs = {}
    function Win:Notify(title, text, dur, kind, force)
        if Win.Destroyed or (not Win.NotifsOn and not force) then return end
        dur = dur or Win.NotifTime
        title, text = tostring(title or ""), tostring(text or "")
        local col = (typeof(kind) == "Color3" and kind) or Lib.Semantic[kind] or Theme.Accent
        local NW, TW = 290, 290 - 30
        local ok, sz = pcall(TextService.GetTextSize, TextService, text, 12, Enum.Font.Gotham, V2(TW, 1000))
        local textH = ok and sz.Y or 14
        local NH = 44 + textH
        while #notifs >= 5 do
            local old = table.remove(notifs, 1)
            if old then old() end
        end
        local wrap = new("Frame", { Parent = nholder, Size = UDim2.fromOffset(NW, NH), BackgroundTransparency = 1 })
        local card = new("Frame", { Parent = wrap, Position = UDim2.fromOffset(NW + 30, 0), Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Panel, ClipsDescendants = true },
            { corner(12), new("UIStroke", { Color = col, Thickness = 1, Transparency = 0.55 }) })
        new("Frame", { Parent = card, Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = col })
        label(card, title, UDim2.fromOffset(16, 8), UDim2.fromOffset(TW, 18), Enum.Font.GothamBold, 13, Theme.Text)
        local body = label(card, text, UDim2.fromOffset(16, 27), UDim2.fromOffset(TW, textH), Enum.Font.Gotham, 12, Theme.Sub)
        body.TextWrapped, body.TextTruncate, body.TextYAlignment = true, Enum.TextTruncate.None, Enum.TextYAlignment.Top
        local closing = false
        local function close()
            if closing then return end
            closing = true
            for i, f in ipairs(notifs) do if f == close then table.remove(notifs, i) break end end
            tw(card, 0.3, { Position = UDim2.fromOffset(NW + 30, 0) }, QUINT, IN)
            after(0.32, function() if wrap.Parent then wrap:Destroy() end end)
        end
        notifs[#notifs + 1] = close
        local hit = new("TextButton", { Parent = card, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5 })
        hit.MouseButton1Click:Connect(close)
        tw(card, 0.4, { Position = UDim2.fromOffset(0, 0) }, QUINT)
        task.delay(dur, close)
    end

    ----------------------------------------------------------------
    --  Подтверждение
    ----------------------------------------------------------------
    local confirm = new("Frame", { Parent = main, Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, Visible = false, ZIndex = 80 }, { corner(18) })
    local cBox = new("Frame", { Parent = confirm, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(330, 140),
        BackgroundColor3 = B"Panel", ZIndex = 81 }, { corner(14), stk() })
    local cTitle = label(cBox, "", UDim2.fromOffset(18, 16), UDim2.new(1, -36, 0, 22), Enum.Font.GothamBold, 16, B"Text") cTitle.ZIndex = 82
    local cText = label(cBox, "", UDim2.fromOffset(18, 42), UDim2.new(1, -36, 0, 40), Enum.Font.Gotham, 12, B"Sub") cText.ZIndex = 82
    cText.TextWrapped, cText.TextTruncate, cText.TextYAlignment = true, Enum.TextTruncate.None, Enum.TextYAlignment.Top
    local function cBtn(txt, xs, xo, accent)
        return new("TextButton", { Parent = cBox, Position = UDim2.new(xs, xo, 1, -46), Size = UDim2.new(0.5, -26, 0, 32),
            BackgroundColor3 = accent and B"Accent" or B"Panel2", Text = txt, TextColor3 = accent and B"OnAccent" or B"Text", Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 82 }, { corner(10) })
    end
    local cNo, cYes = cBtn("Cancel", 0, 18, false), cBtn("Yes", 0.5, 8, true)
    local confirmYes
    cNo.MouseButton1Click:Connect(function() confirm.Visible = false end)
    cYes.MouseButton1Click:Connect(function() confirm.Visible = false if confirmYes then fire(confirmYes) end end)
    function Win:Confirm(title, text, yes)
        cTitle.Text, cText.Text, confirmYes = title, text, yes
        confirm.BackgroundTransparency = 1
        confirm.Visible = true
        tw(confirm, 0.2, { BackgroundTransparency = 0.5 }, SINE)
    end

    ----------------------------------------------------------------
    --  Перетаскиваемые элементы (позиции сохраняются в конфиг)
    ----------------------------------------------------------------
    function Win:AddMovable(name, frame, handle, noDrag)
        local default = frame.Position
        if not noDrag then drag(handle or frame, frame, canDrag) end
        Win.Movables[name] = frame
        Lib.Flags["Pos_" .. name] = {
            Export = function() local p = frame.Position return { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset } end,
            Import = function(v)
                if type(v) == "table" and #v == 4 then
                    frame.Position = UDim2.new(v[1], v[2], v[3], v[4])
                    task.defer(keepOnScreen, frame)
                end
            end,
            Reset = function() frame.Position = default end,
        }
    end
    Win:AddMovable("Window", root, nil, true) -- у окна свои ручки (toolbar/brand/title)

    local openBtn = new("TextButton", { Parent = gui, AnchorPoint = V2(1, 1), Position = UDim2.new(1, -24, 1, -24), Size = UDim2.fromOffset(46, 46),
        BackgroundColor3 = B"Accent", Text = "BH", TextColor3 = B"OnAccent", Font = Enum.Font.GothamBlack, TextSize = 14, Visible = false, ZIndex = 70 }, { corner(23) })
    Win:AddMovable("OpenButton", openBtn)
    local openDownAt
    openBtn.InputBegan:Connect(function(i) if isPress(i) then openDownAt = openBtn.AbsolutePosition end end)

    ----------------------------------------------------------------
    --  Список включённых биндов (HUD, перетаскиваемый)
    ----------------------------------------------------------------
    local HUD = { Enabled = false, Title = "KEYBINDS" }
    Win.HUD = HUD
    local hud = new("Frame", { Parent = gui, Position = UDim2.fromOffset(18, 70), Size = UDim2.fromOffset(190, 0), AutomaticSize = AUTO_Y,
        BackgroundColor3 = B"Panel", Visible = false, ZIndex = 60 }, { corner(12), stk(), pad(8, 8, 8, 8), vlist(2) })
    local hudScale = new("UIScale", { Parent = hud })
    local hudTitle = label(hud, HUD.Title, nil, UDim2.new(1, 0, 0, 20), Enum.Font.GothamBlack, 11, B"Accent")
    hudTitle.LayoutOrder = 0
    Win:AddMovable("Keybinds", hud)

    local hudQueued = false
    local function rebuildHud()
        hudQueued = false
        for _, c in ipairs(hud:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        local n = 0
        for i, b in ipairs(Win.BindList) do
            if b.Key and b.State == true and b.Hud ~= false then
                n += 1
                local r = new("Frame", { Parent = hud, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 })
                label(r, tostring(b.Name or "?"), nil, UDim2.new(1, -60, 1, 0), nil, 12, B"Text")
                new("TextLabel", { Parent = r, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(0, 18), AutomaticSize = AUTO_X,
                    BackgroundColor3 = B"Accent", Text = keyName(b.Key), TextColor3 = B"OnAccent", Font = Enum.Font.GothamBold, TextSize = 10 },
                    { corner(6), pad(0, 0, 7, 7) })
            end
        end
        hud.Visible = HUD.Enabled and n > 0
        hudTitle.Visible = true
    end
    function Win:RefreshHud()
        if hudQueued then return end
        hudQueued = true
        task.defer(rebuildHud)
    end
    function Win:SetHud(k, v)
        HUD[k] = v
        if k == "Scale" then hudScale.Scale = v end
        if k == "Title" then hudTitle.Text = v end
        Win:RefreshHud()
    end

    ----------------------------------------------------------------
    --  Навигация и страницы
    ----------------------------------------------------------------
    local function paintNav()
        for _, c in ipairs(Win.Categories) do
            local on = c == Win.Current
            tw(c.Label, 0.2, { TextColor3 = on and Theme.Text or Theme.Sub }, SINE)
            tw(c.Btn, 0.2, { BackgroundTransparency = on and 0 or 1 }, SINE)
            tw(c.Bar, 0.2, { BackgroundTransparency = on and 0 or 1 }, SINE)
        end
    end
    onTheme(paintNav)

    local function layout()
        local cat = Win.Current
        if not cat then return end
        for _, m in ipairs(Win.Modules) do m.Card.Parent = stash end
        for _, c in ipairs(Win.Categories) do for _, t in ipairs(c.Tops) do t.Parent = stash end end
        local q = Win.Query
        local list = {}
        for _, m in ipairs(q ~= "" and Win.Modules or cat.Modules) do
            if q == "" or m.Search:find(q, 1, true) then list[#list + 1] = m end
        end
        local tops = 0
        if q == "" then for _, t in ipairs(cat.Tops) do t.Parent = topHolder tops += 1 end end
        for i, m in ipairs(list) do
            m.Card.LayoutOrder = i
            m.Card.Parent = (i % 2 == 1) and colL or colR
        end
        emptyL.Visible = (#list == 0 and tops == 0)
        pageTitle.Text = q ~= "" and "Search" or cat.Name
        pageSub.Text = q ~= "" and ('Results for "' .. searchBox.Text .. '"') or cat.Sub
        scroll.CanvasPosition = Vector2.zero
        if q == "" and cat.OnShow then task.defer(cat.OnShow) end
    end

    function Win:Select(cat)
        if type(cat) == "string" then
            for _, c in ipairs(Win.Categories) do if c.Name == cat then cat = c break end end
        end
        if type(cat) ~= "table" then return end
        Win.Current = cat
        paintNav()
        layout()
    end
    local function gotoCat(cat)
        if not cat then return end
        Win.Query = ""
        searchBox.Text = ""
        Win:Select(cat)
    end

    function Win:AddDivider()
        new("Frame", { Parent = nav, LayoutOrder = 1002 + #Win.Categories * 2, Size = UDim2.new(1, -8, 0, 1), BackgroundColor3 = B"Accent", BackgroundTransparency = 0.7 })
    end

    function Win:AddCategory(name, icon, sub)
        local cat = { Name = name, Sub = sub or "", Tops = {}, Modules = {} }
        local idx = #Win.Categories + 1
        local btn = new("TextButton", { Parent = nav, LayoutOrder = 1000 + idx * 2 + 1, Size = UDim2.new(1, -4, 0, 36), BackgroundColor3 = B"Panel2", BackgroundTransparency = 1 }, { corner(10) })
        cat.Btn = btn
        cat.Bar = new("Frame", { Parent = btn, Position = UDim2.fromOffset(0, 9), Size = UDim2.fromOffset(3, 18), BackgroundColor3 = B"Accent", BackgroundTransparency = 1 }, { corner(2) })
        if type(icon) == "number" or (type(icon) == "string" and icon:find("^rbxasset")) then
            new("ImageLabel", { Parent = btn, Position = UDim2.fromOffset(12, 9), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1,
                Image = type(icon) == "number" and ("rbxassetid://" .. icon) or icon })
        else
            local chip = new("TextLabel", { Parent = btn, Position = UDim2.fromOffset(12, 8), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = B"Panel2",
                Text = string.upper(string.sub(name, 1, 1)), TextColor3 = B"Accent", Font = Enum.Font.GothamBold, TextSize = 11 }, { corner(6) })
            chip.ZIndex = 2
        end
        cat.Label = label(btn, name, UDim2.fromOffset(42, 0), UDim2.new(1, -48, 1, 0), nil, 13, B"Sub")
        btn.MouseButton1Click:Connect(function() gotoCat(cat) end)

        function cat:AddCustom(h)
            local f = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = #cat.Tops + 1 })
            f.Parent = stash
            cat.Tops[#cat.Tops + 1] = f
            return f
        end

        ------------------------------------------------------------
        --  Модуль (карточка)
        ------------------------------------------------------------
        function cat:AddModule(o)
            o = o or {}
            local defKey = (o.Keybind ~= true) and o.Keybind or nil
            local mod = { Name = o.Name or "Module", Cat = cat, State = o.Default and true or false, Key = defKey, DefaultKey = defKey,
                Mode = o.Mode or "Toggle", DefaultMode = o.Mode or "Toggle", Static = o.Static, Hud = o.Hud ~= false, _n = 0,
                Search = ((o.Name or "") .. " " .. (o.Info or "")):lower() }

            local card = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundColor3 = B"Panel" },
                { corner(14), stk(), pad(12, 12, 14, 14), vlist(10) })
            card.Parent = stash
            glassT(card, 0.05)
            mod.Card = card

            local head = new("Frame", { Parent = card, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 })
            label(head, mod.Name, nil, UDim2.new(1, -64, 1, 0), Enum.Font.GothamBold, 15, B"Text")
            if o.Info then
                local sub = label(card, o.Info, nil, UDim2.new(1, 0, 0, 14), Enum.Font.Gotham, 11, B"Sub")
                sub.LayoutOrder = 2
            end

            local sf = new("Frame", { Parent = card, LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1, Visible = false }, { vlist(10) })
            mod.Settings = sf

            local expand
            local function setOpen(v)
                sf.Visible = v
                if expand then
                    expand.Text = v and "–" or "+"
                    expand.TextColor3 = v and Theme.Accent or Theme.Sub
                end
            end

            if mod.Static then
                sf.Visible = true
                function mod:Set() end
            else
                expand = new("TextButton", { Parent = head, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(24, 24),
                    BackgroundTransparency = 1, Text = "+", TextColor3 = B"Sub", Font = Enum.Font.GothamMedium, TextSize = 20 })
                expand.MouseButton1Click:Connect(function() setOpen(not sf.Visible) end)
                local sw = makeSwitch(head, mod.State, function(v) mod:Set(v) end)
                sw.Frame.Position = UDim2.new(1, -30, 0.5, 0) -- переключатель левее кнопки «+»

                function mod:Set(v, silent)
                    v = v and true or false
                    if mod.State == v then return end
                    mod.State = v
                    sw:Set(v, true)
                    if not silent then fire(o.Callback, v) end
                    Win:RefreshHud()
                end
                local kr
                local function changed() Win:RefreshHud() fire(o.KeyChanged, mod.Key) end
                kr = keyRow(sf, 0, "Keybind", mod, { "Toggle", "Hold" }, changed)
                mod.Press = function(down)
                    if mod.Mode == "Hold" then mod:Set(down) elseif down then mod:Set(not mod.State) end
                end
                Win.BindList[#Win.BindList + 1] = mod
                card.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then setOpen(not sf.Visible) end end)
                if mod.State then task.defer(fire, o.Callback, true) end

                if o.Flag then
                    Lib.Flags[o.Flag] = {
                        Export = function() return { State = mod.State, Key = mod.Key and mod.Key.Name or nil, Mode = mod.Mode } end,
                        Import = function(v)
                            if type(v) ~= "table" then return end
                            mod.Key = keyFromName(v.Key)
                            if v.Mode == "Hold" or v.Mode == "Toggle" then mod.Mode = v.Mode end
                            kr:Paint()
                            mod:Set(v.State)
                            Win:RefreshHud()
                        end,
                        Reset = function()
                            mod.Key, mod.Mode = mod.DefaultKey, mod.DefaultMode
                            kr:Paint()
                            mod:Set(o.Default and true or false)
                            Win:RefreshHud()
                        end,
                        Get = function() return mod.State end,
                        Set = function(_, v) mod:Set(v) end,
                    }
                end
            end

            function mod:Get() return mod.State end
            local function order() mod._n += 1 return mod._n + 1 end
            local function addWord(w) mod.Search = mod.Search .. " " .. tostring(w):lower() end

            function mod:AddToggle(t)
                addWord(t.Name or "")
                local def = t.Default and true or false
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 })
                label(row, t.Name or "Toggle", nil, UDim2.new(1, -56, 1, 0), nil, 13, B"Text")
                local sw = makeSwitch(row, def, function(v) fire(t.Callback, v) end)
                local api = {}
                function api:Set(v, silent) sw:Set(v, silent) end
                function api:Get() return sw:Get() end
                api.Export = function() return sw:Get() end
                api.Import = function(v) sw:Set(v and true or false) end
                api.Reset = function() sw:Set(def) end
                flag(t, api)
                if def then task.defer(fire, t.Callback, true) end
                return api
            end

            function mod:AddSlider(t)
                addWord(t.Name or "")
                local api = makeSlider(sf, t, order())
                flag(t, api)
                return api
            end

            function mod:AddOptions(t)
                addWord(t.Name or "")
                local opts = t.Options or {}
                local def = t.Default or opts[1]
                local sel = def
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 }, { vlist(6) })
                local nl = label(row, t.Name or "Options", nil, UDim2.new(1, 0, 0, 16), Enum.Font.GothamMedium, 12, B"Sub") nl.LayoutOrder = 1
                local wrapF = new("Frame", { Parent = row, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 },
                    { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
                local btns = {}
                local function paint()
                    for name, b in pairs(btns) do
                        local on = name == sel
                        tw(b, 0.2, { BackgroundColor3 = on and Theme.Accent or Theme.Panel2, TextColor3 = on and Theme.OnAccent or Theme.Sub }, SINE)
                    end
                end
                for i, name in ipairs(opts) do
                    local b = new("TextButton", { Parent = wrapF, LayoutOrder = i, Size = UDim2.fromOffset(0, 26), AutomaticSize = AUTO_X, BackgroundColor3 = B"Panel2",
                        Text = tostring(name), TextColor3 = B"Sub", Font = Enum.Font.GothamBold, TextSize = 11 }, { corner(8), pad(0, 0, 12, 12) })
                    btns[name] = b
                    b.MouseButton1Click:Connect(function()
                        if sel ~= name then sel = name paint() fire(t.Callback, name) end
                    end)
                end
                paint()
                onTheme(paint)
                local api = {}
                function api:Set(v, silent) if btns[v] and v ~= sel then sel = v paint() if not silent then fire(t.Callback, v) end end end
                function api:Get() return sel end
                api.Export = function() return sel end
                api.Import = function(v) api:Set(v) end
                api.Reset = function() api:Set(def) end
                flag(t, api)
                return api
            end

            function mod:AddDropdown(t)
                addWord(t.Name or "")
                local opts = t.Options or {}
                local def = t.Default or opts[1]
                local sel = def
                local ROW, ITEM, MAXV = 28, 26, 6
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, ROW), BackgroundTransparency = 1, ClipsDescendants = true })
                label(row, t.Name or "Dropdown", nil, UDim2.new(1, -150, 0, ROW), nil, 13, B"Text")
                local selL = label(row, tostring(sel or "-"), UDim2.new(1, -170, 0, 0), UDim2.fromOffset(150, ROW), Enum.Font.GothamBold, 12, B"Accent", RIGHT)
                local arrow = label(row, "v", UDim2.new(1, -14, 0, 0), UDim2.fromOffset(14, ROW), Enum.Font.GothamBold, 11, B"Sub", CENTER)
                local list = new("ScrollingFrame", { Parent = row, Position = UDim2.fromOffset(0, ROW + 4), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
                    ScrollBarThickness = 2, ScrollBarImageColor3 = B"Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = AUTO_Y, BorderSizePixel = 0 }, { vlist(4) })
                local open, btns = false, {}
                local function listH() return math.min(#opts, MAXV) * (ITEM + 4) end
                local function setOpen(v)
                    open = v
                    row.Size = UDim2.new(1, 0, 0, v and (ROW + 4 + listH()) or ROW)
                    list.Size = UDim2.new(1, 0, 0, v and listH() or 0)
                    arrow.Text = v and "^" or "v"
                end
                local function paint()
                    for name, b in pairs(btns) do
                        local on = name == sel
                        tw(b, 0.2, { BackgroundColor3 = on and Theme.Accent or Theme.Panel2, TextColor3 = on and Theme.OnAccent or Theme.Sub }, SINE)
                    end
                end
                local function choose(v, silent)
                    sel = v
                    selL.Text = tostring(v)
                    paint()
                    if not silent then fire(t.Callback, v) end
                end
                local function build()
                    for _, b in pairs(btns) do b:Destroy() end
                    btns = {}
                    for i, name in ipairs(opts) do
                        local b = new("TextButton", { Parent = list, LayoutOrder = i, Size = UDim2.new(1, -4, 0, ITEM), BackgroundColor3 = B"Panel2", Text = tostring(name),
                            TextColor3 = B"Sub", Font = Enum.Font.GothamMedium, TextSize = 12 }, { corner(8) })
                        btns[name] = b
                        b.MouseButton1Click:Connect(function() choose(name) setOpen(false) end)
                    end
                    paint()
                    if open then setOpen(true) end
                end
                build()
                onTheme(paint)
                local hdr = new("TextButton", { Parent = row, Size = UDim2.new(1, 0, 0, ROW), BackgroundTransparency = 1, ZIndex = 3 })
                hdr.MouseButton1Click:Connect(function() setOpen(not open) end)
                local api = {}
                function api:Set(v, silent) if btns[v] then choose(v, silent) end end
                function api:Get() return sel end
                function api:Refresh(newOpts)
                    opts = newOpts
                    if not table.find(opts, sel) then sel = opts[1] selL.Text = tostring(sel or "-") end
                    build()
                end
                api.Export = function() return sel end
                api.Import = function(v) api:Set(v) end
                api.Reset = function() api:Set(def) end
                flag(t, api)
                return api
            end

            function mod:AddButton(t)
                addWord(t.Name or "")
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 })
                label(row, t.Name or "Button", nil, UDim2.new(1, -90, 1, 0), nil, 13, B"Text")
                local b = new("TextButton", { Parent = row, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(78, 26),
                    BackgroundColor3 = B"Panel2", Text = t.ButtonText or "RUN", TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 11 }, { corner(8) })
                b.MouseEnter:Connect(function() tw(b, 0.15, { BackgroundColor3 = Theme.Accent, TextColor3 = Theme.OnAccent }, SINE) end)
                b.MouseLeave:Connect(function() tw(b, 0.2, { BackgroundColor3 = Theme.Panel2, TextColor3 = Theme.Text }, SINE) end)
                b.MouseButton1Click:Connect(function() fire(t.Callback) end)
                return { Row = row, Button = b }
            end

            function mod:AddTextbox(t)
                addWord(t.Name or "")
                local wide = t.Wide == true
                local def = t.Default or ""
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, wide and 56 or 30), BackgroundTransparency = 1 })
                label(row, t.Name or "Textbox", nil, wide and UDim2.new(1, 0, 0, 20) or UDim2.new(1, -150, 1, 0), nil, 13, B"Text")
                local back = new("Frame", { Parent = row, AnchorPoint = V2(1, wide and 1 or 0.5), Position = UDim2.new(1, 0, wide and 1 or 0.5, 0),
                    Size = wide and UDim2.new(1, 0, 0, 30) or UDim2.fromOffset(140, 28), BackgroundColor3 = B"Bg" }, { corner(9) })
                local box = new("TextBox", { Parent = back, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1,
                    PlaceholderText = t.Placeholder or "", PlaceholderColor3 = B"Sub", Text = def, TextColor3 = B"Text", TextSize = 12, ClearTextOnFocus = false, TextXAlignment = LEFT })
                box.FocusLost:Connect(function(enter) fire(t.Callback, box.Text, enter) end)
                local api = {}
                function api:Set(v) box.Text = tostring(v) end
                function api:Get() return box.Text end
                api.Export = function() return box.Text end
                api.Import = function(v) if type(v) == "string" then box.Text = v fire(t.Callback, v, true) end end
                api.Reset = function() box.Text = def fire(t.Callback, def, true) end
                flag(t, api)
                return api
            end

            function mod:AddLabel(text, h)
                local l = label(sf, text, nil, UDim2.new(1, 0, 0, h or 30), Enum.Font.Gotham, 11, B"Sub")
                l.LayoutOrder = order()
                l.TextWrapped, l.TextTruncate, l.TextYAlignment = true, Enum.TextTruncate.None, Enum.TextYAlignment.Top
                return l
            end
            function mod:AddCustom(h)
                return new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1 })
            end

            function mod:AddKeybind(t)
                addWord(t.Name or "")
                local MODES = { "Press", "Toggle", "Hold" }
                local b = { Name = t.Name, Key = t.Default, Mode = t.Mode or "Press", Callback = t.Callback, State = false, Hud = t.Hud ~= false }
                local defKey, defMode = b.Key, b.Mode
                local kr
                local function changed() Win:RefreshHud() fire(t.Changed, b.Key) end
                kr = keyRow(sf, order(), t.Name or "Keybind", b, MODES, changed)
                b.Press = function(down)
                    if b.Mode == "Press" then
                        if down then fire(b.Callback) end
                    elseif b.Mode == "Toggle" then
                        if down then b.State = not b.State fire(b.Callback, b.State) Win:RefreshHud() end
                    else
                        b.State = down
                        fire(b.Callback, down)
                        Win:RefreshHud()
                    end
                end
                Win.BindList[#Win.BindList + 1] = b
                local api = { Bind = b }
                function api:Get() return b.Key end
                api.Export = function() return { Key = b.Key and b.Key.Name or nil, Mode = b.Mode } end
                api.Import = function(v)
                    if type(v) ~= "table" then return end
                    b.Key = keyFromName(v.Key)
                    if v.Mode and table.find(MODES, v.Mode) then b.Mode = v.Mode end
                    b.State = false
                    kr:Paint()
                    changed()
                end
                api.Reset = function() b.Key, b.Mode, b.State = defKey, defMode, false kr:Paint() changed() end
                flag(t, api)
                return api
            end

            function mod:AddColorPicker(t)
                addWord(t.Name or "")
                local def = t.Default or WHITE
                local col = def
                local hh, ss, vv = col:ToHSV()
                local OPEN_H = 212
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, ClipsDescendants = true })
                label(row, t.Name or "Color", nil, UDim2.new(1, -120, 0, 26), nil, 13, B"Text")
                local hexL = label(row, "#FFFFFF", UDim2.new(1, -118, 0, 0), UDim2.fromOffset(70, 26), Enum.Font.GothamBold, 11, B"Sub", RIGHT)
                local sw = new("TextButton", { Parent = row, AnchorPoint = V2(1, 0), Position = UDim2.new(1, 0, 0, 3), Size = UDim2.fromOffset(40, 20), BackgroundColor3 = col },
                    { corner(7), new("UIStroke", { Color = WHITE, Transparency = 0.7, Thickness = 1 }) })
                local sv = new("Frame", { Parent = row, Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 112), BackgroundColor3 = Color3.fromHSV(hh, 1, 1), ClipsDescendants = true }, { corner(8) })
                new("Frame", { Parent = sv, Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, ZIndex = 2 }, { new("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
                new("Frame", { Parent = sv, Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, ZIndex = 3 }, { new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
                local svK = new("Frame", { Parent = sv, AnchorPoint = V2(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ZIndex = 4 },
                    { corner(6), new("UIStroke", { Color = WHITE, Thickness = 2 }) })
                local function kp(t2, c) return ColorSequenceKeypoint.new(t2, c) end
                local hue = new("Frame", { Parent = row, Position = UDim2.fromOffset(0, 154), Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = WHITE }, {
                    corner(7), new("UIGradient", { Color = ColorSequence.new({ kp(0, rgb(255, 0, 0)), kp(1 / 6, rgb(255, 255, 0)), kp(2 / 6, rgb(0, 255, 0)),
                        kp(3 / 6, rgb(0, 255, 255)), kp(4 / 6, rgb(0, 0, 255)), kp(5 / 6, rgb(255, 0, 255)), kp(1, rgb(255, 0, 0)) }) }) })
                local hK = new("Frame", { Parent = hue, AnchorPoint = V2(0.5, 0.5), Size = UDim2.fromOffset(8, 20), BackgroundColor3 = WHITE, ZIndex = 3 },
                    { corner(4), new("UIStroke", { Color = BLACK, Transparency = 0.3 }) })
                local hexBack = new("Frame", { Parent = row, Position = UDim2.fromOffset(0, 178), Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = B"Bg" }, { corner(9) })
                local hexBox = new("TextBox", { Parent = hexBack, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1,
                    PlaceholderText = "#RRGGBB", PlaceholderColor3 = B"Sub", Text = "", TextColor3 = B"Text", TextSize = 12, ClearTextOnFocus = false, TextXAlignment = LEFT })
                local lastE, trailing = 0, false
                local function emit()
                    local now = os.clock()
                    if now - lastE >= 0.06 then
                        lastE = now
                        fire(t.Callback, col)
                    elseif not trailing then
                        trailing = true
                        task.delay(0.06, function() trailing = false lastE = os.clock() fire(t.Callback, col) end)
                    end
                end
                local function refresh(silent)
                    col = Color3.fromHSV(hh, ss, vv)
                    sw.BackgroundColor3 = col
                    sv.BackgroundColor3 = Color3.fromHSV(hh, 1, 1)
                    svK.Position = UDim2.fromScale(ss, 1 - vv)
                    hK.Position = UDim2.fromScale(hh, 0.5)
                    hexL.Text = hex(col)
                    if not hexBox:IsFocused() then hexBox.Text = hex(col) end
                    if not silent then emit() end
                end
                refresh(true)
                local svHit = new("TextButton", { Parent = row, Position = sv.Position, Size = sv.Size, BackgroundTransparency = 1, ZIndex = 6 })
                local hueHit = new("TextButton", { Parent = row, Position = UDim2.fromOffset(0, 148), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, ZIndex = 6 })
                local function svMove(p)
                    ss = clamp((p.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
                    vv = 1 - clamp((p.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
                    refresh(false)
                end
                local function hueMove(p)
                    hh = clamp((p.X - hue.AbsolutePosition.X) / math.max(hue.AbsoluteSize.X, 1), 0, 0.999)
                    refresh(false)
                end
                svHit.InputBegan:Connect(function(i) if isPress(i) then svMove(i.Position) capture(svMove) end end)
                hueHit.InputBegan:Connect(function(i) if isPress(i) then hueMove(i.Position) capture(hueMove) end end)
                hexBox.FocusLost:Connect(function()
                    local c = parseHex(hexBox.Text)
                    if c then hh, ss, vv = c:ToHSV() end
                    refresh(not c)
                end)
                local open = false
                sw.MouseButton1Click:Connect(function()
                    open = not open
                    row.Size = UDim2.new(1, 0, 0, open and OPEN_H or 26)
                end)
                local api = {}
                function api:Set(c, silent) hh, ss, vv = c:ToHSV() refresh(silent) end
                function api:SetSilent(c) hh, ss, vv = c:ToHSV() refresh(true) end
                function api:Get() return col end
                api.Export = function() return { floor(col.R * 255 + 0.5), floor(col.G * 255 + 0.5), floor(col.B * 255 + 0.5) } end
                api.Import = function(v) if type(v) == "table" and #v == 3 then api:Set(rgb(v[1], v[2], v[3])) end end
                api.Reset = function() api:Set(def) end
                flag(t, api)
                return api
            end

            cat.Modules[#cat.Modules + 1] = mod
            Win.Modules[#Win.Modules + 1] = mod
            if Win.Current == cat then layout() end
            return mod
        end

        Win.Categories[idx] = cat
        return cat
    end

    ----------------------------------------------------------------
    --  Настройки окна
    ----------------------------------------------------------------
    function Win:SetOpacity(v)
        Win.Opacity = v
        for _, g in ipairs(glass) do
            if g[1].Parent then tw(g[1], 0.15, { BackgroundTransparency = 1 - (1 - g[2]) * v }, SINE) end
        end
    end
    function Win:SetTheme(def)
        Win.ThemeDef, Win.AccentOverride = def, nil
        applyTheme(def, nil, false)
        if Lib.Flags.AccentColor then Lib.Flags.AccentColor:SetSilent(Theme.Accent) end
    end
    function Win:SetAccent(c)
        Win.AccentOverride = c
        applyTheme(Win.ThemeDef, c, true)
    end
    function Win:SetScale(v) Win.UserScale = v tw(scale, 0.25, { Scale = fit() }, QUINT) end
    function Win:SetMenuKey(k) Win.ToggleKey = k end
    function Win:ResetPos()
        local f = Lib.Flags.Pos_Window
        if f then f.Reset() end
    end

    ----------------------------------------------------------------
    --  Открытие / закрытие
    ----------------------------------------------------------------
    local animTok = 0
    function Win:Show()
        if Win.Open or Win.Destroyed then return end
        Win.Open = true
        animTok += 1
        openBtn.Visible = false
        root.Visible = true
        modalBtn.Modal = Win.FreeMouse
        local s = fit()
        scale.Scale = s * 0.92
        tw(scale, 0.35, { Scale = s }, BACK)
        if Win.Current then layout() end
    end
    function Win:Hide()
        if not Win.Open then return end
        Win.Open = false
        animTok += 1
        local my = animTok
        modalBtn.Modal = false
        tw(scale, 0.2, { Scale = fit() * 0.92 }, QUINT, IN)
        after(0.2, function()
            if animTok ~= my then return end
            root.Visible = false
            openBtn.Visible = true
        end)
    end
    function Win:Toggle() if Win.Open then Win:Hide() else Win:Show() end end
    openBtn.MouseButton1Click:Connect(function()
        if openDownAt and (openBtn.AbsolutePosition - openDownAt).Magnitude > 6 then return end -- это был драг
        Win:Show()
    end)
    hideBtn.MouseButton1Click:Connect(function()
        Win:Hide()
        Win:Notify("Menu hidden", "Press " .. keyName(Win.ToggleKey) .. " or tap the BH button to open", 3)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        Win:Confirm("Unload?", "This closes the interface and removes every effect.", function() Win:Destroy() end)
    end)
    gearBtn.MouseButton1Click:Connect(function() gotoCat(Win.SettingsCat) end)

    ----------------------------------------------------------------
    --  Конфиги (JSON) / пресеты
    ----------------------------------------------------------------
    Lib.Flags.Theme = {
        Export = function() return { Name = Win.ThemeDef.Name } end,
        Import = function(v)
            if type(v) ~= "table" then return end
            for _, d in ipairs(THEMES) do if d.Name == v.Name then Win:SetTheme(d) return end end
        end,
        Reset = function() Win:SetTheme(THEMES[1]) end,
    }

    local function sortedNames(src)
        local keys = {}
        for f in pairs(src) do keys[#keys + 1] = f end
        table.sort(keys, function(a, b)
            if a == "Theme" then return b ~= "Theme" end
            if b == "Theme" then return false end
            return a < b
        end)
        return keys
    end

    function Win:ExportString()
        local data = {}
        for f, a in pairs(Lib.Flags) do
            if type(a) == "table" and a.Export then
                local ok, v = pcall(a.Export)
                if ok and v ~= nil then data[f] = v end
            end
        end
        return HttpService:JSONEncode(data)
    end
    function Win:ImportData(data)
        Win.Loading = true
        for _, f in ipairs(sortedNames(data)) do
            local a = Lib.Flags[f]
            if a and a.Import then pcall(a.Import, data[f]) end
        end
        Win.Loading = false
    end
    function Win:ImportString(s)
        local ok, data = pcall(function() return HttpService:JSONDecode(s) end)
        if not ok or type(data) ~= "table" then return false end
        Win:ImportData(data)
        return true
    end
    function Win:ResetAll()
        Win.Loading = true
        for _, f in ipairs(sortedNames(Lib.Flags)) do
            local a = Lib.Flags[f]
            if type(a) == "table" and a.Reset then pcall(a.Reset) end
        end
        Win.Loading = false
    end

    function Win:AddPreset(name, data) Win.Presets[#Win.Presets + 1] = { Name = name, Data = data } end
    function Win:ApplyPreset(name)
        for _, p in ipairs(Win.Presets) do
            if p.Name == name then Win:ImportData(p.Data) return true end
        end
        return false
    end

    local FOLDER = Win.Folder
    local function clean(n) return (tostring(n):gsub("[^%w_%- ]", "")) end
    local function ensure() pcall(function() if makefolder and isfolder and not isfolder(FOLDER) then makefolder(FOLDER) end end) end
    function Win:SaveConfig(name)
        name = clean(name)
        if not writefile or name == "" then return false end
        ensure()
        return (pcall(writefile, FOLDER .. "/" .. name .. ".json", Win:ExportString()))
    end
    function Win:LoadConfig(name)
        if not (readfile and isfile) then return false end
        local path = FOLDER .. "/" .. clean(name) .. ".json"
        if not isfile(path) then return false end
        local ok, s = pcall(readfile, path)
        return ok and Win:ImportString(s)
    end
    function Win:DeleteConfig(name)
        local path = FOLDER .. "/" .. clean(name) .. ".json"
        if not (delfile and isfile and isfile(path)) then return false end
        return (pcall(delfile, path))
    end
    function Win:ListConfigs()
        local out = {}
        if listfiles and isfolder and isfolder(FOLDER) then
            local ok, files = pcall(listfiles, FOLDER)
            if ok then
                for _, f in ipairs(files) do
                    local n = tostring(f):match("([^/\\]+)%.json$")
                    if n then out[#out + 1] = n end
                end
            end
        end
        table.sort(out)
        if #out == 0 then out = { "default" } end
        return out
    end
    function Win:SetAutoload(name)
        if not writefile then return false end
        ensure()
        return (pcall(writefile, FOLDER .. "/autoload.txt", clean(name)))
    end
    function Win:ClearAutoload()
        local p = FOLDER .. "/autoload.txt"
        if delfile and isfile and isfile(p) then pcall(delfile, p) end
    end

    function Win:Destroy()
        if Win.Destroyed then return end
        Win.Destroyed = true
        Win.Open = false
        pcall(function() modalBtn.Modal = false end)
        genv.BHVAUnload = nil
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        conns, reg, hooks = {}, {}, {}
        active, Lib._listen = nil, nil
        if Win.OnDestroy then pcall(Win.OnDestroy) end
        gui:Destroy()
        Lib.Flags = {}
    end
    genv.BHVAUnload = function() Win:Destroy() end

    ----------------------------------------------------------------
    --  Finish: Settings + Configs, затем показать окно
    ----------------------------------------------------------------
    function Win:Finish()
        if Win._finished then return end
        Win._finished = true
        Win:AddDivider()
        local st = Win:AddCategory("Settings", nil, "Theme, interface, overlays and notifications.")
        local cf = Win:AddCategory("Configs", nil, "Save, load, presets and import/export.")
        Win.SettingsCat = st

        -- сетка тем
        local cols = 3
        local rows = math.ceil(#THEMES / cols)
        local grid = st:AddCustom(rows * 74 + (rows - 1) * 10)
        new("UIGridLayout", { Parent = grid, CellSize = UDim2.new(1 / cols, -8, 0, 74), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder })
        for i, def in ipairs(THEMES) do
            local b = new("TextButton", { Parent = grid, LayoutOrder = i, BackgroundColor3 = B"Panel" }, { corner(12) })
            local s = new("UIStroke", { Thickness = 1, Parent = b })
            local mini = new("Frame", { Parent = b, Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 32), BackgroundColor3 = def.Bg }, { corner(7) })
            new("Frame", { Parent = mini, Position = UDim2.fromOffset(5, 5), Size = UDim2.fromOffset(12, 22), BackgroundColor3 = def.Panel2 }, { corner(4) })
            new("Frame", { Parent = mini, Position = UDim2.fromOffset(22, 5), Size = UDim2.new(1, -28, 0, 10), BackgroundColor3 = def.Accent }, { corner(4) })
            new("Frame", { Parent = mini, Position = UDim2.fromOffset(22, 19), Size = UDim2.new(0.5, 0, 0, 8), BackgroundColor3 = def.Panel }, { corner(4) })
            label(b, def.Name, UDim2.fromOffset(10, 48), UDim2.new(1, -20, 0, 18), Enum.Font.GothamBold, 12, B"Text")
            onTheme(function()
                local on = Win.ThemeDef == def
                s.Color = on and Theme.Accent or Theme.Stroke
                s.Transparency = on and 0.1 or Theme.StrokeT
                s.Thickness = on and 1.8 or 1
            end)
            b.MouseButton1Click:Connect(function() Win:SetTheme(def) end)
        end

        local th = st:AddModule({ Name = "Theme", Info = "Colors and transparency", Static = true })
        th:AddColorPicker({ Name = "Accent color", Default = Theme.Accent, Flag = "AccentColor", Callback = function(c) Win:SetAccent(c) end })
        th:AddSlider({ Name = "Window opacity", Min = 30, Max = 100, Default = 100, Suffix = "%", Flag = "UIOpacity", Callback = function(v) Win:SetOpacity(v / 100) end })

        local ui = st:AddModule({ Name = "Interface", Info = "Size, position and behavior", Static = true })
        ui:AddKeybind({ Name = "Toggle menu key", Default = Win.ToggleKey, Mode = "Press", Flag = "MenuKey", Hud = false,
            Changed = function(k) if k then Win:SetMenuKey(k) end end })
        ui:AddSlider({ Name = "Menu size", Min = 60, Max = 130, Default = 100, Suffix = "%", Flag = "UIScale", Callback = function(v) Win:SetScale(v / 100) end })
        ui:AddSlider({ Name = "Animation speed", Min = 0.5, Max = 2.5, Step = 0.1, Default = 1, Suffix = "x", Flag = "AnimSpeed", Callback = function(v) Lib.Speed = v end })
        ui:AddToggle({ Name = "Free mouse in menu", Default = true, Flag = "FreeMouse", Callback = function(v)
            Win.FreeMouse = v
            if Win.Open then modalBtn.Modal = v end
        end })
        ui:AddToggle({ Name = "Lock UI positions", Flag = "LockUI", Callback = function(v) Win.LockPos = v end })
        ui:AddButton({ Name = "Reset all UI positions", ButtonText = "RESET", Callback = function()
            for name in pairs(Win.Movables) do
                local f = Lib.Flags["Pos_" .. name]
                if f then f.Reset() end
            end
        end })

        local kb = st:AddModule({ Name = "Keybind list", Info = "Movable list of active binds", Static = true })
        kb:AddToggle({ Name = "Enabled", Flag = "HudOn", Callback = function(v) Win:SetHud("Enabled", v) end })
        kb:AddTextbox({ Name = "Title", Default = HUD.Title, Placeholder = "KEYBINDS", Flag = "HudTitle", Callback = function(t) Win:SetHud("Title", t) end })
        kb:AddSlider({ Name = "Size", Min = 60, Max = 160, Default = 100, Suffix = "%", Flag = "HudScale", Callback = function(v) Win:SetHud("Scale", v / 100) end })

        local nt = st:AddModule({ Name = "Notifications", Info = "Popup messages", Static = true })
        nt:AddToggle({ Name = "Enabled", Default = true, Flag = "Notifs", Callback = function(v) Win.NotifsOn = v end })
        nt:AddSlider({ Name = "Duration", Min = 1, Max = 10, Step = 0.5, Default = 3, Suffix = "s", Flag = "NotifTime", Callback = function(v) Win.NotifTime = v end })
        nt:AddButton({ Name = "Test notification", ButtonText = "TEST", Callback = function() Win:Notify("Visual Assistant", "This is a test notification", 3, "ok", true) end })

        -- пресеты интерфейса
        local function builtin(name, data)
            for _, p in ipairs(Win.Presets) do if p.Name == name then return end end
            Win:AddPreset(name, data)
        end
        builtin("Default", { Theme = { Name = "Lavender" }, UIOpacity = 100, UIScale = 100, HudScale = 100 })
        builtin("Crimson Glass", { Theme = { Name = "Crimson" }, UIOpacity = 82, UIScale = 100 })
        builtin("Ocean Compact", { Theme = { Name = "Ocean" }, UIOpacity = 95, UIScale = 85, HudScale = 85 })
        builtin("Mono Clean", { Theme = { Name = "Mono" }, UIOpacity = 100, UIScale = 100 })
        local pm = cf:AddModule({ Name = "UI presets", Info = "Ready-made looks for the interface", Static = true })
        for _, p in ipairs(Win.Presets) do
            pm:AddButton({ Name = p.Name, ButtonText = "APPLY", Callback = function()
                Win:ApplyPreset(p.Name)
                Win:Notify("Preset", "Applied: " .. p.Name, 2, "ok")
            end })
        end

        local cm = cf:AddModule({ Name = "Configs", Info = "Every flagged setting is stored as JSON", Static = true })
        local cfgName, cfgDD = "default", nil
        local function refresh() if cfgDD then cfgDD:Refresh(Win:ListConfigs()) end end
        cm:AddTextbox({ Name = "Config name", Placeholder = "default", Default = "default", Callback = function(t) if t ~= "" then cfgName = t end end })
        cfgDD = cm:AddDropdown({ Name = "Saved configs", Options = Win:ListConfigs(), Default = "default", Callback = function(v) cfgName = v end })
        cm:AddButton({ Name = "Save config", ButtonText = "SAVE", Callback = function()
            if Win:SaveConfig(cfgName) then Win:Notify("Config", "Saved: " .. cfgName, 3, "ok") refresh()
            else Win:Notify("Config", "writefile is not available", 3, "err") end end })
        cm:AddButton({ Name = "Load config", ButtonText = "LOAD", Callback = function()
            if Win:LoadConfig(cfgName) then Win:Notify("Config", "Loaded: " .. cfgName, 3, "ok")
            else Win:Notify("Config", "Config not found", 3, "err") end end })
        cm:AddButton({ Name = "Delete config", ButtonText = "DELETE", Callback = function()
            if Win:DeleteConfig(cfgName) then Win:Notify("Config", "Deleted: " .. cfgName, 3, "warn") refresh()
            else Win:Notify("Config", "Nothing to delete", 3, "err") end end })
        cm:AddButton({ Name = "Autoload this config", ButtonText = "SET", Callback = function()
            if Win:SetAutoload(cfgName) then Win:Notify("Config", "Autoload: " .. cfgName, 3, "ok")
            else Win:Notify("Config", "writefile is not available", 3, "err") end end })
        cm:AddButton({ Name = "Clear autoload", ButtonText = "CLEAR", Callback = function() Win:ClearAutoload() Win:Notify("Config", "Autoload cleared", 3, "warn") end })
        cm:AddButton({ Name = "Refresh list", ButtonText = "SCAN", Callback = refresh })
        cm:AddButton({ Name = "Copy config to clipboard", ButtonText = "COPY", Callback = function()
            local fn = setclipboard or toclipboard
            if fn then pcall(fn, Win:ExportString()) Win:Notify("Config", "Copied", 3, "ok")
            else Win:Notify("Config", "Clipboard is not available", 3, "warn") end end })
        local importText = ""
        cm:AddTextbox({ Name = "Import from text", Placeholder = "paste config JSON", Callback = function(t) importText = t end })
        cm:AddButton({ Name = "Apply imported text", ButtonText = "APPLY", Callback = function()
            if importText ~= "" and Win:ImportString(importText) then Win:Notify("Config", "Imported", 3, "ok")
            else Win:Notify("Config", "Invalid config text", 3, "err") end end })
        cm:AddButton({ Name = "Reset ALL settings", ButtonText = "RESET", Callback = function()
            Win:Confirm("Reset everything?", "All settings, keybinds and UI positions go back to defaults.", function()
                Win:ResetAll()
                Win:Notify("Settings", "Everything reset", 3, "warn")
            end)
        end })

        Win:Select(Win.Categories[1])
        Win:Show()

        task.delay(1, function()
            pcall(function()
                local p = FOLDER .. "/autoload.txt"
                if isfile and readfile and isfile(p) then
                    local name = readfile(p):match("^%s*(.-)%s*$")
                    if name and name ~= "" and Win:LoadConfig(name) then Win:Notify("Config", "Autoloaded: " .. name, 3, "ok") end
                end
            end)
        end)
    end

    ----------------------------------------------------------------
    --  Поиск и бинды
    ----------------------------------------------------------------
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
        if q == Win.Query then return end
        Win.Query = q
        if Win.Current then layout() end
    end)

    local function fireBinds(input, down)
        if UIS:GetFocusedTextBox() then return end
        for _, b in ipairs(Win.BindList) do
            if b.Press and keyMatch(b.Key, input) then
                if down then b.Press(true) elseif b.Mode == "Hold" then b.Press(false) end
            end
        end
    end
    keep(UIS.InputBegan:Connect(function(input, gp)
        if Lib._listen then
            local ut = input.UserInputType
            if ut == Enum.UserInputType.Keyboard then
                local f = Lib._listen
                Lib._listen = nil
                f(input.KeyCode)
            elseif ut == Enum.UserInputType.MouseButton2 or ut == Enum.UserInputType.MouseButton3 then
                local f = Lib._listen
                Lib._listen = nil
                f(ut)
            end
            return
        end
        if gp then return end
        fireBinds(input, true)
        if input.KeyCode == Win.ToggleKey and not UIS:GetFocusedTextBox() then Win:Toggle() end
    end))
    keep(UIS.InputEnded:Connect(function(input) fireBinds(input, false) end))

    return Win
end

function Lib:GetFlag(name)
    local a = Lib.Flags[name]
    if a and a.Get then return a:Get() end
    return nil
end

return Lib