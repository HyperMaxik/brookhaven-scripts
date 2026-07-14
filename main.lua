--[[
    ECLIPSE HUB | Brookhaven RP
    Made for Delta X Executor
    Version: 1.1.0
]]

--==================================================--
--  CONSOLE + LOGGING
--==================================================--
pcall(function()
    if rconsolecreate then rconsolecreate("Eclipse Hub") end
end)

local function Log(msg)
    print("[EclipseHub] " .. tostring(msg))
    pcall(function() if rconsoleprint then rconsoleprint("[EclipseHub] " .. tostring(msg) .. "\n") end end)
end

local function LogErr(msg)
    warn("[EclipseHub] [ERROR] " .. tostring(msg))
    pcall(function() if rconsoleprint then rconsoleprint("[EclipseHub] [ERROR] " .. tostring(msg) .. "\n") end end)
end

print("====================================")
print("   ECLIPSE HUB - Brookhaven RP v1.1")
print("   Executor: " .. (identifyexecutor and identifyexecutor() or "unknown"))
print("====================================")

--==================================================--
--  MAIN PCALL WRAPPER
--==================================================--
local ok, err = pcall(function()

--==================================================--
--  SERVICES
--==================================================--
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local StarterGui        = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera       = Workspace.CurrentCamera

Log("Services loaded")

--==================================================--
--  STATE
--==================================================--
local Eclipse = {
    Flags = {},
    Connections = {},
    Theme = {
        Background    = Color3.fromRGB(20, 20, 28),
        Sidebar       = Color3.fromRGB(26, 26, 36),
        Accent        = Color3.fromRGB(138, 99, 255),
        Text          = Color3.fromRGB(235, 235, 245),
        TextDark      = Color3.fromRGB(150, 150, 165),
        Element       = Color3.fromRGB(34, 34, 46),
        ElementHover  = Color3.fromRGB(42, 42, 56),
        Stroke        = Color3.fromRGB(50, 50, 65),
        Green         = Color3.fromRGB(80, 220, 130),
        Red           = Color3.fromRGB(235, 80, 90),
    },
}

--==================================================--
--  UTILITIES
--==================================================--
local function Round(n, d) local m = 10 ^ (d or 0) return math.floor(n * m + 0.5) / m end

local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = duration or 3,
        })
    end)
end

local function Create(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then obj[k] = v end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    if props and props.Parent then
        obj.Parent = props.Parent
    end
    return obj
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

--==================================================--
--  PARENT GUI (fallback chain)
--==================================================--
local parentGui

-- 1) gethui() — best for executors
if gethui then
    pcall(function() parentGui = gethui() end)
    Log("gethui() result: " .. tostring(parentGui and parentGui.Name or "nil"))
end

-- 2) CoreGui
if not parentGui then
    pcall(function() parentGui = CoreGui end)
    Log("Using CoreGui as parent")
end

-- 3) PlayerGui fallback
if not parentGui then
    pcall(function() parentGui = LocalPlayer:WaitForChild("PlayerGui") end)
    Log("Using PlayerGui as parent")
end

-- Destroy old instance
local old = parentGui and parentGui:FindFirstChild("EclipseHub")
if old then
    Log("Destroying old EclipseHub instance")
    old:Destroy()
end

Log("Creating ScreenGui...")

--==================================================--
--  UI LIBRARY
--==================================================--
local UI = {}
UI.Tabs = {}

local ScreenGui = Create("ScreenGui", {
    Name              = "EclipseHub",
    ResetOnSpawn      = false,
    ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,
    DisplayOrder      = 999,
    IgnoreGuiInset    = true,
})
ScreenGui.Parent = parentGui

Log("ScreenGui parented to: " .. tostring(parentGui and parentGui.Name or "NONE"))

-- Blur
local Blur = Create("BlurEffect", {
    Name   = "EclipseBlur",
    Size   = 0,
    Parent = Lighting,
})
TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 12}):Play()

-- Main Window
local MainWindow = Create("Frame", {
    Name             = "MainWindow",
    Parent           = ScreenGui,
    AnchorPoint      = Vector2.new(0.5, 0.5),
    Position         = UDim2.new(0.5, 0, 0.5, 0),
    Size             = UDim2.new(0, 560, 0, 380),
    BackgroundColor3 = Eclipse.Theme.Background,
    Active           = true,
}, {
    Create("UICorner", { CornerRadius = UDim.new(0, 12) }),
    Create("UIStroke", { Color = Eclipse.Theme.Stroke, Thickness = 1 }),
})

MakeDraggable(MainWindow)
Log("MainWindow created")

-- Sidebar
local Sidebar = Create("Frame", {
    Name             = "Sidebar",
    Parent           = MainWindow,
    Size             = UDim2.new(0, 160, 1, 0),
    BackgroundColor3 = Eclipse.Theme.Sidebar,
}, {
    Create("UICorner", { CornerRadius = UDim.new(0, 12) }),
})

Create("Frame", {
    Parent           = Sidebar,
    Size             = UDim2.new(0, 12, 1, 0),
    Position         = UDim2.new(1, -12, 0, 0),
    BackgroundColor3 = Eclipse.Theme.Sidebar,
    BorderSizePixel  = 0,
})

Create("TextLabel", {
    Parent           = Sidebar,
    Size             = UDim2.new(1, 0, 0, 50),
    Position         = UDim2.new(0, 0, 0, 10),
    BackgroundTransparency = 1,
    Text             = "ECLIPSE",
    TextColor3       = Eclipse.Theme.Text,
    TextSize         = 22,
    Font             = Enum.Font.GothamBold,
    TextXAlignment   = Enum.TextXAlignment.Center,
})

Create("TextLabel", {
    Parent           = Sidebar,
    Size             = UDim2.new(1, 0, 0, 16),
    Position         = UDim2.new(0, 0, 0, 38),
    BackgroundTransparency = 1,
    Text             = "Brookhaven RP",
    TextColor3       = Eclipse.Theme.Accent,
    TextSize         = 11,
    Font             = Enum.Font.Gotham,
    TextXAlignment   = Enum.TextXAlignment.Center,
})

local TabList = Create("Frame", {
    Name             = "TabList",
    Parent           = Sidebar,
    Size             = UDim2.new(1, -20, 1, -90),
    Position         = UDim2.new(0, 10, 0, 75),
    BackgroundTransparency = 1,
}, {
    Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local ContentArea = Create("Frame", {
    Name             = "Content",
    Parent           = MainWindow,
    Size             = UDim2.new(1, -170, 1, -20),
    Position         = UDim2.new(0, 165, 0, 10),
    BackgroundTransparency = 1,
})

-- Close button
local CloseBtn = Create("TextButton", {
    Parent           = MainWindow,
    Size             = UDim2.new(0, 24, 0, 24),
    Position         = UDim2.new(1, -30, 0, 6),
    BackgroundColor3 = Eclipse.Theme.Red,
    Text             = "",
    AutoButtonColor  = false,
}, {
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
})

Create("ImageLabel", {
    Parent           = CloseBtn,
    Size             = UDim2.new(0, 12, 0, 12),
    Position         = UDim2.new(0.5, -6, 0.5, -6),
    BackgroundTransparency = 1,
    Image            = "rbxassetid://3926305904",
    ImageRectOffset  = Vector2.new(284, 4),
    ImageRectSize    = Vector2.new(24, 24),
})

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Blur, TweenInfo.new(0.3), {Size = 0}):Play()
    TweenService:Create(MainWindow, TweenInfo.new(0.3), {Size = UDim2.new(0, 560, 0, 0)}):Play()
    task.wait(0.3)
    ScreenGui:Destroy()
    if Blur then Blur:Destroy() end
end)

-- Minimize button
local MinBtn = Create("TextButton", {
    Parent           = MainWindow,
    Size             = UDim2.new(0, 24, 0, 24),
    Position         = UDim2.new(1, -60, 0, 6),
    BackgroundColor3 = Eclipse.Theme.Element,
    Text             = "",
    AutoButtonColor  = false,
}, {
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
})

Create("ImageLabel", {
    Parent           = MinBtn,
    Size             = UDim2.new(0, 12, 0, 12),
    Position         = UDim2.new(0.5, -6, 0.5, -6),
    BackgroundTransparency = 1,
    Image            = "rbxassetid://3926305904",
    ImageRectOffset  = Vector2.new(116, 204),
    ImageRectSize    = Vector2.new(24, 24),
})

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(MainWindow, TweenInfo.new(0.25), {Size = UDim2.new(0, 560, 0, 50)}):Play()
        ContentArea.Visible = false
        Sidebar.Visible = false
    else
        TweenService:Create(MainWindow, TweenInfo.new(0.25), {Size = UDim2.new(0, 560, 0, 380)}):Play()
        task.wait(0.25)
        ContentArea.Visible = true
        Sidebar.Visible = true
    end
end)

--==================================================--
--  TAB SYSTEM
--==================================================--
local TabOrder = 0

function UI:AddTab(name)
    TabOrder = TabOrder + 1
    local tab = {}

    local TabBtn = Create("TextButton", {
        Parent           = TabList,
        Size             = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Eclipse.Theme.Element,
        Text             = "",
        AutoButtonColor  = false,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) }),
    })

    local TabLabel = Create("TextLabel", {
        Parent           = TabBtn,
        Size             = UDim2.new(1, -20, 1, 0),
        Position         = UDim2.new(0, 20, 0, 0),
        BackgroundTransparency = 1,
        Text             = name,
        TextColor3       = Eclipse.Theme.TextDark,
        TextSize         = 14,
        Font             = Enum.Font.GothamMedium,
        TextXAlignment   = Enum.TextXAlignment.Left,
    })

    local Page = Create("ScrollingFrame", {
        Parent           = ContentArea,
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Eclipse.Theme.Accent,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible          = false,
    }, {
        Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
        Create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }),
    })

    tab.Button = TabBtn
    tab.Page   = Page
    tab.Label  = TabLabel

    local function Select()
        for _, t in pairs(UI.Tabs) do
            t.Button.BackgroundColor3 = Eclipse.Theme.Element
            t.Label.TextColor3 = Eclipse.Theme.TextDark
            t.Page.Visible = false
        end
        TabBtn.BackgroundColor3 = Eclipse.Theme.Accent
        TabLabel.TextColor3 = Eclipse.Theme.Text
        Page.Visible = true
    end

    TabBtn.MouseButton1Click:Connect(Select)
    if TabOrder == 1 then Select() end

    function tab:AddSection(title)
        Create("TextLabel", {
            Parent           = Page,
            Size             = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text             = string.upper(title),
            TextColor3       = Eclipse.Theme.Accent,
            TextSize         = 12,
            Font             = Enum.Font.GothamBold,
            TextXAlignment   = Enum.TextXAlignment.Left,
        })
    end

    function tab:AddToggle(text, default, callback)
        local flag = text
        Eclipse.Flags[flag] = default or false

        local ToggleFrame = Create("Frame", {
            Parent           = Page,
            Size             = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Eclipse.Theme.Element,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        })

        Create("TextLabel", {
            Parent           = ToggleFrame,
            Size             = UDim2.new(1, -60, 1, 0),
            Position         = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text             = text,
            TextColor3       = Eclipse.Theme.Text,
            TextSize         = 14,
            Font             = Enum.Font.Gotham,
            TextXAlignment   = Enum.TextXAlignment.Left,
        })

        local SwitchBg = Create("Frame", {
            Parent           = ToggleFrame,
            Size             = UDim2.new(0, 40, 0, 20),
            Position         = UDim2.new(1, -50, 0.5, -10),
            BackgroundColor3 = default and Eclipse.Theme.Green or Eclipse.Theme.Stroke,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        })

        local SwitchKnob = Create("Frame", {
            Parent           = SwitchBg,
            Size             = UDim2.new(0, 16, 0, 16),
            Position         = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        }, {
            Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        })

        local ToggleBtn = Create("TextButton", {
            Parent           = ToggleFrame,
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text             = "",
            AutoButtonColor  = false,
        })

        local state = default or false
        local function Update()
            Eclipse.Flags[flag] = state
            local goal = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {Position = goal}):Play()
            TweenService:Create(SwitchBg, TweenInfo.new(0.2), {
                BackgroundColor3 = state and Eclipse.Theme.Green or Eclipse.Theme.Stroke
            }):Play()
            pcall(callback, state)
        end

        ToggleBtn.MouseButton1Click:Connect(function()
            state = not state
            Update()
        end)

        ToggleFrame.MouseEnter:Connect(function()
            TweenService:Create(ToggleFrame, TweenInfo.new(0.15), {BackgroundColor3 = Eclipse.Theme.ElementHover}):Play()
        end)
        ToggleFrame.MouseLeave:Connect(function()
            TweenService:Create(ToggleFrame, TweenInfo.new(0.15), {BackgroundColor3 = Eclipse.Theme.Element}):Play()
        end)

        return { Set = function(v) state = v Update() end, Get = function() return state end }
    end

    function tab:AddButton(text, callback)
        local Btn = Create("TextButton", {
            Parent           = Page,
            Size             = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Eclipse.Theme.Element,
            Text             = text,
            TextColor3       = Eclipse.Theme.Text,
            TextSize         = 14,
            Font             = Enum.Font.GothamMedium,
            AutoButtonColor  = false,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        })

        Btn.MouseButton1Click:Connect(function() pcall(callback) end)
        Btn.MouseEnter:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Eclipse.Theme.Accent}):Play()
        end)
        Btn.MouseLeave:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Eclipse.Theme.Element}):Play()
        end)
    end

    function tab:AddSlider(text, min, max, default, callback)
        local flag = text
        Eclipse.Flags[flag] = default or min

        local SliderFrame = Create("Frame", {
            Parent           = Page,
            Size             = UDim2.new(1, 0, 0, 50),
            BackgroundColor3 = Eclipse.Theme.Element,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        })

        Create("TextLabel", {
            Parent           = SliderFrame,
            Size             = UDim2.new(1, -20, 0, 20),
            Position         = UDim2.new(0, 12, 0, 6),
            BackgroundTransparency = 1,
            Text             = text,
            TextColor3       = Eclipse.Theme.Text,
            TextSize         = 13,
            Font             = Enum.Font.Gotham,
            TextXAlignment   = Enum.TextXAlignment.Left,
        })

        local ValueLabel = Create("TextLabel", {
            Parent           = SliderFrame,
            Size             = UDim2.new(0, 60, 0, 20),
            Position         = UDim2.new(1, -70, 0, 6),
            BackgroundTransparency = 1,
            Text             = tostring(default or min),
            TextColor3       = Eclipse.Theme.Accent,
            TextSize         = 13,
            Font             = Enum.Font.GothamBold,
            TextXAlignment   = Enum.TextXAlignment.Right,
        })

        local Track = Create("Frame", {
            Parent           = SliderFrame,
            Size             = UDim2.new(1, -24, 0, 6),
            Position         = UDim2.new(0, 12, 0, 34),
            BackgroundColor3 = Eclipse.Theme.Stroke,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        })

        local Fill = Create("Frame", {
            Parent           = Track,
            Size             = UDim2.new((default or min - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = Eclipse.Theme.Accent,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        })

        local Knob = Create("Frame", {
            Parent           = Track,
            Size             = UDim2.new(0, 14, 0, 14),
            Position         = UDim2.new(Fill.Size.X.Scale, -7, 0.5, -7),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        }, {
            Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        })

        local dragging = false
        local function Update(input)
            local rel = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
            rel = math.clamp(rel, 0, 1)
            local val = Round(min + (max - min) * rel, 0)
            Eclipse.Flags[flag] = val
            ValueLabel.Text = tostring(val)
            Fill.Size = UDim2.new(rel, 0, 1, 0)
            Knob.Position = UDim2.new(rel, -7, 0.5, -7)
            pcall(callback, val)
        end

        Track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                Update(input)
            end
        end)
        Track.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                Update(input)
            end
        end)
    end

    function tab:AddDropdown(text, options, callback)
        local flag = text
        Eclipse.Flags[flag] = options[1]

        local DropFrame = Create("Frame", {
            Parent           = Page,
            Size             = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Eclipse.Theme.Element,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        })

        local DropLabel = Create("TextLabel", {
            Parent           = DropFrame,
            Size             = UDim2.new(1, -40, 1, 0),
            Position         = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text             = text .. ": " .. options[1],
            TextColor3       = Eclipse.Theme.Text,
            TextSize         = 13,
            Font             = Enum.Font.Gotham,
            TextXAlignment   = Enum.TextXAlignment.Left,
        })

        local ListFrame = Create("Frame", {
            Parent           = DropFrame,
            Size             = UDim2.new(1, 0, 0, 0),
            Position         = UDim2.new(0, 0, 0, 40),
            BackgroundColor3 = Eclipse.Theme.Sidebar,
            Visible          = false,
            ZIndex           = 10,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
            Create("UIListLayout", { Padding = UDim.new(0, 2) }),
        })

        local open = false
        local DropBtn = Create("TextButton", {
            Parent           = DropFrame,
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text             = "",
            AutoButtonColor  = false,
        })

        local function RefreshList()
            for _, c in ipairs(ListFrame:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _, opt in ipairs(options) do
                local OptBtn = Create("TextButton", {
                    Parent           = ListFrame,
                    Size             = UDim2.new(1, -8, 0, 28),
                    BackgroundColor3 = Eclipse.Theme.Element,
                    Text             = opt,
                    TextColor3       = Eclipse.Theme.Text,
                    TextSize         = 13,
                    Font             = Enum.Font.Gotham,
                    AutoButtonColor  = false,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                })
                OptBtn.MouseButton1Click:Connect(function()
                    Eclipse.Flags[flag] = opt
                    DropLabel.Text = text .. ": " .. opt
                    pcall(callback, opt)
                    open = false
                    ListFrame.Visible = false
                end)
            end
        end

        DropBtn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                RefreshList()
                ListFrame.Visible = true
                TweenService:Create(ListFrame, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, #options * 30)}):Play()
            else
                TweenService:Create(ListFrame, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                task.wait(0.15)
                ListFrame.Visible = false
            end
        end)

        return {
            Refresh = function(newOpts)
                options = newOpts
                if #options > 0 then
                    Eclipse.Flags[flag] = options[1]
                    DropLabel.Text = text .. ": " .. options[1]
                end
            end,
        }
    end

    function tab:AddLabel(text)
        Create("TextLabel", {
            Parent           = Page,
            Size             = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Text             = text,
            TextColor3       = Eclipse.Theme.TextDark,
            TextSize         = 13,
            Font             = Enum.Font.Gotham,
            TextXAlignment   = Enum.TextXAlignment.Left,
        })
    end

    table.insert(UI.Tabs, tab)
    return tab
end

Log("UI library ready")

--==================================================--
--  FEATURE MODULES
--==================================================--
local function GetChar()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then return char end
    return nil
end

local function GetRoot()
    local char = GetChar()
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

local function GetHum()
    local char = GetChar()
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

-- FLY
local FlyConfig = { Speed = 50, Enabled = false }
local FlyConn, BV, BG

local function StartFly()
    local root = GetRoot()
    if not root then return end
    BV = Create("BodyVelocity", { MaxForce = Vector3.new(9e9, 9e9, 9e9), Velocity = Vector3.zero, Parent = root })
    BG = Create("BodyGyro", { MaxForce = Vector3.new(9e9, 9e9, 9e9), P = 10000, CFrame = root.CFrame, Parent = root })
    FlyConn = RunService.RenderStepped:Connect(function()
        local hum = GetHum()
        local r = GetRoot()
        if not r or not BV then return end
        if hum then hum.PlatformStand = true end
        local dir = Vector3.zero
        local cam = Camera
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then dir = dir.Unit end
        BV.Velocity = dir * FlyConfig.Speed
        BG.CFrame = cam.CFrame
    end)
end

local function StopFly()
    if FlyConn then FlyConn:Disconnect() FlyConn = nil end
    local hum = GetHum()
    if hum then hum.PlatformStand = false end
    if BV then BV:Destroy() BV = nil end
    if BG then BG:Destroy() BG = nil end
end

-- NOCLIP
local NoclipConn
local function StartNoclip()
    NoclipConn = RunService.Stepped:Connect(function()
        local char = GetChar()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end)
end

local function StopNoclip()
    if NoclipConn then NoclipConn:Disconnect() NoclipConn = nil end
    local char = GetChar()
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end

-- INFINITE JUMP
local InfJumpConn
local function StartInfJump()
    InfJumpConn = UserInputService.JumpRequest:Connect(function()
        local hum = GetHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

local function StopInfJump()
    if InfJumpConn then InfJumpConn:Disconnect() InfJumpConn = nil end
end

-- ESP
local ESPObjects = {}
local ESPConn

local function ClearESP()
    for _, obj in pairs(ESPObjects) do
        pcall(function() obj:Destroy() end)
    end
    ESPObjects = {}
end

local function CreateESPForPlayer(plr)
    if plr == LocalPlayer then return end
    local function Build()
        local char = plr.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end

        local bb = Create("BillboardGui", {
            Name = "EclipseESP_" .. plr.Name,
            Adornee = head,
            Size = UDim2.new(0, 200, 0, 50),
            StudsOffset = Vector3.new(0, 2, 0),
            AlwaysOnTop = true,
            LightInfluence = 0,
        })

        local frame = Create("Frame", {
            Parent = bb,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
        })

        local nameLbl = Create("TextLabel", {
            Parent = frame,
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = plr.DisplayName,
            TextColor3 = Eclipse.Theme.Accent,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextStrokeTransparency = 0.5,
        })

        local distLbl = Create("TextLabel", {
            Parent = frame,
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.new(0, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = Eclipse.Theme.Text,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextStrokeTransparency = 0.5,
        })

        bb.Parent = parentGui
        ESPObjects[plr.UserId] = bb

        task.spawn(function()
            while ESPObjects[plr.UserId] do
                local r = GetRoot()
                local theirChar = plr.Character
                local theirHead = theirChar and theirChar:FindFirstChild("Head")
                if r and theirHead then
                    local dist = (r.Position - theirHead.Position).Magnitude
                    distLbl.Text = string.format("%.0f studs", dist)
                end
                task.wait(0.2)
            end
        end)
    end

    if plr.Character then Build() end
    plr.CharacterAdded:Connect(Build)
end

local function StartESP()
    for _, plr in ipairs(Players:GetPlayers()) do CreateESPForPlayer(plr) end
    ESPConn = Players.PlayerAdded:Connect(CreateESPForPlayer)
end

local function StopESP()
    if ESPConn then ESPConn:Disconnect() ESPConn = nil end
    ClearESP()
end

-- FULLBRIGHT
local FullbrightConn
local origBrightness, origClock, origFogEnd, origFogStart

local function StartFullbright()
    origBrightness = Lighting.Brightness
    origClock = Lighting.ClockTime
    origFogEnd = Lighting.FogEnd
    origFogStart = Lighting.FogStart
    FullbrightConn = RunService.RenderStepped:Connect(function()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e10
        Lighting.FogStart = 1e10
    end)
end

local function StopFullbright()
    if FullbrightConn then FullbrightConn:Disconnect() FullbrightConn = nil end
    if origBrightness then Lighting.Brightness = origBrightness end
    if origClock then Lighting.ClockTime = origClock end
    if origFogEnd then Lighting.FogEnd = origFogEnd end
    if origFogStart then Lighting.FogStart = origFogStart end
end

-- BTOOLS
local function GiveBTools()
    local char = GetChar()
    if not char then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end

    local function makeTool(name, action)
        local tool = Create("Tool", { Name = name, Parent = backpack, RequiresHandle = false })
        tool.Activated:Connect(function()
            local mouse = LocalPlayer:GetMouse()
            local target = mouse.Target
            if target and not target.Anchored then
                pcall(action, target, mouse)
            end
        end)
        return tool
    end

    makeTool("Delete", function(p) p:Destroy() end)
    makeTool("Move", function(p, mouse)
        local conn
        conn = RunService.RenderStepped:Connect(function()
            if p and p.Parent then
                p.CFrame = CFrame.new(mouse.Hit.Position)
            else
                conn:Disconnect()
            end
        end)
        task.delay(10, function() if conn then conn:Disconnect() end end)
    end)
    makeTool("Clone", function(p)
        local clone = p:Clone()
        clone.Parent = Workspace
        clone.CFrame = p.CFrame + Vector3.new(0, 5, 0)
    end)
    Notify("Eclipse Hub", "BTools выданы!", 4)
end

-- TELEPORT
local TeleportSpots = {
    { name = "Spawn",       pos = Vector3.new(0, 5, 0) },
    { name = "City Center", pos = Vector3.new(-130, 5, -50) },
    { name = "Gas Station", pos = Vector3.new(280, 5, 120) },
    { name = "School",      pos = Vector3.new(-200, 5, -300) },
    { name = "Hospital",    pos = Vector3.new(150, 5, -200) },
    { name = "Police Dept", pos = Vector3.new(-50, 5, 250) },
    { name = "Lake",        pos = Vector3.new(-400, 5, -400) },
    { name = "Bridge",      pos = Vector3.new(0, 5, 400) },
}

local function TeleportTo(pos)
    local root = GetRoot()
    if root then root.CFrame = CFrame.new(pos) end
end

Log("Feature modules loaded")

--==================================================--
--  BUILD TABS
--==================================================--
Log("Building tabs...")

-- PLAYER TAB
local PlayerTab = UI:AddTab("Player")

PlayerTab:AddSection("Movement")
PlayerTab:AddToggle("Fly (WASD + Space/Shift)", false, function(val)
    FlyConfig.Enabled = val
    if val then StartFly() else StopFly() end
end)
PlayerTab:AddSlider("Fly Speed", 10, 300, 50, function(val) FlyConfig.Speed = val end)
PlayerTab:AddToggle("Noclip", false, function(val)
    if val then StartNoclip() else StopNoclip() end
end)
PlayerTab:AddToggle("Infinite Jump", false, function(val)
    if val then StartInfJump() else StopInfJump() end
end)

PlayerTab:AddSection("Stats")
PlayerTab:AddSlider("Walk Speed", 16, 200, 16, function(val)
    local hum = GetHum()
    if hum then hum.WalkSpeed = val end
    Eclipse.Flags._ws = val
end)
PlayerTab:AddSlider("Jump Power", 50, 300, 50, function(val)
    local hum = GetHum()
    if hum then hum.JumpPower = val end
    Eclipse.Flags._jp = val
end)

PlayerTab:AddSection("Actions")
PlayerTab:AddButton("Reset Character", function()
    local char = GetChar()
    if char then char:BreakJoints() end
end)
PlayerTab:AddButton("Respawn", function() LocalPlayer:LoadCharacter() end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    local hum = GetHum()
    if hum then
        if Eclipse.Flags._ws then hum.WalkSpeed = Eclipse.Flags._ws end
        if Eclipse.Flags._jp then hum.JumpPower = Eclipse.Flags._jp end
    end
end)

Log("Player tab done")

-- TELEPORT TAB
local TeleportTab = UI:AddTab("Teleport")

TeleportTab:AddSection("Locations")
for _, spot in ipairs(TeleportSpots) do
    TeleportTab:AddButton(spot.name, function()
        TeleportTo(spot.pos)
        Notify("Eclipse Hub", "TP: " .. spot.name, 2)
    end)
end

TeleportTab:AddSection("Players")
local playerDropdown
local function RefreshPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    if #list == 0 then list = { "No players" } end
    if playerDropdown then playerDropdown.Refresh(list) end
end

playerDropdown = TeleportTab:AddDropdown("Teleport to", {"Loading..."}, function(selected)
    if selected == "No players" then return end
    local target = Players:FindFirstChild(selected)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local root = GetRoot()
        if root then
            root.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            Notify("Eclipse Hub", "TP to " .. selected, 2)
        end
    end
end)

TeleportTab:AddButton("Refresh Player List", RefreshPlayers)
RefreshPlayers()
Players.PlayerAdded:Connect(RefreshPlayers)
Players.PlayerRemoving:Connect(RefreshPlayers)

TeleportTab:AddSection("Tools")
TeleportTab:AddButton("Click TP (Q to stop)", function()
    local mouse = LocalPlayer:GetMouse()
    local conn
    Notify("Eclipse Hub", "Click TP активен. Q для стоп.", 4)
    conn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Q then
            conn:Disconnect()
            Notify("Eclipse Hub", "Click TP выключен.", 2)
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local root = GetRoot()
            if root and mouse.Hit then
                root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
            end
        end
    end)
end)

Log("Teleport tab done")

-- VISUALS TAB
local VisualsTab = UI:AddTab("Visuals")

VisualsTab:AddSection("World")
VisualsTab:AddToggle("Fullbright", false, function(val)
    if val then StartFullbright() else StopFullbright() end
end)
VisualsTab:AddSlider("FOV", 40, 120, 70, function(val) Camera.FieldOfView = val end)

VisualsTab:AddSection("Players")
VisualsTab:AddToggle("Player ESP", false, function(val)
    if val then StartESP() else StopESP() end
end)

Log("Visuals tab done")

-- FUN TAB
local FunTab = UI:AddTab("Fun")

FunTab:AddSection("Tools")
FunTab:AddButton("Give BTools", GiveBTools)
FunTab:AddButton("Grab All Tools (BH)", function()
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
            local char = GetChar()
            if char then obj.Parent = char count = count + 1 end
        end
    end
    Notify("Eclipse Hub", "Взято инструментов: " .. count, 3)
end)

FunTab:AddSection("Trolling")
FunTab:AddButton("Sit on nearest", function()
    local root = GetRoot()
    if not root then return end
    local nearest, nearestDist
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (root.Position - plr.Character.HumanoidRootPart.Position).Magnitude
            if not nearestDist or dist < nearestDist then nearest = plr nearestDist = dist end
        end
    end
    if nearest and nearest.Character:FindFirstChild("Humanoid") then
        local hum = GetHum()
        if hum then
            hum.Sit = true
            task.wait(0.1)
            root.CFrame = nearest.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            Notify("Eclipse Hub", "Сел на: " .. nearest.Name, 3)
        end
    end
end)

FunTab:AddButton("Fling nearest", function()
    local root = GetRoot()
    if not root then return end
    local nearest, nearestDist
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (root.Position - plr.Character.HumanoidRootPart.Position).Magnitude
            if not nearestDist or dist < nearestDist then nearest = plr nearestDist = dist end
        end
    end
    if nearest and nearest.Character:FindFirstChild("HumanoidRootPart") then
        local targetRoot = nearest.Character.HumanoidRootPart
        local bv = Create("BodyAngularVelocity", {
            AngularVelocity = Vector3.new(9e9, 9e9, 9e9),
            MaxTorque = Vector3.new(9e9, 9e9, 9e9),
            Parent = targetRoot,
        })
        local bv2 = Create("BodyVelocity", {
            Velocity = Vector3.new(0, 500, 0),
            MaxForce = Vector3.new(9e9, 9e9, 9e9),
            Parent = targetRoot,
        })
        task.wait(0.5)
        bv:Destroy()
        bv2:Destroy()
        Notify("Eclipse Hub", "Fling: " .. nearest.Name, 3)
    end
end)

FunTab:AddButton("Spin (toggle)", function()
    if Eclipse.Flags._spinning then
        Eclipse.Flags._spinning = false
        return
    end
    Eclipse.Flags._spinning = true
    task.spawn(function()
        while Eclipse.Flags._spinning do
            local root = GetRoot()
            if root then root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(5), 0) end
            task.wait()
        end
    end)
end)

Log("Fun tab done")

-- SETTINGS TAB
local SettingsTab = UI:AddTab("Settings")

SettingsTab:AddSection("UI")
SettingsTab:AddButton("Toggle UI (RightShift)", function()
    Notify("Eclipse Hub", "Нажми RightShift для UI", 3)
end)
SettingsTab:AddButton("Destroy UI", function()
    if Blur then Blur:Destroy() end
    ScreenGui:Destroy()
    StopFly() StopNoclip() StopInfJump() StopESP() StopFullbright()
end)

SettingsTab:AddSection("Info")
SettingsTab:AddLabel("Eclipse Hub v1.1.0")
SettingsTab:AddLabel("Game: Brookhaven RP")
SettingsTab:AddLabel("Executor: Delta X")

Log("Settings tab done")

-- KEYBINDS
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

-- INIT
Log("All tabs built! Total: " .. #UI.Tabs)
Notify("Eclipse Hub", "Загружен! RightShift для UI.", 5)
Log("Eclipse Hub loaded successfully!")

end) -- end of main pcall

--==================================================--
--  ERROR HANDLER
--==================================================--
if not ok then
    print("====================================")
    print("   ECLIPSE HUB - FATAL ERROR")
    print("   " .. tostring(err))
    print("====================================")
    pcall(function()
        if rconsoleprint then
            rconsoleprint("\n[EclipseHub] FATAL ERROR: " .. tostring(err) .. "\n")
        end
    end)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Eclipse Hub ERROR",
            Text  = tostring(err):sub(1, 200),
            Duration = 15,
        })
    end)
else
    print("====================================")
    print("   ECLIPSE HUB - LOADED OK")
    print("====================================")
end
