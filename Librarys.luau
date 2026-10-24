--[[
    FEMBOYSENSE HUB — UI Library
    Стиль: Eclipse client (сайдбар, тулбар с поиском, карточки-модули с Enabled-переключателем,
    темы Mono / Lavender / Midnight / Rose (Dark + Light), Solid / Glass, Active binds HUD).

    Управление (как на сайте):
      RightShift      — скрыть / показать меню
      ПКМ по модулю   — открыть настройки модуля
      СКМ по модулю   — назначить клавишу (Esc / Backspace — убрать)
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local Debris           = game:GetService("Debris")
local LocalPlayer      = Players.LocalPlayer

local genv = (getgenv and getgenv()) or _G
if genv.FemboysenseUnload then pcall(genv.FemboysenseUnload) end

local rgb, WHITE = Color3.fromRGB, Color3.new(1, 1, 1)
local SINE, QUINT = Enum.EasingStyle.Sine, Enum.EasingStyle.Quint
local OUT, IN = Enum.EasingDirection.Out, Enum.EasingDirection.In

local Lib = { Flags = {}, Version = "v1.0" }

--=====================================================================
--  THEMES
--=====================================================================
local DARK = {
    Bg = rgb(8, 8, 10), Side = rgb(17, 17, 20), Panel = rgb(26, 26, 30), Panel2 = rgb(38, 38, 43),
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

local function applyTheme(def, instant)
    loadTheme(def)
    for _, e in ipairs(reg) do
        if instant then
            pcall(function() e[1][e[2]] = Theme[e[3]] end)
        else
            pcall(function() tw(e[1], 0.35, { [e[2]] = Theme[e[3]] }, SINE) end)
        end
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
    local knob = new("Frame", {
        Parent = track, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), BackgroundColor3 = WHITE,
    }, { corner(8) })
    local sw = {}
    local function paint(instant)
        local col = state and Theme.Accent:Lerp(Theme.Panel2, 0.38) or Theme.Bg
        local p = state and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        if instant then track.BackgroundColor3, knob.Position = col, p
        else tw(track, 0.25, { BackgroundColor3 = col }, SINE) tw(knob, 0.3, { Position = p }, QUINT) end
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
        tw(fill, fast and 0.06 or 0.25, { Size = UDim2.fromScale(r, 1) }, SINE)
        tw(knob, fast and 0.06 or 0.25, { Position = UDim2.fromScale(r, 0.5) }, SINE)
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
        if isPress(i) then dragging = true fromX(i.Position.X) end
    end)
    keep(UserInputService.InputChanged:Connect(function(i)
        if dragging and isMove(i) then fromX(i.Position.X) end
    end))
    keep(UserInputService.InputEnded:Connect(function(i)
        if dragging and isPress(i) then dragging = false end
    end))
    function api:Set(v, silent) setv(v, silent, false) end
    function api:Get() return value end
    api.Frame = f
    return api
end

local function flag(o, api)
    if not o.Flag then return end
    Lib.Flags[o.Flag] = api
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
        Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1,
    })
    local scale = new("UIScale", { Parent = root })
    local function fit()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        return math.clamp(math.min(vp.X / (W + 40), vp.Y / (H + 40)), 0.4, 1.3) * Win.userScale
    end
    scale.Scale = fit() * 0.9
    tw(scale, 0.6, { Scale = fit() }, QUINT)
    do
        local cam = workspace.CurrentCamera
        if cam then keep(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function() scale.Scale = fit() end)) end
    end

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
        new("Frame", { Parent = logo, Position = UDim2.fromOffset(0, 14), Size = UDim2.fromOffset(7, 20), BackgroundColor3 = B"Text" }, { corner(2) })
        new("Frame", { Parent = logo, Position = UDim2.fromOffset(13, 0), Size = UDim2.fromOffset(7, 34), BackgroundColor3 = B"Text" }, { corner(2) })
        new("Frame", { Parent = logo, Position = UDim2.fromOffset(26, 8), Size = UDim2.fromOffset(7, 26), BackgroundColor3 = B"Text" }, { corner(2) })
        label(brand, cfg.Title or "FEMBOYSENSE", UDim2.fromOffset(62, 20), UDim2.new(1, -68, 0, 20), Enum.Font.GothamBlack, 15, B"Text")
        label(brand, cfg.Sub or "HUB", UDim2.fromOffset(62, 40), UDim2.new(1, -68, 0, 12), Enum.Font.GothamMedium, 9, B"Sub")
    end

    local nav = new("ScrollingFrame", {
        Parent = side, Position = UDim2.fromOffset(10, 80), Size = UDim2.new(1, -20, 1, -80 - 112),
        BackgroundTransparency = 1, ScrollBarThickness = 0, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, { new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })

    label(side, cfg.Platform and (cfg.Version or "1.0") .. " / " .. cfg.Platform or "1.0 / LUAU",
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
    label(account, ">", UDim2.new(1, -24, 0, 0), UDim2.fromOffset(14, 58), Enum.Font.GothamBold, 13, B"Sub", Enum.TextXAlignment.Center)

    ------------------------------------------------------------------
    --  TOOLBAR
    ------------------------------------------------------------------
    local TBW = W - 238
    local toolbar = new("Frame", {
        Parent = main, Position = UDim2.fromOffset(224, 14), Size = UDim2.fromOffset(TBW, 52), BackgroundColor3 = B"Panel",
    }, { corner(16), stk() })
    glassT(toolbar, 0.1)

    local chip = new("Frame", { Parent = toolbar, Position = UDim2.fromOffset(9, 9), Size = UDim2.fromOffset(150, 34), BackgroundColor3 = B"Bg" }, { corner(11) })
    new("Frame", {
        Parent = chip, Position = UDim2.fromOffset(12, 9), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1,
    }, { corner(8), new("UIStroke", { Color = B"Text", Thickness = 1.6 }) })
    label(chip, cfg.Version or "1.0", UDim2.fromOffset(38, 0), UDim2.fromOffset(60, 34), Enum.Font.GothamBold, 14, B"Text")
    label(chip, cfg.Platform or "LUAU", UDim2.new(1, -60, 0, 0), UDim2.fromOffset(50, 34), Enum.Font.GothamMedium, 9, B"Sub", Enum.TextXAlignment.Right)

    local function tbBtn(rightOff, text)
        return new("TextButton", {
            Parent = toolbar, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -rightOff, 0.5, 0),
            Size = UDim2.fromOffset(36, 36), BackgroundColor3 = B"Bg", Text = text or "",
            TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 12,
        }, { corner(11) })
    end
    local settingsBtn = tbBtn(9, "")
    new("Frame", { Parent = settingsBtn, Position = UDim2.fromOffset(10, 11), Size = UDim2.fromOffset(16, 2), BackgroundColor3 = B"Text" })
    new("Frame", { Parent = settingsBtn, Position = UDim2.fromOffset(10, 17), Size = UDim2.fromOffset(16, 2), BackgroundColor3 = B"Text" })
    new("Frame", { Parent = settingsBtn, Position = UDim2.fromOffset(10, 23), Size = UDim2.fromOffset(16, 2), BackgroundColor3 = B"Text" })
    local langChip = tbBtn(53, "EN")
    local chatBtn = tbBtn(97, "")
    new("Frame", { Parent = chatBtn, Position = UDim2.fromOffset(9, 9), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1 },
        { corner(9), new("UIStroke", { Color = B"Text", Thickness = 1.6 }) })

    local searchBack = new("Frame", {
        Parent = toolbar, Position = UDim2.fromOffset(168, 7), Size = UDim2.new(1, -168 - 150, 0, 38), BackgroundColor3 = B"Bg",
    }, { corner(12) })
    local searchStroke = new("UIStroke", { Color = B"Accent", Transparency = 1, Thickness = 1.2, Parent = searchBack })
    new("Frame", { Parent = searchBack, Position = UDim2.fromOffset(14, 11), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1 },
        { corner(7), new("UIStroke", { Color = B"Sub", Thickness = 1.6 }) })
    local searchBox = new("TextBox", {
        Parent = searchBack, Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1,
        PlaceholderText = "Search modules…", PlaceholderColor3 = B"Sub", Text = "", TextColor3 = B"Text",
        TextSize = 13, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
    })
    searchBox.Focused:Connect(function() tw(searchStroke, 0.25, { Transparency = 0.5 }, SINE) end)
    searchBox.FocusLost:Connect(function() tw(searchStroke, 0.3, { Transparency = 1 }, SINE) end)

    drag(toolbar, root)
    drag(brand, root)

    ------------------------------------------------------------------
    --  CONTENT
    ------------------------------------------------------------------
    local content = new("Frame", {
        Parent = main, Position = UDim2.fromOffset(224, 80), Size = UDim2.fromOffset(TBW, H - 80 - 38), BackgroundColor3 = B"Bg",
    }, { corner(18) })
    do
        local c = new("UIStroke", { Color = B"Stroke", Transparency = B"StrokeT", Thickness = 1, Parent = content })
    end

    local titleL = label(content, "", UDim2.fromOffset(22, 14), UDim2.new(1, -220, 0, 32), Enum.Font.GothamBold, 26, B"Text")
    local subL = label(content, "", UDim2.fromOffset(22, 48), UDim2.new(1, -220, 0, 16), Enum.Font.Gotham, 12, B"Sub")
    drag(content, root)

    -- Solid / Glass (только в Appearance)
    local matBox = new("Frame", {
        Parent = content, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 18),
        Size = UDim2.fromOffset(150, 32), BackgroundColor3 = B"Panel", Visible = false,
    }, { corner(10), stk() })
    local matBtns = {}
    for i, name in ipairs({ "Solid", "Glass" }) do
        local b = new("TextButton", {
            Parent = matBox, Position = UDim2.new((i - 1) / 2, 3, 0, 3), Size = UDim2.new(0.5, -6, 1, -6),
            BackgroundColor3 = B"Panel2", Text = name, TextSize = 12, TextColor3 = B"Sub", Font = Enum.Font.GothamBold,
        }, { corner(8) })
        matBtns[name] = b
        b.MouseButton1Click:Connect(function() Win:SetGlass(name == "Glass") end)
    end
    local function paintMat()
        for name, b in pairs(matBtns) do
            local on = (name == "Glass") == Win.Glass
            tw(b, 0.25, { BackgroundTransparency = on and 0 or 1, TextColor3 = on and Theme.Text or Theme.Sub }, SINE)
        end
    end
    onTheme(paintMat)

    local scroll = new("ScrollingFrame", {
        Parent = content, Position = UDim2.fromOffset(14, 80), Size = UDim2.new(1, -28, 1, -92), BackgroundTransparency = 1,
        ScrollBarThickness = 3, ScrollBarImageColor3 = B"Accent", CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
    }, { new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }), pad(0, 10, 0, 8) })

    local topHolder = new("Frame", {
        Parent = scroll, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
    }, { new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }) })
    local colsHolder = new("Frame", {
        Parent = scroll, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
    }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }) })
    local function mkCol(order)
        return new("Frame", {
            Parent = colsHolder, LayoutOrder = order, Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
        }, { new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }) })
    end
    local colL, colR = mkCol(1), mkCol(2)
    local emptyL = label(content, "Nothing found.", UDim2.fromOffset(0, 200), UDim2.new(1, 0, 0, 20), Enum.Font.GothamMedium, 13, B"Sub",
        Enum.TextXAlignment.Center)
    emptyL.Visible = false

    label(main, "RSHIFT · CLOSE / RIGHT CLICK · SETTINGS", UDim2.fromOffset(238, H - 30), UDim2.fromOffset(340, 14),
        Enum.Font.GothamMedium, 10, B"Sub")
    label(main, (cfg.Title or "FEMBOYSENSE") .. " " .. (cfg.Sub or "HUB"), UDim2.new(1, -250, 1, -30), UDim2.fromOffset(236, 14),
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
        tip.Position = UDim2.fromOffset(obj.AbsolutePosition.X, obj.AbsolutePosition.Y - 30)
        tip.Visible = true
    end
    Lib._hideTip = function() tip.Visible = false end

    local nholder = new("Frame", {
        Parent = gui, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.fromOffset(290, 400), BackgroundTransparency = 1,
    }, { new("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right }) })

    function Win:Notify(title, text, dur)
        dur = dur or 3
        text = tostring(text or "")
        local wrap = new("Frame", { Parent = nholder, Size = UDim2.fromOffset(280, 64), BackgroundTransparency = 1 })
        local c = new("Frame", {
            Parent = wrap, Position = UDim2.fromOffset(320, 0), Size = UDim2.fromScale(1, 1), BackgroundColor3 = B"Panel",
        }, { corner(14), stk() })
        new("Frame", { Parent = c, Position = UDim2.fromOffset(12, 14), Size = UDim2.fromOffset(3, 36), BackgroundColor3 = B"Accent" }, { corner(2) })
        label(c, tostring(title), UDim2.fromOffset(26, 10), UDim2.new(1, -36, 0, 18), Enum.Font.GothamBold, 13, B"Text")
        label(c, text, UDim2.fromOffset(26, 30), UDim2.new(1, -36, 0, 28), Enum.Font.Gotham, 11, B"Sub", nil,
            { TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None })
        tw(c, 0.5, { Position = UDim2.fromOffset(0, 0) }, QUINT)
        task.delay(dur, function()
            if not wrap.Parent then return end
            tw(c, 0.35, { Position = UDim2.fromOffset(320, 0) }, QUINT, IN)
            task.delay(0.4, function() wrap:Destroy() end)
        end)
    end

    local hud = new("Frame", {
        Parent = gui, Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(200, 0), AutomaticSize = Enum.AutomaticSize.Y,
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
                local k = label(row, keyName(m.Key), UDim2.new(1, 0, 0.5, 0), UDim2.fromOffset(0, 20), Enum.Font.GothamBold, 10, B"Text",
                    Enum.TextXAlignment.Center)
                k.AnchorPoint = Vector2.new(1, 0.5)
                k.AutomaticSize = Enum.AutomaticSize.X
                k.BackgroundTransparency = 0
                k.BackgroundColor3 = Theme.Panel2
                corner(6).Parent = k
                pad(0, 0, 8, 8).Parent = k
                table.insert(hudRows, row)
            end
        end
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
        for i, m in ipairs(list) do m.Card.Parent = (i % 2 == 1) and colL or colR end
        local tops = 0
        if q == "" then
            for _, t in ipairs(cat.Tops) do t.Parent = topHolder tops += 1 end
        end
        emptyL.Visible = (#list == 0 and tops == 0)
        if q ~= "" then
            titleL.Text, subL.Text = "Search", string.format('Results for "%s"', searchBox.Text)
        else
            titleL.Text, subL.Text = cat.Name, cat.Sub
        end
        matBox.Visible = (q == "" and cat.Name == "Appearance")
        scroll.CanvasPosition = Vector2.zero
    end

    local function paintNav()
        for _, c in ipairs(Win.Categories) do
            local on = (c == Win.Current)
            tw(c.Btn, 0.25, { BackgroundTransparency = on and 0 or 1 }, SINE)
            tw(c.Label, 0.25, { TextColor3 = on and Theme.Text or Theme.Sub }, SINE)
            for _, p in ipairs(c.IconParts) do
                pcall(function()
                    if p:IsA("ImageLabel") then tw(p, 0.25, { ImageColor3 = on and Theme.Text or Theme.Sub }, SINE)
                    else tw(p, 0.25, { Color = on and Theme.Text or Theme.Sub }, SINE) end
                end)
            end
        end
    end
    onTheme(paintNav)

    function Win:Select(cat)
        Win.Current = cat
        paintNav()
        layout()
    end

    function Win:AddCategory(name, icon, sub, isAll)
        local cat = { Name = name, Sub = sub or "", Tops = {}, IconParts = {}, All = isAll }
        local btn = new("TextButton", {
            Parent = nav, LayoutOrder = #Win.Categories + 1, Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = B"Panel2", BackgroundTransparency = 1,
        }, { corner(12) })
        local ic = tonumber(icon) and ("rbxassetid://" .. icon) or (type(icon) == "string" and icon:find("rbx") and icon or nil)
        if ic then
            local im = new("ImageLabel", {
                Parent = btn, Position = UDim2.fromOffset(14, 11), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1,
                Image = ic, ImageColor3 = Theme.Sub,
            })
            table.insert(cat.IconParts, im)
        else
            local box = new("Frame", {
                Parent = btn, Position = UDim2.fromOffset(15, 12), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1,
            }, { corner(isAll and 3 or 8) })
            local s = new("UIStroke", { Color = Theme.Sub, Thickness = 1.6, Parent = box })
            table.insert(cat.IconParts, s)
        end
        cat.Btn = btn
        cat.Label = label(btn, name, UDim2.fromOffset(44, 0), UDim2.new(1, -52, 1, 0), Enum.Font.GothamMedium, 14, B"Sub")
        btn.MouseEnter:Connect(function()
            if Win.Current ~= cat then tw(cat.Label, 0.2, { TextColor3 = Theme.Text }, SINE) end
        end)
        btn.MouseLeave:Connect(function()
            if Win.Current ~= cat then tw(cat.Label, 0.25, { TextColor3 = Theme.Sub }, SINE) end
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
            local card = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = B"Panel",
            }, { corner(14), stk(), pad(14, 14, 16, 16), new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
            mod.Card = card

            -- header
            local head = new("Frame", { Parent = card, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 })
            local left = new("Frame", { Parent = head, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1 },
                { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 9), VerticalAlignment = Enum.VerticalAlignment.Center }) })
            new("Frame", { Parent = left, LayoutOrder = 1, Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1 },
                { corner(9), new("UIStroke", { Color = B"Text", Thickness = 1.5 }) })
            local nameL = new("TextLabel", {
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
                Parent = card, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1, Visible = false,
            }, { new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
            mod.Settings = sf

            local expand
            local open = false
            local function setOpen(v)
                open = v
                sf.Visible = v
                if expand then expand.Text = v and "−" or "+" end
            end
            if mod.Static then
                setOpen(true)
            else
                expand = new("TextButton", {
                    Parent = head, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(22, 22),
                    BackgroundTransparency = 1, Text = "+", TextColor3 = B"Sub", Font = Enum.Font.GothamMedium, TextSize = 18,
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
                if mod.State then task.defer(fire, o.Callback, true) end

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
                    Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                }, { new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
                label(row, t.Name or "Options", nil, UDim2.new(1, 0, 0, 16), Enum.Font.GothamMedium, 12, B"Sub", nil, { LayoutOrder = 1 })
                local wrapF = new("Frame", {
                    Parent = row, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
                }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
                local btns = {}
                local function paint()
                    for name, b in pairs(btns) do
                        local on = name == sel
                        tw(b, 0.25, {
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
                b.MouseEnter:Connect(function() tw(b, 0.2, { BackgroundColor3 = Theme.Accent, TextColor3 = Theme.OnAccent }, SINE) end)
                b.MouseLeave:Connect(function() tw(b, 0.25, { BackgroundColor3 = Theme.Panel2, TextColor3 = Theme.Text }, SINE) end)
                b.MouseButton1Click:Connect(function() fire(t.Callback) end)
            end

            function mod:AddTextbox(t)
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 })
                label(row, t.Name or "Textbox", nil, UDim2.new(1, -150, 1, 0), Enum.Font.GothamMedium, 13, B"Text")
                local back = new("Frame", {
                    Parent = row, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(140, 28),
                    BackgroundColor3 = B"Bg",
                }, { corner(9) })
                local box = new("TextBox", {
                    Parent = back, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1,
                    PlaceholderText = t.Placeholder or "", PlaceholderColor3 = B"Sub", Text = t.Default or "", TextColor3 = B"Text",
                    TextSize = 12, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
                })
                box.FocusLost:Connect(function(enter) fire(t.Callback, box.Text, enter) end)
                local api = {}
                function api:Set(v) box.Text = tostring(v) end
                function api:Get() return box.Text end
                api.Export = function() return box.Text end
                api.Import = function(v) if type(v) == "string" then box.Text = v end end
                flag(t, api)
                return api
            end

            -- flag модуля (Enabled + клавиша)
            if o.Flag and not mod.Static then
                local api = {}
                api.Export = function()
                    return { State = mod.State, Key = mod.Key and mod.Key.Name or nil }
                end
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

            table.insert(cat.Modules or {}, mod)
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
        for _, g in ipairs(glassObjs) do tw(g[1], 0.35, { BackgroundTransparency = Win.Glass and g[2] or 0 }, SINE) end
        paintMat()
    end
    function Win:SetTheme(def)
        Win.ThemeDef = def
        applyTheme(def)
    end
    function Win:SetScale(v)
        Win.userScale = v
        tw(scale, 0.3, { Scale = fit() }, QUINT)
    end
    function Win:SetGlow(g)
        tw(mainStroke, 0.3, { Transparency = 0.95 - 0.5 * g, Thickness = 1 + g }, SINE)
    end
    function Win:SetBindsHud(on) Win.HudOn = on and true or false Win:RefreshHud() end
    function Win:Toggle()
        Win.Open = not Win.Open
        if Win.Open then
            root.Visible = true
            scale.Scale = fit() * 0.9
            tw(scale, 0.4, { Scale = fit() }, QUINT)
        else
            tw(scale, 0.25, { Scale = fit() * 0.9 }, QUINT, IN)
            task.delay(0.26, function() if not Win.Open then root.Visible = false end end)
        end
    end

    -- Конфиги
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
    --  APPEARANCE (встроенная страница, как на сайте)
    ------------------------------------------------------------------
    local settingsPop
    function Win:Finish()
        if Win._finished then return end
        Win._finished = true

        local ap = Win:AddCategory("Appearance", cfg.AppearanceIcon, "Theme, material and the feel of the menus.")

        local grid = new("Frame", { Size = UDim2.new(1, 0, 0, 180), BackgroundTransparency = 1 }, {
            new("UIGridLayout", {
                CellSize = UDim2.new(0.25, -9, 0, 84), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        for i, def in ipairs(THEMES) do
            local base = def.Mode == "Light" and LIGHT or DARK
            local b = new("TextButton", { Parent = grid, LayoutOrder = i, BackgroundColor3 = B"Panel" }, { corner(12) })
            local s = new("UIStroke", { Thickness = 1, Parent = b })
            local mini = new("Frame", { Parent = b, Position = UDim2.fromOffset(9, 9), Size = UDim2.new(1, -18, 0, 36), BackgroundColor3 = base.Bg }, { corner(7) })
            new("Frame", { Parent = mini, Position = UDim2.fromOffset(5, 5), Size = UDim2.fromOffset(13, 26), BackgroundColor3 = base.Panel2 }, { corner(4) })
            new("Frame", { Parent = mini, Position = UDim2.fromOffset(23, 5), Size = UDim2.new(1, -30, 0, 10), BackgroundColor3 = def.Accent }, { corner(4) })
            new("Frame", { Parent = mini, Position = UDim2.fromOffset(23, 20), Size = UDim2.new(0.55, 0, 0, 8), BackgroundColor3 = base.Panel2 }, { corner(4) })
            label(b, def.Name, UDim2.fromOffset(10, 50), UDim2.new(1, -20, 0, 16), Enum.Font.GothamBold, 12, B"Text")
            label(b, def.Mode, UDim2.fromOffset(10, 65), UDim2.new(1, -20, 0, 12), Enum.Font.Gotham, 9, B"Sub")
            local function paint()
                local on = Win.ThemeDef == def
                s.Color = on and Theme.Accent or Theme.Stroke
                s.Transparency = on and 0.1 or Theme.StrokeT
                s.Thickness = on and 1.6 or 1
            end
            onTheme(paint)
            b.MouseButton1Click:Connect(function() Win:SetTheme(def) end)
        end
        ap:AddTop(grid)

        local ui = ap:AddModule({ Name = "Interface", Info = "Window look and feel", Static = true })
        ui:AddSlider({ Name = "Interface glow", Min = 0, Max = 100, Default = 55, Suffix = "%", Flag = "UIGlow",
            Callback = function(v) Win:SetGlow(v / 100) end })
        ui:AddSlider({ Name = "Menu size", Min = 60, Max = 130, Default = 100, Suffix = "%", Flag = "UIScale",
            Callback = function(v) Win:SetScale(v / 100) end })
        ui:AddToggle({ Name = "Active binds HUD", Default = Win.HudOn, Flag = "UIBindsHud",
            Callback = function(v) Win:SetBindsHud(v) end })

        local cf = ap:AddModule({ Name = "Configs", Info = "Save and load your setups", Static = true })
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

    -- поиск
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Win.Query = searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
        if Win.Current then layout() end
    end)

    -- popover настроек (кнопка справа в тулбаре)
    settingsPop = new("Frame", {
        Parent = main, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 74), Size = UDim2.fromOffset(250, 150),
        BackgroundColor3 = B"Panel", Visible = false, ZIndex = 50,
    }, { corner(14), stk(), pad(14, 14, 16, 16), new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
    label(settingsPop, "Interface", nil, UDim2.new(1, 0, 0, 18), Enum.Font.GothamBold, 14, B"Text", nil, { LayoutOrder = 1 })
    do
        local s = makeSlider(settingsPop, { Name = "Menu size", Min = 60, Max = 130, Default = 100, Suffix = "%", Order = 2,
            Callback = function(v) Win:SetScale(v / 100) end })
        local colors = new("Frame", { Parent = settingsPop, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 },
            { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10) }) })
        for _, i in ipairs({ 2, 3, 4 }) do
            local d = THEMES[i]
            local c = new("TextButton", { Parent = colors, Size = UDim2.fromOffset(24, 24), BackgroundColor3 = d.Accent }, { corner(12) })
            c.MouseButton1Click:Connect(function() Win:SetTheme(d) end)
        end
    end
    settingsBtn.MouseButton1Click:Connect(function() settingsPop.Visible = not settingsPop.Visible end)
    chatBtn.MouseButton1Click:Connect(function() Win:Notify("Chat", "Chat is not connected yet") end)

    -- ввод
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

    -- Appearance добавляется после всех категорий пользователя
    task.defer(function() if not Win._finished then Win:Finish() end end)

    -- "All modules" всегда первая вкладка
    Win.AllCat = Win:AddCategory("All modules", nil, "Every module in one place.", true)
    Win.Current = Win.AllCat

    return Win
end

return Lib