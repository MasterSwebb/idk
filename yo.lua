-- Exotic Hub UI v1.0
-- Completely revamped modern dark neon theme UI

local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Client = Players.LocalPlayer
local CGUI = game:GetService("CoreGui")

local InterfaceName = "ExoticHubUI"

-- Destroy old GUI if exists
if gethui() then
    for _, v in ipairs(gethui():GetChildren()) do if v.Name == InterfaceName then v:Destroy() end end
elseif CGUI:FindFirstChild(InterfaceName) then
    CGUI[InterfaceName]:Destroy()
end

-- Create main window
local ExoticHub = Instance.new("ScreenGui")
ExoticHub.Name = InterfaceName
ExoticHub.ResetOnSpawn = false
ExoticHub.Parent = CGUI

local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.new(0, 600, 0, 400)
Window.Position = UDim2.new(0.5, -300, 0.5, -200)
Window.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Window.BorderSizePixel = 0
Window.AnchorPoint = Vector2.new(0.5, 0.5)
Window.ClipsDescendants = true
Window.Parent = ExoticHub
Window.AutoButtonColor = false

-- Rounded corners and shadow
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 15)
Corner.Parent = Window

local Shadow = Instance.new("UIStroke")
Shadow.Thickness = 2
Shadow.Color = Color3.fromRGB(0, 255, 255)
Shadow.Parent = Window

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TitleBar.Parent = Window

local TitleText = Instance.new("TextLabel")
TitleText.Text = "Exotic Hub"
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 20
TitleText.TextColor3 = Color3.fromRGB(0, 255, 255)
TitleText.BackgroundTransparency = 1
TitleText.Size = UDim2.new(1, -50, 1, 0)
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.Parent = TitleBar
CloseBtn.MouseButton1Click:Connect(function() ExoticHub:Destroy() end)

-- Sidebar tabs
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 150, 1, -35)
Sidebar.Position = UDim2.new(0, 0, 0, 35)
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Sidebar.Parent = Window

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.Parent = Sidebar

-- Tab sections container
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -150, 1, -35)
Content.Position = UDim2.new(0, 150, 0, 35)
Content.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Content.Parent = Window

-- Utility function for creating tab buttons
local function CreateTabButton(name)
    local btn = Instance.new("TextButton")
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(0, 255, 255)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.AutoButtonColor = false
    btn.ClipsDescendants = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn

    local hover = Instance.new("UIStroke")
    hover.Color = Color3.fromRGB(0, 255, 255)
    hover.Thickness = 1
    hover.Parent = btn
    hover.Transparency = 1

    btn.MouseEnter:Connect(function() TS:Create(hover, TweenInfo.new(0.2), {Transparency = 0}):Play() end)
    btn.MouseLeave:Connect(function() TS:Create(hover, TweenInfo.new(0.2), {Transparency = 1}):Play() end)

    btn.Parent = Sidebar
    return btn
end

-- Example tabs
local tabs = {"Aimbot", "ESP", "Misc", "Settings"}
local TabFrames = {}

for i, tabName in ipairs(tabs) do
    local tabBtn = CreateTabButton(tabName)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = (i == 1)
    frame.Parent = Content
    TabFrames[tabName] = frame

    tabBtn.MouseButton1Click:Connect(function()
        for _, f in pairs(TabFrames) do f.Visible = false end
        frame.Visible = true
    end)
end

-- Components utility functions
local function CreateToggle(parent, name, default, callback)
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(1, -20, 0, 40)
    toggle.Position = UDim2.new(0, 10, 0, #parent:GetChildren()*45)
    toggle.BackgroundColor3 = Color3.fromRGB(35,35,35)
    toggle.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = toggle

    local label = Instance.new("TextLabel")
    label.Text = name
    label.Font = Enum.Font.Gotham
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(0, 255, 255)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Parent = toggle

    local switch = Instance.new("Frame")
    switch.Size = UDim2.new(0, 30, 0, 15)
    switch.Position = UDim2.new(1, -40, 0, 12)
    switch.BackgroundColor3 = default and Color3.fromRGB(0,255,255) or Color3.fromRGB(50,50,50)
    switch.AnchorPoint = Vector2.new(0,0)
    switch.Parent = toggle

    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 7)
    corner2.Parent = switch

    local value = default
    toggle.InputBegan:Connect(function()
        value = not value
        switch.BackgroundColor3 = value and Color3.fromRGB(0,255,255) or Color3.fromRGB(50,50,50)
        if callback then pcall(callback, value) end
    end)
end

local function CreateSlider(parent, name, min, max, default, callback)
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(1, -20, 0, 40)
    slider.Position = UDim2.new(0, 10, 0, #parent:GetChildren()*45)
    slider.BackgroundColor3 = Color3.fromRGB(35,35,35)
    slider.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,10)
    corner.Parent = slider

    local label = Instance.new("TextLabel")
    label.Text = name.." : "..default
    label.Font = Enum.Font.Gotham
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(0,255,255)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1,0,0.5,0)
    label.Parent = slider

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 10)
    bar.Position = UDim2.new(0,10,0,25)
    bar.BackgroundColor3 = Color3.fromRGB(50,50,50)
    bar.Parent = slider

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(0,255,255)
    fill.Parent = bar

    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
            local x = math.clamp(input.Position.X - bar.AbsolutePosition.X,0,bar.AbsoluteSize.X)
            local val = min + (x/bar.AbsoluteSize.X)*(max-min)
            fill.Size = UDim2.new((val-min)/(max-min),0,1,0)
            label.Text = name.." : "..math.floor(val)
            if callback then pcall(callback, val) end
        end
    end)
end

-- Example components in first tab
local TabAimbot = TabFrames["Aimbot"]
CreateToggle(TabAimbot,"Silent Aim",false,function(v) print("Silent Aim:",v) end)
CreateSlider(TabAimbot,"FOV",10,360,90,function(v) print("FOV:",v) end)

