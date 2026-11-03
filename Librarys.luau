local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local HttpService  = game:GetService("HttpService")
local Stats        = game:GetService("Stats")
local TextService  = game:GetService("TextService")
local GuiService   = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait() until Players.LocalPlayer
    LocalPlayer = Players.LocalPlayer
end

local genv = (getgenv and getgenv()) or _G
if genv.FemboysenseUnload then pcall(genv.FemboysenseUnload) end

local BUILDER_FONT
pcall(function() BUILDER_FONT = Enum.Font.BuilderIcons end)

local rgb, WHITE, BLACK = Color3.fromRGB, Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local SINE, QUINT, BACK = Enum.EasingStyle.Sine, Enum.EasingStyle.Quint, Enum.EasingStyle.Back
local OUT, IN = Enum.EasingDirection.Out, Enum.EasingDirection.In
local AUTO_X, AUTO_Y, AUTO_NONE = Enum.AutomaticSize.X, Enum.AutomaticSize.Y, Enum.AutomaticSize.None
local V2 = Vector2.new
local sin, clamp, floor = math.sin, math.clamp, math.floor

local Lib = {
    Flags = {}, Version = "v6.0", Speed = 1,
    Semantic = { Green = rgb(70, 225, 125), Yellow = rgb(255, 190, 60), Red = rgb(255, 70, 70) },
    ResetIcon = 140026246189675,
}

local DARK = { Bg = rgb(8, 8, 10), Side = rgb(17, 17, 20), Panel = rgb(26, 26, 30), Panel2 = rgb(40, 40, 46),
    Text = rgb(244, 244, 247), Sub = rgb(146, 146, 154), Stroke = WHITE, StrokeT = 0.93 }
local LIGHT = { Bg = rgb(232, 232, 238), Side = rgb(246, 246, 250), Panel = rgb(255, 255, 255), Panel2 = rgb(233, 233, 240),
    Text = rgb(22, 22, 27), Sub = rgb(108, 108, 120), Stroke = BLACK, StrokeT = 0.92 }
local THEMES = {
    { Name = "Mono",     Mode = "Dark",  Accent = rgb(227, 228, 230) },
    { Name = "Lavender", Mode = "Dark",  Accent = rgb(184, 160, 237) },
    { Name = "Midnight", Mode = "Dark",  Accent = rgb(145, 175, 229) },
    { Name = "Rose",     Mode = "Dark",  Accent = rgb(229, 165, 188) },
    { Name = "Mono",     Mode = "Light", Accent = rgb(70, 70, 78) },
    { Name = "Lavender", Mode = "Light", Accent = rgb(150, 120, 220) },
    { Name = "Midnight", Mode = "Light", Accent = rgb(100, 140, 215) },
    { Name = "Rose",     Mode = "Light", Accent = rgb(220, 120, 155) },
    { Name = "Crimson", Mode = "Dark", Accent = rgb(255, 40, 60), Accent2 = rgb(140, 12, 28),
      Colors = { Bg = rgb(10, 8, 10), Side = rgb(15, 9, 12), Panel = rgb(24, 17, 19), Panel2 = rgb(34, 22, 25), Text = rgb(245, 245, 245), Sub = rgb(150, 138, 141) } },
    { Name = "Ocean", Mode = "Dark", Accent = rgb(56, 189, 248), Accent2 = rgb(12, 74, 110),
      Colors = { Bg = rgb(7, 10, 15), Side = rgb(10, 15, 22), Panel = rgb(16, 23, 33), Panel2 = rgb(24, 34, 48), Text = rgb(240, 246, 252), Sub = rgb(130, 148, 168) } },
    { Name = "Violet", Mode = "Dark", Accent = rgb(168, 85, 247), Accent2 = rgb(76, 29, 149),
      Colors = { Bg = rgb(10, 8, 14), Side = rgb(14, 10, 20), Panel = rgb(21, 17, 31), Panel2 = rgb(31, 24, 45), Text = rgb(246, 242, 252), Sub = rgb(150, 140, 170) } },
    { Name = "Emerald", Mode = "Dark", Accent = rgb(52, 211, 153), Accent2 = rgb(6, 78, 59),
      Colors = { Bg = rgb(7, 12, 10), Side = rgb(9, 16, 13), Panel = rgb(15, 25, 21), Panel2 = rgb(22, 36, 30), Text = rgb(240, 252, 246), Sub = rgb(130, 160, 148) } },
    { Name = "Sunset", Mode = "Dark", Accent = rgb(251, 146, 60), Accent2 = rgb(154, 52, 18),
      Colors = { Bg = rgb(13, 9, 7), Side = rgb(19, 12, 9), Panel = rgb(28, 20, 15), Panel2 = rgb(40, 28, 20), Text = rgb(252, 246, 240), Sub = rgb(168, 148, 135) } },
    { Name = "Sakura", Mode = "Dark", Accent = rgb(244, 114, 182), Accent2 = rgb(131, 24, 67),
      Colors = { Bg = rgb(13, 8, 11), Side = rgb(19, 11, 16), Panel = rgb(29, 18, 25), Panel2 = rgb(42, 26, 36), Text = rgb(253, 242, 248), Sub = rgb(170, 140, 158) } },
    { Name = "Gold", Mode = "Dark", Accent = rgb(250, 204, 21), Accent2 = rgb(133, 77, 14),
      Colors = { Bg = rgb(12, 10, 6), Side = rgb(18, 14, 8), Panel = rgb(27, 22, 13), Panel2 = rgb(39, 31, 18), Text = rgb(254, 252, 232), Sub = rgb(165, 155, 125) } },
}
Lib.Themes = THEMES

local Theme = {}
local function loadTheme(def)
    local base = def.Mode == "Light" and LIGHT or DARK
    for k, v in pairs(base) do Theme[k] = v end
    if def.Colors then for k, v in pairs(def.Colors) do Theme[k] = v end end
    Theme.Accent = def.Accent
    Theme.Accent2 = def.Accent2 or (def.Mode == "Light" and def.Accent:Lerp(WHITE, 0.4) or def.Accent:Lerp(BLACK, 0.58))
    Theme.OnAccent = def.Mode == "Light" and WHITE or rgb(12, 12, 14)
end
loadTheme(THEMES[2])
Lib.Theme = Theme

local function kp(t, c) return ColorSequenceKeypoint.new(t, c) end
local function nk(t, v) return NumberSequenceKeypoint.new(t, v) end
local RING_T = NumberSequence.new({ nk(0, 0.88), nk(0.12, 0.05), nk(0.3, 0.88), nk(0.5, 0.88), nk(0.62, 0.05), nk(0.8, 0.88), nk(1, 0.88) })
local function gradColor(kind)
    local A, A2 = Theme.Accent, Theme.Accent2
    if kind == "ring" then
        return ColorSequence.new({ kp(0, A2), kp(0.12, A), kp(0.3, A2), kp(0.5, A2), kp(0.62, A), kp(0.8, A2), kp(1, A2) })
    elseif kind == "lin" then
        return ColorSequence.new(A2, A)
    end
    return ColorSequence.new(A, A2)
end

local reg, hooks, conns, grads = {}, {}, {}, {}
local function keep(c) conns[#conns + 1] = c return c end
local function onTheme(fn) hooks[#hooks + 1] = fn fn(true) end

local function tw(obj, t, props, style, dir)
    local tr = TweenService:Create(obj, TweenInfo.new(math.max(t / Lib.Speed, 0.01), style or QUINT, dir or OUT), props)
    tr:Play()
    return tr
end

local function B(key) return { __bind = key } end
local function bind(obj, prop, key)
    obj[prop] = Theme[key]
    reg[#reg + 1] = { obj, prop, key }
end

local function applyTheme(def, instant)
    loadTheme(def)
    local gui = Lib._gui
    for i = #reg, 1, -1 do
        local e = reg[i]
        local o = e[1]
        if o.Parent then
            if not instant and gui and o:IsDescendantOf(gui) then
                tw(o, 0.3, { [e[2]] = Theme[e[3]] }, SINE)
            else
                o[e[2]] = Theme[e[3]]
            end
        else
            table.remove(reg, i)
        end
    end
    for i = #grads, 1, -1 do
        local g = grads[i]
        if g[1].Parent then g[1].Color = gradColor(g[2]) else table.remove(grads, i) end
    end
    for _, f in ipairs(hooks) do pcall(f, instant == true) end
end

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
    return new("UIStroke", { Color = B"Stroke", Transparency = B"StrokeT", Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function plainStroke(color, th, tr)
    return new("UIStroke", { Color = color, Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function pad(t, b, l, r)
    return new("UIPadding", { PaddingTop = UDim.new(0, t), PaddingBottom = UDim.new(0, b), PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r) })
end
local function label(parent, text, pos, size, font, ts, color, align, extra)
    local l = new("TextLabel", {
        Parent = parent, Text = text, Position = pos or UDim2.new(), Size = size or UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Font = font or Enum.Font.GothamMedium, TextSize = ts or 13,
        TextColor3 = color or B"Text", TextXAlignment = align or Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    if extra then for k, v in pairs(extra) do l[k] = v end end
    return l
end
local function grad(parent, kind, rot)
    local g = new("UIGradient", { Color = gradColor(kind), Rotation = rot or 0, Parent = parent })
    if kind == "ring" then g.Transparency = RING_T end
    grads[#grads + 1] = { g, kind }
    return g
end
local function fire(cb, ...)
    if not cb then return end
    local a = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(cb, table.unpack(a, 1, a.n))
        if not ok then warn("[Femboysense] " .. tostring(err)) end
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
    return rgb(n // 65536, (n // 256) % 256, n % 256)
end

local active
local function capture(onMove, onEnd) active = { move = onMove, stop = onEnd } end
local function drag(handle, target, gate)
    handle.InputBegan:Connect(function(i)
        if not isPress(i) or (gate and gate()) then return end
        local start, sp = i.Position, target.Position
        capture(function(p)
            local d = p - start
            target.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end)
    end)
end

local function makeIcon(parent, icon, pos, px)
    px = px or 18
    if type(icon) == "number" then icon = "rbxassetid://" .. icon end
    local im
    if type(icon) == "string" and (icon:find("^rbxasset") or icon:find("^rbxthumb") or icon:find("^http")) then
        im = new("ImageLabel", { Parent = parent, Position = pos or UDim2.new(), Size = UDim2.fromOffset(px, px),
            BackgroundTransparency = 1, Image = icon, ImageColor3 = Theme.Sub, ScaleType = Enum.ScaleType.Fit })
    else
        local useFont = type(icon) == "string" and icon ~= "" and BUILDER_FONT
        im = new("TextLabel", { Parent = parent, Position = pos or UDim2.new(), Size = UDim2.fromOffset(px, px),
            BackgroundTransparency = 1, Text = useFont and icon or "•", TextColor3 = Theme.Sub, TextSize = px,
            Font = useFont and BUILDER_FONT or Enum.Font.GothamBold })
    end
    local prop = im:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
    local ic = { Holder = im }
    function ic:Paint(c, instant)
        if instant then im[prop] = c else tw(im, 0.25, { [prop] = c }, SINE) end
    end
    function ic:Bind(key) onTheme(function(inst) ic:Paint(Theme[key], inst) end) return ic end
    return ic
end

local SHORT = { RightShift = "RSHIFT", LeftShift = "LSHIFT", RightControl = "RCTRL", LeftControl = "LCTRL",
    RightAlt = "RALT", LeftAlt = "LALT", Return = "ENTER", Backspace = "BKSP", Escape = "ESC",
    Space = "SPACE", Insert = "INS", Delete = "DEL", PageUp = "PGUP", PageDown = "PGDN", CapsLock = "CAPS" }
local function keyName(k)
    if not k then return "" end
    if k == "MouseButton4" then return "M4" end
    if k == "MouseButton5" then return "M5" end
    if type(k) == "string" then return k end
    if k == Enum.UserInputType.MouseButton1 then return "LMB" end
    if k == Enum.UserInputType.MouseButton2 then return "RMB" end
    if k == Enum.UserInputType.MouseButton3 then return "MMB" end
    return SHORT[k.Name] or string.upper(k.Name)
end
local XBTN = { MouseButton4 = 0x05, MouseButton5 = 0x06 }
local function safeEnum(e, n) local ok, v = pcall(function() return e[n] end) return ok and v or nil end
local function keyFromName(n)
    if type(n) ~= "string" then return nil end
    if XBTN[n] then return n end
    return safeEnum(Enum.KeyCode, n) or safeEnum(Enum.UserInputType, n)
end
local function keyToName(k) if not k then return nil end return type(k) == "string" and k or k.Name end
local function keyMatch(key, input)
    if not key or type(key) == "string" then return false end
    return key == input.KeyCode or key == input.UserInputType
end

local function resetBtn(parent, pos, onClick)
    local b = new("TextButton", { Parent = parent, AnchorPoint = V2(1, 0.5), Position = pos, Size = UDim2.fromOffset(24, 24),
        BackgroundColor3 = B"Panel2", Visible = false }, { corner(8) })
    local ic = makeIcon(b, Lib.ResetIcon, UDim2.fromOffset(5, 5), 14):Bind("Sub")
    b.MouseEnter:Connect(function() ic:Paint(Theme.Accent) end)
    b.MouseLeave:Connect(function() ic:Paint(Theme.Sub) end)
    b.MouseButton1Click:Connect(onClick)
    return b
end

local function makeSwitch(parent, init, cb, pos)
    local state = init and true or false
    local trackBtn = new("TextButton", { Parent = parent, AnchorPoint = V2(1, 0.5), Position = pos or UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(40, 22), BackgroundColor3 = Theme.Bg }, { corner(11) })
    local press = new("UIScale", { Parent = trackBtn })
    local knob = new("Frame", { Parent = trackBtn, AnchorPoint = V2(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), BackgroundColor3 = WHITE }, { corner(8) })
    local sw = {}
    local function paint(instant)
        local col = state and Theme.Accent:Lerp(Theme.Panel2, 0.38) or Theme.Bg
        local p = state and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        if instant then
            trackBtn.BackgroundColor3, knob.Position = col, p
        else
            tw(trackBtn, 0.25, { BackgroundColor3 = col }, SINE)
            tw(knob, 0.4, { Position = p }, BACK)
        end
    end
    paint(true)
    onTheme(function(inst) paint(inst) end)
    function sw:Set(v, silent)
        v = v and true or false
        if v == state then return end
        state = v
        paint(false)
        if not silent and cb then cb(v) end
    end
    function sw:Get() return state end
    trackBtn.MouseButton1Down:Connect(function() tw(press, 0.1, { Scale = 0.92 }, SINE) end)
    trackBtn.MouseButton1Up:Connect(function() tw(press, 0.3, { Scale = 1 }, BACK) end)
    trackBtn.MouseLeave:Connect(function() tw(press, 0.2, { Scale = 1 }, SINE) end)
    trackBtn.MouseButton1Click:Connect(function() sw:Set(not state) end)
    sw.Frame = trackBtn
    return sw
end

local function makeSlider(parent, o)
    local mn, mx, step = o.Min or 0, o.Max or 100, o.Step or 1
    local value = clamp(o.Default or mn, mn, mx)
    local f = new("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, LayoutOrder = o.Order or 0 })
    label(f, o.Name or "Slider", UDim2.new(), UDim2.new(1, -70, 0, 18), Enum.Font.GothamMedium, 13, B"Text")
    local out = label(f, "", UDim2.new(1, 0, 0, 0), UDim2.fromOffset(70, 18), Enum.Font.GothamBold, 12, B"Accent", Enum.TextXAlignment.Right)
    out.AnchorPoint = V2(1, 0)
    local bar = new("Frame", { Parent = f, Position = UDim2.new(0, 0, 0, 29), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = B"Bg" }, { corner(2) })
    local fill = new("Frame", { Parent = bar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE }, { corner(2) })
    grad(fill, "lin")
    local knob = new("Frame", { Parent = bar, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(12, 12), BackgroundColor3 = WHITE, ZIndex = 2 }, { corner(6) })
    local function fmt(v)
        if step >= 1 then return string.format("%d", v) end
        local s = string.format(step < 0.1 and "%.3f" or "%.2f", v):gsub("0+$", ""):gsub("%.$", "")
        return s
    end
    local function render(fast)
        local r = (value - mn) / (mx - mn)
        out.Text = fmt(value) .. (o.Suffix or "")
        tw(fill, fast and 0.06 or 0.3, { Size = UDim2.fromScale(r, 1) }, SINE)
        tw(knob, fast and 0.06 or 0.3, { Position = UDim2.fromScale(r, 0.5) }, SINE)
    end
    local api = {}
    local function setv(v, silent, fast)
        v = clamp(floor((v - mn) / step + 0.5) * step + mn, mn, mx)
        if v == value then return end
        value = v
        render(fast)
        if not silent then fire(o.Callback, v) end
    end
    render(false)
    local hit = new("TextButton", { Parent = f, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, ZIndex = 3 })
    local function fromX(x)
        setv(mn + (mx - mn) * clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1), false, true)
    end
    hit.InputBegan:Connect(function(i)
        if not isPress(i) then return end
        tw(knob, 0.2, { Size = UDim2.fromOffset(16, 16) }, BACK)
        fromX(i.Position.X)
        capture(function(p) fromX(p.X) end, function() tw(knob, 0.25, { Size = UDim2.fromOffset(12, 12) }, QUINT) end)
    end)
    function api:Set(v, silent) setv(v, silent, false) end
    function api:Get() return value end
    api.Frame = f
    return api
end

local function flag(o, api) if o.Flag then Lib.Flags[o.Flag] = api end end

local function place(f, name, topMargin)
    local r, b = name:find("Right") ~= nil, name:find("Bottom") ~= nil
    f.AnchorPoint = V2(r and 1 or 0, b and 1 or 0)
    f.Position = UDim2.new(r and 1 or 0, r and -18 or 18, b and 1 or 0, b and -18 or topMargin)
end

function Lib:CreateWindow(cfg)
    cfg = cfg or {}
    local Icons = cfg.Icons or {}
    if Icons.Reset then Lib.ResetIcon = Icons.Reset end
    local W, H = 880, 580
    local TBW = W - 238
    local Win = {
        Categories = {}, Groups = {}, Modules = {}, BindList = {}, Current = nil, Query = "",
        userScale = 1, Open = true, ToggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift,
        ThemeDef = THEMES[2], Opacity = 1, LockPos = false, FolderName = cfg.Folder or "FemboysenseHub",
        NotifTime = 3, NotifsOn = true, FreeMouse = true, BorderSpin = 60, BorderPulse = false,
        BorderThick = 2, _glowT = 0.45, HudOn = false, Loading = false,
    }
    Lib.Win = Win
    local SEM = Lib.Semantic
    Win.Keep = keep

    local gui = new("ScreenGui", { Name = "FemboysenseHub", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999, AutoLocalize = false, Parent = guiParent() })
    Win.Gui = gui
    Lib._gui = gui

    keep(UIS.InputChanged:Connect(function(i) if active and isMove(i) then active.move(i.Position) end end))
    keep(UIS.InputEnded:Connect(function(i)
        if active and isPress(i) then
            local a = active
            active = nil
            if a.stop then a.stop() end
        end
    end))

    local modalBtn = new("TextButton", { Parent = gui, Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Modal = false })
    local stash = Instance.new("Folder")
    stash.Name = "Stash"

    local root = new("Frame", { Parent = gui, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, ZIndex = 2 })
    local scale = new("UIScale", { Parent = root })

    local vpSize = V2(1280, 720)
    local function readViewport()
        local cam = workspace.CurrentCamera
        if cam then vpSize = cam.ViewportSize end
    end
    readViewport()
    local function fit()
        return clamp(math.min(vpSize.X / (W + 40), vpSize.Y / (H + 40)), 0.4, 1.3) * Win.userScale
    end
    do
        local cam = workspace.CurrentCamera
        if cam then
            keep(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                readViewport()
                if Win.Open then scale.Scale = fit() end
            end))
        end
    end

    local glassObjs = {}
    local function glassFinal(g) return 1 - (1 - g[2]) * Win.Opacity end
    local function glassT(obj, base)
        local g = { obj, base }
        glassObjs[#glassObjs + 1] = g
        obj.BackgroundTransparency = glassFinal(g)
    end

    local main = new("Frame", { Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = B"Bg", ClipsDescendants = true }, { corner(22) })
    glassT(main, 0.04)
    local mainStroke = new("UIStroke", { Color = WHITE, Transparency = Win._glowT, Thickness = Win.BorderThick,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = main })
    local ringGrad = grad(mainStroke, "ring")
    main.MouseEnter:Connect(function() Win.OverMenu = true end)
    main.MouseLeave:Connect(function() Win.OverMenu = false end)

    local side = new("Frame", { Parent = main, Position = UDim2.fromOffset(14, 14), Size = UDim2.new(0, 196, 1, -28), BackgroundColor3 = B"Side" }, { corner(18), stk() })
    glassT(side, 0.08)
    local brand = new("Frame", { Parent = side, Size = UDim2.new(1, 0, 0, 74), BackgroundTransparency = 1 })
    local logoHolder = new("Frame", { Parent = brand, Position = UDim2.fromOffset(16, 18), Size = UDim2.fromOffset(38, 38), BackgroundColor3 = WHITE }, { corner(11) })
    if cfg.Logo then
        new("ImageLabel", { Parent = logoHolder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            Image = type(cfg.Logo) == "number" and ("rbxassetid://" .. cfg.Logo) or cfg.Logo, ScaleType = Enum.ScaleType.Fit })
        logoHolder.BackgroundTransparency = 1
    else
        grad(logoHolder, "pill", 45)
        label(logoHolder, string.sub(cfg.Title or "F", 1, 1), nil, nil, Enum.Font.GothamBlack, 20, B"OnAccent", Enum.TextXAlignment.Center)
    end
    label(brand, cfg.Title or "FEMBOYSENSE", UDim2.fromOffset(62, 19), UDim2.new(1, -68, 0, 20), Enum.Font.GothamBlack, 15, B"Text")
    label(brand, cfg.Sub or "HUB", UDim2.fromOffset(62, 40), UDim2.new(1, -68, 0, 12), Enum.Font.GothamMedium, 9, B"Sub")

    local NAV_STEP, HEAD_H, GAP = 44, 26, 8
    local nav = new("ScrollingFrame", { Parent = side, Position = UDim2.fromOffset(10, 78), Size = UDim2.new(1, -20, 1, -78 - 80),
        BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = B"Accent", CanvasSize = UDim2.new(), ClipsDescendants = true })
    local navInd = new("Frame", { Parent = nav, Size = UDim2.new(1, -4, 0, 40), BackgroundColor3 = B"Panel2", Visible = false, ZIndex = 1 }, {
        corner(12), new("UIGradient", { Transparency = NumberSequence.new({ nk(0, 0), nk(1, 0.65) }) }), stk() })
    local navBar = new("Frame", { Parent = navInd, Position = UDim2.fromOffset(0, 11), Size = UDim2.fromOffset(3, 18), BackgroundColor3 = WHITE }, { corner(2) })
    grad(navBar, "lin", 90)

    local account = new("TextButton", { Parent = side, AnchorPoint = V2(0, 1), Position = UDim2.new(0, 12, 1, -12),
        Size = UDim2.new(1, -24, 0, 58), BackgroundColor3 = B"Panel" }, { corner(14), stk() })
    new("ImageLabel", { Parent = account, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = B"Panel2",
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=100&h=100" }, { corner(17) })
    label(account, LocalPlayer.DisplayName, UDim2.fromOffset(54, 12), UDim2.new(1, -86, 0, 18), Enum.Font.GothamBold, 13, B"Text")
    label(account, cfg.Version or Lib.Version, UDim2.fromOffset(54, 30), UDim2.new(1, -86, 0, 14), Enum.Font.Gotham, 10, B"Sub")
    local accArrow = label(account, ">", UDim2.new(1, -24, 0, 0), UDim2.fromOffset(14, 58), Enum.Font.GothamBold, 13, B"Sub", Enum.TextXAlignment.Center)
    account.MouseEnter:Connect(function() tw(account, 0.25, { BackgroundColor3 = Theme.Panel2 }, SINE) tw(accArrow, 0.3, { Position = UDim2.new(1, -20, 0, 0) }, QUINT) end)
    account.MouseLeave:Connect(function() tw(account, 0.3, { BackgroundColor3 = Theme.Panel }, SINE) tw(accArrow, 0.3, { Position = UDim2.new(1, -24, 0, 0) }, QUINT) end)

    local toolbar = new("Frame", { Parent = main, Position = UDim2.fromOffset(224, 14), Size = UDim2.fromOffset(TBW, 52), BackgroundColor3 = B"Panel" }, { corner(16), stk() })
    glassT(toolbar, 0.08)

    local function tbBtn(rightOff, text, size)
        local b = new("TextButton", { Parent = toolbar, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -rightOff, 0.5, 0),
            Size = UDim2.fromOffset(36, 36), BackgroundColor3 = B"Bg", Text = text, TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = size or 13 }, { corner(11) })
        local sc = new("UIScale", { Parent = b })
        b.MouseEnter:Connect(function() tw(b, 0.2, { BackgroundColor3 = Theme.Panel2 }, SINE) tw(sc, 0.3, { Scale = 1.08 }, BACK) end)
        b.MouseLeave:Connect(function() tw(b, 0.25, { BackgroundColor3 = Theme.Bg }, SINE) tw(sc, 0.25, { Scale = 1 }, SINE) end)
        b.MouseButton1Down:Connect(function() tw(sc, 0.08, { Scale = 0.92 }, SINE) end)
        b.MouseButton1Up:Connect(function() tw(sc, 0.3, { Scale = 1.08 }, BACK) end)
        return b
    end
    local closeBtn = tbBtn(9, "×", 20)
    local hideBtn = tbBtn(53, "–", 18)
    local gearBtn = tbBtn(97, "", 13)
    if Icons.Settings then makeIcon(gearBtn, Icons.Settings, UDim2.fromOffset(9, 9), 18):Bind("Text") else gearBtn.Text = "⚙" end
    closeBtn.MouseEnter:Connect(function() tw(closeBtn, 0.2, { BackgroundColor3 = rgb(220, 70, 80), TextColor3 = WHITE }, SINE) end)
    closeBtn.MouseLeave:Connect(function() tw(closeBtn, 0.25, { BackgroundColor3 = Theme.Bg, TextColor3 = Theme.Text }, SINE) end)

    local searchBack = new("Frame", { Parent = toolbar, Position = UDim2.fromOffset(9, 7), Size = UDim2.new(1, -150, 0, 38), BackgroundColor3 = B"Bg" }, { corner(12) })
    local searchStroke = new("UIStroke", { Color = B"Accent", Transparency = 1, Thickness = 1.2, Parent = searchBack })
    local searchIcon = makeIcon(searchBack, Icons.Search or 118685771787843, UDim2.fromOffset(12, 10), 18):Bind("Sub")
    local searchBox = new("TextBox", { Parent = searchBack, Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -48, 1, 0), BackgroundTransparency = 1,
        PlaceholderText = "Search modules…", PlaceholderColor3 = B"Sub", Text = "", TextColor3 = B"Text", TextSize = 13, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left })
    searchBox.Focused:Connect(function() tw(searchStroke, 0.25, { Transparency = 0.45 }, SINE) searchIcon:Paint(Theme.Text) end)
    searchBox.FocusLost:Connect(function() tw(searchStroke, 0.3, { Transparency = 1 }, SINE) searchIcon:Paint(Theme.Sub) end)

    local function canDrag() return Win.LockPos end
    drag(toolbar, root, canDrag)
    drag(brand, root, canDrag)

    local content = new("Frame", { Parent = main, Position = UDim2.fromOffset(224, 80), Size = UDim2.fromOffset(TBW, H - 80 - 38), BackgroundColor3 = B"Bg", ClipsDescendants = true }, { corner(18), stk() })
    glassT(content, 0.02)
    local pageTitle = label(content, "", UDim2.fromOffset(22, 14), UDim2.new(1, -44, 0, 32), Enum.Font.GothamBold, 26, B"Text")
    local pageSub = label(content, "", UDim2.fromOffset(22, 48), UDim2.new(1, -44, 0, 16), Enum.Font.Gotham, 12, B"Sub")
    local titleBar = new("Frame", { Parent = content, Position = UDim2.fromOffset(22, 68), Size = UDim2.fromOffset(38, 2), BackgroundColor3 = WHITE }, { corner(1) })
    grad(titleBar, "lin")
    drag(pageTitle, root, canDrag)

    local SCROLL_X = 4
    local scroll = new("ScrollingFrame", { Parent = content, Position = UDim2.fromOffset(SCROLL_X, 80), Size = UDim2.new(1, -SCROLL_X * 2, 1, -92), BackgroundTransparency = 1,
        ScrollBarThickness = 3, ScrollBarImageColor3 = B"Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = AUTO_Y,
        ScrollingDirection = Enum.ScrollingDirection.Y }, { new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }), pad(0, 14, 12, 18) })
    local topHolder = new("Frame", { Parent = scroll, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 },
        { new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }) })
    local colsHolder = new("Frame", { Parent = scroll, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 },
        { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }) })
    local function mkCol(o)
        return new("Frame", { Parent = colsHolder, LayoutOrder = o, Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 },
            { new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }) })
    end
    local colL, colR = mkCol(1), mkCol(2)
    local emptyL = label(content, "Nothing found.", UDim2.fromOffset(0, 220), UDim2.new(1, 0, 0, 20), Enum.Font.GothamMedium, 13, B"Sub", Enum.TextXAlignment.Center)
    emptyL.Visible = false

    local footerL = label(main, "", UDim2.fromOffset(238, H - 30), UDim2.fromOffset(420, 14), Enum.Font.GothamMedium, 10, B"Sub")
    label(main, cfg.Version or Lib.Version, UDim2.new(1, -150, 1, -30), UDim2.fromOffset(130, 14), Enum.Font.GothamMedium, 10, B"Sub", Enum.TextXAlignment.Right)
    local function setFooter() footerL.Text = keyName(Win.ToggleKey) .. " · HIDE   /   RMB · SETTINGS" end
    setFooter()

    local tip = new("TextLabel", { Parent = gui, Size = UDim2.new(0, 0, 0, 24), AutomaticSize = AUTO_X, BackgroundColor3 = B"Panel2",
        Text = "", TextColor3 = B"Text", TextSize = 11, Visible = false, ZIndex = 200 }, { corner(8), stk(), pad(0, 0, 10, 10) })
    local function showTip(text, obj)
        if not text or text == "" then return end
        tip.Text = text
        tip.Position = UDim2.fromOffset(obj.AbsolutePosition.X, obj.AbsolutePosition.Y - 32)
        tip.Visible = true
    end

    local nholder = new("Frame", { Parent = gui, AnchorPoint = V2(1, 0), Position = UDim2.new(1, -16, 0, 16), Size = UDim2.fromOffset(320, 500), BackgroundTransparency = 1, ZIndex = 100 })
    local nlist = new("UIListLayout", { Parent = nholder, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right })
    local nDir = 1
    function Win:SetNotifPos(name)
        local right, bottom = name:find("Right") ~= nil, name:find("Bottom") ~= nil
        nholder.AnchorPoint = V2(right and 1 or 0, bottom and 1 or 0)
        nholder.Position = UDim2.new(right and 1 or 0, right and -16 or 16, bottom and 1 or 0, bottom and -16 or 16)
        nlist.HorizontalAlignment = right and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
        nlist.VerticalAlignment = bottom and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top
        nDir = right and 1 or -1
    end
    local KIND = { ok = SEM.Green, warn = SEM.Yellow, err = SEM.Red }
    local notifStack = {}
    function Win:Notify(title, text, dur, kind, force)
        if not Win.NotifsOn and not force then return end
        dur = dur or Win.NotifTime
        title, text = tostring(title or ""), tostring(text or "")
        local dir = nDir
        local col = (typeof(kind) == "Color3" and kind) or (kind and KIND[kind]) or Theme.Accent
        local NW, TEXT_W = 300, 300 - 34
        local ok, sz = pcall(TextService.GetTextSize, TextService, text, 12, Enum.Font.Gotham, V2(TEXT_W, 1000))
        local textH = ok and sz.Y or 14
        local NH = 54 + textH
        while #notifStack >= 5 do
            local old = table.remove(notifStack, 1)
            if old and old.Close then old.Close() end
        end
        local wrap = new("Frame", { Parent = nholder, Size = UDim2.fromOffset(NW, NH), BackgroundTransparency = 1 })
        local card = new("CanvasGroup", { Parent = wrap, Position = UDim2.fromOffset((NW + 40) * dir, 0), Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Theme.Panel, GroupTransparency = 1 }, { corner(14), plainStroke(col, 1, 0.55) })
        new("Frame", { Parent = card, Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = col })
        label(card, title, UDim2.fromOffset(18, 10), UDim2.fromOffset(TEXT_W, 18), Enum.Font.GothamBold, 13, Theme.Text)
        label(card, text, UDim2.fromOffset(18, 30), UDim2.fromOffset(TEXT_W, textH), Enum.Font.Gotham, 12, Theme.Sub, nil,
            { TextWrapped = true, TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top })
        local trackF = new("Frame", { Parent = card, AnchorPoint = V2(0, 1), Position = UDim2.new(0, 18, 1, -8), Size = UDim2.new(1, -34, 0, 2),
            BackgroundColor3 = WHITE, BackgroundTransparency = 0.92 }, { corner(1) })
        local fill = new("Frame", { Parent = trackF, Size = UDim2.fromScale(1, 1), BackgroundColor3 = col }, { corner(1) })
        local closing = false
        local entry = {}
        local function close()
            if closing then return end
            closing = true
            for i, e in ipairs(notifStack) do if e == entry then table.remove(notifStack, i) break end end
            tw(card, 0.35, { Position = UDim2.fromOffset((NW + 40) * dir, 0), GroupTransparency = 1 }, QUINT, IN)
            task.delay(0.25, function() if wrap.Parent then tw(wrap, 0.25, { Size = UDim2.fromOffset(NW, 0) }, QUINT) end end)
            task.delay(0.55, function() if wrap.Parent then wrap:Destroy() end end)
        end
        entry.Close = close
        notifStack[#notifStack + 1] = entry
        local hit = new("TextButton", { Parent = card, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5 })
        hit.MouseButton1Click:Connect(close)
        tw(card, 0.5, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 }, QUINT)
        TweenService:Create(fill, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) }):Play()
        task.delay(dur, close)
    end

    local confirm = new("Frame", { Parent = main, Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, Visible = false, ZIndex = 80 })
    local cBox = new("Frame", { Parent = confirm, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, 150), BackgroundColor3 = B"Panel", ZIndex = 81 }, { corner(16), stk() })
    local cScale = new("UIScale", { Parent = cBox, Scale = 0.85 })
    local cTitle = label(cBox, "", UDim2.fromOffset(20, 18), UDim2.new(1, -40, 0, 22), Enum.Font.GothamBold, 16, B"Text") cTitle.ZIndex = 82
    local cText = label(cBox, "", UDim2.fromOffset(20, 46), UDim2.new(1, -40, 0, 40), Enum.Font.Gotham, 12, B"Sub", nil, { TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None }) cText.ZIndex = 82
    local function cBtn(txt, x, accent)
        return new("TextButton", { Parent = cBox, Position = UDim2.new(x, x == 0 and 20 or 8, 1, -50), Size = UDim2.new(0.5, -28, 0, 34),
            BackgroundColor3 = accent and B"Accent" or B"Panel2", Text = txt, TextColor3 = accent and B"OnAccent" or B"Text", Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 82 }, { corner(10) })
    end
    local cNo, cYes = cBtn("Cancel", 0, false), cBtn("Yes", 0.5, true)
    local confirmYes
    local function closeConfirm()
        tw(confirm, 0.2, { BackgroundTransparency = 1 }, SINE)
        tw(cScale, 0.2, { Scale = 0.88 }, QUINT, IN)
        task.delay(0.21, function() confirm.Visible = false end)
    end
    cNo.MouseButton1Click:Connect(closeConfirm)
    cYes.MouseButton1Click:Connect(function() closeConfirm() if confirmYes then confirmYes() end end)
    function Win:Confirm(title, text, yes)
        cTitle.Text, cText.Text = title, text
        confirmYes = yes
        confirm.Visible = true
        cScale.Scale = 0.85
        tw(confirm, 0.25, { BackgroundTransparency = 0.5 }, SINE)
        tw(cScale, 0.4, { Scale = 1 }, BACK)
    end

    local openBtn = new("TextButton", { Parent = gui, AnchorPoint = V2(1, 1), Position = UDim2.new(1, -24, 1, -24), Size = UDim2.fromOffset(48, 48),
        BackgroundColor3 = B"Accent", Visible = false, ZIndex = 70, Text = string.sub(cfg.Title or "F", 1, 1), TextColor3 = B"OnAccent", Font = Enum.Font.GothamBlack, TextSize = 20 }, { corner(24) })
    local openScale = new("UIScale", { Parent = openBtn })
    drag(openBtn, openBtn)
    openBtn.MouseEnter:Connect(function() tw(openScale, 0.3, { Scale = 1.1 }, BACK) end)
    openBtn.MouseLeave:Connect(function() tw(openScale, 0.3, { Scale = 1 }, SINE) end)

    local WM = {
        Enabled = false, Text = "{title} | {user} | {fps} fps | {ping} ms | {time}", Size = 1, Opacity = 0.92, TextSize = 13,
        Font = "GothamMedium", Round = 20, Bar = true, Border = true, Colors = true, TextMode = "Theme", TextCustom = WHITE,
        BgMode = "Panel", BgCustom = rgb(20, 20, 24), H24 = true, Pos = "Top Left", Last = "",
    }
    Win.WM = WM
    local wm = new("CanvasGroup", { Parent = gui, Size = UDim2.fromOffset(0, 30), AutomaticSize = AUTO_X, BackgroundColor3 = Theme.Panel,
        GroupTransparency = 1, Visible = false, ZIndex = 60 })
    local wmCorner = new("UICorner", { Parent = wm, CornerRadius = UDim.new(0, 15) })
    local wmStroke = new("UIStroke", { Parent = wm, Color = Theme.Accent, Transparency = 0.5, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    new("UIPadding", { Parent = wm, PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 16) })
    new("UIListLayout", { Parent = wm, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 9),
        VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder })
    local wmScale = new("UIScale", { Parent = wm })
    local wmBar = new("Frame", { Parent = wm, LayoutOrder = 0, Size = UDim2.fromOffset(3, 14), BackgroundColor3 = Theme.Accent }, { corner(2) })
    local wmLabel = new("TextLabel", { Parent = wm, LayoutOrder = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AUTO_X, BackgroundTransparency = 1,
        Text = "", RichText = true, TextSize = 13, TextColor3 = Theme.Text, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Left })
    place(wm, WM.Pos, 18)
    drag(wm, wm)

    local fpsNow, pingNow = 60, 0
    local ESC = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;" }
    local function tag(text, col) return '<font color="' .. hex(col) .. '">' .. text .. "</font>" end
    local TOK = {
        title = function() return cfg.Title or "FEMBOYSENSE" end,
        user = function() return LocalPlayer.Name end,
        name = function() return LocalPlayer.DisplayName end,
        fps = function()
            local t = tostring(fpsNow)
            if not WM.Colors then return t end
            return tag(t, fpsNow >= 55 and SEM.Green or (fpsNow >= 30 and SEM.Yellow or SEM.Red))
        end,
        ping = function()
            local t = tostring(pingNow)
            if not WM.Colors then return t end
            return tag(t, pingNow <= 80 and SEM.Green or (pingNow <= 150 and SEM.Yellow or SEM.Red))
        end,
        time = function() return os.date(WM.H24 and "%H:%M:%S" or "%I:%M:%S %p") end,
        date = function() return os.date("%d.%m.%Y") end,
        players = function() return #Players:GetPlayers() .. "/" .. Players.MaxPlayers end,
        game = function() return (game.Name:gsub("[&<>]", ESC)) end,
        version = function() return cfg.Version or Lib.Version end,
    }
    local function wmRefresh(force)
        local s = WM.Text:gsub("[&<>]", ESC)
        s = s:gsub("{(%a+)}", function(k) local f = TOK[k] if f then return f() end end)
        if force or s ~= WM.Last then
            WM.Last = s
            wmLabel.Text = s
        end
    end
    local function wmApply()
        local h = floor(WM.TextSize * 2.3)
        wm.Size = UDim2.fromOffset(0, h)
        wmCorner.CornerRadius = UDim.new(0, math.min(WM.Round, h / 2))
        wmLabel.TextSize = WM.TextSize
        local ok, f = pcall(function() return Enum.Font[WM.Font] end)
        wmLabel.Font = ok and f or Enum.Font.GothamMedium
        wmBar.Visible = WM.Bar
        wmBar.Size = UDim2.fromOffset(3, floor(h * 0.45))
        wmBar.BackgroundColor3 = Theme.Accent
        wmStroke.Enabled = WM.Border
        wmStroke.Color = Theme.Accent
        wmLabel.TextColor3 = WM.TextMode == "Custom" and WM.TextCustom or (WM.TextMode == "Accent" and Theme.Accent or Theme.Text)
        wm.BackgroundColor3 = WM.BgMode == "Custom" and WM.BgCustom or (WM.BgMode == "Accent" and Theme.Accent2:Lerp(Theme.Panel, 0.5) or Theme.Panel)
        wm.BackgroundTransparency = 1 - WM.Opacity
    end
    onTheme(wmApply)
    wmRefresh(true)

    local wmTok = 0
    function Win:SetWatermark(on)
        on = on and true or false
        WM.Enabled = on
        wmTok += 1
        local my = wmTok
        if on then
            wmRefresh(true)
            wm.Visible = true
            wmScale.Scale = WM.Size * 0.85
            tw(wm, 0.3, { GroupTransparency = 0 }, SINE)
            tw(wmScale, 0.45, { Scale = WM.Size }, BACK)
        else
            tw(wm, 0.22, { GroupTransparency = 1 }, SINE)
            tw(wmScale, 0.28, { Scale = WM.Size * 0.85 }, QUINT)
            task.delay(0.3 / Lib.Speed, function() if wmTok == my then wm.Visible = false end end)
        end
    end
    function Win:SetWM(k, v)
        WM[k] = v
        if k == "Enabled" then return Win:SetWatermark(v) end
        if k == "Size" then
            if WM.Enabled then tw(wmScale, 0.3, { Scale = v }, QUINT) end
            return
        end
        if k == "Pos" then place(wm, v, 18) return end
        wmApply()
        wmRefresh(true)
    end

    local HUD = { Enabled = false, Title = "KEYBINDS", ShowTitle = true, ShowMode = true, Size = 1, Opacity = 0.92, Pos = "Top Left" }
    Win.HUD = HUD
    local HUD_W, ROW_H = 208, 26
    local hud = new("CanvasGroup", { Parent = gui, Position = UDim2.fromOffset(18, 64), Size = UDim2.fromOffset(HUD_W, 0), AutomaticSize = AUTO_Y,
        BackgroundColor3 = Theme.Panel, BackgroundTransparency = 1 - HUD.Opacity, GroupTransparency = 1, Visible = false, ZIndex = 60 },
        { corner(14), pad(8, 8, 8, 8), new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })
    local hudScale = new("UIScale", { Parent = hud })
    local hudStroke = new("UIStroke", { Parent = hud, Color = Theme.Accent, Transparency = 0.6, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    local hudHead = new("Frame", { Parent = hud, LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 })
    local hudTitle = label(hudHead, HUD.Title, UDim2.fromOffset(6, 0), UDim2.new(1, -40, 1, 0), Enum.Font.GothamBlack, 11, Theme.Text)
    local hudCount = new("TextLabel", { Parent = hudHead, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(0, 18), AutomaticSize = AUTO_X,
        BackgroundColor3 = Theme.Accent2, BackgroundTransparency = 0.35, Text = "0", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Theme.Text },
        { corner(9), pad(0, 0, 8, 8), new("UISizeConstraint", { MinSize = V2(22, 18) }) })
    local hudLine = new("Frame", { Parent = hud, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Accent })
    local hudLineGrad = new("UIGradient", { Parent = hudLine, Transparency = NumberSequence.new({ nk(0, 0.2), nk(0.6, 0.8), nk(1, 1) }) })
    new("Frame", { Parent = hud, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 3), BackgroundTransparency = 1 })
    place(hud, HUD.Pos, 64)
    drag(hud, hud)

    local hudRows = {}
    local function paintRow(r)
        r.Bar.BackgroundColor3 = Theme.Accent
        r.Name.TextColor3 = Theme.Text
        r.Mode.TextColor3 = Theme.Sub
        r.Cap.BackgroundColor3 = Theme.Accent
        r.Cap.TextColor3 = Theme.OnAccent
    end
    onTheme(function()
        hudStroke.Color = Theme.Accent
        hudTitle.TextColor3 = Theme.Text
        hudCount.BackgroundColor3 = Theme.Accent2
        hudCount.TextColor3 = Theme.Text
        hudLine.BackgroundColor3 = Theme.Accent
        hud.BackgroundColor3 = Theme.Panel
        for _, r in pairs(hudRows) do paintRow(r) end
    end)

    local function newRow()
        local r = { tok = 0, shown = false }
        r.Frame = new("Frame", { Parent = hud, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true })
        r.Inner = new("CanvasGroup", { Parent = r.Frame, Size = UDim2.new(1, 0, 0, ROW_H), BackgroundTransparency = 1, GroupTransparency = 1 })
        r.Scale = new("UIScale", { Parent = r.Inner, Scale = 0.85 })
        r.Bar = new("Frame", { Parent = r.Inner, AnchorPoint = V2(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(3, 12) }, { corner(2) })
        r.Name = label(r.Inner, "", UDim2.fromOffset(18, 0), UDim2.new(1, -92, 1, 0), Enum.Font.GothamMedium, 12, Theme.Text)
        local right = new("Frame", { Parent = r.Inner, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(0, 22),
            AutomaticSize = AUTO_X, BackgroundTransparency = 1 },
            { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
                VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }) })
        r.Mode = new("TextLabel", { Parent = right, LayoutOrder = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AUTO_X, BackgroundTransparency = 1,
            Text = "HOLD", Font = Enum.Font.GothamBold, TextSize = 8, TextTransparency = 0.2, Visible = false })
        r.Cap = new("TextLabel", { Parent = right, LayoutOrder = 2, Size = UDim2.fromOffset(0, 20), AutomaticSize = AUTO_X, Text = "",
            Font = Enum.Font.GothamBold, TextSize = 10 }, { corner(6), pad(0, 0, 7, 7), new("UISizeConstraint", { MinSize = V2(24, 20) }) })
        paintRow(r)
        return r
    end
    local function rowIn(r)
        r.tok += 1
        r.Frame.Visible = true
        tw(r.Frame, 0.35, { Size = UDim2.new(1, 0, 0, ROW_H) }, QUINT)
        tw(r.Inner, 0.3, { GroupTransparency = 0 }, SINE)
        tw(r.Scale, 0.45, { Scale = 1 }, BACK)
    end
    local function rowOut(b, r)
        r.tok += 1
        local my = r.tok
        tw(r.Frame, 0.3, { Size = UDim2.new(1, 0, 0, 0) }, QUINT)
        tw(r.Inner, 0.2, { GroupTransparency = 1 }, SINE)
        tw(r.Scale, 0.3, { Scale = 0.85 }, QUINT)
        task.delay(0.34 / Lib.Speed, function()
            if r.tok == my and r.Frame.Parent then
                r.Frame:Destroy()
                if hudRows[b] == r then hudRows[b] = nil end
            end
        end)
    end

    local hudShown, hudTok = false, 0
    local function doRefreshHud()
        local n = 0
        for i, b in ipairs(Win.BindList) do
            local want = HUD.Enabled and b.Hud ~= false and b.Key ~= nil and b.State == true and not b.Static
            local r = hudRows[b]
            if want then
                n += 1
                if not r then r = newRow() hudRows[b] = r end
                r.Frame.LayoutOrder = 10 + i
                r.Name.Text = tostring(b.Name or "?")
                r.Cap.Text = keyName(b.Key)
                r.Mode.Visible = HUD.ShowMode and b.Mode == "Hold"
                if not r.shown then r.shown = true rowIn(r) end
            elseif r and r.shown then
                r.shown = false
                rowOut(b, r)
            end
        end
        hudCount.Text = tostring(n)
        local want = HUD.Enabled and n > 0
        if want and not hudShown then
            hudShown = true
            hudTok += 1
            hud.Visible = true
            hudScale.Scale = HUD.Size * 0.9
            tw(hud, 0.3, { GroupTransparency = 0 }, SINE)
            tw(hudScale, 0.45, { Scale = HUD.Size }, BACK)
        elseif not want and hudShown then
            hudShown = false
            hudTok += 1
            local my = hudTok
            tw(hud, 0.3, { GroupTransparency = 1 }, SINE)
            tw(hudScale, 0.35, { Scale = HUD.Size * 0.9 }, QUINT)
            task.delay(0.4 / Lib.Speed, function() if hudTok == my then hud.Visible = false end end)
        end
    end
    local hudQueued = false
    function Win:RefreshHud()
        if hudQueued then return end
        hudQueued = true
        task.defer(function()
            hudQueued = false
            doRefreshHud()
        end)
    end
    function Win:SetHud(k, v)
        HUD[k] = v
        if k == "Enabled" or k == "ShowMode" then Win:RefreshHud()
        elseif k == "Size" then if hudShown then tw(hudScale, 0.3, { Scale = v }, QUINT) end
        elseif k == "Opacity" then hud.BackgroundTransparency = 1 - v
        elseif k == "Pos" then place(hud, v, 64)
        elseif k == "Title" then hudTitle.Text = v
        elseif k == "ShowTitle" then hudHead.Visible = v hudLine.Visible = v end
    end

    local frames, accFps, decorAcc, wmAcc = 0, 0, 0, 0
    keep(RunService.RenderStepped:Connect(function(dt)
        local open = Win.Open
        local wantModal = Win.FreeMouse and open
        if modalBtn.Modal ~= wantModal then modalBtn.Modal = wantModal end
        frames += 1
        accFps += dt
        if accFps >= 0.5 then
            fpsNow = floor(frames / accFps + 0.5)
            frames, accFps = 0, 0
            pcall(function() pingNow = floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        end
        decorAcc += dt
        if decorAcc >= 1 / 30 then
            local d = decorAcc
            decorAcc = 0
            if open then
                if Win.BorderSpin ~= 0 then ringGrad.Rotation = (ringGrad.Rotation + d * Win.BorderSpin) % 360 end
                if Win.BorderPulse then mainStroke.Transparency = clamp(Win._glowT + 0.15 * sin(os.clock() * 2.4), 0, 1) end
            end
            wmAcc += d
            if wmAcc >= 0.25 then
                wmAcc = 0
                if WM.Enabled then wmRefresh(false) end
            end
        end
    end))

    local function layoutNav()
        local y = 0
        for _, g in ipairs(Win.Groups) do
            if #g.cats > 0 then
                if g.Head then
                    g.Head.Position = UDim2.fromOffset(0, y)
                    g.Head.Visible = true
                    y += HEAD_H
                end
                for _, c in ipairs(g.cats) do
                    c.Y = y
                    c.Btn.Position = UDim2.fromOffset(0, y)
                    y += NAV_STEP
                end
                y += GAP
            elseif g.Head then
                g.Head.Visible = false
            end
        end
        nav.CanvasSize = UDim2.fromOffset(0, y + 6)
    end

    function Win:AddGroup(name)
        local g = { name = name, cats = {} }
        if name ~= "" then
            g.Head = new("Frame", { Parent = nav, Size = UDim2.new(1, 0, 0, HEAD_H), BackgroundTransparency = 1, Visible = false })
            label(g.Head, name, UDim2.fromOffset(6, 2), UDim2.new(1, -12, 1, -4), Enum.Font.GothamBold, 10, B"Sub")
            new("Frame", { Parent = g.Head, Position = UDim2.new(0, 6, 1, -3), Size = UDim2.new(1, -12, 0, 1), BackgroundColor3 = B"Accent", BackgroundTransparency = 0.7 })
        end
        Win.Groups[#Win.Groups + 1] = g
        Win._group = g
        return g
    end

    local layoutTok = 0
    local function layout()
        local cat = Win.Current
        if not cat then return end
        layoutTok += 1
        local tok = layoutTok
        for _, m in ipairs(Win.Modules) do m.Holder.Parent = stash end
        for _, c in ipairs(Win.Categories) do for _, t in ipairs(c.Tops) do t.Parent = stash end end
        local q = Win.Query
        local list = {}
        for _, m in ipairs(q ~= "" and Win.Modules or cat.Modules) do
            if q == "" or m.Search:find(q, 1, true) then list[#list + 1] = m end
        end
        local tops = 0
        if q == "" then
            for _, t in ipairs(cat.Tops) do t.Parent = topHolder tops += 1 end
        end
        for i, m in ipairs(list) do
            m.Holder.Parent = (i % 2 == 1) and colL or colR
            m.Card.GroupTransparency = 1
            m.Scale.Scale = 0.95
            task.delay(0.02 + math.min(i - 1, 8) * 0.04, function()
                if tok == layoutTok and m.Holder.Parent ~= stash then
                    tw(m.Card, 0.4, { GroupTransparency = 0 }, SINE)
                    tw(m.Scale, 0.5, { Scale = 1 }, BACK)
                end
            end)
        end
        if q == "" and cat.OnShow then task.defer(cat.OnShow) end
        emptyL.Visible = (#list == 0 and tops == 0)
        if q ~= "" then
            pageTitle.Text = "Search"
            pageSub.Text = 'Results for "' .. searchBox.Text .. '"'
        else
            pageTitle.Text, pageSub.Text = cat.Name, cat.Sub
        end
        pageTitle.TextTransparency, pageSub.TextTransparency = 1, 1
        pageTitle.Position = UDim2.fromOffset(8, 14)
        tw(pageTitle, 0.45, { TextTransparency = 0, Position = UDim2.fromOffset(22, 14) }, QUINT)
        tw(pageSub, 0.6, { TextTransparency = 0 }, SINE)
        titleBar.Size = UDim2.fromOffset(0, 2)
        tw(titleBar, 0.5, { Size = UDim2.fromOffset(38, 2) }, QUINT)
        scroll.CanvasPosition = Vector2.zero
        scroll.Position = UDim2.fromOffset(SCROLL_X, 100)
        tw(scroll, 0.5, { Position = UDim2.fromOffset(SCROLL_X, 80) }, QUINT)
    end
    Win.Relayout = layout

    local function paintNav()
        for _, c in ipairs(Win.Categories) do
            local on = (c == Win.Current)
            tw(c.Label, 0.25, { TextColor3 = on and Theme.Text or Theme.Sub }, SINE)
            c.Icon:Paint(on and Theme.Accent or Theme.Sub)
        end
    end
    onTheme(paintNav)

    function Win:Select(cat)
        if type(cat) == "string" then
            for _, c in ipairs(Win.Categories) do if c.Name == cat then cat = c break end end
        end
        if type(cat) ~= "table" then return end
        local first = (Win.Current == nil)
        Win.Current = cat
        paintNav()
        navInd.Visible = true
        if cat.Y then
            if first then navInd.Position = UDim2.fromOffset(0, cat.Y) else tw(navInd, 0.45, { Position = UDim2.fromOffset(0, cat.Y) }, BACK) end
            local vis, cy = nav.AbsoluteSize.Y, nav.CanvasPosition.Y
            if cat.Y < cy then tw(nav, 0.4, { CanvasPosition = V2(0, cat.Y) }, QUINT)
            elseif cat.Y + 44 > cy + vis then tw(nav, 0.4, { CanvasPosition = V2(0, cat.Y + 44 - vis) }, QUINT) end
        end
        layout()
    end

    local function gotoCat(cat)
        if not cat then return end
        searchBox.Text = ""
        Win.Query = ""
        Win:Select(cat)
    end

    function Win:AddCategory(name, icon, sub)
        if not Win._group then Win:AddGroup("") end
        local grp = Win._group
        local cat = { Name = name, Sub = sub or "", Tops = {}, Modules = {}, Group = grp, Y = 0, IconId = icon }
        local btn = new("TextButton", { Parent = nav, Size = UDim2.new(1, -4, 0, 40), BackgroundTransparency = 1, ZIndex = 2 })
        cat.Btn = btn
        cat.Icon = makeIcon(btn, icon, UDim2.fromOffset(14, 11), 18)
        cat.Label = label(btn, name, UDim2.fromOffset(44, 0), UDim2.new(1, -52, 1, 0), Enum.Font.GothamMedium, 14, B"Sub")
        cat.Label.ZIndex = 3
        btn.MouseEnter:Connect(function()
            if Win.Current ~= cat then
                tw(cat.Label, 0.2, { TextColor3 = Theme.Text }, SINE)
                cat.Icon:Paint(Theme.Text)
            end
            tw(cat.Label, 0.3, { Position = UDim2.fromOffset(48, 0) }, QUINT)
        end)
        btn.MouseLeave:Connect(function()
            tw(cat.Label, 0.3, { Position = UDim2.fromOffset(44, 0) }, QUINT)
            if Win.Current ~= cat then
                tw(cat.Label, 0.25, { TextColor3 = Theme.Sub }, SINE)
                cat.Icon:Paint(Theme.Sub)
            end
        end)
        btn.MouseButton1Click:Connect(function() gotoCat(cat) end)

        function cat:AddCustom(h)
            local f = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = #cat.Tops + 1 })
            cat.Tops[#cat.Tops + 1] = f
            return f
        end

        function cat:AddModule(o)
            o = o or {}
            local defKey = (o.Keybind ~= true) and o.Keybind or nil
            local mod = { Name = o.Name or "Module", Info = o.Info, Cat = cat, State = o.Default and true or false, Key = defKey, DefaultKey = defKey,
                Mode = o.Mode or "Toggle", Static = o.Static, Hud = o.Hud ~= false, _n = 0,
                Search = ((o.Name or "") .. " " .. (o.Info or "")):lower() }
            local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 })
            mod.Scale = new("UIScale", { Parent = holder })
            local card = new("CanvasGroup", { Parent = holder, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundColor3 = B"Panel" },
                { corner(16), pad(14, 14, 16, 16), new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
            local cardStroke = stk()
            cardStroke.Parent = card
            glassT(card, 0.1)
            mod.Card, mod.Holder = card, holder
            holder.Parent = stash
            card.MouseEnter:Connect(function()
                tw(card, 0.3, { BackgroundColor3 = Theme.Panel:Lerp(Theme.Panel2, 0.45) }, SINE)
                tw(cardStroke, 0.3, { Color = Theme.Accent, Transparency = 0.7 }, SINE)
            end)
            card.MouseLeave:Connect(function()
                tw(card, 0.35, { BackgroundColor3 = Theme.Panel }, SINE)
                tw(cardStroke, 0.35, { Color = Theme.Stroke, Transparency = Theme.StrokeT }, SINE)
            end)

            local head = new("Frame", { Parent = card, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 })
            local left = new("Frame", { Parent = head, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AUTO_X, BackgroundTransparency = 1 },
                { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 9), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })
            local ih = new("Frame", { Parent = left, LayoutOrder = 1, Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1 })
            makeIcon(ih, o.Icon or cat.IconId, UDim2.fromOffset(1, 1), 18):Bind("Text")
            new("TextLabel", { Parent = left, LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AUTO_X, BackgroundTransparency = 1,
                Text = mod.Name, TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 15 })
            if o.Info then
                local i = new("TextButton", { Parent = left, LayoutOrder = 3, Size = UDim2.fromOffset(15, 15), BackgroundTransparency = 1, Text = "i",
                    TextColor3 = B"Sub", Font = Enum.Font.GothamBold, TextSize = 9 }, { corner(8), new("UIStroke", { Color = B"Sub", Thickness = 1, Transparency = 0.4 }) })
                i.MouseEnter:Connect(function() showTip(o.Info, i) end)
                i.MouseLeave:Connect(function() tip.Visible = false end)
            end

            local sf = new("Frame", { Parent = card, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1, Visible = false },
                { new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
            local sfLayout = sf:FindFirstChildOfClass("UIListLayout")
            mod.Settings = sf

            local expand
            local open, tok = false, 0
            local function setOpen(v, instant)
                open = v
                tok += 1
                local my = tok
                if expand then tw(expand, 0.35, { Rotation = v and 45 or 0, TextColor3 = v and Theme.Accent or Theme.Sub }, BACK) end
                if instant then sf.Visible = v return end
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
                        tw(sf, 0.3, { Size = UDim2.new(1, 0, 0, 0) }, QUINT).Completed:Wait()
                        if tok ~= my then return end
                        sf.Visible = false
                        sf.AutomaticSize = AUTO_Y
                        sf.ClipsDescendants = false
                    end
                end)
            end

            if mod.Static then
                setOpen(true, true)
                function mod:Set() end
                function mod:SetKey() end
            else
                expand = new("TextButton", { Parent = head, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(22, 22),
                    BackgroundTransparency = 1, Text = "+", TextColor3 = B"Sub", Font = Enum.Font.GothamMedium, TextSize = 20 })
                expand.MouseButton1Click:Connect(function() setOpen(not open) end)

                local status = new("Frame", { Parent = card, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 })
                local stL = label(status, "Disabled", nil, UDim2.new(1, -140, 1, 0), Enum.Font.GothamMedium, 13, B"Sub")
                local pill = new("TextButton", { Parent = status, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -50, 0.5, 0), Size = UDim2.fromOffset(0, 22), AutomaticSize = AUTO_X,
                    BackgroundColor3 = B"Panel2", Text = "BIND", TextColor3 = B"Sub", Font = Enum.Font.GothamBold, TextSize = 10 }, { corner(7), pad(0, 0, 9, 9) })
                local pillScale = new("UIScale", { Parent = pill })
                local function paintPill(listening)
                    pill.Text = listening and "..." or (mod.Key and keyName(mod.Key) or "BIND")
                    tw(pill, 0.25, { BackgroundColor3 = (listening or mod.Key) and Theme.Accent or Theme.Panel2, TextColor3 = (listening or mod.Key) and Theme.OnAccent or Theme.Sub }, SINE)
                    if not listening then
                        pillScale.Scale = 0.88
                        tw(pillScale, 0.35, { Scale = 1 }, BACK)
                    end
                end
                mod.PaintPill = paintPill
                local sw
                sw = makeSwitch(status, mod.State, function(v) mod:Set(v) end)
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
                function mod:SetKey(k, silent)
                    mod.Key = k
                    paintPill(false)
                    if mod.KeyRow then mod.KeyRow(k) end
                    Win:RefreshHud()
                    if not silent then fire(o.KeyChanged, k) end
                end
                local function listen()
                    paintPill(true)
                    Lib._listen = function(k)
                        if k == Enum.KeyCode.Escape or k == Enum.KeyCode.Backspace then mod:SetKey(nil) else mod:SetKey(k) end
                    end
                end
                pill.MouseButton1Click:Connect(listen)
                paintPill(false)
                if mod.State then
                    stL.Text = "Enabled"
                    stL.TextColor3 = Theme.Text
                    task.defer(fire, o.Callback, true)
                end
                card.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton2 then setOpen(not open)
                    elseif i.UserInputType == Enum.UserInputType.MouseButton3 then listen() end
                end)

                local krow = new("Frame", { Parent = sf, LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 })
                label(krow, "Keybind", nil, UDim2.new(1, -200, 1, 0), Enum.Font.GothamMedium, 13, B"Text")
                local modeB = new("TextButton", { Parent = krow, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -86, 0.5, 0), Size = UDim2.fromOffset(62, 24),
                    BackgroundColor3 = B"Panel2", Text = mod.Mode, TextColor3 = B"Sub", Font = Enum.Font.GothamBold, TextSize = 10 }, { corner(8) })
                modeB.MouseButton1Click:Connect(function()
                    mod.Mode = mod.Mode == "Toggle" and "Hold" or "Toggle"
                    modeB.Text = mod.Mode
                    Win:RefreshHud()
                end)
                local kb = new("TextButton", { Parent = krow, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(78, 24),
                    BackgroundColor3 = B"Panel2", Text = "", TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 10 }, { corner(8) })
                local rb = resetBtn(krow, UDim2.new(1, -156, 0.5, 0), function() mod:SetKey(mod.DefaultKey) end)
                local function paintKb(k)
                    kb.Text = k and keyName(k) or "NONE"
                    rb.Visible = (mod.Key ~= mod.DefaultKey)
                end
                paintKb(mod.Key)
                mod.KeyRow = paintKb
                kb.MouseButton1Click:Connect(function()
                    kb.Text = "..."
                    Lib._listen = function(k)
                        if k == Enum.KeyCode.Escape or k == Enum.KeyCode.Backspace then mod:SetKey(nil) else mod:SetKey(k) end
                    end
                end)
                mod.ModeBtn = modeB
                Win.BindList[#Win.BindList + 1] = mod
                mod.Press = function(down)
                    if mod.Mode == "Hold" then mod:Set(down) elseif down then mod:Set(not mod.State) end
                end
            end

            function mod:Get() return mod.State end
            local function order() mod._n += 1 return mod._n end
            local function addWord(w) mod.Search = mod.Search .. " " .. tostring(w):lower() end

            function mod:AddToggle(t)
                addWord(t.Name or "")
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 })
                label(row, t.Name or "Toggle", nil, UDim2.new(1, -56, 1, 0), Enum.Font.GothamMedium, 13, B"Text")
                local sw = makeSwitch(row, t.Default, function(v) fire(t.Callback, v) end)
                local api = { Row = row }
                function api:Set(v, silent) sw:Set(v, silent) end
                function api:Get() return sw:Get() end
                api.Export = function() return sw:Get() end
                api.Import = function(v) sw:Set(v and true or false) end
                flag(t, api)
                if t.Default then task.defer(fire, t.Callback, true) end
                return api
            end

            function mod:AddSlider(t)
                addWord(t.Name or "")
                t.Order = order()
                local api = makeSlider(sf, t)
                api.Export = function() return api:Get() end
                api.Import = function(v) if type(v) == "number" then api:Set(v) end end
                flag(t, api)
                return api
            end

            function mod:AddOptions(t)
                addWord(t.Name or "")
                local opts = t.Options or {}
                local sel = t.Default or opts[1]
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 },
                    { new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
                label(row, t.Name or "Options", nil, UDim2.new(1, 0, 0, 16), Enum.Font.GothamMedium, 12, B"Sub", nil, { LayoutOrder = 1 })
                local wrapF = new("Frame", { Parent = row, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 },
                    { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
                local btns = {}
                local function paint()
                    for name, b in pairs(btns) do
                        local on = name == sel
                        tw(b, 0.3, { BackgroundColor3 = on and Theme.Accent or Theme.Panel2, TextColor3 = on and Theme.OnAccent or Theme.Sub }, SINE)
                    end
                end
                for i, name in ipairs(opts) do
                    local b = new("TextButton", { Parent = wrapF, LayoutOrder = i, Size = UDim2.fromOffset(0, 26), AutomaticSize = AUTO_X, BackgroundColor3 = B"Panel2",
                        Text = tostring(name), TextColor3 = B"Sub", Font = Enum.Font.GothamBold, TextSize = 11 }, { corner(8), pad(0, 0, 12, 12) })
                    btns[name] = b
                    b.MouseButton1Click:Connect(function()
                        if sel ~= name then
                            sel = name
                            paint()
                            fire(t.Callback, name)
                        end
                    end)
                end
                paint()
                onTheme(paint)
                local api = {}
                function api:Set(v, silent) if btns[v] and v ~= sel then sel = v paint() if not silent then fire(t.Callback, v) end end end
                function api:Get() return sel end
                api.Export = function() return sel end
                api.Import = function(v) api:Set(v) end
                flag(t, api)
                return api
            end

            function mod:AddDropdown(t)
                addWord(t.Name or "")
                local opts = t.Options or {}
                local sel = t.Default or opts[1]
                local ROW, ITEM, MAXV = 28, 26, 7
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, ROW), BackgroundTransparency = 1, ClipsDescendants = true })
                label(row, t.Name or "Dropdown", UDim2.new(), UDim2.new(1, -150, 0, ROW), Enum.Font.GothamMedium, 13, B"Text")
                local selL = label(row, tostring(sel or "-"), UDim2.new(1, -150, 0, 0), UDim2.fromOffset(130, ROW), Enum.Font.GothamBold, 12, B"Accent", Enum.TextXAlignment.Right)
                local arrow = label(row, "v", UDim2.new(1, -14, 0, 0), UDim2.fromOffset(14, ROW), Enum.Font.GothamBold, 11, B"Sub", Enum.TextXAlignment.Center)
                local list = new("ScrollingFrame", { Parent = row, Position = UDim2.fromOffset(0, ROW + 4), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
                    ScrollBarThickness = 2, ScrollBarImageColor3 = B"Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = AUTO_Y },
                    { new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
                local open, btns = false, {}
                local function listH() return math.min(#opts, MAXV) * (ITEM + 4) end
                local function setOpen(v)
                    open = v
                    tw(row, 0.4, { Size = UDim2.new(1, 0, 0, v and (ROW + 4 + listH()) or ROW) }, QUINT)
                    tw(list, 0.4, { Size = UDim2.new(1, 0, 0, v and listH() or 0) }, QUINT)
                    tw(arrow, 0.3, { Rotation = v and 180 or 0 }, BACK)
                end
                local function paint()
                    for name, b in pairs(btns) do
                        local on = name == sel
                        tw(b, 0.3, { BackgroundColor3 = on and Theme.Accent or Theme.Panel2, TextColor3 = on and Theme.OnAccent or Theme.Sub }, SINE)
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
                function api:SetSilent(v) if btns[v] then choose(v, true) end end
                function api:Get() return sel end
                function api:Refresh(newOpts)
                    opts = newOpts
                    if not table.find(opts, sel) then sel = opts[1] end
                    selL.Text = tostring(sel or "-")
                    build()
                end
                api.Export = function() return sel end
                api.Import = function(v) api:Set(v) end
                flag(t, api)
                return api
            end

            function mod:AddButton(t)
                addWord(t.Name or "")
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 })
                label(row, t.Name or "Button", nil, UDim2.new(1, -90, 1, 0), Enum.Font.GothamMedium, 13, B"Text")
                local b = new("TextButton", { Parent = row, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(78, 26),
                    BackgroundColor3 = B"Panel2", Text = t.ButtonText or "RUN", TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 11 }, { corner(8) })
                local sc = new("UIScale", { Parent = b })
                b.MouseEnter:Connect(function() tw(b, 0.2, { BackgroundColor3 = Theme.Accent, TextColor3 = Theme.OnAccent }, SINE) end)
                b.MouseLeave:Connect(function() tw(b, 0.25, { BackgroundColor3 = Theme.Panel2, TextColor3 = Theme.Text }, SINE) end)
                b.MouseButton1Down:Connect(function() tw(sc, 0.08, { Scale = 0.92 }, SINE) end)
                b.MouseButton1Up:Connect(function() tw(sc, 0.3, { Scale = 1 }, BACK) end)
                b.MouseButton1Click:Connect(function() fire(t.Callback) end)
                return { Row = row, Button = b }
            end

            function mod:AddTextbox(t)
                addWord(t.Name or "")
                local wide = t.Wide == true
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, wide and 56 or 30), BackgroundTransparency = 1 })
                label(row, t.Name or "Textbox", nil, wide and UDim2.new(1, 0, 0, 20) or UDim2.new(1, -150, 1, 0), Enum.Font.GothamMedium, 13, B"Text")
                local back = new("Frame", { Parent = row, AnchorPoint = V2(1, wide and 1 or 0.5), Position = UDim2.new(1, 0, wide and 1 or 0.5, 0),
                    Size = wide and UDim2.new(1, 0, 0, 30) or UDim2.fromOffset(140, 28), BackgroundColor3 = B"Bg" }, { corner(9) })
                local bs = new("UIStroke", { Color = B"Accent", Transparency = 1, Thickness = 1.2, Parent = back })
                local box = new("TextBox", { Parent = back, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1,
                    PlaceholderText = t.Placeholder or "", PlaceholderColor3 = B"Sub", Text = t.Default or "", TextColor3 = B"Text", TextSize = 12,
                    ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left })
                box.Focused:Connect(function() tw(bs, 0.25, { Transparency = 0.4 }, SINE) end)
                box.FocusLost:Connect(function(enter)
                    tw(bs, 0.3, { Transparency = 1 }, SINE)
                    fire(t.Callback, box.Text, enter)
                end)
                if t.Live then
                    box:GetPropertyChangedSignal("Text"):Connect(function() fire(t.Callback, box.Text, false) end)
                end
                local api = {}
                function api:Set(v) box.Text = tostring(v) end
                function api:Get() return box.Text end
                api.Export = function() return box.Text end
                api.Import = function(v) if type(v) == "string" then box.Text = v fire(t.Callback, v, false) end end
                flag(t, api)
                return api
            end

            function mod:AddLabel(text, h)
                return label(sf, text, nil, UDim2.new(1, 0, 0, h or 30), Enum.Font.Gotham, 11, B"Sub", nil,
                    { LayoutOrder = order(), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None })
            end
            function mod:AddCustom(h)
                return new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1 })
            end

            function mod:AddKeybind(t)
                addWord(t.Name or "")
                local b = { Name = t.Name, Key = t.Default, Default = t.Default, Mode = t.Mode or "Press", Callback = t.Callback, State = false, Hud = t.Hud ~= false }
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 })
                label(row, t.Name or "Keybind", nil, UDim2.new(1, -200, 1, 0), Enum.Font.GothamMedium, 13, B"Text")
                local modeB = new("TextButton", { Parent = row, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -86, 0.5, 0), Size = UDim2.fromOffset(62, 24),
                    BackgroundColor3 = B"Panel2", Text = b.Mode, TextColor3 = B"Sub", Font = Enum.Font.GothamBold, TextSize = 10 }, { corner(8) })
                local MODES = { "Press", "Toggle", "Hold" }
                modeB.MouseButton1Click:Connect(function()
                    b.Mode = MODES[(table.find(MODES, b.Mode) or 1) % 3 + 1]
                    b.State = false
                    modeB.Text = b.Mode
                    Win:RefreshHud()
                end)
                local kb = new("TextButton", { Parent = row, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(78, 24),
                    BackgroundColor3 = B"Panel2", Text = "", TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 10 }, { corner(8) })
                local paint
                local rb = resetBtn(row, UDim2.new(1, -156, 0.5, 0), function()
                    b.Key = b.Default
                    paint()
                    Win:RefreshHud()
                    if t.Changed then fire(t.Changed, b.Key) end
                end)
                paint = function()
                    kb.Text = b.Key and keyName(b.Key) or "NONE"
                    rb.Visible = (b.Key ~= b.Default)
                end
                paint()
                kb.MouseButton1Click:Connect(function()
                    kb.Text = "..."
                    Lib._listen = function(k)
                        if k == Enum.KeyCode.Escape or k == Enum.KeyCode.Backspace then b.Key = nil else b.Key = k end
                        paint()
                        Win:RefreshHud()
                        if t.Changed then fire(t.Changed, b.Key) end
                    end
                end)
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
                api.Export = function() return { Key = keyToName(b.Key), Mode = b.Mode } end
                api.Import = function(v)
                    if type(v) ~= "table" then return end
                    b.Key = v.Key and keyFromName(v.Key) or nil
                    if v.Mode and table.find(MODES, v.Mode) then b.Mode = v.Mode modeB.Text = v.Mode end
                    paint()
                    Win:RefreshHud()
                    if t.Changed then fire(t.Changed, b.Key) end
                end
                flag(t, api)
                return api
            end

            function mod:AddColorPicker(t)
                addWord(t.Name or "")
                local col = t.Default or WHITE
                local hh, ss, vv = col:ToHSV()
                local OPEN_H = 212
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, ClipsDescendants = true })
                label(row, t.Name or "Color", UDim2.new(), UDim2.new(1, -120, 0, 26), Enum.Font.GothamMedium, 13, B"Text")
                local hexL = label(row, "#FFFFFF", UDim2.new(1, -118, 0, 0), UDim2.fromOffset(70, 26), Enum.Font.GothamBold, 11, B"Sub", Enum.TextXAlignment.Right)
                local sw = new("TextButton", { Parent = row, AnchorPoint = V2(1, 0), Position = UDim2.new(1, 0, 0, 3), Size = UDim2.fromOffset(40, 20), BackgroundColor3 = col },
                    { corner(7), new("UIStroke", { Color = WHITE, Transparency = 0.7, Thickness = 1 }) })
                local sv = new("Frame", { Parent = row, Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 112), BackgroundColor3 = Color3.fromHSV(hh, 1, 1), ClipsDescendants = true }, { corner(8) })
                new("Frame", { Parent = sv, Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, ZIndex = 2 }, { new("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
                new("Frame", { Parent = sv, Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, ZIndex = 3 }, { new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
                local svK = new("Frame", { Parent = sv, AnchorPoint = V2(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ZIndex = 4 },
                    { corner(6), new("UIStroke", { Color = WHITE, Thickness = 2 }) })
                local hue = new("Frame", { Parent = row, Position = UDim2.fromOffset(0, 154), Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = WHITE }, {
                    corner(7), new("UIGradient", { Color = ColorSequence.new({ kp(0, rgb(255, 0, 0)), kp(1 / 6, rgb(255, 255, 0)), kp(2 / 6, rgb(0, 255, 0)),
                        kp(3 / 6, rgb(0, 255, 255)), kp(4 / 6, rgb(0, 0, 255)), kp(5 / 6, rgb(255, 0, 255)), kp(1, rgb(255, 0, 0)) }) }) })
                local hK = new("Frame", { Parent = hue, AnchorPoint = V2(0.5, 0.5), Size = UDim2.fromOffset(8, 20), BackgroundColor3 = WHITE, ZIndex = 3 },
                    { corner(4), new("UIStroke", { Color = BLACK, Transparency = 0.3 }) })
                local hexBack = new("Frame", { Parent = row, Position = UDim2.fromOffset(0, 178), Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = B"Bg" }, { corner(9) })
                local hexStroke = new("UIStroke", { Color = B"Accent", Transparency = 1, Thickness = 1.2, Parent = hexBack })
                local hexBox = new("TextBox", { Parent = hexBack, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1,
                    PlaceholderText = "#RRGGBB", PlaceholderColor3 = B"Sub", Text = "", TextColor3 = B"Text", TextSize = 12, ClearTextOnFocus = false,
                    TextXAlignment = Enum.TextXAlignment.Left })
                local lastE, trailing = 0, false
                local function emit()
                    local now = os.clock()
                    if now - lastE >= 0.06 then
                        lastE = now
                        fire(t.Callback, col)
                    elseif not trailing then
                        trailing = true
                        task.delay(0.06, function()
                            trailing = false
                            lastE = os.clock()
                            fire(t.Callback, col)
                        end)
                    end
                end
                local function refresh(silent)
                    col = Color3.fromHSV(hh, ss, vv)
                    sw.BackgroundColor3 = col
                    sv.BackgroundColor3 = Color3.fromHSV(hh, 1, 1)
                    svK.Position = UDim2.fromScale(ss, 1 - vv)
                    hK.Position = UDim2.fromScale(hh, 0.5)
                    local hx = hex(col)
                    hexL.Text = hx
                    if not hexBox:IsFocused() then hexBox.Text = hx end
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
                hexBox.Focused:Connect(function() tw(hexStroke, 0.25, { Transparency = 0.4 }, SINE) end)
                hexBox.FocusLost:Connect(function()
                    tw(hexStroke, 0.3, { Transparency = 1 }, SINE)
                    local c = parseHex(hexBox.Text)
                    if c then hh, ss, vv = c:ToHSV() end
                    refresh(not c)
                end)
                local open = false
                sw.MouseButton1Click:Connect(function()
                    open = not open
                    tw(row, 0.45, { Size = UDim2.new(1, 0, 0, open and OPEN_H or 26) }, QUINT)
                end)
                local api = {}
                function api:Set(c, silent) hh, ss, vv = c:ToHSV() refresh(silent) end
                function api:SetSilent(c) hh, ss, vv = c:ToHSV() refresh(true) end
                function api:Get() return col end
                api.Export = function() return { floor(col.R * 255 + 0.5), floor(col.G * 255 + 0.5), floor(col.B * 255 + 0.5) } end
                api.Import = function(v) if type(v) == "table" and #v == 3 then api:Set(rgb(v[1], v[2], v[3])) end end
                flag(t, api)
                return api
            end

            if o.Flag and not mod.Static then
                local api = {}
                api.Export = function() return { State = mod.State, Key = keyToName(mod.Key), Mode = mod.Mode } end
                api.Import = function(v)
                    if type(v) ~= "table" then return end
                    mod.Key = v.Key and keyFromName(v.Key) or nil
                    if v.Mode == "Hold" or v.Mode == "Toggle" then
                        mod.Mode = v.Mode
                        if mod.ModeBtn then mod.ModeBtn.Text = v.Mode end
                    end
                    if mod.PaintPill then mod.PaintPill(false) end
                    if mod.KeyRow then mod.KeyRow(mod.Key) end
                    mod:Set(v.State)
                    Win:RefreshHud()
                end
                api.Set = function(_, v) mod:Set(v) end
                api.Get = function() return mod.State end
                Lib.Flags[o.Flag] = api
            end

            cat.Modules[#cat.Modules + 1] = mod
            Win.Modules[#Win.Modules + 1] = mod
            Win:RefreshHud()
            if Win.Current == cat then layout() end
            return mod
        end

        Win.Categories[#Win.Categories + 1] = cat
        grp.cats[#grp.cats + 1] = cat
        layoutNav()
        return cat
    end

    function Win:SetOpacity(v)
        Win.Opacity = v
        for _, g in ipairs(glassObjs) do tw(g[1], 0.2, { BackgroundTransparency = glassFinal(g) }, SINE) end
    end
    function Win:SetTheme(def, silent)
        Win.ThemeDef = def
        Win.CustomAccent2 = nil
        applyTheme(def)
        local a, a2 = Lib.Flags.AccentColor, Lib.Flags.AccentColor2
        if a then a:SetSilent(Theme.Accent) end
        if a2 then a2:SetSilent(Theme.Accent2) end
    end
    function Win:SetAccent(c)
        local def = { Name = "Custom", Mode = Win.ThemeDef.Mode, Accent = c, Accent2 = Win.CustomAccent2, Colors = Win.ThemeDef.Colors }
        Win.ThemeDef = def
        applyTheme(def, true)
        if not Win.CustomAccent2 and Lib.Flags.AccentColor2 then Lib.Flags.AccentColor2:SetSilent(Theme.Accent2) end
    end
    function Win:SetAccent2(c)
        Win.CustomAccent2 = c
        local d = Win.ThemeDef
        local def = { Name = "Custom", Mode = d.Mode, Accent = d.Accent, Accent2 = c, Colors = d.Colors }
        Win.ThemeDef = def
        applyTheme(def, true)
    end
    function Win:ResetAccent2()
        Win.CustomAccent2 = nil
        local d = Win.ThemeDef
        local def = { Name = "Custom", Mode = d.Mode, Accent = d.Accent, Colors = d.Colors }
        Win.ThemeDef = def
        applyTheme(def, true)
        if Lib.Flags.AccentColor2 then Lib.Flags.AccentColor2:SetSilent(Theme.Accent2) end
    end
    function Win:SetScale(v) Win.userScale = v if Win.Open then tw(scale, 0.35, { Scale = fit() }, QUINT) end end
    function Win:SetGlow(g)
        Win._glowT = 0.75 - g * 0.7
        if not Win.BorderPulse then mainStroke.Transparency = Win._glowT end
    end
    function Win:SetBorderThickness(v) Win.BorderThick = v mainStroke.Thickness = v end
    function Win:SetBorderSpin(v) Win.BorderSpin = v end
    function Win:SetBorderPulse(on)
        Win.BorderPulse = on and true or false
        if not on then mainStroke.Transparency = Win._glowT end
    end
    function Win:SetFreeMouse(on) Win.FreeMouse = on and true or false end
    function Win:SetSpeed(v) Lib.Speed = v end
    function Win:SetLockPos(v) Win.LockPos = v end
    function Win:ResetPos() tw(root, 0.6, { Position = UDim2.fromScale(0.5, 0.5) }, QUINT) end
    function Win:SetMenuKey(k) Win.ToggleKey = k setFooter() end

    function Win:Show()
        if Win.Open then return end
        Win.Open = true
        root.Visible = true
        openBtn.Visible = false
        scale.Scale = fit() * 0.85
        tw(scale, 0.6, { Scale = fit() }, BACK)
        if Win.Current then layout() end
    end
    function Win:Hide()
        if not Win.Open then return end
        Win.Open = false
        tw(scale, 0.3, { Scale = fit() * 0.85 }, QUINT, IN)
        task.delay(0.3, function()
            if not Win.Open then
                root.Visible = false
                openBtn.Visible = true
                openBtn.Size = UDim2.fromOffset(0, 0)
                tw(openBtn, 0.45, { Size = UDim2.fromOffset(48, 48) }, BACK)
            end
        end)
    end
    function Win:Toggle() if Win.Open then Win:Hide() else Win:Show() end end
    openBtn.MouseButton1Click:Connect(function() Win:Show() end)
    hideBtn.MouseButton1Click:Connect(function()
        Win:Hide()
        Win:Notify("Menu hidden", "Press " .. keyName(Win.ToggleKey) .. " or the round button to open", 3)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        Win:Confirm("Unload hub?", "This fully closes the hub and removes every effect.", function() Win:Destroy() end)
    end)
    gearBtn.MouseButton1Click:Connect(function() gotoCat(Win.SettingsCat) end)
    account.MouseButton1Click:Connect(function() gotoCat(Win.ConfigsCat) end)

    Lib.Flags.Theme = {
        Export = function() return { Name = Win.ThemeDef.Name, Mode = Win.ThemeDef.Mode } end,
        Import = function(v)
            if type(v) ~= "table" then return end
            local found
            for _, d in ipairs(THEMES) do if d.Name == v.Name and d.Mode == v.Mode then found = d break end end
            if found then Win:SetTheme(found, true)
            elseif v.Mode then Win:SetTheme({ Name = "Custom", Mode = v.Mode, Accent = Theme.Accent }, true) end
        end,
    }

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
        Win.Loading = true
        local keys = {}
        for f in pairs(data) do keys[#keys + 1] = f end
        table.sort(keys, function(a, b)
            if a == "Theme" then return b ~= "Theme" end
            if b == "Theme" then return false end
            return a < b
        end)
        for _, f in ipairs(keys) do
            local a = Lib.Flags[f]
            if a and a.Import then pcall(a.Import, data[f]) end
        end
        Win.Loading = false
        return true
    end
    local FOLDER = Win.FolderName
    local function clean(n) return (tostring(n):gsub("[^%w_%- ]", "")) end
    local function ensure() pcall(function() if makefolder and isfolder and not isfolder(FOLDER) then makefolder(FOLDER) end end) end
    function Win:SaveConfig(name)
        if not writefile then return false end
        name = clean(name)
        if name == "" then return false end
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
    Win.AutoSave, Win.AutoSaveName, Win._lastAuto = false, "autosave", nil
    task.spawn(function()
        while gui.Parent do
            task.wait(5)
            if Win.AutoSave and not Win.Loading then
                local ok, s = pcall(function() return Win:ExportString() end)
                if ok and s ~= Win._lastAuto and Win:SaveConfig(Win.AutoSaveName) then Win._lastAuto = s end
            end
        end
    end)

    function Win:Destroy()
        if Win.Destroyed then return end
        Win.Destroyed = true
        if Win.AutoSave then pcall(function() Win:SaveConfig(Win.AutoSaveName) end) end
        pcall(function() modalBtn.Modal = false end)
        tw(scale, 0.4, { Scale = 0 }, QUINT, IN)
        tw(wm, 0.3, { GroupTransparency = 1 }, SINE)
        tw(hud, 0.3, { GroupTransparency = 1 }, SINE)
        genv.FemboysenseUnload = nil
        task.delay(0.45, function()
            for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
            conns, reg, hooks, grads = {}, {}, {}, {}
            active = nil
            Lib._gui = nil
            Lib._listen = nil
            gui:Destroy()
        end)
    end
    genv.FemboysenseUnload = function() Win:Destroy() end

    function Win:Finish()
        if Win._finished then return end
        Win._finished = true
        Win:AddGroup("SYSTEM")
        local st = Win:AddCategory("Settings", Icons.Settings, "Theme, window, overlays and notifications.")
        local cf = Win:AddCategory("Configs", Icons.Configs, "Save, load and share your setups.")
        Win.SettingsCat, Win.ConfigsCat = st, cf

        local rows = math.ceil(#THEMES / 4)
        local grid = st:AddCustom(rows * 96)
        new("UIGridLayout", { Parent = grid, CellSize = UDim2.new(0.25, -9, 0, 84), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder })
        local themeScales = {}
        for i, def in ipairs(THEMES) do
            local base = def.Mode == "Light" and LIGHT or DARK
            local c = def.Colors or {}
            local b = new("TextButton", { Parent = grid, LayoutOrder = i, BackgroundColor3 = B"Panel" }, { corner(14) })
            local sc = new("UIScale", { Parent = b })
            themeScales[i] = sc
            local s = new("UIStroke", { Thickness = 1, Parent = b })
            local mini = new("Frame", { Parent = b, Position = UDim2.fromOffset(9, 9), Size = UDim2.new(1, -18, 0, 36), BackgroundColor3 = c.Bg or base.Bg }, { corner(7) })
            new("Frame", { Parent = mini, Position = UDim2.fromOffset(5, 5), Size = UDim2.fromOffset(13, 26), BackgroundColor3 = c.Panel2 or base.Panel2 }, { corner(4) })
            new("Frame", { Parent = mini, Position = UDim2.fromOffset(23, 5), Size = UDim2.new(1, -30, 0, 10), BackgroundColor3 = def.Accent }, { corner(4) })
            new("Frame", { Parent = mini, Position = UDim2.fromOffset(23, 20), Size = UDim2.new(0.55, 0, 0, 8), BackgroundColor3 = def.Accent2 or (c.Panel2 or base.Panel2) }, { corner(4) })
            label(b, def.Name, UDim2.fromOffset(10, 50), UDim2.new(1, -20, 0, 16), Enum.Font.GothamBold, 12, B"Text")
            label(b, def.Mode, UDim2.fromOffset(10, 65), UDim2.new(1, -20, 0, 12), Enum.Font.Gotham, 9, B"Sub")
            onTheme(function()
                local on = Win.ThemeDef == def
                tw(s, 0.3, { Color = on and Theme.Accent or Theme.Stroke, Transparency = on and 0.05 or Theme.StrokeT, Thickness = on and 1.8 or 1 }, SINE)
            end)
            b.MouseEnter:Connect(function() tw(sc, 0.3, { Scale = 1.05 }, BACK) end)
            b.MouseLeave:Connect(function() tw(sc, 0.3, { Scale = 1 }, SINE) end)
            b.MouseButton1Click:Connect(function() Win:SetTheme(def) end)
        end
        st.OnShow = function()
            for i, sc in ipairs(themeScales) do
                sc.Scale = 0.85
                task.delay((i - 1) * 0.03, function() tw(sc, 0.5, { Scale = 1 }, BACK) end)
            end
        end

        local th = st:AddModule({ Name = "Theme", Icon = Icons.Visuals, Info = "Colors of the interface", Static = true })
        th:AddColorPicker({ Name = "Accent color", Default = Theme.Accent, Flag = "AccentColor", Callback = function(c) Win:SetAccent(c) end })
        th:AddColorPicker({ Name = "Accent gradient 2", Default = Theme.Accent2, Flag = "AccentColor2", Callback = function(c) Win:SetAccent2(c) end })
        th:AddButton({ Name = "Reset accent 2 (auto)", ButtonText = "AUTO", Callback = function()
            Win:ResetAccent2()
            Win:Notify("Theme", "Accent 2 set to auto", 2, "ok")
        end })
        th:AddButton({ Name = "Random accent", ButtonText = "ROLL", Callback = function()
            Lib.Flags.AccentColor:Set(Color3.fromHSV(math.random(), 0.75 + math.random() * 0.25, 1))
        end })
        th:AddSlider({ Name = "Window opacity", Min = 30, Max = 100, Default = 100, Suffix = "%", Flag = "UIOpacity", Callback = function(v) Win:SetOpacity(v / 100) end })
        th:AddSlider({ Name = "Border glow", Min = 0, Max = 100, Default = 55, Suffix = "%", Flag = "UIGlow", Callback = function(v) Win:SetGlow(v / 100) end })
        th:AddSlider({ Name = "Border thickness", Min = 0, Max = 6, Step = 0.5, Default = 2, Flag = "BorderThick", Callback = function(v) Win:SetBorderThickness(v) end })
        th:AddSlider({ Name = "Border spin speed", Min = -300, Max = 300, Step = 10, Default = 60, Flag = "BorderSpin", Callback = function(v) Win:SetBorderSpin(v) end })
        th:AddToggle({ Name = "Border pulse", Flag = "BorderPulse", Callback = function(v) Win:SetBorderPulse(v) end })

        local wn = st:AddModule({ Name = "Window", Icon = Icons.Settings, Info = "Size, position and behavior", Static = true })
        wn:AddKeybind({ Name = "Toggle menu key", Default = Win.ToggleKey, Mode = "Press", Flag = "MenuKey", Hud = false,
            Callback = function() end, Changed = function(k) if k then Win:SetMenuKey(k) end end })
        wn:AddSlider({ Name = "Menu size", Min = 60, Max = 130, Default = 100, Suffix = "%", Flag = "UIScale", Callback = function(v) Win:SetScale(v / 100) end })
        wn:AddSlider({ Name = "Animation speed", Min = 0.4, Max = 2.5, Step = 0.05, Default = 1, Suffix = "x", Flag = "AnimSpeed", Callback = function(v) Win:SetSpeed(v) end })
        wn:AddToggle({ Name = "Free mouse in menu", Default = true, Flag = "FreeMouse", Callback = function(v) Win:SetFreeMouse(v) end })
        wn:AddToggle({ Name = "Lock window position", Flag = "UILock", Callback = function(v) Win:SetLockPos(v) end })
        wn:AddButton({ Name = "Reset window position", ButtonText = "CENTER", Callback = function() Win:ResetPos() end })

        local wmm = st:AddModule({ Name = "Watermark", Icon = Icons.Visuals, Info = "Write your own text with variables", Static = true })
        wmm:AddToggle({ Name = "Enabled", Flag = "WMEnabled", Callback = function(v) Win:SetWM("Enabled", v) end })
        wmm:AddTextbox({ Name = "Text", Wide = true, Live = true, Default = WM.Text, Placeholder = "Your text...", Flag = "WMText",
            Callback = function(t) Win:SetWM("Text", t) end })
        wmm:AddLabel("Variables: {title} {user} {name} {fps} {ping} {time} {date} {players} {game} {version}", 30)
        wmm:AddOptions({ Name = "Position", Options = { "Top Left", "Top Right", "Bottom Left", "Bottom Right" }, Default = "Top Left", Flag = "WMPos",
            Callback = function(v) Win:SetWM("Pos", v) end })
        wmm:AddSlider({ Name = "Size", Min = 60, Max = 180, Default = 100, Suffix = "%", Flag = "WMSize", Callback = function(v) Win:SetWM("Size", v / 100) end })
        wmm:AddSlider({ Name = "Text size", Min = 10, Max = 22, Default = 13, Flag = "WMTextSize", Callback = function(v) Win:SetWM("TextSize", v) end })
        wmm:AddSlider({ Name = "Opacity", Min = 10, Max = 100, Default = 92, Suffix = "%", Flag = "WMOpacity", Callback = function(v) Win:SetWM("Opacity", v / 100) end })
        wmm:AddSlider({ Name = "Rounding", Min = 0, Max = 24, Default = 20, Flag = "WMRound", Callback = function(v) Win:SetWM("Round", v) end })
        wmm:AddDropdown({ Name = "Font", Options = { "Gotham", "GothamMedium", "GothamBold", "GothamBlack", "SourceSans", "SourceSansBold", "Ubuntu", "Code", "Arial", "Nunito" },
            Default = "GothamMedium", Flag = "WMFont", Callback = function(v) Win:SetWM("Font", v) end })
        wmm:AddOptions({ Name = "Text color", Options = { "Theme", "Accent", "Custom" }, Default = "Theme", Flag = "WMTextMode", Callback = function(v) Win:SetWM("TextMode", v) end })
        wmm:AddColorPicker({ Name = "Custom text color", Default = WHITE, Flag = "WMTextColor", Callback = function(c) Win:SetWM("TextCustom", c) end })
        wmm:AddOptions({ Name = "Background", Options = { "Panel", "Accent", "Custom" }, Default = "Panel", Flag = "WMBgMode", Callback = function(v) Win:SetWM("BgMode", v) end })
        wmm:AddColorPicker({ Name = "Custom background", Default = rgb(20, 20, 24), Flag = "WMBgColor", Callback = function(c) Win:SetWM("BgCustom", c) end })
        wmm:AddToggle({ Name = "Accent bar", Default = true, Flag = "WMBar", Callback = function(v) Win:SetWM("Bar", v) end })
        wmm:AddToggle({ Name = "Border", Default = true, Flag = "WMBorder", Callback = function(v) Win:SetWM("Border", v) end })
        wmm:AddToggle({ Name = "Colored fps / ping", Default = true, Flag = "WMColors", Callback = function(v) Win:SetWM("Colors", v) end })
        wmm:AddToggle({ Name = "24-hour clock", Default = true, Flag = "WMH24", Callback = function(v) Win:SetWM("H24", v) end })
        wmm:AddButton({ Name = "Reset position", ButtonText = "RESET", Callback = function() place(wm, WM.Pos, 18) end })

        local kbm = st:AddModule({ Name = "Keybind list", Icon = Icons.Visuals, Info = "Shows only active binds", Static = true })
        kbm:AddToggle({ Name = "Enabled", Flag = "BindsHud", Callback = function(v) Win:SetHud("Enabled", v) end })
        kbm:AddTextbox({ Name = "Title", Default = HUD.Title, Placeholder = "KEYBINDS", Flag = "HudTitle", Callback = function(t) Win:SetHud("Title", t) end })
        kbm:AddToggle({ Name = "Show title", Default = true, Flag = "HudShowTitle", Callback = function(v) Win:SetHud("ShowTitle", v) end })
        kbm:AddToggle({ Name = "Show hold tag", Default = true, Flag = "HudShowMode", Callback = function(v) Win:SetHud("ShowMode", v) end })
        kbm:AddOptions({ Name = "Position", Options = { "Top Left", "Top Right", "Bottom Left", "Bottom Right" }, Default = "Top Left", Flag = "HudPos",
            Callback = function(v) Win:SetHud("Pos", v) end })
        kbm:AddSlider({ Name = "Size", Min = 60, Max = 160, Default = 100, Suffix = "%", Flag = "HudSize", Callback = function(v) Win:SetHud("Size", v / 100) end })
        kbm:AddSlider({ Name = "Opacity", Min = 10, Max = 100, Default = 92, Suffix = "%", Flag = "HudOpacity", Callback = function(v) Win:SetHud("Opacity", v / 100) end })
        kbm:AddButton({ Name = "Reset position", ButtonText = "RESET", Callback = function() place(hud, HUD.Pos, 64) end })

        local nt = st:AddModule({ Name = "Notifications", Icon = Icons.Settings, Info = "Popup messages", Static = true })
        nt:AddToggle({ Name = "Notifications", Default = true, Flag = "Notifs", Callback = function(v) Win.NotifsOn = v end })
        nt:AddSlider({ Name = "Duration", Min = 1, Max = 10, Step = 0.5, Default = 3, Suffix = "s", Flag = "NotifTime", Callback = function(v) Win.NotifTime = v end })
        nt:AddOptions({ Name = "Position", Options = { "Top Right", "Top Left", "Bottom Right", "Bottom Left" }, Default = "Top Right", Flag = "NotifPos", Callback = function(v) Win:SetNotifPos(v) end })
        nt:AddButton({ Name = "Test notification", ButtonText = "TEST", Callback = function() Win:Notify("FEMBOYSENSE", "This is a test notification", 3, "ok", true) end })

        local cm = cf:AddModule({ Name = "Configs", Icon = Icons.Configs, Info = "Everything with a flag is saved", Static = true })
        local cfgName, cfgDD = "default", nil
        local function refresh() if cfgDD then cfgDD:Refresh(Win:ListConfigs()) end end
        cm:AddTextbox({ Name = "Config name", Placeholder = "default", Default = "default", Callback = function(t) if t ~= "" then cfgName = t end end })
        cfgDD = cm:AddDropdown({ Name = "Saved configs", Options = Win:ListConfigs(), Default = "default", Callback = function(v) cfgName = v end })
        cm:AddButton({ Name = "Save config", ButtonText = "SAVE", Callback = function()
            if Win:SaveConfig(cfgName) then Win:Notify("Config", "Saved: " .. cfgName, 3, "ok") refresh() else Win:Notify("Config", "Executor doesn't support writefile", 3, "err") end end })
        cm:AddButton({ Name = "Load config", ButtonText = "LOAD", Callback = function()
            if Win:LoadConfig(cfgName) then Win:Notify("Config", "Loaded: " .. cfgName, 3, "ok") else Win:Notify("Config", "Config not found", 3, "err") end end })
        cm:AddButton({ Name = "Delete config", ButtonText = "DELETE", Callback = function()
            if Win:DeleteConfig(cfgName) then Win:Notify("Config", "Deleted: " .. cfgName, 3, "warn") refresh() else Win:Notify("Config", "Nothing to delete", 3, "err") end end })
        cm:AddButton({ Name = "Set as autoload", ButtonText = "SET", Callback = function()
            if Win:SetAutoload(cfgName) then Win:Notify("Config", "Autoload: " .. cfgName, 3, "ok") else Win:Notify("Config", "writefile not supported", 3, "err") end end })
        cm:AddButton({ Name = "Clear autoload", ButtonText = "CLEAR", Callback = function() Win:ClearAutoload() Win:Notify("Config", "Autoload cleared", 3, "warn") end })
        cm:AddButton({ Name = "Refresh list", ButtonText = "SCAN", Callback = refresh })
        cm:AddButton({ Name = "Copy to clipboard", ButtonText = "COPY", Callback = function()
            local fn = setclipboard or toclipboard
            if fn then pcall(fn, Win:ExportString()) Win:Notify("Config", "Copied to clipboard", 3, "ok") else Win:Notify("Config", "Clipboard not supported", 3, "warn") end end })
        local importText = ""
        cm:AddTextbox({ Name = "Import from text", Placeholder = "paste exported config", Callback = function(t) importText = t end })
        cm:AddButton({ Name = "Apply imported config", ButtonText = "APPLY", Callback = function()
            if importText ~= "" and Win:ImportString(importText) then Win:Notify("Config", "Imported", 3, "ok") else Win:Notify("Config", "Invalid config text", 3, "err") end end })
        cm:AddToggle({ Name = "Auto save", Flag = "AutoSave", Callback = function(v) Win.AutoSave = v Win._lastAuto = nil end })
        cm:AddToggle({ Name = "Auto load", Flag = "AutoLoad", Callback = function(v)
            if Win.Loading then return end
            if v then Win:SaveConfig(Win.AutoSaveName) Win:SetAutoload(Win.AutoSaveName) else Win:ClearAutoload() end end })

        if Win.Current == nil then Win:Select(Win.Categories[1]) end
        layoutNav()
        for i, c in ipairs(Win.Categories) do
            c.Btn.Position = UDim2.fromOffset(-30, c.Y)
            task.delay(0.15 + i * 0.03, function() tw(c.Btn, 0.5, { Position = UDim2.fromOffset(0, c.Y) }, BACK) end)
        end
        task.delay(1.2, function()
            pcall(function()
                local p = FOLDER .. "/autoload.txt"
                if isfile and readfile and isfile(p) then
                    local name = readfile(p):match("^%s*(.-)%s*$")
                    if name and name ~= "" and Win:LoadConfig(name) then Win:Notify("Config", "Autoloaded: " .. name, 3, "ok") end
                end
            end)
        end)
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Win.Query = searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
        if Win.Current then layout() end
    end)

    local function fireBinds(match, down)
        if UIS:GetFocusedTextBox() then return end
        for _, b in ipairs(Win.BindList) do
            if b.Key and b.Press and match(b.Key) then
                if down then b.Press(true) elseif b.Mode == "Hold" then b.Press(false) end
            end
        end
    end
    keep(UIS.InputBegan:Connect(function(input, gp)
        if Lib._listen then
            local f, ut = Lib._listen, input.UserInputType
            if ut == Enum.UserInputType.Keyboard then
                Lib._listen = nil
                f(input.KeyCode)
            elseif ut == Enum.UserInputType.MouseButton2 or ut == Enum.UserInputType.MouseButton3 then
                Lib._listen = nil
                f(ut)
            end
            return
        end
        if gp then return end
        fireBinds(function(k) return keyMatch(k, input) end, true)
        if input.KeyCode == Win.ToggleKey and not UIS:GetFocusedTextBox() then Win:Toggle() end
    end))
    keep(UIS.InputEnded:Connect(function(input) fireBinds(function(k) return keyMatch(k, input) end, false) end))

    local xHeld = {}
    local function usesX()
        if Lib._listen then return true end
        for _, b in ipairs(Win.BindList) do if type(b.Key) == "string" then return true end end
        return false
    end
    keep(RunService.Heartbeat:Connect(function()
        local poll = iskeypressed or isKeyPressed
        if not poll or not usesX() then return end
        for name, vk in pairs(XBTN) do
            local ok, d = pcall(poll, vk)
            d = ok and d == true
            if d ~= (xHeld[name] or false) then
                xHeld[name] = d
                if d and Lib._listen then
                    local f = Lib._listen
                    Lib._listen = nil
                    f(name)
                else
                    fireBinds(function(k) return k == name end, d)
                end
            end
        end
    end))

    Win:SetNotifPos("Top Right")
    Win:SetGlow(0.55)
    scale.Scale = fit() * 0.85
    tw(scale, 0.8, { Scale = fit() }, BACK)

    return Win
end

return Lib