local SwebwareUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bozokongy-hash/uis/refs/heads/main/swebui.lua", true))()

-- Services (explicit declarations for obfuscation compatibility)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

-- Variables (explicit for obfuscation)
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Mouse = LocalPlayer:GetMouse()

-- Aimbot Variables
local FOVCircle = nil
local CurrentTarget = nil
local AimbotConnection = nil

-- Fly Variables
local FlyConnection = nil
local BodyVelocity = nil

-- ESP Storage
local ESPObjects = {}
local ChamsObjects = {}

-- Settings
local Settings = {
    Aimbot = {
        Enabled = false,
        FOV = 50,
        FOVColor = Color3.fromRGB(255, 255, 255),
        Type = "Mouse",
        Smoothing = 5,
        ShowFOV = true,
        TargetPart = "Head",
        WallCheck = false,
        TeamCheck = false
    },
    Visuals = {
        PlayerESP = false,
        NameESP = false,
        DistanceESP = false,
        ESPColor = Color3.fromRGB(255, 0, 0),
        PlayerChams = false,
        VisibleColor = Color3.fromRGB(0, 255, 0),
        HiddenColor = Color3.fromRGB(255, 0, 0)
    },
    Movement = {
        SpeedHack = false,
        SpeedValue = 16,
        Fly = false,
        FlySpeed = 50,
        InfiniteJump = false
    }
}

-- Aimbot Functions
local function CreateFOVCircle()
    if FOVCircle then FOVCircle:Remove() end
    
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Color = Settings.Aimbot.FOVColor
    FOVCircle.Thickness = 2
    FOVCircle.NumSides = 100
    FOVCircle.Radius = Settings.Aimbot.FOV
    FOVCircle.Filled = false
    FOVCircle.Transparency = 1
    FOVCircle.Visible = Settings.Aimbot.ShowFOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Settings.Aimbot.TargetPart) then
            -- Team check
            if Settings.Aimbot.TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end
            
            local targetPart = player.Character[Settings.Aimbot.TargetPart]
            local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            
            if onScreen then
                local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                
                if distance < Settings.Aimbot.FOV and distance < shortestDistance then
                    -- Wall check
                    if Settings.Aimbot.WallCheck then
                        local raycastParams = RaycastParams.new()
                        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                        
                        local raycastResult = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * (targetPart.Position - Camera.CFrame.Position).Magnitude, raycastParams)
                        
                        if raycastResult and raycastResult.Instance:IsDescendantOf(player.Character) then
                            closestPlayer = player
                            shortestDistance = distance
                        end
                    else
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

local function AimAt(target)
    if not target or not target.Character or not target.Character:FindFirstChild(Settings.Aimbot.TargetPart) then
        return
    end
    
    local targetPart = target.Character[Settings.Aimbot.TargetPart]
    local targetPosition = targetPart.Position
    
    if Settings.Aimbot.Type == "Mouse" then
        -- Mouse aimbot
        local screenPoint = Camera:WorldToViewportPoint(targetPosition)
        local mousePosition = Vector2.new(Mouse.X, Mouse.Y)
        local targetScreenPosition = Vector2.new(screenPoint.X, screenPoint.Y)
        
        local smoothedPosition = mousePosition:Lerp(targetScreenPosition, 1 / Settings.Aimbot.Smoothing)
        mousemoverel(smoothedPosition.X - mousePosition.X, smoothedPosition.Y - mousePosition.Y)
    else
        -- Camera aimbot
        local lookDirection = (targetPosition - Camera.CFrame.Position).Unit
        local newCFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + lookDirection)
        
        Camera.CFrame = Camera.CFrame:Lerp(newCFrame, 1 / Settings.Aimbot.Smoothing)
    end
end

local function StartAimbot()
    if AimbotConnection then
        AimbotConnection:Disconnect()
    end
    
    AimbotConnection = RunService.Heartbeat:Connect(function()
        if Settings.Aimbot.Enabled then
            CurrentTarget = GetClosestPlayer()
            if CurrentTarget then
                AimAt(CurrentTarget)
            end
        end
        
        -- Update FOV circle
        if FOVCircle then
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            FOVCircle.Radius = Settings.Aimbot.FOV
            FOVCircle.Visible = Settings.Aimbot.ShowFOV and Settings.Aimbot.Enabled
            FOVCircle.Color = Settings.Aimbot.FOVColor
        end
    end)
end

-- Fly Functions
local function StartFly()
    if not Character or not RootPart then return end
    
    if BodyVelocity then BodyVelocity:Destroy() end
    
    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    BodyVelocity.Velocity = Vector3.new(0, 0, 0)
    BodyVelocity.Parent = RootPart
    
    -- Disable gravity
    RootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    RootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    
    if FlyConnection then FlyConnection:Disconnect() end
    
    FlyConnection = RunService.Heartbeat:Connect(function()
        if Settings.Movement.Fly and BodyVelocity then
            local moveVector = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveVector = moveVector + Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveVector = moveVector - Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveVector = moveVector - Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveVector = moveVector + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveVector = moveVector + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveVector = moveVector - Vector3.new(0, 1, 0)
            end
            
            -- If no input, maintain current position (hover)
            if moveVector.Magnitude == 0 then
                BodyVelocity.Velocity = Vector3.new(0, 0, 0)
            else
                BodyVelocity.Velocity = moveVector.Unit * Settings.Movement.FlySpeed
            end
            
            -- Keep character upright and prevent falling
            RootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function StopFly()
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    
    if BodyVelocity then
        BodyVelocity:Destroy()
        BodyVelocity = nil
    end
end

-- ESP Functions
local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local espFolder = Instance.new("Folder")
    espFolder.Name = "ESP_" .. player.Name
    espFolder.Parent = workspace
    
    ESPObjects[player] = {
        Folder = espFolder,
        Connections = {}
    }
    
    local function UpdateESP()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        
        local character = player.Character
        local humanoidRootPart = character.HumanoidRootPart
        local humanoid = character:FindFirstChild("Humanoid")
        
        -- Clear existing ESP
        espFolder:ClearAllChildren()
        
        if Settings.Visuals.PlayerESP then
            -- Create 2D box ESP outline around player
            local boxESP = Instance.new("BillboardGui")
            boxESP.Name = "BoxESP"
            boxESP.Parent = espFolder
            boxESP.Adornee = humanoidRootPart
            boxESP.Size = UDim2.new(4, 0, 6, 0)
            boxESP.StudsOffset = Vector3.new(0, 0, 0)
            boxESP.AlwaysOnTop = true
            
            -- Create the box outline using 4 separate frames for each side
            local topFrame = Instance.new("Frame")
            topFrame.Parent = boxESP
            topFrame.Size = UDim2.new(1, 0, 0, 2)
            topFrame.Position = UDim2.new(0, 0, 0, 0)
            topFrame.BackgroundColor3 = Settings.Visuals.ESPColor
            topFrame.BorderSizePixel = 0
            
            local bottomFrame = Instance.new("Frame")
            bottomFrame.Parent = boxESP
            bottomFrame.Size = UDim2.new(1, 0, 0, 2)
            bottomFrame.Position = UDim2.new(0, 0, 1, -2)
            bottomFrame.BackgroundColor3 = Settings.Visuals.ESPColor
            bottomFrame.BorderSizePixel = 0
            
            local leftFrame = Instance.new("Frame")
            leftFrame.Parent = boxESP
            leftFrame.Size = UDim2.new(0, 2, 1, 0)
            leftFrame.Position = UDim2.new(0, 0, 0, 0)
            leftFrame.BackgroundColor3 = Settings.Visuals.ESPColor
            leftFrame.BorderSizePixel = 0
            
            local rightFrame = Instance.new("Frame")
            rightFrame.Parent = boxESP
            rightFrame.Size = UDim2.new(0, 2, 1, 0)
            rightFrame.Position = UDim2.new(1, -2, 0, 0)
            rightFrame.BackgroundColor3 = Settings.Visuals.ESPColor
            rightFrame.BorderSizePixel = 0
        end
        
        if Settings.Visuals.NameESP and humanoid then
            -- Create name ESP
            local nameESP = Instance.new("BillboardGui")
            nameESP.Name = "NameESP"
            nameESP.Parent = espFolder
            nameESP.Adornee = character:FindFirstChild("Head")
            nameESP.Size = UDim2.new(0, 100, 0, 25)
            nameESP.StudsOffset = Vector3.new(0, 2, 0)
            nameESP.AlwaysOnTop = true
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Parent = nameESP
            nameLabel.Size = UDim2.new(1, 0, 1, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = Settings.Visuals.ESPColor
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.SourceSansBold
            nameLabel.TextStrokeTransparency = 0
            nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        end
        
        if Settings.Visuals.DistanceESP and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            -- Create distance ESP
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
            
            local distanceESP = Instance.new("BillboardGui")
            distanceESP.Name = "DistanceESP"
            distanceESP.Parent = espFolder
            distanceESP.Adornee = character:FindFirstChild("Head")
            distanceESP.Size = UDim2.new(0, 80, 0, 20)
            distanceESP.StudsOffset = Vector3.new(0, -1.5, 0)
            distanceESP.AlwaysOnTop = true
            
            local distanceLabel = Instance.new("TextLabel")
            distanceLabel.Parent = distanceESP
            distanceLabel.Size = UDim2.new(1, 0, 1, 0)
            distanceLabel.BackgroundTransparency = 1
            distanceLabel.Text = math.floor(distance) .. " studs"
            distanceLabel.TextColor3 = Settings.Visuals.ESPColor
            distanceLabel.TextScaled = true
            distanceLabel.Font = Enum.Font.SourceSans
            distanceLabel.TextStrokeTransparency = 0
            distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        end
    end
    
    -- Update ESP when character changes
    local connection = RunService.Heartbeat:Connect(UpdateESP)
    ESPObjects[player].Connections[#ESPObjects[player].Connections + 1] = connection
    
    -- Initial update
    UpdateESP()
end

local function RemoveESP(player)
    if ESPObjects[player] then
        -- Disconnect all connections
        for _, connection in pairs(ESPObjects[player].Connections) do
            connection:Disconnect()
        end
        
        -- Remove ESP folder
        if ESPObjects[player].Folder then
            ESPObjects[player].Folder:Destroy()
        end
        
        ESPObjects[player] = nil
    end
end

local function CreateChams(player)
    if player == LocalPlayer then return end
    
    ChamsObjects[player] = {}
    
    local function UpdateChams()
        if not player.Character then return end
        
        -- Remove existing chams
        for _, cham in pairs(ChamsObjects[player]) do
            if cham then cham:Destroy() end
        end
        ChamsObjects[player] = {}
        
        if Settings.Visuals.PlayerChams then
            -- Create a single Highlight for the entire character
            local highlight = Instance.new("Highlight")
            highlight.Parent = player.Character
            highlight.FillColor = Settings.Visuals.VisibleColor
            highlight.OutlineColor = Settings.Visuals.VisibleColor
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            
            ChamsObjects[player][1] = highlight
        end
    end
    
    -- Update chams when character spawns
    if player.Character then
        UpdateChams()
    end
    
    player.CharacterAdded:Connect(UpdateChams)
end

local function RemoveChams(player)
    if ChamsObjects[player] then
        for _, cham in pairs(ChamsObjects[player]) do
            if cham then cham:Destroy() end
        end
        ChamsObjects[player] = nil
    end
end

-- Initialize ESP for existing players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
        CreateChams(player)
    end
end

-- Handle new players
Players.PlayerAdded:Connect(function(player)
    CreateESP(player)
    CreateChams(player)
end)

-- Handle players leaving
Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
    RemoveChams(player)
end)

-- Initialize FOV Circle and Aimbot
CreateFOVCircle()
StartAimbot()

-- Aimbot Tab
local AimbotTab = SwebwareUI:CreateTab("Aimbot")
local MainSection = AimbotTab:CreateSection("Main")
local ConfigSection = AimbotTab:CreateSection("Config")

MainSection:CreateToggle("Aimbot", function(boolean)
    Settings.Aimbot.Enabled = boolean
    print("Aimbot:", boolean)
end)

MainSection:CreateSlider("Field Of View", 10, 200, 50, false, function(value)
    Settings.Aimbot.FOV = value
    print("Field of View: " .. value)
end)

MainSection:CreateSlider("Smoothing", 1, 20, 5, false, function(value)
    Settings.Aimbot.Smoothing = value
    print("Smoothing: " .. value)
end)

MainSection:CreateToggle("Show FOV Circle", function(boolean)
    Settings.Aimbot.ShowFOV = boolean
    print("Show FOV Circle:", boolean)
end)

ConfigSection:CreateDropdown("Target Part", {"Head", "Torso", "HumanoidRootPart"}, 1, function(option)
    Settings.Aimbot.TargetPart = option
    print("Target Part: " .. option)
end)

ConfigSection:CreateDropdown("Type", {"Mouse", "Camera"}, 1, function(option)
    Settings.Aimbot.Type = option
    print("Aimbot Type: " .. option)
end)

ConfigSection:CreateToggle("Wall Check", function(boolean)
    Settings.Aimbot.WallCheck = boolean
    print("Wall Check:", boolean)
end)

ConfigSection:CreateToggle("Team Check", function(boolean)
    Settings.Aimbot.TeamCheck = boolean
    print("Team Check:", boolean)
end)

ConfigSection:CreateColorPicker("FOV Color", Color3.fromRGB(255, 255, 255), function(color)
    Settings.Aimbot.FOVColor = color
    print("FOV Color:", color)
end)

ConfigSection:CreateKeybind("Aimbot Toggle", Enum.KeyCode.Unknown, false, false, function()
    Settings.Aimbot.Enabled = not Settings.Aimbot.Enabled
    print("Aimbot toggled:", Settings.Aimbot.Enabled)
end)

-- Visuals Tab
local VisualsTab = SwebwareUI:CreateTab("Visuals")
local ESPSection = VisualsTab:CreateSection("ESP")
local ChamsSection = VisualsTab:CreateSection("Chams")

ESPSection:CreateToggle("Player ESP", function(boolean)
    Settings.Visuals.PlayerESP = boolean
    print("Player ESP:", boolean)
    
    -- Update all existing ESP
    for player, espData in pairs(ESPObjects) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            task.wait(0.1)
        end
    end
end)

ESPSection:CreateToggle("Name ESP", function(boolean)
    Settings.Visuals.NameESP = boolean
    print("Name ESP:", boolean)
    
    -- Update all existing ESP
    for player, espData in pairs(ESPObjects) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            task.wait(0.1)
        end
    end
end)

ESPSection:CreateToggle("Distance ESP", function(boolean)
    Settings.Visuals.DistanceESP = boolean
    print("Distance ESP:", boolean)
    
    -- Update all existing ESP
    for player, espData in pairs(ESPObjects) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            task.wait(0.1)
        end
    end
end)

ESPSection:CreateColorPicker("ESP Color", Color3.fromRGB(255, 0, 0), function(color)
    Settings.Visuals.ESPColor = color
    print("ESP Color:", color)
    
    -- Update all existing ESP colors
    for player, espData in pairs(ESPObjects) do
        local folder = espData.Folder
        if folder then
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("BillboardGui") then
                    if child.Name == "BoxESP" then
                        -- Update all the outline frames
                        for _, frame in pairs(child:GetChildren()) do
                            if frame:IsA("Frame") then
                                frame.BackgroundColor3 = color
                            end
                        end
                    else
                        local label = child:FindFirstChild("TextLabel")
                        if label then
                            label.TextColor3 = color
                        end
                    end
                end
            end
        end
    end
end)

ChamsSection:CreateToggle("Player Chams", function(boolean)
    Settings.Visuals.PlayerChams = boolean
    print("Player Chams:", boolean)
    
    if boolean then
        -- Enable chams for all players
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                -- Recreate chams
                RemoveChams(player)
                CreateChams(player)
            end
        end
    else
        -- Disable chams for all players
        for _, player in pairs(Players:GetPlayers()) do
            RemoveChams(player)
        end
    end
end)

ChamsSection:CreateColorPicker("Visible Color", Color3.fromRGB(0, 255, 0), function(color)
    Settings.Visuals.VisibleColor = color
    print("Visible Chams Color:", color)
    
    -- Update existing chams colors
    for player, chams in pairs(ChamsObjects) do
        for _, cham in pairs(chams) do
            if cham then
                cham.FillColor = color
                cham.OutlineColor = color
            end
        end
    end
end)

ChamsSection:CreateColorPicker("Hidden Color", Color3.fromRGB(255, 0, 0), function(color)
    Settings.Visuals.HiddenColor = color
    print("Hidden Chams Color:", color)
    -- Note: This would be used for wall-hack style chams (through walls)
end)

-- Movement Tab
local MovementTab = SwebwareUI:CreateTab("Movement")
local SpeedSection = MovementTab:CreateSection("Speed")
local FlySection = MovementTab:CreateSection("Fly")

SpeedSection:CreateToggle("Speed Hack", function(boolean)
    Settings.Movement.SpeedHack = boolean
    if boolean then
        Humanoid.WalkSpeed = Settings.Movement.SpeedValue
    else
        Humanoid.WalkSpeed = 16
    end
    print("Speed Hack:", boolean)
end)

SpeedSection:CreateSlider("Speed Value", 16, 100, 16, false, function(value)
    Settings.Movement.SpeedValue = value
    if Settings.Movement.SpeedHack then
        Humanoid.WalkSpeed = value
    end
    print("Speed Value: " .. value)
end)

SpeedSection:CreateKeybind("Speed Toggle", Enum.KeyCode.Unknown, false, false, function()
    Settings.Movement.SpeedHack = not Settings.Movement.SpeedHack
    if Settings.Movement.SpeedHack then
        Humanoid.WalkSpeed = Settings.Movement.SpeedValue
    else
        Humanoid.WalkSpeed = 16
    end
    print("Speed toggled:", Settings.Movement.SpeedHack)
end)

FlySection:CreateToggle("Fly", function(boolean)
    Settings.Movement.Fly = boolean
    if boolean then
        StartFly()
    else
        StopFly()
    end
    print("Fly:", boolean)
end)

FlySection:CreateSlider("Fly Speed", 10, 200, 50, false, function(value)
    Settings.Movement.FlySpeed = value
    print("Fly Speed: " .. value)
end)

FlySection:CreateToggle("Infinite Jump", function(boolean)
    Settings.Movement.InfiniteJump = boolean
    print("Infinite Jump:", boolean)
end)

-- Credits Tab
local CreditsTab = SwebwareUI:CreateTab("Credits")
local InfoSection = CreditsTab:CreateSection("Information")
local LinksSection = CreditsTab:CreateSection("Links")

InfoSection:CreateLabel("Space1", "")
InfoSection:CreateLabel("Space2", "")
InfoSection:CreateLabel("Space3", "")
InfoSection:CreateLabel("Space4", "")
InfoSection:CreateLabel("Space5", "")
InfoSection:CreateLabel("Developer", "Made by sweb / @4503")
InfoSection:CreateLabel("Version", "V1.2")
InfoSection:CreateLabel("MenuToggle", "Menu Toggle - Right Shift")
InfoSection:CreateLabel("Space6", "")

InfoSection:CreateButton("Copy Discord", function()
    if setclipboard then
        setclipboard("https://discord.gg/Q9caeDr2M8")
        print("Discord link copied to clipboard!")
    else
        print("Clipboard not supported")
    end
end)

LinksSection:CreateButton("GitHub", function()
    if setclipboard then
        setclipboard("https://github.com/bozokongy-hash")
        print("GitHub link copied to clipboard!")
    else
        print("GitHub: https://github.com/bozokongy-hash")
    end
end)

LinksSection:CreateButton("Rewire Discord", function()
    if setclipboard then
        setclipboard("https://discord.gg/rewire")
        print("Rewire Discord link copied to clipboard!")
    else
        print("Rewire Discord: https://discord.gg/rewire")
    end
end)

LinksSection:CreateButton("Reload Script", function()
    print("Reloading script...")
    -- Add reload functionality here
end)

LinksSection:CreateLabel("Space3", "")

-- Infinite Jump functionality
UserInputService.JumpRequest:Connect(function()
    if Settings.Movement.InfiniteJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Character respawn handling
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    
    -- Reapply settings
    if Settings.Movement.SpeedHack then
        Humanoid.WalkSpeed = Settings.Movement.SpeedValue
    end
    if Settings.Movement.Fly then
        task.wait(1) -- Wait for character to fully load
        StartFly()
    end
end)
