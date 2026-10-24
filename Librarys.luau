--[[
    FEMBOYSENSE HUB — UI Library v2 (Eclipse-style)
    + нарисованные иконки (grid / swords / eye / globe / monitor / keyboard / sparkles / palette ...)
    + анимации: волны при открытии, скользящий индикатор вкладок, каскадное появление карточек,
      плавное раскрытие настроек, hover-подсветка карточек, пресс-анимация переключателей,
      каскад карточек тем.

    RightShift — скрыть/показать | ПКМ по модулю — настройки | СКМ по модулю — бинд
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Debris           = game:GetService("Debris")
local LocalPlayer      = Players.LocalPlayer

local genv = (getgenv and getgenv()) or _G
if genv.FemboysenseUnload then pcall(genv.FemboysenseUnload) end

local rgb, WHITE = Color3.fromRGB, Color3.new(1, 1, 1)
local SINE, QUINT, BACK = Enum.EasingStyle.Sine, Enum.EasingStyle.Quint, Enum.EasingStyle.Back
local OUT, IN = Enum.EasingDirection.Out, Enum.EasingDirection.In
local AUTO_Y, AUTO_NONE = Enum.AutomaticSize.Y, Enum.AutomaticSize.None

local Lib = { Flags = {}, Version = "v2.0" }

--=====================================================================
--  THEMES
--=====================================================================
local DARK = {
    Bg = rgb(8, 8, 10), Side = rgb(17, 17, 20), Panel = rgb(26, 26, 30), Panel2 = rgb(40, 40, 46),
    Text = rgb(244, 244, 247), Sub = rgb(146, 146, 154), Stroke = WHITE, StrokeT = 0.93,
}
local LIGHT = {
    Bg = rgb(232, 232, 238), Side = rgb(246, 246, 250), Panel = rgb(255, 255, 255), Panel2 = rgb(233, 233, 240),
    Text = rgb(22, 22, 27), Sub = rgb(108, 108, 120), Stroke = Color3.new(0, 0, 0), StrokeT = 0.92,
}
local THEMES = {
    { Name = "Mono",     Mode = "Dark",  Accent = rgb(227, 228, 230) },
    { Name = "Lavender", Mode = "Dark",  Accent = rgb(184, 160, 237) },
    { Name = "Midnight", Mode = "Dark",  Accent = rgb(145, 175, 229) },
    { Name = "Rose",     Mode = "Dark",  Accent = rgb(229, 165, 188) },
    { Name = "Mono",     Mode = "Light", Accent = rgb(70, 70, 78) },
    { Name = "Lavender", Mode = "Light", Accent = rgb(150, 120, 220) },
    { Name = "Midnight", Mode = "Light", Accent = rgb(100, 140, 215) },
    { Name = "Rose",     Mode = "Light", Accent = rgb(220, 120, 155) },
}
Lib.Themes = THEMES

local Theme = {}
local function loadTheme(def)
    local base = def.Mode == "Light" and LIGHT or DARK
    for k, v in pairs(base) do Theme[k] = v end
    Theme.Accent = def.Accent
    Theme.OnAccent = def.Mode == "Light" and WHITE or rgb(12, 12, 14)
end
loadTheme(THEMES[1])
Lib.Theme = Theme

local reg, hooks, conns = {}, {}, {}
local function keep(c) table.insert(conns, c) return c end
local function onTheme(fn) table.insert(hooks, fn) fn(true) end

local function tw(obj, t, props, style, dir)
    local tr = TweenService:Create(obj, TweenInfo.new(math.max(t, 0.01), style or QUINT, dir or OUT), props)
    tr:Play()
    return tr
end

local function B(key) return { __bind = key } end
local function bind(obj, prop, key)
    obj[prop] = Theme[key]
    table.insert(reg, { obj, prop, key })
end

local function applyTheme(def)
    loadTheme(def)
    for _, e in ipairs(reg) do
        pcall(function() tw(e[1], 0.35, { [e[2]] = Theme[e[3]] }, SINE) end)
    end
    for _, f in ipairs(hooks) do task.spawn(pcall, f) end
end

--=====================================================================
--  HELPERS
--=====================================================================
local function new(class, props, kids)
    local o = Instance.new(class)
    if o:IsA("GuiObject") then o.BorderSizePixel = 0 end
    if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
        o.AutoLocalize = false
        o.Font = Enum.Font.GothamMedium
    end
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
local function stk(th)
    return new("UIStroke", {
        Color = B"Stroke", Transparency = B"StrokeT", Thickness = th or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end
local function pad(t, b, l, r)
    return new("UIPadding", {
        PaddingTop = UDim.new(0, t), PaddingBottom = UDim.new(0, b),
        PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r),
    })
end
local function label(parent, text, pos, size, font, ts, color, align, extra)
    local l = new("TextLabel", {
        Parent = parent, Text = text, Position = pos or UDim2.new(), Size = size or UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Font = font or Enum.Font.GothamMedium, TextSize = ts or 13,
        TextColor3 = color or B"Text", TextXAlignment = align or Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    for k, v in pairs(extra or {}) do l[k] = v end
    return l
end
local function fire(cb, ...)
    if not cb then return end
    local a = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(cb, table.unpack(a, 1, a.n))
        if not ok then warn("[Femboysense] " .. tostring(err)) end
    end)
end
local function isPress(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end
local function guiParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

--=====================================================================
--  ICONS (нарисованы из Frame + UIStroke, в стиле Lucide)
--  Можно передать и свой rbxassetid в AddCategory / AddModule.
--=====================================================================
local ICON_ALIAS = {
    ["all modules"] = "grid", combat = "swords", visuals = "eye", world = "globe", interface = "monitor",
    utility = "keyboard", cosmetics = "sparkles", appearance = "palette", settings = "sliders", configs = "layers",
    movement = "arrow", aim = "target", esp = "target", misc = "layers", weather = "globe", player = "user",
}

local function makeIcon(parent, name, pos, px)
    px = px or 18
    local h = new("Frame", { Parent = parent, Position = pos or UDim2.new(), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1 })
    if px ~= 18 then new("UIScale", { Parent = h, Scale = px / 18 }) end
    local parts = {}
    local function ring(x, y, w, hh, r, par)
        local f = new("Frame", { Parent = par or h, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, hh), BackgroundTransparency = 1 }, { corner(r) })
        local s = new("UIStroke", { Color = Theme.Sub, Thickness = 1.5, Parent = f })
        parts[#parts + 1] = { s, "Color" }
        return f
    end
    local function fill(x, y, w, hh, r)
        local f = new("Frame", { Parent = h, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, hh), BackgroundColor3 = Theme.Sub }, { corner(r or 1) })
        parts[#parts + 1] = { f, "BackgroundColor3" }
        return f
    end
    local function bar(cx, cy, w, hh, rot)
        local f = new("Frame", {
            Parent = h, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
            Size = UDim2.fromOffset(w, hh), Rotation = rot or 0, BackgroundColor3 = Theme.Sub,
        }, { corner(math.ceil(hh / 2)) })
        parts[#parts + 1] = { f, "BackgroundColor3" }
        return f
    end

    if name == "grid" then
        ring(1, 1, 7, 7, 2) ring(10, 1, 7, 7, 2) ring(1, 10, 7, 7, 2) ring(10, 10, 7, 7, 2)
    elseif name == "swords" then
        bar(9, 9, 20, 1.8, 45) bar(9, 9, 20, 1.8, -45)
        bar(4, 14, 6, 1.8, -45) bar(14, 14, 6, 1.8, 45)
        bar(14, 4, 5, 1.8, 45) bar(4, 4, 5, 1.8, -45)
    elseif name == "eye" then
        ring(0, 3, 18, 12, 6) fill(6.5, 6.5, 5, 5, 3)
    elseif name == "globe" then
        ring(1, 1, 16, 16, 8) bar(9, 9, 16, 1.4, 0) ring(5, 1, 8, 16, 4)
    elseif name == "monitor" then
        ring(1, 2, 16, 11, 3) fill(8, 13, 2, 3, 1) fill(5, 16, 8, 1.6, 1)
    elseif name == "keyboard" then
        ring(0, 3, 18, 12, 3) fill(4, 6.5, 2, 2, 1) fill(8, 6.5, 2, 2, 1) fill(12, 6.5, 2, 2, 1) fill(5, 10.5, 8, 1.6, 1)
    elseif name == "sparkles" then
        bar(7, 8, 2, 14, 0) bar(7, 8, 14, 2, 0) bar(7, 8, 8, 1.4, 45) bar(7, 8, 8, 1.4, -45)
        bar(14.5, 3.5, 1.5, 6, 0) bar(14.5, 3.5, 6, 1.5, 0) fill(3, 14, 3, 3, 2)
    elseif name == "palette" then
        ring(1, 1, 16, 16, 8) fill(4.5, 6, 3, 3, 2) fill(9.5, 4, 3, 3, 2) fill(12, 9, 3, 3, 2) fill(5, 11, 3, 3, 2)
    elseif name == "sliders" then
        fill(1, 4, 16, 1.5, 1) fill(1, 9, 16, 1.5, 1) fill(1, 14, 16, 1.5, 1)
        fill(10, 2, 5, 5, 3) fill(3, 7, 5, 5, 3) fill(11, 12, 5, 5, 3)
    elseif name == "user" then
        ring(5, 1, 8, 8, 4)
        local clip = new("Frame", { Parent = h, Position = UDim2.fromOffset(1, 11), Size = UDim2.fromOffset(16, 7), BackgroundTransparency = 1, ClipsDescendants = true })
        ring(1, 0, 14, 14, 7, clip)
    elseif name == "layers" then
        ring(2, 2, 14, 4, 2) ring(2, 7, 14, 4, 2) ring(2, 12, 14, 4, 2)
    elseif name == "arrow" then
        bar(9, 9, 14, 1.8, -45) fill(8, 2, 8, 1.8, 1) fill(14.2, 2, 1.8, 8, 1)
    elseif name == "target" then
        ring(1, 1, 16, 16, 8) ring(4.5, 4.5, 9, 9, 5) fill(8, 8, 2, 2, 1)
    elseif name == "chat" then
        ring(1, 1, 16, 13, 6) bar(5, 15, 4, 1.8, -45)
    elseif name == "search" then
        ring(1, 1, 11, 11, 6) bar(14.5, 14.5, 6, 2, 45)
    else
        ring(2, 2, 14, 14, 4)
    end

    local icon = { Holder = h }
    function icon:Paint(c, instant)
        for _, p in ipairs(parts) do
            if instant then p[1][p[2]] = c else tw(p[1], 0.25, { [p[2]] = c }, SINE) end
        end
    end
    function icon:Bind(key)
        onTheme(function(inst) icon:Paint(Theme[key], inst == true) end)
        return icon
    end
    return icon
end

local function resolveIcon(parent, icon, fallbackName, pos, px)
    -- число / rbxassetid → картинка; строка → нарисованная иконка
    if type(icon) == "number" then icon = "rbxassetid://" .. icon end
    if type(icon) == "string" and icon:find("rbx") then
        local im = new("ImageLabel", { Parent = parent, Position = pos, Size = UDim2.fromOffset(px or 18, px or 18), BackgroundTransparency = 1, Image = icon, ImageColor3 = Theme.Sub })
        return { Holder = im, Paint = function(_, c, inst) if inst then im.ImageColor3 = c else tw(im, 0.25, { ImageColor3 = c }, SINE) end end,
            Bind = function(self, key) onTheme(function(i) self:Paint(Theme[key], i == true) end) return self end }
    end
    local n = type(icon) == "string" and icon or ICON_ALIAS[(fallbackName or ""):lower()] or "square"
    return makeIcon(parent, n, pos, px)
end

local SHORT = {
    RightShift = "RSHIFT", LeftShift = "LSHIFT", RightControl = "RCTRL", LeftControl = "LCTRL",
    RightAlt = "RALT", LeftAlt = "LALT", Return = "ENTER", Backspace = "BKSP", Escape = "ESC",
}
local function keyName(k) return k and (SHORT[k.Name] or string.upper(k.Name)) or "" end

local function drag(handle, target)
    local dragging, start, startPos
    handle.InputBegan:Connect(function(i)
        if isPress(i) then dragging, start, startPos = true, i.Position, target.Position end
    end)
    keep(UserInputService.InputChanged:Connect(function(i)
        if dragging and isMove(i) then
            local d = i.Position - start
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    keep(UserInputService.InputEnded:Connect(function(i)
        if isPress(i) then dragging = false end
    end))
end

--=====================================================================
--  WIDGETS
--=====================================================================
local function makeSwitch(parent, init, cb, pos)
    local state = init and true or false
    local track = new("TextButton", {
        Parent = parent, AnchorPoint = Vector2.new(1, 0.5), Position = pos or UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(40, 22), BackgroundColor3 = Theme.Bg,
    }, { corner(11) })
    local press = new("UIScale", { Parent = track })
    local knob = new("Frame", {
        Parent = track, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), BackgroundColor3 = WHITE,
    }, { corner(8) })
    local sw = {}
    local function paint(instant)
        local col = state and Theme.Accent:Lerp(Theme.Panel2, 0.38) or Theme.Bg
        local p = state and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        if instant then track.BackgroundColor3, knob.Position = col, p
        else tw(track, 0.25, { BackgroundColor3 = col }, SINE) tw(knob, 0.4, { Position = p }, BACK) end
    end
    paint(true)
    onTheme(function() paint(false) end)
    function sw:Set(v, silent)
        v = v and true or false
        if v == state then return end
        state = v
        paint(false)
        if not silent and cb then cb(v) end
    end
    function sw:Get() return state end
    track.MouseButton1Down:Connect(function() tw(press, 0.1, { Scale = 0.92 }, SINE) end)
    track.MouseButton1Up:Connect(function() tw(press, 0.3, { Scale = 1 }, BACK) end)
    track.MouseLeave:Connect(function() tw(press, 0.2, { Scale = 1 }, SINE) end)
    track.MouseButton1Click:Connect(function() sw:Set(not state) end)
    sw.Frame = track
    return sw
end

local function makeSlider(parent, o)
    local mn, mx, step = o.Min or 0, o.Max or 100, o.Step or 1
    local value = math.clamp(o.Default or mn, mn, mx)
    local f = new("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, LayoutOrder = o.Order or 0 })
    label(f, o.Name or "Slider", UDim2.new(), UDim2.new(1, -70, 0, 18), Enum.Font.GothamMedium, 13, B"Text")
    local out = label(f, "", UDim2.new(1, 0, 0, 0), UDim2.fromOffset(70, 18), Enum.Font.GothamBold, 12, B"Sub", Enum.TextXAlignment.Right)
    out.AnchorPoint = Vector2.new(1, 0)
    local bar = new("Frame", { Parent = f, Position = UDim2.new(0, 0, 0, 29), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = B"Bg" }, { corner(2) })
    local fill = new("Frame", { Parent = bar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = B"Accent" }, { corner(2) })
    local knob = new("Frame", {
        Parent = bar, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(12, 12), BackgroundColor3 = WHITE, ZIndex = 2,
    }, { corner(6) })
    local function fmt(v)
        if step >= 1 then return string.format("%d", v) end
        return string.format(step < 0.1 and "%.2f" or "%.1f", v)
    end
    local function render(fast)
        local r = (value - mn) / (mx - mn)
        out.Text = fmt(value) .. (o.Suffix or "")
        tw(fill, fast and 0.06 or 0.3, { Size = UDim2.fromScale(r, 1) }, SINE)
        tw(knob, fast and 0.06 or 0.3, { Position = UDim2.fromScale(r, 0.5) }, SINE)
    end
    local api = {}
    local function setv(v, silent, fast)
        v = math.clamp(math.floor((v - mn) / step + 0.5) * step + mn, mn, mx)
        if v == value then return end
        value = v
        render(fast)
        if not silent then fire(o.Callback, v) end
    end
    render(false)
    local hit = new("TextButton", { Parent = f, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, ZIndex = 3 })
    local dragging = false
    local function fromX(x)
        local r = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        setv(mn + (mx - mn) * r, false, true)
    end
    hit.InputBegan:Connect(function(i)
        if isPress(i) then
            dragging = true
            tw(knob, 0.2, { Size = UDim2.fromOffset(16, 16) }, BACK)
            fromX(i.Position.X)
        end
    end)
    keep(UserInputService.InputChanged:Connect(function(i)
        if dragging and isMove(i) then fromX(i.Position.X) end
    end))
    keep(UserInputService.InputEnded:Connect(function(i)
        if dragging and isPress(i) then
            dragging = false
            tw(knob, 0.3, { Size = UDim2.fromOffset(12, 12) }, QUINT)
        end
    end))
    function api:Set(v, silent) setv(v, silent, false) end
    function api:Get() return value end
    api.Frame = f
    return api
end

local function flag(o, api)
    if o.Flag then Lib.Flags[o.Flag] = api end
end

--=====================================================================
--  WINDOW
--=====================================================================
function Lib:CreateWindow(cfg)
    cfg = cfg or {}
    local W, H = 880, 580
    local Win = {
        Categories = {}, Modules = {}, Current = nil, Query = "", Glass = cfg.Glass ~= false,
        userScale = 1, Open = true, HudOn = cfg.ActiveBinds ~= false, ToggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift,
        ThemeDef = THEMES[1],
    }

    local gui = new("ScreenGui", {
        Name = "FemboysenseHub", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999, Parent = guiParent(),
    })
    Win.Gui = gui

    local root = new("Frame", {
        Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, ZIndex = 2,
    })
    local scale = new("UIScale", { Parent = root })
    local function fit()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        return math.clamp(math.min(vp.X / (W + 40), vp.Y / (H + 40)), 0.4, 1.3) * Win.userScale
    end
    do
        local cam = workspace.CurrentCamera
        if cam then keep(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function() scale.Scale = fit() end)) end
    end

    -- «звуковая волна» при открытии (как Opening effect на сайте)
    local function waves()
        for i = 1, 3 do
            task.delay((i - 1) * 0.13, function()
                if not gui.Parent then return end
                local f = new("Frame", {
                    Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = root.Position,
                    Size = UDim2.fromOffset(260, 260), BackgroundTransparency = 1, ZIndex = 1,
                }, { corner(1000) })
                local s = new("UIStroke", { Color = Theme.Accent, Thickness = 2.2, Transparency = 0.35, Parent = f })
                tw(f, 1.2, { Size = UDim2.fromOffset(1500, 1500) }, QUINT)
                tw(s, 1.2, { Transparency = 1, Thickness = 0.5 }, SINE)
                Debris:AddItem(f, 1.4)
            end)
        end
    end
    scale.Scale = fit() * 0.82
    tw(scale, 0.8, { Scale = fit() }, BACK)
    waves()

    local glassObjs = {}
    local function glassT(obj, glassVal)
        table.insert(glassObjs, { obj, glassVal })
        obj.BackgroundTransparency = Win.Glass and glassVal or 0
    end

    local main = new("Frame", { Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = B"Bg" }, { corner(22) })
    glassT(main, 0.06)
    local mainStroke = new("UIStroke", {
        Color = B"Accent", Transparency = 0.7, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = main,
    })
    -- мягкая пульсация рамки
    task.spawn(function()
        while gui.Parent do
            task.wait(0.05)
            if Win.Open then
                local t = os.clock()
                mainStroke.Transparency = (Win._glowBase or 0.67) + math.sin(t * 1.6) * 0.06
            end
        end
    end)

    ------------------------------------------------------------------
    --  SIDEBAR
    ------------------------------------------------------------------
    local side = new("Frame", {
        Parent = main, Position = UDim2.fromOffset(14, 14), Size = UDim2.new(0, 196, 1, -28), BackgroundColor3 = B"Side",
    }, { corner(18), stk() })
    glassT(side, 0.1)

    local brand = new("Frame", { Parent = side, Size = UDim2.new(1, 0, 0, 74), BackgroundTransparency = 1 })
    do
        local logo = new("Frame", { Parent = brand, Position = UDim2.fromOffset(18, 20), Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 1 })
        local b1 = new("Frame", { Parent = logo, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(0, 34), Size = UDim2.fromOffset(7, 20), BackgroundColor3 = B"Text" }, { corner(2) })
        local b2 = new("Frame", { Parent = logo, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(13, 34), Size = UDim2.fromOffset(7, 34), BackgroundColor3 = B"Text" }, { corner(2) })
        local b3 = new("Frame", { Parent = logo, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(26, 34), Size = UDim2.fromOffset(7, 26), BackgroundColor3 = B"Text" }, { corner(2) })
        -- «эквалайзер» оживает при открытии
        for i, b in ipairs({ b1, b2, b3 }) do
            local target = b.Size
            b.Size = UDim2.fromOffset(7, 2)
            task.delay(0.25 + i * 0.1, function() tw(b, 0.7, { Size = target }, BACK) end)
        end
        label(brand, cfg.Title or "FEMBOYSENSE", UDim2.fromOffset(62, 20), UDim2.new(1, -68, 0, 20), Enum.Font.GothamBlack, 15, B"Text")
        label(brand, cfg.Sub or "HUB", UDim2.fromOffset(62, 40), UDim2.new(1, -68, 0, 12), Enum.Font.GothamMedium, 9, B"Sub")
    end

    local NAV_STEP = 44
    local nav = new("ScrollingFrame", {
        Parent = side, Position = UDim2.fromOffset(10, 80), Size = UDim2.new(1, -20, 1, -80 - 112),
        BackgroundTransparency = 1, ScrollBarThickness = 0, CanvasSize = UDim2.new(),
    })
    local navInd = new("Frame", {
        Parent = nav, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = B"Panel2", Visible = false, ZIndex = 1,
    }, {
        corner(12),
        new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.65) }) }),
        stk(),
    })

    label(side, (cfg.Version or "1.0") .. " / " .. (cfg.Platform or "LUAU"),
        UDim2.new(0, 22, 1, -108), UDim2.new(1, -30, 0, 14), Enum.Font.GothamMedium, 9, B"Sub")

    local account = new("TextButton", {
        Parent = side, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12),
        Size = UDim2.new(1, -24, 0, 58), BackgroundColor3 = B"Panel",
    }, { corner(14), stk() })
    new("ImageLabel", {
        Parent = account, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = B"Panel2",
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=100&h=100",
    }, { corner(17) })
    label(account, LocalPlayer.DisplayName, UDim2.fromOffset(54, 12), UDim2.new(1, -86, 0, 18), Enum.Font.GothamBold, 13, B"Text")
    label(account, "Configs", UDim2.fromOffset(54, 30), UDim2.new(1, -86, 0, 14), Enum.Font.Gotham, 10, B"Sub")
    local accArrow = label(account, ">", UDim2.new(1, -24, 0, 0), UDim2.fromOffset(14, 58), Enum.Font.GothamBold, 13, B"Sub", Enum.TextXAlignment.Center)
    account.MouseEnter:Connect(function()
        tw(account, 0.25, { BackgroundColor3 = Theme.Panel2 }, SINE)
        tw(accArrow, 0.3, { Position = UDim2.new(1, -20, 0, 0) }, QUINT)
    end)
    account.MouseLeave:Connect(function()
        tw(account, 0.3, { BackgroundColor3 = Theme.Panel }, SINE)
        tw(accArrow, 0.3, { Position = UDim2.new(1, -24, 0, 0) }, QUINT)
    end)

    ------------------------------------------------------------------
    --  TOOLBAR
    ------------------------------------------------------------------
    local TBW = W - 238
    local toolbar = new("Frame", {
        Parent = main, Position = UDim2.fromOffset(224, 14), Size = UDim2.fromOffset(TBW, 52), BackgroundColor3 = B"Panel",
    }, { corner(16), stk() })
    glassT(toolbar, 0.1)

    local chip = new("Frame", { Parent = toolbar, Position = UDim2.fromOffset(9, 9), Size = UDim2.fromOffset(150, 34), BackgroundColor3 = B"Bg" }, { corner(11) })
    makeIcon(chip, "globe", UDim2.fromOffset(12, 9), 16):Bind("Text")
    label(chip, cfg.Version or "1.0", UDim2.fromOffset(38, 0), UDim2.fromOffset(60, 34), Enum.Font.GothamBold, 14, B"Text")
    label(chip, cfg.Platform or "LUAU", UDim2.new(1, -60, 0, 0), UDim2.fromOffset(50, 34), Enum.Font.GothamMedium, 9, B"Sub", Enum.TextXAlignment.Right)

    local function tbBtn(rightOff, text)
        local b = new("TextButton", {
            Parent = toolbar, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -rightOff, 0.5, 0),
            Size = UDim2.fromOffset(36, 36), BackgroundColor3 = B"Bg", Text = text or "",
            TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 12,
        }, { corner(11) })
        local sc = new("UIScale", { Parent = b })
        b.MouseEnter:Connect(function() tw(b, 0.2, { BackgroundColor3 = Theme.Panel2 }, SINE) tw(sc, 0.25, { Scale = 1.06 }, BACK) end)
        b.MouseLeave:Connect(function() tw(b, 0.25, { BackgroundColor3 = Theme.Bg }, SINE) tw(sc, 0.25, { Scale = 1 }, SINE) end)
        b.MouseButton1Down:Connect(function() tw(sc, 0.08, { Scale = 0.92 }, SINE) end)
        b.MouseButton1Up:Connect(function() tw(sc, 0.25, { Scale = 1.06 }, BACK) end)
        return b
    end
    local settingsBtn = tbBtn(9, "")
    makeIcon(settingsBtn, "sliders", UDim2.fromOffset(9, 9), 18):Bind("Text")
    local langChip = tbBtn(53, "EN")
    local chatBtn = tbBtn(97, "")
    makeIcon(chatBtn, "chat", UDim2.fromOffset(9, 9), 18):Bind("Text")

    local searchBack = new("Frame", {
        Parent = toolbar, Position = UDim2.fromOffset(168, 7), Size = UDim2.new(1, -168 - 150, 0, 38), BackgroundColor3 = B"Bg",
    }, { corner(12) })
    local searchStroke = new("UIStroke", { Color = B"Accent", Transparency = 1, Thickness = 1.2, Parent = searchBack })
    local searchIcon = makeIcon(searchBack, "search", UDim2.fromOffset(13, 11), 16):Bind("Sub")
    local searchBox = new("TextBox", {
        Parent = searchBack, Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1,
        PlaceholderText = "Search modules…", PlaceholderColor3 = B"Sub", Text = "", TextColor3 = B"Text",
        TextSize = 13, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
    })
    searchBox.Focused:Connect(function()
        tw(searchStroke, 0.25, { Transparency = 0.45 }, SINE)
        searchIcon:Paint(Theme.Text)
    end)
    searchBox.FocusLost:Connect(function()
        tw(searchStroke, 0.3, { Transparency = 1 }, SINE)
        searchIcon:Paint(Theme.Sub)
    end)

    drag(toolbar, root)
    drag(brand, root)

    ------------------------------------------------------------------
    --  CONTENT
    ------------------------------------------------------------------
    local content = new("Frame", {
        Parent = main, Position = UDim2.fromOffset(224, 80), Size = UDim2.fromOffset(TBW, H - 80 - 38), BackgroundColor3 = B"Bg",
        ClipsDescendants = true,
    }, { corner(18), stk() })

    local titleL = label(content, "", UDim2.fromOffset(22, 14), UDim2.new(1, -220, 0, 32), Enum.Font.GothamBold, 26, B"Text")
    local subL = label(content, "", UDim2.fromOffset(22, 48), UDim2.new(1, -220, 0, 16), Enum.Font.Gotham, 12, B"Sub")
    drag(content, root)

    -- Solid / Glass (только в Appearance) со скользящим ползунком
    local matBox = new("Frame", {
        Parent = content, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 18),
        Size = UDim2.fromOffset(150, 32), BackgroundColor3 = B"Panel", Visible = false,
    }, { corner(10), stk() })
    local matPill = new("Frame", {
        Parent = matBox, Position = UDim2.new(0.5, 3, 0, 3), Size = UDim2.new(0.5, -6, 1, -6), BackgroundColor3 = B"Panel2", ZIndex = 1,
    }, { corner(8) })
    local matBtns = {}
    for i, name in ipairs({ "Solid", "Glass" }) do
        local b = new("TextButton", {
            Parent = matBox, Position = UDim2.new((i - 1) / 2, 3, 0, 3), Size = UDim2.new(0.5, -6, 1, -6),
            BackgroundTransparency = 1, Text = name, TextSize = 12, TextColor3 = B"Sub", Font = Enum.Font.GothamBold, ZIndex = 2,
        })
        matBtns[name] = b
        b.MouseButton1Click:Connect(function() Win:SetGlass(name == "Glass") end)
    end
    local function paintMat()
        for name, b in pairs(matBtns) do
            local on = (name == "Glass") == Win.Glass
            tw(b, 0.25, { TextColor3 = on and Theme.Text or Theme.Sub }, SINE)
        end
        tw(matPill, 0.4, { Position = Win.Glass and UDim2.new(0.5, 3, 0, 3) or UDim2.new(0, 3, 0, 3) }, QUINT)
    end
    onTheme(paintMat)

    local scroll = new("ScrollingFrame", {
        Parent = content, Position = UDim2.fromOffset(14, 80), Size = UDim2.new(1, -28, 1, -92), BackgroundTransparency = 1,
        ScrollBarThickness = 3, ScrollBarImageColor3 = B"Accent", CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
    }, { new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }), pad(0, 10, 0, 8) })

    local topHolder = new("Frame", {
        Parent = scroll, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1,
    }, { new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }) })
    local colsHolder = new("Frame", {
        Parent = scroll, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1,
    }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }) })
    local function mkCol(order)
        return new("Frame", {
            Parent = colsHolder, LayoutOrder = order, Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = AUTO_Y,
            BackgroundTransparency = 1,
        }, { new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }) })
    end
    local colL, colR = mkCol(1), mkCol(2)
    local emptyL = label(content, "Nothing found.", UDim2.fromOffset(0, 200), UDim2.new(1, 0, 0, 20), Enum.Font.GothamMedium, 13, B"Sub",
        Enum.TextXAlignment.Center)
    emptyL.Visible = false

    label(main, "RSHIFT · CLOSE / RIGHT CLICK · SETTINGS", UDim2.fromOffset(238, H - 30), UDim2.fromOffset(340, 14),
        Enum.Font.GothamMedium, 10, B"Sub")
    label(main, "Interactive preview", UDim2.new(1, -250, 1, -30), UDim2.fromOffset(236, 14),
        Enum.Font.GothamMedium, 10, B"Sub", Enum.TextXAlignment.Right)

    ------------------------------------------------------------------
    --  TOOLTIP / NOTIFY / HUD
    ------------------------------------------------------------------
    local tip = new("TextLabel", {
        Parent = gui, Size = UDim2.new(0, 0, 0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = B"Panel2",
        Text = "", TextColor3 = B"Text", TextSize = 11, Visible = false, ZIndex = 200,
    }, { corner(8), stk(), pad(0, 0, 10, 10) })
    Lib._showTip = function(text, obj)
        if not text or text == "" then return end
        tip.Text = text
        tip.Position = UDim2.fromOffset(obj.AbsolutePosition.X, obj.AbsolutePosition.Y - 32)
        tip.Visible = true
    end
    Lib._hideTip = function() tip.Visible = false end

    local nholder = new("Frame", {
        Parent = gui, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.fromOffset(290, 400), BackgroundTransparency = 1, ZIndex = 100,
    }, { new("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right }) })

    function Win:Notify(title, text, dur)
        dur = dur or 3
        text = tostring(text or "")
        local wrap = new("Frame", { Parent = nholder, Size = UDim2.fromOffset(280, 64), BackgroundTransparency = 1 })
        local c = new("CanvasGroup", {
            Parent = wrap, Position = UDim2.fromOffset(320, 0), Size = UDim2.fromScale(1, 1), BackgroundColor3 = B"Panel",
            GroupTransparency = 1,
        }, { corner(14), stk() })
        new("Frame", { Parent = c, Position = UDim2.fromOffset(12, 14), Size = UDim2.fromOffset(3, 36), BackgroundColor3 = B"Accent" }, { corner(2) })
        label(c, tostring(title), UDim2.fromOffset(26, 10), UDim2.new(1, -36, 0, 18), Enum.Font.GothamBold, 13, B"Text")
        label(c, text, UDim2.fromOffset(26, 30), UDim2.new(1, -36, 0, 28), Enum.Font.Gotham, 11, B"Sub", nil,
            { TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None })
        local prog = new("Frame", { Parent = c, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = B"Accent" })
        tw(c, 0.55, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 }, QUINT)
        tw(prog, dur, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
        task.delay(dur, function()
            if not wrap.Parent then return end
            tw(c, 0.4, { Position = UDim2.fromOffset(320, 0), GroupTransparency = 1 }, QUINT, IN)
            task.delay(0.45, function() wrap:Destroy() end)
        end)
    end

    local hud = new("Frame", {
        Parent = gui, Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(200, 0), AutomaticSize = AUTO_Y,
        BackgroundColor3 = B"Panel", BackgroundTransparency = 0.06, Visible = false,
    }, { corner(14), stk(), pad(12, 12, 14, 14), new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
    label(hud, "Active binds", nil, UDim2.new(1, 0, 0, 18), Enum.Font.GothamBold, 13, B"Text", nil, { LayoutOrder = 0 })
    local hudRows = {}
    function Win:RefreshHud()
        for _, r in ipairs(hudRows) do r:Destroy() end
        hudRows = {}
        local n = 0
        for _, m in ipairs(Win.Modules) do
            if m.Key then
                n += 1
                local row = new("Frame", { Parent = hud, LayoutOrder = n, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1 })
                label(row, m.Name, nil, UDim2.new(1, -50, 1, 0), Enum.Font.GothamMedium, 12, m.State and B"Text" or B"Sub")
                local k = new("TextLabel", {
                    Parent = row, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = B"Panel2",
                    Text = keyName(m.Key), TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 10,
                }, { corner(6), pad(0, 0, 8, 8) })
                table.insert(hudRows, row)
            end
        end
        local was = hud.Visible
        hud.Visible = Win.HudOn and n > 0
    end

    ------------------------------------------------------------------
    --  LAYOUT / SELECTION
    ------------------------------------------------------------------
    local function layout()
        local q = Win.Query
        local cat = Win.Current
        for _, m in ipairs(Win.Modules) do m.Card.Parent = nil end
        for _, c in ipairs(Win.Categories) do for _, t in ipairs(c.Tops) do t.Parent = nil end end
        local list = {}
        for _, m in ipairs(Win.Modules) do
            local show
            if q ~= "" then
                show = m.Name:lower():find(q, 1, true) or (m.Info or ""):lower():find(q, 1, true)
            elseif cat.All then show = true
            else show = (m.Cat == cat) end
            if show then list[#list + 1] = m end
        end
        for i, m in ipairs(list) do
            m.Card.Parent = (i % 2 == 1) and colL or colR
            m.Card.GroupTransparency = 1
            task.delay(0.05 + (i - 1) * 0.05, function()
                if m.Card.Parent then tw(m.Card, 0.5, { GroupTransparency = 0 }, SINE) end
            end)
        end
        local tops = 0
        if q == "" then
            for _, t in ipairs(cat.Tops) do t.Parent = topHolder tops += 1 end
            if cat.OnShow then task.defer(cat.OnShow) end
        end
        emptyL.Visible = (#list == 0 and tops == 0)
        local tt, st
        if q ~= "" then tt, st = "Search", string.format('Results for "%s"', searchBox.Text)
        else tt, st = cat.Name, cat.Sub end
        titleL.Text, subL.Text = tt, st
        titleL.TextTransparency, subL.TextTransparency = 1, 1
        tw(titleL, 0.45, { TextTransparency = 0 }, SINE)
        tw(subL, 0.6, { TextTransparency = 0 }, SINE)
        matBox.Visible = (q == "" and cat.Name == "Appearance")
        scroll.CanvasPosition = Vector2.zero
        scroll.Position = UDim2.fromOffset(14, 98)
        tw(scroll, 0.55, { Position = UDim2.fromOffset(14, 80) }, QUINT)
    end

    local function paintNav()
        for _, c in ipairs(Win.Categories) do
            local on = (c == Win.Current)
            tw(c.Label, 0.25, { TextColor3 = on and Theme.Text or Theme.Sub }, SINE)
            c.Icon:Paint(on and Theme.Text or Theme.Sub)
        end
    end
    onTheme(paintNav)

    function Win:Select(cat)
        local first = (Win.Current == nil)
        Win.Current = cat
        paintNav()
        navInd.Visible = true
        local p = UDim2.fromOffset(0, (cat.Index - 1) * NAV_STEP)
        if first then navInd.Position = p else tw(navInd, 0.5, { Position = p }, QUINT) end
        layout()
    end

    function Win:AddCategory(name, icon, sub, isAll)
        local cat = { Name = name, Sub = sub or "", Tops = {}, All = isAll, Index = #Win.Categories + 1 }
        local btn = new("TextButton", {
            Parent = nav, Position = UDim2.fromOffset(0, (cat.Index - 1) * NAV_STEP), Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1, ZIndex = 2,
        })
        nav.CanvasSize = UDim2.fromOffset(0, cat.Index * NAV_STEP)
        cat.Icon = resolveIcon(btn, icon, name, UDim2.fromOffset(14, 11), 18)
        cat.Btn = btn
        cat.Label = label(btn, name, UDim2.fromOffset(44, 0), UDim2.new(1, -52, 1, 0), Enum.Font.GothamMedium, 14, B"Sub")
        cat.Label.ZIndex = 3
        btn.MouseEnter:Connect(function()
            if Win.Current ~= cat then
                tw(cat.Label, 0.2, { TextColor3 = Theme.Text }, SINE)
                tw(cat.Label, 0.3, { Position = UDim2.fromOffset(48, 0) }, QUINT)
                cat.Icon:Paint(Theme.Text)
            end
        end)
        btn.MouseLeave:Connect(function()
            tw(cat.Label, 0.3, { Position = UDim2.fromOffset(44, 0) }, QUINT)
            if Win.Current ~= cat then
                tw(cat.Label, 0.25, { TextColor3 = Theme.Sub }, SINE)
                cat.Icon:Paint(Theme.Sub)
            end
        end)
        btn.MouseButton1Click:Connect(function()
            searchBox.Text = ""
            Win.Query = ""
            Win:Select(cat)
        end)

        function cat:AddTop(frame) frame.LayoutOrder = #cat.Tops + 1 table.insert(cat.Tops, frame) return frame end

        function cat:AddModule(o)
            o = o or {}
            local mod = {
                Name = o.Name or "Module", Info = o.Info, Cat = cat, State = o.Default and true or false,
                Key = o.Keybind, Static = o.Static, _n = 0,
            }
            local card = new("CanvasGroup", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundColor3 = B"Panel",
            }, { corner(16), pad(14, 14, 16, 16), new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
            local cardStroke = stk()
            cardStroke.Parent = card
            glassT(card, 0.12)
            mod.Card = card

            card.MouseEnter:Connect(function()
                tw(card, 0.3, { BackgroundColor3 = Theme.Panel:Lerp(Theme.Panel2, 0.45) }, SINE)
                tw(cardStroke, 0.3, { Color = Theme.Accent, Transparency = 0.7 }, SINE)
            end)
            card.MouseLeave:Connect(function()
                tw(card, 0.35, { BackgroundColor3 = Theme.Panel }, SINE)
                tw(cardStroke, 0.35, { Color = Theme.Stroke, Transparency = Theme.StrokeT }, SINE)
            end)

            -- header
            local head = new("Frame", { Parent = card, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 })
            local left = new("Frame", { Parent = head, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1 },
                { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 9), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })
            do
                local iconHolder = new("Frame", { Parent = left, LayoutOrder = 1, Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1 })
                resolveIcon(iconHolder, o.Icon, mod.Name, UDim2.fromOffset(1, 1), 18):Bind("Text")
            end
            new("TextLabel", {
                Parent = left, LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1, Text = mod.Name, TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 15,
            })
            if o.Info then
                local i = new("TextButton", {
                    Parent = left, LayoutOrder = 3, Size = UDim2.fromOffset(15, 15), BackgroundTransparency = 1, Text = "i",
                    TextColor3 = B"Sub", Font = Enum.Font.GothamBold, TextSize = 9,
                }, { corner(8), new("UIStroke", { Color = B"Sub", Thickness = 1, Transparency = 0.4 }) })
                i.MouseEnter:Connect(function() Lib._showTip(o.Info, i) end)
                i.MouseLeave:Connect(function() Lib._hideTip() end)
            end

            local sf = new("Frame", {
                Parent = card, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y,
                BackgroundTransparency = 1, Visible = false,
            }, { new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
            local sfLayout = sf:FindFirstChildOfClass("UIListLayout")
            mod.Settings = sf

            local expand
            local open, tok = false, 0
            local function setOpen(v, instant)
                open = v
                tok += 1
                local my = tok
                if expand then tw(expand, 0.35, { Rotation = v and 45 or 0, TextColor3 = v and Theme.Text or Theme.Sub }, BACK) end
                if instant then
                    sf.Visible = v
                    return
                end
                task.spawn(function()
                    if v then
                        sf.ClipsDescendants = true
                        sf.AutomaticSize = AUTO_Y
                        sf.Visible = true
                        RunService.Heartbeat:Wait()
                        if tok ~= my then return end
                        local hgt = sfLayout.AbsoluteContentSize.Y
                        sf.AutomaticSize = AUTO_NONE
                        sf.Size = UDim2.new(1, 0, 0, 0)
                        tw(sf, 0.45, { Size = UDim2.new(1, 0, 0, hgt) }, QUINT).Completed:Wait()
                        if tok ~= my then return end
                        sf.AutomaticSize = AUTO_Y
                        sf.ClipsDescendants = false
                    else
                        local hgt = sf.AbsoluteSize.Y
                        sf.ClipsDescendants = true
                        sf.AutomaticSize = AUTO_NONE
                        sf.Size = UDim2.new(1, 0, 0, hgt)
                        tw(sf, 0.35, { Size = UDim2.new(1, 0, 0, 0) }, QUINT).Completed:Wait()
                        if tok ~= my then return end
                        sf.Visible = false
                        sf.AutomaticSize = AUTO_Y
                        sf.ClipsDescendants = false
                    end
                end)
            end
            if mod.Static then
                setOpen(true, true)
            else
                expand = new("TextButton", {
                    Parent = head, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(22, 22),
                    BackgroundTransparency = 1, Text = "+", TextColor3 = B"Sub", Font = Enum.Font.GothamMedium, TextSize = 20,
                })
                expand.MouseButton1Click:Connect(function() setOpen(not open) end)

                local status = new("Frame", { Parent = card, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 })
                local stL = label(status, mod.State and "Enabled" or "Disabled", nil, UDim2.new(1, -120, 1, 0), Enum.Font.GothamMedium, 13, B"Sub")
                local kbd = new("TextLabel", {
                    Parent = status, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -50, 0.5, 0),
                    Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = B"Panel2",
                    Text = "", TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 10, Visible = false,
                }, { corner(6), pad(0, 0, 8, 8) })
                local sw
                sw = makeSwitch(status, mod.State, function(v) mod:Set(v) end)
                function mod:_paintKey()
                    kbd.Text = keyName(mod.Key)
                    kbd.Visible = mod.Key ~= nil
                end
                function mod:Set(v, silent)
                    v = v and true or false
                    if mod.State == v then return end
                    mod.State = v
                    stL.Text = v and "Enabled" or "Disabled"
                    tw(stL, 0.3, { TextColor3 = v and Theme.Text or Theme.Sub }, SINE)
                    sw:Set(v, true)
                    if not silent then fire(o.Callback, v) end
                    Win:RefreshHud()
                end
                function mod:SetKey(k)
                    mod.Key = k
                    mod:_paintKey()
                    Win:RefreshHud()
                    fire(o.KeyChanged, k)
                end
                mod:_paintKey()
                if mod.State then
                    stL.TextColor3 = Theme.Text
                    task.defer(fire, o.Callback, true)
                end

                card.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton2 then
                        setOpen(not open)
                    elseif i.UserInputType == Enum.UserInputType.MouseButton3 then
                        kbd.Visible = true
                        kbd.Text = "..."
                        Lib._listen = function(kc)
                            if kc == Enum.KeyCode.Escape or kc == Enum.KeyCode.Backspace then mod:SetKey(nil)
                            else mod:SetKey(kc) end
                        end
                    end
                end)
            end
            if mod.Static then
                function mod:Set() end
                function mod:SetKey() end
            end

            function mod:Get() return mod.State end
            local function order() mod._n += 1 return mod._n end

            function mod:AddToggle(t)
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 })
                label(row, t.Name or "Toggle", nil, UDim2.new(1, -56, 1, 0), Enum.Font.GothamMedium, 13, B"Text")
                local sw = makeSwitch(row, t.Default, function(v) fire(t.Callback, v) end)
                local api = {}
                function api:Set(v, silent) sw:Set(v, silent) end
                function api:Get() return sw:Get() end
                api.Export = function() return sw:Get() end
                api.Import = function(v) sw:Set(v and true or false) end
                flag(t, api)
                if t.Default then task.defer(fire, t.Callback, true) end
                return api
            end

            function mod:AddSlider(t)
                t.Order = order()
                local api = makeSlider(sf, t)
                api.Export = function() return api:Get() end
                api.Import = function(v) if type(v) == "number" then api:Set(v) end end
                flag(t, api)
                return api
            end

            function mod:AddOptions(t)
                local opts = t.Options or {}
                local sel = t.Default or opts[1]
                local row = new("Frame", {
                    Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y,
                    BackgroundTransparency = 1,
                }, { new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
                label(row, t.Name or "Options", nil, UDim2.new(1, 0, 0, 16), Enum.Font.GothamMedium, 12, B"Sub", nil, { LayoutOrder = 1 })
                local wrapF = new("Frame", {
                    Parent = row, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1,
                }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
                local btns = {}
                local function paint()
                    for name, b in pairs(btns) do
                        local on = name == sel
                        tw(b, 0.3, {
                            BackgroundColor3 = on and Theme.Accent or Theme.Panel2,
                            TextColor3 = on and Theme.OnAccent or Theme.Sub,
                        }, SINE)
                    end
                end
                for i, name in ipairs(opts) do
                    local b = new("TextButton", {
                        Parent = wrapF, LayoutOrder = i, Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundColor3 = B"Panel2", Text = tostring(name), TextColor3 = B"Sub", Font = Enum.Font.GothamBold, TextSize = 11,
                    }, { corner(8), pad(0, 0, 12, 12) })
                    btns[name] = b
                    b.MouseButton1Click:Connect(function()
                        if sel == name then return end
                        sel = name
                        paint()
                        fire(t.Callback, name)
                    end)
                end
                paint()
                onTheme(paint)
                local api = {}
                function api:Set(v, silent)
                    if btns[v] and v ~= sel then sel = v paint() if not silent then fire(t.Callback, v) end end
                end
                function api:Get() return sel end
                api.Export = function() return sel end
                api.Import = function(v) api:Set(v) end
                flag(t, api)
                return api
            end

            function mod:AddButton(t)
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 })
                label(row, t.Name or "Button", nil, UDim2.new(1, -90, 1, 0), Enum.Font.GothamMedium, 13, B"Text")
                local b = new("TextButton", {
                    Parent = row, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(78, 26),
                    BackgroundColor3 = B"Panel2", Text = t.ButtonText or "RUN", TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 11,
                }, { corner(8) })
                local sc = new("UIScale", { Parent = b })
                b.MouseEnter:Connect(function() tw(b, 0.2, { BackgroundColor3 = Theme.Accent, TextColor3 = Theme.OnAccent }, SINE) end)
                b.MouseLeave:Connect(function() tw(b, 0.25, { BackgroundColor3 = Theme.Panel2, TextColor3 = Theme.Text }, SINE) end)
                b.MouseButton1Down:Connect(function() tw(sc, 0.08, { Scale = 0.9 }, SINE) end)
                b.MouseButton1Up:Connect(function() tw(sc, 0.3, { Scale = 1 }, BACK) end)
                b.MouseButton1Click:Connect(function() fire(t.Callback) end)
            end

            function mod:AddTextbox(t)
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 })
                label(row, t.Name or "Textbox", nil, UDim2.new(1, -150, 1, 0), Enum.Font.GothamMedium, 13, B"Text")
                local back = new("Frame", {
                    Parent = row, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(140, 28),
                    BackgroundColor3 = B"Bg",
                }, { corner(9) })
                local bs = new("UIStroke", { Color = B"Accent", Transparency = 1, Thickness = 1.2, Parent = back })
                local box = new("TextBox", {
                    Parent = back, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1,
                    PlaceholderText = t.Placeholder or "", PlaceholderColor3 = B"Sub", Text = t.Default or "", TextColor3 = B"Text",
                    TextSize = 12, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
                })
                box.Focused:Connect(function() tw(bs, 0.25, { Transparency = 0.4 }, SINE) end)
                box.FocusLost:Connect(function(enter) tw(bs, 0.3, { Transparency = 1 }, SINE) fire(t.Callback, box.Text, enter) end)
                local api = {}
                function api:Set(v) box.Text = tostring(v) end
                function api:Get() return box.Text end
                api.Export = function() return box.Text end
                api.Import = function(v) if type(v) == "string" then box.Text = v end end
                flag(t, api)
                return api
            end

            if o.Flag and not mod.Static then
                local api = {}
                api.Export = function() return { State = mod.State, Key = mod.Key and mod.Key.Name or nil } end
                api.Import = function(v)
                    if type(v) ~= "table" then return end
                    if v.Key then
                        local ok, kc = pcall(function() return Enum.KeyCode[v.Key] end)
                        mod.Key = ok and kc or nil
                    else mod.Key = nil end
                    mod:_paintKey()
                    mod:Set(v.State)
                    Win:RefreshHud()
                end
                api.Set = function(_, v) mod:Set(v) end
                api.Get = function() return mod.State end
                Lib.Flags[o.Flag] = api
            end

            table.insert(cat.Modules, mod)
            table.insert(Win.Modules, mod)
            Win:RefreshHud()
            if Win.Current then layout() end
            return mod
        end

        cat.Modules = {}
        table.insert(Win.Categories, cat)
        return cat
    end

    ------------------------------------------------------------------
    --  WINDOW API
    ------------------------------------------------------------------
    function Win:SetGlass(on)
        Win.Glass = on and true or false
        for _, g in ipairs(glassObjs) do
            if g[1].Parent or true then tw(g[1], 0.4, { BackgroundTransparency = Win.Glass and g[2] or 0 }, SINE) end
        end
        paintMat()
    end
    function Win:SetTheme(def)
        Win.ThemeDef = def
        applyTheme(def)
        waves()
    end
    function Win:SetScale(v)
        Win.userScale = v
        tw(scale, 0.35, { Scale = fit() }, QUINT)
    end
    function Win:SetGlow(g)
        Win._glowBase = 0.95 - 0.5 * g
        tw(mainStroke, 0.3, { Thickness = 1 + g }, SINE)
    end
    function Win:SetBindsHud(on) Win.HudOn = on and true or false Win:RefreshHud() end
    function Win:Toggle()
        Win.Open = not Win.Open
        if Win.Open then
            root.Visible = true
            scale.Scale = fit() * 0.85
            tw(scale, 0.55, { Scale = fit() }, BACK)
            waves()
        else
            tw(scale, 0.3, { Scale = fit() * 0.85 }, QUINT, IN)
            task.delay(0.3, function() if not Win.Open then root.Visible = false end end)
        end
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
    function Win:ImportString(s)
        local ok, data = pcall(function() return HttpService:JSONDecode(s) end)
        if not ok or type(data) ~= "table" then return false end
        for f, v in pairs(data) do
            local a = Lib.Flags[f]
            if a and a.Import then pcall(a.Import, v) end
        end
        return true
    end
    local FOLDER = cfg.Folder or "FemboysenseHub"
    function Win:SaveConfig(name)
        if not writefile then return false end
        pcall(function() if makefolder and isfolder and not isfolder(FOLDER) then makefolder(FOLDER) end end)
        name = tostring(name):gsub("[^%w_%- ]", "")
        return (pcall(writefile, FOLDER .. "/" .. name .. ".json", Win:ExportString()))
    end
    function Win:LoadConfig(name)
        if not (readfile and isfile) then return false end
        name = tostring(name):gsub("[^%w_%- ]", "")
        local path = FOLDER .. "/" .. name .. ".json"
        if not isfile(path) then return false end
        local ok, s = pcall(readfile, path)
        return ok and Win:ImportString(s)
    end

    ------------------------------------------------------------------
    --  APPEARANCE
    ------------------------------------------------------------------
    function Win:Finish()
        if Win._finished then return end
        Win._finished = true

        local ap = Win:AddCategory("Appearance", cfg.AppearanceIcon, "Theme, material and the feel of the menus.")

        local grid = new("Frame", { Size = UDim2.new(1, 0, 0, 180), BackgroundTransparency = 1 }, {
            new("UIGridLayout", {
                CellSize = UDim2.new(0.25, -9, 0, 84), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        local themeScales = {}
        for i, def in ipairs(THEMES) do
            local base = def.Mode == "Light" and LIGHT or DARK
            local b = new("TextButton", { Parent = grid, LayoutOrder = i, BackgroundColor3 = B"Panel" }, { corner(14) })
            local sc = new("UIScale", { Parent = b })
            themeScales[i] = sc
            local s = new("UIStroke", { Thickness = 1, Parent = b })
            local mini = new("Frame", { Parent = b, Position = UDim2.fromOffset(9, 9), Size = UDim2.new(1, -18, 0, 36), BackgroundColor3 = base.Bg }, { corner(7) })
            new("Frame", { Parent = mini, Position = UDim2.fromOffset(5, 5), Size = UDim2.fromOffset(13, 26), BackgroundColor3 = base.Panel2 }, { corner(4) })
            new("Frame", { Parent = mini, Position = UDim2.fromOffset(23, 5), Size = UDim2.new(1, -30, 0, 10), BackgroundColor3 = def.Accent }, { corner(4) })
            new("Frame", { Parent = mini, Position = UDim2.fromOffset(23, 20), Size = UDim2.new(0.55, 0, 0, 8), BackgroundColor3 = base.Panel2 }, { corner(4) })
            label(b, def.Name, UDim2.fromOffset(10, 50), UDim2.new(1, -20, 0, 16), Enum.Font.GothamBold, 12, B"Text")
            label(b, def.Mode, UDim2.fromOffset(10, 65), UDim2.new(1, -20, 0, 12), Enum.Font.Gotham, 9, B"Sub")
            local function paint()
                local on = Win.ThemeDef == def
                tw(s, 0.3, { Color = on and Theme.Accent or Theme.Stroke, Transparency = on and 0.05 or Theme.StrokeT, Thickness = on and 1.8 or 1 }, SINE)
            end
            onTheme(paint)
            b.MouseEnter:Connect(function() tw(sc, 0.25, { Scale = 1.04 }, BACK) end)
            b.MouseLeave:Connect(function() tw(sc, 0.3, { Scale = 1 }, SINE) end)
            b.MouseButton1Click:Connect(function() Win:SetTheme(def) end)
        end
        ap:AddTop(grid)
        ap.OnShow = function()      -- каскад карточек тем (--egui-order на сайте)
            for i, sc in ipairs(themeScales) do
                sc.Scale = 0.8
                task.delay((i - 1) * 0.05, function() tw(sc, 0.55, { Scale = 1 }, BACK) end)
            end
        end

        local ui = ap:AddModule({ Name = "Interface", Icon = "monitor", Info = "Window look and feel", Static = true })
        ui:AddSlider({ Name = "Interface glow", Min = 0, Max = 100, Default = 55, Suffix = "%", Flag = "UIGlow",
            Callback = function(v) Win:SetGlow(v / 100) end })
        ui:AddSlider({ Name = "Menu size", Min = 60, Max = 130, Default = 100, Suffix = "%", Flag = "UIScale",
            Callback = function(v) Win:SetScale(v / 100) end })
        ui:AddToggle({ Name = "Active binds HUD", Default = Win.HudOn, Flag = "UIBindsHud",
            Callback = function(v) Win:SetBindsHud(v) end })

        local cf = ap:AddModule({ Name = "Configs", Icon = "layers", Info = "Save and load your setups", Static = true })
        local cfgName = "default"
        cf:AddTextbox({ Name = "Config name", Placeholder = "default", Default = "default", Callback = function(t) if t ~= "" then cfgName = t end end })
        cf:AddButton({ Name = "Save config", ButtonText = "SAVE", Callback = function()
            Win:Notify("Config", Win:SaveConfig(cfgName) and ("Saved: " .. cfgName) or "writefile is not supported")
        end })
        cf:AddButton({ Name = "Load config", ButtonText = "LOAD", Callback = function()
            Win:Notify("Config", Win:LoadConfig(cfgName) and ("Loaded: " .. cfgName) or "Config not found")
        end })
        cf:AddButton({ Name = "Copy to clipboard", ButtonText = "COPY", Callback = function()
            local fn = setclipboard or toclipboard
            if fn then pcall(fn, Win:ExportString()) Win:Notify("Config", "Copied to clipboard") end
        end })

        account.MouseButton1Click:Connect(function() searchBox.Text = "" Win.Query = "" Win:Select(ap) end)
        Win:Select(Win.Categories[1])
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Win.Query = searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
        if Win.Current then layout() end
    end)

    -- popover настроек
    local settingsPop = new("CanvasGroup", {
        Parent = main, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 70), Size = UDim2.fromOffset(250, 150),
        BackgroundColor3 = B"Panel", Visible = false, ZIndex = 50, GroupTransparency = 1,
    }, { corner(14), stk(), pad(14, 14, 16, 16), new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
    label(settingsPop, "Interface", nil, UDim2.new(1, 0, 0, 18), Enum.Font.GothamBold, 14, B"Text", nil, { LayoutOrder = 1 })
    do
        makeSlider(settingsPop, { Name = "Menu size", Min = 60, Max = 130, Default = 100, Suffix = "%", Order = 2,
            Callback = function(v) Win:SetScale(v / 100) end })
        local colors = new("Frame", { Parent = settingsPop, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 },
            { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10) }) })
        for _, i in ipairs({ 2, 3, 4 }) do
            local d = THEMES[i]
            local c = new("TextButton", { Parent = colors, Size = UDim2.fromOffset(24, 24), BackgroundColor3 = d.Accent }, { corner(12) })
            local sc = new("UIScale", { Parent = c })
            c.MouseEnter:Connect(function() tw(sc, 0.25, { Scale = 1.2 }, BACK) end)
            c.MouseLeave:Connect(function() tw(sc, 0.25, { Scale = 1 }, SINE) end)
            c.MouseButton1Click:Connect(function() Win:SetTheme(d) end)
        end
    end
    local popOpen = false
    settingsBtn.MouseButton1Click:Connect(function()
        popOpen = not popOpen
        if popOpen then
            settingsPop.Visible = true
            settingsPop.Position = UDim2.new(1, -24, 0, 58)
            tw(settingsPop, 0.4, { GroupTransparency = 0, Position = UDim2.new(1, -24, 0, 70) }, QUINT)
        else
            tw(settingsPop, 0.25, { GroupTransparency = 1 }, SINE)
            task.delay(0.26, function() if not popOpen then settingsPop.Visible = false end end)
        end
    end)
    chatBtn.MouseButton1Click:Connect(function() Win:Notify("Chat", "Chat is not connected yet") end)

    keep(UserInputService.InputBegan:Connect(function(input, gp)
        if Lib._listen and input.UserInputType == Enum.UserInputType.Keyboard then
            local f = Lib._listen
            Lib._listen = nil
            f(input.KeyCode)
            return
        end
        if gp then return end
        if input.KeyCode == Win.ToggleKey then Win:Toggle() return end
        for _, m in ipairs(Win.Modules) do
            if m.Key and not m.Static and input.KeyCode == m.Key then m:Set(not m.State) end
        end
    end))

    function Win:Destroy()
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        conns, reg, hooks = {}, {}, {}
        gui:Destroy()
        genv.FemboysenseUnload = nil
    end
    genv.FemboysenseUnload = function() Win:Destroy() end

    task.defer(function() if not Win._finished then Win:Finish() end end)

    Win.AllCat = Win:AddCategory("All modules", "grid", "Every module in one place.", true)
    Win.Current = nil
    Win:Select(Win.AllCat)

    return Win
end

return Lib