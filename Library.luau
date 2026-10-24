--// FEMBOYSENSE LIBRARY v2  (spring animations, sliding indicators, animated popups)
local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UIS            = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local HttpService    = game:GetService("HttpService")
local Lighting       = game:GetService("Lighting")
local Workspace      = game:GetService("Workspace")
local LP = Players.LocalPlayer
local SINE, QUINT, BACK, EXPO, LINEAR = Enum.EasingStyle.Sine, Enum.EasingStyle.Quint, Enum.EasingStyle.Back,
    Enum.EasingStyle.Exponential, Enum.EasingStyle.Linear
local OUT, IN = Enum.EasingDirection.Out, Enum.EasingDirection.In

local Lib = { Flags = {}, ThemeName = "Lavender Dark", Windows = {} }
local Window, Tab = {}, {}
Window.__index, Tab.__index = Window, Tab

--// ---------------------------------------------------------------- THEMES
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

--// ---------------------------------------------------------------- HELPERS
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
        TextXAlignment = align or Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
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
Lib.U = { new = new, corner = corner, stroke = stroke, label = label, tween = tween, onTheme = onTheme, fire = fire }

local function ripple(card, input, W)
    local sc = math.max(W.Scale.Scale, 0.05)
    local rel = (Vector2.new(input.Position.X, input.Position.Y) - card.AbsolutePosition) / sc
    local r = new("Frame", { Parent = card, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(rel.X, rel.Y),
        Size = UDim2.fromOffset(0, 0), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.78, BorderSizePixel = 0,
        ZIndex = 0 }, { corner(500) })
    tween(r, 0.7, { Size = UDim2.fromOffset(420, 420), BackgroundTransparency = 1 }, QUINT)
    task.delay(0.75, function() r:Destroy() end)
end

--// ---------------------------------------------------------------- NOTIFY
function Lib:Notify(title, text, dur, color)
    local h = Lib._notif
    if not (h and h.Parent) then return end
    dur = dur or 3
    color = color or Theme.Accent
    local wrap = new("Frame", { Parent = h, Size = UDim2.fromOffset(290, 66), BackgroundTransparency = 1 })
    local card = new("TextButton", { Parent = wrap, Position = UDim2.fromOffset(330, 0), Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = "@Panel", BorderSizePixel = 0, Text = "", AutoButtonColor = false, ClipsDescendants = true },
        { corner(14), stroke(color, 1.2, 0.5) })
    new("Frame", { Parent = card, Position = UDim2.fromOffset(0, 14), Size = UDim2.fromOffset(3, 34), BackgroundColor3 = color,
        BorderSizePixel = 0 }, { corner(2) })
    label(card, tostring(title or ""), UDim2.fromOffset(16, 9), UDim2.new(1, -28, 0, 18), Enum.Font.GothamBold, 13, "@Text")
    label(card, tostring(text or ""), UDim2.fromOffset(16, 29), UDim2.new(1, -28, 0, 20), Enum.Font.Gotham, 12, "@Sub")
    local bar = new("Frame", { Parent = card, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = color, BackgroundTransparency = 0.25, BorderSizePixel = 0 })
    tween(card, 0.6, { Position = UDim2.fromOffset(0, 0) }, BACK)
    tween(bar, dur, { Size = UDim2.new(0, 0, 0, 2) }, LINEAR)
    local closed = false
    local function close()
        if closed then return end
        closed = true
        tween(card, 0.4, { Position = UDim2.fromOffset(330, 0) }, QUINT, IN)
        task.wait(0.3)
        tween(wrap, 0.25, { Size = UDim2.fromOffset(290, 0) }, QUINT)
        task.wait(0.3)
        wrap:Destroy()
    end
    card.MouseButton1Click:Connect(function() task.spawn(close) end)
    task.delay(dur, function() if wrap.Parent then close() end end)
end

--// ---------------------------------------------------------------- WINDOW
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
        Size = UDim2.fromOffset(290, 500), BackgroundTransparency = 1, ZIndex = 100 },
        { new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })

    W.Root = new("Frame", { Parent = W.Gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(WIDTH, HEIGHT), BackgroundTransparency = 1 })
    W.Scale = new("UIScale", { Parent = W.Root, Scale = 1 })

    W.Main = new("CanvasGroup", { Parent = W.Root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = "@Outer",
        BorderSizePixel = 0, GroupTransparency = 1 }, { corner(26), stroke("@Line", 1.2, 0.3) })
    W.Pop = new("UIScale", { Parent = W.Main, Scale = 0.86 })
    table.insert(W.GlassPanels, { W.Main, 0, 0.3 })

    --// sidebar
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
    label(logoArea, string.upper(o.Title or "FEMBOYSENSE"), UDim2.fromOffset(60, 20), UDim2.fromOffset(142, 22), Enum.Font.GothamBlack, 15, "@Text")
    label(logoArea, string.upper(o.Subtitle or "HUB"), UDim2.fromOffset(60, 42), UDim2.fromOffset(142, 14), Enum.Font.GothamMedium, 9, "@Sub")

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

    --// topbar
    local topW = WIDTH - 244
    local top = new("Frame", { Parent = W.Main, Position = UDim2.fromOffset(232, 12), Size = UDim2.fromOffset(topW, 56),
        BackgroundColor3 = "@Panel", BorderSizePixel = 0 }, { corner(18), stroke("@Line", 1, 0.5) })
    table.insert(W.GlassPanels, { top, 0, 0.35 })
    local pill = new("Frame", { Parent = top, Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(180, 40),
        BackgroundColor3 = "@Content", BorderSizePixel = 0 }, { corner(12), stroke("@Line", 1, 0.6) })
    local dotp = new("Frame", { Parent = pill, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(21, 20),
        Size = UDim2.fromOffset(10, 10), BackgroundColor3 = "@Accent", BorderSizePixel = 0 }, { corner(5) })
    W.StatusDot = dotp
    label(pill, o.Version or "1.0", UDim2.fromOffset(40, 0), UDim2.fromOffset(80, 40), Enum.Font.GothamBold, 14, "@Text")
    label(pill, string.upper(o.Tag or "HUB"), UDim2.new(1, -66, 0, 0), UDim2.fromOffset(54, 40), Enum.Font.GothamMedium, 9, "@Sub", Enum.TextXAlignment.Right)

    local searchBack = new("Frame", { Parent = top, Position = UDim2.fromOffset(206, 8), Size = UDim2.fromOffset(330, 40),
        BackgroundColor3 = "@Content", BorderSizePixel = 0 }, { corner(12) })
    local sStroke = stroke("@Line", 1, 0.6)
    sStroke.Parent = searchBack
    new("Frame", { Parent = searchBack, Position = UDim2.fromOffset(14, 12), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1 },
        { corner(6), stroke("@Sub", 1.5) })
    new("Frame", { Parent = searchBack, Position = UDim2.fromOffset(24, 25), Size = UDim2.fromOffset(6, 2), Rotation = 45,
        BackgroundColor3 = "@Sub", BorderSizePixel = 0 })
    W.Search = new("TextBox", { Parent = searchBack, Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -50, 1, 0),
        BackgroundTransparency = 1, PlaceholderText = o.SearchText or "Search modules...", PlaceholderColor3 = "@Sub", Text = "",
        TextColor3 = "@Text", Font = Enum.Font.GothamMedium, TextSize = 13, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left })
    W.Search:GetPropertyChangedSignal("Text"):Connect(function() W:_filter(W.Search.Text) end)
    W.Search.Focused:Connect(function()
        tween(sStroke, 0.3, { Color = Theme.Accent, Transparency = 0.05, Thickness = 1.6 }, SINE)
        tween(searchBack, 0.35, { Size = UDim2.fromOffset(380, 40) }, BACK)
    end)
    W.Search.FocusLost:Connect(function()
        tween(sStroke, 0.35, { Color = Theme.Line, Transparency = 0.6, Thickness = 1 }, SINE)
        tween(searchBack, 0.35, { Size = UDim2.fromOffset(330, 40) }, QUINT)
    end)

    local sett = new("TextButton", { Parent = top, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8),
        Size = UDim2.fromOffset(40, 40), BackgroundColor3 = "@Content", Text = "", AutoButtonColor = false, BorderSizePixel = 0 },
        { corner(12), stroke("@Line", 1, 0.6) })
    local gear = new("Frame", { Parent = sett, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1 }, { corner(8), stroke("@Text", 1.6) })
    sett.MouseEnter:Connect(function()
        tween(sett, 0.25, { BackgroundColor3 = Theme.Card2 }, SINE)
        tween(gear, 0.6, { Rotation = 180 }, BACK)
    end)
    sett.MouseLeave:Connect(function()
        tween(sett, 0.3, { BackgroundColor3 = Theme.Content }, SINE)
        tween(gear, 0.5, { Rotation = 0 }, QUINT)
    end)
    sett.MouseButton1Click:Connect(function()
        if o.OnSettings then fire(o.OnSettings) return end
        local t = W:GetTab("Settings")
        if t then W:Select(t) end
    end)

    --// content
    local CH = HEIGHT - 76 - 40
    W.Content = new("Frame", { Parent = W.Main, Position = UDim2.fromOffset(232, 76), Size = UDim2.fromOffset(topW, CH),
        BackgroundColor3 = "@Content", BorderSizePixel = 0, ClipsDescendants = true }, { corner(18), stroke("@Line", 1, 0.6) })
    table.insert(W.GlassPanels, { W.Content, 0, 0.5 })
    W.Title = label(W.Content, "", UDim2.fromOffset(22, 14), UDim2.fromOffset(380, 30), Enum.Font.GothamBold, 24, "@Text")
    W.Sub = label(W.Content, "", UDim2.fromOffset(22, 48), UDim2.fromOffset(440, 16), Enum.Font.Gotham, 12, "@Sub")

    new("TextLabel", { Parent = W.Main, Position = UDim2.fromOffset(240, HEIGHT - 32), Size = UDim2.fromOffset(400, 16),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 9, TextColor3 = "@Sub",
        TextXAlignment = Enum.TextXAlignment.Left, AutoLocalize = false,
        Text = string.upper(keyName(W.Key) .. "  ·  CLOSE  ·  DRAG TOPBAR  ·  MOVE") })
    label(W.Main, string.upper(o.Title or "FEMBOYSENSE") .. " " .. string.upper(o.Subtitle or "HUB"),
        UDim2.new(1, -250, 1, -32), UDim2.fromOffset(230, 16), Enum.Font.GothamMedium, 9, "@Sub", Enum.TextXAlignment.Right)

    --// drag
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

    --// input / keybinds
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

    --// loop: autoscale + animated logo
    conn(RunService.RenderStepped:Connect(function()
        W.Scale.Scale = W:_scale()
        if W.Open then
            local t = os.clock()
            for i, b in ipairs(W.LogoBars) do
                local h = b[2] * (0.7 + 0.3 * math.sin(t * 2.6 + i * 1.3))
                b[1].Size = UDim2.fromOffset(6, h)
            end
            W.StatusDot.BackgroundTransparency = 0.5 - 0.5 * math.sin(t * 3)
        end
    end))
    W.Blur = new("BlurEffect", { Parent = Lighting, Size = 0 })
    task.defer(function()
        tween(W.Pop, 0.8, { Scale = 1 }, BACK)
        tween(W.Main, 0.5, { GroupTransparency = 0 }, QUINT)
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
    if self.Blur then tween(self.Blur, 0.4, { Size = (self.Glass and self.Open) and (self.GlassBlur * 0.5) or 0 }, SINE) end
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

function Window:Toggle(force)
    if force ~= nil then self.Open = force else self.Open = not self.Open end
    if self.Open then
        self.Root.Visible = true
        self.Pop.Scale = 0.88
        tween(self.Pop, 0.6, { Scale = 1 }, BACK)
        tween(self.Main, 0.35, { GroupTransparency = 0 }, QUINT)
    else
        self:_closePopup()
        tween(self.Pop, 0.3, { Scale = 0.9 }, QUINT, IN)
        tween(self.Main, 0.28, { GroupTransparency = 1 }, QUINT)
        task.delay(0.32, function() if not self.Open then self.Root.Visible = false end end)
    end
    self:_blur()
end
function Window:Notify(t, x, d, c) Lib:Notify(t, x, d, c) end
function Window:Destroy()
    self:_closePopup()
    for _, c in ipairs(self.Conns) do pcall(function() c:Disconnect() end) end
    if self.Blur then self.Blur:Destroy() end
    self.Gui:Destroy()
end

--// popups (animated)
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

--// tabs / search
function Window:GetTab(name) for _, t in ipairs(self.Tabs) do if t.Name == name then return t end end end

function Window:AddTab(name, opts)
    if type(opts) == "string" then opts = { Sub = opts } end
    opts = opts or {}
    local W = self
    local idx = #W.Tabs + 1

    local btn = new("TextButton", { Parent = W.TabList, LayoutOrder = idx, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, BorderSizePixel = 0 })
    local paint
    local icon = opts.Icon
    if type(icon) == "number" then icon = "rbxassetid://" .. icon end
    if type(icon) == "string" and icon ~= "" then
        local img = new("ImageLabel", { Parent = btn, Position = UDim2.fromOffset(14, 10), Size = UDim2.fromOffset(20, 20),
            BackgroundTransparency = 1, Image = icon, ImageColor3 = Theme.Sub })
        paint = function(c) tween(img, 0.3, { ImageColor3 = c }, SINE) end
    else
        local box = new("Frame", { Parent = btn, Position = UDim2.fromOffset(15, 11), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1 }, { corner(5) })
        local s = stroke(Theme.Sub, 1.6)
        s.Parent = box
        paint = function(c) tween(s, 0.3, { Color = c }, SINE) end
    end
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
        tween(t.NameLabel, 0.3, { TextColor3 = on and Theme.Text or Theme.Sub }, SINE)
        t.paint(on and Theme.Text or Theme.Sub)
        if t.SegmentFrame then t.SegmentFrame.Visible = on end
    end
    local ind = self.Indicator
    local y = (tab.Index - 1) * 44
    if not ind.Visible then
        ind.Position = UDim2.fromOffset(0, y)
        ind.Visible = true
    else
        tween(ind, 0.5, { Position = UDim2.fromOffset(0, y) }, BACK)
    end
    self.Title.Text, self.Sub.Text = tab.Name, tab.Sub
    self.Title.TextTransparency, self.Sub.TextTransparency = 1, 1
    self.Title.Position, self.Sub.Position = UDim2.fromOffset(6, 14), UDim2.fromOffset(6, 48)
    tween(self.Title, 0.5, { TextTransparency = 0, Position = UDim2.fromOffset(22, 14) }, QUINT)
    tween(self.Sub, 0.6, { TextTransparency = 0, Position = UDim2.fromOffset(22, 48) }, QUINT)

    if old then
        local oh = old.Holder
        tween(oh, 0.15, { GroupTransparency = 1 }, SINE)
        task.delay(0.16, function() if self.Current ~= old then oh.Visible = false end end)
    end
    local h = tab.Holder
    h.Position = UDim2.fromOffset(12, 108)
    h.GroupTransparency = 1
    h.Visible = true
    tween(h, 0.55, { Position = UDim2.fromOffset(12, 84), GroupTransparency = 0 }, QUINT)
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

--// ---------------------------------------------------------------- ELEMENT BASE
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
        BackgroundTransparency = W.Glass and 0.25 or 0, ClipsDescendants = true }, { corner(12), st })
    f.MouseEnter:Connect(function()
        tween(f, 0.25, { BackgroundColor3 = hoverColor() }, SINE)
        tween(st, 0.3, { Color = Theme.Accent, Transparency = 0.55 }, SINE)
    end)
    f.MouseLeave:Connect(function()
        tween(f, 0.35, { BackgroundColor3 = Theme.Card }, SINE)
        tween(st, 0.4, { Color = Theme.Line, Transparency = 0.45 }, SINE)
    end)
    table.insert(W.Items, { frame = f, row = row, text = (text or ""):lower(), tab = self })
    table.insert(W.GlassCards, f)
    return f
end

local function rowTexts(card, o, rightPad)
    label(card, o.Name or "Option", UDim2.fromOffset(14, o.Desc and 9 or 0), o.Desc and UDim2.new(1, -rightPad, 0, 18) or UDim2.new(1, -rightPad, 1, 0),
        Enum.Font.GothamMedium, 12, "@Text")
    if o.Desc then label(card, o.Desc, UDim2.fromOffset(14, 28), UDim2.new(1, -rightPad, 0, 14), Enum.Font.Gotham, 10, "@Sub") end
end
local function clickArea(card)
    return new("TextButton", { Parent = card, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2 })
end
local function register(o, api) if o.Flag then Lib.Flags[o.Flag] = api end return api end

--// ---------------------------------------------------------------- ELEMENTS
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
    local W = self.Window
    local card = self:_card(o.Desc and 54 or 44, o, (o.Name or "") .. " " .. (o.Desc or ""))
    rowTexts(card, o, 120)
    local p = new("Frame", { Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(74, 26),
        BackgroundColor3 = "@Accent", BorderSizePixel = 0 }, { corner(9) })
    new("UIGradient", { Parent = p, Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 190)),
        Transparency = NumberSequence.new(0.88, 0.7) })
    new("TextLabel", { Parent = p, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = o.ButtonText or "RUN",
        Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.new(1, 1, 1), AutoLocalize = false })
    local sc = new("UIScale", { Parent = p })
    local hit = clickArea(card)
    hit.InputBegan:Connect(function(i)
        if isPress(i) then tween(sc, 0.12, { Scale = 0.88 }, QUINT) ripple(card, i, W) end
    end)
    hit.InputEnded:Connect(function(i) if isPress(i) then tween(sc, 0.45, { Scale = 1 }, BACK) end end)
    hit.MouseButton1Click:Connect(function() fire(o.Callback) end)
    return { Frame = card }
end

function Tab:AddToggle(o)
    local W = self.Window
    local state = o.Default == true
    local hasBind = o.Keybind ~= nil and o.Keybind ~= false
    local card = self:_card(o.Desc and 54 or 44, o, (o.Name or "") .. " " .. (o.Desc or ""))
    rowTexts(card, o, hasBind and 140 or 80)
    local track = new("Frame", { Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(40, 22),
        BackgroundColor3 = state and Theme.Accent or Theme.Off, BorderSizePixel = 0 }, { corner(11), stroke("@Line", 1, 0.4) })
    local knob = new("Frame", { Parent = track, Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = "@Knob", BorderSizePixel = 0 }, { corner(8) })
    local function render(anim)
        local d = anim and 1 or 0.01
        tween(track, 0.3 * d + 0.01, { BackgroundColor3 = state and Theme.Accent or Theme.Off }, SINE)
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
    local hit = clickArea(card)
    hit.InputBegan:Connect(function(i) if isPress(i) then ripple(card, i, W) end end)
    hit.MouseButton1Click:Connect(function() api:Set(not state) end)

    local bind
    if hasBind then
        bind = { Key = (typeof(o.Keybind) == "EnumItem") and o.Keybind or nil, Mode = "Press",
            Press = function(down) if down then api:Set(not state) end end }
        table.insert(W.Binds, bind)
        local pillB = new("TextButton", { Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -62, 0.5, 0), Size = UDim2.fromOffset(60, 24),
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

function Tab:AddSlider(o)
    local W = self.Window
    local min, max, step = o.Min or 0, o.Max or 100, o.Step or 1
    local digits = step >= 1 and 0 or math.max(0, -math.floor(math.log10(step) + 1e-9))
    local value = math.clamp(o.Default or min, min, max)
    local card = self:_card(58, o, o.Name)
    label(card, o.Name or "Slider", UDim2.fromOffset(14, 9), UDim2.new(1, -90, 0, 16), Enum.Font.GothamMedium, 12, "@Text")
    local vl = label(card, "", UDim2.new(1, -94, 0, 9), UDim2.fromOffset(80, 16), Enum.Font.GothamMedium, 11, "@Accent", Enum.TextXAlignment.Right)
    local bar = new("Frame", { Parent = card, Position = UDim2.fromOffset(14, 38), Size = UDim2.new(1, -28, 0, 4), BackgroundColor3 = "@Card2", BorderSizePixel = 0 }, { corner(2) })
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
    local hit = new("TextButton", { Parent = card, Position = UDim2.fromOffset(6, 28), Size = UDim2.new(1, -12, 0, 28), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, ZIndex = 3 })
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

function Tab:AddDropdown(o)
    local W = self.Window
    local opts = o.Options or {}
    local selected = o.Default or opts[1]
    local card = self:_card(44, o, (o.Name or "") .. " " .. table.concat(opts, " "))
    label(card, o.Name or "Dropdown", UDim2.fromOffset(14, 0), UDim2.new(1, -150, 1, 0), Enum.Font.GothamMedium, 12, "@Text")
    local vl = label(card, tostring(selected), UDim2.new(1, -150, 0, 0), UDim2.fromOffset(120, 44), Enum.Font.Gotham, 10, "@Sub", Enum.TextXAlignment.Right)
    local arrow = label(card, ">", UDim2.new(1, -24, 0, 0), UDim2.fromOffset(12, 44), Enum.Font.GothamBold, 11, "@Sub", Enum.TextXAlignment.Center)
    arrow.Rotation = 90
    local api = {}
    local function choose(v, silent)
        selected = v
        vl.Text = tostring(v)
        if not silent then fire(o.Callback, v) end
    end
    local hit = clickArea(card)
    hit.InputBegan:Connect(function(i) if isPress(i) then ripple(card, i, W) end end)
    hit.MouseButton1Click:Connect(function()
        if W._pop then W:_closePopup() tween(arrow, 0.3, { Rotation = 90 }, QUINT) return end
        local width = math.max(card.AbsoluteSize.X / math.max(W.Scale.Scale, 0.05), 170)
        local h = math.min(#opts, 7) * 30 + 12
        tween(arrow, 0.35, { Rotation = 270 }, BACK)
        local pop = W:_popup(card, width, h, function(frame)
            local sc = new("ScrollingFrame", { Parent = frame, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12), BackgroundTransparency = 1,
                BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = "@Accent", CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 52 }, { new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })
            for i, opt in ipairs(opts) do
                local on = opt == selected
                local b = new("TextButton", { Parent = sc, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = "@Card2",
                    BackgroundTransparency = on and 0.3 or 1, Text = "  " .. tostring(opt), TextColor3 = on and Theme.Accent or Theme.Text,
                    Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 52,
                    BorderSizePixel = 0 }, { corner(8) })
                b.MouseEnter:Connect(function() tween(b, 0.15, { BackgroundTransparency = 0.3 }, SINE) end)
                b.MouseLeave:Connect(function() tween(b, 0.2, { BackgroundTransparency = (opt == selected) and 0.3 or 1 }, SINE) end)
                b.MouseButton1Click:Connect(function() choose(opt) W:_closePopup() tween(arrow, 0.3, { Rotation = 90 }, QUINT) end)
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

function Tab:AddTextbox(o)
    local card = self:_card(44, o, o.Name)
    label(card, o.Name or "Textbox", UDim2.fromOffset(14, 0), UDim2.new(1, -190, 1, 0), Enum.Font.GothamMedium, 12, "@Text")
    local back = new("Frame", { Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(160, 28),
        BackgroundColor3 = "@Content", BorderSizePixel = 0 }, { corner(9) })
    local bs = stroke("@Line", 1.2, 0.2)
    bs.Parent = back
    local box = new("TextBox", { Parent = back, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), BackgroundTransparency = 1,
        PlaceholderText = o.Placeholder or "", PlaceholderColor3 = "@Sub", Text = o.Default or "", TextColor3 = "@Text",
        Font = Enum.Font.GothamMedium, TextSize = 11, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left })
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

function Tab:AddKeybind(o)
    local W = self.Window
    local state, bind = false, nil
    local card = self:_card(o.Desc and 54 or 44, o, (o.Name or "") .. " " .. (o.Desc or ""))
    rowTexts(card, o, 170)
    bind = { Key = o.Default, Mode = o.Mode or "Press", Press = function(down)
        if bind.Mode == "Press" then if down then fire(o.Callback) end
        elseif bind.Mode == "Toggle" then if down then state = not state fire(o.Callback, state) end
        else state = down fire(o.Callback, down) end
    end }
    table.insert(W.Binds, bind)
    local modeL = label(card, string.upper(bind.Mode), UDim2.new(1, -172, 0, 0), UDim2.fromOffset(50, 44), Enum.Font.GothamBold, 9, "@Sub", Enum.TextXAlignment.Right)
    local pillB = new("TextButton", { Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(92, 26),
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

function Tab:AddColorPicker(o)
    local W = self.Window
    local col = o.Default or Color3.new(1, 1, 1)
    local card = self:_card(o.Desc and 54 or 44, o, (o.Name or "") .. " " .. (o.Desc or ""))
    rowTexts(card, o, 80)
    local sw = new("Frame", { Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(40, 22),
        BackgroundColor3 = col, BorderSizePixel = 0 }, { corner(8), stroke("@Line", 1, 0.2) })
    local api = {}
    local function setColor(c, silent)
        col = c
        tween(sw, 0.2, { BackgroundColor3 = c }, SINE)
        if not silent then fire(o.Callback, c) end
    end
    local hit = clickArea(card)
    hit.InputBegan:Connect(function(i) if isPress(i) then ripple(card, i, W) end end)
    hit.MouseButton1Click:Connect(function()
        if W._pop then W:_closePopup() return end
        W:_popup(card, 224, 176, function(frame, pop)
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
            local function refresh()
                local c = Color3.fromHSV(h, s, v)
                svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                svKnob.Position = UDim2.fromScale(s, 1 - v)
                hueKnob.Position = UDim2.fromScale(h, 0.5)
                hex.Text = string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
                col = c
                sw.BackgroundColor3 = c
                fire(o.Callback, c)
            end
            svKnob.Position = UDim2.fromScale(s, 1 - v)
            hueKnob.Position = UDim2.fromScale(h, 0.5)
            hex.Text = string.format("#%02X%02X%02X", math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5))
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
    api.Export = function() return { math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5) } end
    api.Import = function(v) if type(v) == "table" and #v == 3 then setColor(rgb(v[1], v[2], v[3])) end end
    return register(o, api)
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

--// ---------------------------------------------------------------- CONFIG
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

return Lib