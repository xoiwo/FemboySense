-- FEMBOYSENSE — KEY LIB  v1.1  (UIShadow edition)

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Lighting     = game:GetService("Lighting")
local GuiService   = game:GetService("GuiService")
local TextService  = game:GetService("TextService")
local LocalPlayer  = Players.LocalPlayer

local rgb, WHITE = Color3.fromRGB, Color3.new(1, 1, 1)
local V2  = Vector2.new
local sin, clamp = math.sin, math.clamp
local SINE, QUINT, BACK, LIN = Enum.EasingStyle.Sine, Enum.EasingStyle.Quint, Enum.EasingStyle.Back, Enum.EasingStyle.Linear
local OUT, IN = Enum.EasingDirection.Out, Enum.EasingDirection.In

local Lib = {
    Version = "v1.1",
    Flags   = {},
    Speed   = 1,
    Semantic = {
        Green  = rgb(70, 225, 125),
        Yellow = rgb(255, 190, 60),
        Red    = rgb(255, 70, 70),
    },
}

local DARK = {
    Bg = rgb(8, 8, 10), Side = rgb(17, 17, 20), Panel = rgb(26, 26, 30), Panel2 = rgb(40, 40, 46),
    Text = rgb(244, 244, 247), Sub = rgb(146, 146, 154), Stroke = WHITE, StrokeT = 0.93,
}
local LIGHT = {
    Bg = rgb(232, 232, 238), Side = rgb(246, 246, 250), Panel = rgb(255, 255, 255), Panel2 = rgb(233, 233, 240),
    Text = rgb(22, 22, 27), Sub = rgb(108, 108, 120), Stroke = Color3.new(0, 0, 0), StrokeT = 0.92,
}
local THEMES = {
    { Name = "Mono",     Mode = "Dark", Accent = rgb(227, 228, 230) },
    { Name = "Lavender", Mode = "Dark", Accent = rgb(184, 160, 237) },
    { Name = "Midnight", Mode = "Dark", Accent = rgb(145, 175, 229) },
    { Name = "Rose",     Mode = "Dark", Accent = rgb(229, 165, 188) },
    { Name = "Crimson",  Mode = "Dark", Accent = rgb(255, 40, 60), Accent2 = rgb(140, 12, 28),
      Colors = { Bg = rgb(10, 8, 10), Side = rgb(15, 9, 12), Panel = rgb(24, 17, 19), Panel2 = rgb(34, 22, 25) } },
    { Name = "Ocean",    Mode = "Dark", Accent = rgb(56, 189, 248), Accent2 = rgb(12, 74, 110),
      Colors = { Bg = rgb(7, 10, 15), Side = rgb(10, 15, 22), Panel = rgb(16, 23, 33), Panel2 = rgb(24, 34, 48) } },
    { Name = "Violet",   Mode = "Dark", Accent = rgb(168, 85, 247), Accent2 = rgb(76, 29, 149),
      Colors = { Bg = rgb(10, 8, 14), Side = rgb(14, 10, 20), Panel = rgb(21, 17, 31), Panel2 = rgb(31, 24, 45) } },
    { Name = "Emerald",  Mode = "Dark", Accent = rgb(52, 211, 153), Accent2 = rgb(6, 78, 59),
      Colors = { Bg = rgb(7, 12, 10), Side = rgb(9, 16, 13), Panel = rgb(15, 25, 21), Panel2 = rgb(22, 36, 30) } },
}
Lib.Themes = THEMES
local Theme = {}

local function loadTheme(def)
    local base = def.Mode == "Light" and LIGHT or DARK
    for k, v in pairs(base) do Theme[k] = v end
    if def.Colors then for k, v in pairs(def.Colors) do Theme[k] = v end end
    Theme.Accent   = def.Accent
    Theme.Accent2  = def.Accent2 or (def.Mode == "Light" and def.Accent:Lerp(WHITE, 0.4) or def.Accent:Lerp(rgb(0, 0, 0), 0.58))
    Theme.OnAccent = def.Mode == "Light" and WHITE or rgb(12, 12, 14)
end
loadTheme(THEMES[2])
Lib.Theme = Theme

local function kp(t, c) return ColorSequenceKeypoint.new(t, c) end
local function nk(t, v) return NumberSequenceKeypoint.new(t, v) end

local RING_T = NumberSequence.new({
    nk(0, 0.88), nk(0.12, 0.05), nk(0.3, 0.88),
    nk(0.5, 0.88), nk(0.62, 0.05), nk(0.8, 0.88), nk(1, 0.88),
})

local function gradColor(kind)
    local A, A2 = Theme.Accent, Theme.Accent2
    if kind == "ring" then
        return ColorSequence.new({ kp(0, A2), kp(0.12, A), kp(0.3, A2), kp(0.5, A2), kp(0.62, A), kp(0.8, A2), kp(1, A2) })
    elseif kind == "lin" then return ColorSequence.new(A2, A)
    elseif kind == "shine" then return ColorSequence.new({ kp(0, Theme.Text), kp(0.5, A), kp(1, Theme.Text) })
    elseif kind == "tri" then return ColorSequence.new({ kp(0, A2), kp(0.5, A), kp(1, A2) })
    elseif kind == "green" then return ColorSequence.new({ kp(0, Lib.Semantic.Green), kp(1, Lib.Semantic.Green) })
    elseif kind == "red" then return ColorSequence.new({ kp(0, Lib.Semantic.Red), kp(1, Lib.Semantic.Red) })
    end
    return ColorSequence.new(A, A2)
end
Lib.GradColor = gradColor

local reg, hooks, conns = {}, {}, {}
local grads, spinners, shimmers = {}, {}, {}
local shadowList, staticShadows = {}, {}
local ShadowCfg = { Enabled = true, Mul = 1, Behind = false }

local function keep(c) table.insert(conns, c) return c end
local function onTheme(fn) table.insert(hooks, fn) fn(true) end
Lib._keep, Lib._onTheme = keep, onTheme

local function tw(obj, t, props, style, dir)
    local tr = TweenService:Create(obj, TweenInfo.new(math.max(t / Lib.Speed, 0.01), style or QUINT, dir or OUT), props)
    tr:Play()
    return tr
end
Lib._tw = tw

local function B(key) return { __bind = key } end

local function bind(obj, prop, key)
    obj[prop] = Theme[key]
    table.insert(reg, { obj, prop, key })
end
Lib._bind = bind

local function applyTheme(def, instant)
    loadTheme(def)
    for i = #reg, 1, -1 do
        local e = reg[i]
        local o = e[1]
        if o.Parent then
            if not instant then pcall(function() tw(o, 0.35, { [e[2]] = Theme[e[3]] }, SINE) end)
            else pcall(function() o[e[2]] = Theme[e[3]] end) end
        else table.remove(reg, i) end
    end
    for i = #grads, 1, -1 do
        local g = grads[i]
        if g[1].Parent then g[1].Color = gradColor(g[2]) else table.remove(grads, i) end
    end
    for _, f in ipairs(hooks) do task.spawn(pcall, f) end
end
Lib.ApplyTheme = applyTheme

local function new(class, props, kids)
    local o = Instance.new(class)
    if o:IsA("GuiObject") then o.BorderSizePixel = 0 end
    local isText = o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")
    if isText then o.AutoLocalize = false o.Font = Enum.Font.GothamMedium end
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
Lib._new = new

local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function stk(th)
    return new("UIStroke", {
        Color = B"Stroke", Transparency = B"StrokeT",
        Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
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
        Parent = parent, Text = text,
        Position = pos or UDim2.new(), Size = size or UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Font = font or Enum.Font.GothamMedium,
        TextSize = ts or 13, TextColor3 = color or B"Text",
        TextXAlignment = align or Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    for k, v in pairs(extra or {}) do l[k] = v end
    return l
end
local function plainStroke(color, th, tr)
    return new("UIStroke", {
        Color = color, Thickness = th or 1, Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i)  return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

Lib._corner, Lib._stk, Lib._label, Lib._plainStroke = corner, stk, label, plainStroke
Lib._isPress, Lib._isMove = isPress, isMove

local function guiParent()
    if gethui then local ok, h = pcall(gethui) if ok and h then return h end end
    return LocalPlayer:WaitForChild("PlayerGui")
end
Lib._guiParent = guiParent

function Lib.Grad(parent, kind, rot)
    local g = new("UIGradient", { Color = gradColor(kind), Rotation = rot or 0, Parent = parent })
    if kind == "ring" then g.Transparency = RING_T end
    table.insert(grads, { g, kind })
    return g
end

function Lib.Spin(g, speed, cond)
    local e = { g, speed, cond }
    table.insert(spinners, e)
    return e
end

function Lib.Shimmer(g) table.insert(shimmers, g) return g end

local function makeShadow(parent, o)
    o = o or {}
    local ok, sh = pcall(Instance.new, "UIShadow")
    if not ok or not sh then return nil end
    pcall(function()
        sh.Mode = Enum.ApplyShadowMode.Shape
        sh.Inset = false
        sh.ShowBehindParent = o.Behind == true
        sh.ZIndex = -math.max(1, math.abs(o.ZIndex or 1))
        sh.BlurRadius = UDim.new(0, o.Blur or 20)
        sh.Spread = UDim2.fromOffset(o.Spread or 0, o.Spread or 0)
        sh.Offset = UDim2.fromOffset(o.OffX or 0, o.OffY or 0)
        sh.Color = o.Color or Theme.Accent2
        sh.Transparency = o.Transparency or 0.8
    end)
    pcall(function() sh.Parent = parent end)
    return sh
end
Lib._makeShadow = makeShadow

local function setAllShadows(fn)
    for _, e in ipairs(staticShadows) do pcall(fn, e) end
    for _, e in ipairs(shadowList)   do pcall(fn, e) end
end

function Lib.SetShadows(on)
    ShadowCfg.Enabled = on and true or false
    setAllShadows(function(e)
        if e.Apply then e:Apply()
        elseif e.Shadow then e.Shadow.Enabled = ShadowCfg.Enabled end
    end)
end

function Lib.SetShadowIntensity(v)
    ShadowCfg.Mul = v or 1
    for _, e in ipairs(staticShadows) do if e.Apply then e:Apply() end end
end

function Lib.SetShadowBehind(on)
    ShadowCfg.Behind = on and true or false
    setAllShadows(function(e)
        if e.Shadow then pcall(function() e.Shadow.ShowBehindParent = ShadowCfg.Behind end) end
    end)
end

local function animatedShadow(target, o)
    o = o or {}
    local e = {
        Target = target, Spread = o.Size or 36, Alpha = o.Alpha or 0.07,
        Speed = o.Speed or 1.6, Phase = math.random() * 6,
        H = 0, HT = 0, Vis = 0, OffY = o.OffY or 6,
    }
    e.Shadow = makeShadow(target, {
        Blur = e.Spread * 0.55, OffY = e.OffY,
        ZIndex = o.ZIndex, Transparency = 1, Behind = ShadowCfg.Behind,
    })
    if e.Shadow then e.Shadow.Enabled = false end
    function e:SetHover(on) self.HT = on and 1 or 0 end
    function e:Step(dt, clk)
        local sh, tg = self.Shadow, self.Target
        if not sh then return end
        self.H += (self.HT - self.H) * math.min(dt * 8, 1)
        self.Vis += ((ShadowCfg.Enabled and 1 or 0) - self.Vis) * math.min(dt * 6, 1)
        local show = tg.Parent ~= nil and tg.Visible and self.Vis > 0.02
        if sh.Enabled ~= show then sh.Enabled = show end
        if not show then return end
        local s = sin(clk * self.Speed + self.Phase)
        local h = self.H
        sh.BlurRadius = UDim.new(0, self.Spread * (0.55 + 0.08 * s + h * 0.25))
        local sp = self.Spread * (0.05 + 0.02 * s + h * 0.08)
        sh.Spread = UDim2.fromOffset(sp, sp)
        sh.Offset = UDim2.fromOffset(0, self.OffY * (1 + h * 0.3))
        sh.Transparency = 1 - clamp(self.Alpha * 7 * ShadowCfg.Mul * (0.85 + 0.15 * s) * (1 + h * 0.9) * self.Vis, 0, 0.85)
        sh.Color = Theme.Accent2:Lerp(Theme.Accent, 0.45 + 0.35 * s * 0.5 + h * 0.2)
    end
    table.insert(shadowList, e)
    return e
end

local function staticShadow(target, o)
    o = o or {}
    local e = {
        Target = target, Alpha = o.Alpha or 0.3,
        Key = o.Key or "Accent2", Blur = o.Blur or 16, Hov = false,
    }
    e.Shadow = makeShadow(target, {
        Blur = e.Blur, OffY = o.OffY or 4, Spread = o.Spread or 0,
        ZIndex = o.ZIndex, Transparency = 1, Behind = ShadowCfg.Behind,
    })
    function e:TargetT()
        return 1 - clamp(self.Alpha * ShadowCfg.Mul * (self.Hov and 1.7 or 1), 0, 0.9)
    end
    function e:Apply()
        local sh = self.Shadow
        if not sh then return end
        sh.Enabled = ShadowCfg.Enabled
        sh.Color = Theme[self.Key]
        sh.Transparency = self:TargetT()
    end
    function e:SetHover(on)
        self.Hov = on
        local sh = self.Shadow
        if not sh then return end
        tw(sh, 0.3, {
            Transparency = self:TargetT(),
            BlurRadius = UDim.new(0, self.Blur * (on and 1.35 or 1)),
            Color = on and Theme.Accent or Theme[self.Key],
        }, SINE)
    end
    function e:FadeIn()
        local sh = self.Shadow
        if not sh or not sh.Enabled then return end
        sh.Transparency = 1
        tw(sh, 0.55, { Transparency = self:TargetT() }, SINE)
    end
    table.insert(staticShadows, e)
    e:Apply()
    return e
end

Lib.AnimatedShadow = animatedShadow
Lib.StaticShadow   = staticShadow

onTheme(function()
    for _, e in ipairs(staticShadows) do if e.Apply then e:Apply() end end
end)

local function drag(handle, target, gate)
    local dragging, start, startPos
    handle.InputBegan:Connect(function(i)
        if isPress(i) and not (gate and gate()) then
            dragging, start, startPos = true, i.Position, target.Position
        end
    end)
    keep(UIS.InputChanged:Connect(function(i)
        if dragging and isMove(i) then
            local d = i.Position - start
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end))
    keep(UIS.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end))
end
Lib.Drag = drag

function Lib.Copy(text)
    local fn = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
    if fn then return (pcall(fn, text)) end
    return false
end

function Lib.MaskKey(k)
    if not k or k == "" then return "N/A" end
    if #k <= 4 then return "****" end
    return k:sub(1, 4) .. string.rep("*", math.min(#k - 4, 8))
end

function Lib.HasFile() return (writefile and readfile and isfile) and true or false end

local decorAcc, clockT = 0, 0
local DECOR_STEP = 1 / 30
keep(RunService.RenderStepped:Connect(function(dt)
    decorAcc += dt
    if decorAcc >= DECOR_STEP then
        local d = decorAcc
        decorAcc = 0
        clockT += d
        for i = #spinners, 1, -1 do
            local s = spinners[i]
            local g = s[1]
            if g.Parent then
                if not s[3] or s[3]() then g.Rotation = (g.Rotation + d * s[2]) % 360 end
            else table.remove(spinners, i) end
        end
        for i, g in ipairs(shimmers) do
            if g.Parent then g.Offset = V2(sin(clockT * 1.4 + i) * 0.5, 0) end
        end
        for i = #shadowList, 1, -1 do
            local e = shadowList[i]
            if e.Shadow and not e.Shadow.Parent then
                table.remove(shadowList, i)
            else
                e:Step(d, clockT)
            end
        end
    end
end))

function Lib:CreateApp(cfg)
    cfg = cfg or {}
    local W, H = cfg.Width or 520, cfg.Height or 620
    local unloaders = {}
    local App = {
        Config = cfg,
        Tabs = {},
        Pages = {},
        CurrentTab = nil,
        CurrentPage = nil,
        PageToken = 0,
        Opened = false,
        Destroyed = false,
        ThemeDef = THEMES[2],
    }

    local gui = new("ScreenGui", {
        Name = "FemboysenseKey", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999,
        AutoLocalize = false, Parent = guiParent(),
    })
    App.Gui = gui

    local dim = new("Frame", {
        Parent = gui, Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = rgb(5, 5, 8), BackgroundTransparency = 1, ZIndex = 0,
    })
    App.Dim = dim

    local blur
    local function setBlur(size)
        if size > 0 and not blur then
            blur = Instance.new("BlurEffect") blur.Size = 0 blur.Parent = Lighting
        end
        if blur then tw(blur, 0.5, { Size = size }, SINE) end
    end
    App.SetBlur = setBlur

    local root = new("Frame", {
        Parent = gui, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, ZIndex = 2,
    }, { corner(22) })
    App.Root = root
    local scale = new("UIScale", { Parent = root })
    App.Scale = scale

    local vpSize = V2(1280, 720)
    local function readViewport()
        local cam = workspace.CurrentCamera
        if cam then vpSize = cam.ViewportSize end
    end
    readViewport()
    local function fit()
        return clamp(math.min(vpSize.X / (W + 40), vpSize.Y / (H + 40)), 0.4, 1.3)
    end
    App.Fit = fit
    do
        local cam = workspace.CurrentCamera
        if cam then
            keep(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                readViewport()
                if App.Opened then scale.Scale = fit() end
            end))
        end
    end

    local main = new("Frame", {
        Parent = root, Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = B"Bg", ClipsDescendants = true,
    }, { corner(22) })
    App.Main = main
    main.BackgroundTransparency = cfg.Glass == false and 0.04 or 0.06

    local mainStroke = new("UIStroke", {
        Color = WHITE, Transparency = 0.45, Thickness = 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = main,
    })
    local ringGrad = Lib.Grad(mainStroke, "ring")
    Lib.Spin(ringGrad, 60, function() return App.Opened end)
    App.MainStroke = mainStroke
    App.RingGrad = ringGrad

    App.Shadow     = animatedShadow(root, { Size = 70, Alpha = 0.075, Speed = 1.2, OffY = 10 })
    App.MainShadow = staticShadow(main, { Alpha = 0.4, Blur = 22, OffY = 5, Key = "Accent2", ZIndex = 1 })
    main.MouseEnter:Connect(function() App.MainShadow:SetHover(true)  end)
    main.MouseLeave:Connect(function() App.MainShadow:SetHover(false) end)

    function App.Ripple(obj, input)
        if not obj.Parent then return end
        local ptr
        if input.UserInputType == Enum.UserInputType.Touch then
            ptr = V2(input.Position.X, input.Position.Y) + GuiService:GetGuiInset()
        else
            ptr = UIS:GetMouseLocation()
        end
        local rel = (ptr - obj.AbsolutePosition) / math.max(scale.Scale, 0.05)
        local r = new("Frame", {
            Parent = obj, AnchorPoint = V2(0.5, 0.5),
            Position = UDim2.fromOffset(rel.X, rel.Y),
            Size = UDim2.fromOffset(0, 0),
            BackgroundColor3 = WHITE, BackgroundTransparency = 0.8,
        }, { corner(500) })
        tw(r, 0.9, { Size = UDim2.fromOffset(560, 560), BackgroundTransparency = 1 }, QUINT)
        task.delay(1, function() if r.Parent then r:Destroy() end end)
    end

    function App:Switch(parent, init, callback, pos)
        local state = init and true or false
        local track = new("TextButton", {
            Parent = parent, AnchorPoint = V2(1, 0.5),
            Position = pos or UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(40, 22),
            BackgroundColor3 = Theme.Bg,
        }, { corner(11) })
        local press = new("UIScale", { Parent = track })
        local knob = new("Frame", {
            Parent = track, AnchorPoint = V2(0, 0.5),
            Position = UDim2.new(0, 3, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            BackgroundColor3 = WHITE,
        }, { corner(8) })
        local sw = {}
        local function paint(instant)
            local col = state and Theme.Accent:Lerp(Theme.Panel2, 0.38) or Theme.Bg
            local p = state and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
            if instant then
                track.BackgroundColor3, knob.Position = col, p
            else
                tw(track, 0.25, { BackgroundColor3 = col }, SINE)
                tw(knob, 0.45, { Position = p }, BACK)
            end
        end
        paint(true)
        onTheme(function() paint(false) end)
        function sw:Set(v, silent)
            v = v and true or false
            if v == state then return end
            state = v
            paint(false)
            if not silent and callback then callback(v) end
        end
        function sw:Get() return state end
        track.MouseButton1Down:Connect(function() tw(press, 0.1, { Scale = 0.9 }, SINE) knob.Size = UDim2.fromOffset(20, 16) end)
        track.MouseButton1Up:Connect(function() tw(press, 0.35, { Scale = 1 }, BACK) knob.Size = UDim2.fromOffset(16, 16) end)
        track.MouseButton1Click:Connect(function() sw:Set(not state) end)
        sw.Frame = track
        return sw
    end

    function App:Slider(parent, o)
        local mn, mx, step = o.Min or 0, o.Max or 100, o.Step or 1
        local value = clamp(o.Default or mn, mn, mx)
        local f = new("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1 })
        label(f, o.Name or "Slider", UDim2.new(), UDim2.new(1, -70, 0, 18), Enum.Font.GothamMedium, 13, B"Text")
        local out = label(f, "", UDim2.new(1, 0, 0, 0), UDim2.fromOffset(70, 18), Enum.Font.GothamBold, 12, B"Accent", Enum.TextXAlignment.Right)
        out.AnchorPoint = V2(1, 0)
        local bar = new("Frame", {
            Parent = f, Position = UDim2.new(0, 0, 0, 29),
            Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = B"Bg",
        }, { corner(2) })
        local fill = new("Frame", { Parent = bar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE }, { corner(2) })
        Lib.Grad(fill, "lin")
        local knob = new("Frame", {
            Parent = bar, AnchorPoint = V2(0.5, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromOffset(12, 12), BackgroundColor3 = WHITE, ZIndex = 2,
        }, { corner(6) })
        local function fmt(v)
            if step >= 1 then return string.format("%d", v) end
            return string.format(step < 0.1 and "%.3f" or "%.2f", v):gsub("0+$", ""):gsub("%.$", "")
        end
        local function render(fast)
            local r = (value - mn) / (mx - mn)
            out.Text = fmt(value) .. (o.Suffix or "")
            tw(fill, fast and 0.06 or 0.3, { Size = UDim2.fromScale(r, 1) }, SINE)
            tw(knob, fast and 0.06 or 0.3, { Position = UDim2.fromScale(r, 0.5) }, SINE)
        end
        local api = {}
        local function setv(v, silent, fast)
            v = clamp(math.floor((v - mn) / step + 0.5) * step + mn, mn, mx)
            if v == value then return end
            value = v
            render(fast)
            if not silent and o.Callback then task.spawn(o.Callback, v) end
        end
        render(false)
        local hit = new("TextButton", { Parent = f, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 })
        local dragging = false
        local function fromX(x)
            setv(mn + (mx - mn) * clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1), false, true)
        end
        hit.InputBegan:Connect(function(i)
            if isPress(i) then
                dragging = true
                tw(knob, 0.25, { Size = UDim2.fromOffset(17, 17) }, BACK)
                fromX(i.Position.X)
            end
        end)
        keep(UIS.InputChanged:Connect(function(i) if dragging and isMove(i) then fromX(i.Position.X) end end))
        keep(UIS.InputEnded:Connect(function(i)
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

    function App:Textbox(parent, o)
        local row = new("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1 })
        if o.Name then
            label(row, o.Name, nil, UDim2.new(1, 0, 0, 16), Enum.Font.GothamMedium, 12, B"Sub")
        end
        local back = new("Frame", {
            Parent = row, Position = UDim2.fromOffset(0, o.Name and 20 or 0),
            Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = B"Bg",
        }, { corner(10) })
        local bs = new("UIStroke", { Color = B"Accent", Transparency = 1, Thickness = 1.2, Parent = back })
        local box = new("TextBox", {
            Parent = back, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0),
            BackgroundTransparency = 1, PlaceholderText = o.Placeholder or "",
            PlaceholderColor3 = B"Sub", Text = o.Default or "",
            TextColor3 = B"Text", TextSize = 13, ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        box.Focused:Connect(function() tw(bs, 0.25, { Transparency = 0.4 }, SINE) end)
        box.FocusLost:Connect(function(enter)
            tw(bs, 0.3, { Transparency = 1 }, SINE)
            if o.Callback then task.spawn(o.Callback, box.Text, enter) end
        end)
        local api = {}
        function api:Get() return box.Text end
        function api:Set(v) box.Text = tostring(v) end
        api.Box = box
        api.Frame = row
        return api
    end

    function App:Dropdown(parent, o)
        local opts = o.Options or {}
        local sel  = o.Default or opts[1]
        local ROW, ITEM, MAXV = 28, 26, 7
        local row = new("Frame", {
            Parent = parent, Size = UDim2.new(1, 0, 0, ROW),
            BackgroundTransparency = 1, ClipsDescendants = true,
        })
        label(row, o.Name or "Dropdown", nil, UDim2.new(1, -150, 0, ROW), Enum.Font.GothamMedium, 13, B"Text")
        local selL = label(row, tostring(sel or "-"), UDim2.new(1, -150, 0, 0), UDim2.fromOffset(130, ROW),
            Enum.Font.GothamBold, 12, B"Accent", Enum.TextXAlignment.Right)
        local arrow = label(row, "v", UDim2.new(1, -14, 0, 0), UDim2.fromOffset(14, ROW),
            Enum.Font.GothamBold, 11, B"Sub", Enum.TextXAlignment.Center)
        local list = new("ScrollingFrame", {
            Parent = row, Position = UDim2.fromOffset(0, ROW + 4),
            Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
            ScrollBarThickness = 2, ScrollBarImageColor3 = B"Accent",
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, { new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })

        local open, btns = false, {}
        local function listH() return math.min(#opts, MAXV) * (ITEM + 4) end
        local function setOpen(v)
            open = v
            tw(row, 0.45, { Size = UDim2.new(1, 0, 0, v and (ROW + 4 + listH()) or ROW) }, QUINT)
            tw(list, 0.45, { Size = UDim2.new(1, 0, 0, v and listH() or 0) }, QUINT)
            tw(arrow, 0.35, { Rotation = v and 180 or 0 }, BACK)
        end
        local function paint()
            for name, b in pairs(btns) do
                local on = name == sel
                tw(b, 0.3, {
                    BackgroundColor3 = on and Theme.Accent or Theme.Panel2,
                    TextColor3 = on and Theme.OnAccent or Theme.Sub,
                }, SINE)
            end
        end
        local function choose(v, silent)
            sel = v
            selL.Text = tostring(v)
            paint()
            if not silent and o.Callback then task.spawn(o.Callback, v) end
        end
        local function build()
            for _, b in pairs(btns) do b:Destroy() end
            btns = {}
            for i, name in ipairs(opts) do
                local b = new("TextButton", {
                    Parent = list, LayoutOrder = i, Size = UDim2.new(1, -4, 0, ITEM),
                    BackgroundColor3 = B"Panel2", Text = tostring(name),
                    TextColor3 = B"Sub", Font = Enum.Font.GothamMedium, TextSize = 12,
                }, { corner(8) })
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
            if not table.find(opts, sel) then sel = opts[1] end
            selL.Text = tostring(sel or "-")
            build()
        end
        api.Frame = row
        return api
    end

    function App:Button(parent, text, primary, callback)
        local b = new("TextButton", {
            Parent = parent, Size = UDim2.new(1, 0, 0, 46),
            BackgroundColor3 = primary and Theme.Accent or B"Panel",
            Text = text, TextColor3 = primary and Theme.OnAccent or B"Text",
            Font = Enum.Font.GothamBold, TextSize = 14, ClipsDescendants = true,
        }, { corner(12) })
        local sc = new("UIScale", { Parent = b })
        local border = plainStroke(primary and Theme.Accent or Theme.Accent2, 1.5, primary and 0.1 or 0.5)
        border.Parent = b
        if primary then Lib.Grad(b, "lin", 45) end

        local btnSh = staticShadow(b, {
            Alpha = primary and 0.45 or 0.25,
            Blur = primary and 20 or 12,
            OffY = 4, Key = primary and "Accent" or "Accent2",
        })

        b.MouseEnter:Connect(function()
            tw(sc, 0.3, { Scale = 1.03 }, QUINT)
            tw(border, 0.3, { Transparency = 0.1 }, SINE)
            btnSh:SetHover(true)
        end)
        b.MouseLeave:Connect(function()
            tw(sc, 0.3, { Scale = 1 }, QUINT)
            tw(border, 0.3, { Transparency = primary and 0.1 or 0.5 }, SINE)
            btnSh:SetHover(false)
        end)
        b.MouseButton1Down:Connect(function() tw(sc, 0.1, { Scale = 0.96 }, QUINT) end)
        b.MouseButton1Up:Connect(function() tw(sc, 0.35, { Scale = 1 }, BACK) end)
        b.MouseButton1Click:Connect(function()
            if callback then task.spawn(callback) end
        end)
        onTheme(function()
            if primary then
                b.BackgroundColor3 = Theme.Accent
                b.TextColor3 = Theme.OnAccent
                border.Color = Theme.Accent
            else
                b.BackgroundColor3 = Theme.Panel
                b.TextColor3 = Theme.Text
                border.Color = Theme.Accent2
            end
        end)

        local api = {}
        api.Button = b
        function api:SetText(t) b.Text = tostring(t) end
        function api:Get() return b.Text end
        function api:SetPrimary(p)
            primary = p and true or false
            b.BackgroundColor3 = primary and Theme.Accent or Theme.Panel
            b.TextColor3 = primary and Theme.OnAccent or Theme.Text
            border.Color = primary and Theme.Accent or Theme.Accent2
        end
        return api
    end

    function App:Label(parent, text, o)
        o = o or {}
        local l = label(parent, text,
            o.Position or UDim2.new(),
            o.Size or UDim2.new(1, 0, 0, o.Height or 20),
            o.Font or Enum.Font.GothamMedium,
            o.TextSize or 12,
            o.Color or B"Sub",
            o.Align,
            {
                TextWrapped = o.Wrap ~= false,
                TextYAlignment = o.YAlign or Enum.TextYAlignment.Top,
                TextTruncate = o.Wrap == false and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None,
            })
        local api = {}
        api.Label = l
        function api:Set(t) l.Text = tostring(t) end
        function api:Get() return l.Text end
        return api
    end

    function App:Progress(parent, o)
        o = o or {}
        local f = new("Frame", {
            Parent = parent,
            Size = o.Size or UDim2.new(1, 0, 0, o.Height or 6),
            BackgroundColor3 = B"Panel",
        }, { corner((o.Height or 6) / 2) })
        local fill = new("Frame", {
            Parent = f, Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE,
        }, { corner((o.Height or 6) / 2) })
        local grad = Lib.Grad(fill, "lin")
        staticShadow(f, { Alpha = 0.3, Blur = 14, OffY = 3, Key = "Accent2" })

        local api = {}
        api.Frame = f
        api.Fill = fill
        api.Grad = grad
        function api:Set(p, instant)
            p = clamp(p or 0, 0, 1)
            if instant then fill.Size = UDim2.fromScale(p, 1)
            else tw(fill, 0.5, { Size = UDim2.fromScale(p, 1) }, SINE) end
        end
        function api:SetColor(seq)
            if seq then fill.BackgroundColor3 = WHITE grad.Color = seq end
        end
        function api:Reset()
            grad.Color = gradColor("lin")
            fill.Size = UDim2.fromScale(0, 1)
        end
        function api:AnimateTo(p, duration, style)
            p = clamp(p or 0, 0, 1)
            tw(fill, duration or 0.6, { Size = UDim2.fromScale(p, 1) }, style or SINE)
        end
        return api
    end

    function App:Card(parent, o)
        o = o or {}
        local f = new("Frame", {
            Parent = parent, Size = o.Size or UDim2.new(1, 0, 0, 100),
            BackgroundColor3 = B"Panel", BackgroundTransparency = o.Transparency or 0.05,
        }, { corner(o.Radius or 16), plainStroke(o.StrokeColor or Theme.Accent2, 1, o.StrokeTrans or 0.4) })
        if o.Padding ~= false then
            local p = o.PaddingSize or 14
            pad(p, p, p, p).Parent = f
        end
        if o.Shadow ~= false then
            local sh = staticShadow(f, { Alpha = o.ShadowAlpha or 0.28, Blur = o.ShadowBlur or 14, OffY = 3, Key = "Accent2" })
            f.MouseEnter:Connect(function() sh:SetHover(true)  end)
            f.MouseLeave:Connect(function() sh:SetHover(false) end)
        end
        return f
    end

    --=================================================================
    --  TABS
    --=================================================================
    local tabsBar = new("Frame", {
        Parent = main, Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, ZIndex = 3,
    })
    new("UIListLayout", {
        Parent = tabsBar, FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    pad(0, 0, 16, 100).Parent = tabsBar
    App.TabsBar = tabsBar

    local tabIndicator = new("Frame", {
        Parent = tabsBar, BackgroundColor3 = B"Accent",
        Size = UDim2.fromOffset(0, 3), Position = UDim2.fromOffset(0, 48),
        AnchorPoint = V2(0, 0.5), ZIndex = 4,
    }, { corner(2) })
    App.TabIndicator = tabIndicator

    local pagesHolder = new("Frame", {
        Parent = main, Position = UDim2.fromOffset(0, 56),
        Size = UDim2.new(1, 0, 1, -56), BackgroundTransparency = 1, ZIndex = 2,
    })
    App.PagesHolder = pagesHolder

    local function showPage(name)
        if App.CurrentPage == name then return end
        App.PageToken += 1
        local token = App.PageToken
        local old = App.CurrentPage and App.Pages[App.CurrentPage]
        App.CurrentPage = name

        if old then
            for _, sec in ipairs(old.Sections or {}) do
                tw(sec.Group, 0.25, { GroupTransparency = 1 }, SINE)
            end
            task.wait(0.27)
        end
        if token ~= App.PageToken then return end

        for pname, p in pairs(App.Pages) do
            p.Frame.Visible = (pname == name)
        end
        local page = App.Pages[name]
        if not page then return end
        for i, sec in ipairs(page.Sections or {}) do
            sec.Group.GroupTransparency = 1
            task.delay((i - 1) * 0.06, function()
                if token ~= App.PageToken then return end
                tw(sec.Group, 0.55, { GroupTransparency = 0 }, QUINT)
            end)
        end
    end
    App._showPage = showPage

    function App:AddTab(name, icon, title, sub)
        local tabDef = { Name = name, Icon = icon, Title = title or name, Sub = sub or "" }
        table.insert(App.Tabs, tabDef)
        local idx = #App.Tabs

        local btn = new("TextButton", {
            Parent = tabsBar, LayoutOrder = idx, Size = UDim2.fromOffset(0, 40),
            BackgroundColor3 = B"Panel", BackgroundTransparency = 0.15,
            Text = "", AutoButtonColor = false, ClipsDescendants = true,
        }, { corner(10) })
        local sc = new("UIScale", { Parent = btn })
        local bst = new("UIStroke", { Color = B"Accent2", Thickness = 1, Transparency = 0.5, Parent = btn })
        local tabSh = staticShadow(btn, { Alpha = 0.22, Blur = 12, OffY = 2, Key = "Accent2" })

        local inner = new("Frame", {
            Parent = btn, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        }, { new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }), pad(0, 0, 14, 14) })

        local iconLbl
        if icon then
            iconLbl = new("ImageLabel", {
                Parent = inner, LayoutOrder = 1, Size = UDim2.fromOffset(16, 16),
                BackgroundTransparency = 1,
                Image = type(icon) == "number" and ("rbxassetid://" .. icon) or icon,
                ImageColor3 = B"Sub", ScaleType = Enum.ScaleType.Fit,
            })
        end
        local nameLbl = new("TextLabel", {
            Parent = inner, LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
            Text = name, TextColor3 = B"Sub", Font = Enum.Font.GothamBold, TextSize = 13,
            TextTruncate = Enum.TextTruncate.None,
        })

        task.defer(function()
            local pad2 = 28
            local w = (iconLbl and 16 + 8 or 0)
                + TextService:GetTextSize(name, 13, Enum.Font.GothamBold, V2(9999, 999)).X + pad2
            btn.Size = UDim2.fromOffset(math.max(80, w), 40)
        end)

        local tab = { Def = tabDef, Btn = btn, Active = false, Index = idx }
        App.Tabs[idx] = tab

        local function paint(active)
            tab.Active = active
            tw(btn, 0.3, {
                BackgroundColor3 = active and Theme.Accent or Theme.Panel,
                BackgroundTransparency = active and 0 or 0.15,
            }, SINE)
            tw(bst, 0.3, {
                Color = active and Theme.Accent or Theme.Accent2,
                Transparency = active and 0.1 or 0.5,
            }, SINE)
            if iconLbl then
                tw(iconLbl, 0.3, { ImageColor3 = active and Theme.OnAccent or Theme.Sub }, SINE)
            end
            tw(nameLbl, 0.3, { TextColor3 = active and Theme.OnAccent or Theme.Sub }, SINE)
        end
        tab.Paint = paint
        onTheme(function() paint(tab.Active) end)

        btn.MouseEnter:Connect(function()
            if tab.Active then return end
            tw(sc, 0.25, { Scale = 1.03 }, QUINT)
            tw(nameLbl, 0.2, { TextColor3 = Theme.Text }, SINE)
            tabSh:SetHover(true)
        end)
        btn.MouseLeave:Connect(function()
            tw(sc, 0.3, { Scale = 1 }, QUINT)
            if not tab.Active then tw(nameLbl, 0.25, { TextColor3 = Theme.Sub }, SINE) end
            tabSh:SetHover(false)
        end)
        btn.MouseButton1Click:Connect(function()
            App:SelectTab(idx)
        end)

        local pageFrame = new("Frame", {
            Parent = pagesHolder, Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1, Visible = false,
        }, { pad(0, 16, 16, 16) })
        local scroll = new("ScrollingFrame", {
            Parent = pageFrame, Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1, ScrollBarThickness = 3,
            ScrollBarImageColor3 = B"Accent",
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, {
            new("UIListLayout", {
                Padding = UDim.new(0, 14),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        local page = { Frame = pageFrame, Scroll = scroll, Sections = {}, Def = tabDef }
        App.Pages[name] = page

        function page:Section(h)
            local g = new("CanvasGroup", {
                Parent = scroll, Size = UDim2.new(1, 0, 0, h or 100),
                BackgroundTransparency = 1, GroupTransparency = 0,
            }, {
                new("UIListLayout", {
                    Padding = UDim.new(0, 10),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            })
            table.insert(self.Sections, { Group = g })
            return g
        end

        function page:Header(title, sub)
            local g = self:Section(48)
            label(g, title or "", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 22),
                Enum.Font.GothamBold, 16, B"Text")
            if sub then
                label(g, sub, UDim2.fromOffset(0, 24), UDim2.new(1, 0, 0, 16),
                    Enum.Font.Gotham, 11, B"Sub")
            end
            return g
        end

        return tab
    end

    function App:SelectTab(i)
        if App.CurrentTab == i then return end
        App.CurrentTab = i
        for k, t in ipairs(App.Tabs) do
            if t.Paint then t.Paint(k == i) end
        end
        local tab = App.Tabs[i]
        if tab then
            local targetX = tab.Btn.AbsolutePosition.X - tabsBar.AbsolutePosition.X
            tw(tabIndicator, 0.4, {
                Position = UDim2.fromOffset(targetX, 48),
                Size = UDim2.fromOffset(tab.Btn.AbsoluteSize.X, 3),
            }, QUINT)
            showPage(tab.Def.Name)
        end
    end

    --=================================================================
    --  NOTIFICATIONS
    --=================================================================
    local notifHolder = new("Frame", {
        Parent = gui, AnchorPoint = V2(1, 0), Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.fromOffset(320, 400), BackgroundTransparency = 1, ZIndex = 200,
    })
    new("UIListLayout", {
        Parent = notifHolder, Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    local notifCount = 0
    App.NotifHolder = notifHolder

    function App:Notify(title, text, kind, dur)
        dur = dur or 3
        kind = kind or "info"
        local color = kind == "ok" and Lib.Semantic.Green
                   or kind == "warn" and Lib.Semantic.Yellow
                   or kind == "err" and Lib.Semantic.Red
                   or Theme.Accent
        local glyph = kind == "ok" and "✓" or kind == "warn" and "!" or kind == "err" and "×" or "i"

        notifCount += 1
        local card = new("Frame", {
            Parent = notifHolder, LayoutOrder = -notifCount,
            Size = UDim2.fromOffset(320, 64), BackgroundColor3 = B"Panel",
            BackgroundTransparency = 0.05, AnchorPoint = V2(1, 0),
        }, { corner(12) })
        local cs = new("UIStroke", { Color = color, Thickness = 1.2, Transparency = 0.35, Parent = card })
        Lib.Grad(cs, "tri")

        local nShadow = staticShadow(card, {
            Alpha = 0.55, Blur = 20, OffY = 5, Key = "Accent", ZIndex = 2,
        })
        if nShadow and nShadow.Shadow then
            pcall(function() nShadow.Shadow.Color = color end)
        end
        card.MouseEnter:Connect(function() nShadow:SetHover(true)  end)
        card.MouseLeave:Connect(function() nShadow:SetHover(false) end)

        local iconBg = new("Frame", {
            Parent = card, Position = UDim2.fromOffset(12, 12),
            Size = UDim2.fromOffset(36, 36),
            BackgroundColor3 = color, BackgroundTransparency = 0.8,
        }, { corner(10), plainStroke(color, 1.2, 0.2) })
        new("TextLabel", {
            Parent = iconBg, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            Text = glyph, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = color,
        })
        label(card, title or "Notification", UDim2.fromOffset(58, 12), UDim2.new(1, -68, 0, 16),
            Enum.Font.GothamBold, 12, B"Text")
        label(card, text or "", UDim2.fromOffset(58, 30), UDim2.new(1, -68, 0, 24),
            Enum.Font.Gotham, 11, B"Sub", nil, { TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })

        card.Position = UDim2.fromOffset(360, 0)
        tw(card, 0.5, { Position = UDim2.fromOffset(0, 0) }, QUINT)
        task.delay(dur, function()
            if card.Parent then
                tw(card, 0.4, { Position = UDim2.fromOffset(360, 0), BackgroundTransparency = 1 }, QUINT, IN)
                tw(cs, 0.4, { Transparency = 1 }, SINE)
                task.delay(0.5, function() if card.Parent then card:Destroy() end end)
            end
        end)
        return card
    end

    --=================================================================
    --  CONFIRM MODAL
    --=================================================================
    local confirmLayer = new("Frame", {
        Parent = gui, Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 1,
        Visible = false, ZIndex = 300,
    })
    local confirmBox = new("Frame", {
        Parent = confirmLayer, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(340, 160), BackgroundColor3 = B"Panel", ZIndex = 301,
    }, { corner(16), stk() })
    local cScale = new("UIScale", { Parent = confirmBox, Scale = 0.85 })

    staticShadow(confirmBox, { Alpha = 0.65, Blur = 30, OffY = 8, Key = "Accent", ZIndex = 2 })

    local cTitle = label(confirmBox, "", UDim2.fromOffset(20, 18), UDim2.new(1, -40, 0, 22),
        Enum.Font.GothamBold, 15, B"Text")
    local cText = label(confirmBox, "", UDim2.fromOffset(20, 44), UDim2.new(1, -40, 0, 40),
        Enum.Font.Gotham, 12, B"Sub", nil, { TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
    local cNo = new("TextButton", {
        Parent = confirmBox, Position = UDim2.new(0, 20, 1, -50),
        Size = UDim2.new(0.5, -28, 0, 34), BackgroundColor3 = B"Panel2",
        Text = "Cancel", TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 12,
    }, { corner(10) })
    local cYes = new("TextButton", {
        Parent = confirmBox, Position = UDim2.new(0.5, 8, 1, -50),
        Size = UDim2.new(0.5, -28, 0, 34), BackgroundColor3 = B"Accent",
        Text = "Yes", TextColor3 = B"OnAccent", Font = Enum.Font.GothamBold, TextSize = 12,
    }, { corner(10) })

    local confirmYes = nil
    local function closeConfirm()
        tw(confirmLayer, 0.25, { BackgroundTransparency = 1 }, SINE)
        tw(cScale, 0.25, { Scale = 0.85 }, QUINT, IN)
        task.delay(0.26, function() confirmLayer.Visible = false end)
    end
    cNo.MouseButton1Click:Connect(closeConfirm)
    cYes.MouseButton1Click:Connect(function()
        closeConfirm()
        if confirmYes then task.spawn(confirmYes) end
    end)

    function App:Confirm(title, text, yes)
        cTitle.Text = title or "Are you sure?"
        cText.Text = text or ""
        confirmYes = yes
        confirmLayer.Visible = true
        cScale.Scale = 0.85
        tw(confirmLayer, 0.3, { BackgroundTransparency = 0.5 }, SINE)
        tw(cScale, 0.4, { Scale = 1 }, BACK)
    end

    --=================================================================
    --  SHOW / HIDE / DESTROY
    --=================================================================
    function App:Show()
        if App.Destroyed then return end
        App.Opened = true
        scale.Scale = fit() * 0.85
        tw(scale, 0.6, { Scale = fit() }, BACK)
        tw(dim, 0.5, { BackgroundTransparency = 1 - (cfg.Dim or 0.5) }, SINE)
        if cfg.Blur ~= false then setBlur(cfg.BlurSize or 14) end
    end

    function App:Hide()
        App.Opened = false
        tw(scale, 0.35, { Scale = fit() * 0.85 }, QUINT, IN)
        tw(dim, 0.35, { BackgroundTransparency = 1 }, SINE)
        setBlur(0)
    end

    function App:Destroy()
        if App.Destroyed then return end
        App.Destroyed = true
        for _, fn in ipairs(unloaders) do pcall(fn) end
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        conns = {}
        if blur then pcall(function() blur:Destroy() end) end
        tw(scale, 0.4, { Scale = 0 }, QUINT, IN)
        tw(dim, 0.35, { BackgroundTransparency = 1 }, SINE)
        task.delay(0.5, function() if gui.Parent then gui:Destroy() end end)
    end

    function App:OnUnload(fn) table.insert(unloaders, fn) end

    function App:SetShadows(on)        Lib.SetShadows(on)        end
    function App:SetShadowIntensity(v) Lib.SetShadowIntensity(v) end
    function App:SetShadowBehind(on)   Lib.SetShadowBehind(on)   end
    function App:AnimatedShadow(t, o)  return animatedShadow(t, o) end
    function App:StaticShadow(t, o)    return staticShadow(t, o)   end

    return App
end

Lib._hooks = hooks
Lib._conns = conns

return Lib