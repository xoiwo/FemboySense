local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')

local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local ScreenGui = Instance.new('ScreenGui');
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.ResetOnSpawn = false;
ScreenGui.AutoLocalize = false;
ScreenGui.Parent = LocalPlayer:WaitForChild('PlayerGui', 10);

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    FontColor = Color3.fromRGB(255, 255, 255);
    MainColor = Color3.fromRGB(36, 36, 36);
    BackgroundColor = Color3.fromRGB(28, 28, 28);
    AccentColor = Color3.fromRGB(0, 250, 157);
    OutlineColor = Color3.fromRGB(55, 55, 55);
    RiskColor = Color3.fromRGB(255, 50, 50);

    Black = Color3.new(0, 0, 0);

    AccentColor2 = Color3.fromRGB(72, 255, 178);
    AccentFill = Color3.new(1, 1, 1);
    GradientEnabled = true;
    GradientRotation = 165;
    GlowEnabled = true;
    GlowSize = 10;
    GlowIntensity = 15;
    GlowFollowAccent = true;
    GlowColor = Color3.fromRGB(0, 250, 157);
    _Glows = {};
    _AccentGradients = {};

    Font = Enum.Font.Code;
    TextScale = 1;
    MinTextScale = 0.7;
    MaxTextScale = 1.5;

    OpenedFrames = {};
    DependencyBoxes = {};

    Signals = {};
    ScreenGui = ScreenGui;
    _KeyPickers = {};
};

local Hue = 0
local _rainbowAccum = 0

table.insert(Library.Signals, RunService.Heartbeat:Connect(function(Delta)
    _rainbowAccum = _rainbowAccum + Delta
    if _rainbowAccum < 0.05 then return end
    _rainbowAccum = 0

    Hue = Hue + (1 / 400);
    if Hue > 1 then Hue = 0 end

    Library.CurrentRainbowHue = Hue;
    Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
end))

table.insert(Library.Signals, InputService.InputBegan:Connect(function(Input, Processed)
    local kp = Library._KeyPickers
    for i = 1, #kp do
        local entry = kp[i]
        local KeyPicker       = entry.KeyPicker
        local PickingRef      = entry.PickingRef
        local ModeSelectOuter = entry.ModeSelectOuter

        if not PickingRef[1] then
            if KeyPicker.Mode == 'Toggle' and not Processed then
                local Key = KeyPicker.Value
                if Key == 'MB1' or Key == 'MB2' then
                    if (Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1)
                    or (Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2) then
                        KeyPicker.Toggled = not KeyPicker.Toggled
                        KeyPicker:DoClick()
                    end
                elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                    if Input.KeyCode.Name == Key then
                        KeyPicker.Toggled = not KeyPicker.Toggled
                        KeyPicker:DoClick()
                    end
                end
            end
            KeyPicker:Update()
        end

        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local AbsPos  = ModeSelectOuter.AbsolutePosition
            local AbsSize = ModeSelectOuter.AbsoluteSize
            if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
            or Mouse.Y < (AbsPos.Y - 21) or Mouse.Y > AbsPos.Y + AbsSize.Y then
                ModeSelectOuter.Visible = false
            end
        end
    end
end))

table.insert(Library.Signals, InputService.InputEnded:Connect(function()
    local kp = Library._KeyPickers
    for i = 1, #kp do
        local entry = kp[i]
        if not entry.PickingRef[1] then
            entry.KeyPicker:Update()
        end
    end
end))

local _cachedPlayerList = nil;
local _cachedTeamList   = nil;

local function _buildPlayerList()
    local raw = Players:GetPlayers();
    local t = table.create(#raw);
    for i = 1, #raw do t[i] = raw[i].Name end;
    table.sort(t, function(a, b) return a < b end);
    _cachedPlayerList = t;
end;

local function _buildTeamList()
    local raw = Teams:GetTeams();
    local t = table.create(#raw);
    for i = 1, #raw do t[i] = raw[i].Name end;
    table.sort(t, function(a, b) return a < b end);
    _cachedTeamList = t;
end;

local function GetPlayersString()
    if not _cachedPlayerList then _buildPlayerList() end;
    return _cachedPlayerList;
end;

local function GetTeamsString()
    if not _cachedTeamList then _buildTeamList() end;
    return _cachedTeamList;
end;

Players.PlayerAdded:Connect(function()   _cachedPlayerList = nil end);
Players.PlayerRemoving:Connect(function() _cachedPlayerList = nil end);
Teams.ChildAdded:Connect(function()    _cachedTeamList = nil end);
Teams.ChildRemoved:Connect(function()  _cachedTeamList = nil end);

function Library:SafeCallback(f, ...)
    if (not f) then
        return;
    end;

    if not Library.NotifyOnError then
        return f(...);
    end;

    local success, event = pcall(f, ...);

    if not success then
        local _, i = event:find(":%d+: ");

        if not i then
            return Library:Notify(event);
        end;

        return Library:Notify(event:sub(i + 1), 3);
    end;
end;

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = type(Class) == 'string' and Instance.new(Class) or Class;

    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;

    return _Instance;
end;

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;

    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        LineJoinMode = Enum.LineJoinMode.Miter;
        Parent = Inst;
    });
end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Instance.new('TextLabel');
    _Instance.BackgroundTransparency = 1;
    _Instance.Font = Library.Font;
    _Instance.TextColor3 = Library.FontColor;
    _Instance.TextSize = 16;
    _Instance.TextStrokeTransparency = 1;
    _Instance.AutoLocalize = false;

    local _stroke = Instance.new('UIStroke');
    _stroke.Color = Color3.new(0, 0, 0);
    _stroke.Thickness = 1;
    _stroke.LineJoinMode = Enum.LineJoinMode.Miter;
    _stroke.Parent = _Instance;

    Library:AddToRegistry(_Instance, { TextColor3 = 'FontColor' }, IsHud);

    for Prop, Val in next, Properties do
        _Instance[Prop] = Val;
    end;

    return _Instance;
end;

Library.AllowOverlap = true;
Library._Draggables = setmetatable({}, { __mode = 'k' });

local function _IsReallyVisible(Gui)
    local Cur = Gui;
    while Cur and Cur ~= ScreenGui do
        if Cur:IsA('GuiObject') and not Cur.Visible then return false end;
        Cur = Cur.Parent;
    end;
    return Cur == ScreenGui;
end;

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true;
    Library._Draggables[Instance] = true;

    local _cutoff = Cutoff or 40;

    local Dragging = false;
    local StartMouse, StartAbs, StartPos, LastAbs;
    local _dragConn = nil;

    local function Collides(Pos)
        local Size = Instance.AbsoluteSize;
        for Other in next, Library._Draggables do
            if Other ~= Instance and _IsReallyVisible(Other) then
                local OP, OS = Other.AbsolutePosition, Other.AbsoluteSize;
                if OS.X > 0 and OS.Y > 0
                    and Pos.X < OP.X + OS.X and Pos.X + Size.X > OP.X
                    and Pos.Y < OP.Y + OS.Y and Pos.Y + Size.Y > OP.Y then
                    return true;
                end;
            end;
        end;
        return false;
    end;

    local function Resolve(Cur, Target)
        if Library.AllowOverlap then return Target end;
        if not Collides(Target) then return Target end;
        if Collides(Cur) then return Target end;
        local OnlyX = Vector2.new(Target.X, Cur.Y);
        if not Collides(OnlyX) then return OnlyX end;
        local OnlyY = Vector2.new(Cur.X, Target.Y);
        if not Collides(OnlyY) then return OnlyY end;
        return Cur;
    end;

    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local absPos = Instance.AbsolutePosition;
            local dy = Mouse.Y - absPos.Y;
            if dy > _cutoff then return end;

            Dragging   = true;
            StartMouse = Vector2.new(Input.Position.X, Input.Position.Y);
            StartAbs   = absPos;
            StartPos   = Instance.Position;
            LastAbs    = absPos;

            if _dragConn then _dragConn:Disconnect() end;
            _dragConn = InputService.InputChanged:Connect(function(Input)
                if not Dragging then return end;
                if Input.UserInputType ~= Enum.UserInputType.MouseMovement then return end;

                local Wanted = StartAbs + (Vector2.new(Input.Position.X, Input.Position.Y) - StartMouse);

                local Dist  = math.max(math.abs(Wanted.X - LastAbs.X), math.abs(Wanted.Y - LastAbs.Y));
                local Steps = math.max(1, math.ceil(Dist / 8));
                local From, Pos = LastAbs, LastAbs;
                for i = 1, Steps do
                    Pos = Resolve(Pos, From:Lerp(Wanted, i / Steps));
                end;
                LastAbs = Pos;

                local Delta = Pos - StartAbs;
                Instance.Position = UDim2.new(
                    StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                    StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                );
            end);
        end;
    end);

    Instance.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = false;
            if _dragConn then
                _dragConn:Disconnect();
                _dragConn = nil;
            end;
        end;
    end);
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14);
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,

        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,

        Visible = false,
    })

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y);
        TextSize = 14;
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1,

        Parent = Tooltip;
    });

    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    Library:AddToRegistry(Label, {
        TextColor3 = 'FontColor',
    });

    local _tooltipConn = nil;

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then return end

        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12);
        Tooltip.Visible = true;

        _tooltipConn = InputService.InputChanged:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement then
                Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12);
            end;
        end);
    end)

    HoverInstance.MouseLeave:Connect(function()
        Tooltip.Visible = false;
        if _tooltipConn then
            _tooltipConn:Disconnect();
            _tooltipConn = nil;
        end;
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    local lib = Library;
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = lib.RegistryMap[Instance];

        for Property, ColorIdx in next, Properties do
            Instance[Property] = lib[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = lib.RegistryMap[Instance];

        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = lib[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)
end;

function Library:MouseIsOverOpenedFrame()
    local mx, my = Mouse.X, Mouse.Y;
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

        if mx >= AbsPos.X and mx <= AbsPos.X + AbsSize.X
            and my >= AbsPos.Y and my <= AbsPos.Y + AbsSize.Y then

            return true;
        end;
    end;
end;

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
    local mx, my = Mouse.X, Mouse.Y;

    if mx >= AbsPos.X and mx <= AbsPos.X + AbsSize.X
        and my >= AbsPos.Y and my <= AbsPos.Y + AbsSize.Y then

        return true;
    end;
end;

function Library:UpdateDependencyBoxes()
    local db = Library.DependencyBoxes;
    for i = 1, #db do
        db[i]:Update();
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    local t = (Value - MinA) / (MaxA - MinA);
    return (1 - t) * MinB + t * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    Size = math.max(1, math.floor(Size * (Library.TextScale or 1) + 0.5));
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end;
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);
Library.MainColorDark   = Library:GetDarkerColor(Library.MainColor);

local _cachedMainGradient = nil;
local _cachedMainColorForGradient = nil;
local function GetMainGradient()
    if Library.MainColor ~= _cachedMainColorForGradient then
        _cachedMainColorForGradient = Library.MainColor;
        Library.MainColorDark = Library:GetDarkerColor(Library.MainColor);
        _cachedMainGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library.MainColorDark),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
    end;
    return _cachedMainGradient;
end;

function Library:AddToRegistry(Instance, Properties, IsHud)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;

    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };

    Library.Registry[Idx] = Data;
    Library.RegistryMap[Instance] = Data;

    if IsHud then
        Library.HudRegistry[#Library.HudRegistry + 1] = Data;
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];
    if not Data then return end;

    local reg = Library.Registry;
    local regIdx = Data.Idx;
    local last = reg[#reg];
    if last and last ~= Data then
        reg[regIdx] = last;
        last.Idx = regIdx;
    end;
    reg[#reg] = nil;

    local hud = Library.HudRegistry;
    for i = #hud, 1, -1 do
        if hud[i] == Data then
            hud[i] = hud[#hud];
            hud[#hud] = nil;
            break;
        end;
    end;

    Library.RegistryMap[Instance] = nil;
end;

function Library:UpdateColorsUsingRegistry()
    Library:RefreshAccent();
    local reg = Library.Registry;
    local lib = Library;
    local _type = type;
    for i = 1, #reg do
        local Object = reg[i];
        local inst = Object.Instance;
        local props = Object.Properties;
        for Property, ColorIdx in next, props do
            local t = _type(ColorIdx);
            if t == 'string' then
                inst[Property] = lib[ColorIdx];
            elseif t == 'function' then
                inst[Property] = ColorIdx();
            end;
        end;
    end;
    Library:UpdateGradients();
    Library:UpdateGlows();
end;

function Library:RefreshAccent()

    Library.AccentFill = Library.GradientEnabled and Color3.new(1, 1, 1) or Library.AccentColor;
end;

function Library:GetAccentGradient()
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, Library.AccentColor),
        ColorSequenceKeypoint.new(1, Library.AccentColor2),
    });
end;

function Library:AddAccentGradient(Frame, Cond, Rotation)
    local G = Library:Create('UIGradient', {
        Color = Library:GetAccentGradient();
        Rotation = Rotation or Library.GradientRotation;
        Enabled = Library.GradientEnabled and (not Cond or Cond());
        Parent = Frame;
    });
    Library._AccentGradients[G] = { Cond = Cond; Fixed = Rotation };
    return G;
end;

function Library:UpdateGradients()
    local seq = Library:GetAccentGradient();
    for G, Data in next, Library._AccentGradients do
        if not G.Parent then
            Library._AccentGradients[G] = nil;
        else
            G.Color = seq;
            G.Rotation = Data.Fixed or Library.GradientRotation;
            G.Enabled = Library.GradientEnabled and (not Data.Cond or Data.Cond());
        end;
    end;
end;

function Library:SetGradient(Enabled, Color2, Rotation)
    if Enabled ~= nil then Library.GradientEnabled = Enabled and true or false end;
    if typeof(Color2) == 'Color3' then Library.AccentColor2 = Color2 end;
    if type(Rotation) == 'number' then Library.GradientRotation = Rotation end;
    Library:UpdateColorsUsingRegistry();
end;

local GLOW_LAYERS = 8;

function Library:GetGlowColor()
    return Library.GlowFollowAccent and Library.AccentColor or Library.GlowColor;
end;

function Library:AddGlow(Parent, Opts)
    Opts = Opts or {};
    local Z = Opts.ZIndex or math.max(Parent.ZIndex - 1, 0);

    local Glow = Library:Create('Frame', {
        Name = 'Glow';
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = Z;
        Visible = false;
        Parent = Parent;
    });

    local Layers, Corners = {}, {};
    for i = 1, GLOW_LAYERS do
        local Layer = Library:Create('Frame', {
            BackgroundColor3 = Library:GetGlowColor();
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            ZIndex = Z;
            Parent = Glow;
        });
        Corners[i] = Library:Create('UICorner', { Parent = Layer });
        Layers[i] = Layer;
    end;

    Library._Glows[Glow] = { Cond = Opts.Cond; SizeMul = Opts.SizeMul or 1; Layers = Layers; Corners = Corners };
    Library:UpdateGlows();
    return Glow;
end;

function Library:UpdateGlows()
    local Color = Library:GetGlowColor();
    local Trans = 1 - (math.clamp(Library.GlowIntensity, 0, 100) / 100) * 0.2;
    for Glow, Data in next, Library._Glows do
        if not Glow.Parent then
            Library._Glows[Glow] = nil;
        else
            local S = Library.GlowSize * Data.SizeMul;
            local N = #Data.Layers;
            for i = 1, N do
                local O = math.max(1, math.floor(S * i / N + 0.5));
                local Layer = Data.Layers[i];
                Layer.BackgroundColor3 = Color;
                Layer.BackgroundTransparency = Trans;
                Layer.Size = UDim2.new(1, O * 2, 1, O * 2);
                Layer.Position = UDim2.new(0, -O, 0, -O);
                Data.Corners[i].CornerRadius = UDim.new(0, O);
            end;
            Glow.Visible = Library.GlowEnabled and (not Data.Cond or Data.Cond());
        end;
    end;
end;

function Library:SetGlow(Enabled, Size, Intensity)
    if Enabled ~= nil then Library.GlowEnabled = Enabled and true or false end;
    if type(Size) == 'number' then Library.GlowSize = Size end;
    if type(Intensity) == 'number' then Library.GlowIntensity = Intensity end;
    Library:UpdateGlows();
end;

function Library:GiveSignal(Signal)
    Library.Signals[#Library.Signals + 1] = Signal
end

Library._OnUnloadCallback = nil;

function Library:Unload()
    Library.Unloaded = true

    for _, toggle in pairs(getgenv().Toggles or {}) do
        pcall(function()
            if toggle.Value == true then
                toggle:SetValue(false)
            end
        end)
    end

    for _, option in pairs(getgenv().Options or {}) do
        pcall(function()
            if option.Default ~= nil and option.SetValue then
                option:SetValue(option.Default)
            end
        end)
    end

    if Library._OnUnloadCallback then
        pcall(Library._OnUnloadCallback)
    end

    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        pcall(function() Connection:Disconnect() end)
    end

    table.clear(Library._KeyPickers)

    local rs = game:GetService('RunService')
    for _, name in ipairs({'RenderStepped', 'Heartbeat', 'Stepped'}) do
        pcall(function()
            if rs[name] then
                rs[name]:DisconnectAll()
            end
        end)
    end

    if ScreenGui and ScreenGui.Parent then
        ScreenGui:Destroy()
    end

    getgenv().Library = nil
    getgenv().Toggles = nil
    getgenv().Options = nil
    getgenv().SkywareLoaded = nil
end

function Library:OnUnload(Callback)
    Library._OnUnloadCallback = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end))

local BaseAddons = {};

do
    local Funcs = {};

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;

        assert(Info.Default, 'AddColorPicker: Missing default value.');

        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end;
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);

            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;

        ColorPicker:SetHSVFromRGB(ColorPicker.Value);

        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(0, 28, 0, 14);
            ZIndex = 6;
            Parent = ToggleLabel;
        });

        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(0, 27, 0, 13);
            ZIndex = 5;
            Image = 'http://www.roblox.com/asset/?id=12977615774';
            Visible = not not Info.Transparency;
            Parent = DisplayFrame;
        });

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        });

        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
        end)

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });

        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        });

        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapInner;
        });

        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        });

        local CursorInner = Library:Create('ImageLabel', {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex = 20;
            Parent = CursorOuter;
        })

        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        });

        local HueCursor = Library:Create('Frame', { 
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = 18;
            Parent = HueSelectorInner;
        });

        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner;
        });

        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = HueBoxOuter;
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = HueBoxInner;
        });

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            AutoLocalize = false;
            ZIndex = 20,
            Parent = HueBoxInner;
        });

        Library:ApplyTextStroke(HueBox);

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        });

        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = Library.FontColor
        });

        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor;
        
        if Info.Transparency then 
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = PickerFrameInner;
            });

            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = TransparencyBoxOuter;
            });

            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' });

            Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 20;
                Parent = TransparencyBoxInner;
            });

            TransparencyCursor = Library:Create('Frame', { 
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 21;
                Parent = TransparencyBoxInner;
            });
        end;

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 14;
            Text = ColorPicker.Title,
            TextWrapped = false;
            ZIndex = 16;
            Parent = PickerFrameInner;
        });


        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,

                Visible = false,
                Parent = ScreenGui
            })

            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = ContextMenu.Container;
            });

            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = ContextMenu.Inner;
            });

            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            });

            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end

            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end

                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end

            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)

            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            function ContextMenu:Show()
                self.Container.Visible = true
            end

            function ContextMenu:Hide()
                self.Container.Visible = false
            end

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then
                    Callback = function() end
                end

                local Button = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = 13;
                    Text = Str;
                    ZIndex = 16;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                });

                Library:OnHighlight(Button, Button, 
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor' }
                );

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                    end

                    Callback()
                end)
            end

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)

            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then
                    return Library:Notify('You have not copied a color!', 2)
                end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)


            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('Copied hex code to clipboard!', 2)
            end)

            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', '))
                Library:Notify('Copied RGB values to clipboard!', 2)
            end)

        end

        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });

        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor', });
        Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor', });

        local SequenceTable = {};

        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
        end;

        local HueSelectorGradient = Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent = HueSelectorInner;
        });

        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end

            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end

            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);

            DisplayFrame.BackgroundColor3 = ColorPicker.Value;
            DisplayFrame.BackgroundTransparency = ColorPicker.Transparency;
            DisplayFrame.BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);

            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value;
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0);
            end;

            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0);

            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value);
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value);
        end;

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            Func(ColorPicker.Value)
        end;

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false;
                    Library.OpenedFrames[Frame] = nil;
                end;
            end;

            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = true;
        end;

        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;

        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);

            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinX = SatVibMap.AbsolutePosition.X;
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X;
                    local MouseX = math.clamp(Mouse.X, MinX, MaxX);

                    local MinY = SatVibMap.AbsolutePosition.Y;
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinY = HueSelectorInner.AbsolutePosition.Y;
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y;
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        DisplayFrame.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end;
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end);

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local MinX = TransparencyBoxInner.AbsolutePosition.X;
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X;
                        local MouseX = math.clamp(Mouse.X, MinX, MaxX);

                        ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX));

                        ColorPicker:Display();

                        RenderStepped:Wait();
                    end;

                    Library:AttemptSave();
                end;
            end);
        end;

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                if PickerFrameOuter.Visible then
                    local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;

                    if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                        or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                        ColorPicker:Hide();
                    end;
                end;

                if not Library:IsMouseOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))

        ColorPicker:Display();
        ColorPicker.DisplayFrame = DisplayFrame

        Options[Idx] = ColorPicker;

        return self;
    end;

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self;
        local ToggleLabel = self.TextLabel;
        local Container = self.Container;

        assert(Info.Default, 'AddKeyPicker: Missing default value.');

        local KeyPicker = {
            Value = Info.Default;
            Toggled = false;
            Mode = Info.Mode or 'Toggle';
            Type = 'KeyPicker';
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;

            SyncToggleState = Info.SyncToggleState or false;
        };

        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' }
            Info.Mode = 'Toggle'
        end

        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 6;
            LayoutOrder = 0;
            Parent = ToggleLabel;
        });

        local ResetOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 24, 0, 15);
            ZIndex = 6;
            LayoutOrder = 1;
            Parent = ToggleLabel;
        });

        local ResetInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = ResetOuter;
        });

        Library:AddToRegistry(ResetInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        local ResetLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 11;
            Text = 'RS';
            TextXAlignment = Enum.TextXAlignment.Center;
            ZIndex = 8;
            Parent = ResetInner;
        });

        Library:OnHighlight(ResetOuter, ResetOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.ResetTooltip) == 'string' then
            Library:AddToolTip(Info.ResetTooltip, ResetOuter)
        end

        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = PickOuter;
        });

        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 13;
            Text = Info.Default;
            TextWrapped = true;
            ZIndex = 8;
            Parent = PickInner;
        });

        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
            Size = UDim2.new(0, 60, 0, 45 + 2);
            Visible = false;
            ZIndex = 14;
            Parent = ScreenGui;
        });

        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
        end);

        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 15;
            Parent = ModeSelectOuter;
        });

        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        });

        local ContainerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left;
            Size = UDim2.new(1, 0, 0, 18);
            TextSize = 13;
            Visible = false;
            ZIndex = 110;
            Parent = Library.KeybindContainer;
        },  true);

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
        local ModeButtons = {};

        for Idx, Mode in next, Modes do
            local ModeButton = {};

            local Label = Library:CreateLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = 13;
                Text = Mode;
                ZIndex = 16;
                Parent = ModeSelectInner;
            });

            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect();
                end;

                KeyPicker.Mode = Mode;

                Label.TextColor3 = Library.AccentColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';

                ModeSelectOuter.Visible = false;
            end;

            function ModeButton:Deselect()
                Label.TextColor3 = Library.FontColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
            end;

            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    ModeButton:Select();
                    Library:AttemptSave();
                end;
            end);

            if Mode == KeyPicker.Mode then
                ModeButton:Select();
            end;

            ModeButtons[Mode] = ModeButton;
        end;

        local _keybindLayout = Library.KeybindContainer:FindFirstChildWhichIsA('UIListLayout');

        function KeyPicker:Update()
            if Info.NoUI then
                return;
            end;

            local State = KeyPicker:GetState();

            ContainerLabel.Text = string.format('[%s] %s (%s)', KeyPicker.Value or '', Info.Text, KeyPicker.Mode);

            ContainerLabel.Visible = true;
            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor;

            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor';

            local YSize = 0;
            local XSize = 0;
            for _, Label in next, Library.KeybindContainer:GetChildren() do
                if Label:IsA('TextLabel') then
                    if Label.Visible then
                        YSize = YSize + Label.AbsoluteSize.Y;
                        if Label.TextBounds.X > XSize then
                            XSize = Label.TextBounds.X;
                        end;
                    end;
                end;
            end;

            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10, 210), 0, YSize + 23)
        end;

        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true;
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then
                    return false;
                end

                local Key = KeyPicker.Value;

                if Key == 'MB1' or Key == 'MB2' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
                else
                    if not KeyPicker.Value then return false end;
                    local ok, code = pcall(function() return Enum.KeyCode[KeyPicker.Value] end);
                    return ok and code and InputService:IsKeyDown(code) or false;
                end;
            else
                return KeyPicker.Toggled;
            end;
        end;

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2];
            if Key == 'None' then Key = nil end;
            DisplayLabel.Text = Key or '';
            KeyPicker.Value = Key;
            if ModeButtons[Mode] then ModeButtons[Mode]:Select() end;
            KeyPicker:Update();
        end;

        function KeyPicker:Reset()
            KeyPicker.Toggled = false;
            KeyPicker.Value = nil;
            DisplayLabel.Text = '';

            if ParentObj.Type == 'Toggle' then
                ParentObj:SetValue(false);
            end;

            Library:SafeCallback(KeyPicker.Callback, false)
            Library:SafeCallback(KeyPicker.Clicked, false)
            Library:SafeCallback(KeyPicker.ChangedCallback, nil)
            Library:SafeCallback(KeyPicker.Changed, nil)

            KeyPicker:Update();
            Library:AttemptSave();
        end;

        ResetOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                KeyPicker:Reset();
            end;
        end);

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end

        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            Callback(KeyPicker.Value)
        end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
        end

        local Picking = false;
        local _pickingRef = {false};

        PickOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking = true;
                if _pickingRef then _pickingRef[1] = true end

                DisplayLabel.Text = '';

                local Break;
                local Text = '';

                task.spawn(function()
                    while (not Break) do
                        if Text == '...' then
                            Text = '';
                        end;

                        Text = Text .. '.';
                        DisplayLabel.Text = Text;

                        task.wait(0.4);
                    end;
                end);

                task.wait(0.2);

                local Event;
                Event = InputService.InputBegan:Connect(function(Input)
                    local Key;

                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name;
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Key = 'MB1';
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = 'MB2';
                    end;

                    Break = true;
                    Picking = false;
                    if _pickingRef then _pickingRef[1] = false end

                    if not Key then Event:Disconnect(); return end;

                    if Key == 'Backspace' then
                        Event:Disconnect();
                        KeyPicker:Reset();
                        return;
                    end;

                    DisplayLabel.Text = Key;
                    KeyPicker.Value = Key;

                    Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
                    Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)

                    Library:AttemptSave();

                    Event:Disconnect();
                end);
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ModeSelectOuter.Visible = true;
            elseif Input.UserInputType == Enum.UserInputType.MouseButton3 and not Library:MouseIsOverOpenedFrame() then
                KeyPicker:Reset();
            end;
        end);

        Library._KeyPickers[#Library._KeyPickers + 1] = {
            KeyPicker       = KeyPicker;
            PickingRef      = _pickingRef;
            ModeSelectOuter = ModeSelectOuter;
        }

        KeyPicker:Update();

        Options[Idx] = KeyPicker;

        return self;
    end;

    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

local BaseGroupbox = {};

do
    local Funcs = {};

    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Container = Groupbox.Container;

        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container;
        });
    end;

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {};

        local Groupbox = self;
        local Container = Groupbox.Container;

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = 14;
            Text = Text;
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            });
        end

        Label.TextLabel = TextLabel;
        Label.Container = Container;

        function Label:SetText(Text)
            TextLabel.Text = Text

            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end

            Groupbox:Resize();
        end

        if (not DoesWrap) then
            setmetatable(Label, BaseAddons);
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Label;
    end;

    function Funcs:AddButton(...)
        local Button = {};
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end

            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
        end

        ProcessButtonParams('Button', Button, ...)

        local Groupbox = self;
        local Container = Groupbox.Container;

        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -4, 0, 20);
                ZIndex = 5;
            });

            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer;
            });

            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = 14;
                Text = Button.Text;
                ZIndex = 6;
                Parent = Inner;
            });

            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
                });
                Rotation = 90;
                Parent = Inner;
            });

            Library:AddToRegistry(Outer, {
                BorderColor3 = 'Black';
            });

            Library:AddToRegistry(Inner, {
                BackgroundColor3 = 'MainColor';
                BorderColor3 = 'OutlineColor';
            });

            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'Black' }
            );

            return Outer, Inner, Label
        end

        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local co = coroutine.running()
                local fired = false
                local connection
                connection = event:Once(function(...)
                    if fired then return end
                    fired = true
                    connection = nil
                    local ok = type(validator) == 'function' and validator(...)
                    task.spawn(co, ok and true or false)
                end)
                task.delay(timeout, function()
                    if fired then return end
                    fired = true
                    if connection then connection:Disconnect() end
                    task.spawn(co, false)
                end)
                return coroutine.yield()
            end

            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then
                    return false
                end

                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                    return false
                end

                return true
            end

            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end
                if Button.Locked then return end

                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' })

                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = 'Are you sure?'
                    Button.Locked = true

                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })

                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)

                    if clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    return
                end

                Library:SafeCallback(Button.Func);
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        InitEvents(Button)

        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then
                Library:AddToolTip(tooltip, self.Outer)
            end
            return self
        end


        function Button:AddButton(...)
            local SubButton = {}

            ProcessButtonParams('SubButton', SubButton, ...)

            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)

            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer

            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then
                    Library:AddToolTip(tooltip, self.Outer)
                end
                return SubButton
            end

            if type(SubButton.Tooltip) == 'string' then
                SubButton:AddTooltip(SubButton.Tooltip)
            end

            InitEvents(SubButton)
            return SubButton
        end

        if type(Button.Tooltip) == 'string' then
            Button:AddTooltip(Button.Tooltip)
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Button;
    end;

    function Funcs:AddDivider()
        local Groupbox = self;
        local Container = self.Container

        local Divider = {
            Type = 'Divider',
        }

        Groupbox:AddBlank(2);
        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 5);
            ZIndex = 5;
            Parent = Container;
        });

        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DividerOuter;
        });

        Library:AddToRegistry(DividerOuter, {
            BorderColor3 = 'Black';
        });

        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Groupbox:AddBlank(9);
        Groupbox:Resize();
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        Groupbox:AddBlank(1);

        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });

        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        });

        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, TextBoxOuter)
        end

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = TextBoxInner;
        });

        local Container = Library:Create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants = true;

            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);

            ZIndex = 7;
            Parent = TextBoxInner;
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = Info.Placeholder or '';

            Text = Info.Default or '';
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            AutoLocalize = false;

            ZIndex = 7;
            Parent = Container;
        });

        Library:ApplyTextStroke(Box);

        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength);
            end;

            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Textbox.Value
                end
            end

            Textbox.Value = Text;
            Box.Text = Text;

            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed, Textbox.Value);
        end;

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end

                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        end

        local function Update()
            local PADDING = 2
            local reveal = Container.AbsoluteSize.X

            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

                    local currentCursorPos = Box.Position.X.Offset + width

                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end

        task.spawn(Update)

        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, {
            TextColor3 = 'FontColor';
        });

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func;
            Func(Textbox.Value);
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        Options[Idx] = Textbox;

        return Textbox;
    end;

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddToggle: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';

            Callback = Info.Callback or function(Value) end;
            Addons = {},
            Risky = Info.Risky,
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black';
        });

        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        });

        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local ToggleGradient = Library:AddAccentGradient(ToggleInner, function() return Toggle.Value end);
        local ToggleGlow = Library:AddGlow(ToggleOuter, { Cond = function() return Toggle.Value end });

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0);
            Position = UDim2.new(1, 6, 0, 0);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleInner;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        });

        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 170, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        });

        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        function Toggle:UpdateColors()
            Toggle:Display();
        end;

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRegion)
        end

        function Toggle:Display()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentFill or Library.MainColor;
            ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentFill' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';

            ToggleGradient.Enabled = Library.GradientEnabled and Toggle.Value;
            ToggleGlow.Visible = Library.GlowEnabled and Toggle.Value;
        end;

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func(Toggle.Value);
        end;

        function Toggle:SetValue(Bool)
            Bool = (not not Bool);

            Toggle.Value = Bool;
            Toggle:Display();

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;

        ToggleRegion.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value)
                Library:AttemptSave();
            end;
        end);

        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
        end

        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();

        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);

        Toggles[Idx] = Toggle;

        Library:UpdateDependencyBoxes();

        return Toggle;
    end;

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default ~= nil, 'AddSlider: Missing default value.');
        assert(Info.Text, 'AddSlider: Missing slider text.');
        assert(Info.Min ~= nil, 'AddSlider: Missing minimum value.');
        assert(Info.Max ~= nil, 'AddSlider: Missing maximum value.');
        assert(Info.Rounding ~= nil, 'AddSlider: Missing rounding value.');

        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type = 'Slider';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = 'Black';
        });

        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = SliderOuter;
        });

        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentFill;
            BorderColor3 = Library.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner;
        });

        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentFill';
            BorderColor3 = 'AccentColorDark';
        });

        Library:AddAccentGradient(Fill);
        local FillGlow = Library:AddGlow(Fill, { SizeMul = 0.6; Cond = function() return Fill.Size.X.Offset > 0 end });

        local function GetHideBorderColor()
            return Library.GradientEnabled and Library.AccentColor2 or Library.AccentColor;
        end;

        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = GetHideBorderColor();
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = 8;
            Parent = Fill;
        });

        Library:AddToRegistry(HideBorderRight, {
            BackgroundColor3 = GetHideBorderColor;
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 14;
            Text = 'Infinite';
            ZIndex = 9;
            Parent = SliderInner;
        });

        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter)
        end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentFill;
            Fill.BorderColor3 = Library.AccentColorDark;
        end;

        function Slider:Display()
            local Suffix = Info.Suffix or '';

            if Info.Compact then
                DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
            elseif Info.HideMax then
                DisplayLabel.Text = string.format('%s', Slider.Value .. Suffix)
            else
                DisplayLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix);
            end

            local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize));
            Fill.Size = UDim2.new(0, X, 1, 0);

            HideBorderRight.Visible = not (X == Slider.MaxSize or X == 0);
            FillGlow.Visible = Library.GlowEnabled and X > 0;
        end;

        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func(Slider.Value);
        end;

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value);
            end;


            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end;

        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max));
        end;

        function Slider:SetValue(Str)
            local Num = tonumber(Str);

            if (not Num) then
                return;
            end;

            Num = math.clamp(Num, Slider.Min, Slider.Max);

            Slider.Value = Num;
            Slider:Display();

            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed, Slider.Value);
        end;

        SliderInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                local mPos = Mouse.X;
                local gPos = Fill.Size.X.Offset;
                local Diff = mPos - (Fill.AbsolutePosition.X + gPos);

                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local nMPos = Mouse.X;
                    local nX = math.clamp(gPos + (nMPos - mPos) + Diff, 0, Slider.MaxSize);

                    local nValue = Slider:GetValueFromXOffset(nX);
                    local OldValue = Slider.Value;
                    Slider.Value = nValue;

                    Slider:Display();

                    if nValue ~= OldValue then
                        Library:SafeCallback(Slider.Callback, Slider.Value);
                        Library:SafeCallback(Slider.Changed, Slider.Value);
                    end;

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();

        Options[Idx] = Slider;

        return Slider;
    end;

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString();
            Info.AllowNull = true;
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString();
            Info.AllowNull = true;
        end;

        assert(Info.Values, 'AddDropdown: Missing dropdown value list.');
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

        if (not Info.Text) then
            Info.Compact = true;
        end;

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
            SpecialType = Info.SpecialType;
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        if not Info.Compact then
            local DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end

        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = 'Black';
        });

        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        });

        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = DropdownInner;
        });

        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex = 8;
            Parent = DropdownInner;
        });

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = 14;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            ZIndex = 7;
            Parent = DropdownInner;
        });

        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, DropdownOuter)
        end

        local MAX_DROPDOWN_ITEMS = 8;

        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui;
        });

        local DesiredListHeight = MAX_DROPDOWN_ITEMS * 20 + 2;

        local function RecalculateListPosition()
            local Screen   = ScreenGui.AbsoluteSize;
            local DropPos  = DropdownOuter.AbsolutePosition;
            local DropSize = DropdownOuter.AbsoluteSize;

            local Width  = DropSize.X;
            local Height = DesiredListHeight;

            local Below = Screen.Y - (DropPos.Y + DropSize.Y) - 1;
            local Above = DropPos.Y - 1;
            local GoUp  = false;

            if Height > Below then
                if Height <= Above or Above > Below then
                    GoUp = true;
                end;
                local Space = GoUp and Above or Below;
                if Screen.Y > 0 and Height > Space then
                    Height = math.max(22, Space);
                end;
            end;

            local X = DropPos.X;
            if Screen.X > 0 then
                X = math.clamp(X, 0, math.max(0, Screen.X - Width));
            end;

            local Y = GoUp and (DropPos.Y - Height - 1) or (DropPos.Y + DropSize.Y + 1);

            ListOuter.Size = UDim2.fromOffset(Width, Height);
            ListOuter.Position = UDim2.fromOffset(X, Y);
        end;

        local function RecalculateListSize(YSize)
            DesiredListHeight = YSize or (MAX_DROPDOWN_ITEMS * 20 + 2);
            RecalculateListPosition();
        end;

        RecalculateListPosition();
        RecalculateListSize();

        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            RecalculateListPosition()
            if ListOuter.Visible then
                Dropdown:CloseDropdown()
            end
        end);

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        });

        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        });

        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = 'AccentColor'
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        });

        function Dropdown:Display()
            local Str;

            if Info.Multi then
                local parts = {};
                local Values = Dropdown.Values;
                for i = 1, #Values do
                    local v = Values[i];
                    if Dropdown.Value[v] then
                        parts[#parts + 1] = v;
                    end;
                end;
                Str = #parts > 0 and table.concat(parts, ', ') or '';
            else
                Str = Dropdown.Value or '';
            end;

            ItemList.Text = (Str == '' and '--' or Str);
        end;

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local count = 0;
                for _ in next, Dropdown.Value do count = count + 1 end;
                return count;
            else
                return Dropdown.Value and 1 or 0;
            end;
        end;

        local _lastBuiltValues = nil;

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values;

            if Values == _lastBuiltValues then
                Dropdown:Display();
                return;
            end;
            _lastBuiltValues = Values;

            local Buttons = {};

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    Element:Destroy();
                end;
            end;

            local Count = 0;

            for Idx, Value in next, Values do
                local Table = {};

                Count = Count + 1;

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    ZIndex = 23;
                    Active = true,
                    Parent = Scrolling;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = 14;
                    Text = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 25;
                    Parent = Button;
                });

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                );

                local Selected;

                if Info.Multi then
                    Selected = Dropdown.Value[Value];
                else
                    Selected = Dropdown.Value == Value;
                end;

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value];
                    else
                        Selected = Dropdown.Value == Value;
                    end;

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
                end;

                ButtonLabel.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local Try = not Selected;

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value[Value] = true;
                                else
                                    Dropdown.Value[Value] = nil;
                                end;
                            else
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value = Value;
                                else
                                    Dropdown.Value = nil;
                                end;

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton();
                                end;
                            end;

                            Table:UpdateButton();
                            Dropdown:Display();

                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);

                            Library:AttemptSave();
                        end;
                    end;
                end);

                Table:UpdateButton();
                Dropdown:Display();

                Buttons[Button] = Table;
            end;

            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1);

            local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1;
            RecalculateListSize(Y);
        end;

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues;
            end;

            Dropdown:BuildDropdownList();
        end;

        function Dropdown:OpenDropdown()
            RecalculateListPosition();
            ListOuter.Visible = true;
            Library.OpenedFrames[ListOuter] = true;
            DropdownArrow.Rotation = 180;
        end;

        function Dropdown:CloseDropdown()
            ListOuter.Visible = false;
            Library.OpenedFrames[ListOuter] = nil;
            DropdownArrow.Rotation = 0;
        end;

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func;
            Func(Dropdown.Value);
        end;

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {};

                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true
                    end;
                end;

                Dropdown.Value = nTable;
            else
                if (not Val) then
                    return;
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val;
                else
                    return;
                end;
            end;

            Dropdown:BuildDropdownList();

            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
        end;

        DropdownOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown();
                else
                    Dropdown:OpenDropdown();
                end;
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                if not ListOuter.Visible then return end;

                if not Library:IsMouseOverFrame(ListOuter) and not Library:IsMouseOverFrame(DropdownOuter) then
                    Dropdown:CloseDropdown();
                end;
            end;
        end));

        Dropdown:BuildDropdownList();
        Dropdown:Display();

        local Defaults = {}

        if type(Info.Default) == 'string' then
            local Idx = table.find(Dropdown.Values, Info.Default)
            if Idx then
                table.insert(Defaults, Idx)
            end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local Idx = table.find(Dropdown.Values, Value)
                if Idx then
                    table.insert(Defaults, Idx)
                end
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index];
                end

                if (not Info.Multi) then break end
            end

            Dropdown:BuildDropdownList();
            Dropdown:Display();
        end

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        Options[Idx] = Dropdown;

        if Info.SpecialType == 'Player' and Library._RegisterPlayerDropdown then
            Library._RegisterPlayerDropdown(Dropdown)
        end

        return Dropdown;
    end;

    function Funcs:AddDependencyBox()
        local Depbox = {
            Dependencies = {};
        };
        
        local Groupbox = self;
        local Container = Groupbox.Container;

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = Container;
        });

        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder;
        });

        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame;
        });

        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
            Groupbox:Resize();
        end;

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Depbox:Resize();
        end);

        Holder:GetPropertyChangedSignal('Visible'):Connect(function()
            Depbox:Resize();
        end);

        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1];
                local Value = Dependency[2];

                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false;
                    Depbox:Resize();
                    return;
                end;
            end;

            Holder.Visible = true;
            Depbox:Resize();
        end;

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.');
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.');
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.');
            end;

            Depbox.Dependencies = Dependencies;
            Depbox:Update();
        end;

        Depbox.Container = Frame;

        setmetatable(Depbox, BaseGroupbox);

        table.insert(Library.DependencyBoxes, Depbox);

        return Depbox;
    end;

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 40);
        Size = UDim2.new(0, 300, 0, 200);
        ZIndex = 100;
        Parent = ScreenGui;
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.NotificationArea;
    });

    local WatermarkOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, -25);
        Size = UDim2.new(0, 213, 0, 20);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });

    Library:AddToRegistry(WatermarkInner, {
        BorderColor3 = 'AccentColor';
    });

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = WatermarkInner;
    });

    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library.MainColorDark),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });

    Library:AddToRegistry(Gradient, {
        Color = GetMainGradient
    });

    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = 14;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = InnerFrame;
    });

    Library:AddGlow(WatermarkOuter, { ZIndex = 199; SizeMul = 0.8 });
    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);



    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 210, 0, 20);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    });

    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    });

    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    local ColorFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentFill;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 102;
        Parent = KeybindInner;
    });

    Library:AddToRegistry(ColorFrame, {
        BackgroundColor3 = 'AccentFill';
    }, true);
    Library:AddAccentGradient(ColorFrame, nil, 0);

    local KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20);
        Position = UDim2.fromOffset(5, 2),
        TextXAlignment = Enum.TextXAlignment.Left,

        Text = 'Keybinds';
        ZIndex = 104;
        Parent = KeybindInner;
    });

    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20);
        ZIndex = 1;
        Parent = KeybindInner;
    });

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });

    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        Parent = KeybindContainer,
    })

    Library.KeybindFrame = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;
    Library:MakeDraggable(KeybindOuter);
end;

function Library:SetWatermarkVisibility(Bool)
    Library.Watermark.Visible = Bool;
end;

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, 14);
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3);
    Library:SetWatermarkVisibility(true)

    Library.WatermarkText.Text = Text;
end;

function Library:Notify(Text, Time)
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14);

    YSize = YSize + 7

    local NotifyOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, 10);
        Size = UDim2.new(0, 0, 0, YSize);
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = Library.NotificationArea;
    });

    local NotifyInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(NotifyInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 102;
        Parent = NotifyInner;
    });

    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library.MainColorDark),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });

    Library:AddToRegistry(Gradient, {
        Color = GetMainGradient
    });

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        Text = Text;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize = 14;
        ZIndex = 103;
        Parent = InnerFrame;
    });

    local LeftColor = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentFill;
        BorderSizePixel = 0;
        Position = UDim2.new(0, -1, 0, -1);
        Size = UDim2.new(0, 3, 1, 2);
        ZIndex = 104;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(LeftColor, {
        BackgroundColor3 = 'AccentFill';
    }, true);
    Library:AddAccentGradient(LeftColor, nil, 90);
    Library:AddGlow(NotifyOuter, { SizeMul = 0.7 });

    pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + 8 + 4, 0, YSize), 'Out', 'Quad', 0.4, true);

    task.spawn(function()
        task.wait(Time or 5);

        pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', 0.4, true);

        task.wait(0.4);

        NotifyOuter:Destroy();
    end);
end;

function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false;
    end

    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 0 end

    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(550, 600) end

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end

    local Window = {
        Tabs = {};
    };

    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderSizePixel = 0;
        Position = Config.Position,
        Size = Config.Size,
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
    });

    Library:MakeDraggable(Outer, 25);

    Library._BackgroundImage = Library:Create('ImageLabel', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 1, 0);
        Position = UDim2.new(0, 0, 0, 0);
        Image = '';
        ScaleType = Enum.ScaleType.Crop;
        ZIndex = 1;
        Visible = false;
        Parent = Outer;
    });

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = Outer;
    });

    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'AccentColor';
    });

    Library._WindowInner = Inner;
    Library._WindowOuter = Outer;
    Library._WindowGlow = Library:AddGlow(Outer, { ZIndex = 0; SizeMul = 1.5 });

    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 7, 0, 0);
        Size = UDim2.new(0, 0, 0, 25);
        Text = Config.Title or '';
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 1;
        Parent = Inner;
    });

    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 25);
        Size = UDim2.new(1, -16, 1, -33);
        ZIndex = 1;
        Parent = Inner;
    });

    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });

    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    });

    Library:AddToRegistry(MainSectionInner, {
        BackgroundColor3 = 'BackgroundColor';
    });

    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 8, 0, 8);
        Size = UDim2.new(1, -16, 0, 21);
        ZIndex = 1;
        Parent = MainSectionInner;
    });

    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, Config.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea;
    });

    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 30);
        Size = UDim2.new(1, -16, 1, -38);
        ZIndex = 2;
        Parent = MainSectionInner;
    });
    

    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    Library._MainSectionOuter = MainSectionOuter;
    Library._MainSectionInner = MainSectionInner;
    Library._TabContainer = TabContainer;

    Library._MainSectionOuter = MainSectionOuter;
    Library._MainSectionInner = MainSectionInner;
    Library._TabContainer = TabContainer;

    function Window:SetWindowTitle(Title)
        WindowLabel.Text = Title;
    end;

    function Window:AddTab(Name)
        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
        };

        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 16);

        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0);
            ZIndex = 1;
            Parent = TabArea;
        });

        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        function Tab:_UpdateWidth()
            local W = Library:GetTextBounds(Name, Library.Font, 16);
            TabButton.Size = UDim2.new(0, W + 8 + 4, 1, 0);
        end;

        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, -1);
            Text = Name;
            ZIndex = 1;
            Parent = TabButton;
        });

        local Blocker = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 1, 0);
            Size = UDim2.new(1, 0, 0, 1);
            BackgroundTransparency = 1;
            ZIndex = 3;
            Parent = TabButton;
        });

        Library:AddToRegistry(Blocker, {
            BackgroundColor3 = 'MainColor';
        });

        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        });

        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -18);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });

        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -18);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide;
        });

        for _, Side in next, { LeftSide, RightSide } do
            local Layout = Side:WaitForChild('UIListLayout', 5);
            Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y);
            end);
        end;

        function Tab:ShowTab()
            for _, Tab in next, Window.Tabs do
                Tab:HideTab();
            end;

            Blocker.BackgroundTransparency = 0;
            TabButton.BackgroundColor3 = Library.MainColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor';
            TabFrame.Visible = true;
        end;

        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1;
            TabButton.BackgroundColor3 = Library.BackgroundColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor';
            TabFrame.Visible = false;
        end;

        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position;
            TabListLayout:ApplyLayout();
        end;

        function Tab:AddGroupbox(Info)
            local Groupbox = {};

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 507 + 2);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentFill;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 5;
                Parent = BoxInner;
            });

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentFill';
            });
            Library:AddAccentGradient(Highlight, nil, 0);

            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 4, 0, 2);
                TextSize = 14;
                Text = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 5;
                Parent = BoxInner;
            });

            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 4, 0, 20);
                Size = UDim2.new(1, -4, 1, -20);
                ZIndex = 1;
                Parent = BoxInner;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            });

            local _containerLayout = Container:WaitForChild('UIListLayout', 1) or Container:FindFirstChildWhichIsA('UIListLayout');

            function Groupbox:Resize()
                local Size = _containerLayout and _containerLayout.AbsoluteContentSize.Y or 0;
                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 4);
            end;

            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);

            Groupbox:AddBlank(3);
            Groupbox:Resize();

            Tab.Groupboxes[Info.Name] = Groupbox;

            return Groupbox;
        end;

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; });
        end;

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; });
        end;

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
                _TabCount = 0;
            };

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentFill;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 10;
                Parent = BoxInner;
            });

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentFill';
            });
            Library:AddAccentGradient(Highlight, nil, 0);

            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 5;
                Parent = BoxInner;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            });

            function Tabbox:AddTab(Name)
                local Tab = {};

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = 14;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                });

                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                });

                Library:AddToRegistry(Block, {
                    BackgroundColor3 = 'BackgroundColor';
                });

                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 4, 0, 20);
                    Size = UDim2.new(1, -4, 1, -20);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                });

                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                });

                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide();
                    end;

                    Container.Visible = true;
                    Block.Visible = true;

                    Button.BackgroundColor3 = Library.BackgroundColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';

                    Tab:Resize();
                end;

                function Tab:Hide()
                    Container.Visible = false;
                    Block.Visible = false;

                    Button.BackgroundColor3 = Library.MainColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                end;

                local _tabContainerLayout = Container:FindFirstChildWhichIsA('UIListLayout');

                function Tab:Resize()
                    local TabCount = Tabbox._TabCount;
                    local newSize = UDim2.new(1 / TabCount, 0, 1, 0);

                    for _, Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA('UIListLayout') then
                            Button.Size = newSize;
                        end;
                    end;

                    if not Container.Visible then return end;

                    local Size = _tabContainerLayout and _tabContainerLayout.AbsoluteContentSize.Y or 0;
                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 4);
                end;

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show();
                        Tab:Resize();
                    end;
                end);

                Tab.Container = Container;
                Tabbox.Tabs[Name] = Tab;
                Tabbox._TabCount = Tabbox._TabCount + 1;

                setmetatable(Tab, BaseGroupbox);

                Tab:AddBlank(3);
                Tab:Resize();

                if Tabbox._TabCount == 1 then
                    Tab:Show();
                end;

                return Tab;
            end;

            Tab.Tabboxes[Info.Name or ''] = Tabbox;

            return Tabbox;
        end;

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; });
        end;

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; });
        end;

        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                for Frame, _ in next, Library.OpenedFrames do
                    Frame.Visible = false;
                end;
                table.clear(Library.OpenedFrames);
                Tab:ShowTab();
            end;
        end);

        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab();
        end;

        Window.Tabs[Name] = Tab;
        return Tab;
    end;

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    });

    local Toggled = false;

    function Library:Toggle()
        Toggled = not Toggled;
        ModalElement.Modal = Toggled;
        Outer.Visible = Toggled;

        if not Toggled then
            for Frame, _ in next, Library.OpenedFrames do
                Frame.Visible = false;
            end;
            table.clear(Library.OpenedFrames);
        end;

        if Toggled then
            InputService.MouseIconEnabled = true;
            InputService.MouseBehavior = Enum.MouseBehavior.Default;
        end;
    end;

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(function() Library:Toggle() end)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            task.spawn(function() Library:Toggle() end)
        end
    end))

    if Config.AutoShow then task.spawn(function() Library:Toggle() end) end

    Window.Holder = Outer;
    Library._Window = Window;

    return Window;
end;

local _PlayerDropdowns = {}

local function OnPlayerChange()
    local PlayerList = GetPlayersString();
    for i = 1, #_PlayerDropdowns do
        _PlayerDropdowns[i]:SetValues(PlayerList);
    end;
end;

Library._RegisterPlayerDropdown = function(dropdown)
    _PlayerDropdowns[#_PlayerDropdowns + 1] = dropdown
end

Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);

function Library:SetBackground(decalId)
    local Inner = Library._WindowInner;
    local Outer = Library._WindowOuter;
    local MSO = Library._MainSectionOuter;
    local MSI = Library._MainSectionInner;
    local TC = Library._TabContainer;
    if not Inner then return end;

    if not decalId or decalId == '' then
        if Library._BackgroundImage then
            Library._BackgroundImage.Visible = false;
            Library._BackgroundImage.Image = '';
        end
        if Library._BackgroundStroke then
            Library._BackgroundStroke:Destroy();
            Library._BackgroundStroke = nil;
        end
        Outer.BackgroundTransparency = 0;
        Inner.BackgroundTransparency = 0;
        Inner.BorderSizePixel = 1;
        Library:RemoveFromRegistry(Inner);
        Library:AddToRegistry(Inner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'AccentColor';
        });
        if MSO then MSO.BackgroundTransparency = 0; MSO.BorderSizePixel = 1; end;
        if MSI then MSI.BackgroundTransparency = 0; MSI.BorderSizePixel = 1; end;
        if TC then TC.BackgroundTransparency = 0; TC.BorderSizePixel = 1; end;
        for i = 1, #Library.Registry do
            local data = Library.Registry[i];
            if data then
                local inst = data.Instance;
                local props = data.Properties;
                local skip = {[Inner]=true,[MSO]=true,[MSI]=true,[TC]=true};
                if not skip[inst] and props.BackgroundColor3 == 'BackgroundColor' then
                    pcall(function()
                        inst.BackgroundTransparency = 0;
                        inst.BorderSizePixel = 1;
                    end);
                end;
            end;
        end;
        return;
    end;

    Outer.BackgroundTransparency = 1;
    Inner.BackgroundTransparency = 1;
    Inner.BorderSizePixel = 0;
    Library:RemoveFromRegistry(Inner);
    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor';
    });
    if MSO then MSO.BackgroundTransparency = 1; MSO.BorderSizePixel = 0; end;
    if MSI then MSI.BackgroundTransparency = 1; MSI.BorderSizePixel = 0; end;
    if TC then TC.BackgroundTransparency = 1; TC.BorderSizePixel = 0; end;
    for i = 1, #Library.Registry do
        local data = Library.Registry[i];
        if data then
            local inst = data.Instance;
            local props = data.Properties;
            local skip = {[Inner]=true,[MSO]=true,[MSI]=true,[TC]=true};
            if not skip[inst] and props.BackgroundColor3 == 'BackgroundColor' then
                pcall(function()
                    inst.BackgroundTransparency = 0.5;
                    inst.BorderSizePixel = 0;
                end);
            end;
        end;
    end;

    if not Library._BackgroundStroke then
        Library._BackgroundStroke = Library:Create('UIStroke', {
            Color = Library.AccentColor;
            Thickness = 1;
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Parent = Outer;
        });
        Library:AddToRegistry(Library._BackgroundStroke, { Color = 'AccentColor' });
    end;

    local cleanId = tostring(decalId):gsub('%s+', '');
    local imageToSet = nil;
    local ok, result = pcall(function()
        return game:GetObjects('rbxassetid://' .. cleanId)
    end)
    if ok and result and result[1] and typeof(result[1]) ~= 'string' then
        local obj = result[1]
        if obj:IsA('Decal') then
            imageToSet = obj.Texture;
        elseif obj:IsA('ImageLabel') or obj:IsA('ImageButton') then
            imageToSet = obj.Image;
        else
            imageToSet = 'rbxassetid://' .. cleanId;
        end
    else
        imageToSet = 'rbxassetid://' .. cleanId;
    end

    Library._BackgroundImage.Image = imageToSet;
    Library._BackgroundImage.Visible = true;
end;

Library.FontList = {
    'Code', 'RobotoMono', 'Gotham', 'GothamMedium', 'GothamBold', 'GothamBlack',
    'SourceSans', 'SourceSansSemibold', 'SourceSansBold', 'Ubuntu', 'Roboto',
    'Arial', 'ArialBold', 'Montserrat', 'Nunito', 'Oswald', 'Highway',
    'Jura', 'Michroma', 'Fondamento', 'Merriweather', 'Bangers', 'Antique',
    'SciFi', 'Arcade', 'Fantasy', 'Cartoon', 'Bodoni', 'Garamond',
};

do
    local ok = {};
    for _, Name in ipairs(Library.FontList) do
        if Enum.Font[Name] ~= nil then ok[#ok + 1] = Name end;
    end;
    Library.FontList = ok;
end;

local _BaseTextSize = setmetatable({}, { __mode = 'k' });

local function _IsText(Obj)
    return Obj:IsA('TextLabel') or Obj:IsA('TextButton') or Obj:IsA('TextBox');
end;

local function _ApplyText(Obj)
    if not _IsText(Obj) then return end;
    local Base = _BaseTextSize[Obj];
    if not Base then
        Base = Obj.TextSize;
        _BaseTextSize[Obj] = Base;
    end;
    Obj.Font = Library.Font;
    Obj.TextSize = math.max(1, math.floor(Base * Library.TextScale + 0.5));
end;

ScreenGui.DescendantAdded:Connect(function(Obj)
    if _IsText(Obj) then
        task.defer(function()
            if Obj.Parent then _ApplyText(Obj) end;
        end);
    end;
end);

function Library:_ApplyTextToAll()
    for _, Obj in ipairs(ScreenGui:GetDescendants()) do
        _ApplyText(Obj);
    end;

    local Win = Library._Window;
    if Win then
        for _, Tab in next, Win.Tabs do
            if Tab._UpdateWidth then Tab:_UpdateWidth() end;
        end;
    end;
end;

function Library:SetFont(Font)
    if type(Font) == 'string' then
        Font = Enum.Font[Font];
    end;
    if typeof(Font) ~= 'EnumItem' or Font.EnumType ~= Enum.Font then
        return warn('[Library] SetFont: неизвестный шрифт');
    end;

    Library.Font = Font;
    Library:_ApplyTextToAll();
end;

function Library:SetTextScale(Scale)
    Scale = math.clamp(tonumber(Scale) or 1, Library.MinTextScale, Library.MaxTextScale);
    Library.TextScale = Scale;
    Library:_ApplyTextToAll();
end;

function Library:SetAllowOverlap(Bool)
    Library.AllowOverlap = Bool and true or false;
end;

function Library:SetMenuSize(Width, Height)
    local Outer = Library._WindowOuter;
    if not Outer then return end;

    if typeof(Width) == 'Vector2' then
        Width, Height = Width.X, Width.Y;
    end;

    local Cam = workspace.CurrentCamera;
    local MaxW = Cam and (Cam.ViewportSize.X - 20) or 1920;
    local MaxH = Cam and (Cam.ViewportSize.Y - 20) or 1080;

    Width  = math.clamp(math.floor(tonumber(Width)  or 550), 350, math.max(350, MaxW));
    Height = math.clamp(math.floor(tonumber(Height) or 600), 250, math.max(250, MaxH));

    Outer.Size = UDim2.fromOffset(Width, Height);
end;

function Library:AddUISettings(Tab, Side)
    local Box = (Side == 'Right') and Tab:AddRightGroupbox('Menu size & font')
                                   or Tab:AddLeftGroupbox('Menu size & font');

    local Outer = Library._WindowOuter;
    local CurW = Outer and Outer.Size.X.Offset or 550;
    local CurH = Outer and Outer.Size.Y.Offset or 600;

    Box:AddSlider('UI_MenuWidth', {
        Text = 'Menu width', Default = CurW, Min = 400, Max = 1200, Rounding = 0, Suffix = 'px',
        Callback = function(V) Library:SetMenuSize(V, Options.UI_MenuHeight and Options.UI_MenuHeight.Value or CurH) end,
    });

    Box:AddSlider('UI_MenuHeight', {
        Text = 'Menu height', Default = CurH, Min = 300, Max = 1000, Rounding = 0, Suffix = 'px',
        Callback = function(V) Library:SetMenuSize(Options.UI_MenuWidth and Options.UI_MenuWidth.Value or CurW, V) end,
    });

    Box:AddSlider('UI_TextScale', {
        Text = 'Font size', Default = 100, Min = Library.MinTextScale * 100, Max = Library.MaxTextScale * 100,
        Rounding = 0, Suffix = '%',
        Callback = function(V) Library:SetTextScale(V / 100) end,
    });

    Box:AddDropdown('UI_Font', {
        Text = 'Font', Values = Library.FontList,
        Default = table.find(Library.FontList, Library.Font.Name) or 1,
        Callback = function(V) Library:SetFont(V) end,
    });

    Box:AddToggle('UI_AllowOverlap', {
        Text = 'Allow windows overlap', Default = true,
        Callback = function(V) Library:SetAllowOverlap(V) end,
    });

    Library:_AddGlowGradientToBox(Box);

    return Box;
end;

function Library:_AddGlowGradientToBox(Box)
    Box:AddDivider();

    Box:AddToggle('UI_GlowEnabled', {
        Text = 'Glow', Default = Library.GlowEnabled,
        Callback = function(V) Library:SetGlow(V) end,
    });

    Box:AddSlider('UI_GlowSize', {
        Text = 'Size', Default = Library.GlowSize, Min = 1, Max = 20, Rounding = 0, Suffix = 'px',
        Callback = function(V) Library:SetGlow(nil, V) end,
    });

    Box:AddSlider('UI_GlowIntensity', {
        Text = 'Intensity', Default = Library.GlowIntensity, Min = 10, Max = 35, Rounding = 0, Suffix = '%',
        Callback = function(V) Library:SetGlow(nil, nil, V) end,
    });

    Box:AddToggle('UI_GlowFollowAccent', {
        Text = 'Accent', Default = Library.GlowFollowAccent,
        Callback = function(V) Library.GlowFollowAccent = V; Library:UpdateGlows() end,
    });

    Box:AddLabel('Glow color'):AddColorPicker('UI_GlowColor', {
        Default = Library.GlowColor, Title = 'Color Glow',
        Callback = function(C) Library.GlowColor = C; Library:UpdateGlows() end,
    });

    Box:AddDivider();

    Box:AddToggle('UI_GradientEnabled', {
        Text = 'Accent gradient', Default = Library.GradientEnabled,
        Callback = function(V) Library:SetGradient(V) end,
    });

    Box:AddLabel('Gradient color 2'):AddColorPicker('UI_GradientColor2', {
        Default = Library.AccentColor2, Title = 'Gradient end color',
        Callback = function(C) Library:SetGradient(nil, C) end,
    });

    Box:AddSlider('UI_GradientRotation', {
        Text = 'Angle', Default = Library.GradientRotation, Min = 0, Max = 360, Rounding = 0, Suffix = '°',
        Callback = function(V) Library:SetGradient(nil, nil, V) end,
    });

    return Box;
end;

function Library:AddGlowGradientSettings(Tab, Side)
    local Box = (Side == 'Right') and Tab:AddRightGroupbox('Glow & gradient')
                                   or Tab:AddLeftGroupbox('Glow & gradient');
    return Library:_AddGlowGradientToBox(Box);
end;

getgenv().Library = Library
return Library
