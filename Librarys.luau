--[[
    FEMBOYSENSE — UI Library v4.0  (UIShadow edition)

    Что нового относительно v3.1:
      • Нативный UIShadow вместо ImageLabel-хака (rbxassetid://6014261993).
        Тень лежит ПРЯМО в целевом элементе: сама повторяет размер, UICorner,
        масштаб (UIScale) и поворот — никаких пересчётов позиций.
      • Win:AnimatedShadow  — «дышащая» неоновая тень (Blur / Spread / Transparency / Color).
      • Win:Shadow          — статичная тень с hover-реакцией (карточки, сайдбар, тулбар, тултип, confirm).
      • Тени у уведомлений (цвет по типу), HUD, watermark, кнопки открытия.
      • Кольцевая рамка стала «кометой» (две дуги) — спокойнее и дороже на вид.
      • Градиентные слайдеры, градиентный логотип, edge-lit обводка карточек.
      • Оптимизация: один декор-тик 30 Гц, кэш viewport, тема применяется мгновенно
        к скрытым элементам и плавно только к видимым.
      • Настройки: Card shadows / Shadow through glass / Overlay opacity.
      • Вся прежняя функциональность (конфиги, курсор, фон, selection, HUD, watermark...) сохранена.

    Примечание: UIShadow должен быть доступен в вашем клиенте. Если Instance.new("UIShadow")
    не поддерживается, библиотека продолжит работать без теней (всё обёрнуто в pcall).
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UIS              = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Debris           = game:GetService("Debris")
local Lighting         = game:GetService("Lighting")
local SoundService     = game:GetService("SoundService")
local Stats            = game:GetService("Stats")
local TextService      = game:GetService("TextService")
local GuiService       = game:GetService("GuiService")
local Marketplace      = game:GetService("MarketplaceService")
local LocalPlayer      = Players.LocalPlayer

local genv = (getgenv and getgenv()) or _G
if genv.FemboysenseUnload then pcall(genv.FemboysenseUnload) end

local rgb, WHITE = Color3.fromRGB, Color3.new(1, 1, 1)
local SINE, QUINT, BACK, LIN = Enum.EasingStyle.Sine, Enum.EasingStyle.Quint, Enum.EasingStyle.Back, Enum.EasingStyle.Linear
local OUT, IN = Enum.EasingDirection.Out, Enum.EasingDirection.In
local AUTO_Y, AUTO_NONE, AUTO_X = Enum.AutomaticSize.Y, Enum.AutomaticSize.None, Enum.AutomaticSize.X
local V2 = Vector2.new
local sin, clamp = math.sin, math.clamp

local Lib = {
    Flags = {}, Version = "v4.0", Lang = "EN", Dicts = {}, Speed = 1,
    Semantic = { Green = rgb(70, 225, 125), Yellow = rgb(255, 190, 60), Red = rgb(255, 70, 70) },
    ResetIcon = 140026246189675,
}

--=====================================================================
--  THEMES
--=====================================================================
local DARK = { Bg = rgb(8, 8, 10), Side = rgb(17, 17, 20), Panel = rgb(26, 26, 30), Panel2 = rgb(40, 40, 46),
    Text = rgb(244, 244, 247), Sub = rgb(146, 146, 154), Stroke = WHITE, StrokeT = 0.93 }
local LIGHT = { Bg = rgb(232, 232, 238), Side = rgb(246, 246, 250), Panel = rgb(255, 255, 255), Panel2 = rgb(233, 233, 240),
    Text = rgb(22, 22, 27), Sub = rgb(108, 108, 120), Stroke = Color3.new(0, 0, 0), StrokeT = 0.92 }
local THEMES = {
    { Name = "Mono",     Mode = "Dark",  Accent = rgb(227, 228, 230) },
    { Name = "Lavender", Mode = "Dark",  Accent = rgb(184, 160, 237) },
    { Name = "Midnight", Mode = "Dark",  Accent = rgb(145, 175, 229) },
    { Name = "Rose",     Mode = "Dark",  Accent = rgb(229, 165, 188) },
    { Name = "Mono",     Mode = "Light", Accent = rgb(70, 70, 78) },
    { Name = "Lavender", Mode = "Light", Accent = rgb(150, 120, 220) },
    { Name = "Midnight", Mode = "Light", Accent = rgb(100, 140, 215) },
    { Name = "Rose",     Mode = "Light", Accent = rgb(220, 120, 155) },
    -- из Crimson Hub (свои палитры + Accent2)
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
    Theme.Accent2 = def.Accent2 or (def.Mode == "Light" and def.Accent:Lerp(WHITE, 0.4) or def.Accent:Lerp(rgb(0, 0, 0), 0.58))
    Theme.OnAccent = def.Mode == "Light" and WHITE or rgb(12, 12, 14)
end
loadTheme(THEMES[2])
Lib.Theme = Theme

--// градиенты (kind: ring / lin / shine / tri / pill)
local function kp(t, c) return ColorSequenceKeypoint.new(t, c) end
local function nk(t, v) return NumberSequenceKeypoint.new(t, v) end
-- «комета»: две яркие дуги на тонкой подложке — спокойнее, чем старая 5-цветная рамка
local RING_T = NumberSequence.new({ nk(0, 0.88), nk(0.12, 0.05), nk(0.3, 0.88), nk(0.5, 0.88), nk(0.62, 0.05), nk(0.8, 0.88), nk(1, 0.88) })
local function gradColor(kind)
    local A, A2 = Theme.Accent, Theme.Accent2
    if kind == "ring" then
        return ColorSequence.new({ kp(0, A2), kp(0.12, A), kp(0.3, A2), kp(0.5, A2), kp(0.62, A), kp(0.8, A2), kp(1, A2) })
    elseif kind == "lin" then return ColorSequence.new(A2, A)
    elseif kind == "shine" then return ColorSequence.new({ kp(0, Theme.Text), kp(0.5, A), kp(1, Theme.Text) })
    elseif kind == "tri" then return ColorSequence.new({ kp(0, A2), kp(0.5, A), kp(1, A2) }) end
    return ColorSequence.new(A, A2)
end
Lib.GradColor = gradColor

local reg, hooks, conns, tracked = {}, {}, {}, setmetatable({}, { __mode = "k" })
local grads, spinners, shimmers = {}, {}, {}
local function keep(c) table.insert(conns, c) return c end
local function onTheme(fn) table.insert(hooks, fn) fn(true) end

local function tw(obj, t, props, style, dir)
    local tr = TweenService:Create(obj, TweenInfo.new(math.max(t / Lib.Speed, 0.01), style or QUINT, dir or OUT), props)
    tr:Play()
    return tr
end
local function B(key) return { __bind = key } end
local function bind(obj, prop, key) obj[prop] = Theme[key] table.insert(reg, { obj, prop, key }) end
-- видимые элементы красим плавно, всё остальное (в стэше / вне GUI) — мгновенно: нет подвисаний при смене темы
local function applyTheme(def, instant)
    loadTheme(def)
    local gui = Lib._gui
    for i = #reg, 1, -1 do
        local e = reg[i]
        local o = e[1]
        if o.Parent then
            if not instant and gui and o:IsDescendantOf(gui) then
                pcall(function() tw(o, 0.35, { [e[2]] = Theme[e[3]] }, SINE) end)
            else
                pcall(function() o[e[2]] = Theme[e[3]] end)
            end
        else table.remove(reg, i) end
    end
    for i = #grads, 1, -1 do
        local g = grads[i]
        if g[1].Parent then g[1].Color = gradColor(g[2]) else table.remove(grads, i) end
    end
    for _, f in ipairs(hooks) do task.spawn(pcall, f) end
end

--// ЯЗЫК
local function T(s)
    local d = Lib.Dicts[Lib.Lang]
    return d and d[s] or s
end
local function track(obj, prop, key)
    local t = tracked[obj] or {}
    t[prop] = key
    tracked[obj] = t
end
local function setTxt(obj, key, prop)
    prop = prop or "Text"
    track(obj, prop, key)
    obj[prop] = T(key)
end
local function dyn(obj) tracked[obj] = nil return obj end -- динамический текст: не переводим
function Lib:SetDict(lang, tbl) Lib.Dicts[lang] = tbl end
function Lib:SetLang(l)
    Lib.Lang = l
    for o, props in pairs(tracked) do
        for p, key in pairs(props) do pcall(function() o[p] = T(key) end) end
    end
end
Lib.T = T

--=====================================================================
--  HELPERS
--=====================================================================
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
        elseif isText and (k == "Text" or k == "PlaceholderText") and type(v) == "string" then setTxt(o, v, k)
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
local function pad(t, b, l, r)
    return new("UIPadding", { PaddingTop = UDim.new(0, t), PaddingBottom = UDim.new(0, b), PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r) })
end
local function label(parent, text, pos, size, font, ts, color, align, extra)
    local l = new("TextLabel", {
        Parent = parent, Text = text, Position = pos or UDim2.new(), Size = size or UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Font = font or Enum.Font.GothamMedium, TextSize = ts or 13,
        TextColor3 = color or B"Text", TextXAlignment = align or Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
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
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end
local function guiParent()
    if gethui then local ok, h = pcall(gethui) if ok and h then return h end end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local function plainStroke(color, th, tr)
    return new("UIStroke", { Color = color, Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

--// публичные градиент-хелперы
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

--=====================================================================
--  UISHADOW (нативный)
--=====================================================================
-- Создаёт UIShadow внутри parent. Тень сама повторяет размер/UICorner/UIScale родителя.
-- ZIndex обязан быть отрицательным, иначе тень ляжет поверх содержимого.
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

--// ИКОНКИ (реальные картинки)
local function makeIcon(parent, icon, pos, px)
    px = px or 18
    if type(icon) == "number" then icon = "rbxassetid://" .. icon end
    local im
    if type(icon) == "string" and icon ~= "" then
        im = new("ImageLabel", { Parent = parent, Position = pos or UDim2.new(), Size = UDim2.fromOffset(px, px),
            BackgroundTransparency = 1, Image = icon, ImageColor3 = Theme.Sub, ScaleType = Enum.ScaleType.Fit })
    else
        im = new("TextLabel", { Parent = parent, Position = pos or UDim2.new(), Size = UDim2.fromOffset(px, px),
            BackgroundTransparency = 1, Text = "•", TextColor3 = Theme.Sub, TextSize = px, Font = Enum.Font.GothamBold })
    end
    local prop = im:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
    local ic = { Holder = im }
    function ic:Paint(c, instant)
        if instant then im[prop] = c else tw(im, 0.25, { [prop] = c }, SINE) end
    end
    function ic:Bind(key) onTheme(function(inst) ic:Paint(Theme[key], inst == true) end) return ic end
    return ic
end

--// КЛАВИШИ
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

local function drag(handle, target, gate)
    local dragging, start, startPos
    handle.InputBegan:Connect(function(i)
        if isPress(i) and not (gate and gate()) then dragging, start, startPos = true, i.Position, target.Position end
    end)
    keep(UIS.InputChanged:Connect(function(i)
        if dragging and isMove(i) then
            local d = i.Position - start
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    keep(UIS.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end))
end
Lib.Drag = drag

--// ЗВУК
local sfxSound
local function sfx()
    if not Lib.SoundsOn then return end
    if not sfxSound then
        sfxSound = Instance.new("Sound")
        sfxSound.SoundId = "rbxassetid://6895079853"
        sfxSound.Parent = SoundService
    end
    sfxSound.Volume = Lib.SoundVol or 0.5
    sfxSound:Play()
end

--// кнопка «сбросить бинд»
local function resetBtn(parent, pos, onClick)
    local b = new("TextButton", { Parent = parent, AnchorPoint = V2(1, 0.5), Position = pos, Size = UDim2.fromOffset(24, 24),
        BackgroundColor3 = B"Panel2", Visible = false }, { corner(8) })
    local ic = makeIcon(b, Lib.ResetIcon, UDim2.fromOffset(5, 5), 14):Bind("Sub")
    b.MouseEnter:Connect(function() ic:Paint(Theme.Accent) end)
    b.MouseLeave:Connect(function() ic:Paint(Theme.Sub) end)
    b.MouseButton1Click:Connect(onClick)
    return b
end

--=====================================================================
--  WIDGETS
--=====================================================================
local function makeSwitch(parent, init, cb, pos)
    local state = init and true or false
    local track = new("TextButton", {
        Parent = parent, AnchorPoint = V2(1, 0.5), Position = pos or UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(40, 22), BackgroundColor3 = Theme.Bg,
    }, { corner(11) })
    local press = new("UIScale", { Parent = track })
    local knob = new("Frame", { Parent = track, AnchorPoint = V2(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), BackgroundColor3 = WHITE }, { corner(8) })
    local sw = {}
    local function paint(instant)
        local col = state and Theme.Accent:Lerp(Theme.Panel2, 0.38) or Theme.Bg
        local p = state and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        if instant then track.BackgroundColor3, knob.Position = col, p
        else tw(track, 0.25, { BackgroundColor3 = col }, SINE) tw(knob, 0.45, { Position = p }, BACK) end
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
    track.MouseButton1Down:Connect(function() tw(press, 0.1, { Scale = 0.9 }, SINE) knob.Size = UDim2.fromOffset(20, 16) end)
    track.MouseButton1Up:Connect(function() tw(press, 0.35, { Scale = 1 }, BACK) knob.Size = UDim2.fromOffset(16, 16) end)
    track.MouseLeave:Connect(function() tw(press, 0.2, { Scale = 1 }, SINE) knob.Size = UDim2.fromOffset(16, 16) end)
    track.MouseButton1Click:Connect(function() sfx() sw:Set(not state) end)
    sw.Frame = track
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
    -- заливка с градиентом Accent2 → Accent (фон белый, чтобы градиент не тускнел)
    local fill = new("Frame", { Parent = bar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE }, { corner(2) })
    Lib.Grad(fill, "lin")
    local knob = new("Frame", { Parent = bar, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(12, 12), BackgroundColor3 = WHITE, ZIndex = 2 }, { corner(6) })
    local glow = new("Frame", { Parent = knob, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12), BackgroundColor3 = B"Accent", BackgroundTransparency = 1, ZIndex = 1 }, { corner(20) })
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
        if not silent then fire(o.Callback, v) end
    end
    render(false)
    local hit = new("TextButton", { Parent = f, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, ZIndex = 3 })
    local dragging = false
    local function fromX(x)
        setv(mn + (mx - mn) * clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1), false, true)
    end
    hit.InputBegan:Connect(function(i)
        if isPress(i) then
            dragging = true
            tw(knob, 0.25, { Size = UDim2.fromOffset(17, 17) }, BACK)
            tw(glow, 0.3, { Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 0.75 }, QUINT)
            fromX(i.Position.X)
        end
    end)
    keep(UIS.InputChanged:Connect(function(i) if dragging and isMove(i) then fromX(i.Position.X) end end))
    keep(UIS.InputEnded:Connect(function(i)
        if dragging and isPress(i) then
            dragging = false
            tw(knob, 0.3, { Size = UDim2.fromOffset(12, 12) }, QUINT)
            tw(glow, 0.4, { Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1 }, QUINT)
        end
    end))
    function api:Set(v, silent) setv(v, silent, false) end
    function api:Get() return value end
    api.Frame = f
    return api
end

local function flag(o, api) if o.Flag then Lib.Flags[o.Flag] = api end end

--=====================================================================
--  WINDOW
--=====================================================================
function Lib:CreateWindow(cfg)
    cfg = cfg or {}
    local Icons = cfg.Icons or {}
    if Icons.Reset then Lib.ResetIcon = Icons.Reset end
    local W, H = 880, 580
    local DECOR_STEP = 1 / 30
    local Win = {
        Categories = {}, Groups = {}, Modules = {}, BindList = {}, Current = nil, Query = "", Glass = cfg.Glass ~= false,
        userScale = 1, Open = true, HudOn = false, ToggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift,
        ThemeDef = THEMES[2], Opacity = 1, Favs = {}, Recent = {}, LockPos = false, Streamer = false,
        FolderName = cfg.Folder or "FemboysenseHub", unloaders = {}, Particles = false,
        NotifTime = 3, NotifsOn = true, Speed = 1,
        Shadows = true, CardShadows = true, ShadowBehind = false, ShadowMul = 1,
        FreeMouse = true, OverMenu = false, HideSystemCursor = false,
        BorderSpin = 60, BorderPulse = false, BorderThick = 2, _glowT = 0.45, ParticleWait = 0.225,
        Ripples = true, NotifSoundOn = false, WMColors = true, CustomAccent2 = nil,
        StreamTargets = {}, Tiles = {},
    }
    Lib.Win = Win
    function Win:OnUnload(fn) table.insert(Win.unloaders, fn) end
    Win.Keep = keep
    local SEM = Lib.Semantic

    function Win:StreamLabel(lbl, real, fake)
        table.insert(Win.StreamTargets, { dyn(lbl), real, fake })
        if Win.Streamer then lbl.Text = fake end
        return lbl
    end

    local gui = new("ScreenGui", { Name = "FemboysenseHub", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999, AutoLocalize = false, Parent = guiParent() })
    Win.Gui = gui
    Lib._gui = gui

    -- кнопка-Modal (освобождает мышь в играх с залоченным курсором)
    local modalBtn = new("TextButton", { Parent = gui, Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Modal = false })

    -- «склад» для скрытых карточек (чтобы не терялись темы)
    local stash = Instance.new("Folder")
    stash.Name = "Stash"

    local dim = new("Frame", { Parent = gui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(5, 5, 8), BackgroundTransparency = 1, ZIndex = 0 })
    local blur
    local function setBlur(size)
        if size > 0 and not blur then blur = Instance.new("BlurEffect") blur.Size = 0 blur.Parent = Lighting end
        if blur then tw(blur, 0.5, { Size = size }, SINE) end
    end
    Win.BlurSize, Win.BlurOn, Win.DimAmt = 14, false, 0.35

    -- root: прозрачный контейнер + UICorner(22) — UIShadow берёт форму отсюда, main при этом может клипать содержимое
    local root = new("Frame", { Parent = gui, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, ZIndex = 2 }, { corner(22) })
    local scale = new("UIScale", { Parent = root })

    -- viewport кэшируется один раз; fit() не лезет в workspace каждый вызов
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

    ------------------------------------------------------------------
    --  SHADOWS (native UIShadow)
    ------------------------------------------------------------------
    local shadowList, statics = {}, {}

    -- Анимированная «дышащая» тень. Двигаем Blur / Spread / Transparency / Color.
    -- Размер, угол и масштаб подхватываются от родителя автоматически.
    function Win:AnimatedShadow(target, o)
        o = o or {}
        local e = {
            Target = target, Spread = o.Size or 36, Alpha = o.Alpha or 0.07, Speed = o.Speed or 1.6,
            Phase = math.random() * 6, H = 0, HT = 0, Vis = 0, OffY = o.OffY or 6, Anim = true,
        }
        e.Shadow = makeShadow(target, { Blur = e.Spread * 0.55, OffY = e.OffY, ZIndex = o.ZIndex, Transparency = 1, Behind = Win.ShadowBehind })
        if e.Shadow then e.Shadow.Enabled = false end
        function e:SetHover(on) self.HT = on and 1 or 0 end
        function e:Step(dt, clk)
            local sh, tg = self.Shadow, self.Target
            if not sh then return end
            self.H += (self.HT - self.H) * math.min(dt * 8, 1)
            self.Vis += ((Win.Shadows and 1 or 0) - self.Vis) * math.min(dt * 6, 1)
            local show = tg.Parent ~= nil and tg.Visible and self.Vis > 0.02
            if sh.Enabled ~= show then sh.Enabled = show end
            if not show then return end
            local s = sin(clk * self.Speed + self.Phase)
            local h = self.H
            sh.BlurRadius = UDim.new(0, self.Spread * (0.55 + 0.08 * s + h * 0.25))
            local sp = self.Spread * (0.05 + 0.02 * s + h * 0.08)
            sh.Spread = UDim2.fromOffset(sp, sp)
            sh.Offset = UDim2.fromOffset(0, self.OffY * (1 + h * 0.3))
            sh.Transparency = 1 - clamp(self.Alpha * 7 * Win.ShadowMul * (0.85 + 0.15 * s) * (1 + h * 0.9) * self.Vis, 0, 0.85)
            sh.Color = Theme.Accent2:Lerp(Theme.Accent, 0.45 + 0.35 * s * 0.5 + h * 0.2)
        end
        table.insert(shadowList, e)
        return e
    end

    -- Статичная тень (карточки, сайдбар, тулбар, тултип...). Обновляется только при смене темы/настроек/hover.
    function Win:Shadow(target, o)
        o = o or {}
        local e = { Target = target, Alpha = o.Alpha or 0.3, Key = o.Key or "Accent2", Kind = o.Kind, Blur = o.Blur or 16, Hov = false }
        e.Shadow = makeShadow(target, { Blur = e.Blur, OffY = o.OffY or 4, Spread = o.Spread or 0, ZIndex = o.ZIndex, Transparency = 1, Behind = Win.ShadowBehind })
        function e:TargetT() return 1 - clamp(self.Alpha * Win.ShadowMul * (self.Hov and 1.7 or 1), 0, 0.9) end
        function e:Apply()
            local sh = self.Shadow
            if not sh then return end
            sh.Enabled = Win.Shadows and (self.Kind ~= "card" or Win.CardShadows)
            sh.Color = Theme[self.Key]
            sh.Transparency = self:TargetT()
        end
        function e:SetHover(on)
            self.Hov = on
            local sh = self.Shadow
            if not sh then return end
            tw(sh, 0.3, { Transparency = self:TargetT(), BlurRadius = UDim.new(0, self.Blur * (on and 1.35 or 1)),
                Color = on and Theme.Accent or Theme[self.Key] }, SINE)
        end
        function e:FadeIn()
            local sh = self.Shadow
            if not sh or not sh.Enabled then return end
            sh.Transparency = 1
            tw(sh, 0.55, { Transparency = self:TargetT() }, SINE)
        end
        table.insert(statics, e)
        e:Apply()
        return e
    end
    local function applyStatics() for _, e in ipairs(statics) do e:Apply() end end
    onTheme(applyStatics)

    Win.RootShadow = Win:AnimatedShadow(root, { Size = 70, Alpha = 0.075, Speed = 1.2, OffY = 10 })

    local function waves()
        for i = 1, 3 do
            task.delay((i - 1) * 0.12, function()
                if not gui.Parent then return end
                local f = new("Frame", { Parent = gui, AnchorPoint = V2(0.5, 0.5), Position = root.Position,
                    Size = UDim2.fromOffset(260, 260), BackgroundTransparency = 1, ZIndex = 1 }, { corner(1000) })
                local s = new("UIStroke", { Color = Theme.Accent, Thickness = 2.2, Transparency = 0.35, Parent = f })
                tw(f, 1.2, { Size = UDim2.fromOffset(1500, 1500) }, QUINT)
                tw(s, 1.2, { Transparency = 1, Thickness = 0.5 }, SINE)
                Debris:AddItem(f, 1.4)
            end)
        end
    end

    local glassObjs = {}
    local function glassFinal(g) local base = Win.Glass and g[2] or 0 return 1 - (1 - base) * Win.Opacity end
    local function glassT(obj, gv) table.insert(glassObjs, { obj, gv }) obj.BackgroundTransparency = glassFinal(glassObjs[#glassObjs]) end

    local main = new("Frame", { Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = B"Bg", ClipsDescendants = true }, { corner(22) })
    glassT(main, 0.06)
    local mainStroke = new("UIStroke", { Color = WHITE, Transparency = Win._glowT, Thickness = Win.BorderThick, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = main })
    local ringGrad = Lib.Grad(mainStroke, "ring")
    Win.RingSpin = Lib.Spin(ringGrad, Win.BorderSpin, function() return Win.Open end)

    main.MouseEnter:Connect(function() Win.RootShadow:SetHover(true) Win.OverMenu = true end)
    main.MouseLeave:Connect(function() Win.RootShadow:SetHover(false) Win.OverMenu = false end)

    -- фон-картинка меню
    Win.BgImage = new("ImageLabel", { Parent = main, Size = UDim2.fromScale(1.05, 1.05), Position = UDim2.fromScale(-0.025, -0.025),
        BackgroundTransparency = 1, Image = "", ImageTransparency = 1, ScaleType = Enum.ScaleType.Crop, ZIndex = 0 })
    Win.BgDim = new("Frame", { Parent = main, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 0 }, { corner(22) })
    local edgeFades = {}
    do
        local function mkEdge(rot, anchor, pos, size)
            local f = new("Frame", { Parent = main, AnchorPoint = anchor, Position = pos, Size = size,
                BackgroundColor3 = Color3.new(0, 0, 0), Visible = false, ZIndex = 0 })
            new("UIGradient", { Rotation = rot, Parent = f, Transparency = NumberSequence.new({ nk(0, 0), nk(1, 1) }) })
            table.insert(edgeFades, f)
        end
        mkEdge(90,  V2(0, 0), UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.28))
        mkEdge(270, V2(0, 1), UDim2.fromScale(0, 1), UDim2.fromScale(1, 0.28))
        mkEdge(0,   V2(0, 0), UDim2.fromScale(0, 0), UDim2.fromScale(0.2, 1))
        mkEdge(180, V2(1, 0), UDim2.fromScale(1, 0), UDim2.fromScale(0.2, 1))
    end

    -- частицы
    local particleLayer = new("Frame", { Parent = main, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0 })
    local partCount = 0
    task.spawn(function()
        while gui.Parent do
            task.wait(Win.ParticleWait / Lib.Speed)
            if Win.Particles and Win.Open and partCount < 36 then
                partCount += 1
                local sz, x = math.random(2, 6), math.random()
                local p = new("Frame", { Parent = particleLayer, Size = UDim2.fromOffset(sz, sz), Position = UDim2.fromScale(x, 1.03),
                    BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.6 }, { corner(10) })
                local dur = math.random(60, 110) / 10
                tw(p, dur, { Position = UDim2.fromScale(clamp(x + (math.random() - 0.5) * 0.25, 0, 1), -0.05), BackgroundTransparency = 1 }, SINE)
                task.delay(dur / Lib.Speed + 0.1, function() p:Destroy() partCount -= 1 end)
            end
        end
    end)

    ------------------------------------------------------------------
    --  BACKGROUND SYSTEM
    ------------------------------------------------------------------
    local Bg = {
        Enabled = false, ImageId = "", Opacity = 1, Dim = 0.45, DimColor = "Black", DimCustom = rgb(0, 0, 0),
        Tint = WHITE, TintStrength = 0, Parallax = 0.02, KenBurns = false, KenSpeed = 0.08,
        Slideshow = false, SlideTime = 15, EdgeFade = true, ScaleType = "Crop",
        Images = {}, Index = 1, _ken = 0, _timer = 0, _applied = "",
    }
    Win.Bg = Bg
    local function resolveImageId(input)
        input = tostring(input or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if input == "" then return "" end
        if input:find("^rbxassetid://") or input:find("^rbxthumb://") or input:find("^http") then return input end
        local n = tonumber(input)
        if n then return "rbxassetid://" .. n end
        return ""
    end
    Win.ResolveImageId = resolveImageId
    local function currentImage()
        if Bg.Slideshow and #Bg.Images > 0 then return Bg.Images[Bg.Index] or "" end
        return resolveImageId(Bg.ImageId)
    end
    local function dimColor()
        if Bg.DimColor == "Theme" then return Theme.Accent2 end
        if Bg.DimColor == "Custom" then return Bg.DimCustom end
        return Color3.new(0, 0, 0)
    end
    function Win:ApplyBackground()
        local img = currentImage()
        Bg._applied = img
        local active = Bg.Enabled and img ~= ""
        local st = Bg.ScaleType == "Fit" and Enum.ScaleType.Fit or (Bg.ScaleType == "Stretch" and Enum.ScaleType.Stretch or Enum.ScaleType.Crop)
        Win.BgImage.Image = img
        Win.BgImage.ScaleType = st
        tw(Win.BgImage, 0.6, { ImageTransparency = active and (1 - Bg.Opacity) or 1 }, SINE)
        local dc = dimColor()
        Win.BgDim.BackgroundColor3 = dc
        tw(Win.BgDim, 0.6, { BackgroundTransparency = active and (1 - Bg.Dim) or 1 }, SINE)
        for _, f in ipairs(edgeFades) do
            f.BackgroundColor3 = dc
            f.Visible = active and Bg.EdgeFade
        end
        Win.BgImage.ImageColor3 = Bg.TintStrength > 0 and WHITE:Lerp(Bg.Tint, Bg.TintStrength) or WHITE
        if not active then
            Win.BgImage.Size = UDim2.fromScale(1.05, 1.05)
            Win.BgImage.Position = UDim2.fromScale(-0.025, -0.025)
        end
    end
    onTheme(function()
        if Bg.DimColor == "Theme" then
            local c = Theme.Accent2
            Win.BgDim.BackgroundColor3 = c
            for _, f in ipairs(edgeFades) do f.BackgroundColor3 = c end
        end
    end)
    local function bgStep(dt)
        if currentImage() ~= Bg._applied then Win:ApplyBackground() end
        if Bg.Parallax == 0 and not Bg.KenBurns and not (Bg.Slideshow and #Bg.Images > 1) then return end
        local buffer = 1 + Bg.Parallax * 2 + 0.02
        local kbScale, kbX, kbY = 1, 0, 0
        if Bg.KenBurns then
            Bg._ken += dt * Bg.KenSpeed
            kbScale = 1 + sin(Bg._ken) * 0.05
            kbX = sin(Bg._ken * 0.6) * 0.02
            kbY = math.cos(Bg._ken * 0.4) * 0.02
        end
        local total = buffer * kbScale
        local px, py = (1 - total) / 2 + kbX, (1 - total) / 2 + kbY
        if Bg.Parallax > 0 then
            local m = UIS:GetMouseLocation()
            px -= ((m.X - vpSize.X / 2) / vpSize.X) * Bg.Parallax
            py -= ((m.Y - vpSize.Y / 2) / vpSize.Y) * Bg.Parallax
        end
        Win.BgImage.Size = UDim2.fromScale(total, total)
        Win.BgImage.Position = UDim2.fromScale(px, py)
        if Bg.Slideshow and #Bg.Images > 1 then
            Bg._timer += dt
            if Bg._timer >= Bg.SlideTime then
                Bg._timer = 0
                Bg.Index = (Bg.Index % #Bg.Images) + 1
                Win:ApplyBackground()
            end
        end
    end

    ------------------------------------------------------------------
    --  SIDEBAR
    ------------------------------------------------------------------
    local side = new("Frame", { Parent = main, Position = UDim2.fromOffset(14, 14), Size = UDim2.new(0, 196, 1, -28), BackgroundColor3 = B"Side" }, { corner(18), stk() })
    glassT(side, 0.1)
    Win:Shadow(side, { Alpha = 0.32, Blur = 16, OffY = 3, Key = "Accent2" })
    local brand = new("Frame", { Parent = side, Size = UDim2.new(1, 0, 0, 74), BackgroundTransparency = 1 })
    local logoHolder = new("Frame", { Parent = brand, Position = UDim2.fromOffset(16, 18), Size = UDim2.fromOffset(38, 38), BackgroundColor3 = WHITE }, { corner(11) })
    if cfg.Logo then
        new("ImageLabel", { Parent = logoHolder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            Image = type(cfg.Logo) == "number" and ("rbxassetid://" .. cfg.Logo) or cfg.Logo, ScaleType = Enum.ScaleType.Fit })
        logoHolder.BackgroundTransparency = 1
    else
        Lib.Spin(Lib.Grad(logoHolder, "pill", 45), 40, function() return Win.Open end)
        label(logoHolder, string.sub(cfg.Title or "F", 1, 1), nil, nil, Enum.Font.GothamBlack, 20, B"OnAccent", Enum.TextXAlignment.Center)
    end
    local titleL = label(brand, cfg.Title or "FEMBOYSENSE", UDim2.fromOffset(62, 19), UDim2.new(1, -68, 0, 20), Enum.Font.GothamBlack, 15, WHITE)
    Lib.Shimmer(Lib.Grad(titleL, "shine"))
    label(brand, cfg.Sub or "HUB", UDim2.fromOffset(62, 40), UDim2.new(1, -68, 0, 12), Enum.Font.GothamMedium, 9, B"Sub")

    local NAV_STEP, HEAD_H, GAP = 44, 28, 8
    local nav = new("ScrollingFrame", { Parent = side, Position = UDim2.fromOffset(10, 78), Size = UDim2.new(1, -20, 1, -78 - 80),
        BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = B"Accent", CanvasSize = UDim2.new(), ClipsDescendants = true })
    local navInd = new("Frame", { Parent = nav, Size = UDim2.new(1, -4, 0, 40), BackgroundColor3 = B"Panel2", Visible = false, ZIndex = 1 }, {
        corner(12), new("UIGradient", { Transparency = NumberSequence.new({ nk(0, 0), nk(1, 0.65) }) }), stk() })
    local navBar = new("Frame", { Parent = navInd, Position = UDim2.fromOffset(0, 11), Size = UDim2.fromOffset(3, 18), BackgroundColor3 = WHITE }, { corner(2) })
    Lib.Grad(navBar, "lin", 90)

    local account = new("TextButton", { Parent = side, AnchorPoint = V2(0, 1), Position = UDim2.new(0, 12, 1, -12),
        Size = UDim2.new(1, -24, 0, 58), BackgroundColor3 = B"Panel" }, { corner(14), stk() })
    local avatar = new("ImageLabel", { Parent = account, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = B"Panel2",
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=100&h=100" }, { corner(17) })
    local accName = label(account, LocalPlayer.DisplayName, UDim2.fromOffset(54, 12), UDim2.new(1, -86, 0, 18), Enum.Font.GothamBold, 13, B"Text")
    Win:StreamLabel(accName, LocalPlayer.DisplayName, "Hidden")
    label(account, cfg.Version or "v1.0", UDim2.fromOffset(54, 30), UDim2.new(1, -86, 0, 14), Enum.Font.Gotham, 10, B"Sub")
    local accArrow = label(account, ">", UDim2.new(1, -24, 0, 0), UDim2.fromOffset(14, 58), Enum.Font.GothamBold, 13, B"Sub", Enum.TextXAlignment.Center)
    account.MouseEnter:Connect(function() tw(account, 0.25, { BackgroundColor3 = Theme.Panel2 }, SINE) tw(accArrow, 0.3, { Position = UDim2.new(1, -20, 0, 0) }, QUINT) end)
    account.MouseLeave:Connect(function() tw(account, 0.3, { BackgroundColor3 = Theme.Panel }, SINE) tw(accArrow, 0.3, { Position = UDim2.new(1, -24, 0, 0) }, QUINT) end)

    ------------------------------------------------------------------
    --  TOOLBAR
    ------------------------------------------------------------------
    local TBW = W - 238
    local toolbar = new("Frame", { Parent = main, Position = UDim2.fromOffset(224, 14), Size = UDim2.fromOffset(TBW, 52), BackgroundColor3 = B"Panel" }, { corner(16), stk() })
    glassT(toolbar, 0.1)
    Win:Shadow(toolbar, { Alpha = 0.3, Blur = 14, OffY = 3, Key = "Accent2" })
    local chip = new("Frame", { Parent = toolbar, Position = UDim2.fromOffset(9, 9), Size = UDim2.fromOffset(120, 34), BackgroundColor3 = B"Bg" }, { corner(11) })
    local fpsL = dyn(label(chip, "60 fps", UDim2.fromOffset(12, 0), UDim2.fromOffset(50, 34), Enum.Font.GothamBold, 12, B"Text"))
    local pingL = dyn(label(chip, "0 ms", UDim2.new(1, -56, 0, 0), UDim2.fromOffset(46, 34), Enum.Font.GothamMedium, 11, B"Sub", Enum.TextXAlignment.Right))
    Win.FpsLabel, Win.PingLabel = fpsL, pingL

    local function tbBtn(rightOff, text, w)
        local b = new("TextButton", { Parent = toolbar, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -rightOff, 0.5, 0),
            Size = UDim2.fromOffset(w or 36, 36), BackgroundColor3 = B"Bg", Text = text or "", TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 13 }, { corner(11) })
        local sc = new("UIScale", { Parent = b })
        b.MouseEnter:Connect(function() tw(b, 0.2, { BackgroundColor3 = Theme.Panel2 }, SINE) tw(sc, 0.3, { Scale = 1.08 }, BACK) end)
        b.MouseLeave:Connect(function() tw(b, 0.25, { BackgroundColor3 = Theme.Bg }, SINE) tw(sc, 0.25, { Scale = 1 }, SINE) end)
        b.MouseButton1Down:Connect(function() tw(sc, 0.08, { Scale = 0.9 }, SINE) end)
        b.MouseButton1Up:Connect(function() tw(sc, 0.3, { Scale = 1.08 }, BACK) end)
        return b
    end
    local closeBtn = tbBtn(9, "×")  closeBtn.TextSize = 20
    local hideBtn = tbBtn(53, "–")  hideBtn.TextSize = 18
    local gearBtn = tbBtn(97, "")
    if Icons.Settings then makeIcon(gearBtn, Icons.Settings, UDim2.fromOffset(9, 9), 18):Bind("Text") else gearBtn.Text = "⚙" end
    local langBtn = tbBtn(141, "EN", 40)  langBtn.TextSize = 12
    local chatBtn = tbBtn(189, "")
    if Icons.Chat then makeIcon(chatBtn, Icons.Chat, UDim2.fromOffset(9, 9), 18):Bind("Text") else chatBtn.Text = "Chat" chatBtn.TextSize = 10 chatBtn.Size = UDim2.fromOffset(44, 36) end
    closeBtn.MouseEnter:Connect(function() tw(closeBtn, 0.2, { BackgroundColor3 = rgb(220, 70, 80), TextColor3 = WHITE }, SINE) end)
    closeBtn.MouseLeave:Connect(function() tw(closeBtn, 0.25, { BackgroundColor3 = Theme.Bg, TextColor3 = Theme.Text }, SINE) end)

    local searchBack = new("Frame", { Parent = toolbar, Position = UDim2.fromOffset(138, 7), Size = UDim2.new(1, -138 - 240, 0, 38), BackgroundColor3 = B"Bg" }, { corner(12) })
    local searchStroke = new("UIStroke", { Color = B"Accent", Transparency = 1, Thickness = 1.2, Parent = searchBack })
    local searchIcon = makeIcon(searchBack, Icons.Search or 118685771787843, UDim2.fromOffset(12, 10), 18):Bind("Sub")
    local searchBox = new("TextBox", { Parent = searchBack, Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -48, 1, 0), BackgroundTransparency = 1,
        PlaceholderText = "Search modules…", PlaceholderColor3 = B"Sub", Text = "", TextColor3 = B"Text", TextSize = 13, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left })
    searchBox.Focused:Connect(function() tw(searchStroke, 0.25, { Transparency = 0.45 }, SINE) searchIcon:Paint(Theme.Text) end)
    searchBox.FocusLost:Connect(function() tw(searchStroke, 0.3, { Transparency = 1 }, SINE) searchIcon:Paint(Theme.Sub) end)

    local function canDrag() return Win.LockPos end
    drag(toolbar, root, canDrag)
    drag(brand, root, canDrag)

    ------------------------------------------------------------------
    --  CONTENT
    ------------------------------------------------------------------
    local content = new("Frame", { Parent = main, Position = UDim2.fromOffset(224, 80), Size = UDim2.fromOffset(TBW, H - 80 - 38), BackgroundColor3 = B"Bg", ClipsDescendants = true }, { corner(18), stk() })
    glassT(content, 0.03)
    local pageTitle = label(content, "", UDim2.fromOffset(22, 14), UDim2.new(1, -220, 0, 32), Enum.Font.GothamBold, 26, B"Text")
    local pageSub = label(content, "", UDim2.fromOffset(22, 48), UDim2.new(1, -220, 0, 16), Enum.Font.Gotham, 12, B"Sub")
    -- тонкая градиентная «подчёркивающая» полоска под заголовком
    local titleBar = new("Frame", { Parent = content, Position = UDim2.fromOffset(22, 68), Size = UDim2.fromOffset(38, 2), BackgroundColor3 = WHITE }, { corner(1) })
    Lib.Grad(titleBar, "lin")
    drag(pageTitle, root, canDrag)

    -- боковой отступ скролла = запас под тени карточек (иначе UIShadow обрежется клипом ScrollingFrame)
    local SCROLL_X = 4
    local scroll = new("ScrollingFrame", { Parent = content, Position = UDim2.fromOffset(SCROLL_X, 80), Size = UDim2.new(1, -SCROLL_X * 2, 1, -92), BackgroundTransparency = 1,
        ScrollBarThickness = 3, ScrollBarImageColor3 = B"Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
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

    local footL = label(main, "RSHIFT · HIDE   /   RMB · SETTINGS   /   ★ · FAVORITE", UDim2.fromOffset(238, H - 30), UDim2.fromOffset(420, 14), Enum.Font.GothamMedium, 10, B"Sub")
    label(main, cfg.Version or "v1.0", UDim2.new(1, -150, 1, -30), UDim2.fromOffset(130, 14), Enum.Font.GothamMedium, 10, B"Sub", Enum.TextXAlignment.Right)

    ------------------------------------------------------------------
    --  RIPPLE
    ------------------------------------------------------------------
    local function ptr(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            return V2(input.Position.X, input.Position.Y) + GuiService:GetGuiInset()
        end
        return UIS:GetMouseLocation()
    end
    function Win.Ripple(obj, input)
        if not Win.Ripples or not obj.Parent then return end
        local rel = (ptr(input) - obj.AbsolutePosition) / math.max(scale.Scale, 0.05)
        local r = new("Frame", { Parent = obj, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromOffset(rel.X, rel.Y),
            Size = UDim2.fromOffset(0, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.8 }, { corner(500) })
        tw(r, 0.9, { Size = UDim2.fromOffset(560, 560), BackgroundTransparency = 1 }, QUINT)
        Debris:AddItem(r, 1)
    end

    ------------------------------------------------------------------
    --  TOOLTIP / NOTIFY
    ------------------------------------------------------------------
    local tip = new("TextLabel", { Parent = gui, Size = UDim2.new(0, 0, 0, 24), AutomaticSize = AUTO_X, BackgroundColor3 = B"Panel2",
        Text = "", TextColor3 = B"Text", TextSize = 11, Visible = false, ZIndex = 200 }, { corner(8), stk(), pad(0, 0, 10, 10) })
    Win:Shadow(tip, { Alpha = 0.45, Blur = 12, OffY = 3, Key = "Accent" })
    local function showTip(text, obj)
        if not text or text == "" then return end
        tip.Text = T(text)
        tip.Position = UDim2.fromOffset(obj.AbsolutePosition.X, obj.AbsolutePosition.Y - 32)
        tip.Visible = true
    end

    local nholder = new("Frame", { Parent = gui, AnchorPoint = V2(1, 0), Position = UDim2.new(1, -16, 0, 16), Size = UDim2.fromOffset(340, 500), BackgroundTransparency = 1, ZIndex = 100 })
    local nlist = new("UIListLayout", { Parent = nholder, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Right })
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
    local notifStack, notifSound = {}, nil
    -- kind: "ok" | "warn" | "err" | Color3 | nil
    function Win:Notify(title, text, dur, kind, force)
        if not Win.NotifsOn and not force then return end
        dur = dur or Win.NotifTime
        title, text = T(tostring(title or "")), T(tostring(text or ""))
        local dir = nDir
        local col = (typeof(kind) == "Color3" and kind) or (kind and KIND[kind]) or Theme.Accent
        local glyph = "i"
        if col == SEM.Green then glyph = "✓" elseif col == SEM.Yellow then glyph = "!" elseif col == SEM.Red then glyph = "×" end

        local NW, TEXT_W = 320, 320 - 64 - 18
        local ok, sz = pcall(function() return TextService:GetTextSize(text, 12, Enum.Font.Gotham, V2(TEXT_W, 1000)) end)
        local textH = ok and sz.Y or 14
        local NH = math.max(72, 36 + textH + 24)

        while #notifStack >= 5 do
            local old = table.remove(notifStack, 1)
            if old and old.Close then old.Close() end
        end

        -- wrap (место в списке) > slide (двигается, держит UIShadow) > card (стекло, прозрачность)
        local wrap = new("Frame", { Parent = nholder, Size = UDim2.fromOffset(NW, NH), BackgroundTransparency = 1 })
        local slide = new("Frame", { Parent = wrap, Position = UDim2.fromOffset((NW + 60) * dir, 0), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, { corner(16) })
        local nsh = makeShadow(slide, { Color = col, Blur = 22, OffY = 6, Transparency = 1, Behind = Win.ShadowBehind })
        if nsh then nsh.Enabled = Win.Shadows end
        local card = new("CanvasGroup", { Parent = slide, Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = B"Panel", BackgroundTransparency = 0.06, GroupTransparency = 1 },
            { corner(16) })
        local cs = new("UIStroke", { Color = col, Thickness = 1.2, Transparency = 0.25, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card })
        new("UIGradient", { Parent = cs, Transparency = NumberSequence.new({ nk(0, 0), nk(0.55, 0.55), nk(1, 0.85) }) })
        new("Frame", { Parent = card, Size = UDim2.new(0, 120, 1, 0), BackgroundColor3 = col, BackgroundTransparency = 0.85 },
            { new("UIGradient", { Transparency = NumberSequence.new({ nk(0, 0), nk(1, 1) }) }) })
        local iconBg = new("Frame", { Parent = card, Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(36, 36),
            BackgroundColor3 = col, BackgroundTransparency = 0.8 }, { corner(12), plainStroke(col, 1.5, 0.2) })
        dyn(new("TextLabel", { Parent = iconBg, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = glyph,
            Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = col }))
        dyn(label(card, title, UDim2.fromOffset(64, 15), UDim2.fromOffset(TEXT_W, 18), Enum.Font.GothamBold, 13, B"Text"))
        dyn(label(card, text, UDim2.fromOffset(64, 34), UDim2.fromOffset(TEXT_W, textH), Enum.Font.Gotham, 12, B"Sub", nil,
            { TextWrapped = true, TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top }))
        local trackF = new("Frame", { Parent = card, AnchorPoint = V2(0, 1), Position = UDim2.new(0, 16, 1, -8), Size = UDim2.new(1, -32, 0, 3),
            BackgroundColor3 = WHITE, BackgroundTransparency = 0.92 }, { corner(2) })
        local fill = new("Frame", { Parent = trackF, Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE }, { corner(2),
            new("UIGradient", { Color = ColorSequence.new({ kp(0, col), kp(1, col:Lerp(WHITE, 0.55)) }) }) })

        local closing, hovered = false, false
        local entry = {}
        local function close()
            if closing then return end
            closing = true
            for i, e in ipairs(notifStack) do if e == entry then table.remove(notifStack, i) break end end
            tw(slide, 0.4, { Position = UDim2.fromOffset((NW + 60) * dir, 0) }, QUINT, IN)
            tw(card, 0.4, { GroupTransparency = 1 }, QUINT, IN)
            if nsh then tw(nsh, 0.3, { Transparency = 1 }, SINE) end
            task.delay(0.25, function() if wrap.Parent then tw(wrap, 0.3, { Size = UDim2.fromOffset(NW, 0) }, QUINT) end end)
            task.delay(0.55, function() if wrap.Parent then wrap:Destroy() end end)
        end
        entry.Close = close
        table.insert(notifStack, entry)

        local hit = new("TextButton", { Parent = card, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5 })
        hit.MouseEnter:Connect(function()
            hovered = true
            tw(iconBg, 0.2, { Size = UDim2.fromOffset(38, 38), Position = UDim2.fromOffset(15, 15) }, SINE)
            if nsh then tw(nsh, 0.25, { Transparency = 0.55, BlurRadius = UDim.new(0, 28) }, SINE) end
        end)
        hit.MouseLeave:Connect(function()
            hovered = false
            tw(iconBg, 0.3, { Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(16, 16) }, SINE)
            if nsh then tw(nsh, 0.3, { Transparency = 0.72, BlurRadius = UDim.new(0, 22) }, SINE) end
        end)
        hit.MouseButton1Click:Connect(close)

        tw(slide, 0.6, { Position = UDim2.fromOffset(0, 0) }, QUINT)
        tw(card, 0.6, { GroupTransparency = 0 }, QUINT)
        if nsh then tw(nsh, 0.7, { Transparency = 0.72 }, SINE) end

        if Win.NotifSoundOn then
            pcall(function()
                if not notifSound then
                    notifSound = Instance.new("Sound")
                    notifSound.SoundId = "rbxassetid://6696469190"
                    notifSound.Volume = 0.35
                    notifSound.Parent = SoundService
                end
                notifSound:Play()
            end)
        end

        task.spawn(function()
            local t = 0
            while t < dur and not closing and wrap.Parent do
                local d = task.wait()
                if not hovered then
                    t += d
                    fill.Size = UDim2.fromScale(clamp(1 - t / dur, 0, 1), 1)
                end
            end
            close()
        end)
    end

    ------------------------------------------------------------------
    --  CONFIRM
    ------------------------------------------------------------------
    local confirm = new("Frame", { Parent = main, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 80 })
    local cBox = new("Frame", { Parent = confirm, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, 150), BackgroundColor3 = B"Panel", ZIndex = 81 }, { corner(16), stk() })
    Win:Shadow(cBox, { Alpha = 0.6, Blur = 26, OffY = 8, Key = "Accent", ZIndex = 2 })
    local cScale = new("UIScale", { Parent = cBox, Scale = 0.8 })
    local cTitle = label(cBox, "", UDim2.fromOffset(20, 18), UDim2.new(1, -40, 0, 22), Enum.Font.GothamBold, 16, B"Text") cTitle.ZIndex = 82
    local cText = label(cBox, "", UDim2.fromOffset(20, 46), UDim2.new(1, -40, 0, 40), Enum.Font.Gotham, 12, B"Sub", nil, { TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None }) cText.ZIndex = 82
    local function cBtn(txt, x, accent)
        local b = new("TextButton", { Parent = cBox, Position = UDim2.new(x, x == 0 and 20 or 8, 1, -50), Size = UDim2.new(0.5, -28, 0, 34),
            BackgroundColor3 = accent and B"Accent" or B"Panel2", Text = txt, TextColor3 = accent and B"OnAccent" or B"Text", Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 82 }, { corner(10) })
        return b
    end
    local cNo, cYes = cBtn("Cancel", 0, false), cBtn("Yes", 0.5, true)
    local confirmYes
    local function closeConfirm()
        tw(confirm, 0.25, { BackgroundTransparency = 1 }, SINE)
        tw(cScale, 0.25, { Scale = 0.85 }, QUINT, IN)
        task.delay(0.26, function() confirm.Visible = false end)
    end
    cNo.MouseButton1Click:Connect(closeConfirm)
    cYes.MouseButton1Click:Connect(function() closeConfirm() if confirmYes then confirmYes() end end)
    function Win:Confirm(title, text, yes)
        setTxt(cTitle, title) setTxt(cText, text)
        confirmYes = yes
        confirm.Visible = true
        cScale.Scale = 0.8
        tw(confirm, 0.3, { BackgroundTransparency = 0.45 }, SINE)
        tw(cScale, 0.45, { Scale = 1 }, BACK)
    end

    ------------------------------------------------------------------
    --  FLOATING OPEN BUTTON
    ------------------------------------------------------------------
    local openBtn = new("TextButton", { Parent = gui, AnchorPoint = V2(1, 1), Position = UDim2.new(1, -24, 1, -24), Size = UDim2.fromOffset(48, 48),
        BackgroundColor3 = B"Accent", Visible = false, ZIndex = 70, Text = string.sub(cfg.Title or "F", 1, 1), TextColor3 = B"OnAccent", Font = Enum.Font.GothamBlack, TextSize = 20 }, { corner(24) })
    local openScale = new("UIScale", { Parent = openBtn })
    local openRing = new("Frame", { Parent = openBtn, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 69 }, { corner(30) })
    local openRingS = new("UIStroke", { Color = B"Accent", Thickness = 2, Transparency = 0.5, Parent = openRing })
    task.spawn(function()
        while gui.Parent do
            if openBtn.Visible then
                openRing.Size = UDim2.fromScale(1, 1) openRingS.Transparency = 0.4
                tw(openRing, 1.2, { Size = UDim2.fromScale(1.7, 1.7) }, QUINT) tw(openRingS, 1.2, { Transparency = 1 }, SINE)
            end
            task.wait(1.6)
        end
    end)
    drag(openBtn, openBtn)
    Win:AnimatedShadow(openBtn, { Size = 22, Alpha = 0.12, OffY = 4 })
    openBtn.MouseEnter:Connect(function() tw(openScale, 0.3, { Scale = 1.12 }, BACK) end)
    openBtn.MouseLeave:Connect(function() tw(openScale, 0.3, { Scale = 1 }, SINE) end)
--[[
    ЗАМЕНИ в библиотеке всё от строки
        --  KEYBIND LIST (HUD) v2
    до строки (включительно, перед MAIN LOOP) конца функции
        function Win:SetStreamer(on) ... end
    на этот блок целиком.
]]

    ------------------------------------------------------------------
    --  KEYBIND LIST (HUD) v3
    ------------------------------------------------------------------
    local HUD_W, HUD_ROW = 226, 28
    local hud = new("Frame", { Parent = gui, Position = UDim2.fromOffset(18, 100), Size = UDim2.fromOffset(HUD_W, 0), AutomaticSize = AUTO_Y,
        BackgroundColor3 = WHITE, BackgroundTransparency = 0.06, Visible = false, ZIndex = 60 },
        { corner(18), new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }), pad(10, 10, 10, 10) })
    local hudScale = new("UIScale", { Parent = hud })
    local hudBg = new("UIGradient", { Rotation = 90, Parent = hud })
    onTheme(function() hudBg.Color = ColorSequence.new(Theme.Accent2:Lerp(Theme.Panel, 0.72), Theme.Panel) end)
    local hudStroke = plainStroke(WHITE, 1.5, 0.15)
    hudStroke.Parent = hud
    Lib.Spin(Lib.Grad(hudStroke, "ring"), -90, function() return hud.Visible end)
    local hudShadow = Win:AnimatedShadow(hud, { Size = 30, Alpha = 0.09, OffY = 5 })
    hud.MouseEnter:Connect(function() hudShadow:SetHover(true) end)
    hud.MouseLeave:Connect(function() hudShadow:SetHover(false) end)
    Win.HudCompact = false

    local hudCount, hudHead
    do
        -- шапка (клик = показывать только активные)
        hudHead = new("TextButton", { Parent = hud, LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 })
        local badge = new("Frame", { Parent = hudHead, AnchorPoint = V2(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.fromOffset(24, 24), BackgroundColor3 = WHITE }, { corner(8) })
        Lib.Spin(Lib.Grad(badge, "pill", 45), 60, function() return hud.Visible end)
        if Icons.Keybinds then
            new("ImageLabel", { Parent = badge, AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14),
                BackgroundTransparency = 1, Image = type(Icons.Keybinds) == "number" and ("rbxassetid://" .. Icons.Keybinds) or Icons.Keybinds, ImageColor3 = WHITE })
        else
            new("TextLabel", { Parent = badge, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "K",
                Font = Enum.Font.GothamBlack, TextSize = 13, TextColor3 = WHITE })
        end
        local title = dyn(label(hudHead, "KEYBINDS", UDim2.fromOffset(36, 0), UDim2.new(1, -90, 1, 0), Enum.Font.GothamBlack, 11, WHITE))
        Lib.Shimmer(Lib.Grad(title, "shine"))
        hudCount = dyn(new("TextLabel", { Parent = hudHead, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0),
            Size = UDim2.fromOffset(0, 18), AutomaticSize = AUTO_X, BackgroundColor3 = B"Accent2", BackgroundTransparency = 0.45,
            Text = "0/0", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = WHITE }, { corner(9), pad(0, 0, 8, 8) }))
        local line = new("Frame", { Parent = hud, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = B"Accent" })
        new("UIGradient", { Parent = line, Transparency = NumberSequence.new({ nk(0, 0.15), nk(0.6, 0.75), nk(1, 1) }) })
        new("Frame", { Parent = hud, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 1 })
    end
    drag(hud, hud)

    local hudRows = {} -- [entry] = row

    local function mkHudRow()
        local r = {}
        r.Frame = new("Frame", { Parent = hud, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true, Visible = false })
        -- мягкая подсветка активной строки (слева направо)
        r.Hl = new("Frame", { Parent = r.Frame, Position = UDim2.fromOffset(0, 1), Size = UDim2.new(1, 0, 1, -2),
            BackgroundColor3 = WHITE, BackgroundTransparency = 1 },
            { corner(9), new("UIGradient", { Transparency = NumberSequence.new({ nk(0, 0), nk(1, 1) }) }) })
        r.Bar = new("Frame", { Parent = r.Frame, AnchorPoint = V2(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0),
            Size = UDim2.fromOffset(3, 14), BackgroundColor3 = Theme.Accent2 }, { corner(2) })
        r.Name = dyn(label(r.Frame, "", UDim2.fromOffset(18, 0), UDim2.new(1, -112, 1, 0), Enum.Font.GothamMedium, 12, Theme.Sub))
        local right = new("Frame", { Parent = r.Frame, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0),
            Size = UDim2.fromOffset(0, 22), AutomaticSize = AUTO_X, BackgroundTransparency = 1 },
            { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
                VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })
        r.Mode = dyn(new("TextLabel", { Parent = right, LayoutOrder = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AUTO_X, BackgroundTransparency = 1,
            Text = "HOLD", Font = Enum.Font.GothamBold, TextSize = 8, TextColor3 = Theme.Sub, TextTransparency = 0.25, Visible = false }))
        r.Cap = dyn(new("TextLabel", { Parent = right, LayoutOrder = 2, Size = UDim2.fromOffset(0, 20), AutomaticSize = AUTO_X,
            BackgroundColor3 = Theme.Panel2, Text = "", TextColor3 = Theme.Sub, Font = Enum.Font.GothamBold, TextSize = 10 },
            { corner(6), pad(0, 0, 7, 7), new("UISizeConstraint", { MinSize = V2(24, 20) }) }))
        r.CapStroke = plainStroke(Theme.Accent2, 1, 0.55)
        r.CapStroke.Parent = r.Cap
        r.CapScale = new("UIScale", { Parent = r.Cap })
        return r
    end

    local function paintHudRow(r, on, instant)
        local A, A2 = Theme.Accent, Theme.Accent2
        local function set(o, p, v)
            if instant then o[p] = v else tw(o, 0.25, { [p] = v }, SINE) end
        end
        set(r.Hl, "BackgroundColor3", A)
        set(r.Hl, "BackgroundTransparency", on and 0.82 or 1)
        set(r.Bar, "BackgroundColor3", on and A or A2)
        set(r.Bar, "BackgroundTransparency", on and 0 or 0.55)
        set(r.Name, "TextColor3", on and Theme.Text or Theme.Sub)
        set(r.Cap, "BackgroundColor3", on and A or Theme.Panel2)
        set(r.Cap, "TextColor3", on and Theme.OnAccent or Theme.Sub)
        set(r.CapStroke, "Color", on and A or A2)
        set(r.CapStroke, "Transparency", on and 0.2 or 0.55)
        set(r.Mode, "TextColor3", on and A or Theme.Sub)
        if on and r.on == false and not instant then
            r.CapScale.Scale = 1.18
            tw(r.CapScale, 0.45, { Scale = 1 }, BACK)
        end
        r.on = on
    end

    function Win:RefreshHud()
        local list = {}
        -- модули тоже лежат в BindList, поэтому идём только по нему (раньше строки дублировались)
        for _, b in ipairs(Win.BindList) do
            if b.Hud and b.Key and not b.Static then list[#list + 1] = b end
        end
        local seen, active = {}, 0
        for i, e in ipairs(list) do
            seen[e] = true
            local on = e.State == true
            if on then active += 1 end
            local r = hudRows[e]
            local fresh = (r == nil)
            if fresh then r = mkHudRow() hudRows[e] = r end
            r.Frame.LayoutOrder = i + 2
            r.Name.Text = tostring(e.Name or "?")
            r.Cap.Text = keyName(e.Key)
            r.Mode.Visible = (e.Mode == "Hold")
            paintHudRow(r, on, fresh)
            local show = (not Win.HudCompact) or on
            if show ~= r.shown then
                r.shown = show
                if show then r.Frame.Visible = true end
                tw(r.Frame, fresh and 0.45 or 0.3, { Size = UDim2.new(1, 0, 0, show and HUD_ROW or 0) }, QUINT)
                if not show then
                    task.delay(0.32, function() if r.Frame.Parent and not r.shown then r.Frame.Visible = false end end)
                end
            end
        end
        for e, r in pairs(hudRows) do
            if not seen[e] then hudRows[e] = nil r.Frame:Destroy() end
        end
        hudCount.Text = string.format("%d/%d", active, #list)
        tw(hudCount, 0.25, { BackgroundTransparency = active > 0 and 0.15 or 0.5 }, SINE)

        local want = Win.HudOn and #list > 0
        if want and not hud.Visible then
            hudScale.Scale = 0.92
            hud.Visible = true
            tw(hudScale, 0.45, { Scale = 1 }, BACK)
        elseif not want then
            hud.Visible = false
        end
    end
    function Win:SetBindsHud(on) Win.HudOn = on and true or false Win:RefreshHud() end
    function Win:SetBindsHudCompact(on) Win.HudCompact = on and true or false Win:RefreshHud() end
    hudHead.MouseButton1Click:Connect(function() sfx() Win:SetBindsHudCompact(not Win.HudCompact) end)
    onTheme(function() if Win.RefreshHud then Win:RefreshHud() end end)

    ------------------------------------------------------------------
    --  WATERMARK v3
    ------------------------------------------------------------------
    local WM_H = 38
    local wm = new("Frame", { Parent = gui, Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(0, WM_H), AutomaticSize = AUTO_X,
        BackgroundColor3 = WHITE, BackgroundTransparency = 0.08, Visible = false, ZIndex = 60 },
        { corner(19), pad(0, 0, 6, 14),
          new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 0),
              VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })
    local wmScale = new("UIScale", { Parent = wm })
    local wmBg = new("UIGradient", { Rotation = 0, Parent = wm })
    onTheme(function() wmBg.Color = ColorSequence.new(Theme.Accent2:Lerp(Theme.Panel, 0.72), Theme.Panel) end)
    local wmStroke = plainStroke(WHITE, 1.5, 0.15)
    wmStroke.Parent = wm
    Lib.Spin(Lib.Grad(wmStroke, "ring"), 90, function() return wm.Visible end)
    local wmShadow = Win:AnimatedShadow(wm, { Size = 30, Alpha = 0.09, OffY = 5 })
    wm.MouseEnter:Connect(function() wmShadow:SetHover(true) end)
    wm.MouseLeave:Connect(function() wmShadow:SetHover(false) end)

    -- бренд: бейдж со статус-точкой, название и тег версии
    do
        local brand = new("Frame", { Parent = wm, LayoutOrder = 0, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AUTO_X, BackgroundTransparency = 1 },
            { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
                VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })
        local badge = new("Frame", { Parent = brand, LayoutOrder = 0, Size = UDim2.fromOffset(26, 26), BackgroundColor3 = WHITE }, { corner(9) })
        Lib.Spin(Lib.Grad(badge, "pill", 45), 60, function() return wm.Visible end)
        new("TextLabel", { Parent = badge, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = string.sub(cfg.Title or "F", 1, 1),
            Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = WHITE })
        local dot = new("Frame", { Parent = badge, AnchorPoint = V2(0.5, 0.5), Position = UDim2.new(1, -2, 1, -2), Size = UDim2.fromOffset(8, 8),
            BackgroundColor3 = SEM.Green, ZIndex = 3 }, { corner(4), plainStroke(Theme.Panel, 1.5) })
        pcall(function()
            TweenService:Create(dot, TweenInfo.new(1.1, SINE, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.65 }):Play()
        end)
        local title = dyn(new("TextLabel", { Parent = brand, LayoutOrder = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AUTO_X, BackgroundTransparency = 1,
            Text = cfg.Title or "FEMBOYSENSE", Font = Enum.Font.GothamBlack, TextSize = 12, TextColor3 = WHITE }))
        Lib.Shimmer(Lib.Grad(title, "shine"))
        dyn(new("TextLabel", { Parent = brand, LayoutOrder = 2, Size = UDim2.fromOffset(0, 16), AutomaticSize = AUTO_X,
            BackgroundColor3 = B"Accent2", BackgroundTransparency = 0.55, Text = cfg.Version or "v1.0", Font = Enum.Font.GothamBold,
            TextSize = 9, TextColor3 = B"Text" }, { corner(8), pad(0, 0, 7, 7) }))
    end

    -- чип: разделитель | маркер (иконка или точка) | значение
    -- tint=true: маркер повторяет цвет значения (зелёный/жёлтый/красный из главного цикла)
    local function wmChip(order, icon, width, text, tint)
        local f = new("Frame", { Parent = wm, LayoutOrder = order, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AUTO_X, BackgroundTransparency = 1 },
            { pad(0, 0, 12, 0),
              new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
                  VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })
        local div = new("Frame", { Parent = f, LayoutOrder = 0, Size = UDim2.fromOffset(1, 16), BackgroundColor3 = B"Accent" })
        new("UIGradient", { Parent = div, Rotation = 90, Transparency = NumberSequence.new({ nk(0, 1), nk(0.5, 0.35), nk(1, 1) }) })

        local mark, prop
        if icon then
            prop = "ImageColor3"
            mark = new("ImageLabel", { Parent = f, LayoutOrder = 1, Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1,
                Image = type(icon) == "number" and ("rbxassetid://" .. icon) or icon, ImageColor3 = tint and Theme.Text or nil })
        else
            prop = "BackgroundColor3"
            mark = new("Frame", { Parent = f, LayoutOrder = 1, Size = UDim2.fromOffset(6, 6) }, { corner(3) })
        end
        if not tint then bind(mark, prop, "Accent") end

        local l = dyn(new("TextLabel", { Parent = f, LayoutOrder = 2, Size = UDim2.fromOffset(width, 16), BackgroundTransparency = 1,
            AutomaticSize = width == 0 and AUTO_X or AUTO_NONE, Text = text, Font = Enum.Font.GothamBold, TextSize = 12,
            TextColor3 = B"Text", TextXAlignment = Enum.TextXAlignment.Left }))
        if tint then
            mark[prop] = l.TextColor3
            l:GetPropertyChangedSignal("TextColor3"):Connect(function() mark[prop] = l.TextColor3 end)
        end
        return l, f
    end

    local wmFps,  wmFpsF  = wmChip(3, Icons.FPS,  Icons.FPS  and 28 or 54, "0", true)
    local wmPing, wmPingF = wmChip(5, Icons.Ping, Icons.Ping and 46 or 58, "0 ms", true)
    local wmTime, wmTimeF = wmChip(7, nil, 0, "00:00:00")
    local wmUser, wmUserF = wmChip(9, nil, 0, LocalPlayer.DisplayName)
    wmUserF.Visible = false
    Win:StreamLabel(wmUser, LocalPlayer.DisplayName, "Hidden")
    Win.WMChips = { Fps = wmFps, Ping = wmPing, Time = wmTime, User = wmUser }
    Win.WMFrames = { Fps = wmFpsF, Ping = wmPingF, Time = wmTimeF, User = wmUserF }
    drag(wm, wm)

    function Win:SetWatermark(on)
        on = on and true or false
        if on and not wm.Visible then
            wmScale.Scale = 0.9
            wm.Visible = true
            tw(wmScale, 0.45, { Scale = 1 }, BACK)
        else
            wm.Visible = on
        end
    end
    function Win:SetWatermarkPos(name)
        local right, bottom = name:find("Right") ~= nil, name:find("Bottom") ~= nil
        wm.AnchorPoint = V2(right and 1 or 0, bottom and 1 or 0)
        wm.Position = UDim2.new(right and 1 or 0, right and -18 or 18, bottom and 1 or 0, bottom and -18 or 18)
    end
    function Win:SetWatermarkChip(name, on) if Win.WMFrames[name] then Win.WMFrames[name].Visible = on end end
    -- общая прозрачность стеклянных оверлеев (watermark + keybind HUD)
    function Win:SetWatermarkOpacity(v)
        local bgT, stT = 1 - v, 0.15 + (1 - v) * 0.6
        wm.BackgroundTransparency, hud.BackgroundTransparency = bgT, bgT
        wmStroke.Transparency, hudStroke.Transparency = stT, stT
    end
    function Win:SetStreamer(on)
        Win.Streamer = on and true or false
        for _, e in ipairs(Win.StreamTargets) do e[1].Text = on and e[3] or e[2] end
        avatar.ImageTransparency = on and 1 or 0
        if Win.OnStreamer then Win.OnStreamer(on) end
    end

    ------------------------------------------------------------------
    --  MAIN LOOP
    ------------------------------------------------------------------
    local frames, last, fpsAvg = 0, os.clock(), 60
    local decorAcc, clockT = 0, 0
    keep(RunService.RenderStepped:Connect(function(dt)
        local open = Win.Open
        local wantModal = Win.FreeMouse and open
        if modalBtn.Modal ~= wantModal then modalBtn.Modal = wantModal end

        frames += 1
        local now = os.clock()
        if now - last >= 0.5 then
            fpsAvg = fpsAvg + (math.floor(frames / (now - last)) - fpsAvg) * 0.6
            local fps = math.floor(fpsAvg + 0.5)
            local ping = 0
            pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            if open then fpsL.Text, pingL.Text = fps .. " fps", ping .. " ms" end
            if wm.Visible then
                wmFps.Text = Icons.FPS and tostring(fps) or (fps .. " fps")
                wmPing.Text = ping .. (Icons.Ping and "ms" or " ms")
                wmTime.Text = os.date(Win.Time24 == false and "%I:%M:%S %p" or "%H:%M:%S")
                if Win.WMColors then
                    wmFps.TextColor3 = fps >= 55 and SEM.Green or (fps >= 30 and SEM.Yellow or SEM.Red)
                    wmPing.TextColor3 = ping <= 80 and SEM.Green or (ping <= 150 and SEM.Yellow or SEM.Red)
                else
                    wmFps.TextColor3, wmPing.TextColor3 = Theme.Text, Theme.Text
                end
            end
            if open and next(Win.Tiles) then
                local t = Win.Tiles
                if t.FPS then t.FPS.Text = tostring(fps) end
                if t.PING then t.PING.Text = ping .. "ms" end
                if t.PLAYERS then t.PLAYERS.Text = #Players:GetPlayers() .. "/" .. Players.MaxPlayers end
                if t.TIME then t.TIME.Text = os.date("%H:%M") end
            end
            Win.Fps, Win.Ping = fps, ping
            if Win.OnStats then Win.OnStats(fps, ping) end
            frames, last = 0, now
        end

        -- единый «декор-тик» 30 Гц: вращение рамок, shimmer, пульс, анимированные тени
        decorAcc += dt
        if decorAcc >= DECOR_STEP then
            local d = decorAcc
            decorAcc = 0
            clockT += d
            if open or wm.Visible or hud.Visible then
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
                if Win.BorderPulse and open then
                    mainStroke.Transparency = clamp(Win._glowT + 0.15 * sin(clockT * 2.4), 0, 1)
                end
            end
            for i = #shadowList, 1, -1 do
                local e = shadowList[i]
                if e.Shadow and not e.Shadow.Parent then table.remove(shadowList, i) else e:Step(d, clockT) end
            end
        end

        if open and Bg.Enabled then bgStep(dt) end
    end))

    ------------------------------------------------------------------
    --  NAV LAYOUT
    ------------------------------------------------------------------
    local function layoutNav(instant)
        local y = 0
        for _, g in ipairs(Win.Groups) do
            local headY = y
            if g.Head then
                g.Head.Position = UDim2.fromOffset(0, y)
                g.Head.Visible = #g.cats > 0
                tw(g.Arrow, instant and 0.01 or 0.3, { Rotation = g.open and 90 or 0 }, SINE)
                if #g.cats > 0 then y += HEAD_H end
            end
            for _, c in ipairs(g.cats) do
                if g.open or not g.Head then
                    c.Y = y
                    if not c.Btn.Visible then c.Btn.Position = UDim2.fromOffset(0, headY) end
                    c.Btn.Visible = true
                    if instant then c.Btn.Position = UDim2.fromOffset(0, y) else tw(c.Btn, 0.35, { Position = UDim2.fromOffset(0, y) }, QUINT) end
                    y += NAV_STEP
                else
                    c.Y = headY
                    c.Btn.Visible = false
                end
            end
            if #g.cats > 0 then y += GAP end
        end
        nav.CanvasSize = UDim2.fromOffset(0, y + 6)
        local cur = Win.Current
        if cur and cur.Y then
            navInd.Visible = (cur.Group.open or not cur.Group.Head) and true or false
            tw(navInd, instant and 0.01 or 0.45, { Position = UDim2.fromOffset(0, cur.Y) }, BACK)
        end
    end

    function Win:AddGroup(name)
        local g = { name = name, open = true, cats = {} }
        if name ~= "" then
            local head = new("TextButton", { Parent = nav, Size = UDim2.new(1, 0, 0, HEAD_H), BackgroundTransparency = 1, Text = "" })
            label(head, name, UDim2.fromOffset(6, 2), UDim2.new(1, -40, 1, -4), Enum.Font.GothamBold, 10, B"Sub")
            g.Arrow = new("TextLabel", { Parent = head, AnchorPoint = V2(0.5, 0.5), Position = UDim2.new(1, -12, 0.5, -1), Size = UDim2.fromOffset(14, 14),
                BackgroundTransparency = 1, Text = ">", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = B"Sub", Rotation = 90 })
            new("Frame", { Parent = head, Position = UDim2.new(0, 6, 1, -3), Size = UDim2.new(1, -12, 0, 1), BackgroundColor3 = B"Accent", BackgroundTransparency = 0.7 })
            head.MouseButton1Click:Connect(function() sfx() g.open = not g.open layoutNav() end)
            g.Head = head
        end
        table.insert(Win.Groups, g)
        Win._group = g
        return g
    end

    ------------------------------------------------------------------
    --  LAYOUT / SELECTION
    ------------------------------------------------------------------
    local function visibleMods()
        local q, cat, list = Win.Query, Win.Current, {}
        for _, m in ipairs(Win.Modules) do
            local show
            if q ~= "" then show = m.Search:find(q, 1, true)
            elseif cat.All then show = true
            elseif cat.Filter then show = cat.Filter(m)
            else show = (m.Cat == cat) end
            if show then list[#list + 1] = m end
        end
        if cat.Sort and q == "" then table.sort(list, cat.Sort) end
        return list
    end
    local layoutTok = 0
    local function layout()
        local cat = Win.Current
        if not cat then return end
        layoutTok += 1
        for _, m in ipairs(Win.Modules) do m.Holder.Parent = stash end
        for _, c in ipairs(Win.Categories) do for _, t in ipairs(c.Tops) do t.Parent = stash end end
        local list = visibleMods()
        local q = Win.Query
        local tops = 0
        if q == "" then
            for _, t in ipairs(cat.Tops) do t.Parent = topHolder tops += 1 end
        end
        for i, m in ipairs(list) do
            m.Holder.Parent = (i % 2 == 1) and colL or colR
            m.Card.GroupTransparency = 1
            m.Scale.Scale = 0.93
            if m.Shadow then m.Shadow:FadeIn() end
            task.delay(0.03 + (i - 1) * 0.045, function()
                if m.Holder.Parent == colL or m.Holder.Parent == colR then
                    tw(m.Card, 0.5, { GroupTransparency = 0 }, SINE)
                    tw(m.Scale, 0.6, { Scale = 1 }, BACK)
                end
            end)
        end
        if q == "" and cat.OnShow then task.defer(cat.OnShow) end
        emptyL.Visible = (#list == 0 and tops == 0)
        if q ~= "" then
            setTxt(pageTitle, "Search")
            pageSub.Text = T("Results for") .. ' "' .. searchBox.Text .. '"'
        else
            setTxt(pageTitle, cat.Name)
            setTxt(pageSub, cat.Sub)
        end
        pageTitle.TextTransparency, pageSub.TextTransparency = 1, 1
        pageTitle.Position = UDim2.fromOffset(8, 14)
        tw(pageTitle, 0.5, { TextTransparency = 0, Position = UDim2.fromOffset(22, 14) }, QUINT)
        tw(pageSub, 0.7, { TextTransparency = 0 }, SINE)
        titleBar.Size = UDim2.fromOffset(0, 2)
        tw(titleBar, 0.6, { Size = UDim2.fromOffset(38, 2) }, QUINT)
        scroll.CanvasPosition = Vector2.zero
        scroll.Position = UDim2.fromOffset(SCROLL_X, 104)
        tw(scroll, 0.6, { Position = UDim2.fromOffset(SCROLL_X, 80) }, QUINT)
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
        if type(cat) == "string" then for _, c in ipairs(Win.Categories) do if c.Name == cat then cat = c break end end end
        if type(cat) ~= "table" then return end
        local first = (Win.Current == nil)
        Win.Current = cat
        if cat.Group and not cat.Group.open then cat.Group.open = true layoutNav() end
        paintNav()
        navInd.Visible = true
        if cat.Y then
            if first then navInd.Position = UDim2.fromOffset(0, cat.Y) else tw(navInd, 0.5, { Position = UDim2.fromOffset(0, cat.Y) }, BACK) end
            local vis, cy = nav.AbsoluteSize.Y, nav.CanvasPosition.Y
            if cat.Y < cy then tw(nav, 0.4, { CanvasPosition = V2(0, cat.Y) }, QUINT)
            elseif cat.Y + 44 > cy + vis then tw(nav, 0.4, { CanvasPosition = V2(0, cat.Y + 44 - vis) }, QUINT) end
        end
        layout()
    end

    function Win:AddCategory(name, icon, sub, opts)
        opts = opts or {}
        if not Win._group then Win:AddGroup("") end
        local grp = Win._group
        local cat = { Name = name, Sub = sub or "", Tops = {}, All = opts.All, Filter = opts.Filter, Sort = opts.Sort, Modules = {}, Group = grp, Y = 0 }
        local btn = new("TextButton", { Parent = nav, Size = UDim2.new(1, -4, 0, 40), BackgroundTransparency = 1, ZIndex = 2 })
        cat.Btn = btn
        cat.Icon = makeIcon(btn, icon, UDim2.fromOffset(14, 11), 18)
        cat.Label = label(btn, name, UDim2.fromOffset(44, 0), UDim2.new(1, -52, 1, 0), Enum.Font.GothamMedium, 14, B"Sub")
        cat.Label.ZIndex = 3
        btn.MouseEnter:Connect(function()
            if Win.Current ~= cat then
                tw(cat.Label, 0.2, { TextColor3 = Theme.Text }, SINE) tw(cat.Label, 0.3, { Position = UDim2.fromOffset(49, 0) }, QUINT) cat.Icon:Paint(Theme.Text)
            end
        end)
        btn.MouseLeave:Connect(function()
            tw(cat.Label, 0.3, { Position = UDim2.fromOffset(44, 0) }, QUINT)
            if Win.Current ~= cat then tw(cat.Label, 0.25, { TextColor3 = Theme.Sub }, SINE) cat.Icon:Paint(Theme.Sub) end
        end)
        btn.MouseButton1Click:Connect(function() sfx() searchBox.Text = "" Win.Query = "" Win:Select(cat) end)

        function cat:AddTop(f) f.LayoutOrder = #cat.Tops + 1 table.insert(cat.Tops, f) return f end
        function cat:AddCustom(h)
            local f = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1 })
            return cat:AddTop(f)
        end

        -- карточка приветствия
        function cat:AddHero(o)
            o = o or {}
            local f = cat:AddCustom(104)
            local card = new("Frame", { Parent = f, Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.05 },
                { corner(18), new("UIStroke", { Color = B"Accent2", Thickness = 1, Transparency = 0.3 }) })
            Win:Shadow(card, { Alpha = 0.3, Blur = 14, OffY = 3, Key = "Accent2" })
            local bgG = new("UIGradient", { Parent = card })
            onTheme(function() bgG.Color = ColorSequence.new(Theme.Accent2:Lerp(Theme.Panel, 0.6), Theme.Panel) end)
            new("ImageLabel", { Parent = card, Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(72, 72), BackgroundColor3 = B"Panel2",
                Image = o.Image or ("rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150") }, { corner(14), new("UIStroke", { Color = B"Accent", Thickness = 1.5, Transparency = 0.15 }) })
            label(card, o.Welcome or "WELCOME BACK", UDim2.fromOffset(106, 16), UDim2.fromOffset(250, 14), Enum.Font.GothamBold, 10, B"Accent")
            local nm = label(card, o.Name or LocalPlayer.DisplayName, UDim2.fromOffset(106, 31), UDim2.new(1, -130, 0, 28), Enum.Font.GothamBlack, 22, WHITE)
            Lib.Shimmer(Lib.Grad(nm, "shine"))
            Win:StreamLabel(nm, o.Name or LocalPlayer.DisplayName, "Streamer")
            local playing = dyn(label(card, "Playing  ...", UDim2.fromOffset(106, 64), UDim2.new(1, -130, 0, 18), Enum.Font.GothamMedium, 12, B"Sub"))
            task.spawn(function()
                local ok, info = pcall(function() return Marketplace:GetProductInfo(game.PlaceId) end)
                playing.Text = "Playing  " .. ((ok and info and info.Name) or "this game")
            end)
            local session = dyn(label(card, "Session 00:00:00", UDim2.new(1, -176, 0, 16), UDim2.fromOffset(160, 14), Enum.Font.GothamMedium, 11, B"Sub", Enum.TextXAlignment.Right))
            local t0 = os.time()
            task.spawn(function()
                while gui.Parent do
                    local s = os.time() - t0
                    session.Text = string.format("Session %02d:%02d:%02d", s // 3600, (s // 60) % 60, s % 60)
                    task.wait(1)
                end
            end)
            return f
        end

        -- плитки FPS / PING / PLAYERS / TIME
        function cat:AddTiles(names)
            names = names or { "FPS", "PING", "PLAYERS", "TIME" }
            local f = cat:AddCustom(76)
            new("UIListLayout", { Parent = f, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
            local n = #names
            local icons = { FPS = Icons.FPS, PING = Icons.Ping }
            for i, name in ipairs(names) do
                local tile = new("Frame", { Parent = f, LayoutOrder = i, Size = UDim2.new(1 / n, -(10 * (n - 1)) / n, 1, 0), BackgroundColor3 = B"Panel", BackgroundTransparency = 0.1 },
                    { corner(16), new("UIStroke", { Color = B"Accent2", Thickness = 1, Transparency = 0.4 }) })
                local ts = Win:Shadow(tile, { Alpha = 0.26, Blur = 12, OffY = 3, Key = "Accent2" })
                tile.MouseEnter:Connect(function() ts:SetHover(true) end)
                tile.MouseLeave:Connect(function() ts:SetHover(false) end)
                label(tile, name, UDim2.fromOffset(14, 12), UDim2.new(1, -44, 0, 12), Enum.Font.GothamBold, 10, B"Sub")
                if icons[name] then
                    new("ImageLabel", { Parent = tile, AnchorPoint = V2(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(18, 18),
                        BackgroundTransparency = 1, Image = type(icons[name]) == "number" and ("rbxassetid://" .. icons[name]) or icons[name], ImageColor3 = B"Accent" })
                end
                Win.Tiles[name] = dyn(label(tile, "-", UDim2.fromOffset(14, 32), UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, 20, B"Text"))
            end
            return f
        end

        function cat:AddModule(o)
            o = o or {}
            local defKey = (o.Keybind ~= true) and o.Keybind or nil
            local mod = { Name = o.Name or "Module", Info = o.Info, Cat = cat, State = o.Default and true or false, Key = defKey, DefaultKey = defKey, Mode = o.Mode or "Toggle",
                Static = o.Static, _n = 0, Search = ((o.Name or "") .. " " .. (o.Info or "")):lower(), Fav = false, Hud = true }
            -- holder (прозрачная обёртка + UICorner + UIShadow + UIScale) > card (CanvasGroup: клипует и фейдит содержимое)
            -- UIShadow нельзя класть в CanvasGroup — он бы обрезался канвасом, поэтому тень живёт на обёртке.
            local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1 }, { corner(16) })
            mod.Scale = new("UIScale", { Parent = holder })
            local card = new("CanvasGroup", { Parent = holder, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundColor3 = B"Panel" },
                { corner(16), pad(14, 14, 16, 16), new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
            local cardStroke = stk()
            cardStroke.Parent = card
            new("UIGradient", { Parent = cardStroke, Rotation = 90, Transparency = NumberSequence.new(0, 0.7) }) -- обводка «подсвечена» сверху
            glassT(card, 0.12)
            mod.Card, mod.Holder = card, holder
            mod.Shadow = Win:Shadow(holder, { Alpha = 0.2, Blur = 14, OffY = 3, Key = "Accent2", Kind = "card" })
            holder.Parent = stash
            card.MouseEnter:Connect(function()
                tw(card, 0.3, { BackgroundColor3 = Theme.Panel:Lerp(Theme.Panel2, 0.45) }, SINE)
                tw(cardStroke, 0.3, { Color = Theme.Accent, Transparency = 0.65 }, SINE)
                mod.Shadow:SetHover(true)
            end)
            card.MouseLeave:Connect(function()
                tw(card, 0.35, { BackgroundColor3 = Theme.Panel }, SINE)
                tw(cardStroke, 0.35, { Color = Theme.Stroke, Transparency = Theme.StrokeT }, SINE)
                mod.Shadow:SetHover(false)
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

            local star = new("TextButton", { Parent = head, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -26, 0.5, 0), Size = UDim2.fromOffset(20, 20),
                BackgroundTransparency = 1, Text = "★", TextColor3 = B"Sub", Font = Enum.Font.GothamBold, TextSize = 15, TextTransparency = 0.5 })
            local function paintStar() tw(star, 0.25, { TextColor3 = mod.Fav and Theme.Accent or Theme.Sub, TextTransparency = mod.Fav and 0 or 0.5 }, SINE) end
            onTheme(paintStar)
            star.MouseButton1Click:Connect(function() sfx() mod.Fav = not mod.Fav Win.Favs[mod.Name] = mod.Fav or nil paintStar() if Win.Current and Win.Current.Name == "Favorites" then layout() end end)
            function mod:SetFav(v) mod.Fav = v paintStar() end

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
                if expand then tw(expand, 0.4, { Rotation = v and 45 or 0, TextColor3 = v and Theme.Accent or Theme.Sub }, BACK) end
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
                        tw(sf, 0.5, { Size = UDim2.new(1, 0, 0, hgt) }, QUINT).Completed:Wait()
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
            local function touch() mod._t = os.clock() Win.Recent[mod.Name] = mod._t end

            if mod.Static then
                star.Visible = false
                setOpen(true, true)
                function mod:Set() end
                function mod:SetKey() end
            else
                expand = new("TextButton", { Parent = head, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(22, 22),
                    BackgroundTransparency = 1, Text = "+", TextColor3 = B"Sub", Font = Enum.Font.GothamMedium, TextSize = 20 })
                expand.MouseButton1Click:Connect(function() sfx() setOpen(not open) end)

                local status = new("Frame", { Parent = card, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 })
                local stL = label(status, "Disabled", nil, UDim2.new(1, -140, 1, 0), Enum.Font.GothamMedium, 13, B"Sub")
                local pill = new("TextButton", { Parent = status, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -50, 0.5, 0), Size = UDim2.fromOffset(0, 22), AutomaticSize = AUTO_X,
                    BackgroundColor3 = B"Panel2", Text = "BIND", TextColor3 = B"Sub", Font = Enum.Font.GothamBold, TextSize = 10 }, { corner(7), pad(0, 0, 9, 9) })
                local pillScale = new("UIScale", { Parent = pill })
                local function paintPill(listening)
                    pill.Text = listening and "..." or (mod.Key and keyName(mod.Key) or T("BIND"))
                    tw(pill, 0.25, { BackgroundColor3 = (listening or mod.Key) and Theme.Accent or Theme.Panel2, TextColor3 = (listening or mod.Key) and Theme.OnAccent or Theme.Sub }, SINE)
                    if not listening then pillScale.Scale = 0.85 tw(pillScale, 0.4, { Scale = 1 }, BACK) end
                end
                mod.PaintPill = paintPill
                local sw
                sw = makeSwitch(status, mod.State, function(v) mod:Set(v) end)
                function mod:Set(v, silent)
                    v = v and true or false
                    if mod.State == v then return end
                    mod.State = v
                    setTxt(stL, v and "Enabled" or "Disabled")
                    tw(stL, 0.3, { TextColor3 = v and Theme.Text or Theme.Sub }, SINE)
                    sw:Set(v, true)
                    if not silent then touch() fire(o.Callback, v) end
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
                pill.MouseButton1Click:Connect(function() sfx() listen() end)
                paintPill(false)
                if mod.State then setTxt(stL, "Enabled") stL.TextColor3 = Theme.Text task.defer(fire, o.Callback, true) end
                card.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton2 then setOpen(not open)
                    elseif i.UserInputType == Enum.UserInputType.MouseButton3 then listen() end
                end)

                -- строка бинда в настройках (+ сброс к дефолту)
                local krow = new("Frame", { Parent = sf, LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 })
                label(krow, "Keybind", nil, UDim2.new(1, -200, 1, 0), Enum.Font.GothamMedium, 13, B"Text")
                local modeB = new("TextButton", { Parent = krow, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -86, 0.5, 0), Size = UDim2.fromOffset(62, 24),
                    BackgroundColor3 = B"Panel2", Text = mod.Mode, TextColor3 = B"Sub", Font = Enum.Font.GothamBold, TextSize = 10 }, { corner(8) })
                modeB.MouseButton1Click:Connect(function() sfx() mod.Mode = mod.Mode == "Toggle" and "Hold" or "Toggle" setTxt(modeB, mod.Mode) end)
                local kb = new("TextButton", { Parent = krow, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(78, 24),
                    BackgroundColor3 = B"Panel2", Text = "", TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 10 }, { corner(8) })
                local rb = resetBtn(krow, UDim2.new(1, -156, 0.5, 0), function() sfx() mod:SetKey(mod.DefaultKey) end)
                local function paintKb(k)
                    kb.Text = k and keyName(k) or T("NONE")
                    rb.Visible = (mod.Key ~= mod.DefaultKey)
                end
                paintKb(mod.Key)
                mod.KeyRow = paintKb
                kb.MouseButton1Click:Connect(function() sfx() kb.Text = "..." Lib._listen = function(k) if k == Enum.KeyCode.Escape or k == Enum.KeyCode.Backspace then mod:SetKey(nil) else mod:SetKey(k) end end end)
                mod.ModeBtn = modeB
                mod._n = 0
                table.insert(Win.BindList, mod)
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
                local sw = makeSwitch(row, t.Default, function(v) touch() fire(t.Callback, v) end)
                local api = {}
                function api:Set(v, silent) sw:Set(v, silent) end
                function api:Get() return sw:Get() end
                api.Export = function() return sw:Get() end
                api.Import = function(v) sw:Set(v and true or false) end
                api.Row = row
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
                    b.MouseButton1Click:Connect(function() if sel ~= name then sfx() sel = name paint() touch() fire(t.Callback, name) end end)
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
                    ScrollBarThickness = 2, ScrollBarImageColor3 = B"Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y },
                    { new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
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
                        tw(b, 0.3, { BackgroundColor3 = on and Theme.Accent or Theme.Panel2, TextColor3 = on and Theme.OnAccent or Theme.Sub }, SINE)
                    end
                end
                local function choose(v, silent) sel = v selL.Text = tostring(v) paint() if not silent then touch() fire(t.Callback, v) end end
                local function build()
                    for _, b in pairs(btns) do b:Destroy() end
                    btns = {}
                    for i, name in ipairs(opts) do
                        local b = new("TextButton", { Parent = list, LayoutOrder = i, Size = UDim2.new(1, -4, 0, ITEM), BackgroundColor3 = B"Panel2", Text = tostring(name),
                            TextColor3 = B"Sub", Font = Enum.Font.GothamMedium, TextSize = 12 }, { corner(8) })
                        btns[name] = b
                        b.MouseButton1Click:Connect(function() sfx() choose(name) setOpen(false) end)
                    end
                    paint()
                    if open then setOpen(true) end
                end
                build()
                onTheme(paint)
                local hdr = new("TextButton", { Parent = row, Size = UDim2.new(1, 0, 0, ROW), BackgroundTransparency = 1, ZIndex = 3 })
                hdr.InputBegan:Connect(function(i) if isPress(i) then Win.Ripple(row, i) end end)
                hdr.MouseButton1Click:Connect(function() sfx() setOpen(not open) end)
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
                    BackgroundColor3 = B"Panel2", Text = t.ButtonText or "RUN", TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 11, ClipsDescendants = true }, { corner(8) })
                local sc = new("UIScale", { Parent = b })
                b.MouseEnter:Connect(function() tw(b, 0.2, { BackgroundColor3 = Theme.Accent, TextColor3 = Theme.OnAccent }, SINE) end)
                b.MouseLeave:Connect(function() tw(b, 0.25, { BackgroundColor3 = Theme.Panel2, TextColor3 = Theme.Text }, SINE) end)
                b.MouseButton1Down:Connect(function() tw(sc, 0.08, { Scale = 0.9 }, SINE) end)
                b.MouseButton1Up:Connect(function() tw(sc, 0.35, { Scale = 1 }, BACK) end)
                b.InputBegan:Connect(function(i) if isPress(i) then Win.Ripple(b, i) end end)
                b.MouseButton1Click:Connect(function() sfx() touch() fire(t.Callback) end)
                return { Row = row, Button = b }
            end

            function mod:AddTextbox(t)
                addWord(t.Name or "")
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 })
                label(row, t.Name or "Textbox", nil, UDim2.new(1, -150, 1, 0), Enum.Font.GothamMedium, 13, B"Text")
                local back = new("Frame", { Parent = row, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(140, 28), BackgroundColor3 = B"Bg" }, { corner(9) })
                local bs = new("UIStroke", { Color = B"Accent", Transparency = 1, Thickness = 1.2, Parent = back })
                local box = new("TextBox", { Parent = back, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1,
                    PlaceholderText = t.Placeholder or "", PlaceholderColor3 = B"Sub", Text = t.Default or "", TextColor3 = B"Text", TextSize = 12, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left })
                box.Focused:Connect(function() tw(bs, 0.25, { Transparency = 0.4 }, SINE) end)
                box.FocusLost:Connect(function(enter) tw(bs, 0.3, { Transparency = 1 }, SINE) touch() fire(t.Callback, box.Text, enter) end)
                local api = {}
                function api:Set(v) box.Text = tostring(v) end
                function api:Get() return box.Text end
                api.Export = function() return box.Text end
                api.Import = function(v) if type(v) == "string" then box.Text = v fire(t.Callback, v, false) end end
                flag(t, api)
                return api
            end

            function mod:AddLabel(text, h)
                local l = label(sf, text, nil, UDim2.new(1, 0, 0, h or 30), Enum.Font.Gotham, 11, B"Sub", nil,
                    { LayoutOrder = order(), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None })
                return l
            end
            function mod:AddCustom(h)
                return new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1 })
            end

            function mod:AddKeybind(t)
                addWord(t.Name or "")
                local b = { Name = t.Name, Key = t.Default, Default = t.Default, Mode = t.Mode or "Press", Callback = t.Callback, State = false, Hud = t.Hud }
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 })
                label(row, t.Name or "Keybind", nil, UDim2.new(1, -200, 1, 0), Enum.Font.GothamMedium, 13, B"Text")
                local modeB = new("TextButton", { Parent = row, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -86, 0.5, 0), Size = UDim2.fromOffset(62, 24),
                    BackgroundColor3 = B"Panel2", Text = b.Mode, TextColor3 = B"Sub", Font = Enum.Font.GothamBold, TextSize = 10 }, { corner(8) })
                local MODES = { "Press", "Toggle", "Hold" }
                modeB.MouseButton1Click:Connect(function() sfx() b.Mode = MODES[(table.find(MODES, b.Mode) or 1) % 3 + 1] b.State = false setTxt(modeB, b.Mode) end)
                local kb = new("TextButton", { Parent = row, AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(78, 24),
                    BackgroundColor3 = B"Panel2", Text = "", TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 10 }, { corner(8) })
                local paint
                local rb = resetBtn(row, UDim2.new(1, -156, 0.5, 0), function()
                    sfx()
                    b.Key = b.Default
                    paint()
                    Win:RefreshHud()
                    if t.Changed then fire(t.Changed, b.Key) end
                end)
                paint = function()
                    kb.Text = b.Key and keyName(b.Key) or T("NONE")
                    rb.Visible = (b.Key ~= b.Default)
                end
                paint()
                kb.MouseButton1Click:Connect(function()
                    sfx() kb.Text = "..."
                    Lib._listen = function(k)
                        if k == Enum.KeyCode.Escape or k == Enum.KeyCode.Backspace then b.Key = nil else b.Key = k end
                        paint() Win:RefreshHud() if t.Changed then fire(t.Changed, b.Key) end
                    end
                end)
                b.Press = function(down)
                    if b.Mode == "Press" then if down then fire(b.Callback) end
                    elseif b.Mode == "Toggle" then if down then b.State = not b.State fire(b.Callback, b.State) Win:RefreshHud() end
                    else b.State = down fire(b.Callback, down) Win:RefreshHud() end
                end
                table.insert(Win.BindList, b)
                local api = { Bind = b }
                function api:Get() return b.Key end
                api.Export = function() return { Key = keyToName(b.Key), Mode = b.Mode } end
                api.Import = function(v)
                    if type(v) ~= "table" then return end
                    b.Key = v.Key and keyFromName(v.Key) or nil
                    if v.Mode and table.find(MODES, v.Mode) then b.Mode = v.Mode setTxt(modeB, v.Mode) end
                    paint() Win:RefreshHud()
                end
                flag(t, api)
                return api
            end

            function mod:AddColorPicker(t)
                addWord(t.Name or "")
                local col = t.Default or WHITE
                local hh, ss, vv = col:ToHSV()
                local OPEN_H = 26 + 8 + 100 + 10 + 14 + 4
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, ClipsDescendants = true })
                label(row, t.Name or "Color", UDim2.new(), UDim2.new(1, -110, 0, 26), Enum.Font.GothamMedium, 13, B"Text")
                local hexL = dyn(label(row, "#FFFFFF", UDim2.new(1, -112, 0, 0), UDim2.fromOffset(64, 26), Enum.Font.GothamBold, 11, B"Sub", Enum.TextXAlignment.Right))
                local sw = new("TextButton", { Parent = row, AnchorPoint = V2(1, 0), Position = UDim2.new(1, 0, 0, 3), Size = UDim2.fromOffset(40, 20), BackgroundColor3 = col }, { corner(7), new("UIStroke", { Color = WHITE, Transparency = 0.7, Thickness = 1 }) })
                local sv = new("Frame", { Parent = row, Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 100), BackgroundColor3 = Color3.fromHSV(hh, 1, 1), ClipsDescendants = true }, { corner(8) })
                new("Frame", { Parent = sv, Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, ZIndex = 2 }, { new("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
                new("Frame", { Parent = sv, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 3 }, { new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
                local svK = new("Frame", { Parent = sv, AnchorPoint = V2(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ZIndex = 4 }, { corner(6), new("UIStroke", { Color = WHITE, Thickness = 2 }) })
                local hue = new("Frame", { Parent = row, Position = UDim2.fromOffset(0, 144), Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = WHITE }, {
                    corner(7), new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(255, 0, 0)), ColorSequenceKeypoint.new(1 / 6, rgb(255, 255, 0)),
                        ColorSequenceKeypoint.new(2 / 6, rgb(0, 255, 0)), ColorSequenceKeypoint.new(3 / 6, rgb(0, 255, 255)), ColorSequenceKeypoint.new(4 / 6, rgb(0, 0, 255)),
                        ColorSequenceKeypoint.new(5 / 6, rgb(255, 0, 255)), ColorSequenceKeypoint.new(1, rgb(255, 0, 0)) }) }) })
                local hK = new("Frame", { Parent = hue, AnchorPoint = V2(0.5, 0.5), Size = UDim2.fromOffset(8, 20), BackgroundColor3 = WHITE, ZIndex = 3 }, { corner(4), new("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.3 }) })
                local lastE, trailing = 0, false
                local function emit()
                    local now = os.clock()
                    if now - lastE >= 0.06 then lastE = now fire(t.Callback, col)
                    elseif not trailing then trailing = true task.delay(0.06, function() trailing = false lastE = os.clock() fire(t.Callback, col) end) end
                end
                local function refresh(silent)
                    col = Color3.fromHSV(hh, ss, vv)
                    sw.BackgroundColor3 = col
                    sv.BackgroundColor3 = Color3.fromHSV(hh, 1, 1)
                    svK.Position = UDim2.fromScale(ss, 1 - vv)
                    hK.Position = UDim2.fromScale(hh, 0.5)
                    hexL.Text = string.format("#%02X%02X%02X", math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5))
                    if not silent then emit() end
                end
                refresh(true)
                local function bindDrag(hit, onMove)
                    local dn = false
                    hit.InputBegan:Connect(function(i) if isPress(i) then dn = true onMove(i.Position) end end)
                    keep(UIS.InputChanged:Connect(function(i) if dn and isMove(i) then onMove(i.Position) end end))
                    keep(UIS.InputEnded:Connect(function(i) if dn and isPress(i) then dn = false end end))
                end
                local svHit = new("TextButton", { Parent = row, Position = sv.Position, Size = sv.Size, BackgroundTransparency = 1, ZIndex = 6 })
                local hueHit = new("TextButton", { Parent = row, Position = UDim2.fromOffset(0, 138), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, ZIndex = 6 })
                bindDrag(svHit, function(p)
                    ss = clamp((p.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
                    vv = 1 - clamp((p.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
                    refresh(false)
                end)
                bindDrag(hueHit, function(p) hh = clamp((p.X - hue.AbsolutePosition.X) / math.max(hue.AbsoluteSize.X, 1), 0, 0.999) refresh(false) end)
                local open = false
                sw.MouseButton1Click:Connect(function() sfx() open = not open tw(row, 0.5, { Size = UDim2.new(1, 0, 0, open and OPEN_H or 26) }, QUINT) end)
                local api = {}
                function api:Set(c, silent) hh, ss, vv = c:ToHSV() refresh(silent) end
                function api:SetSilent(c) hh, ss, vv = c:ToHSV() refresh(true) end
                function api:Get() return col end
                api.Export = function() return { math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5) } end
                api.Import = function(v) if type(v) == "table" and #v == 3 then api:Set(rgb(v[1], v[2], v[3])) end end
                flag(t, api)
                return api
            end

            -- список с поиском / multi-выбором / кнопками
            function mod:AddSelection(t)
                t = t or {}
                addWord(t.Name or "")
                local isMulti = t.Multi == true
                local row = new("Frame", { Parent = sf, LayoutOrder = order(), Size = UDim2.new(1, 0, 0, t.Height or 240), BackgroundColor3 = B"Bg" }, { corner(12), stk() })
                label(row, t.Name or "Selection", UDim2.fromOffset(12, 6), UDim2.new(1, -80, 0, 16), Enum.Font.GothamBold, 11, B"Accent")
                local badge = dyn(label(row, "0", UDim2.new(1, -70, 0, 5), UDim2.fromOffset(58, 18), Enum.Font.GothamBold, 10, B"Sub", Enum.TextXAlignment.Right,
                    { TextTruncate = Enum.TextTruncate.None }))
                local search = new("TextBox", { Parent = row, Position = UDim2.fromOffset(10, 26), Size = UDim2.new(1, -20, 0, 26), BackgroundColor3 = B"Panel",
                    PlaceholderText = t.SearchPlaceholder or "Search...", PlaceholderColor3 = B"Sub", Text = "", TextColor3 = B"Text", TextSize = 12,
                    ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, { corner(8), pad(0, 0, 8, 8) })
                local sStroke = new("UIStroke", { Color = B"Accent", Transparency = 1, Thickness = 1.2, Parent = search })
                search.Focused:Connect(function() tw(sStroke, 0.2, { Transparency = 0.3 }, SINE) end)
                search.FocusLost:Connect(function() tw(sStroke, 0.3, { Transparency = 1 }, SINE) end)
                local list = new("ScrollingFrame", { Parent = row, Position = UDim2.fromOffset(10, 60), Size = UDim2.new(1, -20, 1, -70), BackgroundTransparency = 1,
                    ScrollBarThickness = 3, ScrollBarImageColor3 = B"Accent", CanvasSize = UDim2.new(), AutomaticCanvasSize = AUTO_Y,
                    ScrollingDirection = Enum.ScrollingDirection.Y }, { new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })
                local empty = label(row, t.EmptyText or "No items", UDim2.fromOffset(10, 60), UDim2.new(1, -20, 1, -70), Enum.Font.GothamMedium, 12, B"Sub",
                    Enum.TextXAlignment.Center, { TextTruncate = Enum.TextTruncate.None, TextWrapped = true })
                local btnBar = new("Frame", { Parent = row, Position = UDim2.new(0, 10, 1, -34), Size = UDim2.new(1, -20, 0, 26), BackgroundTransparency = 1, Visible = false },
                    { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }) })

                local items, itemRows, selectedSet = {}, {}, {}
                local api = {}
                local function isSel(n) return selectedSet[n] == true end
                local function paintItem(n)
                    local r = itemRows[n]
                    if not r or not r.Parent then return end
                    local on = isSel(n)
                    r.BackgroundColor3 = on and Theme.Accent or Theme.Panel2
                    r.TextColor3 = on and Theme.OnAccent or Theme.Sub
                end
                local function paintAll() for n in pairs(itemRows) do paintItem(n) end end
                local function updateBadge()
                    local total, sel = 0, 0
                    for _ in pairs(itemRows) do total += 1 end
                    for _ in pairs(selectedSet) do sel += 1 end
                    badge.Text = sel > 0 and string.format("%d/%d", sel, total) or tostring(total)
                end
                local function updateEmpty()
                    local any = false
                    for _, r in pairs(itemRows) do if r.Visible then any = true break end end
                    empty.Visible = not any
                end
                local function fireSelect(name)
                    if not t.OnSelect then return end
                    if isMulti then fire(t.OnSelect, name, name and items[name] or nil, api:GetSelected())
                    else fire(t.OnSelect, name, name and items[name] or nil) end
                end
                local function selectItem(name, toggleIt)
                    if not name then selectedSet = {} paintAll() updateBadge() fireSelect(nil) return end
                    if not itemRows[name] then return end
                    sfx()
                    if toggleIt and isMulti then selectedSet[name] = isSel(name) and nil or true
                    else selectedSet = { [name] = true } end
                    paintAll() updateBadge() touch() fireSelect(name)
                end
                local function render()
                    local q = (search.Text or ""):lower()
                    for n, r in pairs(itemRows) do r.Visible = q == "" or n:lower():find(q, 1, true) ~= nil end
                    updateEmpty()
                end
                search:GetPropertyChangedSignal("Text"):Connect(render)
                search.FocusLost:Connect(function(enter)
                    if not enter or search.Text == "" then return end
                    for _, r in ipairs(list:GetChildren()) do
                        if r:IsA("TextButton") and r.Visible then
                            local n = r:GetAttribute("SelName")
                            if n then selectItem(n, false) end
                            return
                        end
                    end
                end)

                function api:Add(name, meta)
                    if not name then return end
                    name = tostring(name)
                    if itemRows[name] then return end
                    items[name] = meta or true
                    local r = new("TextButton", { Parent = list, Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = Theme.Panel2, Text = name, TextColor3 = Theme.Sub,
                        Font = Enum.Font.GothamMedium, TextSize = 11, ClipsDescendants = true, TextTruncate = Enum.TextTruncate.AtEnd,
                        TextXAlignment = Enum.TextXAlignment.Left }, { corner(6), pad(0, 0, 8, 8) })
                    dyn(r)
                    r:SetAttribute("SelName", name)
                    r.MouseButton1Click:Connect(function() selectItem(name, true) end)
                    r.MouseButton2Click:Connect(function()
                        if isSel(name) then selectedSet[name] = nil paintAll() updateBadge() fireSelect(api:GetSelected()) end
                    end)
                    r.MouseEnter:Connect(function() if not isSel(name) then tw(r, 0.2, { BackgroundColor3 = Theme.Panel2:Lerp(Theme.Accent, 0.2) }, SINE) end end)
                    r.MouseLeave:Connect(function() if not isSel(name) then tw(r, 0.2, { BackgroundColor3 = Theme.Panel2 }, SINE) end end)
                    itemRows[name] = r
                    local q = (search.Text or ""):lower()
                    r.Visible = q == "" or name:lower():find(q, 1, true) ~= nil
                    updateEmpty() updateBadge()
                end
                function api:AddMany(names) if type(names) == "table" then for _, n in ipairs(names) do api:Add(n) end end end
                function api:Remove(name)
                    local r = itemRows[name]
                    if not r then return end
                    itemRows[name], items[name], selectedSet[name] = nil, nil, nil
                    r:Destroy()
                    updateEmpty() updateBadge()
                end
                function api:Clear()
                    for _, r in pairs(itemRows) do r:Destroy() end
                    items, itemRows, selectedSet = {}, {}, {}
                    updateEmpty() updateBadge()
                end
                function api:GetItems()
                    local out = {}
                    for n in pairs(itemRows) do out[#out + 1] = n end
                    table.sort(out)
                    return out
                end
                function api:Count() local n = 0 for _ in pairs(itemRows) do n += 1 end return n end
                function api:GetSelected()
                    if isMulti then
                        local out = {}
                        for n in pairs(selectedSet) do out[#out + 1] = n end
                        table.sort(out)
                        return out
                    end
                    for n in pairs(selectedSet) do return n, items[n] end
                    return nil
                end
                function api:SetSelected(v)
                    if isMulti then
                        selectedSet = {}
                        if type(v) == "table" then for _, n in ipairs(v) do if itemRows[n] then selectedSet[n] = true end end end
                    else
                        selectedSet = (type(v) == "string" and itemRows[v]) and { [v] = true } or {}
                    end
                    paintAll() updateBadge() fireSelect(api:GetSelected())
                end
                function api:Refresh() render() end
                function api:AddButton(text, cb)
                    local b = new("TextButton", { Parent = btnBar, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = B"Panel2", Text = text or "OK",
                        TextColor3 = B"Text", Font = Enum.Font.GothamBold, TextSize = 10 }, { corner(6) })
                    b.MouseButton1Click:Connect(function()
                        sfx()
                        local name, meta
                        if isMulti then name = api:GetSelected() else name, meta = api:GetSelected() end
                        if name then fire(cb, name, meta) end
                    end)
                    local btns = {}
                    for _, c in ipairs(btnBar:GetChildren()) do if c:IsA("TextButton") then btns[#btns + 1] = c end end
                    local n = #btns
                    local gap = 6 * math.max(0, n - 1)
                    for _, c in ipairs(btns) do c.Size = UDim2.new(1 / n, -(gap / n), 1, 0) end
                    btnBar.Visible = n > 0
                    list.Size = UDim2.new(1, -20, 1, -106)
                    empty.Size = list.Size
                    return b
                end
                api.Export = function()
                    if isMulti then return { Multi = true, Selected = api:GetSelected() } end
                    return { Multi = false, Selected = api:GetSelected() }
                end
                api.Import = function(v)
                    if type(v) ~= "table" then return end
                    if v.Multi then api:SetSelected(type(v.Selected) == "table" and v.Selected or {})
                    else api:SetSelected(type(v.Selected) == "string" and v.Selected or nil) end
                end
                onTheme(paintAll)
                if type(t.Items) == "table" then api:AddMany(t.Items) end
                if type(t.Buttons) == "table" then
                    for _, bt in ipairs(t.Buttons) do
                        if type(bt) == "table" then api:AddButton(bt.Name or bt.Text or "OK", bt.Callback) end
                    end
                end
                if t.Default ~= nil then api:SetSelected(t.Default) end
                updateEmpty() updateBadge()
                flag(t, api)
                return api
            end

            if o.Flag and not mod.Static then
                local api = {}
                api.Export = function() return { State = mod.State, Key = keyToName(mod.Key), Mode = mod.Mode } end
                api.Import = function(v)
                    if type(v) ~= "table" then return end
                    mod.Key = v.Key and keyFromName(v.Key) or nil
                    if v.Mode == "Hold" or v.Mode == "Toggle" then mod.Mode = v.Mode if mod.ModeBtn then setTxt(mod.ModeBtn, v.Mode) end end
                    if mod.PaintPill then mod.PaintPill(false) end
                    if mod.KeyRow then mod.KeyRow(mod.Key) end
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

        table.insert(Win.Categories, cat)
        table.insert(grp.cats, cat)
        cat.IconId = icon
        return cat
    end

    ------------------------------------------------------------------
    --  WINDOW API
    ------------------------------------------------------------------
    function Win:SetGlass(on)
        Win.Glass = on and true or false
        for _, g in ipairs(glassObjs) do tw(g[1], 0.4, { BackgroundTransparency = glassFinal(g) }, SINE) end
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
        if not silent then waves() end
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
    function Win:SetBorderSpin(v) Win.BorderSpin = v Win.RingSpin[2] = v end
    function Win:SetBorderPulse(on)
        Win.BorderPulse = on and true or false
        if not on then mainStroke.Transparency = Win._glowT end
    end
    function Win:SetParticleAmount(v) Win.ParticleWait = 0.9 / math.max(v, 0.1) end
    function Win:SetShadows(on) Win.Shadows = on and true or false applyStatics() end
    function Win:SetCardShadows(on) Win.CardShadows = on and true or false applyStatics() end
    function Win:SetShadowIntensity(v) Win.ShadowMul = v applyStatics() end
    function Win:SetShadowBehind(on)
        Win.ShadowBehind = on and true or false
        for _, e in ipairs(statics) do if e.Shadow then pcall(function() e.Shadow.ShowBehindParent = Win.ShadowBehind end) end end
        for _, e in ipairs(shadowList) do if e.Shadow then pcall(function() e.Shadow.ShowBehindParent = Win.ShadowBehind end) end end
    end
    function Win:SetFreeMouse(on) Win.FreeMouse = on and true or false end
    function Win:SetRipples(on) Win.Ripples = on and true or false end
    function Win:SetBlur(on, size) Win.BlurOn = on Win.BlurSize = size or Win.BlurSize if Win.Open then setBlur(on and Win.BlurSize or 0) end end
    function Win:SetDim(v) Win.DimAmt = v if Win.Open then tw(dim, 0.3, { BackgroundTransparency = 1 - v }, SINE) end end
    function Win:SetSpeed(v) Lib.Speed = v end
    function Win:SetLockPos(v) Win.LockPos = v end
    function Win:ResetPos() tw(root, 0.6, { Position = UDim2.fromScale(0.5, 0.5) }, QUINT) end
    function Win:SetMenuKey(k) Win.ToggleKey = k end
    function Win:SetSounds(on, vol) Lib.SoundsOn = on Lib.SoundVol = vol or Lib.SoundVol end
    function Win:SetParticles(on) Win.Particles = on end

    function Win:Show()
        if Win.Open then return end
        Win.Open = true
        root.Visible = true
        openBtn.Visible = false
        scale.Scale = fit() * 0.8
        tw(scale, 0.7, { Scale = fit() }, BACK)
        tw(dim, 0.4, { BackgroundTransparency = 1 - Win.DimAmt }, SINE)
        if Win.BlurOn then setBlur(Win.BlurSize) end
        waves()
        if Win.Current then layout() end
    end
    function Win:Hide()
        if not Win.Open then return end
        Win.Open = false
        tw(scale, 0.35, { Scale = fit() * 0.8 }, QUINT, IN)
        tw(dim, 0.3, { BackgroundTransparency = 1 }, SINE)
        setBlur(0)
        task.delay(0.35, function()
            if not Win.Open then
                root.Visible = false
                openBtn.Visible = true
                openBtn.Size = UDim2.fromOffset(0, 0)
                tw(openBtn, 0.5, { Size = UDim2.fromOffset(48, 48) }, BACK)
            end
        end)
    end
    function Win:Toggle() if Win.Open then Win:Hide() else Win:Show() end end
    openBtn.MouseButton1Click:Connect(function() Win:Show() end)
    hideBtn.MouseButton1Click:Connect(function() sfx() Win:Hide() Win:Notify("Menu hidden", "Press " .. keyName(Win.ToggleKey) .. " or the round button to open", 3) end)
    closeBtn.MouseButton1Click:Connect(function() sfx() Win:Confirm("Unload hub?", "This fully closes FEMBOYSENSE HUB and removes every effect.", function() Win:Destroy() end) end)
    gearBtn.MouseButton1Click:Connect(function() sfx() if Win.SettingsCat then searchBox.Text = "" Win.Query = "" Win:Select(Win.SettingsCat) end end)
    chatBtn.MouseButton1Click:Connect(function() sfx() local c for _, x in ipairs(Win.Categories) do if x.Name == "Chat" then c = x end end if c then searchBox.Text = "" Win.Query = "" Win:Select(c) end end)
    local function setLangBtn() langBtn.Text = Lib.Lang end
    langBtn.MouseButton1Click:Connect(function()
        sfx()
        Lib:SetLang(Lib.Lang == "EN" and "RU" or "EN")
        setLangBtn()
        if Win.Query ~= "" then layout() else
            setTxt(pageTitle, Win.Current.Name) setTxt(pageSub, Win.Current.Sub) end
        Win:RefreshHud()
        if Lib.Flags.Language then Lib.Flags.Language:Set(Lib.Lang == "RU" and "Русский" or "English", true) end
    end)
    function Win:SetLanguage(l) Lib:SetLang(l) setLangBtn() if Win.Current then setTxt(pageTitle, Win.Current.Name) setTxt(pageSub, Win.Current.Sub) end Win:RefreshHud() end

    -- избранное
    Lib.Flags._Favs = {
        Export = function() local t = {} for n in pairs(Win.Favs) do t[#t + 1] = n end return t end,
        Import = function(v)
            if type(v) ~= "table" then return end
            Win.Favs = {}
            for _, n in ipairs(v) do Win.Favs[n] = true end
            for _, m in ipairs(Win.Modules) do if m.SetFav then m:SetFav(Win.Favs[m.Name] == true) end end
        end,
    }
    -- тема в конфиге
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
    -- слайд-шоу фона в конфиге
    Lib.Flags.BgSlideImages = {
        Export = function() return Bg.Images end,
        Import = function(v)
            if type(v) ~= "table" then return end
            Bg.Images = {}
            for _, id in ipairs(v) do if type(id) == "string" then table.insert(Bg.Images, id) end end
            Bg.Index = 1
            if Win.RefreshSlideInfo then Win.RefreshSlideInfo() end
            Win:ApplyBackground()
        end,
    }

    --// КОНФИГИ
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
            if ok then for _, f in ipairs(files) do local n = tostring(f):match("([^/\\]+)%.json$") if n and n ~= "chat_settings" and n ~= "chat_cache" then out[#out + 1] = n end end end
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
        for _, f in ipairs(Win.unloaders) do pcall(f) end
        if Win.AutoSave then pcall(function() Win:SaveConfig(Win.AutoSaveName) end) end
        pcall(function() modalBtn.Modal = false end)
        if blur then pcall(function() blur:Destroy() end) end
        tw(scale, 0.45, { Scale = 0 }, QUINT, IN)
        tw(dim, 0.4, { BackgroundTransparency = 1 }, SINE)
        task.delay(0.5, function()
            for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
            conns, reg, hooks, grads, spinners, shimmers = {}, {}, {}, {}, {}, {}
            shadowList, statics = {}, {}
            if sfxSound then sfxSound:Destroy() sfxSound = nil end
            if notifSound then notifSound:Destroy() notifSound = nil end
            Lib._gui = nil
            gui:Destroy()
        end)
        genv.FemboysenseUnload = nil
    end
    genv.FemboysenseUnload = function() Win:Destroy() end

    ------------------------------------------------------------------
    --  BUILT-IN SETTINGS + CURSOR + BACKGROUND + CONFIGS
    ------------------------------------------------------------------
    function Win:Finish()
        if Win._finished then return end
        Win._finished = true

        Win:AddGroup("SYSTEM")
        local st = Win:AddCategory("Settings", Icons.Settings, "Theme, window, overlays and notifications.")
        local curCat = Win:AddCategory("Cursor", Icons.Cursor or Icons.Visuals or Icons.Settings, "Custom cursor, styles, trail and effects.")
        local bgCat = Win:AddCategory("Background", Icons.Background or Icons.Visuals or Icons.Settings, "Custom background, slideshow, effects.")
        local cf = Win:AddCategory("Configs", Icons.Configs, "Save, load and share your setups.")
        Win.SettingsCat = st

        -- сетка тем
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
            local function paint()
                local on = Win.ThemeDef == def
                tw(s, 0.3, { Color = on and Theme.Accent or Theme.Stroke, Transparency = on and 0.05 or Theme.StrokeT, Thickness = on and 1.8 or 1 }, SINE)
            end
            onTheme(paint)
            b.MouseEnter:Connect(function() tw(sc, 0.3, { Scale = 1.05 }, BACK) end)
            b.MouseLeave:Connect(function() tw(sc, 0.3, { Scale = 1 }, SINE) end)
            b.MouseButton1Click:Connect(function() sfx() Win:SetTheme(def) end)
        end
        st.OnShow = function()
            for i, sc in ipairs(themeScales) do sc.Scale = 0.8 task.delay((i - 1) * 0.05, function() tw(sc, 0.6, { Scale = 1 }, BACK) end) end
        end

        local th = st:AddModule({ Name = "Theme", Icon = Icons.Visuals, Info = "Colors of the interface", Static = true })
        th:AddColorPicker({ Name = "Accent color", Default = Theme.Accent, Flag = "AccentColor", Callback = function(c) Win:SetAccent(c) end })
        th:AddColorPicker({ Name = "Accent gradient 2", Default = Theme.Accent2, Flag = "AccentColor2", Callback = function(c) Win:SetAccent2(c) end })
        th:AddButton({ Name = "Reset accent 2 (auto)", ButtonText = "AUTO", Callback = function()
            Win:ResetAccent2()
            Win:Notify("Theme", "Accent 2 set to auto", 2, "ok")
        end })
        th:AddTextbox({ Name = "Accent hex", Placeholder = "#FF283C", Callback = function(t)
            local hex = tostring(t):gsub("#", "")
            if #hex == 6 and tonumber(hex, 16) then
                local n = tonumber(hex, 16)
                Lib.Flags.AccentColor:Set(rgb(n // 65536, (n // 256) % 256, n % 256))
            elseif t ~= "" and not Win.Loading then
                Win:Notify("Accent", "Use hex like #FF283C", 2, "warn")
            end
        end })
        th:AddButton({ Name = "Random accent", ButtonText = "ROLL", Callback = function()
            Lib.Flags.AccentColor:Set(Color3.fromHSV(math.random(), 0.75 + math.random() * 0.25, 1))
        end })
        th:AddOptions({ Name = "Material", Options = { "Solid", "Glass" }, Default = "Glass", Flag = "Material", Callback = function(v) Win:SetGlass(v == "Glass") end })
        th:AddSlider({ Name = "Interface glow", Min = 0, Max = 100, Default = 55, Suffix = "%", Flag = "UIGlow", Callback = function(v) Win:SetGlow(v / 100) end })
        th:AddSlider({ Name = "Window opacity", Min = 30, Max = 100, Default = 100, Suffix = "%", Flag = "UIOpacity", Callback = function(v) Win:SetOpacity(v / 100) end })
        th:AddToggle({ Name = "Animated shadows", Default = true, Flag = "Shadows", Callback = function(v) Win:SetShadows(v) end })
        th:AddToggle({ Name = "Card shadows", Default = true, Flag = "CardShadows", Callback = function(v) Win:SetCardShadows(v) end })
        th:AddToggle({ Name = "Shadow through glass", Flag = "ShadowBehind", Callback = function(v) Win:SetShadowBehind(v) end })
        th:AddSlider({ Name = "Shadow intensity", Min = 0.2, Max = 3, Step = 0.05, Default = 1, Suffix = "x", Flag = "ShadowMul", Callback = function(v) Win:SetShadowIntensity(v) end })
        th:AddToggle({ Name = "Floating particles", Flag = "UIParticles", Callback = function(v) Win:SetParticles(v) end })
        th:AddSlider({ Name = "Particle amount", Min = 1, Max = 10, Default = 4, Flag = "ParticleAmount", Callback = function(v) Win:SetParticleAmount(v) end })

        local wn = st:AddModule({ Name = "Window", Icon = Icons.Settings, Info = "Size, position and effects", Static = true })
        wn:AddKeybind({ Name = "Toggle menu key", Default = Win.ToggleKey, Mode = "Press", Flag = "MenuKey",
            Callback = function() end, Changed = function(k) if k then Win:SetMenuKey(k) end end })
        wn:AddSlider({ Name = "Menu size", Min = 60, Max = 130, Default = 100, Suffix = "%", Flag = "UIScale", Callback = function(v) Win:SetScale(v / 100) end })
        wn:AddSlider({ Name = "Animation speed", Min = 0.4, Max = 2.5, Step = 0.05, Default = 1, Suffix = "x", Flag = "AnimSpeed", Callback = function(v) Win:SetSpeed(v) end })
        wn:AddToggle({ Name = "Background blur", Flag = "UIBlur", Callback = function(v) Win:SetBlur(v) end })
        wn:AddSlider({ Name = "Blur amount", Min = 2, Max = 40, Default = 14, Flag = "UIBlurAmt", Callback = function(v) Win.BlurSize = v if Win.BlurOn and Win.Open then setBlur(v) end end })
        wn:AddSlider({ Name = "Background dim", Min = 0, Max = 90, Default = 35, Suffix = "%", Flag = "UIDim", Callback = function(v) Win:SetDim(v / 100) end })
        wn:AddToggle({ Name = "Free mouse in menu", Default = true, Flag = "FreeMouse", Callback = function(v) Win:SetFreeMouse(v) end })
        wn:AddToggle({ Name = "Click ripple", Default = true, Flag = "Ripples", Callback = function(v) Win:SetRipples(v) end })
        wn:AddToggle({ Name = "Lock window position", Flag = "UILock", Callback = function(v) Win:SetLockPos(v) end })
        wn:AddButton({ Name = "Reset window position", ButtonText = "CENTER", Callback = function() Win:ResetPos() end })
        wn:AddOptions({ Name = "Language", Options = { "English", "Русский" }, Default = "English", Flag = "Language",
            Callback = function(v) Win:SetLanguage(v == "Русский" and "RU" or "EN") end })

        local bd = st:AddModule({ Name = "Border & Effects", Icon = Icons.Visuals, Info = "Window border", Static = true })
        bd:AddSlider({ Name = "Border thickness", Min = 0, Max = 6, Step = 0.5, Default = 2, Flag = "BorderThick", Callback = function(v) Win:SetBorderThickness(v) end })
        bd:AddToggle({ Name = "Border pulse", Flag = "BorderPulse", Callback = function(v) Win:SetBorderPulse(v) end })
        bd:AddSlider({ Name = "Border spin speed", Min = -300, Max = 300, Step = 10, Default = 60, Flag = "BorderSpin", Callback = function(v) Win:SetBorderSpin(v) end })

        local ov = st:AddModule({ Name = "Overlays", Icon = Icons.Visuals, Info = "Watermark, active binds, streamer mode", Static = true })
        ov:AddToggle({ Name = "Watermark", Flag = "Watermark", Callback = function(v) Win:SetWatermark(v) end })
        ov:AddOptions({ Name = "Watermark position", Options = { "Top Left", "Top Right", "Bottom Left", "Bottom Right" }, Default = "Top Left", Flag = "WMPos", Callback = function(v) Win:SetWatermarkPos(v) end })
        ov:AddSlider({ Name = "Overlay opacity", Min = 30, Max = 100, Default = 92, Suffix = "%", Flag = "WMAlpha", Callback = function(v) Win:SetWatermarkOpacity(v / 100) end })
        ov:AddToggle({ Name = "Colored FPS / ping", Default = true, Flag = "WMColors", Callback = function(v) Win.WMColors = v end })
        ov:AddToggle({ Name = "Show FPS", Default = true, Flag = "WMFps", Callback = function(v) Win:SetWatermarkChip("Fps", v) end })
        ov:AddToggle({ Name = "Show ping", Default = true, Flag = "WMPing", Callback = function(v) Win:SetWatermarkChip("Ping", v) end })
        ov:AddToggle({ Name = "Show time", Default = true, Flag = "WMTime", Callback = function(v) Win:SetWatermarkChip("Time", v) end })
        ov:AddToggle({ Name = "Show player name", Flag = "WMUser", Callback = function(v) Win:SetWatermarkChip("User", v) end })
        ov:AddToggle({ Name = "24-hour clock", Default = true, Flag = "Time24", Callback = function(v) Win.Time24 = v end })
        ov:AddToggle({ Name = "Active binds list", Flag = "BindsHud", Callback = function(v) Win:SetBindsHud(v) end })
        ov:AddToggle({ Name = "Streamer mode", Flag = "Streamer", Callback = function(v) Win:SetStreamer(v) end })

        local nt = st:AddModule({ Name = "Notifications", Icon = Icons.Settings, Info = "Popups and sounds", Static = true })
        nt:AddToggle({ Name = "Notifications", Default = true, Flag = "Notifs", Callback = function(v) Win.NotifsOn = v end })
        nt:AddSlider({ Name = "Notification time", Min = 1, Max = 10, Step = 0.5, Default = 3, Suffix = "s", Flag = "NotifTime", Callback = function(v) Win.NotifTime = v end })
        nt:AddOptions({ Name = "Position", Options = { "Top Right", "Top Left", "Bottom Right", "Bottom Left" }, Default = "Top Right", Flag = "NotifPos", Callback = function(v) Win:SetNotifPos(v) end })
        nt:AddToggle({ Name = "Notification sound", Flag = "NotifSound", Callback = function(v) Win.NotifSoundOn = v end })
        nt:AddButton({ Name = "Test notification", ButtonText = "TEST", Callback = function() Win:Notify("FEMBOYSENSE HUB", "This is a test notification", 3, "ok", true) end })
        nt:AddToggle({ Name = "UI sounds", Flag = "UISounds", Callback = function(v) Win:SetSounds(v) end })
        nt:AddSlider({ Name = "UI volume", Min = 0, Max = 100, Default = 50, Suffix = "%", Flag = "UIVol", Callback = function(v) Lib.SoundVol = v / 100 end })

        --------------------------------------------------------------
        --  CUSTOM CURSOR
        --------------------------------------------------------------
        local Cursor = {
            Enabled = false, Style = "Arrow", Size = 1, Mode = "Theme", Custom = rgb(255, 255, 255),
            RainbowSpeed = 0.4, Alpha = 1, Outline = true, Glow = false,
            HideSystem = true, OnlyMenu = false, Smooth = 0, Pulse = false, Spin = false, SpinSpeed = 120,
            Click = true, Shrink = true, Hover = true,
            Trail = false, TrailLen = 12, TrailSize = 1, Dirty = true,
        }
        Win.Cursor = Cursor
        local CursorGui = new("ScreenGui", { Name = "FemboysenseCursor", ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 10001, AutoLocalize = false, Parent = guiParent() })
        local CShape = new("Frame", { Parent = CursorGui, AnchorPoint = V2(0.5, 0.5), Size = UDim2.new(), BackgroundTransparency = 1, ZIndex = 5, Visible = false })
        local CScale = new("UIScale", { Parent = CShape })
        local Trail = {}
        for i = 1, 24 do
            Trail[i] = { f = new("Frame", { Parent = CursorGui, AnchorPoint = V2(0.5, 0.5), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = WHITE, Visible = false, ZIndex = 4 }, { corner(8) }), x = 0, y = 0 }
        end
        local cParts = {}
        local function cReg(inst, kind, mul) cParts[#cParts + 1] = { inst, kind, mul or 1 } return inst end
        local HALF = V2(0.5, 0.5)
        local function disc(sz, x, y, kind, mul, z)
            return cReg(new("Frame", { Parent = CShape, AnchorPoint = HALF, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = WHITE, ZIndex = z or 3 }, { corner(sz) }), kind, mul)
        end
        local function ringC(sz, x, y, th, kind, z, round)
            local f = new("Frame", { Parent = CShape, AnchorPoint = HALF, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(sz, sz), BackgroundTransparency = 1, ZIndex = z or 3 }, { corner(round or sz) })
            local s = plainStroke(WHITE, th)
            s.Parent = f
            cReg(s, kind)
            return f
        end
        local function barC(w, h, x, y, rot, kind, z)
            return cReg(new("Frame", { Parent = CShape, AnchorPoint = HALF, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), Rotation = rot or 0, BackgroundColor3 = WHITE, ZIndex = z or 3 }, { corner(1) }), kind)
        end
        local STYLES = {}
        STYLES.Arrow = function()
            disc(34, 6, 9, "glow", 0.10, 1)
            disc(54, 6, 9, "glow", 0.05, 1)
            cReg(new("Frame", { Parent = CShape, Position = UDim2.fromOffset(-1, -1), Size = UDim2.fromOffset(4, 1), ZIndex = 2 }), "outline")
            for i = 0, 17 do
                local w = math.floor(i * 0.65) + 2
                cReg(new("Frame", { Parent = CShape, Position = UDim2.fromOffset(-1, i), Size = UDim2.fromOffset(w + 2, 1), ZIndex = 2 }), "outline")
                cReg(new("Frame", { Parent = CShape, Position = UDim2.fromOffset(0, i), Size = UDim2.fromOffset(w, 1), ZIndex = 3 }), "fill")
            end
            cReg(new("Frame", { Parent = CShape, Position = UDim2.fromOffset(-1, 18), Size = UDim2.fromOffset(15, 1), ZIndex = 2 }), "outline")
        end
        STYLES.Dot = function() disc(30, 0, 0, "glow", 0.10, 1) disc(11, 0, 0, "outline", 1, 2) disc(8, 0, 0, "fill", 1, 3) end
        STYLES.Ring = function() disc(38, 0, 0, "glow", 0.10, 1) ringC(24, 0, 0, 1.5, "ostroke", 2) ringC(20, 0, 0, 2, "stroke", 3) disc(3, 0, 0, "fill", 1, 3) end
        STYLES["Dual Ring"] = function()
            disc(44, 0, 0, "glow", 0.08, 1)
            ringC(32, 0, 0, 1.5, "ostroke", 2) ringC(28, 0, 0, 2.2, "stroke", 3)
            ringC(18, 0, 0, 1.5, "ostroke", 2) ringC(14, 0, 0, 2, "stroke", 3)
        end
        STYLES.Cross = function()
            disc(40, 0, 0, "glow", 0.08, 1)
            barC(21, 5, 0, 0, 45, "outline", 2) barC(21, 5, 0, 0, -45, "outline", 2)
            barC(19, 3, 0, 0, 45, "fill", 3) barC(19, 3, 0, 0, -45, "fill", 3)
        end
        STYLES.Plus = function()
            disc(40, 0, 0, "glow", 0.08, 1)
            barC(4, 10, 0, -8, 0, "outline", 2) barC(4, 10, 0, 8, 0, "outline", 2)
            barC(10, 4, -8, 0, 0, "outline", 2) barC(10, 4, 8, 0, 0, "outline", 2)
            barC(2, 8, 0, -8, 0, "fill", 3) barC(2, 8, 0, 8, 0, "fill", 3)
            barC(8, 2, -8, 0, 0, "fill", 3) barC(8, 2, 8, 0, 0, "fill", 3)
            disc(2, 0, 0, "fill", 1, 3)
        end
        STYLES.Diamond = function() disc(40, 0, 0, "glow", 0.08, 1) barC(16, 16, 0, 0, 45, "outline", 2) barC(12, 12, 0, 0, 45, "fill", 3) end
        STYLES.Square = function()
            disc(40, 0, 0, "glow", 0.08, 1)
            ringC(21, 0, 0, 1.5, "ostroke", 2, 3) ringC(17, 0, 0, 2, "stroke", 3, 2)
            disc(3, 0, 0, "fill", 1, 3)
        end
        STYLES.Orb = function()
            disc(46, 0, 0, "glow", 0.07, 1)
            disc(28, 0, 0, "fill", 0.22, 3) disc(20, 0, 0, "fill", 0.40, 3) disc(13, 0, 0, "fill", 0.65, 3)
            disc(7, 0, 0, "outline", 1, 3) disc(5, 0, 0, "fill", 1, 4)
        end
        local STYLE_LIST = { "Arrow", "Dot", "Ring", "Dual Ring", "Cross", "Plus", "Diamond", "Square", "Orb" }

        local function cursorColor()
            if Cursor.Mode == "Rainbow" then return Color3.fromHSV((os.clock() * Cursor.RainbowSpeed) % 1, 0.85, 1)
            elseif Cursor.Mode == "Custom" then return Cursor.Custom
            elseif Cursor.Mode == "White" then return WHITE end
            return Theme.Accent
        end
        local BLACK = Color3.new(0, 0, 0)
        local function applyLook()
            local col = cursorColor()
            for _, p in ipairs(cParts) do
                local inst, kind, mul = p[1], p[2], p[3]
                if kind == "fill" then inst.BackgroundColor3 = col inst.BackgroundTransparency = 1 - Cursor.Alpha * mul
                elseif kind == "stroke" then inst.Color = col inst.Transparency = 1 - Cursor.Alpha * mul
                elseif kind == "outline" then inst.BackgroundColor3 = BLACK inst.BackgroundTransparency = Cursor.Outline and (1 - Cursor.Alpha * 0.9) or 1
                elseif kind == "ostroke" then inst.Color = BLACK inst.Transparency = Cursor.Outline and (1 - Cursor.Alpha * 0.8) or 1
                elseif kind == "glow" then inst.BackgroundColor3 = col inst.BackgroundTransparency = Cursor.Glow and (1 - Cursor.Alpha * mul) or 1 end
            end
        end
        local function buildCursor()
            for _, c in ipairs(CShape:GetChildren()) do if not c:IsA("UIScale") then c:Destroy() end end
            cParts = {}
            ;(STYLES[Cursor.Style] or STYLES.Arrow)()
            Cursor.Dirty = true
        end
        buildCursor()
        onTheme(function() Cursor.Dirty = true end)

        local cpos = UIS:GetMouseLocation()
        local crot, pressMul, hoverMul = 0, 1, 1
        local sysHidden, sysBackup, trailHidden = false, UIS.MouseIconEnabled, true
        local function clickFx()
            if not (Cursor.Click and CShape.Visible) then return end
            local f = new("Frame", { Parent = CursorGui, AnchorPoint = HALF, Position = UDim2.fromOffset(cpos.X, cpos.Y), Size = UDim2.fromOffset(6, 6), BackgroundTransparency = 1, ZIndex = 3 }, { corner(100) })
            local s = plainStroke(cursorColor(), 2, 0.1)
            s.Parent = f
            local d = 46 * Cursor.Size
            tw(f, 0.5, { Size = UDim2.fromOffset(d, d) }, QUINT)
            tw(s, 0.5, { Transparency = 1, Thickness = 0.5 }, SINE)
            Debris:AddItem(f, 0.7)
        end
        keep(UIS.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then clickFx() end
        end))
        keep(RunService.RenderStepped:Connect(function(dt)
            local menuOpen = Win.Open
            local show = Cursor.Enabled and (not Cursor.OnlyMenu or menuOpen)
            CShape.Visible = show
            local wantHide = (show and Cursor.HideSystem) or Win.HideSystemCursor
            if wantHide then
                if not sysHidden then sysBackup = UIS.MouseIconEnabled sysHidden = true end
                if UIS.MouseIconEnabled then UIS.MouseIconEnabled = false end
            elseif sysHidden then
                UIS.MouseIconEnabled = sysBackup
                sysHidden = false
            end
            if not show then
                if not trailHidden then
                    for _, t in ipairs(Trail) do t.f.Visible = false end
                    trailHidden = true
                end
                return
            end
            trailHidden = false
            if Cursor.Dirty or Cursor.Mode == "Rainbow" then
                if Cursor.Mode == "Rainbow" and not Cursor.Dirty then
                    local col = cursorColor()
                    for _, p in ipairs(cParts) do
                        local kind = p[2]
                        if kind == "fill" or kind == "glow" then p[1].BackgroundColor3 = col
                        elseif kind == "stroke" then p[1].Color = col end
                    end
                else
                    applyLook()
                end
                Cursor.Dirty = false
            end
            local m = UIS:GetMouseLocation()
            local a = 1 - Cursor.Smooth ^ (dt * 60)
            cpos = cpos:Lerp(m, clamp(a, 0, 1))
            CShape.Position = UDim2.fromOffset(cpos.X, cpos.Y)
            local down = Cursor.Shrink and (UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
            pressMul += ((down and 0.78 or 1) - pressMul) * math.min(dt * 18, 1)
            hoverMul += (((Cursor.Hover and menuOpen and Win.OverMenu) and 1.15 or 1) - hoverMul) * math.min(dt * 10, 1)
            local pulse = Cursor.Pulse and (1 + 0.07 * sin(os.clock() * 3.2)) or 1
            CScale.Scale = Cursor.Size * pressMul * hoverMul * pulse
            if Cursor.Spin then
                crot = (crot + dt * Cursor.SpinSpeed) % 360
                CShape.Rotation = crot
            elseif CShape.Rotation ~= 0 then
                CShape.Rotation = 0
            end
            if Cursor.Trail then
                local col = cursorColor()
                local n = math.min(Cursor.TrailLen, #Trail)
                local px, py = cpos.X, cpos.Y
                for i = 1, n do
                    local t = Trail[i]
                    local k = math.min(dt * (30 - i * 0.7), 1)
                    t.x += (px - t.x) * k
                    t.y += (py - t.y) * k
                    px, py = t.x, t.y
                    local fade = 1 - i / (n + 1)
                    local sz = math.max(2, 10 * fade * Cursor.TrailSize)
                    t.f.Visible = true
                    t.f.Position = UDim2.fromOffset(t.x, t.y)
                    t.f.Size = UDim2.fromOffset(sz, sz)
                    t.f.BackgroundColor3 = col
                    t.f.BackgroundTransparency = 1 - 0.6 * fade * Cursor.Alpha
                end
                for i = n + 1, #Trail do
                    local t = Trail[i]
                    if t.f.Visible then t.f.Visible = false end
                    t.x, t.y = cpos.X, cpos.Y
                end
            else
                for _, t in ipairs(Trail) do
                    if t.f.Visible then t.f.Visible = false end
                    t.x, t.y = cpos.X, cpos.Y
                end
            end
        end))
        Win:OnUnload(function()
            if sysHidden then UIS.MouseIconEnabled = sysBackup end
            pcall(function() CursorGui:Destroy() end)
        end)
        function Win:SetHideSystemCursor(v) Win.HideSystemCursor = v and true or false end

        local c1 = curCat:AddModule({ Name = "General", Icon = Icons.Visuals, Static = true })
        c1:AddToggle({ Name = "Custom cursor", Flag = "CurEnabled", Callback = function(v) Cursor.Enabled = v end })
        c1:AddDropdown({ Name = "Style", Options = STYLE_LIST, Default = "Arrow", Flag = "CurStyle", Callback = function(v) Cursor.Style = v buildCursor() end })
        c1:AddSlider({ Name = "Size", Min = 0.4, Max = 3, Step = 0.05, Default = 1, Suffix = "x", Flag = "CurSize", Callback = function(v) Cursor.Size = v end })
        c1:AddSlider({ Name = "Opacity", Min = 0.1, Max = 1, Step = 0.05, Default = 1, Flag = "CurAlpha", Callback = function(v) Cursor.Alpha = v Cursor.Dirty = true end })
        c1:AddToggle({ Name = "Outline", Default = true, Flag = "CurOutline", Callback = function(v) Cursor.Outline = v Cursor.Dirty = true end })
        c1:AddToggle({ Name = "Glow", Flag = "CurGlow", Callback = function(v) Cursor.Glow = v Cursor.Dirty = true end })
        c1:AddToggle({ Name = "Hide system cursor", Default = true, Flag = "CurHideSys", Callback = function(v) Cursor.HideSystem = v end })
        c1:AddToggle({ Name = "Hide system mouse icon (always)", Flag = "HideCursor", Callback = function(v) Win:SetHideSystemCursor(v) end })
        c1:AddToggle({ Name = "Only when menu is open", Flag = "CurOnlyMenu", Callback = function(v) Cursor.OnlyMenu = v end })

        local c2 = curCat:AddModule({ Name = "Color", Icon = Icons.Visuals, Static = true })
        c2:AddOptions({ Name = "Color mode", Options = { "Theme", "Rainbow", "Custom", "White" }, Default = "Theme", Flag = "CurMode", Callback = function(v) Cursor.Mode = v Cursor.Dirty = true end })
        c2:AddColorPicker({ Name = "Custom color", Default = rgb(255, 255, 255), Flag = "CurColor", Callback = function(c) Cursor.Custom = c Cursor.Dirty = true end })
        c2:AddSlider({ Name = "Rainbow speed", Min = 0.05, Max = 2, Step = 0.05, Default = 0.4, Suffix = "x", Flag = "CurRainbow", Callback = function(v) Cursor.RainbowSpeed = v end })

        local c3 = curCat:AddModule({ Name = "Motion", Icon = Icons.Visuals, Static = true })
        c3:AddSlider({ Name = "Smoothing", Min = 0, Max = 0.95, Step = 0.01, Default = 0, Flag = "CurSmooth", Callback = function(v) Cursor.Smooth = v end })
        c3:AddToggle({ Name = "Idle pulse", Flag = "CurPulse", Callback = function(v) Cursor.Pulse = v end })
        c3:AddToggle({ Name = "Spin", Flag = "CurSpin", Callback = function(v) Cursor.Spin = v end })
        c3:AddSlider({ Name = "Spin speed", Min = 10, Max = 720, Step = 10, Default = 120, Suffix = "°/s", Flag = "CurSpinSpeed", Callback = function(v) Cursor.SpinSpeed = v end })
        c3:AddToggle({ Name = "Click ripple", Default = true, Flag = "CurClick", Callback = function(v) Cursor.Click = v end })
        c3:AddToggle({ Name = "Press shrink", Default = true, Flag = "CurShrink", Callback = function(v) Cursor.Shrink = v end })
        c3:AddToggle({ Name = "Menu hover grow", Default = true, Flag = "CurHover", Callback = function(v) Cursor.Hover = v end })

        local c4 = curCat:AddModule({ Name = "Trail", Icon = Icons.Visuals, Static = true })
        c4:AddToggle({ Name = "Cursor trail", Flag = "CurTrail", Callback = function(v) Cursor.Trail = v end })
        c4:AddSlider({ Name = "Trail length", Min = 2, Max = 24, Default = 12, Flag = "CurTrailLen", Callback = function(v) Cursor.TrailLen = v end })
        c4:AddSlider({ Name = "Trail size", Min = 0.3, Max = 2.5, Step = 0.05, Default = 1, Suffix = "x", Flag = "CurTrailSize", Callback = function(v) Cursor.TrailSize = v end })

        local c5 = curCat:AddModule({ Name = "Presets", Icon = Icons.Visuals, Static = true })
        local PRE = {
            ["Classic"]       = { CurStyle = "Arrow",     CurSize = 1,   CurMode = "White",   CurGlow = false, CurTrail = false, CurSpin = false, CurSmooth = 0 },
            ["Accent Dot"]    = { CurStyle = "Dot",       CurSize = 1.2, CurMode = "Theme",   CurGlow = true,  CurTrail = false, CurSpin = false, CurSmooth = 0 },
            ["Neon Ring"]     = { CurStyle = "Dual Ring", CurSize = 1.1, CurMode = "Theme",   CurGlow = true,  CurTrail = true,  CurSpin = true,  CurSmooth = 0.15 },
            ["Rainbow Orb"]   = { CurStyle = "Orb",       CurSize = 1.2, CurMode = "Rainbow", CurGlow = true,  CurTrail = true,  CurSpin = false, CurSmooth = 0.2 },
            ["Sniper Plus"]   = { CurStyle = "Plus",      CurSize = 1,   CurMode = "White",   CurGlow = false, CurTrail = false, CurSpin = false, CurSmooth = 0 },
            ["Diamond Glide"] = { CurStyle = "Diamond",   CurSize = 1.1, CurMode = "Theme",   CurGlow = true,  CurTrail = true,  CurSpin = true,  CurSmooth = 0.35 },
        }
        c5:AddDropdown({ Name = "Apply preset", Options = { "Classic", "Accent Dot", "Neon Ring", "Rainbow Orb", "Sniper Plus", "Diamond Glide" }, Default = "Classic",
            Callback = function(name)
                local p = PRE[name]
                if not p then return end
                for fl, v in pairs(p) do local api = Lib.Flags[fl] if api then api:Set(v) end end
                if Lib.Flags.CurEnabled then Lib.Flags.CurEnabled:Set(true) end
                Win:Notify("Cursor", "Preset: " .. name, 2)
            end })
        c5:AddButton({ Name = "Reset cursor", ButtonText = "RESET", Callback = function()
            local d = { CurStyle = "Arrow", CurSize = 1, CurAlpha = 1, CurOutline = true, CurGlow = false, CurHideSys = true, CurOnlyMenu = false,
                CurMode = "Theme", CurRainbow = 0.4, CurSmooth = 0, CurPulse = false, CurSpin = false, CurSpinSpeed = 120, CurClick = true,
                CurShrink = true, CurHover = true, CurTrail = false, CurTrailLen = 12, CurTrailSize = 1 }
            for fl, v in pairs(d) do local api = Lib.Flags[fl] if api then api:Set(v) end end
            Win:Notify("Cursor", "Settings reset", 2, "ok")
        end })

        --------------------------------------------------------------
        --  BACKGROUND UI
        --------------------------------------------------------------
        local b1 = bgCat:AddModule({ Name = "Image", Icon = Icons.Visuals, Static = true })
        b1:AddToggle({ Name = "Enabled", Flag = "BgEnabled", Callback = function(v) Bg.Enabled = v Win:ApplyBackground() end })
        b1:AddTextbox({ Name = "Image ID / URL", Placeholder = "rbxassetid://123 or 123", Flag = "BgImageId", Callback = function(t) Bg.ImageId = t Win:ApplyBackground() end })
        b1:AddOptions({ Name = "Scale mode", Options = { "Crop", "Fit", "Stretch" }, Default = "Crop", Flag = "BgScaleType", Callback = function(v) Bg.ScaleType = v Win:ApplyBackground() end })
        b1:AddSlider({ Name = "Opacity", Min = 0, Max = 1, Step = 0.05, Default = 1, Flag = "BgOpacity", Callback = function(v) Bg.Opacity = v Win:ApplyBackground() end })
        b1:AddSlider({ Name = "Dim (darkness)", Min = 0, Max = 0.9, Step = 0.05, Default = 0.45, Flag = "BgImageDim", Callback = function(v) Bg.Dim = v Win:ApplyBackground() end })
        b1:AddOptions({ Name = "Dim color", Options = { "Black", "Theme", "Custom" }, Default = "Black", Flag = "BgDimColor", Callback = function(v) Bg.DimColor = v Win:ApplyBackground() end })
        b1:AddColorPicker({ Name = "Custom dim color", Default = rgb(0, 0, 0), Flag = "BgDimCustom", Callback = function(c) Bg.DimCustom = c Win:ApplyBackground() end })
        b1:AddColorPicker({ Name = "Tint color", Default = WHITE, Flag = "BgTint", Callback = function(c) Bg.Tint = c Win:ApplyBackground() end })
        b1:AddSlider({ Name = "Tint strength", Min = 0, Max = 1, Step = 0.05, Default = 0, Flag = "BgTintStrength", Callback = function(v) Bg.TintStrength = v Win:ApplyBackground() end })
        b1:AddToggle({ Name = "Edge fade", Default = true, Flag = "BgEdgeFade", Callback = function(v) Bg.EdgeFade = v Win:ApplyBackground() end })

        local b2 = bgCat:AddModule({ Name = "Motion", Icon = Icons.Visuals, Static = true })
        b2:AddSlider({ Name = "Parallax", Min = 0, Max = 0.15, Step = 0.005, Default = 0.02, Flag = "BgParallax", Callback = function(v) Bg.Parallax = v end })
        b2:AddToggle({ Name = "Ken Burns", Flag = "BgKenBurns", Callback = function(v) Bg.KenBurns = v end })
        b2:AddSlider({ Name = "Ken Burns speed", Min = 0.02, Max = 0.5, Step = 0.01, Default = 0.08, Flag = "BgKenSpeed", Callback = function(v) Bg.KenSpeed = v end })

        local b3 = bgCat:AddModule({ Name = "Slideshow", Icon = Icons.Visuals, Static = true })
        b3:AddToggle({ Name = "Slideshow", Flag = "BgSlideshow", Callback = function(v) Bg.Slideshow = v Win:ApplyBackground() end })
        b3:AddSlider({ Name = "Interval", Min = 3, Max = 60, Step = 1, Default = 15, Suffix = "s", Flag = "BgSlideTime", Callback = function(v) Bg.SlideTime = v end })
        local slideInfo = b3:AddLabel("Slideshow: 0 images", 20)
        Win.RefreshSlideInfo = function()
            slideInfo.Text = string.format("Slideshow: %d images (current: %d/%d)", #Bg.Images,
                clamp(Bg.Index, 1, math.max(#Bg.Images, 1)), math.max(#Bg.Images, 1))
        end
        Win.RefreshSlideInfo()
        b3:AddTextbox({ Name = "Add image", Placeholder = "paste ID, press Enter", Callback = function(t)
            if t == "" then return end
            local id = resolveImageId(t)
            if id == "" then Win:Notify("Background", "Invalid image ID", 2, "err") return end
            table.insert(Bg.Images, id)
            Win.RefreshSlideInfo()
            Win:Notify("Background", "Added (" .. #Bg.Images .. " total)", 2, "ok")
            Win:ApplyBackground()
        end })
        b3:AddButton({ Name = "Add current image", ButtonText = "ADD", Callback = function()
            local id = resolveImageId(Bg.ImageId)
            if id == "" then Win:Notify("Background", "Set an Image ID first", 2, "warn") return end
            table.insert(Bg.Images, id)
            Win.RefreshSlideInfo()
            Win:Notify("Background", "Added current (" .. #Bg.Images .. " total)", 2, "ok")
        end })
        b3:AddButton({ Name = "Next image", ButtonText = "NEXT", Callback = function()
            if #Bg.Images > 0 then
                Bg.Index = (Bg.Index % #Bg.Images) + 1
                Win.RefreshSlideInfo()
                Win:ApplyBackground()
            end
        end })
        b3:AddButton({ Name = "Clear slideshow", ButtonText = "CLEAR", Callback = function()
            Bg.Images, Bg.Index = {}, 1
            Win.RefreshSlideInfo()
            Win:Notify("Background", "Slideshow cleared", 2, "warn")
            Win:ApplyBackground()
        end })

        local b4 = bgCat:AddModule({ Name = "Presets", Icon = Icons.Visuals, Static = true })
        local BPRE = {
            { "Current Game",  function() return "rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=1080&h=1080" end },
            { "Player Avatar", function() return "rbxthumb://type=Avatar&id=" .. LocalPlayer.UserId .. "&w=1080&h=1080" end },
            { "Sample 1", "rbxassetid://112667309817699" },
            { "Sample 2", "rbxassetid://75896864475870" },
            { "Sample 3", "rbxassetid://11460838" },
        }
        local bnames = {}
        for _, p in ipairs(BPRE) do table.insert(bnames, p[1]) end
        local function applyPreset(p)
            local id = type(p[2]) == "function" and p[2]() or p[2]
            Bg.ImageId = id
            if Lib.Flags.BgImageId then Lib.Flags.BgImageId:Set(id) end
            if Lib.Flags.BgEnabled then Lib.Flags.BgEnabled:Set(true) end
            Win:ApplyBackground()
            Win:Notify("Background", "Preset: " .. p[1], 2)
        end
        b4:AddDropdown({ Name = "Preset", Options = bnames, Default = "Current Game", Callback = function(name)
            for _, p in ipairs(BPRE) do if p[1] == name then applyPreset(p) return end end
        end })
        b4:AddButton({ Name = "Random preset", ButtonText = "ROLL", Callback = function() applyPreset(BPRE[math.random(#BPRE)]) end })
        Win:ApplyBackground()

        --------------------------------------------------------------
        --  CONFIGS
        --------------------------------------------------------------
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

        account.MouseButton1Click:Connect(function() sfx() searchBox.Text = "" Win.Query = "" Win:Select(cf) end)

        if Win.Current == nil then Win:Select(Win.Categories[1]) end
        layoutNav(true)
        -- каскадное появление сайдбара
        for i, c in ipairs(Win.Categories) do
            if c.Btn.Visible then
                c.Btn.Position = UDim2.fromOffset(-40, c.Y)
                task.delay(0.25 + i * 0.03, function() tw(c.Btn, 0.6, { Position = UDim2.fromOffset(0, c.Y) }, BACK) end)
            end
        end
        -- автозагрузка
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

    ------------------------------------------------------------------
    --  INPUT
    ------------------------------------------------------------------
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
            if ut == Enum.UserInputType.Keyboard then Lib._listen = nil f(input.KeyCode)
            elseif ut == Enum.UserInputType.MouseButton2 or ut == Enum.UserInputType.MouseButton3 then Lib._listen = nil f(ut) end
            return
        end
        if gp then return end
        fireBinds(function(k) return keyMatch(k, input) end, true)
    end))
    keep(UIS.InputEnded:Connect(function(input) fireBinds(function(k) return keyMatch(k, input) end, false) end))
    local xHeld = {}
    keep(RunService.Heartbeat:Connect(function()
        local poll = iskeypressed or isKeyPressed
        if not poll then return end
        for name, vk in pairs(XBTN) do
            local ok, d = pcall(poll, vk)
            d = ok and d == true
            if d ~= (xHeld[name] or false) then
                xHeld[name] = d
                if d and Lib._listen then local f = Lib._listen Lib._listen = nil f(name)
                else fireBinds(function(k) return k == name end, d) end
            end
        end
    end))
    -- клавиша меню — отдельно, чтобы работала даже без модулей
    keep(UIS.InputBegan:Connect(function(input, gp)
        if gp or Lib._listen then return end
        if input.KeyCode == Win.ToggleKey and not UIS:GetFocusedTextBox() then Win:Toggle() end
    end))

    Win:SetNotifPos("Top Right")
    Win:SetWatermarkPos("Top Left")
    Win:SetGlow(0.55)
    scale.Scale = fit() * 0.8
    tw(scale, 0.9, { Scale = fit() }, BACK)
    tw(dim, 0.8, { BackgroundTransparency = 1 - Win.DimAmt }, SINE)
    waves()
    Win.Open = true

    return Win
end

return Lib