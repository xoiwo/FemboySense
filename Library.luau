
local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local UIS           = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local HttpService   = game:GetService("HttpService")
local Lighting      = game:GetService("Lighting")
local Workspace     = game:GetService("Workspace")

local LP = Players.LocalPlayer
local SINE, QUINT, BACK = Enum.EasingStyle.Sine, Enum.EasingStyle.Quint, Enum.EasingStyle.Back
local OUT, IN = Enum.EasingDirection.Out, Enum.EasingDirection.In

local Lib  = { Flags = {}, ThemeName = "Lavender Dark", Windows = {} }
local Window, Tab, Mod = {}, {}, {}
Window.__index, Tab.__index, Mod.__index = Window, Tab, Mod

--// ------------------------------------------------------------------ THEMES
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local function palette(accent, dark)
    if dark then
        return {
            Dark = true, Accent = accent,
            Outer   = rgb(15, 15, 17),
            Panel   = rgb(22, 22, 25),
            Content = rgb(18, 18, 20),
            Card    = rgb(28, 28, 31),
            Card2   = rgb(40, 40, 45),
            Text    = rgb(242, 242, 245),
            Sub     = rgb(140, 140, 152),
            Line    = rgb(48, 48, 54),
            Off     = rgb(46, 46, 52),
            Knob    = rgb(255, 255, 255),
            Bg      = rgb(10, 10, 12),
        }
    end
    return {
        Dark = false, Accent = accent,
        Outer   = rgb(216, 216, 222),
        Panel   = rgb(238, 238, 244),
        Content = rgb(248, 248, 250),
        Card    = rgb(255, 255, 255),
        Card2   = rgb(232, 232, 238),
        Text    = rgb(22, 22, 26),
        Sub     = rgb(112, 112, 124),
        Line    = rgb(210, 210, 220),
        Off     = rgb(200, 200, 208),
        Knob    = rgb(255, 255, 255),
        Bg      = rgb(246, 246, 250),
    }
end

local FAMILIES = {
    { "Lavender", rgb(184, 160, 237) },
    { "Midnight", rgb(145, 175, 229) },
    { "Rose",     rgb(229, 165, 188) },
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

--// ------------------------------------------------------------------ HELPERS
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
            local key = v:sub(2)
            o[k] = Theme[key]
            table.insert(themed, { o, k, key })
        else
            o[k] = v
        end
    end
    for _, c in ipairs(children or {}) do c.Parent = o end
    if parent then o.Parent = parent end
    return o
end

local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function stroke(color, th, tr)
    return new("UIStroke", { Color = color, Thickness = th or 1, Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function label(parent, text, pos, size, font, ts, color, align, extra)
    local l = new("TextLabel", {
        Parent = parent, Text = text, Position = pos, Size = size, BackgroundTransparency = 1,
        Font = font or Enum.Font.Gotham, TextSize = ts or 12, TextColor3 = color or "@Text",
        TextXAlignment = align or Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    for k, v in pairs(extra or {}) do l[k] = v end
    return l
end

local function onTheme(fn) table.insert(hooks, fn) end

local function isPress(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

local function fire(cb, ...)
    if not cb then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(cb, table.unpack(args, 1, args.n))
        if not ok then warn("[Eclipse] " .. tostring(err)) end
    end)
end

local function hoverColor() return Theme.Card:Lerp(Theme.Card2, 0.6) end

local KEYSHORT = { LeftControl = "LCtrl", RightControl = "RCtrl", LeftShift = "LShift", RightShift = "RShift",
    LeftAlt = "LAlt", RightAlt = "RAlt", Return = "Enter", Backspace = "Bksp", Escape = "Esc", Space = "SPC" }
local function keyName(k) if not k then return "NONE" end return (KEYSHORT[k.Name] or k.Name):upper() end

--// ------------------------------------------------------------------ ICONS
-- Draw simple Lucide-like icons with frames. Kind can be a string, number (asset id), or URL.
local ICON_NAMES = {
    grid="grid", combat="combat", eye="eye", cloud="cloud",
    monitor="monitor", keyboard="keyboard", sparkle="sparkle", palette="palette",
    swords="combat", visuals="eye", world="cloud", interface="monitor",
    utility="keyboard", cosmetics="sparkle", appearance="palette", all="grid",
}

local function drawIcon(parent, kind, sz, color, yOff)
    local holder = new("Frame", {
        Parent = parent, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, yOff or 0),
        Size = UDim2.fromOffset(sz, sz), BackgroundTransparency = 1,
    })
    kind = ICON_NAMES[kind] or kind
    if kind == "grid" then
        local s = sz/2 - 1
        for i = 0, 1 do for j = 0, 1 do
            new("Frame", {
                Parent = holder, Position = UDim2.fromOffset(j*(s+2), i*(s+2)),
                Size = UDim2.fromOffset(s, s), BackgroundTransparency = 1,
            }, { corner(2), stroke(color, 1.6) })
        end end
    elseif kind == "combat" then
        new("Frame", { Parent = holder, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
            Size = UDim2.fromOffset(sz*0.9, 1.5), BackgroundColor3 = color, Rotation = 45, BorderSizePixel = 0 }, { corner(1) })
        new("Frame", { Parent = holder, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
            Size = UDim2.fromOffset(sz*0.9, 1.5), BackgroundColor3 = color, Rotation = -45, BorderSizePixel = 0 }, { corner(1) })
    elseif kind == "eye" then
        new("Frame", { Parent = holder, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
            Size = UDim2.fromOffset(sz, sz*0.65), BackgroundTransparency = 1 }, { corner(sz/2), stroke(color, 1.6) })
        new("Frame", { Parent = holder, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
            Size = UDim2.fromOffset(sz*0.3, sz*0.3), BackgroundColor3 = color, BorderSizePixel = 0 }, { corner(sz*0.15) })
    elseif kind == "cloud" then
        new("Frame", { Parent = holder, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.35),
            Size = UDim2.fromOffset(sz*0.75, sz*0.45), BackgroundColor3 = color, BorderSizePixel = 0 }, { corner(sz*0.3) })
        new("Frame", { Parent = holder, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.3,0.6),
            Size = UDim2.fromOffset(sz*0.45, sz*0.4), BackgroundColor3 = color, BorderSizePixel = 0 }, { corner(sz*0.2) })
    elseif kind == "monitor" then
        new("Frame", { Parent = holder, Position = UDim2.fromOffset(0, sz*0.12), Size = UDim2.fromOffset(sz, sz*0.6),
            BackgroundTransparency = 1 }, { corner(2), stroke(color, 1.6) })
        new("Frame", { Parent = holder, AnchorPoint = Vector2.new(0.5,0), Position = UDim2.new(0.5, 0, 0, sz*0.78),
            Size = UDim2.fromOffset(sz*0.6, 1.5), BackgroundColor3 = color, BorderSizePixel = 0 }, { corner(1) })
    elseif kind == "keyboard" then
        local base = new("Frame", { Parent = holder, Position = UDim2.fromOffset(0, sz*0.22), Size = UDim2.fromOffset(sz, sz*0.56),
            BackgroundTransparency = 1 }, { corner(2), stroke(color, 1.6) })
        for i = 0, 3 do
            new("Frame", { Parent = base, Position = UDim2.fromOffset(2 + i*((sz-4)/4), sz*0.15),
                Size = UDim2.fromOffset((sz-4)/4 - 2, 1.5), BackgroundColor3 = color, BorderSizePixel = 0 })
        end
    elseif kind == "sparkle" then
        new("Frame", { Parent = holder, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
            Size = UDim2.fromOffset(sz*0.85, 1.6), BackgroundColor3 = color, BorderSizePixel = 0 }, { corner(1) })
        new("Frame", { Parent = holder, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
            Size = UDim2.fromOffset(1.6, sz*0.85), BackgroundColor3 = color, BorderSizePixel = 0 }, { corner(1) })
    elseif kind == "palette" then
        local c = new("Frame", { Parent = holder, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
            Size = UDim2.fromOffset(sz, sz*0.85), BackgroundTransparency = 1 }, { corner(sz/2), stroke(color, 1.6) })
        for _, pos in ipairs({{0.32,0.32},{0.65,0.32},{0.32,0.65}}) do
            new("Frame", { Parent = c, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(pos[1], pos[2]),
                Size = UDim2.fromOffset(sz*0.14, sz*0.14), BackgroundColor3 = color, BorderSizePixel = 0 }, { corner(sz*0.07) })
        end
    else
        new("Frame", { Parent = holder, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
            Size = UDim2.fromOffset(sz*0.85, sz*0.85), BackgroundTransparency = 1 }, { corner(4), stroke(color, 1.6) })
    end
    return holder
end

function Lib:SetTheme(name)
    local t = Themes[name]
    if not t then return end
    Lib.ThemeName = name
    for k, v in pairs(t) do Theme[k] = v end
    for i = #themed, 1, -1 do
        local e = themed[i]
        if e[1].Parent then tween(e[1], 0.35, { [e[2]] = Theme[e[3]] }, SINE)
        else table.remove(themed, i) end
    end
    for _, f in ipairs(hooks) do task.spawn(pcall, f) end
end

--// ------------------------------------------------------------------ NOTIFY
function Lib:Notify(title, text, dur)
    local h = Lib._notif
    if not (h and h.Parent) then return end
    dur = dur or 3
    local wrap = new("Frame", { Parent = h, Size = UDim2.fromOffset(300, 66), BackgroundTransparency = 1 })
    local card = new("Frame", {
        Parent = wrap, Position = UDim2.fromOffset(330, 0), Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = "@Panel", BorderSizePixel = 0,
    }, { corner(14), stroke("@Line", 1, 0.3) })
    new("Frame", { Parent = card, Position = UDim2.fromOffset(0, 16), Size = UDim2.fromOffset(3, 34),
        BackgroundColor3 = "@Accent", BorderSizePixel = 0 }, { corner(2) })
    label(card, tostring(title or ""), UDim2.fromOffset(18, 12), UDim2.new(1, -30, 0, 18), Enum.Font.GothamBold, 13, "@Text")
    label(card, tostring(text or ""), UDim2.fromOffset(18, 32), UDim2.new(1, -30, 0, 22), Enum.Font.Gotham, 12, "@Sub")
    tween(card, 0.5, { Position = UDim2.fromOffset(0, 0) })
    task.delay(dur, function()
        if not wrap.Parent then return end
        tween(card, 0.4, { Position = UDim2.fromOffset(330, 0) }, QUINT, IN)
        task.wait(0.45)
        wrap:Destroy()
    end)
end

--// ------------------------------------------------------------------ WINDOW
local function guiParent()
    if gethui then local ok, r = pcall(gethui) if ok and r then return r end end
    return LP:WaitForChild("PlayerGui")
end

function Lib:CreateWindow(o)
    o = o or {}
    local WIDTH, HEIGHT = 940, 620
    local W = setmetatable({
        Tabs = {}, Items = {}, Binds = {}, Conns = {}, GlassPanels = {}, GlassCards = {},
        Glass = o.Glass == true, Key = o.Key or Enum.KeyCode.RightShift, Open = true,
        UserScale = 1, GlassBlur = 40, W = WIDTH, H = HEIGHT, Folder = o.Folder or "Eclipse",
        Library = Lib, Query = "",
    }, Window)
    table.insert(Lib.Windows, W)

    local function conn(c) table.insert(W.Conns, c) return c end
    W.keep = conn

    local parent = guiParent()
    local old = parent:FindFirstChild("EclipseHub")
    if old then old:Destroy() end
    W.Gui = new("ScreenGui", {
        Name = "EclipseHub", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999, Parent = parent,
    })

    Lib._notif = new("Frame", {
        Parent = W.Gui, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.fromOffset(300, 500), BackgroundTransparency = 1, ZIndex = 100,
    }, { new("UIListLayout", {
        Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right,
    }) })

    W.Root = new("Frame", {
        Parent = W.Gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(WIDTH, HEIGHT), BackgroundTransparency = 1,
    })
    W.Scale = new("UIScale", { Parent = W.Root, Scale = 0 })

    W.Main = new("Frame", {
        Parent = W.Root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = "@Outer",
        BorderSizePixel = 0, ZIndex = 1,
    }, { corner(22), stroke("@Line", 1.2, 0.35) })
    table.insert(W.GlassPanels, { W.Main, 0, 0.35 })

    --// ---------- sidebar
    local side = new("Frame", {
        Parent = W.Main, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(216, HEIGHT - 24 - 30),
        BackgroundColor3 = "@Panel", BorderSizePixel = 0,
    }, { corner(18), stroke("@Line", 1, 0.5) })
    table.insert(W.GlassPanels, { side, 0, 0.35 })

    --// logo
    local logoArea = new("Frame", { Parent = side, Size = UDim2.fromOffset(216, 62), BackgroundTransparency = 1 })
    -- equalizer mark
    local markHolder = new("Frame", { Parent = logoArea, Position = UDim2.fromOffset(18, 0),
        Size = UDim2.fromOffset(24, 62), BackgroundTransparency = 1 })
    for i, h in ipairs({ 14, 26, 20 }) do
        new("Frame", { Parent = markHolder, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset((i-1)*7, 40),
            Size = UDim2.fromOffset(4, h), BackgroundColor3 = "@Text", BorderSizePixel = 0 }, { corner(1.5) })
    end
    label(logoArea, string.upper(o.Title or "ECLIPSE"), UDim2.fromOffset(52, 16), UDim2.fromOffset(150, 20),
        Enum.Font.GothamBold, 14, "@Text")
    label(logoArea, string.upper(o.Subtitle or "VISUAL UTILITY"), UDim2.fromOffset(52, 34), UDim2.fromOffset(150, 12),
        Enum.Font.GothamMedium, 8, "@Sub")

    W.TabScroll = new("ScrollingFrame", {
        Parent = side, Position = UDim2.fromOffset(8, 70), Size = UDim2.new(1, -16, 1, -70 - 110),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, { new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })

    label(side, (o.Version or "1.21.11") .. " / " .. (o.Tag or "FABRIC"), UDim2.new(0, 20, 1, -98),
        UDim2.fromOffset(150, 14), Enum.Font.GothamMedium, 9, "@Sub")

    local user = new("TextButton", {
        Parent = side, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -10),
        Size = UDim2.fromOffset(196, 62), BackgroundColor3 = "@Card", Text = "",
        AutoButtonColor = false, BorderSizePixel = 0,
    }, { corner(14), stroke("@Line", 1, 0.5) })
    new("ImageLabel", {
        Parent = user, Position = UDim2.fromOffset(10, 13), Size = UDim2.fromOffset(36, 36),
        BackgroundColor3 = "@Card2", Image = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=100&h=100",
    }, { corner(18) })
    W.UserName = label(user, o.UserName or "Eclipse Client", UDim2.fromOffset(56, 14),
        UDim2.fromOffset(112, 16), Enum.Font.GothamBold, 12, "@Text")
    W.UserSub = label(user, o.UserSub or "Configs", UDim2.fromOffset(56, 32), UDim2.fromOffset(112, 14),
        Enum.Font.Gotham, 10, "@Sub")
    -- chevron
    new("Frame", { Parent = user, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -18, 0.5, 0),
        Size = UDim2.fromOffset(7, 7), BackgroundTransparency = 1, Rotation = 45 },
        { stroke("@Sub", 1.5) })
    user.MouseEnter:Connect(function() tween(user, 0.25, { BackgroundColor3 = hoverColor() }, SINE) end)
    user.MouseLeave:Connect(function() tween(user, 0.3, { BackgroundColor3 = Theme.Card }, SINE) end)
    user.MouseButton1Click:Connect(function()
        if o.OnUser then fire(o.OnUser) return end
        local t = W:GetTab(o.UserTab or "Configs")
        if t then W:Select(t) end
    end)

    --// ---------- topbar
    local topW = WIDTH - 244
    local top = new("Frame", {
        Parent = W.Main, Position = UDim2.fromOffset(240, 12), Size = UDim2.fromOffset(topW, 60),
        BackgroundColor3 = "@Panel", BorderSizePixel = 0,
    }, { corner(18), stroke("@Line", 1, 0.5) })
    table.insert(W.GlassPanels, { top, 0, 0.35 })

    -- version pill
    local pill = new("Frame", {
        Parent = top, Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(190, 40),
        BackgroundColor3 = "@Content", BorderSizePixel = 0,
    }, { corner(12), stroke("@Line", 1, 0.55) })
    -- earth icon
    local earth = new("Frame", { Parent = pill, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1 }, { corner(8), stroke("@Text", 1.5) })
    new("Frame", { Parent = earth, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(4, 4), BackgroundColor3 = "@Text", BorderSizePixel = 0 }, { corner(2) })
    label(pill, o.Version or "1.21.11", UDim2.fromOffset(36, 0), UDim2.fromOffset(90, 40),
        Enum.Font.GothamBold, 14, "@Text")
    label(pill, string.upper(o.Tag or "FABRIC"), UDim2.new(1, -70, 0, 0), UDim2.fromOffset(58, 40),
        Enum.Font.GothamMedium, 9, "@Sub", Enum.TextXAlignment.Right)

    -- search
    local searchBack = new("Frame", {
        Parent = top, Position = UDim2.fromOffset(214, 10), Size = UDim2.fromOffset(330, 40),
        BackgroundColor3 = "@Content", BorderSizePixel = 0,
    }, { corner(12), stroke("@Line", 1, 0.55) })
    local sStroke = searchBack:FindFirstChildOfClass("UIStroke")
    -- magnifier
    new("Frame", { Parent = searchBack, Position = UDim2.fromOffset(14, 12), Size = UDim2.fromOffset(11, 11),
        BackgroundTransparency = 1 }, { corner(6), stroke("@Sub", 1.5) })
    new("Frame", { Parent = searchBack, Position = UDim2.fromOffset(23, 24), Size = UDim2.fromOffset(6, 1.5),
        Rotation = 45, BackgroundColor3 = "@Sub", BorderSizePixel = 0 })
    W.Search = new("TextBox", {
        Parent = searchBack, Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -48, 1, 0),
        BackgroundTransparency = 1, PlaceholderText = o.SearchText or "Search modules…",
        PlaceholderColor3 = "@Sub", Text = "", TextColor3 = "@Text", Font = Enum.Font.GothamMedium,
        TextSize = 13, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
    })
    W.Search:GetPropertyChangedSignal("Text"):Connect(function() W:_filter(W.Search.Text) end)
    W.Search.Focused:Connect(function() tween(sStroke, 0.25, { Color = Theme.Accent, Transparency = 0.1 }, SINE) end)
    W.Search.FocusLost:Connect(function() tween(sStroke, 0.3, { Color = Theme.Line, Transparency = 0.55 }, SINE) end)

    local function topBtn(w, x)
        local b = new("TextButton", {
            Parent = top, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -x, 0, 10),
            Size = UDim2.fromOffset(w, 40), BackgroundColor3 = "@Content", Text = "", AutoButtonColor = false,
            BorderSizePixel = 0,
        }, { corner(12), stroke("@Line", 1, 0.55) })
        b.MouseEnter:Connect(function() tween(b, 0.2, { BackgroundColor3 = Theme.Card2 }, SINE) end)
        b.MouseLeave:Connect(function() tween(b, 0.25, { BackgroundColor3 = Theme.Content }, SINE) end)
        return b
    end

    -- chat button
    local chat = topBtn(40, 12)
    local bubble = new("Frame", { Parent = chat, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.48),
        Size = UDim2.fromOffset(15, 12), BackgroundTransparency = 1 }, { corner(4), stroke("@Text", 1.5) })
    new("Frame", { Parent = bubble, AnchorPoint = Vector2.new(0.5,0), Position = UDim2.new(0.3, 0, 1, -1),
        Size = UDim2.fromOffset(4, 4), BackgroundColor3 = "@Text", BorderSizePixel = 0, Rotation = 45 })
    chat.MouseButton1Click:Connect(function() fire(o.OnChat) end)

    -- lang pill
    local langs, langIdx = o.Languages or { "EN", "RU" }, 1
    local lang = topBtn(44, 60)
    local langL = label(lang, langs[1], UDim2.new(), UDim2.fromScale(1, 1), Enum.Font.GothamBold, 11, "@Text",
        Enum.TextXAlignment.Center)
    lang.MouseButton1Click:Connect(function()
        langIdx = langIdx % #langs + 1
        langL.Text = langs[langIdx]
        fire(o.OnLanguage, langs[langIdx])
    end)

    -- settings button (sliders icon)
    local sett = topBtn(40, 108)
    local sIcon = new("Frame", { Parent = sett, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(16, 14), BackgroundTransparency = 1 })
    new("Frame", { Parent = sIcon, Position = UDim2.fromOffset(0, 3), Size = UDim2.fromOffset(16, 1.5),
        BackgroundColor3 = "@Text", BorderSizePixel = 0 })
    new("Frame", { Parent = sIcon, Position = UDim2.fromOffset(0, 9), Size = UDim2.fromOffset(16, 1.5),
        BackgroundColor3 = "@Text", BorderSizePixel = 0 })
    new("Frame", { Parent = sIcon, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromOffset(5, 3.75),
        Size = UDim2.fromOffset(5, 5), BackgroundColor3 = "@Content", BorderSizePixel = 0 }, { corner(3), stroke("@Text", 1.5) })
    new("Frame", { Parent = sIcon, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromOffset(11, 9.75),
        Size = UDim2.fromOffset(5, 5), BackgroundColor3 = "@Content", BorderSizePixel = 0 }, { corner(3), stroke("@Text", 1.5) })
    sett.MouseButton1Click:Connect(function()
        if o.OnSettings then fire(o.OnSettings) return end
        local t = W:GetTab("Settings")
        if t then W:Select(t) end
    end)

    --// ---------- content
    local contentH = HEIGHT - 12 - 60 - 8 - 30   -- top bar 60, gap 8, footer 30
    W.Content = new("Frame", {
        Parent = W.Main, Position = UDim2.fromOffset(240, 80), Size = UDim2.fromOffset(topW, contentH),
        BackgroundColor3 = "@Content", BorderSizePixel = 0, ClipsDescendants = true,
    }, { corner(18), stroke("@Line", 1, 0.55) })
    table.insert(W.GlassPanels, { W.Content, 0, 0.5 })

    W.Title = label(W.Content, "", UDim2.fromOffset(24, 16), UDim2.fromOffset(400, 30),
        Enum.Font.GothamBold, 24, "@Text")
    W.Sub   = label(W.Content, "", UDim2.fromOffset(24, 50), UDim2.fromOffset(460, 16),
        Enum.Font.Gotham, 12, "@Sub")

    --// footer
    label(W.Main, string.upper(keyName(W.Key)) .. "  ·  CLOSE  ·  RIGHT CLICK  ·  SETTINGS",
        UDim2.fromOffset(248, HEIGHT - 28), UDim2.fromOffset(400, 16), Enum.Font.GothamMedium, 9, "@Sub")
    label(W.Main, "Interactive preview", UDim2.new(1, -240, 1, -28), UDim2.fromOffset(220, 16),
        Enum.Font.GothamMedium, 9, "@Sub", Enum.TextXAlignment.Right)

    --// ---------- drag
    local function makeDrag(handle)
        local dragging, ds, sp
        handle.InputBegan:Connect(function(i)
            if isPress(i) then
                dragging, ds, sp = true, i.Position, W.Root.Position
                i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end)
        conn(UIS.InputChanged:Connect(function(i)
            if dragging and isMove(i) then
                local d = i.Position - ds
                W.Root.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end))
    end
    makeDrag(top)
    makeDrag(logoArea)

    --// ---------- input (keybinds)
    conn(UIS.InputBegan:Connect(function(input, gp)
        if W.Listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local f = W.Listening
                W.Listening = nil
                f(input.KeyCode)
            end
            return
        end
        if gp then return end
        if input.KeyCode == W.Key then W:Toggle() return end
        for _, b in ipairs(W.Binds) do
            if b.Key and input.KeyCode == b.Key then task.spawn(b.Press, true) end
        end
    end))
    conn(UIS.InputEnded:Connect(function(input)
        for _, b in ipairs(W.Binds) do
            if b.Key and b.Mode == "Hold" and input.KeyCode == b.Key then task.spawn(b.Press, false) end
        end
    end))

    onTheme(function()
        for _, t in ipairs(W.Tabs) do
            local c = t.Active and Theme.Text or Theme.Sub
            t.NameLabel.TextColor3 = c
            if t.IconPaint then t.IconPaint(c) end
        end
    end)

    conn(RunService.RenderStepped:Connect(function()
        if W.Open and W._autoScale then W.Scale.Scale = W:_scale() end
    end))
    W:_scale()
    W.Blur = new("BlurEffect", { Parent = Lighting, Size = 0 })
    task.defer(function()
        -- opening: scale + slight fade
        tween(W.Scale, 0.55, { Scale = W:_scale() }, BACK)
        task.delay(0.6, function() W._autoScale = true end)
    end)
    if W.Glass then W:SetGlass(true) end
    return W
end

function Window:_scale()
    local cam = Workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    return math.clamp(math.min(vp.X / (self.W + 40), vp.Y / (self.H + 40)), 0.4, 1.2) * self.UserScale
end

function Window:SetScale(v) self.UserScale = v end
function Window:SetKey(k) self.Key = k end

function Window:_blur()
    if self.Blur then
        tween(self.Blur, 0.4, { Size = (self.Glass and self.Open) and (self.GlassBlur * 0.5) or 0 }, SINE)
    end
end

function Window:SetGlass(on)
    self.Glass = on and true or false
    for _, g in ipairs(self.GlassPanels) do
        tween(g[1], 0.4, { BackgroundTransparency = self.Glass and g[3] or g[2] }, SINE)
    end
    for _, c in ipairs(self.GlassCards) do
        if c.Parent then tween(c, 0.35, { BackgroundTransparency = self.Glass and 0.25 or 0 }, SINE) end
    end
    self:_blur()
end
function Window:SetGlassBlur(pct) self.GlassBlur = pct self:_blur() end

function Window:Toggle(force)
    if force ~= nil then self.Open = force else self.Open = not self.Open end
    if self.Open then
        self.Root.Visible = true
        tween(self.Scale, 0.55, { Scale = self:_scale() }, BACK)
    else
        self:_closePopup()
        tween(self.Scale, 0.3, { Scale = 0 }, QUINT, IN)
        task.delay(0.33, function() if not self.Open then self.Root.Visible = false end end)
    end
    self:_blur()
end

function Window:Notify(t, x, d) Lib:Notify(t, x, d) end

function Window:Destroy()
    self:_closePopup()
    for _, c in ipairs(self.Conns) do pcall(function() c:Disconnect() end) end
    if self.Blur then self.Blur:Destroy() end
    self.Gui:Destroy()
end

--// ---------- popups
function Window:_closePopup()
    local p = self._pop
    if not p then return end
    self._pop = nil
    for _, c in ipairs(p.conns) do pcall(function() c:Disconnect() end) end
    p.blocker:Destroy()
    p.frame:Destroy()
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

    local blocker = new("TextButton", {
        Parent = self.Root, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, ZIndex = 50,
    })
    local frame = new("Frame", {
        Parent = self.Root, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = "@Panel", BorderSizePixel = 0, ZIndex = 51, ClipsDescendants = true,
    }, { corner(12), stroke("@Line", 1, 0.2) })
    local pop = { blocker = blocker, frame = frame, conns = {} }
    self._pop = pop
    blocker.MouseButton1Click:Connect(function() self:_closePopup() end)
    build(frame, pop)
    return pop
end

--// ---------- tabs
function Window:GetTab(name)
    for _, t in ipairs(self.Tabs) do if t.Name == name then return t end end
end

function Window:AddTab(name, opts)
    if type(opts) == "string" then opts = { Sub = opts } end
    opts = opts or {}
    local W = self
    local idx = #W.Tabs + 1

    local btn = new("TextButton", {
        Parent = W.TabScroll, LayoutOrder = idx, Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = "@Card2", BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
        BorderSizePixel = 0, ClipsDescendants = true,
    }, { corner(10) })

    local icon, paint
    local ic = opts.Icon
    if type(ic) == "number" then ic = "rbxassetid://" .. ic end
    if type(ic) == "string" and ic ~= "" and (ic:find("rbxassetid") or ic:find("http")) then
        local img = new("ImageLabel", {
            Parent = btn, Position = UDim2.fromOffset(14, 9), Size = UDim2.fromOffset(20, 20),
            BackgroundTransparency = 1, Image = ic, ImageColor3 = Theme.Sub,
        })
        paint = function(c) tween(img, 0.25, { ImageColor3 = c }, SINE) end
    else
        local holder = new("Frame", { Parent = btn, Position = UDim2.fromOffset(14, 9),
            Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1 })
        local drawn = drawIcon(holder, ic or "grid", 20, Theme.Sub)
        -- redraw on theme: recolor each stroke
        paint = function(c)
            for _, f in ipairs(drawn:GetDescendants()) do
                if f:IsA("UIStroke") then tween(f, 0.25, { Color = c }, SINE)
                elseif f:IsA("Frame") and f.BackgroundTransparency ~= 1 then
                    tween(f, 0.25, { BackgroundColor3 = c }, SINE)
                end
            end
        end
    end

    local nameLabel = label(btn, name, UDim2.fromOffset(48, 0), UDim2.new(1, -56, 1, 0),
        Enum.Font.GothamMedium, 13, Theme.Sub)

    local page = new("ScrollingFrame", {
        Parent = W.Content, Position = UDim2.fromOffset(14, 92), Size = UDim2.new(1, -28, 1, -104),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = "@Card2", CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
    }, {
        new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
        new("UIPadding", { PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 12) }),
    })

    local tab = setmetatable({
        Window = W, Name = name, Sub = opts.Sub or "", Btn = btn, NameLabel = nameLabel, Page = page,
        IconPaint = paint, Order = 0, Active = false, Sections = {}, _row = nil, _rowN = 0,
    }, Tab)
    table.insert(W.Tabs, tab)

    --// segment (Solid/Glass) in top-right of section header
    if opts.Segment then
        local seg = opts.Segment
        local holder = new("Frame", {
            Parent = W.Content, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 18),
            Size = UDim2.fromOffset(#seg.Options * 60 + 8, 30), BackgroundColor3 = "@Panel",
            BorderSizePixel = 0, Visible = false,
        }, { corner(10) })
        local sel = seg.Default or seg.Options[1]
        local btns = {}
        local function paintSeg()
            for n, b in pairs(btns) do
                local on = n == sel
                tween(b, 0.2, { BackgroundTransparency = on and 0 or 1,
                    TextColor3 = on and Theme.Text or Theme.Sub }, SINE)
            end
        end
        for i, n in ipairs(seg.Options) do
            local b = new("TextButton", {
                Parent = holder, Position = UDim2.fromOffset(4 + (i-1)*60, 3), Size = UDim2.fromOffset(58, 24),
                BackgroundColor3 = "@Card2", Text = n, TextColor3 = Theme.Sub,
                Font = Enum.Font.GothamMedium, TextSize = 11, AutoButtonColor = false, BorderSizePixel = 0,
            }, { corner(7) })
            btns[n] = b
            b.MouseButton1Click:Connect(function()
                sel = n paintSeg() fire(seg.Callback, n)
            end)
        end
        paintSeg()
        onTheme(paintSeg)
        tab.SegmentFrame = holder
        local api = {
            Get = function() return sel end,
            Set = function(_, v) if btns[v] then sel = v paintSeg() fire(seg.Callback, v) end end,
            Export = function() return sel end,
            Import = function(v) api:Set(v) end,
        }
        if seg.Flag then Lib.Flags[seg.Flag] = api end
        tab.Segment = api
        task.defer(function() if seg.Default then fire(seg.Callback, sel) end end)
    end

    btn.MouseEnter:Connect(function()
        if not tab.Active then
            tween(btn, 0.15, { BackgroundTransparency = 0.6 }, SINE)
            tween(nameLabel, 0.15, { TextColor3 = Theme.Text }, SINE)
            paint(Theme.Text)
        end
    end)
    btn.MouseLeave:Connect(function()
        if not tab.Active then
            tween(btn, 0.2, { BackgroundTransparency = 1 }, SINE)
            tween(nameLabel, 0.2, { TextColor3 = Theme.Sub }, SINE)
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
        tween(t.Btn, 0.25, { BackgroundTransparency = on and 0.55 or 1 }, SINE)
        tween(t.NameLabel, 0.25, { TextColor3 = on and Theme.Text or Theme.Sub }, SINE)
        t.IconPaint(on and Theme.Text or Theme.Sub)
        if t.SegmentFrame then t.SegmentFrame.Visible = on end
    end
    self.Title.Text, self.Sub.Text = tab.Name, tab.Sub
    self.Title.TextTransparency, self.Sub.TextTransparency = 1, 1
    self.Title.Position = UDim2.fromOffset(24, 20)
    self.Sub.Position   = UDim2.fromOffset(24, 54)
    tween(self.Title, 0.35, { TextTransparency = 0, Position = UDim2.fromOffset(24, 16) }, SINE)
    tween(self.Sub,   0.35, { TextTransparency = 0, Position = UDim2.fromOffset(24, 50) }, SINE)
    if old then old.Page.Visible = false end
    tab.Page.Position = UDim2.fromOffset(14, 108)
    tab.Page.Visible = true
    tween(tab.Page, 0.4, { Position = UDim2.fromOffset(14, 92) }, SINE)
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
    for _, it in ipairs(self.Items) do
        if it.row then it.row.Visible = q == "" or rowVis[it.row] == true end
    end
    for _, t in ipairs(self.Tabs) do
        for _, s in ipairs(t.Sections) do s.Visible = q == "" end
        tween(t.NameLabel, 0.2, { TextTransparency = (q ~= "" and not counts[t]) and 0.6 or 0 }, SINE)
    end
    if q ~= "" and self.Current and not counts[self.Current] then
        for _, t in ipairs(self.Tabs) do
            if counts[t] then self:Select(t) break end
        end
    end
end

--// ------------------------------------------------------------------ ELEMENT BASE
function Tab:_slot(h, half)
    if half then
        local row = self._row
        if not row or self._rowN >= 2 then
            self.Order += 1
            row = new("Frame", {
                Parent = self.Page, LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, h),
                BackgroundTransparency = 1,
            }, { new("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }) })
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
    local flat = self.Flat
    local f = new("Frame", {
        Parent = parent, LayoutOrder = order, Size = size,
        BackgroundColor3 = flat and "@Card2" or "@Card",
        BackgroundTransparency = flat and 0.55 or (W.Glass and 0.22 or 0),
        BorderSizePixel = 0,
    })
    if not flat then
        corner(12).Parent = f
        stroke("@Line", 1, 0.45).Parent = f
        f.MouseEnter:Connect(function() tween(f, 0.2, { BackgroundColor3 = hoverColor() }, SINE) end)
        f.MouseLeave:Connect(function() tween(f, 0.25, { BackgroundColor3 = Theme.Card }, SINE) end)
        table.insert(W.GlassCards, f)
    else
        corner(8).Parent = f
    end
    table.insert(W.Items, { frame = f, row = row, text = (text or ""):lower(), tab = self })
    return f
end

local function rowTexts(card, o, rightPad)
    label(card, o.Name or "Option", UDim2.fromOffset(14, o.Desc and 9 or 0),
        o.Desc and UDim2.new(1, -rightPad, 0, 18) or UDim2.new(1, -rightPad, 1, 0),
        Enum.Font.GothamMedium, 12, "@Text")
    if o.Desc then
        label(card, o.Desc, UDim2.fromOffset(14, 28), UDim2.new(1, -rightPad, 0, 14),
            Enum.Font.Gotham, 10, "@Sub")
    end
end

local function clickArea(card)
    return new("TextButton", {
        Parent = card, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, ZIndex = 2,
    })
end

local function register(o, api)
    if o.Flag then Lib.Flags[o.Flag] = api end
    return api
end

--// ------------------------------------------------------------------ ELEMENTS
function Tab:AddSection(name)
    self.Order += 1
    self._row = nil
    local f = new("Frame", { Parent = self.Page, LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1 })
    label(f, string.upper(name), UDim2.fromOffset(4, 4), UDim2.new(1, 0, 0, 14),
        Enum.Font.GothamBold, 10, "@Accent")
    table.insert(self.Sections, f)
    return f
end

function Tab:AddLabel(text, h)
    self.Order += 1
    self._row = nil
    local f = new("Frame", { Parent = self.Page, LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, h or 30),
        BackgroundTransparency = 1 })
    local l = label(f, text, UDim2.fromOffset(4, 0), UDim2.new(1, -4, 1, 0), Enum.Font.Gotham, 11, "@Sub", nil,
        { TextWrapped = true, TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top })
    table.insert(self.Sections, f)
    return l
end

function Tab:AddButton(o)
    local card = self:_card(o.Desc and 54 or 44, o, (o.Name or "") .. " " .. (o.Desc or ""))
    rowTexts(card, o, 120)
    local p = new("Frame", {
        Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(76, 26), BackgroundColor3 = "@Accent", BorderSizePixel = 0,
    }, { corner(8) })
    new("TextLabel", {
        Parent = p, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Text = o.ButtonText or "RUN", Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = Color3.new(1, 1, 1), AutoLocalize = false,
    })
    local sc = new("UIScale", { Parent = p })
    local hit = clickArea(card)
    hit.InputBegan:Connect(function(i) if isPress(i) then tween(sc, 0.12, { Scale = 0.92 }) end end)
    hit.InputEnded:Connect(function(i) if isPress(i) then tween(sc, 0.3, { Scale = 1 }) end end)
    hit.MouseButton1Click:Connect(function() fire(o.Callback) end)
    return { Frame = card }
end

function Tab:AddToggle(o)
    local W = self.Window
    local state = o.Default == true
    local hasBind = o.Keybind ~= nil and o.Keybind ~= false
    local card = self:_card(o.Desc and 54 or 44, o, (o.Name or "") .. " " .. (o.Desc or ""))
    rowTexts(card, o, hasBind and 140 or 80)

    local track = new("Frame", {
        Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(40, 22), BackgroundColor3 = state and Theme.Accent or Theme.Off,
        BorderSizePixel = 0,
    }, { corner(11), stroke("@Line", 1, 0.35) })
    local knob = new("Frame", {
        Parent = track, Position = state and UDim2.fromOffset(20, 3) or UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(16, 16), BackgroundColor3 = "@Knob", BorderSizePixel = 0,
    }, { corner(8) })
    local function render()
        tween(track, 0.25, { BackgroundColor3 = state and Theme.Accent or Theme.Off }, SINE)
        tween(knob, 0.3, { Position = state and UDim2.fromOffset(20, 3) or UDim2.fromOffset(3, 3) }, QUINT)
    end
    onTheme(render)

    local api = {}
    function api:Get() return state end
    function api:Set(v, silent)
        state = v and true or false
        render()
        if not silent then fire(o.Callback, state) end
    end

    local hit = clickArea(card)
    hit.MouseButton1Click:Connect(function() api:Set(not state) end)

    local bind
    if hasBind then
        bind = { Key = (typeof(o.Keybind) == "EnumItem") and o.Keybind or nil, Mode = "Press",
            Press = function(down) if down then api:Set(not state) end end }
        table.insert(W.Binds, bind)
        local pillB = new("TextButton", {
            Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -62, 0.5, 0),
            Size = UDim2.fromOffset(60, 24), BackgroundColor3 = "@Card2", Text = keyName(bind.Key),
            TextColor3 = "@Sub", Font = Enum.Font.GothamBold, TextSize = 9,
            AutoButtonColor = false, ZIndex = 3, BorderSizePixel = 0,
        }, { corner(7), stroke("@Line", 1, 0.5) })
        pillB.MouseButton1Click:Connect(function()
            pillB.Text = "..."
            W.Listening = function(kc)
                if kc == Enum.KeyCode.Backspace or kc == Enum.KeyCode.Delete then bind.Key = nil
                elseif kc ~= Enum.KeyCode.Escape then bind.Key = kc end
                pillB.Text = keyName(bind.Key)
            end
        end)
        bind.pill = pillB
    end

    api.Export = function()
        if bind then return { State = state, Key = bind.Key and bind.Key.Name or nil } end
        return state
    end
    api.Import = function(v)
        if type(v) == "table" then
            if bind then
                bind.Key = v.Key and Enum.KeyCode[v.Key] or nil
                bind.pill.Text = keyName(bind.Key)
            end
            api:Set(v.State)
        else
            api:Set(v)
        end
    end
    register(o, api)
    if state then fire(o.Callback, state) end
    return api
end

function Tab:AddSlider(o)
    local W = self.Window
    local min, max, step = o.Min or 0, o.Max or 100, o.Step or 1
    local digits = step >= 1 and 0 or math.max(0, -math.floor(math.log10(step) + 1e-9))
    local value = math.clamp(o.Default or min, min, max)
    local card = self:_card(58, o, o.Name)
    label(card, o.Name or "Slider", UDim2.fromOffset(14, 9), UDim2.new(1, -90, 0, 16),
        Enum.Font.GothamMedium, 12, "@Text")
    local vl = label(card, "", UDim2.new(1, -94, 0, 9), UDim2.fromOffset(80, 16),
        Enum.Font.GothamMedium, 11, "@Text", Enum.TextXAlignment.Right)
    local bar = new("Frame", {
        Parent = card, Position = UDim2.fromOffset(14, 40), Size = UDim2.new(1, -28, 0, 4),
        BackgroundColor3 = "@Card2", BorderSizePixel = 0,
    }, { corner(2) })
    local fill = new("Frame", { Parent = bar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = "@Accent",
        BorderSizePixel = 0 }, { corner(2) })
    local knob = new("Frame", {
        Parent = bar, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(12, 12), BackgroundColor3 = "@Knob", BorderSizePixel = 0, ZIndex = 2,
    }, { corner(6), stroke("@Accent", 1.5) })

    local function render(fast)
        local r = (value - min) / (max - min)
        vl.Text = string.format("%." .. digits .. "f", value) .. (o.Suffix or "")
        local t = fast and 0.08 or 0.25
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

    local hit = new("TextButton", {
        Parent = card, Position = UDim2.fromOffset(6, 30), Size = UDim2.new(1, -12, 0, 26),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3,
    })
    local dragging = false
    local function fromX(x)
        local r = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        setV(min + (max - min) * r, true)
    end
    hit.InputBegan:Connect(function(i)
        if isPress(i) then
            dragging = true
            tween(knob, 0.15, { Size = UDim2.fromOffset(16, 16) })
            fromX(i.Position.X)
        end
    end)
    W.keep(UIS.InputChanged:Connect(function(i) if dragging and isMove(i) then fromX(i.Position.X) end end))
    W.keep(UIS.InputEnded:Connect(function(i)
        if dragging and isPress(i) then
            dragging = false
            tween(knob, 0.25, { Size = UDim2.fromOffset(12, 12) })
        end
    end))

    local api = {}
    function api:Get() return value end
    function api:Set(v) setV(v, false) end
    api.Export = function() return value end
    api.Import = function(v) if type(v) == "number" then setV(v, false) end end
    return register(o, api)
end

function Tab:AddDropdown(o)
    local W = self.Window
    local opts = o.Options or {}
    local selected = o.Default or opts[1]
    local card = self:_card(44, o, (o.Name or "") .. " " .. table.concat(opts, " "))
    label(card, o.Name or "Dropdown", UDim2.fromOffset(14, 0), UDim2.new(1, -150, 1, 0),
        Enum.Font.GothamMedium, 12, "@Text")
    local vl = label(card, tostring(selected), UDim2.new(1, -150, 0, 0), UDim2.fromOffset(120, 44),
        Enum.Font.Gotham, 10, "@Sub", Enum.TextXAlignment.Right)
    -- chevron
    new("Frame", { Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0),
        Size = UDim2.fromOffset(7, 7), BackgroundTransparency = 1, Rotation = 45 },
        { stroke("@Sub", 1.5) })

    local api = {}
    local function choose(v, silent)
        selected = v
        vl.Text = tostring(v)
        if not silent then fire(o.Callback, v) end
    end
    local hit = clickArea(card)
    hit.MouseButton1Click:Connect(function()
        if W._pop then W:_closePopup() return end
        local n = #opts
        local width = math.max(card.AbsoluteSize.X / math.max(W.Scale.Scale, 0.05), 170)
        local h = math.min(n, 7) * 30 + 12
        W:_popup(card, width, h, function(frame)
            local sc = new("ScrollingFrame", {
                Parent = frame, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12),
                BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
                ScrollBarImageColor3 = "@Accent", CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 52,
            }, { new("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }) })
            for i, opt in ipairs(opts) do
                local on = opt == selected
                local b = new("TextButton", {
                    Parent = sc, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = "@Card2", BackgroundTransparency = on and 0.3 or 1,
                    Text = "  " .. tostring(opt), TextColor3 = on and Theme.Accent or Theme.Text,
                    Font = Enum.Font.GothamMedium, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
                    ZIndex = 52, BorderSizePixel = 0,
                }, { corner(8) })
                b.MouseEnter:Connect(function() tween(b, 0.15, { BackgroundTransparency = 0.3 }, SINE) end)
                b.MouseLeave:Connect(function() tween(b, 0.2, { BackgroundTransparency = (opt == selected) and 0.3 or 1 }, SINE) end)
                b.MouseButton1Click:Connect(function() choose(opt) W:_closePopup() end)
            end
        end)
    end)
    function api:Get() return selected end
    function api:Set(v) if table.find(opts, v) then choose(v) end end
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

function Tab:AddTextbox(o)
    local card = self:_card(44, o, o.Name)
    label(card, o.Name or "Textbox", UDim2.fromOffset(14, 0), UDim2.new(1, -190, 1, 0),
        Enum.Font.GothamMedium, 12, "@Text")
    local back = new("Frame", {
        Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(160, 28), BackgroundColor3 = "@Content", BorderSizePixel = 0,
    }, { corner(8) })
    local bs = stroke("@Line", 1.2, 0.2)
    bs.Parent = back
    local box = new("TextBox", {
        Parent = back, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0),
        BackgroundTransparency = 1, PlaceholderText = o.Placeholder or "",
        PlaceholderColor3 = "@Sub", Text = o.Default or "", TextColor3 = "@Text",
        Font = Enum.Font.GothamMedium, TextSize = 11, ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    box.Focused:Connect(function() tween(bs, 0.25, { Color = Theme.Accent }, SINE) end)
    box.FocusLost:Connect(function(enter)
        tween(bs, 0.3, { Color = Theme.Line }, SINE)
        fire(o.Callback, box.Text, enter)
    end)
    local api = {}
    function api:Get() return box.Text end
    function api:Set(t) box.Text = t end
    api.Export = function() return box.Text end
    api.Import = function(v) if type(v) == "string" then box.Text = v fire(o.Callback, v, false) end end
    return register(o, api)
end

function Tab:AddKeybind(o)
    local W = self.Window
    local state = false
    local bind
    local card = self:_card(o.Desc and 54 or 44, o, (o.Name or "") .. " " .. (o.Desc or ""))
    rowTexts(card, o, 140)
    bind = { Key = o.Default, Mode = o.Mode or "Press",
        Press = function(down)
            if bind.Mode == "Press" then if down then fire(o.Callback) end
            elseif bind.Mode == "Toggle" then if down then state = not state fire(o.Callback, state) end
            else state = down fire(o.Callback, down) end
        end }
    table.insert(W.Binds, bind)
    local pillB = new("TextButton", {
        Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(92, 26), BackgroundColor3 = "@Card2", Text = keyName(bind.Key),
        TextColor3 = "@Text", Font = Enum.Font.GothamBold, TextSize = 10,
        AutoButtonColor = false, ZIndex = 3, BorderSizePixel = 0,
    }, { corner(7), stroke("@Line", 1, 0.5) })
    pillB.MouseButton1Click:Connect(function()
        pillB.Text = "..."
        W.Listening = function(kc)
            if kc == Enum.KeyCode.Backspace or kc == Enum.KeyCode.Delete then bind.Key = nil
            elseif kc ~= Enum.KeyCode.Escape then bind.Key = kc end
            pillB.Text = keyName(bind.Key)
            fire(o.Changed, bind.Key)
        end
    end)
    local api = {}
    function api:Get() return bind.Key end
    api.Export = function() return { Key = bind.Key and bind.Key.Name or nil, Mode = bind.Mode } end
    api.Import = function(v)
        if type(v) ~= "table" then return end
        bind.Key = v.Key and Enum.KeyCode[v.Key] or nil
        if v.Mode then bind.Mode = v.Mode end
        pillB.Text = keyName(bind.Key)
    end
    return register(o, api)
end

function Tab:AddColorPicker(o)
    local W = self.Window
    local col = o.Default or Color3.new(1, 1, 1)
    local card = self:_card(o.Desc and 54 or 44, o, (o.Name or "") .. " " .. (o.Desc or ""))
    rowTexts(card, o, 80)
    local sw = new("Frame", {
        Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(40, 22), BackgroundColor3 = col, BorderSizePixel = 0,
    }, { corner(8), stroke("@Line", 1, 0.2) })
    local api = {}
    local function setColor(c, silent)
        col = c
        sw.BackgroundColor3 = c
        if not silent then fire(o.Callback, c) end
    end
    local hit = clickArea(card)
    hit.MouseButton1Click:Connect(function()
        if W._pop then W:_closePopup() return end
        W:_popup(card, 224, 176, function(frame, pop)
            local h, s, v = col:ToHSV()
            local svBox = new("Frame", {
                Parent = frame, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(200, 112),
                BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0,
                ClipsDescendants = true, ZIndex = 52,
            }, { corner(8) })
            new("Frame", { Parent = svBox, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0, ZIndex = 53 },
                { new("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
            new("Frame", { Parent = svBox, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0, ZIndex = 54 },
                { new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
            local svKnob = new("Frame", {
                Parent = svBox, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10),
                BackgroundTransparency = 1, ZIndex = 56,
            }, { corner(5), stroke(Color3.new(1, 1, 1), 2) })
            local hueBar = new("Frame", {
                Parent = frame, Position = UDim2.fromOffset(12, 134), Size = UDim2.fromOffset(200, 12),
                BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 52,
            }, { corner(6), new("UIGradient", { Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, rgb(255, 0, 0)), ColorSequenceKeypoint.new(1/6, rgb(255, 255, 0)),
                ColorSequenceKeypoint.new(2/6, rgb(0, 255, 0)), ColorSequenceKeypoint.new(3/6, rgb(0, 255, 255)),
                ColorSequenceKeypoint.new(4/6, rgb(0, 0, 255)), ColorSequenceKeypoint.new(5/6, rgb(255, 0, 255)),
                ColorSequenceKeypoint.new(1, rgb(255, 0, 0)) }) }) })
            local hueKnob = new("Frame", {
                Parent = hueBar, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 16),
                BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 53,
            }, { corner(3), stroke(Color3.new(0, 0, 0), 1, 0.4) })
            local hex = label(frame, "", UDim2.fromOffset(12, 152), UDim2.fromOffset(200, 16),
                Enum.Font.GothamBold, 11, "@Sub", Enum.TextXAlignment.Left, { ZIndex = 52 })

            local function refresh()
                local c = Color3.fromHSV(h, s, v)
                svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                svKnob.Position = UDim2.fromScale(s, 1 - v)
                hueKnob.Position = UDim2.fromScale(h, 0.5)
                hex.Text = string.format("#%02X%02X%02X",
                    math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
                setColor(c)
            end
            refresh()

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
    function api:Set(c) setColor(c) end
    api.Export = function()
        return { math.floor(col.R*255+0.5), math.floor(col.G*255+0.5), math.floor(col.B*255+0.5) }
    end
    api.Import = function(v) if type(v) == "table" and #v == 3 then setColor(rgb(v[1], v[2], v[3])) end end
    return register(o, api)
end

--// 3x2 grid of theme cards (Lavender / Midnight / Rose × Dark / Light)
function Tab:AddThemeCards(o)
    o = o or {}
    local W = self.Window
    local list = o.Themes or ThemeList
    self.Order += 1
    self._row = nil
    local grid = new("Frame", {
        Parent = self.Page, LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
    }, { new("UIGridLayout", {
        CellSize = UDim2.new(1/3, -7, 0, 100),
        CellPadding = UDim2.fromOffset(10, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }) })
    table.insert(W.Items, { frame = grid, text = "theme lavender midnight rose dark light", tab = self })

    local strokes = {}
    local function mark(silent)
        for key, s in pairs(strokes) do
            local on = key == Lib.ThemeName
            tween(s, silent and 0.01 or 0.25, {
                Color = on and Theme.Accent or Theme.Line,
                Thickness = on and 1.6 or 1,
                Transparency = on and 0 or 0.35,
            }, SINE)
        end
    end
    for i, key in ipairs(list) do
        local t = Themes[key]
        local fam, mode = key:match("^(%S+)%s+(%S+)$")
        local c = new("TextButton", {
            Parent = grid, LayoutOrder = i, Text = "", AutoButtonColor = false,
            BackgroundColor3 = "@Card", BorderSizePixel = 0,
        }, { corner(14) })
        local s = stroke(Theme.Line, 1, 0.35)
        s.Parent = c
        strokes[key] = s
        -- mini preview
        local pv = new("Frame", {
            Parent = c, Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 0, 36),
            BackgroundColor3 = t.Panel, BorderSizePixel = 0,
        }, { corner(9) })
        new("Frame", { Parent = pv, Position = UDim2.fromOffset(6, 6),
            Size = UDim2.fromOffset(24, 24), BackgroundColor3 = t.Card2,
            BorderSizePixel = 0 }, { corner(6) })
        local bar = new("Frame", { Parent = pv, Position = UDim2.fromOffset(36, 6),
            Size = UDim2.new(1, -42, 0, 24), BackgroundColor3 = t.Content,
            BorderSizePixel = 0 }, { corner(6) })
        new("Frame", { Parent = bar, Position = UDim2.fromOffset(8, 7),
            Size = UDim2.new(0.35, 0, 0, 3), BackgroundColor3 = t.Accent,
            BorderSizePixel = 0 }, { corner(2) })
        new("Frame", { Parent = bar, Position = UDim2.fromOffset(8, 14),
            Size = UDim2.new(0.7, 0, 0, 2), BackgroundColor3 = t.Sub,
            BorderSizePixel = 0 }, { corner(1) })
        label(c, fam, UDim2.fromOffset(12, 56), UDim2.new(1, -24, 0, 18),
            Enum.Font.GothamBold, 12, "@Text")
        label(c, mode, UDim2.fromOffset(12, 76), UDim2.new(1, -24, 0, 12),
            Enum.Font.Gotham, 10, "@Sub")
        c.MouseEnter:Connect(function() tween(c, 0.15, { BackgroundColor3 = hoverColor() }, SINE) end)
        c.MouseLeave:Connect(function() tween(c, 0.2, { BackgroundColor3 = Theme.Card }, SINE) end)
        c.MouseButton1Click:Connect(function()
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

--// ------------------------------------------------------------------ MODULE (expandable card)
-- A single card that shows a title row + Enabled toggle, and expands to show settings.
--   local mod = Tab:AddModule({ Name = "Silk trails", Desc = "...", Icon = "sparkle", Default = true, Callback = ... })
--   mod:AddSegmented({ Name = "Trail style", Options = {"Silk","Steps","Star path","Butterflies"}, Callback = ... })
--   mod:AddSlider({ Name = "Opacity", ... })
function Tab:AddModule(o)
    o = o or {}
    local W = self.Window
    local state = o.Default == true
    local expanded = false

    -- Outer card (auto-height)
    self.Order += 1
    self._row = nil
    local card = new("Frame", {
        Parent = self.Page, LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = "@Card", BackgroundTransparency = W.Glass and 0.22 or 0,
        BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y,
    }, { corner(14), stroke("@Line", 1, 0.45) })
    table.insert(W.GlassCards, card)
    card.MouseEnter:Connect(function() tween(card, 0.2, { BackgroundColor3 = hoverColor() }, SINE) end)
    card.MouseLeave:Connect(function() tween(card, 0.25, { BackgroundColor3 = Theme.Card }, SINE) end)
    table.insert(W.Items, { frame = card, text = ((o.Name or "") .. " " .. (o.Desc or "")):lower(), tab = self })

    local container = new("Frame", {
        Parent = card, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, {
        new("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
        new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
    })

    -- Row 1: title + info + expand
    local titleRow = new("Frame", {
        Parent = container, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
    })
    local iconX = 0
    if o.Icon then
        local ih = new("Frame", { Parent = titleRow, Position = UDim2.fromOffset(14, 1),
            Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1 })
        local ic = drawIcon(ih, o.Icon, 18, Theme.Text)
        ic.Position = UDim2.fromOffset(0, 0)
        ic.AnchorPoint = Vector2.new(0, 0)
        iconX = 40
    end
    label(titleRow, o.Name or "Module", UDim2.fromOffset(o.Icon and 40 or 14, 0),
        UDim2.new(1, -100, 1, 0), Enum.Font.GothamBold, 13, "@Text")
    -- info dot
    if o.Desc then
        local info = new("Frame", {
            Parent = titleRow, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -32, 0.5, 0),
            Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1,
        }, { corner(7), stroke("@Sub", 1.2) })
        label(info, "i", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1),
            Enum.Font.GothamBold, 9, "@Sub", Enum.TextXAlignment.Center)
    end
    -- expand button
    local expandBtn = new("TextButton", {
        Parent = titleRow, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Text = "+",
        TextColor3 = "@Sub", TextSize = 16, AutoButtonColor = false,
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center,
    })

    -- Row 2: Enabled toggle
    local statusRow = new("Frame", {
        Parent = container, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
    })
    label(statusRow, "Enabled", UDim2.fromOffset(14, 0), UDim2.new(1, -70, 1, 0),
        Enum.Font.Gotham, 11, "@Sub")

    local track = new("Frame", {
        Parent = statusRow, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(40, 22),
        BackgroundColor3 = state and Theme.Accent or Theme.Off, BorderSizePixel = 0,
    }, { corner(11), stroke("@Line", 1, 0.35) })
    local knob = new("Frame", {
        Parent = track, Position = state and UDim2.fromOffset(20, 3) or UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(16, 16), BackgroundColor3 = "@Knob", BorderSizePixel = 0,
    }, { corner(8) })
    local function render()
        tween(track, 0.25, { BackgroundColor3 = state and Theme.Accent or Theme.Off }, SINE)
        tween(knob, 0.3, { Position = state and UDim2.fromOffset(20, 3) or UDim2.fromOffset(3, 3) }, QUINT)
    end
    onTheme(render)

    -- Settings container (hidden when collapsed)
    local settings = new("Frame", {
        Parent = container, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.None, Visible = false,
    }, {
        new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
        new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 4) }),
    })

    local function setExpanded(v)
        expanded = v
        expandBtn.Text = expanded and "−" or "+"
        if expanded then
            settings.Visible = true
            settings.AutomaticSize = Enum.AutomaticSize.Y
            settings.Size = UDim2.new(1, 0, 0, 0)
        else
            settings.AutomaticSize = Enum.AutomaticSize.None
            settings.Size = UDim2.new(1, 0, 0, 0)
            settings.Visible = false
        end
        fire(o.OnExpand, expanded)
    end
    expandBtn.MouseButton1Click:Connect(function() setExpanded(not expanded) end)
    expandBtn.MouseEnter:Connect(function() tween(expandBtn, 0.15, { TextColor3 = Theme.Text }, SINE) end)
    expandBtn.MouseLeave:Connect(function() tween(expandBtn, 0.2, { TextColor3 = Theme.Sub }, SINE) end)

    -- Toggle API
    local toggleAPI = {}
    function toggleAPI:Get() return state end
    function toggleAPI:Set(v, silent)
        state = v and true or false
        render()
        if not silent then fire(o.Callback, state) end
    end
    -- Enable-row click (only on row, not the pill)
    local rowHit = new("TextButton", {
        Parent = statusRow, Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, ZIndex = 2,
    })
    rowHit.MouseButton1Click:Connect(function() toggleAPI:Set(not state) end)

    -- Build Mod wrapper (inherits from Tab so all Add* work; Flat = true skips card backgrounds)
    local mod = setmetatable({
        Window = W, Name = o.Name, Page = settings, Order = 0,
        _row = nil, _rowN = 0, Sections = {}, Flat = true,
    }, Tab)
    mod.Toggle = toggleAPI
    mod.Card = card
    mod.Settings = settings
    mod.SetExpanded = setExpanded
    mod.Export = function()
        return { State = state, Expanded = expanded }
    end
    mod.Import = function(v)
        if type(v) == "table" then
            toggleAPI:Set(v.State)
            if v.Expanded ~= nil then setExpanded(v.Expanded) end
        else
            toggleAPI:Set(v)
        end
    end
    if o.Flag then Lib.Flags[o.Flag] = mod end

    -- Auto-callback initial state
    if state then task.defer(fire, o.Callback, state) end
    return mod
end

--// 2x2 options grid (like "Trail style" in the reference)
function Tab:AddSegmented(o)
    o = o or {}
    self.Order += 1
    self._row = nil
    local opts = o.Options or {}
    local sel = o.Default or opts[1]

    local wrap = new("Frame", {
        Parent = self.Page, LayoutOrder = self.Order, Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
    }, {
        new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
        new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
    })
    if o.Name then
        label(wrap, o.Name, UDim2.new(), UDim2.new(1, 0, 0, 14),
            Enum.Font.GothamMedium, 11, "@Sub")
    end
    local grid = new("Frame", {
        Parent = wrap, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
    }, { new("UIGridLayout", {
        CellSize = UDim2.new(0.5, -4, 0, 32),
        CellPadding = UDim2.fromOffset(8, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }) })

    local buttons = {}
    local function paint()
        for opt, b in pairs(buttons) do
            local on = opt == sel
            tween(b, 0.2, { BackgroundTransparency = on and 0 or 0.4 }, SINE)
            tween(b.TextLabel, 0.2, { TextColor3 = on and Theme.Text or Theme.Sub }, SINE)
            local st = b:FindFirstChildOfClass("UIStroke")
            if st then tween(st, 0.2, { Color = on and Theme.Accent or Theme.Line,
                Transparency = on and 0 or 0.35 }, SINE) end
        end
    end
    for i, opt in ipairs(opts) do
        local b = new("TextButton", {
            Parent = grid, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = "@Card2", BackgroundTransparency = 0.4,
            Text = opt, TextColor3 = "@Sub", Font = Enum.Font.GothamMedium, TextSize = 12,
            AutoButtonColor = false, BorderSizePixel = 0,
        }, { corner(8), stroke("@Line", 1, 0.35) })
        buttons[opt] = b
        b.MouseButton1Click:Connect(function()
            sel = opt
            paint()
            fire(o.Callback, opt)
        end)
        b.MouseEnter:Connect(function()
            if opt ~= sel then tween(b, 0.15, { BackgroundTransparency = 0.25 }, SINE) end
        end)
        b.MouseLeave:Connect(function()
            if opt ~= sel then tween(b, 0.2, { BackgroundTransparency = 0.4 }, SINE) end
        end)
    end
    paint()
    onTheme(paint)

    local api = {}
    function api:Get() return sel end
    function api:Set(v) if buttons[v] then sel = v paint() fire(o.Callback, v) end end
    api.Export = function() return sel end
    api.Import = function(v) api:Set(v) end
    return register(o, api)
end

--// ------------------------------------------------------------------ CONFIG
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
    for f, v in pairs(data) do
        local a = Lib.Flags[f]
        if a and a.Import then pcall(a.Import, v) end
    end
    return true
end

function Window:SaveConfig(name)
    if not writefile then return false end
    pcall(function() if makefolder and isfolder and not isfolder(self.Folder) then makefolder(self.Folder) end end)
    return (pcall(writefile, self.Folder .. "/" .. tostring(name):gsub("[^%w_%- ]", "") .. ".json", self:ExportString()))
end

function Window:LoadConfig(name)
    if not (readfile and isfile) then return false end
    local path = self.Folder .. "/" .. tostring(name):gsub("[^%w_%- ]", "") .. ".json"
    if not isfile(path) then return false end
    local ok, s = pcall(readfile, path)
    return ok and self:ImportString(s)
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

return Lib