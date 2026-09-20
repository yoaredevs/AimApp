--[[
    ==========================================================
     yoaredevs | Phone GUI Hub
     Celular flutuante com apps: Info Server, Player Configs,
     ScriptBlox API. Sistema de notificação (popup deslizante)
     e animações de abrir/fechar.
     Compatível com executores (Synapse/Script-Ware/Fluxus/etc)
    ==========================================================
]]

local _ok, _err = xpcall(function()

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local StarterGui        = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==========================================================
-- CONFIG
-- ==========================================================
local CONFIG = {
    ScriptBloxSearchURL = "https://scriptblox.com/api/script/search?q=",
    AccentColor  = Color3.fromRGB(56, 189, 248),
    AccentSoft   = Color3.fromRGB(18, 48, 66),
    SuccessColor = Color3.fromRGB(52, 211, 153),
    WarningColor = Color3.fromRGB(251, 191, 36),
    DangerColor  = Color3.fromRGB(248, 113, 113),
    InfoColor    = Color3.fromRGB(96, 165, 250),
    BgColor      = Color3.fromRGB(10, 11, 16),
    CardColor    = Color3.fromRGB(22, 24, 32),
    CardHover    = Color3.fromRGB(31, 34, 45),
    TextColor    = Color3.fromRGB(245, 246, 250),
    SubTextColor = Color3.fromRGB(145, 150, 165),
    BorderColor  = Color3.fromRGB(65, 68, 84),
}

-- request cross-executor
local httpRequest = (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request) or request or http_request

-- clipboard cross-executor
local setClipboard = setclipboard or toclipboard or function() end

-- ==========================================================
-- ROOT GUI
-- ==========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "yoaredevs_Phone"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

local function resolveGuiParent()
    if gethui then
        return gethui()
    end
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        return game:GetService("CoreGui")
    end
    local coreGuiOk = pcall(function()
        local probe = Instance.new("ScreenGui")
        probe.Parent = game:GetService("CoreGui")
        probe:Destroy()
    end)
    if coreGuiOk then
        return game:GetService("CoreGui")
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

ScreenGui.Parent = resolveGuiParent()

-- ==========================================================
-- HELPERS
-- ==========================================================

-- Forward declaration: precisa existir ANTES de qualquer bloco que chame
-- lucideIcon (ex: sistema de notificações), senão essas chamadas capturam
-- a variável global "lucideIcon" (nil) em vez do valor atribuído mais abaixo,
-- e cada notificação/ícone quebra com "attempt to call a nil value".
local lucideIcon

local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function corner(radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

local function stroke(color, thickness)
    return create("UIStroke", {
        Color = color or CONFIG.AccentColor,
        Thickness = thickness or 1,
        Transparency = 0.4,
    })
end

local function tween(obj, props, time, style, dir)
    local t = TweenService:Create(obj, TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function scaleObject(parent, scale)
    local s = parent:FindFirstChildOfClass("UIScale")
    if not s then
        s = Instance.new("UIScale")
        s.Parent = parent
    end
    s.Scale = scale or 1
    return s
end

local function buttonPress(btn, target, normalSize)
    btn.MouseButton1Down:Connect(function()
        tween(target, {Size = UDim2.new(1, -8, 1, -8)}, 0.08, Enum.EasingStyle.Quad)
    end)
    btn.MouseButton1Up:Connect(function()
        tween(target, {Size = normalSize}, 0.16, Enum.EasingStyle.Back)
    end)
end

local function addHover(btn, normalColor, hoverColor)
    if not UserInputService.TouchEnabled then
        btn.MouseEnter:Connect(function()
            tween(btn, {BackgroundColor3 = hoverColor}, 0.12)
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, {BackgroundColor3 = normalColor}, 0.16)
        end)
    end
end

-- ==========================================================
-- FLOATING BUBBLE
-- ==========================================================
local Bubble = create("TextButton", {
    Name = "Bubble",
    Parent = ScreenGui,
    Size = UDim2.new(0, 52, 0, 52),
    Position = UDim2.new(0, 18, 0.5, -26),
    BackgroundColor3 = Color3.fromRGB(12, 20, 27),
    AutoButtonColor = false,
    BorderSizePixel = 0,
    Text = "",
    Active = true,
    Draggable = false,
}, { corner(14), stroke(Color3.fromRGB(255, 255, 255), 1) })

scaleObject(Bubble, 1)

-- Ícone inspirado no Lucide "Smartphone": traços brancos num quadrado preto.
local LucidePhone = create("Frame", {
    Parent = Bubble,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 22, 0, 30),
    BackgroundTransparency = 1,
}, {})

create("Frame", {
    Parent = LucidePhone,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
}, {
    create("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 2,
    }),
    corner(5),
})

create("Frame", {
    Parent = LucidePhone,
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 4),
    Size = UDim2.new(0, 7, 0, 2),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
}, { corner(1) })

create("Frame", {
    Parent = LucidePhone,
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -3),
    Size = UDim2.new(0, 4, 0, 4),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
}, { corner(2) })

do
    local dragging, dragStart, startPos = false, nil, nil
    Bubble.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Bubble.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Bubble.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ==========================================================
-- FRAME DO CELULAR
-- ==========================================================
local PhoneFrame = create("Frame", {
    Name = "PhoneFrame",
    Parent = ScreenGui,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = CONFIG.BgColor,
    BorderSizePixel = 0,
    Visible = false,
    ClipsDescendants = true,
}, { corner(34), stroke(CONFIG.BorderColor, 1) })

local function getPhoneSize()
    local viewport = Camera and Camera.ViewportSize or Vector2.new(1280, 720)
    local maxW = math.min(330, viewport.X - 28)
    local maxH = math.min(620, viewport.Y - 36)

    -- Mantém proporção de telefone, mas nunca ultrapassa a tela.
    local width = math.min(maxW, maxH * 0.56)
    local height = math.min(maxH, width / 0.56)

    return UDim2.fromOffset(math.floor(width), math.floor(height))
end

local PHONE_SIZE = getPhoneSize()

local PhoneShadow = create("Frame", {
    Name = "PhoneShadow",
    Parent = ScreenGui,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = PhoneFrame.Position,
    Size = PHONE_SIZE,
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.55,
    ZIndex = -1,
    Visible = false,
}, { corner(38) })

create("Frame", {
    Parent = PhoneFrame,
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 8),
    Size = UDim2.new(0, 116, 0, 20),
    BackgroundColor3 = Color3.fromRGB(3, 3, 5),
    ZIndex = 5,
}, { corner(9) })

local ClockLabel = create("TextLabel", {
    Parent = PhoneFrame,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 16, 0, 8),
    Size = UDim2.new(0, 100, 0, 18),
    Font = Enum.Font.GothamBold,
    Text = "00:00",
    TextColor3 = CONFIG.TextColor,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 6,
}, {})

task.spawn(function()
    while ScreenGui.Parent do
        ClockLabel.Text = os.date("%H:%M")
        task.wait(5)
    end
end)

-- ==========================================================
-- NOTIFICATION BAR
-- ==========================================================
local NotifHolder = create("Frame", {
    Parent = PhoneFrame,
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 0),
    Size = UDim2.new(1, -20, 0, 64),
    BackgroundTransparency = 1,
    ZIndex = 50,
    ClipsDescendants = false,
}, {})

local notifQueue = {}
local notifBusy = false

local function processNotifQueue()
    if notifBusy or #notifQueue == 0 then return end
    notifBusy = true

    local data = table.remove(notifQueue, 1)

    local card = create("Frame", {
        Parent = NotifHolder,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, -76),
        Size = UDim2.new(1, -18, 0, 62),
        BackgroundColor3 = Color3.fromRGB(10, 10, 14),
        ZIndex = 51,
    }, { corner(16), stroke(CONFIG.AccentColor, 1) })

    local notifIcon = create("Frame", {
        Parent = card,
        Position = UDim2.new(0, 12, 0, 7),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        ZIndex = 53,
    }, {})
    local notifColor = (data.icon == "triangle-alert") and CONFIG.WarningColor
        or (data.icon == "check") and CONFIG.SuccessColor
        or CONFIG.AccentColor
    lucideIcon(notifIcon, data.icon, notifColor, 18)

    create("TextLabel", {
        Parent = card,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 7),
        Size = UDim2.new(1, -50, 0, 19),
        Font = Enum.Font.GothamBold,
        Text = data.title,
        TextColor3 = CONFIG.TextColor,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 52,
    }, {})

    create("TextLabel", {
        Parent = card,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 28),
        Size = UDim2.new(1, -24, 0, 22),
        Font = Enum.Font.Gotham,
        Text = data.text,
        TextColor3 = CONFIG.SubTextColor,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 52,
    }, {})

    tween(card, { Position = UDim2.new(0.5, 0, 0, 12) }, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    task.delay(2.8, function()
        local up = tween(card, { Position = UDim2.new(0.5, 0, 0, -76) }, 0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        up.Completed:Connect(function()
            card:Destroy()
            notifBusy = false
            processNotifQueue()
        end)
    end)
end

local function Notify(title, text, icon)
    table.insert(notifQueue, { title = title, text = text, icon = icon or "info" })
    processNotifQueue()
end

-- ==========================================================
-- ÁREA DE CONTEÚDO
-- ==========================================================
local ContentArea = create("Frame", {
    Parent = PhoneFrame,
    Position = UDim2.new(0, 0, 0, 50),
    Size = UDim2.new(1, 0, 1, -50),
    BackgroundTransparency = 1,
}, {})

local HomeScreen = create("Frame", {
    Parent = ContentArea,
    Size = UDim2.new(1, 0, 1, -8),
    BackgroundTransparency = 1,
}, {})

local HomeIndicator = create("TextButton", {
    Parent = PhoneFrame,
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -7),
    Size = UDim2.new(0, 110, 0, 24),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 100,
}, {})

create("Frame", {
    Parent = HomeIndicator,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 92, 0, 4),
    BackgroundColor3 = Color3.fromRGB(235, 235, 240),
    BackgroundTransparency = 0.08,
    ZIndex = 101,
}, {corner(3)})


local AppGrid = create("UIGridLayout", {
    CellSize = UDim2.new(0.27, 0, 0, 82),
    CellPadding = UDim2.new(0.045, 0, 0, 10),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
})
AppGrid.Parent = HomeScreen

create("UIPadding", {
    Parent = HomeScreen,
    PaddingTop = UDim.new(0, 14),
    PaddingLeft = UDim.new(0.035, 0),
    PaddingRight = UDim.new(0.035, 0),
}, {})

local appFrames = {}
-- (lucideIcon já foi declarado no topo do arquivo, na seção HELPERS)

local function createAppWindow(name, title, icon)
    local win = create("Frame", {
        Name = name,
        Parent = ContentArea,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
    }, {})

    local header = create("Frame", {
        Parent = win,
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
    }, {})

    local backBtn = create("TextButton", {
        Parent = header,
        Position = UDim2.new(0, 12, 0.5, -14),
        Size = UDim2.new(0, 28, 0, 28),
        BackgroundColor3 = CONFIG.CardColor,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, { corner(14) })

    lucideIcon(backBtn, "chevron-left", CONFIG.TextColor, 20)

    addHover(backBtn, CONFIG.CardColor, CONFIG.CardHover)

    local headerIcon = create("Frame", {
        Parent = header,
        Position = UDim2.new(0, 50, 0.5, -14),
        Size = UDim2.new(0, 28, 0, 28),
        BackgroundTransparency = 1,
    }, {})
    lucideIcon(headerIcon, icon, CONFIG.AccentColor, 22)

    create("TextLabel", {
        Parent = header,
        Position = UDim2.new(0, 84, 0, 0),
        Size = UDim2.new(1, -94, 1, 0),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = CONFIG.TextColor,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, {})

    local body = create("Frame", {
        Name = "Body",
        Parent = win,
        Position = UDim2.new(0, 10, 0, 48),
        Size = UDim2.new(1, -20, 1, -54),
        BackgroundTransparency = 1,
    }, {})

    backBtn.MouseButton1Click:Connect(function()
        OpenApp("home")
    end)

    appFrames[name] = win
    return win, body
end

local currentApp = "home"
function OpenApp(name)
    if currentApp == name then return end

    local goingHome = (name == "home")
    local currentFrame = (currentApp == "home") and HomeScreen or appFrames[currentApp]
    local nextFrame = (name == "home") and HomeScreen or appFrames[name]

    if not nextFrame then return end

    nextFrame.Visible = true
    nextFrame.Position = UDim2.new(goingHome and -1 or 1, 0, 0, 0)

    local nextScale = scaleObject(nextFrame, 0.94)
    local currentScale = scaleObject(currentFrame, 1)

    tween(nextFrame, {
        Position = UDim2.new(0, 0, 0, 0),
    }, 0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    tween(nextScale, {Scale = 1}, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    local outTween = tween(currentFrame, {
        Position = UDim2.new(goingHome and 1 or -1, 0, 0, 0),
    }, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

    tween(currentScale, {Scale = 0.97}, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    outTween.Completed:Connect(function()
        currentFrame.Visible = false
        currentFrame.Position = UDim2.new(0, 0, 0, 0)
        currentScale.Scale = 1
    end)

    currentApp = name
end

-- Ícones Lucide reais (rbxassetid), portados pela comunidade (lucideblox/frappedevs).
-- Nada de desenho vetorial manual nem emoji: é a mesma imagem PNG que o site
-- lucide.dev usa, já hospedada no Roblox. ImageColor3 tinge o ícone (ele vem
-- em branco/transparente, pronto pra receber cor).
local LUCIDE_ASSETS = {
    ["server"]          = "rbxassetid://7734053426",
    ["settings"]        = "rbxassetid://7734053495",
    ["code"]            = "rbxassetid://7733749837",
    ["file-code"]       = "rbxassetid://7733779730",
    ["info"]            = "rbxassetid://7733964719",
    ["activity"]        = "rbxassetid://7733655755",
    ["trending-up"]     = "rbxassetid://7743874262",
    ["wind"]            = "rbxassetid://7743878264",
    ["ghost"]           = "rbxassetid://7743868000",
    ["search"]          = "rbxassetid://7734052925",
    ["copy"]            = "rbxassetid://7733764083",
    ["play"]            = "rbxassetid://7743871480",
    ["chevron-left"]    = "rbxassetid://7733717651",
    ["chevron-right"]   = "rbxassetid://7733717755",
    ["alert-triangle"]  = "rbxassetid://7733658504",
    ["check"]           = "rbxassetid://7733715400",
    ["check-circle-2"]  = "rbxassetid://7733710700",
    ["x-circle"]        = "rbxassetid://7743878496",
    ["x"]               = "rbxassetid://7743878857",
    ["clock"]           = "rbxassetid://7733734848",
    ["clipboard-list"]  = "rbxassetid://7733920117",
    ["file-text"]       = "rbxassetid://7733789088",
    ["home"]            = "rbxassetid://7733960981",
    ["smartphone"]      = "rbxassetid://7734058979",
    ["sliders"]         = "rbxassetid://7734058803",
    ["refresh-cw"]      = "rbxassetid://7734051052",
    ["gamepad-2"]       = "rbxassetid://7733799795",
    ["lock"]            = "rbxassetid://7733992528",
    ["gauge"]           = "rbxassetid://7733799969",
    ["user"]            = "rbxassetid://7743875962",
    ["users"]           = "rbxassetid://7743876054",
    ["eye"]            = "rbxassetid://7733967939",
}

-- aliases: nomes usados no resto do script que não são a chave exata do asset
local LUCIDE_ALIASES = {
    ["server-cog"]         = "server",
    ["settings-2"]         = "settings",
    ["users-round"]        = "users",
    ["user-round"]         = "user",
    ["zap"]                = "trending-up",       -- não existe "zap" nesse pack; usa trending-up como substituto de "boost"
    ["plane"]              = "wind",
    ["triangle-alert"]     = "alert-triangle",
    ["circle-check"]       = "check-circle-2",
    ["circle-x"]           = "x-circle",
    ["clipboard"]          = "clipboard-list",
    ["phone"]              = "smartphone",
    ["sliders-horizontal"] = "sliders",
}

lucideIcon = function(parent, name, color, size)
    local resolved = LUCIDE_ALIASES[name] or name
    local assetId = LUCIDE_ASSETS[resolved] or LUCIDE_ASSETS["info"]

    local icon = create("ImageLabel", {
        Parent = parent,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(size or 28, size or 28),
        BackgroundTransparency = 1,
        Image = assetId,
        ImageColor3 = color or Color3.fromRGB(226, 232, 240),
        ScaleType = Enum.ScaleType.Fit,
    }, {})

    return icon
end

local function addAppIcon(name, label, icon, layoutOrder, color)
    local accent = color or CONFIG.AccentColor
    local btn = create("TextButton", {
        Parent = HomeScreen,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = layoutOrder,
    }, {})

    local iconBox = create("Frame", {
        Parent = btn,
        Size = UDim2.new(1, 0, 1, -22),
        BackgroundColor3 = Color3.fromRGB(18, 22, 28),
        BorderSizePixel = 0,
    }, { corner(18), stroke(accent, 1) })

    create("Frame", {
        Parent = iconBox,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.90,
        BorderSizePixel = 0,
    }, { corner(18) })

    lucideIcon(iconBox, icon, accent, 30)

    create("TextLabel", {
        Parent = btn,
        Position = UDim2.new(0, 0, 1, -20),
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Color3.fromRGB(226, 232, 240),
        Font = Enum.Font.Gotham,
        TextSize = 11,
    }, {})

    local normalIconSize = UDim2.new(1, 0, 1, -22)

    btn.MouseButton1Down:Connect(function()
        tween(iconBox, {Size = UDim2.new(1, -8, 1, -30)}, 0.08, Enum.EasingStyle.Quad)
    end)

    btn.MouseButton1Up:Connect(function()
        tween(iconBox, {Size = normalIconSize}, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

    btn.MouseButton1Click:Connect(function()
        OpenApp(name)
    end)

    return btn
end

-- ==========================================================
-- APP 1: INFO SERVER
-- ==========================================================
do
    local win, body = createAppWindow("info", "Info Server", "server")
    addAppIcon("info", "Info Server", "server", 1, Color3.fromRGB(56, 189, 248))

    local function statLine(order)
        local row = create("Frame", {
            Parent = body,
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundColor3 = CONFIG.CardColor,
            LayoutOrder = order,
        }, { corner(12) })

        local title = create("TextLabel", {
            Parent = row,
            Position = UDim2.new(0, 12, 0, 4),
            Size = UDim2.new(1, -24, 0, 16),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = CONFIG.SubTextColor,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, {})

        local value = create("TextLabel", {
            Parent = row,
            Position = UDim2.new(0, 12, 0, 20),
            Size = UDim2.new(1, -24, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextColor3 = CONFIG.TextColor,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, {})

        return title, value
    end

    create("UIListLayout", { Parent = body, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

    local t1, v1 = statLine(1); t1.Text = "NOME DO JOGO"
    local t2, v2 = statLine(2); t2.Text = "JOGADORES"
    local t3, v3 = statLine(3); t3.Text = "PING"
    local t4, v4 = statLine(4); t4.Text = "TEMPO ONLINE (UPTIME)"
    local t5, v5 = statLine(5); t5.Text = "PLACE ID / JOB ID"

    local startTime = os.clock()

    local function formatUptime(seconds)
        local h = math.floor(seconds / 3600)
        local m = math.floor((seconds % 3600) / 60)
        local s = math.floor(seconds % 60)
        return string.format("%02dh %02dm %02ds", h, m, s)
    end

    task.spawn(function()
        while ScreenGui.Parent do
            v1.Text = game.Name ~= "" and game.Name or "Desconhecido"
            v2.Text = #Players:GetPlayers() .. " / " .. Players.MaxPlayers
            local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
            v3.Text = ping .. " ms"
            v4.Text = formatUptime(os.clock() - startTime)
            v5.Text = tostring(game.PlaceId) .. " | " .. tostring(game.JobId):sub(1, 8) .. "..."
            task.wait(1)
        end
    end)
end

-- ==========================================================
-- APP 2: PLAYER CONFIGS
-- ==========================================================
do
    local win, body = createAppWindow("configs", "Player Configs", "settings")
    addAppIcon("configs", "Configs", "settings", 2, Color3.fromRGB(251, 191, 36))

    create("UIListLayout", { Parent = body, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder })

    local function getHumanoid()
        local char = LocalPlayer.Character
        return char and char:FindFirstChildOfClass("Humanoid")
    end

    local function createSlider(labelText, min, max, default, onChange, order)
        local container = create("Frame", {
            Parent = body,
            Size = UDim2.new(1, 0, 0, 54),
            BackgroundColor3 = CONFIG.CardColor,
            LayoutOrder = order,
        }, { corner(12) })

        local sliderIcon = create("Frame", {
            Parent = container,
            Position = UDim2.new(0, 10, 0, 4),
            Size = UDim2.new(0, 20, 0, 20),
            BackgroundTransparency = 1,
        }, {})
        lucideIcon(sliderIcon, labelText == "WalkSpeed" and "activity" or "zap", CONFIG.InfoColor, 18)

        local lbl = create("TextLabel", {
            Parent = container,
            Position = UDim2.new(0, 38, 0, 6),
            Size = UDim2.new(1, -50, 0, 18),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = CONFIG.TextColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = labelText .. ": " .. tostring(default),
        }, {})

        local track = create("Frame", {
            Parent = container,
            Position = UDim2.new(0, 12, 0, 32),
            Size = UDim2.new(1, -24, 0, 6),
            BackgroundColor3 = Color3.fromRGB(35, 45, 55),
        }, { corner(3) })

        local fillPct = (default - min) / (max - min)
        local fill = create("Frame", {
            Parent = track,
            Size = UDim2.new(fillPct, 0, 1, 0),
            BackgroundColor3 = CONFIG.InfoColor,
        }, { corner(3) })

        local knob = create("Frame", {
            Parent = track,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(fillPct, 0, 0.5, 0),
            Size = UDim2.new(0, 14, 0, 14),
            BackgroundColor3 = CONFIG.TextColor,
            ZIndex = 3,
        }, { corner(7) })

        local dragging = false
        local function setFromX(xPos)
            local rel = math.clamp((xPos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, 0, 0.5, 0)
            local val = math.floor(min + (max - min) * rel)
            lbl.Text = labelText .. ": " .. tostring(val)
            onChange(val)
        end

        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                setFromX(input.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                setFromX(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        return container
    end

    local function createToggle(labelText, default, onChange, order)
        local container = create("Frame", {
            Parent = body,
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundColor3 = CONFIG.CardColor,
            LayoutOrder = order,
        }, { corner(12) })

        local toggleIcon = (labelText == "Fly") and "wind" or "ghost"
        local toggleIconHolder = create("Frame", {
            Parent = container,
            Position = UDim2.new(0, 10, 0.5, -10),
            Size = UDim2.new(0, 20, 0, 20),
            BackgroundTransparency = 1,
        }, {})
        lucideIcon(toggleIconHolder, toggleIcon, CONFIG.WarningColor, 18)

        create("TextLabel", {
            Parent = container,
            Position = UDim2.new(0, 38, 0, 0),
            Size = UDim2.new(1, -70, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = CONFIG.TextColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = labelText,
        }, {})

        local switchBg = create("Frame", {
            Parent = container,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.new(0, 46, 0, 24),
            BackgroundColor3 = default and CONFIG.SuccessColor or Color3.fromRGB(48, 58, 68),
        }, { corner(12) })

        local knob = create("Frame", {
            Parent = switchBg,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = default and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.new(0, 20, 0, 20),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        }, { corner(10) })

        local state = default
        local clickArea = create("TextButton", {
            Parent = switchBg,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
        }, {})

        clickArea.MouseButton1Click:Connect(function()
            state = not state
            tween(switchBg, { BackgroundColor3 = state and CONFIG.SuccessColor or Color3.fromRGB(48, 58, 68) }, 0.18)
            tween(knob, { Position = state and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) }, 0.18, Enum.EasingStyle.Quart)
            onChange(state)
        end)

        return container
    end

    createSlider("WalkSpeed", 0, 200, 16, function(val)
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = val end
    end, 1)

    createSlider("JumpPower", 0, 300, 50, function(val)
        local hum = getHumanoid()
        if hum then hum.JumpPower = val end
    end, 2)

    local flyEnabled = false
    local flyConn
    local flyBodyVel

    local function toggleFly(state)
        flyEnabled = state
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        if state then
            flyBodyVel = Instance.new("BodyVelocity")
            flyBodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            flyBodyVel.Velocity = Vector3.new(0, 0, 0)
            flyBodyVel.Parent = root

            flyConn = RunService.RenderStepped:Connect(function()
                local cam = workspace.CurrentCamera
                local moveDir = Vector3.new(0, 0, 0)
                local camCF = cam.CFrame

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir + Vector3.new(0, -1, 0) end

                if moveDir.Magnitude > 0 then
                    flyBodyVel.Velocity = moveDir.Unit * 60
                else
                    flyBodyVel.Velocity = Vector3.new(0, 0, 0)
                end
            end)
            Notify("Player Configs", "Fly ativado (WASD + Espaço/Ctrl)", "wind")
        else
            if flyConn then flyConn:Disconnect() end
            if flyBodyVel then flyBodyVel:Destroy() end
            Notify("Player Configs", "Fly desativado", "wind")
        end
    end

    createToggle("Fly", false, toggleFly, 3)

    local noclipEnabled = false
    local noclipConn

    local function toggleNoclip(state)
        noclipEnabled = state
        if noclipConn then noclipConn:Disconnect() end

        if state then
            noclipConn = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
            Notify("Player Configs", "Noclip ativado", "ghost")
        else
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            Notify("Player Configs", "Noclip desativado", "ghost")
        end
    end

    createToggle("NoClip", false, toggleNoclip, 4)
end

-- ==========================================================
-- APP 3: SCRIPTBLOX API
-- ==========================================================
do
    local win, body = createAppWindow("scriptblox", "ScriptBlox", "code")
    addAppIcon("scriptblox", "ScriptBlox", "code", 3, Color3.fromRGB(52, 211, 153))

    local searchBar = create("Frame", {
        Parent = body,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = CONFIG.CardColor,
        BorderSizePixel = 0,
    }, { corner(15), stroke(CONFIG.BorderColor, 1) })

    local searchIcon = create("Frame", {
        Parent = searchBar,
        Position = UDim2.new(0, 10, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
    }, {})
    lucideIcon(searchIcon, "search", CONFIG.AccentColor, 18)

    local searchBox = create("TextBox", {
        Parent = searchBar,
        Position = UDim2.new(0, 36, 0, 0),
        Size = UDim2.new(1, -106, 1, 0),
        BackgroundTransparency = 1,
        PlaceholderText = "Buscar script...",
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = CONFIG.TextColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    }, {})

    local searchBtn = create("TextButton", {
        Parent = searchBar,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 64, 0, 28),
        BackgroundColor3 = CONFIG.InfoColor,
        Text = "Buscar",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        AutoButtonColor = false,
    }, { corner(10) })

    local resultsList = create("ScrollingFrame", {
        Parent = body,
        Position = UDim2.new(0, 0, 0, 50),
        Size = UDim2.new(1, 0, 1, -72),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = CONFIG.InfoColor,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, {})

    create("UIListLayout", {
        Parent = resultsList,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    create("TextLabel", {
        Parent = body,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -7),
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = "Powered by ScriptBlox.com",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = CONFIG.SubTextColor,
    }, {})

    local function clearResults()
        for _, child in ipairs(resultsList:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
    end

    local function getRawScript(slug)
        if not slug or slug == "" then
            return nil, "Slug inválido"
        end

        if not httpRequest then
            return nil, "HTTP Request não disponível"
        end

        local url = "https://scriptblox.com/api/script/raw/"
            .. HttpService:UrlEncode(slug)

        local ok, response = pcall(function()
            return httpRequest({
                Url = url,
                Method = "GET",
                Headers = {
                    ["Content-Type"] = "application/json"
                }
            })
        end)

        if not ok or not response then
            return nil, "Falha na requisição"
        end

        local bodyText = response.Body

        if not bodyText or bodyText == "" then
            return nil, "Resposta vazia"
        end

        return bodyText
    end

    local function addResultCard(scriptData, order)
        local title = scriptData.title or "Sem título"
        local slug = scriptData.slug
        local gameName = "Desconhecido"

        if scriptData.game then
            gameName = scriptData.game.name
                or scriptData.gameName
                or "Desconhecido"
        end

        local isKeyRequired = scriptData.key == true

        local card = create("Frame", {
            Parent = resultsList,
            Size = UDim2.new(1, -4, 0, 88),
            BackgroundColor3 = CONFIG.CardColor,
            LayoutOrder = order,
        }, { corner(12) })

        create("TextLabel", {
            Parent = card,
            Position = UDim2.new(0, 10, 0, 6),
            Size = UDim2.new(1, -20, 0, 18),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = CONFIG.TextColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = title,
        }, {})

        create("TextLabel", {
            Parent = card,
            Position = UDim2.new(0, 10, 0, 24),
            Size = UDim2.new(1, -20, 0, 16),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = CONFIG.SubTextColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = gameName .. (isKeyRequired and "  • KEY" or ""),
        }, {})

        local copyBtn = create("TextButton", {
            Parent = card,
            Position = UDim2.new(0, 10, 1, -30),
            Size = UDim2.new(0.43, 0, 0, 24),
            BackgroundColor3 = CONFIG.AccentColor,
            Text = "  Copiar",
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            AutoButtonColor = false,
        }, { corner(8) })

        local copyIcon = create("Frame", {
            Parent = copyBtn,
            Position = UDim2.new(0, 8, 0.5, -9),
            Size = UDim2.new(0, 18, 0, 18),
            BackgroundTransparency = 1,
        }, {})
        lucideIcon(copyIcon, "copy", Color3.fromRGB(255,255,255), 17)

        local execBtn = create("TextButton", {
            Parent = card,
            Position = UDim2.new(0.53, 0, 1, -30),
            Size = UDim2.new(0.43, 0, 0, 24),
            BackgroundColor3 = Color3.fromRGB(30, 41, 50),
            Text = "  Executar",
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            AutoButtonColor = false,
        }, { corner(8) })

        local execIcon = create("Frame", {
            Parent = execBtn,
            Position = UDim2.new(0, 8, 0.5, -9),
            Size = UDim2.new(0, 18, 0, 18),
            BackgroundTransparency = 1,
        }, {})
        lucideIcon(execIcon, "play", Color3.fromRGB(255,255,255), 17)

        copyBtn.MouseButton1Click:Connect(function()
            if not slug or slug == "" then
                Notify("ScriptBlox", "Este resultado não possui slug", "triangle-alert")
                return
            end

            task.spawn(function()
                local code, err = getRawScript(slug)

                if not code then
                    Notify("ScriptBlox", "Erro: " .. tostring(err), "triangle-alert")
                    return
                end

                setClipboard(code)
                Notify("ScriptBlox", "Script copiado: " .. title, "copy")
            end)
        end)

        execBtn.MouseButton1Click:Connect(function()
            if not slug or slug == "" then
                Notify("ScriptBlox", "Este resultado não possui slug", "triangle-alert")
                return
            end

            execBtn.Text = "Carregando..."

            task.spawn(function()
                local code, err = getRawScript(slug)

                if not code then
                    execBtn.Text = "Executar"
                    Notify("ScriptBlox", "Erro: " .. tostring(err), "triangle-alert")
                    return
                end

                local compileOk, loaded = pcall(loadstring, code)

                if not compileOk or not loaded then
                    execBtn.Text = "Executar"
                    Notify("ScriptBlox", "Código inválido ou não pôde ser carregado", "triangle-alert")
                    return
                end

                local runOk, runErr = pcall(loaded)

                execBtn.Text = "Executar"

                if runOk then
                    Notify("Script executado", title, "check")
                else
                    Notify("ScriptBlox", "Erro durante execução", "triangle-alert")
                    warn("[ScriptBlox] " .. tostring(runErr))
                end
            end)
        end)

        return card
    end

    local function doSearch(query)
        clearResults()

        if not httpRequest then
            Notify("ScriptBlox", "HttpRequest não disponível no executor", "triangle-alert")
            return
        end

        query = tostring(query or ""):match("^%s*(.-)%s*$")

        if query == "" then
            Notify("ScriptBlox", "Digite algo para pesquisar", "triangle-alert")
            return
        end

        local loadingLbl = create("TextLabel", {
            Parent = resultsList,
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
            Text = "A pesquisar...",
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = CONFIG.SubTextColor,
        }, {})

        task.spawn(function()
            local url = CONFIG.ScriptBloxSearchURL
                .. HttpService:UrlEncode(query)
                .. "&max=20"

            local ok, response = pcall(function()
                return httpRequest({
                    Url = url,
                    Method = "GET",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                })
            end)

            if loadingLbl and loadingLbl.Parent then
                loadingLbl:Destroy()
            end

            if not ok or not response then
                Notify("ScriptBlox", "Falha na requisição", "triangle-alert")
                return
            end

            if not response.Body or response.Body == "" then
                Notify("ScriptBlox", "A API devolveu uma resposta vazia", "triangle-alert")
                return
            end

            local decodeOk, data = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)

            if not decodeOk or type(data) ~= "table" then
                Notify("ScriptBlox", "Erro ao interpretar resposta da API", "triangle-alert")
                return
            end

            local scripts = {}

            if data.result and type(data.result.scripts) == "table" then
                scripts = data.result.scripts
            elseif type(data.scripts) == "table" then
                scripts = data.scripts
            end

            if #scripts == 0 then
                create("TextLabel", {
                    Parent = resultsList,
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundTransparency = 1,
                    Text = "Nenhum resultado encontrado",
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextColor3 = CONFIG.SubTextColor,
                }, {})
                return
            end

            local displayed = 0

            for i, scriptData in ipairs(scripts) do
                if type(scriptData) == "table" then
                    addResultCard(scriptData, i)
                    displayed += 1
                end

                if displayed >= 20 then
                    break
                end
            end

            Notify(
                "ScriptBlox",
                tostring(displayed) .. " resultado(s) encontrado(s)",
                "file-text"
            )
        end)
    end

    searchBtn.MouseButton1Click:Connect(function()
        doSearch(searchBox.Text)
    end)

    searchBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            doSearch(searchBox.Text)
        end
    end)
end

-- ==========================================================

-- ==========================================================
-- COMPONENTES UI COMPARTILHADOS (Apps 4-6)
-- Materia: this section replaces the previous incomplete one
-- ==========================================================
local function newToggle(body, props)
    -- props: text, icon, iconColor, switchColor, default, order, onChange
    local state = props.default or false
    local switchColor = props.switchColor or CONFIG.SuccessColor

    local container = create("Frame", {
        Parent = body, Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = CONFIG.CardColor, LayoutOrder = props.order or 0,
    }, { corner(12) })

    local iconHolder = create("Frame", {
        Parent = container, Position = UDim2.new(0, 10, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20), BackgroundTransparency = 1,
    }, {})
    lucideIcon(iconHolder, props.icon or "info", props.iconColor or CONFIG.AccentColor, 18)

    create("TextLabel", {
        Parent = container, Position = UDim2.new(0, 38, 0, 0),
        Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = CONFIG.TextColor, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = props.text or "Toggle",
    }, {})

    local switchBg = create("Frame", {
        Parent = container, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 46, 0, 24),
        BackgroundColor3 = state and switchColor or Color3.fromRGB(48, 58, 68),
    }, { corner(12) })

    local knob = create("Frame", {
        Parent = switchBg, AnchorPoint = Vector2.new(0, 0.5),
        Position = state and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    }, { corner(10) })

    local function render()
        tween(switchBg, { BackgroundColor3 = state and switchColor or Color3.fromRGB(48, 58, 68) }, 0.18)
        tween(knob, { Position = state and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) }, 0.18, Enum.EasingStyle.Quart)
    end

    create("TextButton", {
        Parent = switchBg, Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Text = "",
    }, {}).MouseButton1Click:Connect(function()
        state = not state
        render()
        if props.onChange then props.onChange(state) end
    end)

    return container, function() return state end
end

local function newSlider(body, props)
    -- props: text, icon, iconColor, min, max, default, order, isFloat, format, onChange
    local min, max = props.min or 0, props.max or 100
    local isFloat = props.isFloat
    local value = props.default or min

    local container = create("Frame", {
        Parent = body, Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = CONFIG.CardColor, LayoutOrder = props.order or 0,
    }, { corner(12) })

    local iconHolder = create("Frame", {
        Parent = container, Position = UDim2.new(0, 10, 0, 4),
        Size = UDim2.new(0, 20, 0, 20), BackgroundTransparency = 1,
    }, {})
    lucideIcon(iconHolder, props.icon or "sliders", props.iconColor or CONFIG.InfoColor, 18)

    local function fmt(v)
        if props.format then return props.format(v) end
        return tostring(math.floor(v + 0.5))
    end

    local lbl = create("TextLabel", {
        Parent = container, Position = UDim2.new(0, 38, 0, 6),
        Size = UDim2.new(1, -50, 0, 18), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = CONFIG.TextColor, TextXAlignment = Enum.TextXAlignment.Left,
        Text = (props.text or "Slider") .. ": " .. fmt(value),
    }, {})

    local track = create("Frame", {
        Parent = container, Position = UDim2.new(0, 12, 0, 32),
        Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = Color3.fromRGB(35, 45, 55),
    }, { corner(3) })

    local rel = math.clamp((value - min) / (max - min), 0, 1)
    local fill = create("Frame", {
        Parent = track, Size = UDim2.new(rel, 0, 1, 0),
        BackgroundColor3 = props.iconColor or CONFIG.InfoColor,
    }, { corner(3) })

    local knob = create("Frame", {
        Parent = track, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(rel, 0, 0.5, 0), Size = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = CONFIG.TextColor, ZIndex = 3,
    }, { corner(7) })

    local dragging = false

    local function applyFromX(xPos)
        local r = math.clamp((xPos - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local v = min + (max - min) * r
        if not isFloat then v = math.floor(v + 0.5) end
        value = v
        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, 0, 0.5, 0)
        lbl.Text = (props.text or "Slider") .. ": " .. fmt(value)
        if props.onChange then props.onChange(value) end
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            applyFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            applyFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return container, function() return value end
end

local function newCycleButton(body, props)
    -- props: label, icon, iconColor, options (array de strings), defaultIndex, order, onChange
    local options = props.options or {"Opção A", "Opção B"}
    local index = props.defaultIndex or 1

    local container = create("Frame", {
        Parent = body, Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = CONFIG.CardColor, LayoutOrder = props.order or 0,
    }, { corner(12) })

    local iconHolder = create("Frame", {
        Parent = container, Position = UDim2.new(0, 10, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20), BackgroundTransparency = 1,
    }, {})
    lucideIcon(iconHolder, props.icon or "sliders", props.iconColor or CONFIG.InfoColor, 18)

    create("TextLabel", {
        Parent = container, Position = UDim2.new(0, 38, 0, 0),
        Size = UDim2.new(1, -160, 1, 0), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = CONFIG.TextColor, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = props.label or "Opção",
    }, {})

    local valueBtn = create("TextButton", {
        Parent = container, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 108, 0, 28),
        BackgroundColor3 = Color3.fromRGB(35, 48, 60), Text = "",
        AutoButtonColor = false,
    }, { corner(8) })

    create("TextLabel", {
        Parent = valueBtn, Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -26, 1, 0), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = CONFIG.TextColor, TextXAlignment = Enum.TextXAlignment.Left,
        Text = options[index],
    }, {})

    local chevHolder = create("Frame", {
        Parent = valueBtn, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.new(0, 16, 0, 16),
        BackgroundTransparency = 1,
    }, {})
    lucideIcon(chevHolder, "chevron-right", CONFIG.SubTextColor, 14)

    local valueLbl = valueBtn:FindFirstChildOfClass("TextLabel")

    valueBtn.MouseButton1Click:Connect(function()
        index = index % #options + 1
        valueLbl.Text = options[index]
        if props.onChange then props.onChange(options[index]) end
    end)

    return container, function() return options[index] end
end

local function newIconButton(parent, props)
    -- props: text, icon, iconColor, bg textColor, position, size, onClick
    local btn = create("TextButton", {
        Parent = parent, Size = props.size or UDim2.new(0, 88, 0, 26),
        BackgroundColor3 = props.bg or Color3.fromRGB(35, 48, 60),
        Position = props.position or UDim2.new(0, 0, 0, 0),
        Text = "", AutoButtonColor = false, ZIndex = 3,
    }, { corner(8) })

    local iconHolder = create("Frame", {
        Parent = btn, Position = UDim2.new(0, 6, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16), BackgroundTransparency = 1,
    }, {})
    lucideIcon(iconHolder, props.icon or "info", props.iconColor or Color3.fromRGB(255, 255, 255), 15)

    create("TextLabel", {
        Parent = btn, Position = UDim2.new(0, 26, 0, 0),
        Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = props.textColor or Color3.fromRGB(255, 255, 255),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = props.text or "",
    }, {})

    btn.MouseButton1Click:Connect(props.onClick or function() end)

    return btn
end

-- ==========================================================
-- APP 4: AIMBOT (Mobile)
-- ==========================================================
do
    local win, body = createAppWindow("aimbot", "Aimbot", "gauge")
    addAppIcon("aimbot", "Aimbot", "gauge", 4, CONFIG.DangerColor)

    local scroll = create("ScrollingFrame", {
        Parent = body, Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 4, ScrollBarImageColor3 = CONFIG.DangerColor,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, {})
    create("UIListLayout", { Parent = scroll, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

    local aimState = {
        enabled = false, fov = 200, smooth = 0.35,
        partName = "Head", teamCheck = false, wallCheck = false, showCircle = true,
    }

    -- Círculo de FOV desenhado na tela toda (fora do celular)
    local fovCircle = create("Frame", {
        Name = "AimbotFOV",
        Parent = ScreenGui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(aimState.fov * 2, aimState.fov * 2),
        BackgroundTransparency = 1, Visible = false, ZIndex = 200,
    }, {
        create("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
        create("UIStroke", { Color = CONFIG.DangerColor, Thickness = 1, Transparency = 0.25 }),
    })

    -- Card de status: mostra o alvo travado em tempo real
    local statusCard = create("Frame", {
        Parent = scroll, Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = CONFIG.CardColor, LayoutOrder = 2,
    }, { corner(12) })

    local stIconHolder = create("Frame", {
        Parent = statusCard, Position = UDim2.new(0, 10, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20), BackgroundTransparency = 1,
    }, {})
    lucideIcon(stIconHolder, "user", CONFIG.DangerColor, 18)

    create("TextLabel", {
        Parent = statusCard, Position = UDim2.new(0, 38, 0, 6),
        Size = UDim2.new(1, -50, 0, 14), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = CONFIG.SubTextColor, Text = "ALVO TRAVADO",
    }, {})

    local statusValue = create("TextLabel", {
        Parent = statusCard, Position = UDim2.new(0, 38, 0, 21),
        Size = UDim2.new(1, -50, 0, 18), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = CONFIG.SuccessColor, Text = "—",
    }, {})

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local function getAimTarget()
        local best, bestDist = nil, aimState.fov
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                if not aimState.teamCheck or plr.Team ~= LocalPlayer.Team then
                    local char = plr.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local part = char and char:FindFirstChild(aimState.partName)
                    if char and hum and part and hum.Health > 0 then
                        local sp, onScreen = Camera:WorldToScreenPoint(part.Position)
                        if onScreen then
                            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if d <= bestDist then
                                local blocked = false
                                if aimState.wallCheck then
                                    rayParams.FilterDescendantsInstances = {char}
                                    local camPos = Camera.CFrame.Position
                                    local result = workspace:Raycast(camPos, part.Position - camPos, rayParams)
                                    blocked = result ~= nil
                                end
                                if not blocked then
                                    best, bestDist = plr, d
                                end
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local aimConn = nil

    local function setAimbot(on)
        aimState.enabled = on
        if on then
            fovCircle.Visible = aimState.showCircle
            aimConn = RunService.RenderStepped:Connect(function()
                local target = getAimTarget()
                statusValue.Text = target and target.Name or "Nenhum"
                if target then
                    local part = target.Character and target.Character:FindFirstChild(aimState.partName)
                    if part then
                        local look = CFrame.lookAt(Camera.CFrame.Position, part.Position)
                        Camera.CFrame = Camera.CFrame:Lerp(look, aimState.smooth)
                    end
                end
            end)
            Notify("Aimbot", "Aimbot ativado", "gauge")
        else
            if aimConn then aimConn:Disconnect(); aimConn = nil end
            fovCircle.Visible = false
            statusValue.Text = "—"
            Notify("Aimbot", "Aimbot desativado", "gauge")
        end
    end

    newToggle(scroll, {
        text = "Aimbot (mira central)", icon = "gauge",
        iconColor = CONFIG.DangerColor, switchColor = CONFIG.DangerColor,
        order = 1, onChange = setAimbot,
    })

    newSlider(scroll, {
        text = "FOV", icon = "sliders", iconColor = CONFIG.DangerColor,
        min = 50, max = 500, default = 200, order = 3,
        onChange = function(v)
            aimState.fov = v
            fovCircle.Size = UDim2.fromOffset(v * 2, v * 2)
        end,
    })

    newSlider(scroll, {
        text = "Suavidade", icon = "activity", iconColor = CONFIG.DangerColor,
        min = 5, max = 100, default = 35, order = 4,
        format = function(v) return v .. "%" end,
        onChange = function(v) aimState.smooth = v / 100 end,
    })

    newCycleButton(scroll, {
        label = "Parte do corpo", icon = "user", iconColor = CONFIG.DangerColor,
        options = {"Cabeça", "Torso", "Raiz"}, defaultIndex = 1, order = 5,
        onChange = function(opt)
            if opt == "Cabeça" then aimState.partName = "Head"
            elseif opt == "Torso" then aimState.partName = "Torso"
            else aimState.partName = "HumanoidRootPart" end
        end,
    })

    newToggle(scroll, {
        text = "Team Check (ignora aliados)", icon = "users",
        iconColor = CONFIG.DangerColor, order = 6,
        onChange = function(v) aimState.teamCheck = v end,
    })

    newToggle(scroll, {
        text = "Wall Check (só alvos visíveis)", icon = "lock",
        iconColor = CONFIG.DangerColor, order = 7,
        onChange = function(v) aimState.wallCheck = v end,
    })

    newToggle(scroll, {
        text = "Mostrar círculo de FOV", icon = "info",
        iconColor = CONFIG.DangerColor, order = 8, default = true,
        onChange = function(v)
            aimState.showCircle = v
            fovCircle.Visible = v and aimState.enabled
        end,
    })
end

-- ==========================================================
-- APP 5: ESP (completo)
-- ==========================================================
do
    local win, body = createAppWindow("esp", "ESP", "ghost")
    addAppIcon("esp", "ESP", "ghost", 5, CONFIG.InfoColor)

    local scroll = create("ScrollingFrame", {
        Parent = body, Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 4, ScrollBarImageColor3 = CONFIG.InfoColor,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, {})
    create("UIListLayout", { Parent = scroll, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

    local espState = {
        enabled = false, names = true, distance = true,
        tracers = true, chams = false, teamCheck = false,
    }
    local espData = {}   -- [player] = { billboard, nameLabel, distLabel, tracer, highlight, charConn }
    local espConns = {}
    local espRenderConn = nil

    local function removeESP(player)
        local data = espData[player]
        if not data then return end
        if data.billboard and data.billboard.Parent then data.billboard:Destroy() end
        if data.tracer then data.tracer:Destroy() end
        if data.highlight then data.highlight:Destroy() end
        if data.charConn then data.charConn:Disconnect() end
        espData[player] = nil
    end

    local function buildBillboard(data, char)
        if data.billboard and data.billboard.Parent then data.billboard:Destroy() end
        local head = char and char:FindFirstChild("Head")
        if not head then return end

        local bb = Instance.new("BillboardGui")
        bb.Name = "yoaredevs_ESP"
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 180, 0, 36)
        bb.StudsOffset = Vector3.new(0, 2.6, 0)
        bb.Enabled = false

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
        bg.BackgroundTransparency = 0.45
        bg.BorderSizePixel = 0
        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(0, 6)
        bgCorner.Parent = bg
        bg.Parent = bb

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -8, 0, 17)
        nameLabel.Position = UDim2.new(0, 4, 0, 1)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 13
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 0.6
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Text = data.player.Name
        nameLabel.Parent = bg

        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(1, -8, 0, 13)
        distLabel.Position = UDim2.new(0, 4, 0, 18)
        distLabel.BackgroundTransparency = 1
        distLabel.Font = Enum.Font.Gotham
        distLabel.TextSize = 11
        distLabel.TextColor3 = Color3.fromRGB(180, 190, 200)
        distLabel.TextStrokeTransparency = 0.6
        distLabel.Text = ""
        distLabel.Parent = bg

        data.billboard = bb
        data.nameLabel = nameLabel
        data.distLabel = distLabel
        bb.Parent = head
    end

    local function addESP(player)
        if player == LocalPlayer or espData[player] then return end
        local data = { player = player }
        espData[player] = data

        -- tracer (linha da base da tela até o jogador)
        data.tracer = create("Frame", {
            Parent = ScreenGui, BackgroundColor3 = CONFIG.InfoColor,
            BorderSizePixel = 0, Visible = false, ZIndex = 150,
            AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 0, 0, 2),
        }, {})

        -- chams (highlight)
        data.highlight = Instance.new("Highlight")
        data.highlight.FillColor = CONFIG.InfoColor
        data.highlight.OutlineColor = CONFIG.InfoColor
        data.highlight.FillTransparency = 0.6
        data.highlight.OutlineTransparency = 0
        data.highlight.Enabled = false
        data.highlight.Parent = ScreenGui

        -- reconstroi ao respawnar
        data.charConn = player.CharacterAdded:Connect(function(char)
            task.wait(0.3)
            buildBillboard(data, char)
            if data.highlight then data.highlight.Adornee = char end
        end)

        if player.Character then
            buildBillboard(data, player.Character)
            data.highlight.Adornee = player.Character
        end
    end

    local function renderESP()
        local lChar = LocalPlayer.Character
        local lRoot = lChar and lChar:FindFirstChild("HumanoidRootPart")

        for player, data in pairs(espData) do
            if not player.Parent then
                removeESP(player)
            else
                local char = player.Character
                local head = char and char:FindFirstChild("Head")
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local alive = hum and hum.Health > 0
                local sameTeam = (player.Team ~= nil and player.Team == LocalPlayer.Team)
                local show = not (espState.teamCheck and sameTeam)

                if not (char and head and root and alive) then
                    if data.tracer then data.tracer.Visible = false end
                    if data.highlight then data.highlight.Enabled = false end
                else
                    -- billboard (nome + distância)
                    if data.billboard then
                        data.billboard.Enabled = show and (espState.names or espState.distance)
                        data.nameLabel.Visible = espState.names
                        data.distLabel.Visible = espState.distance
                        if espState.distance and lRoot then
                            data.distLabel.Text = math.floor((root.Position - lRoot.Position).Magnitude) .. " studs"
                        end
                    end

                    -- chams
                    if data.highlight then
                        local c = sameTeam and CONFIG.SuccessColor or CONFIG.InfoColor
                        data.highlight.FillColor = c
                        data.highlight.OutlineColor = c
                        data.highlight.Enabled = show and espState.chams
                    end

                    -- tracer
                    if espState.tracers and show then
                        local sp = Camera:WorldToScreenPoint(root.Position)
                        if sp.Z > 0 then
                            local origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            local target = Vector2.new(sp.X, sp.Y)
                            local delta = target - origin
                            data.tracer.Visible = true
                            data.tracer.Size = UDim2.fromOffset(math.max(math.floor(delta.Magnitude), 1), 2)
                            data.tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
                            data.tracer.Position = UDim2.fromOffset(math.floor(origin.X), math.floor(origin.Y))
                        else
                            data.tracer.Visible = false
                        end
                    elseif data.tracer then
                        data.tracer.Visible = false
                    end
                end
            end
        end
    end

    local function setESP(on)
        espState.enabled = on
        if on then
            for _, plr in ipairs(Players:GetPlayers()) do addESP(plr) end
            espRenderConn = RunService.RenderStepped:Connect(renderESP)
            table.insert(espConns, Players.PlayerAdded:Connect(addESP))
            table.insert(espConns, Players.PlayerRemoving:Connect(removeESP))
            Notify("ESP", "ESP ativado", "ghost")
        else
            if espRenderConn then espRenderConn:Disconnect(); espRenderConn = nil end
            for _, c in ipairs(espConns) do c:Disconnect() end
            espConns = {}
            for player in pairs(espData) do removeESP(player) end
            Notify("ESP", "ESP desativado", "ghost")
        end
    end

    newToggle(scroll, {
        text = "ESP (ver jogadores)", icon = "ghost",
        iconColor = CONFIG.InfoColor, order = 1, onChange = setESP,
    })

    newToggle(scroll, {
        text = "Mostrar nome", icon = "user", iconColor = CONFIG.InfoColor,
        default = true, order = 2,
        onChange = function(v) espState.names = v end,
    })

    newToggle(scroll, {
        text = "Mostrar distância", icon = "activity", iconColor = CONFIG.InfoColor,
        default = true, order = 3,
        onChange = function(v) espState.distance = v end,
    })

    newToggle(scroll, {
        text = "Tracers (linhas)", icon = "trending-up", iconColor = CONFIG.InfoColor,
        default = true, order = 4,
        onChange = function(v) espState.tracers = v end,
    })

    newToggle(scroll, {
        text = "Chams (corpo colorido)", icon = "check-circle-2", iconColor = CONFIG.InfoColor,
        order = 5,
        onChange = function(v) espState.chams = v end,
    })

    newToggle(scroll, {
        text = "Team Check (aliados verdes)", icon = "users", iconColor = CONFIG.InfoColor,
        order = 6,
        onChange = function(v) espState.teamCheck = v end,
    })
end

-- ==========================================================
-- APP 6: JOGADORES (Spectate + Highlight + Teleport)
-- ==========================================================
do
    local win, body = createAppWindow("playerlist", "Jogadores", "users")
    local stopSpectate -- forward declaration: usado no botão "Parar" abaixo
    addAppIcon("playerlist", "Jogadores", "users", 6, CONFIG.WarningColor)

    local spectating = nil
    local spectateCharConn = nil
    local highlighted = {} -- [player] = connection

    -- ===== BARRA DE STATUS DE SPECTATE =====
    local statusCard = create("Frame", {
        Parent = body, Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = CONFIG.CardColor,
    }, { corner(12) })

    local eyeHolder = create("Frame", {
        Parent = statusCard, Position = UDim2.new(0, 10, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20), BackgroundTransparency = 1,
    }, {})
    lucideIcon(eyeHolder, "eye", CONFIG.WarningColor, 18)

    create("TextLabel", {
        Parent = statusCard, Position = UDim2.new(0, 38, 0, 5),
        Size = UDim2.new(1, -150, 0, 14), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = CONFIG.SubTextColor, Text = "SPECTATE",
    }, {})

    local spectateStatus = create("TextLabel", {
        Parent = statusCard, Position = UDim2.new(0, 38, 0, 19),
        Size = UDim2.new(1, -150, 0, 18), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = CONFIG.SubTextColor, Text = "ninguém", TextTruncate = Enum.TextTruncate.AtEnd,
    }, {})

    newIconButton(statusCard, {
        text = "Parar", icon = "x", iconColor = Color3.fromRGB(255, 90, 90),
        bg = Color3.fromRGB(50, 28, 32), size = UDim2.new(0, 72, 0, 28),
        position = UDim2.new(1, -80, 0.5, -14),
        onClick = function() stopSpectate and stopSpectate() end,
    })

    -- ===== LISTA DE JOGADORES =====
    local playerScroll = create("ScrollingFrame", {
        Parent = body, Position = UDim2.new(0, 0, 0, 54), Size = UDim2.new(1, 0, 1, -54),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 4, ScrollBarImageColor3 = CONFIG.WarningColor,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, {})
    create("UIListLayout", { Parent = playerScroll, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

    local function getAvatar(player)
        return "rbxasset://textures/ui/GuiImagePlaceholder.png"
    end

    local function applyHighlight(char)
        if not char or char:FindFirstChild("yoaredevs_HL") then return end
        local hl = Instance.new("Highlight")
        hl.Name = "yoaredevs_HL"
        hl.FillColor = CONFIG.WarningColor
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.55
        hl.OutlineTransparency = 0
        hl.Parent = char
    end

    local function setHighlight(player, on)
        local char = player.Character
        if char then
            local old = char:FindFirstChild("yoaredevs_HL")
            if old then old:Destroy() end
        end
        if on then
            applyHighlight(player.Character)
            highlighted[player] = player.CharacterAdded:Connect(function(newChar)
                task.wait(0.3)
                applyHighlight(newChar)
            end)
            Notify("Highlight", player.Name .. " destacado", "check")
        else
            if highlighted[player] then highlighted[player]:Disconnect() end
            highlighted[player] = nil
            Notify("Highlight", player.Name .. " sem destaque", "x")
        end
    end

    local function isHighlighted(player)
        return highlighted[player] ~= nil
    end

    local function teleportTo(player)
        local tRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local lRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if tRoot and lRoot then
            lRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
            Notify("Teleport", "Teleportado para " .. player.Name, "trending-up")
        else
            Notify("Teleport", "Personagem não encontrado", "triangle-alert")
        end
    end

    local refreshPlayers -- declarado aqui pra ser acessível dentro das funções abaixo

    stopSpectate = function(silent)
        if spectateCharConn then spectateCharConn:Disconnect(); spectateCharConn = nil end
        spectating = nil

        local lChar = LocalPlayer.Character
        local lHum = lChar and lChar:FindFirstChildOfClass("Humanoid")
        if lHum then Camera.CameraSubject = lHum end

        spectateStatus.Text = "ninguém"
        spectateStatus.TextColor3 = CONFIG.SubTextColor
        if not silent then Notify("Spectate", "Você parou de observar", "eye") end
        if refreshPlayers then refreshPlayers() end
    end

    local function startSpectate(player)
        if spectateCharConn then spectateCharConn:Disconnect(); spectateCharConn = nil end
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then
            Notify("Spectate", player.Name .. " está sem personagem", "triangle-alert")
            return
        end
        spectating = player
        Camera.CameraSubject = hum

        -- troca automática quando o alvo respawna
        spectateCharConn = player.CharacterAdded:Connect(function(newChar)
            task.wait(0.5)
            if spectating == player then
                local newHum = newChar and newChar:FindFirstChildOfClass("Humanoid")
                if newHum then Camera.CameraSubject = newHum end
            end
        end)

        spectateStatus.Text = player.Name
        spectateStatus.TextColor3 = CONFIG.SuccessColor
        Notify("Spectate", "Observando " .. player.Name, "eye")
        refreshPlayers()
    end

    local function createPlayerCard(player, order)
        if player == LocalPlayer then return end

        local card = create("Frame", {
            Parent = playerScroll, Size = UDim2.new(1, -4, 0, 96),
            BackgroundColor3 = CONFIG.CardColor, LayoutOrder = order,
        }, { corner(12) })

        -- Avatar
        local avatar = create("ImageLabel", {
            Parent = card, Position = UDim2.new(0, 8, 0, 10),
            Size = UDim2.new(0, 34, 0, 34), BackgroundColor3 = Color3.fromRGB(30, 34, 45),
            BorderSizePixel = 0, Image = getAvatar(player),
        }, { create("UICorner", { CornerRadius = UDim.new(0, 17) }) })

        -- busca o avatar de verdade (async)
        task.spawn(function()
            local ok, content = pcall(Players.GetUserThumbnailAsync, Players,
                player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            if ok and avatar.Parent then avatar.Image = content end
        end)

        -- Nome + status
        local isSpec = (spectating == player)
        create("TextLabel", {
            Parent = card, Position = UDim2.new(0, 50, 0, 10),
            Size = UDim2.new(1, -60, 0, 17), BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold, TextSize = 13,
            TextColor3 = isSpec and CONFIG.SuccessColor or CONFIG.TextColor,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            Text = player.Name .. (isSpec and "  ● (observando)" or ""),
        }, {})

        local distText = create("TextLabel", {
            Parent = card, Position = UDim2.new(0, 50, 0, 27),
            Size = UDim2.new(1, -60, 0, 13), BackgroundTransparency = 1,
            Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = CONFIG.SubTextColor, Text = "distância: ...",
        }, {})

        -- atualiza distância em tempo real
        task.spawn(function()
            while card.Parent do
                local pRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local lRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if pRoot and lRoot then
                    distText.Text = "distância: " .. math.floor((pRoot.Position - lRoot.Position).Magnitude) .. " studs"
                else
                    distText.Text = "distância: N/A"
                end
                task.wait(1)
            end
        end)

        -- Botões com ícones
        local bgSpec  = isSpec and CONFIG.SuccessColor or Color3.fromRGB(35, 48, 60)
        local bgHl    = isHighlighted(player) and CONFIG.WarningColor or Color3.fromRGB(35, 48, 60)

        newIconButton(card, {
            text = "Espectar", icon = "eye", iconColor = Color3.fromRGB(255,255,255),
            bg = bgSpec, size = UDim2.new(0, 86, 0, 26), position = UDim2.new(0, 8, 0, 44),
            onClick = function()
                if spectating == player then stopSpectate() else startSpectate(player) end
            end,
        })

        newIconButton(card, {
            text = "Destacar", icon = "check-circle-2", iconColor = Color3.fromRGB(255,255,255),
            bg = bgHl, size = UDim2.new(0, 86, 0, 26), position = UDim2.new(0, 100, 0, 44),
            onClick = function()
                setHighlight(player, not isHighlighted(player))
                refreshPlayers()
            end,
        })

        newIconButton(card, {
            text = "Teleportar", icon = "trending-up", iconColor = Color3.fromRGB(255,255,255),
            size = UDim2.new(0, 90, 0, 26), position = UDim2.new(0, 192, 0, 44),
            onClick = function() teleportTo(player) end,
        })
    end

    refreshPlayers = function()
        for _, child in ipairs(playerScroll:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end

        local count = 0
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                count = count + 1
                createPlayerCard(player, count)
            end
        end

        if count == 0 then
            create("TextLabel", {
                Parent = playerScroll, Size = UDim2.new(1, 0, 0, 60),
                BackgroundTransparency = 1, Font = Enum.Font.Gotham,
                Text = "Nenhum outro jogador no servidor",
                TextSize = 12, TextColor3 = CONFIG.SubTextColor,
            }, {})
        end
    end

    -- Eventos automáticos
    Players.PlayerAdded:Connect(function()
        task.wait(0.5)
        refreshPlayers()
    end)

    Players.PlayerRemoving:Connect(function(player)
        if spectating == player then stopSpectate(true) end
        if highlighted[player] then
            highlighted[player]:Disconnect()
            highlighted[player] = nil
        end
        task.wait(0.1)
        refreshPlayers()
    end)

    -- Restaura a câmera quando o jogador local respawna e não está espectando
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if not spectating then
            local lChar = LocalPlayer.Character
            local lHum = lChar and lChar:FindFirstChildOfClass("Humanoid")
            if lHum then Camera.CameraSubject = lHum end
        end
    end)

    -- Refresh da lista sempre que o app é aberto
    local _prevOpenApp = OpenApp
    OpenApp = function(name)
        _prevOpenApp(name)
        if name == "playerlist" then
            task.defer(function() refreshPlayers() end)
        end
    end

    refreshPlayers()
end

-- RESPONSIVE MOBILE
-- ==========================================================
-- Precisa ser declarado ANTES de refreshPhoneLayout, senão a função
-- captura a variável global "phoneOpen" (nil) em vez desta local,
-- e o redimensionamento pensa que o celular está sempre fechado.
local phoneOpen = false

local function refreshPhoneLayout()
    local newSize = getPhoneSize()

    if not phoneOpen then
        PhoneFrame.Size = UDim2.new(0, 0, 0, 0)
        PhoneShadow.Size = newSize
        return
    end

    PhoneFrame.Size = newSize
    PhoneShadow.Size = newSize
    PhoneShadow.Position = UDim2.new(0.5, 0, 0.5, 8)
end

local function hookViewport()
    Camera = workspace.CurrentCamera
    if Camera then
        Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            task.defer(refreshPhoneLayout)
        end)
    end
end
hookViewport()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookViewport)

-- ==========================================================
-- ABRIR / FECHAR O CELULAR
-- ==========================================================
refreshPhoneLayout()

local function togglePhone()
    phoneOpen = not phoneOpen

    local responsiveSize = getPhoneSize()
    local phoneHeight = responsiveSize.Y.Offset

    if phoneOpen then
        PhoneFrame.Visible = true
        PhoneShadow.Visible = true

        -- Começa abaixo do ecrã e sobe para o centro.
        PhoneFrame.Size = responsiveSize
        PhoneFrame.Position = UDim2.new(0.5, 0, 1, phoneHeight / 2 + 28)

        PhoneShadow.Size = responsiveSize
        PhoneShadow.Position = UDim2.new(0.5, 0, 1, phoneHeight / 2 + 36)
        PhoneShadow.BackgroundTransparency = 1

        local phoneScale = scaleObject(PhoneFrame, 0.96)
        local shadowScale = scaleObject(PhoneShadow, 0.96)

        tween(PhoneFrame, {
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }, 0.58, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        tween(phoneScale, {
            Scale = 1
        }, 0.52, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        tween(PhoneShadow, {
            Position = UDim2.new(0.5, 0, 0.5, 9),
            BackgroundTransparency = 0.58
        }, 0.50, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        tween(shadowScale, {
            Scale = 1
        }, 0.50, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    else
        local phoneScale = scaleObject(PhoneFrame, 1)
        local shadowScale = scaleObject(PhoneShadow, 1)

        -- Ao fechar, desce novamente para fora do ecrã.
        tween(phoneScale, {Scale = 0.97}, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        tween(shadowScale, {Scale = 0.97}, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

        local t = tween(PhoneFrame, {
            Position = UDim2.new(0.5, 0, 1, phoneHeight / 2 + 28)
        }, 0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

        tween(PhoneShadow, {
            Position = UDim2.new(0.5, 0, 1, phoneHeight / 2 + 36),
            BackgroundTransparency = 1
        }, 0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

        t.Completed:Connect(function()
            PhoneFrame.Visible = false
            PhoneShadow.Visible = false
            phoneScale.Scale = 1
            shadowScale.Scale = 1
        end)
    end
end

Bubble.MouseButton1Click:Connect(togglePhone)

-- A barra branca inferior funciona como o gesto "home" de um telemóvel.
HomeIndicator.MouseButton1Click:Connect(function()
    if phoneOpen then
        togglePhone()
    end
end)

task.delay(1, function()
    Notify("yoaredevs", "Celular carregado", "info")
end)

end, function(m)
    return debug.traceback(tostring(m), 2)
end)

if not _ok then
    warn("[yoaredevs Phone] ERRO:\n" .. tostring(_err))
end