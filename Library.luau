local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TextService = game:GetService("TextService")
local Stats = game:GetService("Stats")
local LP = Players.LocalPlayer

local SINE, QUINT, BACK, EXPO, LINEAR = Enum.EasingStyle.Sine, Enum.EasingStyle.Quint, Enum.EasingStyle.Back, Enum.EasingStyle.Exponential, Enum.EasingStyle.Linear
local OUT, IN = Enum.EasingDirection.Out, Enum.EasingDirection.In
local LEFT, CENTER, RIGHT = Enum.TextXAlignment.Left, Enum.TextXAlignment.Center, Enum.TextXAlignment.Right

local Lib = { Flags = {}, ThemeName = "Lavender Dark", Windows = {}, Icons = {} }
local Window, Tab, Module = {}, {}, {}
Window.__index, Tab.__index, Module.__index = Window, Tab, Module

Lib.IconNames = {
    -- вкладки (имя вкладки в нижнем регистре, пробелы -> _ , подхватывается само)
    "all_modules", "combat", "visuals", "world", "interface", "utility", "cosmetics", "appearance", "settings", "configs",
    -- верхняя панель
    "search", "chat", "sliders", "logo",
    -- карточки / элементы
    "target", "info", "keyboard", "check", "close", "copy", "lock", "user", "palette", "bell",
    -- уведомления
    "success", "error", "warn",
    -- ватермарк
    "fps", "ping", "clock",
    -- конфиги
    "save", "folder", "trash", "refresh", "download", "upload",
}
function Lib:SetIcons(map)
    for k, v in pairs(map) do Lib.Icons[k] = v end
end
local function resolveIcon(v)
    if v == nil or v == "" then return nil end
    if type(v) == "number" then return "rbxassetid://" .. v end
    if type(v) == "string" then
        if v:find("rbxasset") or v:find("http") then return v end
        local id = Lib.Icons[v]
        if type(id) == "number" then return "rbxassetid://" .. id end
        if type(id) == "string" and id ~= "" then
            if id:find("rbx") or id:find("http") then return id end
            return "rbxassetid://" .. id
        end
    end
    return nil
end

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local function palette(accent, dark)
    if dark then
        return { Dark = true, Accent = accent, Outer = rgb(15, 15, 17), Panel = rgb(25, 25, 28), Content = rgb(9, 9, 11),
            Card = rgb(28, 28, 31), Card2 = rgb(44, 44, 49), Text = rgb(244, 244, 247), Sub = rgb(142, 142, 152),
            Line = rgb(52, 52, 58), Off = rgb(12, 12, 14), Knob = rgb(255, 255, 255) }
    end
    return { Dark = false, Accent = accent, Outer = rgb(214, 214, 222), Panel = rgb(238, 238, 244), Content = rgb(247, 247, 250),
        Card = rgb(255, 255, 255), Card2 = rgb(230, 230, 238), Text = rgb(24, 24, 30), Sub = rgb(110, 110, 124),
        Line = rgb(208, 208, 220), Off = rgb(196, 196, 208), Knob = rgb(255, 255, 255) }
end

local FAMILIES = {
    { "Lavender", rgb(178, 152, 255) }, { "Midnight", rgb(124, 164, 255) }, { "Rose", rgb(246, 142, 192) },
    { "Crimson", rgb(255, 64, 88) }, { "Emerald", rgb(52, 211, 153) }, { "Sunset", rgb(251, 146, 60) },
}
local Themes, ThemeList = {}, {}
for _, mode in ipairs({ "Dark", "Light" }) do
    for _, f in ipairs(FAMILIES) do
        local key = f[1] .. " " .. mode
        Themes[key] = palette(f[2], mode == "Dark")
        table.insert(ThemeList, key)
    end
end
Lib.Themes, Lib.ThemeList = Themes, ThemeList
local Theme = {}
for k, v in pairs(Themes[Lib.ThemeName]) do Theme[k] = v end
Lib.Theme = Theme

local themed, hooks = {}, {}
local function tween(o, t, p, style, dir)
    local tw = TweenService:Create(o, TweenInfo.new(math.max(t, 0.01), style or QUINT, dir or OUT), p)
    tw:Play()
    return tw
end
local function new(class, props, children)
    local o = Instance.new(class)
    if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then o.AutoLocalize = false end
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v
        elseif type(v) == "string" and v:sub(1, 1) == "@" and k:find("Color") then
            o[k] = Theme[v:sub(2)]
            table.insert(themed, { o, k, v:sub(2) })
        else o[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = o end
    if parent then o.Parent = parent end
    return o
end
local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function stroke(color, th, tr)
    return new("UIStroke", { Color = color, Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function label(parent, text, pos, size, font, ts, color, align, extra)
    local l = new("TextLabel", {
        Parent = parent, Text = text, Position = pos, Size = size, BackgroundTransparency = 1,
        Font = font or Enum.Font.Gotham, TextSize = ts or 12, TextColor3 = color or "@Text",
        TextXAlignment = align or LEFT, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    for k, v in pairs(extra or {}) do l[k] = v end
    return l
end
local function onTheme(fn) table.insert(hooks, fn) end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end
local function fire(cb, ...)
    if not cb then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(cb, table.unpack(args, 1, args.n))
        if not ok then warn("[FemboySense] " .. tostring(err)) end
    end)
end
local function hoverColor() return Theme.Card:Lerp(Theme.Card2, 0.5) end
local function c255(c) return math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) end
local function richColor(c) local r, g, b = c255(c) return string.format("rgb(%d,%d,%d)", r, g, b) end
local function textW(text, size, font)
    local ok, v = pcall(function() return TextService:GetTextSize(text, size, font, Vector2.new(1000, 100)).X end)
    return ok and v or (#text * size * 0.55)
end

local KEYSHORT = { LeftControl = "LCtrl", RightControl = "RCtrl", LeftShift = "LShift", RightShift = "RShift",
    LeftAlt = "LAlt", RightAlt = "RAlt", Return = "Enter", Backspace = "Bksp", Escape = "Esc", MouseButton1 = "LMB",
    MouseButton2 = "RMB", MouseButton3 = "MMB" }
local function keyName(k) if not k then return "NONE" end return (KEYSHORT[k.Name] or k.Name):upper() end
local function keyToTbl(k) return k and { K = k.Name, T = tostring(k.EnumType) == "Enum.UserInputType" and "U" or "K" } or nil end
local function tblToKey(t)
    if type(t) ~= "table" or not t.K then return nil end
    local ok, v = pcall(function() return (t.T == "U" and Enum.UserInputType or Enum.KeyCode)[t.K] end)
    return ok and v or nil
end
local function inputKey(i) if i.UserInputType == Enum.UserInputType.Keyboard then return i.KeyCode end return i.UserInputType end

local function icon(parent, ref, pos, size, color, z, fallback)
    local id = resolveIcon(ref)
    if id then
        local img = new("ImageLabel", { Parent = parent, Position = pos, Size = size, BackgroundTransparency = 1, Image = id,
            ImageColor3 = color or "@Text", ZIndex = z or 1 })
        return img, function(c) tween(img, 0.3, { ImageColor3 = c }, SINE) end, true
    end
    if fallback then
        local o, p = fallback()
        return o, p, false
    end
    local box = new("Frame", { Parent = parent, Position = pos, Size = size, BackgroundTransparency = 1, ZIndex = z or 1 },
        { corner(math.max(3, math.floor(size.X.Offset / 3))) })
    local s = stroke(color or "@Text", 1.5)
    s.Parent = box
    return box, function(c) tween(s, 0.3, { Color = c }, SINE) end, false
end

function Lib:SetTheme(name)
    local t = Themes[name]
    if not t then return end
    Lib.ThemeName = name
    for k, v in pairs(t) do Theme[k] = v end
    for i = #themed, 1, -1 do
        local e = themed[i]
        if e[1].Parent then tween(e[1], 0.45, { [e[2]] = Theme[e[3]] }, SINE) else table.remove(themed, i) end
    end
    for _, f in ipairs(hooks) do task.spawn(pcall, f) end
end
Lib.U = { new = new, corner = corner, stroke = stroke, label = label, tween = tween, onTheme = onTheme, fire = fire, icon = icon }

local function D(W, x) return W.Motion and x or 0.01 end

local function dragify(W, handle, target)
    local dragging, ds, sp
    handle.InputBegan:Connect(function(i)
        if isPress(i) then
            dragging, ds, sp = true, i.Position, target.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    W.keep(UIS.InputChanged:Connect(function(i)
        if dragging and isMove(i) then
            local d = i.Position - ds
            target.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end))
end

local function ripple(card, input, W)
    local sc = math.max(W.Scale.Scale, 0.05)
    local rel = (Vector2.new(input.Position.X, input.Position.Y) - card.AbsolutePosition) / sc
    local r = new("Frame", { Parent = card, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(rel.X, rel.Y),
        Size = UDim2.fromOffset(0, 0), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.78, BorderSizePixel = 0,
        ZIndex = 0 }, { corner(500) })
    tween(r, 0.7, { Size = UDim2.fromOffset(420, 420), BackgroundTransparency = 1 }, QUINT)
    task.delay(0.75, function() r:Destroy() end)
end

local KIND = { success = rgb(52, 211, 153), error = rgb(255, 84, 104), warn = rgb(251, 191, 36) }

function Lib:Notify(title, text, dur, kind)
    local h = Lib._notif
    if not (h and h.Parent) then return end
    dur = dur or 3.5
    local color, iname = Theme.Accent, "info"
    if typeof(kind) == "Color3" then color = kind
    elseif type(kind) == "string" and KIND[kind] then color, iname = KIND[kind], kind end

    local wrap = new("Frame", { Parent = h, Size = UDim2.fromOffset(300, 70), BackgroundTransparency = 1 })
    local card = new("TextButton", { Parent = wrap, Position = UDim2.fromOffset(350, 0), Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = "@Panel", BorderSizePixel = 0, Text = "", AutoButtonColor = false, ClipsDescendants = true },
        { corner(16), stroke(color, 1.2, 0.55) })
    local bubble = new("Frame", { Parent = card, Position = UDim2.fromOffset(14, 17), Size = UDim2.fromOffset(34, 34),
        BackgroundColor3 = color, BackgroundTransparency = 0.82, BorderSizePixel = 0 }, { corner(11) })
    icon(bubble, iname, UDim2.fromOffset(9, 9), UDim2.fromOffset(16, 16), color, 2, function()
        local dot = new("Frame", { Parent = bubble, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(10, 10), BackgroundColor3 = color, BorderSizePixel = 0 }, { corner(5) })
        return dot, function() end
    end)
    label(card, tostring(title or ""), UDim2.fromOffset(60, 12), UDim2.new(1, -72, 0, 18), Enum.Font.GothamBold, 13, "@Text")
    label(card, tostring(text or ""), UDim2.fromOffset(60, 32), UDim2.new(1, -72, 0, 18), Enum.Font.Gotham, 12, "@Sub")
    local bar = new("Frame", { Parent = card, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = color, BackgroundTransparency = 0.2, BorderSizePixel = 0 })
    tween(card, 0.6, { Position = UDim2.fromOffset(0, 0) }, BACK)
    tween(bar, dur, { Size = UDim2.new(0, 0, 0, 2) }, LINEAR)
    local closed = false
    local function close()
        if closed then return end
        closed = true
        tween(card, 0.4, { Position = UDim2.fromOffset(350, 0) }, QUINT, IN)
        task.wait(0.3)
        tween(wrap, 0.25, { Size = UDim2.fromOffset(300, 0) }, QUINT)
        task.wait(0.3)
        wrap:Destroy()
    end
    card.MouseButton1Click:Connect(function() task.spawn(close) end)
    task.delay(dur, function() if wrap.Parent then close() end end)
end

local function guiParent()
    if gethui then
        local ok, r = pcall(gethui)
        if ok and r then return r end
    end
    return LP:WaitForChild("PlayerGui")
end

function Lib:CreateWindow(o)
    o = o or {}
    local WIDTH, HEIGHT = 940, 600
    local W = setmetatable({
        Tabs = {}, Items = {}, Binds = {}, Conns = {}, GlassPanels = {}, GlassCards = {},
        Glass = o.Glass == true, Key = o.Key or Enum.KeyCode.RightShift, Open = true, UserScale = 1, GlassBlur = 40,
        W = WIDTH, H = HEIGHT, Folder = o.Folder or "FemboySense", Library = Lib, Query = "",
        Motion = true, HudMotion = true, WorldBlur = false, Effect = o.Effect or "Pop", Glow = o.Glow or 0.55,
    }, Window)
    table.insert(Lib.Windows, W)
    local function conn(c) table.insert(W.Conns, c) return c end
    W.keep = conn

    local parent = guiParent()
    local old = parent:FindFirstChild("FemboySenseHub")
    if old then old:Destroy() end
    W.Gui = new("ScreenGui", { Name = "FemboySenseHub", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999, Parent = parent })

    Lib._notif = new("Frame", { Parent = W.Gui, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.fromOffset(300, 520), BackgroundTransparency = 1, ZIndex = 100 },
        { new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })

    W.TipFrame = new("CanvasGroup", { Parent = W.Gui, Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "@Panel", BorderSizePixel = 0, Visible = false, GroupTransparency = 1, ZIndex = 200 },
        { corner(9), stroke("@Line", 1, 0.2),
          new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }) })
    W.TipLabel = new("TextLabel", { Parent = W.TipFrame, Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = "@Text", TextWrapped = true, Text = "",
        TextXAlignment = LEFT, ZIndex = 201 }, { new("UISizeConstraint", { MaxSize = Vector2.new(260, 400) }) })

    W.Root = new("Frame", { Parent = W.Gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(WIDTH, HEIGHT), BackgroundTransparency = 1 })
    W.Scale = new("UIScale", { Parent = W.Root, Scale = 1 })

    W.MainStroke = stroke("@Line", 1.2, 0.3)
    W.Main = new("CanvasGroup", { Parent = W.Root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = "@Outer",
        BorderSizePixel = 0, GroupTransparency = 1 }, { corner(26), W.MainStroke })
    W.Pop = new("UIScale", { Parent = W.Main, Scale = 0.86 })
    table.insert(W.GlassPanels, { W.Main, 0, 0.3 })

    local side = new("Frame", { Parent = W.Main, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(208, HEIGHT - 24),
        BackgroundColor3 = "@Panel", BorderSizePixel = 0 }, { corner(18), stroke("@Line", 1, 0.5) })
    table.insert(W.GlassPanels, { side, 0, 0.35 })

    local logoArea = new("Frame", { Parent = side, Size = UDim2.fromOffset(208, 78), BackgroundTransparency = 1 })
    W.LogoBars = {}
    for i, h in ipairs({ 14, 24, 30 }) do
        W.LogoBars[i] = { new("Frame", { Parent = logoArea, AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromOffset(18 + (i - 1) * 10, 54), Size = UDim2.fromOffset(6, h), BackgroundColor3 = "@Text",
            BorderSizePixel = 0 }, { corner(2) }), h }
    end
    label(logoArea, string.upper(o.Title or "ECLIPSE"), UDim2.fromOffset(60, 20), UDim2.fromOffset(142, 22), Enum.Font.GothamBlack, 15, "@Text")
    label(logoArea, string.upper(o.Subtitle or "VISUAL UTILITY"), UDim2.fromOffset(60, 42), UDim2.fromOffset(142, 14), Enum.Font.GothamMedium, 9, "@Sub")

    W.TabScroll = new("ScrollingFrame", { Parent = side, Position = UDim2.fromOffset(10, 84), Size = UDim2.new(1, -20, 1, -84 - 112),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y })
    W.Indicator = new("Frame", { Parent = W.TabScroll, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = "@Card2",
        BackgroundTransparency = 0.1, BorderSizePixel = 0, Visible = false }, { corner(12) })
    new("Frame", { Parent = W.Indicator, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(3, 18), BackgroundColor3 = "@Accent", BorderSizePixel = 0 }, { corner(2) })
    W.TabList = new("Frame", { Parent = W.TabScroll, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1 }, { new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })

    label(side, (o.Version or "1.0") .. " / " .. (o.Tag or "HUB"), UDim2.new(0, 14, 1, -98), UDim2.fromOffset(160, 14), Enum.Font.GothamMedium, 9, "@Sub")

    local user = new("TextButton", { Parent = side, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -10),
        Size = UDim2.fromOffset(188, 62), BackgroundColor3 = "@Card", Text = "", AutoButtonColor = false, BorderSizePixel = 0 },
        { corner(14), stroke("@Line", 1, 0.5) })
    new("ImageLabel", { Parent = user, Position = UDim2.fromOffset(10, 13), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = "@Card2",
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=100&h=100" }, { corner(18) })
    W.UserName = label(user, o.UserName or "Client", UDim2.fromOffset(56, 14), UDim2.fromOffset(104, 16), Enum.Font.GothamBold, 12, "@Text")
    W.UserSub = label(user, o.UserSub or "Configs", UDim2.fromOffset(56, 31), UDim2.fromOffset(104, 14), Enum.Font.Gotham, 10, "@Sub")
    local chev = label(user, ">", UDim2.new(1, -24, 0, 0), UDim2.fromOffset(14, 62), Enum.Font.GothamBold, 12, "@Sub")
    user.MouseEnter:Connect(function()
        tween(user, 0.25, { BackgroundColor3 = hoverColor() }, SINE)
        tween(chev, 0.3, { Position = UDim2.new(1, -20, 0, 0) }, BACK)
    end)
    user.MouseLeave:Connect(function()
        tween(user, 0.3, { BackgroundColor3 = Theme.Card }, SINE)
        tween(chev, 0.3, { Position = UDim2.new(1, -24, 0, 0) }, QUINT)
    end)
    user.MouseButton1Click:Connect(function()
        if o.OnUser then fire(o.OnUser) return end
        local t = W:GetTab(o.UserTab or "Configs")
        if t then W:Select(t) end
    end)

    local topW = WIDTH - 244
    local top = new("Frame", { Parent = W.Main, Position = UDim2.fromOffset(232, 12), Size = UDim2.fromOffset(topW, 56),
        BackgroundColor3 = "@Panel", BorderSizePixel = 0 }, { corner(18), stroke("@Line", 1, 0.5) })
    table.insert(W.GlassPanels, { top, 0, 0.35 })

    local pill = new("Frame", { Parent = top, Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(180, 40),
        BackgroundColor3 = "@Content", BorderSizePixel = 0 }, { corner(12), stroke("@Line", 1, 0.6) })
    W.StatusDot = new("Frame", { Parent = pill, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(21, 20),
        Size = UDim2.fromOffset(10, 10), BackgroundColor3 = "@Accent", BorderSizePixel = 0 }, { corner(5) })
    label(pill, o.Version or "1.21.11", UDim2.fromOffset(40, 0), UDim2.fromOffset(80, 40), Enum.Font.GothamBold, 14, "@Text")
    label(pill, string.upper(o.Tag or "FABRIC"), UDim2.new(1, -66, 0, 0), UDim2.fromOffset(54, 40), Enum.Font.GothamMedium, 9, "@Sub", RIGHT)

    local searchBack = new("Frame", { Parent = top, Position = UDim2.fromOffset(206, 8), Size = UDim2.fromOffset(330, 40),
        BackgroundColor3 = "@Content", BorderSizePixel = 0 }, { corner(12) })
    local sStroke = stroke("@Line", 1, 0.6)
    sStroke.Parent = searchBack
    icon(searchBack, "search", UDim2.fromOffset(14, 12), UDim2.fromOffset(16, 16), "@Sub", 2, function()
        local c = new("Frame", { Parent = searchBack, Position = UDim2.fromOffset(14, 12), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1 },
            { corner(6), stroke("@Sub", 1.5) })
        new("Frame", { Parent = searchBack, Position = UDim2.fromOffset(24, 25), Size = UDim2.fromOffset(6, 2), Rotation = 45,
            BackgroundColor3 = "@Sub", BorderSizePixel = 0 })
        return c, function() end
    end)
    W.Search = new("TextBox", { Parent = searchBack, Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -50, 1, 0),
        BackgroundTransparency = 1, PlaceholderText = o.SearchText or "Search modules...", PlaceholderColor3 = "@Sub", Text = "",
        TextColor3 = "@Text", Font = Enum.Font.GothamMedium, TextSize = 13, ClearTextOnFocus = false, TextXAlignment = LEFT })
    W.Search:GetPropertyChangedSignal("Text"):Connect(function() W:_filter(W.Search.Text) end)
    W.Search.Focused:Connect(function()
        tween(sStroke, 0.3, { Color = Theme.Accent, Transparency = 0.05, Thickness = 1.6 }, SINE)
        tween(searchBack, 0.35, { Size = UDim2.fromOffset(380, 40) }, BACK)
    end)
    W.Search.FocusLost:Connect(function()
        tween(sStroke, 0.35, { Color = Theme.Line, Transparency = 0.6, Thickness = 1 }, SINE)
        tween(searchBack, 0.35, { Size = UDim2.fromOffset(330, 40) }, QUINT)
    end)

    local function topBtn(x)
        return new("TextButton", { Parent = top, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, x, 0, 8),
            Size = UDim2.fromOffset(40, 40), BackgroundColor3 = "@Content", Text = "", AutoButtonColor = false, BorderSizePixel = 0 },
            { corner(12), stroke("@Line", 1, 0.6) })
    end
    local function topHover(b, extra)
        b.MouseEnter:Connect(function() tween(b, 0.25, { BackgroundColor3 = Theme.Card2 }, SINE) if extra then extra(true) end end)
        b.MouseLeave:Connect(function() tween(b, 0.3, { BackgroundColor3 = Theme.Content }, SINE) if extra then extra(false) end end)
    end

    local chat = topBtn(-106)
    icon(chat, "chat", UDim2.fromOffset(12, 12), UDim2.fromOffset(16, 16), "@Text", 2, function()
        local l = label(chat, "💬", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.Font.Gotham, 16, "@Text", CENTER)
        return l, function() end
    end)
    topHover(chat)
    chat.MouseButton1Click:Connect(function() if o.OnChat then fire(o.OnChat) end end)

    local lang = topBtn(-58)
    label(lang, "EN", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.Font.GothamBold, 12, "@Text", CENTER)
    topHover(lang)

    local sett = topBtn(-10)
    local gear
    icon(sett, "sliders", UDim2.fromOffset(12, 12), UDim2.fromOffset(16, 16), "@Text", 2, function()
        gear = new("Frame", { Parent = sett, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1 }, { corner(8), stroke("@Text", 1.6) })
        return gear, function() end
    end)
    topHover(sett, function(on)
        if gear then tween(gear, on and 0.6 or 0.5, { Rotation = on and 180 or 0 }, on and BACK or QUINT) end
    end)
    sett.MouseButton1Click:Connect(function()
        if o.OnSettings then fire(o.OnSettings) return end
        local t = W:GetTab("Settings") or W:GetTab("Appearance")
        if t then W:Select(t) end
    end)

    local CH = HEIGHT - 76 - 40
    W.Content = new("Frame", { Parent = W.Main, Position = UDim2.fromOffset(232, 76), Size = UDim2.fromOffset(topW, CH),
        BackgroundColor3 = "@Content", BorderSizePixel = 0, ClipsDescendants = true }, { corner(18), stroke("@Line", 1, 0.6) })
    table.insert(W.GlassPanels, { W.Content, 0, 0.5 })
    W.Title = label(W.Content, "", UDim2.fromOffset(22, 14), UDim2.fromOffset(380, 30), Enum.Font.GothamBold, 24, "@Text")
    W.Sub = label(W.Content, "", UDim2.fromOffset(22, 48), UDim2.fromOffset(440, 16), Enum.Font.Gotham, 12, "@Sub")

    W.Footer = new("TextLabel", { Parent = W.Main, Position = UDim2.fromOffset(240, HEIGHT - 32), Size = UDim2.fromOffset(400, 16),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 9, TextColor3 = "@Sub",
        TextXAlignment = LEFT, AutoLocalize = false, Text = "" })
    function W:_footer()
        self.Footer.Text = string.upper(keyName(self.Key) .. "  ·  CLOSE  ·  DRAG TOPBAR  ·  MOVE")
    end
    W:_footer()
    label(W.Main, string.upper(o.Title or "ECLIPSE") .. " " .. string.upper(o.Subtitle or "VISUAL UTILITY"),
        UDim2.new(1, -250, 1, -32), UDim2.fromOffset(230, 16), Enum.Font.GothamMedium, 9, "@Sub", RIGHT)

    dragify(W, top, W.Root)
    dragify(W, logoArea, W.Root)

    conn(UIS.InputBegan:Connect(function(input, gp)
        local key = inputKey(input)
        if W.Listening then
            if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                local f = W.Listening
                W.Listening = nil
                f(key)
            end
            return
        end
        if gp then return end
        if key == W.Key then W:Toggle() return end
        for _, b in ipairs(W.Binds) do
            if b.Key and key == b.Key then task.spawn(b.Press, true) end
        end
    end))
    conn(UIS.InputEnded:Connect(function(input)
        local key = inputKey(input)
        for _, b in ipairs(W.Binds) do
            if b.Key and b.Mode == "Hold" and key == b.Key then task.spawn(b.Press, false) end
        end
    end))

    onTheme(function()
        for _, t in ipairs(W.Tabs) do
            local c = t.Active and Theme.Text or Theme.Sub
            t.NameLabel.TextColor3 = c
            t.paint(c)
        end
    end)

    conn(RunService.RenderStepped:Connect(function()
        W.Scale.Scale = W:_scale()
        if W.Open then
            local t = os.clock()
            for i, b in ipairs(W.LogoBars) do
                local h = b[2] * (0.7 + 0.3 * math.sin(t * 2.6 + i * 1.3))
                b[1].Size = UDim2.fromOffset(6, h)
            end
            W.StatusDot.BackgroundTransparency = 0.5 - 0.5 * math.sin(t * 3)
            -- Interface glow
            local pulse = 0.5 + 0.5 * math.sin(t * 1.6)
            local g = W.Glow * (0.55 + 0.45 * pulse)
            W.MainStroke.Color = Theme.Line:Lerp(Theme.Accent, g)
            W.MainStroke.Thickness = 1.2 + W.Glow * 1.1
            W.MainStroke.Transparency = 0.3 - 0.25 * W.Glow
        end
        if W.TipFrame.Visible then
            local m = UIS:GetMouseLocation()
            local vp = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
            local sz = W.TipFrame.AbsoluteSize
            local x = math.min(m.X + 16, vp.X - sz.X - 8)
            local y = math.min(m.Y + 18, vp.Y - sz.Y - 8)
            W.TipFrame.Position = UDim2.fromOffset(x, y)
        end
    end))
    W.Blur = new("BlurEffect", { Parent = Lighting, Size = 0 })
    task.defer(function() W:_playOpen(true, true) end)
    if W.Glass then W:SetGlass(true) end
    return W
end

function Window:_scale()
    local cam = Workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    return math.clamp(math.min(vp.X / (self.W + 40), vp.Y / (self.H + 40)), 0.4, 1.2) * self.UserScale
end
function Window:SetScale(v) self.UserScale = v end
function Window:SetKey(k) self.Key = k self:_footer() end
function Window:SetGlow(pct) self.Glow = math.clamp(pct / 100, 0, 1) end
function Window:SetEffect(name) self.Effect = name end
function Window:SetMotion(on) self.Motion = on and true or false end
function Window:SetHudMotion(on) self.HudMotion = on and true or false end
function Window:SetWorldBlur(on) self.WorldBlur = on and true or false self:_blur() end

function Window:_blur()
    if not self.Blur then return end
    local s = 0
    if self.Open then
        if self.Glass then s = self.GlassBlur * 0.5 end
        if self.WorldBlur then s = math.max(s, 18) end
    end
    tween(self.Blur, 0.4, { Size = s }, SINE)
end
function Window:SetGlass(on)
    self.Glass = on and true or false
    for _, g in ipairs(self.GlassPanels) do tween(g[1], 0.45, { BackgroundTransparency = self.Glass and g[3] or g[2] }, SINE) end
    for _, c in ipairs(self.GlassCards) do
        if c.Parent then tween(c, 0.45, { BackgroundTransparency = self.Glass and 0.25 or 0 }, SINE) end
    end
    self:_blur()
end
function Window:SetGlassBlur(pct) self.GlassBlur = pct self:_blur() end

-- tooltips
function Window:_tip(obj, text)
    obj.MouseEnter:Connect(function()
        local t = type(text) == "function" and text() or text
        if not t or t == "" then return end
        self.TipLabel.Text = tostring(t)
        self.TipFrame.Visible = true
        tween(self.TipFrame, 0.18, { GroupTransparency = 0 }, SINE)
    end)
    obj.MouseLeave:Connect(function()
        tween(self.TipFrame, 0.15, { GroupTransparency = 1 }, SINE)
        task.delay(0.16, function() if self.TipFrame.GroupTransparency >= 0.99 then self.TipFrame.Visible = false end end)
    end)
end

function Window:_wave()
    for i = 1, 3 do
        task.delay((i - 1) * 0.12, function()
            if not self.Root.Parent then return end
            local st = stroke(Theme.Accent, 2.5, 0.15)
            local ring = new("Frame", { Parent = self.Root, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(140, 90), BackgroundTransparency = 1, ZIndex = 0 },
                { new("UICorner", { CornerRadius = UDim.new(0.2, 0) }), st })
            tween(ring, 1, { Size = UDim2.fromOffset(self.W + 320, self.H + 240) }, QUINT)
            tween(st, 1, { Transparency = 1, Thickness = 0.5 }, QUINT)
            task.delay(1.05, function() ring:Destroy() end)
        end)
    end
end

function Window:_playOpen(open, first)
    local fx = self.Effect
    local d = function(x) return self.Motion and x or 0.01 end
    if open then
        self.Root.Visible = true
        self.Main.Position = UDim2.fromScale(0, 0)
        if fx == "Fade" then self.Pop.Scale = 1
        elseif fx == "Slide" then self.Pop.Scale = 0.97 self.Main.Position = UDim2.fromOffset(0, 70)
        else self.Pop.Scale = first and 0.86 or 0.88 end
        tween(self.Pop, d(0.7), { Scale = 1 }, BACK)
        tween(self.Main, d(0.4), { GroupTransparency = 0 }, QUINT)
        if fx == "Slide" then tween(self.Main, d(0.65), { Position = UDim2.fromScale(0, 0) }, EXPO) end
        if fx == "Sound wave" and self.Motion then self:_wave() end
    else
        self:_closePopup()
        if fx == "Slide" then tween(self.Main, d(0.3), { Position = UDim2.fromOffset(0, 50) }, QUINT, IN) end
        if fx ~= "Fade" then tween(self.Pop, d(0.3), { Scale = 0.92 }, QUINT, IN) end
        tween(self.Main, d(0.28), { GroupTransparency = 1 }, QUINT)
        task.delay(d(0.32), function() if not self.Open then self.Root.Visible = false end end)
    end
end

function Window:Toggle(force)
    if force ~= nil then self.Open = force else self.Open = not self.Open end
    self:_playOpen(self.Open)
    self:_blur()
end
function Window:Notify(t, x, d, k) Lib:Notify(t, x, d, k) end
function Window:Destroy()
    self:_closePopup()
    for _, c in ipairs(self.Conns) do pcall(function() c:Disconnect() end) end
    if self.Blur then self.Blur:Destroy() end
    self.Gui:Destroy()
end

function Window:_closePopup()
    local p = self._pop
    if not p then return end
    self._pop = nil
    for _, c in ipairs(p.conns) do pcall(function() c:Disconnect() end) end
    p.blocker:Destroy()
    tween(p.scale, 0.18, { Scale = 0.94 }, QUINT, IN)
    tween(p.frame, 0.16, { GroupTransparency = 1 }, QUINT)
    task.delay(0.2, function() p.frame:Destroy() end)
end
function Window:_popup(card, width, height, build)
    self:_closePopup()
    local sc = math.max(self.Scale.Scale, 0.05)
    local rel = (card.AbsolutePosition - self.Root.AbsolutePosition) / sc
    local cw, ch = card.AbsoluteSize.X / sc, card.AbsoluteSize.Y / sc
    local x = math.clamp(rel.X + cw - width, 8, self.W - width - 8)
    local y = rel.Y + ch + 6
    if y + height > self.H - 8 then y = rel.Y - height - 6 end
    y = math.max(y, 8)
    local blocker = new("TextButton", { Parent = self.Root, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, ZIndex = 50 })
    local frame = new("CanvasGroup", { Parent = self.Root, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = "@Panel", BorderSizePixel = 0, ZIndex = 51, GroupTransparency = 1 }, { corner(12), stroke("@Line", 1, 0.2) })
    local scale = new("UIScale", { Parent = frame, Scale = 0.9 })
    local pop = { blocker = blocker, frame = frame, scale = scale, conns = {} }
    self._pop = pop
    blocker.MouseButton1Click:Connect(function() self:_closePopup() end)
    build(frame, pop)
    tween(scale, 0.4, { Scale = 1 }, BACK)
    tween(frame, 0.2, { GroupTransparency = 0 }, QUINT)
    return pop
end

function Window:GetTab(name) for _, t in ipairs(self.Tabs) do if t.Name == name then return t end end end

function Window:AddTab(name, opts)
    if type(opts) == "string" then opts = { Sub = opts } end
    opts = opts or {}
    local W = self
    local idx = #W.Tabs + 1

    local btn = new("TextButton", { Parent = W.TabList, LayoutOrder = idx, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, BorderSizePixel = 0 })
    local autoName = (name:lower():gsub("%s+", "_"))
    local _, paint = icon(btn, opts.Icon or autoName, UDim2.fromOffset(14, 10), UDim2.fromOffset(20, 20), Theme.Sub, 2)
    local nameLabel = label(btn, name, UDim2.fromOffset(46, 0), UDim2.new(1, -56, 1, 0), Enum.Font.GothamMedium, 13, Theme.Sub)

    local holder = new("CanvasGroup", { Parent = W.Content, Position = UDim2.fromOffset(12, 84), Size = UDim2.new(1, -24, 1, -92),
        BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 })
    local page = new("ScrollingFrame", { Parent = holder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = "@Card2", CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y },
        { new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
          new("UIPadding", { PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8) }) })

    local tab = setmetatable({ Window = W, Name = name, Sub = opts.Sub or "", Btn = btn, NameLabel = nameLabel, Page = page, Holder = holder,
        paint = paint, Order = 0, Active = false, Sections = {}, _row = nil, _rowN = 0, Index = idx }, Tab)
    table.insert(W.Tabs, tab)

    if opts.Segment then
        local seg = opts.Segment
        local n = #seg.Options
        local segW = n * 62 + 8
        local seg_h = new("Frame", { Parent = W.Content, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 18),
            Size = UDim2.fromOffset(segW, 30), BackgroundColor3 = "@Panel", BorderSizePixel = 0, Visible = false }, { corner(10) })
        local sel = seg.Default or seg.Options[1]
        local selIdx = table.find(seg.Options, sel) or 1
        local slider = new("Frame", { Parent = seg_h, Position = UDim2.fromOffset(4 + (selIdx - 1) * 62, 3), Size = UDim2.fromOffset(60, 24),
            BackgroundColor3 = "@Card2", BorderSizePixel = 0 }, { corner(8) })
        local btns = {}
        local function paintSeg(anim)
            local i = table.find(seg.Options, sel) or 1
            tween(slider, anim and 0.4 or 0.01, { Position = UDim2.fromOffset(4 + (i - 1) * 62, 3) }, BACK)
            for nme, b in pairs(btns) do tween(b, 0.25, { TextColor3 = nme == sel and Theme.Text or Theme.Sub }, SINE) end
        end
        for i, nme in ipairs(seg.Options) do
            local b = new("TextButton", { Parent = seg_h, Position = UDim2.fromOffset(4 + (i - 1) * 62, 3), Size = UDim2.fromOffset(60, 24),
                BackgroundTransparency = 1, Text = nme, TextColor3 = Theme.Sub, Font = Enum.Font.GothamMedium, TextSize = 11,
                AutoButtonColor = false, ZIndex = 2 })
            btns[nme] = b
            b.MouseButton1Click:Connect(function() sel = nme paintSeg(true) fire(seg.Callback, nme) end)
        end
        paintSeg(false)
        onTheme(function() paintSeg(false) end)
        tab.SegmentFrame = seg_h
        local api = { Get = function() return sel end, Export = function() return sel end }
        function api:Set(v) if btns[v] then sel = v paintSeg(true) fire(seg.Callback, v) end end
        api.Import = function(v) api:Set(v) end
        if seg.Flag then Lib.Flags[seg.Flag] = api end
        tab.Segment = api
        task.defer(function() if seg.Default then fire(seg.Callback, sel) end end)
    end

    btn.MouseEnter:Connect(function()
        if not tab.Active then
            tween(nameLabel, 0.2, { TextColor3 = Theme.Text, Position = UDim2.fromOffset(52, 0) }, SINE)
            paint(Theme.Text)
        end
    end)
    btn.MouseLeave:Connect(function()
        tween(nameLabel, 0.3, { Position = UDim2.fromOffset(46, 0) }, QUINT)
        if not tab.Active then
            tween(nameLabel, 0.25, { TextColor3 = Theme.Sub }, SINE)
            paint(Theme.Sub)
        end
    end)
    btn.MouseButton1Click:Connect(function() W:Select(tab) end)
    if idx == 1 then W:Select(tab) end
    return tab
end

function Window:Select(tab)
    if self.Current == tab then return end
    local old = self.Current
    self.Current = tab
    self:_closePopup()
    for _, t in ipairs(self.Tabs) do
        local on = t == tab
        t.Active = on
        tween(t.NameLabel, D(self, 0.3), { TextColor3 = on and Theme.Text or Theme.Sub }, SINE)
        t.paint(on and Theme.Text or Theme.Sub)
        if t.SegmentFrame then t.SegmentFrame.Visible = on end
    end
    local ind = self.Indicator
    local y = (tab.Index - 1) * 44
    if not ind.Visible then
        ind.Position = UDim2.fromOffset(0, y)
        ind.Visible = true
    else
        tween(ind, D(self, 0.5), { Position = UDim2.fromOffset(0, y) }, BACK)
    end
    self.Title.Text, self.Sub.Text = tab.Name, tab.Sub
    self.Title.TextTransparency, self.Sub.TextTransparency = 1, 1
    self.Title.Position, self.Sub.Position = UDim2.fromOffset(6, 14), UDim2.fromOffset(6, 48)
    tween(self.Title, D(self, 0.5), { TextTransparency = 0, Position = UDim2.fromOffset(22, 14) }, QUINT)
    tween(self.Sub, D(self, 0.6), { TextTransparency = 0, Position = UDim2.fromOffset(22, 48) }, QUINT)

    if old then
        local oh = old.Holder
        tween(oh, D(self, 0.15), { GroupTransparency = 1 }, SINE)
        task.delay(0.16, function() if self.Current ~= old then oh.Visible = false end end)
    end
    local h = tab.Holder
    h.Position = UDim2.fromOffset(12, 108)
    h.GroupTransparency = 1
    h.Visible = true
    tween(h, D(self, 0.55), { Position = UDim2.fromOffset(12, 84), GroupTransparency = 0 }, QUINT)
end

function Window:_filter(q)
    q = (q or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    self.Query = q
    local counts, rowVis = {}, {}
    for _, it in ipairs(self.Items) do
        local hit = q == "" or it.text:find(q, 1, true) ~= nil
        it.frame.Visible = hit
        if hit then
            counts[it.tab] = (counts[it.tab] or 0) + 1
            if it.row then rowVis[it.row] = true end
        end
    end
    for _, it in ipairs(self.Items) do if it.row then it.row.Visible = q == "" or rowVis[it.row] == true end end
    for _, t in ipairs(self.Tabs) do
        for _, s in ipairs(t.Sections) do s.Visible = q == "" end
        tween(t.NameLabel, 0.2, { TextTransparency = (q ~= "" and not counts[t]) and 0.65 or 0 }, SINE)
    end
    if q ~= "" and self.Current and not counts[self.Current] then
        for _, t in ipairs(self.Tabs) do if counts[t] then self:Select(t) break end end
    end
end

------------------------------------------------------------------
-- TAB SLOTS / CARDS
------------------------------------------------------------------
function Tab:_slot(h, half)
    if half then
        local row = self._row
        if not row or self._rowN >= 2 then
            self.Order += 1
            row = new("Frame", { Parent = self.Page, LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1 },
                { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
            self._row, self._rowN = row, 0
        end
        self._rowN += 1
        if row.Size.Y.Offset < h then row.Size = UDim2.new(1, 0, 0, h) end
        return row, UDim2.new(0.5, -5, 1, 0), row, self._rowN
    end
    self._row = nil
    self.Order += 1
    return self.Page, UDim2.new(1, 0, 0, h), nil, self.Order
end

function Tab:_card(h, o, text)
    o = o or {}
    local W = self.Window
    local parent, size, row, order = self:_slot(h, o.Half)
    local st = stroke("@Line", 1, 0.45)
    local f = new("Frame", { Parent = parent, LayoutOrder = order, Size = size, BackgroundColor3 = "@Card", BorderSizePixel = 0,
        BackgroundTransparency = W.Glass and 0.25 or 0, ClipsDescendants = true },
        { corner(14), st, new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 0.12) }) })
    f.MouseEnter:Connect(function()
        tween(f, 0.25, { BackgroundColor3 = hoverColor() }, SINE)
        tween(st, 0.3, { Color = Theme.Accent, Transparency = 0.55 }, SINE)
    end)
    f.MouseLeave:Connect(function()
        tween(f, 0.35, { BackgroundColor3 = Theme.Card }, SINE)
        tween(st, 0.4, { Color = Theme.Line, Transparency = 0.45 }, SINE)
    end)
    local entry = { frame = f, row = row, text = (text or ""):lower(), tab = self }
    table.insert(W.Items, entry)
    table.insert(W.GlassCards, f)
    return f, entry
end

local function rowLabel(host, name, desc, rightPad, compact)
    local pad = compact and 0 or 14
    if compact or not desc then
        label(host, name or "Option", UDim2.fromOffset(pad, 0), UDim2.new(1, -(pad + rightPad), 1, 0), Enum.Font.GothamMedium, 12,
            compact and "@Sub" or "@Text")
    else
        label(host, name or "Option", UDim2.fromOffset(pad, 9), UDim2.new(1, -(pad + rightPad), 0, 18), Enum.Font.GothamMedium, 12, "@Text")
        label(host, desc, UDim2.fromOffset(pad, 28), UDim2.new(1, -(pad + rightPad), 0, 14), Enum.Font.Gotham, 10, "@Sub")
    end
end
local function clickArea(card)
    return new("TextButton", { Parent = card, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2 })
end
local function register(o, api) if o.Flag then Lib.Flags[o.Flag] = api end return api end
local function tipFor(host, o, W, compact)
    local t = o.Tooltip or (compact and o.Desc)
    if t then W:_tip(host, t) end
end

------------------------------------------------------------------
-- ELEMENT BUILDERS (host = frame, compact = внутри модуля)
------------------------------------------------------------------
local function buildToggle(host, o, W, compact)
    local edge = compact and 0 or 14
    local state = o.Default == true
    local hasBind = o.Keybind ~= nil and o.Keybind ~= false
    rowLabel(host, o.Name, o.Desc, edge + 54 + (hasBind and 66 or 0), compact)
    tipFor(host, o, W, compact)
    local track = new("Frame", { Parent = host, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -edge, 0.5, 0), Size = UDim2.fromOffset(40, 22),
        BackgroundColor3 = state and Theme.Accent or Theme.Off, BorderSizePixel = 0 }, { corner(11), stroke("@Line", 1, 0.4) })
    local knob = new("Frame", { Parent = track, Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = "@Knob", BorderSizePixel = 0 }, { corner(8) })
    local function render(anim)
        tween(track, anim and 0.3 or 0.01, { BackgroundColor3 = state and Theme.Accent or Theme.Off }, SINE)
        if anim then
            tween(knob, 0.12, { Size = UDim2.fromOffset(24, 16) }, QUINT)
            task.delay(0.1, function()
                tween(knob, 0.45, { Size = UDim2.fromOffset(16, 16), Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3) }, BACK)
            end)
        else
            knob.Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
        end
    end
    onTheme(function() render(false) end)

    local api = {}
    function api:Get() return state end
    function api:Set(v, silent)
        v = v and true or false
        if v == state then return end
        state = v
        render(true)
        if not silent then fire(o.Callback, state) end
    end
    api.SetSilent = function(_, v) api:Set(v, true) end
    local hit = clickArea(host)
    hit.InputBegan:Connect(function(i) if isPress(i) then ripple(host, i, W) end end)
    hit.MouseButton1Click:Connect(function() api:Set(not state) end)

    local bind
    if hasBind then
        bind = { Key = (typeof(o.Keybind) == "EnumItem") and o.Keybind or nil, Mode = "Press", Name = o.Name or "Toggle",
            Active = function() return state end, NoHud = o.HUD == false,
            Press = function(down) if down then api:Set(not state) end end }
        table.insert(W.Binds, bind)
        local pillB = new("TextButton", { Parent = host, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(edge + 48), 0.5, 0), Size = UDim2.fromOffset(60, 24),
            BackgroundColor3 = "@Card2", Text = keyName(bind.Key), TextColor3 = "@Sub", Font = Enum.Font.GothamBold, TextSize = 9,
            AutoButtonColor = false, ZIndex = 3, BorderSizePixel = 0 }, { corner(8) })
        pillB.MouseButton1Click:Connect(function()
            pillB.Text = "..."
            tween(pillB, 0.2, { TextColor3 = Theme.Accent }, SINE)
            W.Listening = function(k)
                if k == Enum.KeyCode.Backspace or k == Enum.KeyCode.Delete then bind.Key = nil
                elseif k ~= Enum.KeyCode.Escape then bind.Key = k end
                pillB.Text = keyName(bind.Key)
                tween(pillB, 0.3, { TextColor3 = Theme.Sub }, SINE)
            end
        end)
        bind.pill = pillB
    end
    api.Export = function()
        if bind then return { State = state, Key = keyToTbl(bind.Key) } end
        return state
    end
    api.Import = function(v)
        if type(v) == "table" then
            if bind then bind.Key = tblToKey(v.Key) bind.pill.Text = keyName(bind.Key) end
            api:Set(v.State, false)
        else api:Set(v, false) end
    end
    register(o, api)
    if state then fire(o.Callback, state) end
    return api
end

local function buildSlider(host, o, W, compact)
    local pad = compact and 0 or 14
    local bp = compact and 7 or 14
    local ly, by = compact and 2 or 9, compact and 28 or 38
    local min, max, step = o.Min or 0, o.Max or 100, o.Step or 1
    local digits = step >= 1 and 0 or math.max(0, -math.floor(math.log10(step) + 1e-9))
    local value = math.clamp(o.Default or min, min, max)
    tipFor(host, o, W, compact)
    label(host, o.Name or "Slider", UDim2.fromOffset(pad, ly), UDim2.new(1, -(pad + 90), 0, 16), Enum.Font.GothamMedium, 12, compact and "@Sub" or "@Text")
    local vl = label(host, "", UDim2.new(1, -(pad + 80), 0, ly), UDim2.fromOffset(80, 16), Enum.Font.GothamMedium, 11, "@Accent", RIGHT)
    local bar = new("Frame", { Parent = host, Position = UDim2.fromOffset(bp, by), Size = UDim2.new(1, -bp * 2, 0, 4), BackgroundColor3 = "@Card2", BorderSizePixel = 0 }, { corner(2) })
    local fill = new("Frame", { Parent = bar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = "@Accent", BorderSizePixel = 0 },
        { corner(2), new("UIGradient", { Transparency = NumberSequence.new(0.25, 0) }) })
    local knob = new("Frame", { Parent = bar, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = "@Knob", BorderSizePixel = 0, ZIndex = 2 }, { corner(6), stroke("@Accent", 1.5) })
    local halo = new("Frame", { Parent = knob, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = "@Accent", BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 }, { corner(20) })
    local function render(fast)
        local r = (value - min) / (max - min)
        vl.Text = string.format("%." .. digits .. "f", value) .. (o.Suffix or "")
        local t = fast and 0.08 or 0.35
        tween(fill, t, { Size = UDim2.fromScale(r, 1) }, SINE)
        tween(knob, t, { Position = UDim2.fromScale(r, 0.5) }, SINE)
    end
    local function setV(v, fast, silent)
        v = math.clamp(min + math.floor((v - min) / step + 0.5) * step, min, max)
        v = tonumber(string.format("%.6f", v))
        if v ~= value then
            value = v
            render(fast)
            if not silent then fire(o.Callback, v) end
        end
    end
    render(false)
    local hit = new("TextButton", { Parent = host, Position = UDim2.fromOffset(bp - 8, by - 10), Size = UDim2.new(1, -(bp * 2 - 16), 0, 24),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3 })
    local dragging = false
    local function fromX(x)
        setV(min + (max - min) * math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1), true)
    end
    hit.InputBegan:Connect(function(i)
        if isPress(i) then
            dragging = true
            tween(knob, 0.3, { Size = UDim2.fromOffset(17, 17) }, BACK)
            tween(halo, 0.3, { Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 0.82 }, QUINT)
            tween(vl, 0.2, { TextSize = 13 }, QUINT)
            fromX(i.Position.X)
        end
    end)
    W.keep(UIS.InputChanged:Connect(function(i) if dragging and isMove(i) then fromX(i.Position.X) end end))
    W.keep(UIS.InputEnded:Connect(function(i)
        if dragging and isPress(i) then
            dragging = false
            tween(knob, 0.4, { Size = UDim2.fromOffset(12, 12) }, BACK)
            tween(halo, 0.35, { Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1 }, QUINT)
            tween(vl, 0.25, { TextSize = 11 }, QUINT)
        end
    end))
    local api = {}
    function api:Get() return value end
    function api:Set(v, silent) setV(v, false, silent) end
    api.SetSilent = function(_, v) setV(v, false, true) end
    api.Export = function() return value end
    api.Import = function(v) if type(v) == "number" then setV(v, false) end end
    return register(o, api)
end

local function buildDropdown(host, o, W, compact)
    local edge = compact and 0 or 14
    local opts = o.Options or {}
    local selected = o.Default or opts[1]
    tipFor(host, o, W, compact)
    label(host, o.Name or "Dropdown", UDim2.fromOffset(edge, 0), UDim2.new(1, -(edge + 150), 1, 0), Enum.Font.GothamMedium, 12, compact and "@Sub" or "@Text")
    local vl = label(host, tostring(selected), UDim2.new(1, -(edge + 136), 0, 0), UDim2.new(0, 120, 1, 0), Enum.Font.Gotham, 10, "@Sub", RIGHT)
    local arrow = label(host, ">", UDim2.new(1, -(edge + 12), 0, 0), UDim2.new(0, 12, 1, 0), Enum.Font.GothamBold, 11, "@Sub", CENTER)
    arrow.Rotation = 0
    local api = {}
    local function choose(v, silent)
        selected = v
        vl.Text = tostring(v)
        if not silent then fire(o.Callback, v) end
    end
    local hit = clickArea(host)
    hit.InputBegan:Connect(function(i) if isPress(i) then ripple(host, i, W) end end)
    hit.MouseButton1Click:Connect(function()
        if W._pop then W:_closePopup() tween(arrow, 0.3, { Rotation = 0 }, QUINT) return end
        local width = math.max(host.AbsoluteSize.X / math.max(W.Scale.Scale, 0.05), 170)
        local h = math.min(#opts, 7) * 30 + 12
        tween(arrow, 0.35, { Rotation = 90 }, BACK)
        W:_popup(host, width, h, function(frame)
            local sc = new("ScrollingFrame", { Parent = frame, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12), BackgroundTransparency = 1,
                BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = "@Accent", CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 52 }, { new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })
            for i, opt in ipairs(opts) do
                local on = opt == selected
                local b = new("TextButton", { Parent = sc, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = "@Card2",
                    BackgroundTransparency = on and 0.3 or 1, Text = "  " .. tostring(opt), TextColor3 = on and Theme.Accent or Theme.Text,
                    Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = LEFT, AutoButtonColor = false, ZIndex = 52,
                    BorderSizePixel = 0 }, { corner(8) })
                b.MouseEnter:Connect(function() tween(b, 0.15, { BackgroundTransparency = 0.3 }, SINE) end)
                b.MouseLeave:Connect(function() tween(b, 0.2, { BackgroundTransparency = (opt == selected) and 0.3 or 1 }, SINE) end)
                b.MouseButton1Click:Connect(function() choose(opt) W:_closePopup() tween(arrow, 0.3, { Rotation = 0 }, QUINT) end)
            end
            task.defer(function()
                local idx = table.find(opts, selected)
                if idx and #opts > 7 then sc.CanvasPosition = Vector2.new(0, math.max((idx - 3) * 30, 0)) end
            end)
        end)
    end)
    function api:Get() return selected end
    function api:Set(v, silent) if table.find(opts, v) then choose(v, silent) end end
    function api:SetSilent(v) if table.find(opts, v) then choose(v, true) end end
    function api:Refresh(list)
        opts = list
        if not table.find(opts, selected) then selected = opts[1] end
        vl.Text = tostring(selected or "-")
    end
    api.Export = function() return selected end
    api.Import = function(v) api:Set(v) end
    return register(o, api)
end

local function buildKeybind(host, o, W, compact)
    local edge = compact and 0 or 12
    local state, bind = false, nil
    rowLabel(host, o.Name, o.Desc, edge + 170, compact)
    tipFor(host, o, W, compact)
    bind = { Key = o.Default, Mode = o.Mode or "Press", Name = o.Name or "Keybind", NoHud = o.HUD == false, Flash = 0,
        Active = function()
            if bind.Mode == "Press" then return os.clock() < bind.Flash end
            return state
        end,
        Press = function(down)
            if bind.Mode == "Press" then if down then bind.Flash = os.clock() + 0.3 fire(o.Callback) end
            elseif bind.Mode == "Toggle" then if down then state = not state fire(o.Callback, state) end
            else state = down fire(o.Callback, down) end
        end }
    table.insert(W.Binds, bind)
    local modeL = label(host, string.upper(bind.Mode), UDim2.new(1, -(edge + 150), 0, 0), UDim2.new(0, 50, 1, 0), Enum.Font.GothamBold, 9, "@Sub", RIGHT)
    local pillB = new("TextButton", { Parent = host, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -edge, 0.5, 0), Size = UDim2.fromOffset(92, 26),
        BackgroundColor3 = "@Card2", Text = keyName(bind.Key), TextColor3 = "@Text", Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false,
        ZIndex = 3, BorderSizePixel = 0 }, { corner(8) })
    pillB.MouseButton1Click:Connect(function()
        pillB.Text = "..."
        W.Listening = function(k)
            if k == Enum.KeyCode.Backspace or k == Enum.KeyCode.Delete then bind.Key = nil
            elseif k ~= Enum.KeyCode.Escape then bind.Key = k end
            pillB.Text = keyName(bind.Key)
            fire(o.Changed, bind.Key)
        end
    end)
    local MODES = { "Press", "Toggle", "Hold" }
    pillB.MouseButton2Click:Connect(function()
        bind.Mode = MODES[(table.find(MODES, bind.Mode) or 1) % 3 + 1]
        state = false
        modeL.Text = string.upper(bind.Mode)
    end)
    local api = {}
    function api:Get() return bind.Key end
    function api:GetState() return state end
    api.Export = function() return { Key = keyToTbl(bind.Key), Mode = bind.Mode } end
    api.Import = function(v)
        if type(v) ~= "table" then return end
        bind.Key = tblToKey(v.Key)
        if v.Mode then bind.Mode = v.Mode modeL.Text = string.upper(v.Mode) end
        pillB.Text = keyName(bind.Key)
        fire(o.Changed, bind.Key)
    end
    return register(o, api)
end

local function buildColor(host, o, W, compact)
    local edge = compact and 0 or 14
    local col = o.Default or Color3.new(1, 1, 1)
    rowLabel(host, o.Name, o.Desc, edge + 54, compact)
    tipFor(host, o, W, compact)
    local sw = new("Frame", { Parent = host, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -edge, 0.5, 0), Size = UDim2.fromOffset(40, 22),
        BackgroundColor3 = col, BorderSizePixel = 0 }, { corner(8), stroke("@Line", 1, 0.2) })
    local api = {}
    local function setColor(c, silent)
        col = c
        tween(sw, 0.2, { BackgroundColor3 = c }, SINE)
        if not silent then fire(o.Callback, c) end
    end
    local hit = clickArea(host)
    hit.InputBegan:Connect(function(i) if isPress(i) then ripple(host, i, W) end end)
    hit.MouseButton1Click:Connect(function()
        if W._pop then W:_closePopup() return end
        W:_popup(host, 224, 176, function(frame, pop)
            local h, s, v = col:ToHSV()
            local svBox = new("Frame", { Parent = frame, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(200, 112),
                BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 52 }, { corner(8) })
            new("Frame", { Parent = svBox, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 53 },
                { new("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
            new("Frame", { Parent = svBox, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 54 },
                { new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
            local svKnob = new("Frame", { Parent = svBox, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, ZIndex = 56 },
                { corner(5), stroke(Color3.new(1, 1, 1), 2) })
            local hueBar = new("Frame", { Parent = frame, Position = UDim2.fromOffset(12, 134), Size = UDim2.fromOffset(200, 12), BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0, ZIndex = 52 }, { corner(6), new("UIGradient", { Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, rgb(255, 0, 0)), ColorSequenceKeypoint.new(1 / 6, rgb(255, 255, 0)), ColorSequenceKeypoint.new(2 / 6, rgb(0, 255, 0)),
                    ColorSequenceKeypoint.new(3 / 6, rgb(0, 255, 255)), ColorSequenceKeypoint.new(4 / 6, rgb(0, 0, 255)), ColorSequenceKeypoint.new(5 / 6, rgb(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, rgb(255, 0, 0)) }) }) })
            local hueKnob = new("Frame", { Parent = hueBar, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 16), BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0, ZIndex = 53 }, { corner(3), stroke(Color3.new(0, 0, 0), 1, 0.4) })
            local hex = label(frame, "", UDim2.fromOffset(12, 152), UDim2.fromOffset(200, 16), Enum.Font.GothamBold, 11, "@Sub", nil, { ZIndex = 52 })
            local function setHex(c)
                local r, g, b = c255(c)
                hex.Text = string.format("#%02X%02X%02X", r, g, b)
            end
            local function refresh()
                local c = Color3.fromHSV(h, s, v)
                svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                svKnob.Position = UDim2.fromScale(s, 1 - v)
                hueKnob.Position = UDim2.fromScale(h, 0.5)
                setHex(c)
                col = c
                sw.BackgroundColor3 = c
                fire(o.Callback, c)
            end
            svKnob.Position = UDim2.fromScale(s, 1 - v)
            hueKnob.Position = UDim2.fromScale(h, 0.5)
            setHex(col)
            local active
            local function bindDrag(area, fn)
                area.InputBegan:Connect(function(i) if isPress(i) then active = fn fn(i.Position) end end)
            end
            bindDrag(svBox, function(p)
                s = math.clamp((p.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
                v = 1 - math.clamp((p.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
                refresh()
            end)
            bindDrag(hueBar, function(p)
                h = math.clamp((p.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 0.999)
                refresh()
            end)
            table.insert(pop.conns, UIS.InputChanged:Connect(function(i) if active and isMove(i) then active(i.Position) end end))
            table.insert(pop.conns, UIS.InputEnded:Connect(function(i) if active and isPress(i) then active = nil end end))
        end)
    end)
    function api:Get() return col end
    function api:Set(c, silent) setColor(c, silent) end
    api.SetSilent = function(_, c) setColor(c, true) end
    api.Export = function() local r, g, b = c255(col) return { r, g, b } end
    api.Import = function(v) if type(v) == "table" and #v == 3 then setColor(rgb(v[1], v[2], v[3])) end end
    return register(o, api)
end

local function buildTextbox(host, o, W, compact)
    local edge = compact and 0 or 10
    label(host, o.Name or "Textbox", UDim2.fromOffset(compact and 0 or 14, 0), UDim2.new(1, -(edge + 200), 1, 0), Enum.Font.GothamMedium, 12, compact and "@Sub" or "@Text")
    tipFor(host, o, W, compact)
    local back = new("Frame", { Parent = host, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -edge, 0.5, 0), Size = UDim2.fromOffset(160, 28),
        BackgroundColor3 = "@Content", BorderSizePixel = 0 }, { corner(9) })
    local bs = stroke("@Line", 1.2, 0.2)
    bs.Parent = back
    local box = new("TextBox", { Parent = back, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), BackgroundTransparency = 1,
        PlaceholderText = o.Placeholder or "", PlaceholderColor3 = "@Sub", Text = o.Default or "", TextColor3 = "@Text",
        Font = Enum.Font.GothamMedium, TextSize = 11, ClearTextOnFocus = false, TextXAlignment = LEFT })
    box.Focused:Connect(function()
        tween(bs, 0.25, { Color = Theme.Accent }, SINE)
        tween(back, 0.35, { Size = UDim2.fromOffset(190, 28) }, BACK)
    end)
    box.FocusLost:Connect(function(enter)
        tween(bs, 0.3, { Color = Theme.Line }, SINE)
        tween(back, 0.35, { Size = UDim2.fromOffset(160, 28) }, QUINT)
        fire(o.Callback, box.Text, enter)
    end)
    local api = {}
    function api:Get() return box.Text end
    function api:Set(t) box.Text = t end
    api.Export = function() return box.Text end
    api.Import = function(v) if type(v) == "string" then box.Text = v fire(o.Callback, v, false) end end
    return register(o, api)
end

local function buildButton(host, o, W, compact)
    local edge = compact and 0 or 12
    rowLabel(host, o.Name, o.Desc, edge + 90, compact)
    tipFor(host, o, W, compact)
    local p = new("Frame", { Parent = host, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -edge, 0.5, 0), Size = UDim2.fromOffset(74, 26),
        BackgroundColor3 = "@Accent", BorderSizePixel = 0 }, { corner(9) })
    new("UIGradient", { Parent = p, Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 190)),
        Transparency = NumberSequence.new(0.88, 0.7) })
    new("TextLabel", { Parent = p, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = o.ButtonText or "RUN",
        Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.new(1, 1, 1), AutoLocalize = false })
    local sc = new("UIScale", { Parent = p })
    local hit = clickArea(host)
    hit.InputBegan:Connect(function(i)
        if isPress(i) then tween(sc, 0.12, { Scale = 0.88 }, QUINT) ripple(host, i, W) end
    end)
    hit.InputEnded:Connect(function(i) if isPress(i) then tween(sc, 0.45, { Scale = 1 }, BACK) end end)
    hit.MouseButton1Click:Connect(function() fire(o.Callback) end)
    return { Frame = host }
end

-- сетка вариантов ("Marker style" на скрине). Поддерживает Multi = true
local function buildGrid(parent, o, W, order)
    local multi = o.Multi == true
    local cols = o.Columns or 2
    local sel = {}
    if multi then for _, v in ipairs(o.Default or {}) do sel[v] = true end
    else sel[o.Default or (o.Options or {})[1]] = true end
    local sect = new("Frame", { Parent = parent, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
    label(sect, o.Name or "Choose", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 16), Enum.Font.GothamMedium, 12, "@Sub")
    if o.Tooltip or o.Desc then W:_tip(sect, o.Tooltip or o.Desc) end
    local gap = 8
    local grid = new("Frame", { Parent = sect, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 },
        { new("UIGridLayout", { CellSize = UDim2.new(1 / cols, -(gap * (cols - 1) / cols), 0, 32), CellPadding = UDim2.fromOffset(gap, gap), SortOrder = Enum.SortOrder.LayoutOrder }),
          new("UIPadding", { PaddingBottom = UDim.new(0, 2) }) })
    local buttons = {}
    local function paintAll(anim)
        for name, b in pairs(buttons) do
            local on = sel[name] == true
            tween(b, anim and 0.25 or 0.01, { BackgroundColor3 = on and Theme.Card2 or Theme.Content, TextColor3 = on and Theme.Text or Theme.Sub }, SINE)
        end
    end
    local function list()
        local out = {}
        for _, name in ipairs(o.Options or {}) do if sel[name] then table.insert(out, name) end end
        return out
    end
    for i, opt in ipairs(o.Options or {}) do
        local b = new("TextButton", { Parent = grid, LayoutOrder = i, BackgroundColor3 = "@Content", Text = tostring(opt), TextColor3 = "@Sub",
            Font = Enum.Font.GothamMedium, TextSize = 12, AutoButtonColor = false, BorderSizePixel = 0, ClipsDescendants = true }, { corner(9) })
        buttons[opt] = b
        b.InputBegan:Connect(function(inp) if isPress(inp) then ripple(b, inp, W) end end)
        b.MouseButton1Click:Connect(function()
            if multi then sel[opt] = not sel[opt] or nil
            else sel = { [opt] = true } end
            paintAll(true)
            fire(o.Callback, multi and list() or opt)
        end)
    end
    paintAll(false)
    onTheme(function() paintAll(false) end)
    local api = { Frame = sect }
    function api:Get() return multi and list() or (list()[1]) end
    function api:Set(v, silent)
        if multi then sel = {} for _, n in ipairs(v or {}) do sel[n] = true end
        else if not buttons[v] then return end sel = { [v] = true } end
        paintAll(true)
        if not silent then fire(o.Callback, multi and list() or v) end
    end
    api.Export = function() return multi and list() or list()[1] end
    api.Import = function(v) api:Set(v) end
    return register(o, api)
end

------------------------------------------------------------------
-- TAB API
------------------------------------------------------------------
function Tab:AddSection(name)
    self.Order += 1
    self._row = nil
    local f = new("Frame", { Parent = self.Page, LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 })
    label(f, string.upper(name), UDim2.fromOffset(4, 4), UDim2.new(1, 0, 0, 14), Enum.Font.GothamBold, 10, "@Accent")
    table.insert(self.Sections, f)
    return f
end
function Tab:AddLabel(text, h)
    self.Order += 1
    self._row = nil
    local f = new("Frame", { Parent = self.Page, LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, h or 30), BackgroundTransparency = 1 })
    local l = label(f, text, UDim2.fromOffset(4, 0), UDim2.new(1, -4, 1, 0), Enum.Font.Gotham, 11, "@Sub", nil,
        { TextWrapped = true, TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top })
    table.insert(self.Sections, f)
    return l
end
function Tab:AddCustom(h)
    self.Order += 1
    self._row = nil
    return new("Frame", { Parent = self.Page, LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1 })
end

function Tab:AddButton(o)
    local card = self:_card(o.Desc and 54 or 44, o, (o.Name or "") .. " " .. (o.Desc or ""))
    return buildButton(card, o, self.Window, false)
end
function Tab:AddToggle(o)
    local card = self:_card(o.Desc and 54 or 44, o, (o.Name or "") .. " " .. (o.Desc or ""))
    return buildToggle(card, o, self.Window, false)
end
function Tab:AddSlider(o)
    local card = self:_card(58, o, o.Name)
    return buildSlider(card, o, self.Window, false)
end
function Tab:AddDropdown(o)
    local card = self:_card(44, o, (o.Name or "") .. " " .. table.concat(o.Options or {}, " "))
    return buildDropdown(card, o, self.Window, false)
end
function Tab:AddTextbox(o)
    local card = self:_card(44, o, o.Name)
    return buildTextbox(card, o, self.Window, false)
end
function Tab:AddKeybind(o)
    local card = self:_card(o.Desc and 54 or 44, o, (o.Name or "") .. " " .. (o.Desc or ""))
    return buildKeybind(card, o, self.Window, false)
end
function Tab:AddColorPicker(o)
    local card = self:_card(o.Desc and 54 or 44, o, (o.Name or "") .. " " .. (o.Desc or ""))
    return buildColor(card, o, self.Window, false)
end

function Tab:AddModule(o)
    o = o or {}
    local W = self.Window
    local HEAD, TOPH = 46, 28
    local expanded = o.Expanded == true
    local hasTop = o.Enabled ~= nil
    local card, entry = self:_card(HEAD, o, (o.Name or "") .. " " .. (o.Desc or ""))

    local head = new("TextButton", { Parent = card, Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2 })

    local tx = 14
    local ic, paintIc
    if o.Icon then
        ic, paintIc = icon(card, o.Icon, UDim2.fromOffset(14, 13), UDim2.fromOffset(20, 20), "@Text", 3)
        tx = 46
    end
    local name = o.Name or "Module"
    label(card, name, UDim2.fromOffset(tx, 0), UDim2.new(1, -(tx + 50), 0, HEAD), Enum.Font.GothamBold, 14, "@Text", nil, { ZIndex = 3 })
    local tipText = o.Info or o.Desc
    if tipText then
        local w = textW(name, 14, Enum.Font.GothamBold)
        local info = new("Frame", { Parent = card, Position = UDim2.fromOffset(tx + w + 8, HEAD / 2 - 7), Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1, ZIndex = 3 }, { corner(7), stroke("@Sub", 1.2, 0.35) })
        label(info, "i", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.Font.GothamBold, 9, "@Sub", CENTER, { ZIndex = 4 })
        W:_tip(info, tipText)
    end
 
    local glyph = new("Frame", { Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0, HEAD / 2), Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1, ZIndex = 3 })
    new("Frame", { Parent = glyph, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 2),
        BackgroundColor3 = "@Sub", BorderSizePixel = 0, ZIndex = 4 }, { corner(1) })
    local vbar = new("Frame", { Parent = glyph, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(2, expanded and 0 or 12),
        BackgroundColor3 = "@Sub", BorderSizePixel = 0, ZIndex = 4 }, { corner(1) })

    local bl = new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
    local body = new("Frame", { Parent = card, Position = UDim2.fromOffset(0, HEAD), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1 }, { bl, new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }) })
    local extraLayout = new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
    local extra = new("Frame", { Parent = body, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 },
        { extraLayout })

    local function target(exp)
        if exp then return HEAD + bl.AbsoluteContentSize.Y + 14 end
        return HEAD + (hasTop and (TOPH + 14) or 0)
    end
    local animating = false
    local function setExpanded(v, anim)
        expanded = v
        animating = true
        local tw = tween(card, anim and D(W, 0.45) or 0.01, { Size = UDim2.new(card.Size.X.Scale, card.Size.X.Offset, 0, target(v)) }, QUINT)
        tween(vbar, anim and 0.3 or 0.01, { Size = UDim2.fromOffset(2, v and 0 or 12) }, QUINT)
        tween(glyph, anim and 0.4 or 0.01, { Rotation = v and 180 or 0 }, BACK)
        tw.Completed:Connect(function() animating = false end)
    end
    bl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if expanded and not animating then
            card.Size = UDim2.new(card.Size.X.Scale, card.Size.X.Offset, 0, target(true))
        end
    end)
    head.MouseButton1Click:Connect(function() setExpanded(not expanded, true) end)
    card.Size = UDim2.new(card.Size.X.Scale, card.Size.X.Offset, 0, target(false))
    if expanded then task.defer(function() setExpanded(true, false) end) end

    local m = setmetatable({ Card = card, Extra = extra, Window = W, Tab = self, _n = 0, _entry = entry, SetExpanded = function(_, v) setExpanded(v, true) end }, Module)

    if hasTop then
        local r = new("Frame", { Parent = body, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, TOPH), BackgroundTransparency = 1, ClipsDescendants = true })
        local enabled = o.Enabled == true
        m.Toggle = buildToggle(r, {
            Name = o.EnabledText or "Enabled", Default = o.Enabled, Keybind = o.Keybind, Flag = o.Flag, HUD = o.HUD, Tooltip = o.EnabledTip,
            Callback = function(v)
                enabled = v
                if paintIc then paintIc(v and Theme.Accent or Theme.Text) end
                fire(o.Callback, v)
            end,
        }, W, true)
        if o.Keybind and m.Toggle then
            -- название бинда в HUD = название модуля
            for _, b in ipairs(W.Binds) do if b.Active and b.Name == (o.EnabledText or "Enabled") and not b.Renamed then b.Name = name b.Renamed = true end end
        end
        if paintIc then
            if enabled then paintIc(Theme.Accent) end
            onTheme(function() paintIc(enabled and Theme.Accent or Theme.Text) end)
        end
    end
    return m
end

function Module:_row(h, name)
    self._n += 1
    local r = new("Frame", { Parent = self.Extra, LayoutOrder = self._n, Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, ClipsDescendants = true })
    self._entry.text = self._entry.text .. " " .. tostring(name or ""):lower()
    return r
end
function Module:AddToggle(o) return buildToggle(self:_row(28, o.Name), o, self.Window, true) end
function Module:AddSlider(o) return buildSlider(self:_row(42, o.Name), o, self.Window, true) end
function Module:AddDropdown(o) return buildDropdown(self:_row(30, (o.Name or "") .. " " .. table.concat(o.Options or {}, " ")), o, self.Window, true) end
function Module:AddKeybind(o) return buildKeybind(self:_row(30, o.Name), o, self.Window, true) end
function Module:AddColor(o) return buildColor(self:_row(28, o.Name), o, self.Window, true) end
Module.AddColorPicker = Module.AddColor
function Module:AddTextbox(o) return buildTextbox(self:_row(32, o.Name), o, self.Window, true) end
function Module:AddButton(o) return buildButton(self:_row(30, o.Name), o, self.Window, true) end
function Module:AddGrid(o)
    self._n += 1
    self._entry.text = self._entry.text .. " " .. (o.Name or ""):lower() .. " " .. table.concat(o.Options or {}, " "):lower()
    return buildGrid(self.Extra, o, self.Window, self._n)
end
function Module:AddLabel(text)
    self._n += 1
    return label(self.Extra, text, UDim2.new(), UDim2.new(1, 0, 0, 0), Enum.Font.Gotham, 11, "@Sub", nil,
        { LayoutOrder = self._n, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, AutomaticSize = Enum.AutomaticSize.Y })
end
function Module:AddSeparator()
    self._n += 1
    return new("Frame", { Parent = self.Extra, LayoutOrder = self._n, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = "@Line", BackgroundTransparency = 0.5, BorderSizePixel = 0 })
end

function Tab:AddExpandableCard(title, isExpanded, elements)
    local top
    for _, el in ipairs(elements or {}) do
        if el.Type == "Toggle" and el.AlwaysVisible then top = el break end
    end
    local m = self:AddModule({ Name = title, Expanded = isExpanded, Enabled = top and top.Default or nil, EnabledText = top and top.Text, Callback = top and top.Callback })
    for _, el in ipairs(elements or {}) do
        if el ~= top then
            if el.Type == "Toggle" then m:AddToggle({ Name = el.Text, Default = el.Default, Callback = el.Callback })
            elseif el.Type == "Grid" then m:AddGrid({ Name = el.Text, Options = el.Options, Default = el.Default, Callback = el.Callback }) end
        end
    end
    return m
end

function Tab:AddActiveBinds(title, binds)
    local card = self:_card(0, {}, title)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Size = UDim2.new(1, 0, 0, 0)
    local header = new("Frame", { Parent = card, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 })
    label(header, title, UDim2.fromOffset(14, 0), UDim2.new(1, -50, 1, 0), Enum.Font.GothamBold, 14, "@Text")
    icon(header, "keyboard", UDim2.new(1, -34, 0.5, -9), UDim2.fromOffset(18, 18), "@Sub", 2)
    local list = new("Frame", { Parent = card, Position = UDim2.fromOffset(10, 44), Size = UDim2.new(1, -20, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 },
        { new("UIListLayout", { Padding = UDim.new(0, 4) }), new("UIPadding", { PaddingBottom = UDim.new(0, 12) }) })
    for _, b in ipairs(binds) do
        local row = new("Frame", { Parent = list, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = "@Content", BorderSizePixel = 0 }, { corner(9) })
        label(row, b.Name, UDim2.fromOffset(12, 0), UDim2.new(1, -60, 1, 0), Enum.Font.GothamMedium, 12, "@Text")
        local kb = new("Frame", { Parent = row, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(28, 22), BackgroundColor3 = "@Card2", BorderSizePixel = 0 }, { corner(6) })
        label(kb, b.Key, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.Font.GothamBold, 11, "@Text", CENTER)
    end
    return card
end

function Tab:AddThemeCards(o)
    o = o or {}
    local W = self.Window
    local list = o.Themes or ThemeList
    self.Order += 1
    self._row = nil
    local grid = new("Frame", { Parent = self.Page, LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 },
        { new("UIGridLayout", { CellSize = UDim2.new(1 / 3, -7, 0, 98), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
    table.insert(W.Items, { frame = grid, text = "theme dark light " .. table.concat(list, " "):lower(), tab = self })
    local strokes = {}
    local function mark(silent)
        for key, s in pairs(strokes) do
            local on = key == Lib.ThemeName
            tween(s, silent and 0.01 or 0.35, { Color = on and Theme.Accent or Theme.Line, Thickness = on and 1.8 or 1, Transparency = on and 0 or 0.35 }, SINE)
        end
    end
    for i, key in ipairs(list) do
        local t = Themes[key]
        local fam, mode = key:match("^(%S+)%s+(%S+)$")
        local c = new("TextButton", { Parent = grid, LayoutOrder = i, Text = "", AutoButtonColor = false, BackgroundColor3 = "@Card", BorderSizePixel = 0 }, { corner(14) })
        local sc = new("UIScale", { Parent = c })
        local s = stroke(Theme.Line, 1, 0.35)
        s.Parent = c
        strokes[key] = s
        local pv = new("Frame", { Parent = c, Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 0, 34), BackgroundColor3 = t.Panel, BorderSizePixel = 0 }, { corner(9) })
        new("Frame", { Parent = pv, Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(24, 22), BackgroundColor3 = t.Card2, BorderSizePixel = 0 }, { corner(6) })
        local bar = new("Frame", { Parent = pv, Position = UDim2.fromOffset(36, 6), Size = UDim2.new(1, -42, 0, 22), BackgroundColor3 = t.Content, BorderSizePixel = 0 }, { corner(6) })
        new("Frame", { Parent = bar, Position = UDim2.fromOffset(8, 6), Size = UDim2.new(0.35, 0, 0, 3), BackgroundColor3 = t.Accent, BorderSizePixel = 0 }, { corner(2) })
        new("Frame", { Parent = bar, Position = UDim2.fromOffset(8, 13), Size = UDim2.new(0.75, 0, 0, 2), BackgroundColor3 = t.Sub, BorderSizePixel = 0 }, { corner(1) })
        label(c, fam, UDim2.fromOffset(12, 54), UDim2.new(1, -24, 0, 18), Enum.Font.GothamBold, 13, "@Text")
        label(c, mode, UDim2.fromOffset(12, 74), UDim2.new(1, -24, 0, 14), Enum.Font.Gotham, 10, "@Sub")
        c.MouseEnter:Connect(function() tween(sc, 0.3, { Scale = 1.04 }, BACK) end)
        c.MouseLeave:Connect(function() tween(sc, 0.3, { Scale = 1 }, QUINT) end)
        c.InputBegan:Connect(function(i) if isPress(i) then tween(sc, 0.1, { Scale = 0.96 }, QUINT) end end)
        c.MouseButton1Click:Connect(function()
            tween(sc, 0.4, { Scale = 1.04 }, BACK)
            Lib:SetTheme(key)
            fire(o.Callback, key)
        end)
        table.insert(W.GlassCards, c)
    end
    mark(true)
    onTheme(function() mark(false) end)
    local api = {}
    function api:Get() return Lib.ThemeName end
    function api:Set(key) if Themes[key] then Lib:SetTheme(key) fire(o.Callback, key) end end
    api.Export = function() return Lib.ThemeName end
    api.Import = function(v) api:Set(v) end
    return register(o, api)
end

function Window:AddWatermark(o)
    o = o or {}
    local W = self
    local wm = { Visible = o.Visible ~= false, Items = {}, Title = o.Title or "ECLIPSE", Suffix = o.Suffix or ".cc" }
    local startPos = o.Position or UDim2.fromOffset(20, 20)

    local root = new("CanvasGroup", { Parent = W.Gui, Position = startPos, Size = UDim2.fromOffset(0, 38), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = "@Panel", BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 60 }, { corner(12), stroke("@Line", 1, 0.25) })
    local inner = new("Frame", { Parent = root, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1 },
        { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
          new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 2) }) })
    local line = new("Frame", { Parent = root, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = "@Accent",
        BorderSizePixel = 0, ZIndex = 5 })
    local lineGrad = new("UIGradient", { Parent = line, Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) })

    local order = 0
    local function nextOrder() order += 1 return order end

    local logo = new("Frame", { Parent = inner, LayoutOrder = nextOrder(), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1 })
    local bars = {}
    for i, h in ipairs({ 7, 12, 16 }) do
        bars[i] = { new("Frame", { Parent = logo, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset((i - 1) * 6, 16), Size = UDim2.fromOffset(4, h),
            BackgroundColor3 = "@Accent", BorderSizePixel = 0 }, { corner(2) }), h }
    end
    local titleL = new("TextLabel", { Parent = inner, LayoutOrder = nextOrder(), Size = UDim2.fromOffset(0, 36), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 13, TextColor3 = "@Text", RichText = true, Text = "", AutoLocalize = false })
    local function refreshTitle()
        titleL.Text = string.format('%s<font color="%s">%s</font>', string.upper(wm.Title), richColor(Theme.Accent), wm.Suffix)
    end
    refreshTitle()
    onTheme(refreshTitle)

    local function divider()
        return new("Frame", { Parent = inner, LayoutOrder = nextOrder(), Size = UDim2.fromOffset(1, 16), BackgroundColor3 = "@Line", BorderSizePixel = 0 })
    end

    local function addItem(key, iconName, fn)
        local d = divider()
        local f = new("Frame", { Parent = inner, LayoutOrder = nextOrder(), Size = UDim2.fromOffset(0, 36), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1 },
            { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center }) })
        icon(f, iconName, UDim2.new(), UDim2.fromOffset(14, 14), "@Sub", 2)
        local l = new("TextLabel", { Parent = f, Size = UDim2.fromOffset(0, 36), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = "@Text", Text = "", AutoLocalize = false })
        local it = { Key = key, Fn = fn, Label = l, Frame = f, Divider = d }
        table.insert(wm.Items, it)
        return it
    end

    local fpsVal, pingVal = 60, 0
    local builtin = {
        user = function() return addItem("user", "user", function() return LP.DisplayName end) end,
        fps = function() return addItem("fps", "fps", function() return fpsVal .. " fps" end) end,
        ping = function() return addItem("ping", "ping", function() return pingVal .. " ms" end) end,
        time = function() return addItem("time", "clock", function() return os.date("%H:%M") end) end,
    }
    for _, key in ipairs(o.Items or { "user", "fps", "ping", "time" }) do
        if builtin[key] then builtin[key]() end
    end
    function wm:AddItem(key, iconName, fn) return addItem(key, iconName, fn) end
    function wm:SetTitle(t, suffix) wm.Title = t if suffix then wm.Suffix = suffix end refreshTitle() end
    function wm:SetVisible(v)
        wm.Visible = v and true or false
        if wm.Visible then
            root.Visible = true
            tween(root, D(W, 0.4), { GroupTransparency = 0 }, QUINT)
        else
            tween(root, D(W, 0.25), { GroupTransparency = 1 }, QUINT)
            task.delay(0.27, function() if not wm.Visible then root.Visible = false end end)
        end
    end
    wm.Frame = root
    dragify(W, root, root)

    local acc, frames, textT = 0, 0, 0
    W.keep(RunService.RenderStepped:Connect(function(dt)
        local t = os.clock()
        if wm.Visible then
            for i, b in ipairs(bars) do
                b[1].Size = UDim2.fromOffset(4, b[2] * (0.55 + 0.45 * math.sin(t * 3 + i * 1.2)))
            end
            lineGrad.Offset = Vector2.new(((t * 0.45) % 2) - 1, 0)
        end
        acc += dt
        frames += 1
        textT += dt
        if textT >= 0.4 then
            fpsVal = math.floor(frames / math.max(acc, 1e-3) + 0.5)
            acc, frames, textT = 0, 0, 0
            local ok, p = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
            pingVal = ok and math.floor(p + 0.5) or 0
            for _, it in ipairs(wm.Items) do
                local ok2, txt = pcall(it.Fn)
                it.Label.Text = ok2 and tostring(txt) or "?"
            end
        end
    end))

    root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset - (W.HudMotion and 14 or 0))
    task.defer(function()
        if wm.Visible then
            tween(root, W.HudMotion and 0.6 or 0.01, { GroupTransparency = 0, Position = startPos }, BACK)
        else
            root.Visible = false
        end
    end)
    W.Watermark = wm
    return wm
end

function Window:AddBindsHUD(o)
    o = o or {}
    local W = self
    local hud = { OnlyActive = o.OnlyActive == true, HideEmpty = o.HideEmpty == true, Rows = {}, Visible = o.Visible ~= false }
    local startPos = o.Position or UDim2.new(0, 20, 0.5, -90)

    local panel = new("CanvasGroup", { Parent = W.Gui, Position = startPos, Size = UDim2.fromOffset(o.Width or 250, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "@Panel", BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 55 },
        { corner(18), stroke("@Line", 1, 0.3), new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })
    local header = new("Frame", { Parent = panel, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1 })
    label(header, o.Title or "Active binds", UDim2.fromOffset(16, 0), UDim2.new(1, -60, 1, 2), Enum.Font.GothamBold, 15, "@Text")
    icon(header, "keyboard", UDim2.new(1, -36, 0.5, -9), UDim2.fromOffset(18, 18), "@Sub", 2)
    local list = new("Frame", { Parent = panel, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 },
        { new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
          new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }) })
    dragify(W, header, panel)

    local function makeRow(b)
        local slot = new("Frame", { Parent = list, LayoutOrder = #list:GetChildren(), Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Visible = false })
        local inner = new("CanvasGroup", { Parent = slot, Size = UDim2.fromScale(1, 1), BackgroundColor3 = "@Content", BorderSizePixel = 0, GroupTransparency = 1 },
            { corner(11) })
        local dot = new("Frame", { Parent = inner, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 0),
            BackgroundColor3 = "@Accent", BorderSizePixel = 0 }, { corner(2) })
        local nm = label(inner, b.Name, UDim2.fromOffset(14, 0), UDim2.new(1, -70, 1, 0), Enum.Font.GothamMedium, 12, "@Text")
        local badge = new("Frame", { Parent = inner, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(28, 22),
            BackgroundColor3 = "@Card2", BorderSizePixel = 0 }, { corner(7) })
        local bt = label(badge, "", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.Font.GothamBold, 11, "@Text", CENTER)
        return { slot = slot, inner = inner, dot = dot, name = nm, badge = badge, text = bt, shown = false, active = false, key = nil }
    end
    local function setShown(r, show)
        if r.shown == show then return end
        r.shown = show
        if show then
            r.slot.Visible = true
            r.inner.Position = UDim2.fromOffset(W.HudMotion and -26 or 0, 0)
            tween(r.inner, W.HudMotion and 0.5 or 0.01, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 }, BACK)
        else
            tween(r.inner, W.HudMotion and 0.25 or 0.01, { Position = UDim2.fromOffset(W.HudMotion and 20 or 0, 0), GroupTransparency = 1 }, QUINT)
            task.delay(0.27, function() if not r.shown then r.slot.Visible = false end end)
        end
    end
    local function setActive(r, act)
        if r.active == act then return end
        r.active = act
        tween(r.dot, 0.3, { Size = UDim2.fromOffset(3, act and 18 or 0) }, BACK)
        tween(r.badge, 0.25, { BackgroundColor3 = act and Theme.Accent or Theme.Card2 }, SINE)
        tween(r.text, 0.25, { TextColor3 = act and Color3.new(1, 1, 1) or Theme.Text }, SINE)
    end

    local acc = 0
    W.keep(RunService.Heartbeat:Connect(function(dt)
        acc += dt
        if acc < 0.08 then return end
        acc = 0
        local any = false
        for _, b in ipairs(W.Binds) do
            local r = hud.Rows[b]
            if b.Key and not b.NoHud then
                if not r then r = makeRow(b) hud.Rows[b] = r end
                local ok, act = pcall(function() return b.Active and b.Active() or false end)
                act = ok and act or false
                local show = (not hud.OnlyActive) or act
                if r.name.Text ~= b.Name then r.name.Text = b.Name end
                if r.key ~= b.Key then
                    r.key = b.Key
                    local txt = keyName(b.Key)
                    r.text.Text = txt
                    tween(r.badge, 0.3, { Size = UDim2.fromOffset(math.max(28, textW(txt, 11, Enum.Font.GothamBold) + 16), 22) }, BACK)
                end
                setShown(r, show and hud.Visible)
                setActive(r, act)
                any = any or show
            elseif r then
                setShown(r, false)
            end
        end
        local want = hud.Visible and (any or not hud.HideEmpty)
        if want ~= panel.Visible then
            panel.Visible = want
            if want then tween(panel, 0.4, { GroupTransparency = 0 }, QUINT) end
        end
    end))

    function hud:SetVisible(v)
        hud.Visible = v and true or false
        if hud.Visible then
            panel.Visible = true
            tween(panel, D(W, 0.4), { GroupTransparency = 0 }, QUINT)
        else
            tween(panel, D(W, 0.25), { GroupTransparency = 1 }, QUINT)
            task.delay(0.27, function() if not hud.Visible then panel.Visible = false end end)
        end
    end
    function hud:SetOnlyActive(v) hud.OnlyActive = v and true or false end
    hud.Frame = panel

    panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset - (W.HudMotion and 24 or 0), startPos.Y.Scale, startPos.Y.Offset)
    task.defer(function()
        if hud.Visible then
            tween(panel, W.HudMotion and 0.65 or 0.01, { GroupTransparency = 0, Position = startPos }, BACK)
        else
            panel.Visible = false
        end
    end)
    W.BindsHUD = hud
    return hud
end

function Window:ExportString()
    local data = {}
    for f, a in pairs(Lib.Flags) do
        if type(a) == "table" and a.Export then
            local ok, v = pcall(a.Export)
            if ok and v ~= nil then data[f] = v end
        end
    end
    return HttpService:JSONEncode(data)
end
function Window:ImportString(s)
    local ok, data = pcall(function() return HttpService:JSONDecode(s) end)
    if not ok or type(data) ~= "table" then return false end
    local keys = {}
    for f in pairs(data) do table.insert(keys, f) end
    table.sort(keys, function(a, b)
        if a == "Theme" then return b ~= "Theme" end
        if b == "Theme" then return false end
        return a < b
    end)
    for _, f in ipairs(keys) do
        local a = Lib.Flags[f]
        if a and a.Import then pcall(a.Import, data[f]) end
    end
    return true
end
local function cfgPath(self, name) return self.Folder .. "/" .. (tostring(name):gsub("[^%w_%- ]", "")) .. ".json" end
function Window:SaveConfig(name)
    if not writefile then return false end
    pcall(function() if makefolder and isfolder and not isfolder(self.Folder) then makefolder(self.Folder) end end)
    return (pcall(writefile, cfgPath(self, name), self:ExportString()))
end
function Window:LoadConfig(name)
    if not (readfile and isfile) then return false end
    local path = cfgPath(self, name)
    if not isfile(path) then return false end
    local ok, s = pcall(readfile, path)
    return ok and self:ImportString(s)
end
function Window:DeleteConfig(name)
    local path = cfgPath(self, name)
    if not (delfile and isfile and isfile(path)) then return false end
    return (pcall(delfile, path))
end
function Window:ListConfigs()
    local out = {}
    if listfiles and isfolder and isfolder(self.Folder) then
        local ok, files = pcall(listfiles, self.Folder)
        if ok then
            for _, f in ipairs(files) do
                local n = tostring(f):match("([^/\\]+)%.json$")
                if n then table.insert(out, n) end
            end
        end
    end
    table.sort(out)
    if #out == 0 then out = { "default" } end
    return out
end

function Window:BuildConfigs(tab)
    local W = self
    local name = "default"
    tab:AddSection("Configs")
    local box, dd
    box = tab:AddTextbox({ Name = "Config name", Placeholder = "default", Default = "default",
        Callback = function(t) if t and t ~= "" then name = t end end })
    dd = tab:AddDropdown({ Name = "Saved configs", Options = W:ListConfigs(),
        Callback = function(v) name = v box:Set(v) end })
    tab:AddButton({ Name = "Save config", Desc = "Сохранить текущие настройки", ButtonText = "SAVE", Callback = function()
        if W:SaveConfig(name) then
            dd:Refresh(W:ListConfigs()) dd:Set(name, true)
            W:Notify("Config", "Saved: " .. name, 3, "success")
        else W:Notify("Config", "Не удалось сохранить", 3, "error") end
    end })
    tab:AddButton({ Name = "Load config", Desc = "Загрузить выбранный конфиг", ButtonText = "LOAD", Callback = function()
        if W:LoadConfig(name) then W:Notify("Config", "Loaded: " .. name, 3, "success")
        else W:Notify("Config", "Конфиг не найден", 3, "error") end
    end })
    tab:AddButton({ Name = "Delete config", ButtonText = "DELETE", Callback = function()
        if W:DeleteConfig(name) then
            dd:Refresh(W:ListConfigs())
            W:Notify("Config", "Deleted: " .. name, 3, "warn")
        else W:Notify("Config", "Нечего удалять", 3, "error") end
    end })
    tab:AddSection("Share")
    tab:AddButton({ Name = "Copy config to clipboard", ButtonText = "COPY", Callback = function()
        if setclipboard then setclipboard(W:ExportString()) W:Notify("Config", "Скопировано", 2.5, "success")
        else W:Notify("Config", "setclipboard недоступен", 3, "error") end
    end })
    tab:AddTextbox({ Name = "Import string", Placeholder = "paste + Enter", Callback = function(t, enter)
        if enter and t ~= "" then
            if W:ImportString(t) then W:Notify("Config", "Imported", 3, "success") else W:Notify("Config", "Неверная строка", 3, "error") end
        end
    end })
end

function Window:BuildAppearance(tab)
    local W = self
    tab:AddThemeCards({ Flag = "Theme" })
    tab:AddSlider({ Name = "Interface glow", Min = 0, Max = 100, Default = math.floor(W.Glow * 100), Suffix = "%", Half = true, Flag = "Glow",
        Callback = function(v) W:SetGlow(v) end })
    tab:AddSlider({ Name = "Glass blur strength", Min = 0, Max = 100, Default = 100, Suffix = "%", Half = true, Flag = "GlassBlur",
        Callback = function(v) W:SetGlassBlur(v * 0.4) end })
    tab:AddToggle({ Name = "HUD entrance motion", Default = true, Half = true, Flag = "HudMotion", Callback = function(v) W:SetHudMotion(v) end })
    tab:AddToggle({ Name = "Menu motion", Default = true, Half = true, Flag = "MenuMotion", Callback = function(v) W:SetMotion(v) end })
    tab:AddToggle({ Name = "World blur", Default = false, Half = true, Flag = "WorldBlur", Callback = function(v) W:SetWorldBlur(v) end })
    tab:AddDropdown({ Name = "Opening effect", Options = { "Pop", "Fade", "Slide", "Sound wave" }, Default = W.Effect, Half = true, Flag = "OpenEffect",
        Callback = function(v) W:SetEffect(v) end })
    tab:AddToggle({ Name = "Watermark", Default = true, Half = true, Flag = "ShowWatermark",
        Callback = function(v) if W.Watermark then W.Watermark:SetVisible(v) end end })
    tab:AddToggle({ Name = "Active binds HUD", Default = true, Half = true, Flag = "ShowBindsHUD",
        Callback = function(v) if W.BindsHUD then W.BindsHUD:SetVisible(v) end end })
    tab:AddSlider({ Name = "Menu scale", Min = 60, Max = 130, Default = 100, Suffix = "%", Half = true, Flag = "MenuScale",
        Callback = function(v) W:SetScale(v / 100) end })
    tab:AddKeybind({ Name = "Menu key", Default = W.Key, Half = true, HUD = false, Flag = "MenuKey", Mode = "Press",
        Changed = function(k) if k then W:SetKey(k) end end })
end

return Lib