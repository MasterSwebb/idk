-- Exotic Hub UI
local CGUI = game:GetService("CoreGui")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Client = game:GetService("Players").LocalPlayer

local version = "Exotic Hub 1.0"
local base64encode = (syn and syn.crypt.base64.encode) or crypt.base64encode

-- Rebrand
local InterfaceName = "ExoticHub"
local Interface = game:GetObjects("rbxassetid://14193090516")[1]
Interface.Name = InterfaceName

-- GUI Parent Logic
if gethui() then 
    for i, v in ipairs(gethui():GetChildren()) do 
        if v.Name == InterfaceName then v:Destroy() end
    end
    Interface.Parent = gethui()
elseif syn.protect_gui then
    for i, v in ipairs(CGUI:GetChildren()) do 
        if v.Name == InterfaceName then v:Destroy() end
    end
    Interface.Parent = CGUI
    syn.protect_gui(Interface)
else
    for i, v in ipairs(CGUI:GetChildren()) do 
        if v.Name == InterfaceName then v:Destroy() end
    end
    Interface.Parent = CGUI
end

local InterfaceManager = {}

function InterfaceManager:Begin(title: string)
    local OPEN = true
    local Window = Interface:WaitForChild("Window")
    local Title = Window:WaitForChild("Container"):WaitForChild("Title")
    local Templates = Window:WaitForChild("Container"):WaitForChild("Components"):WaitForChild("Templates")

    Window.Draggable = true
    Window.Visible = OPEN
    Title.Text = title

    -- Close Button Animations
    local CloseBtn = Title:WaitForChild("Close")
    CloseBtn.MouseEnter:Connect(function()
        TS:Create(CloseBtn, TweenInfo.new(.2), {ImageColor3=Color3.fromRGB(67, 67, 67)}):Play()
    end)
    CloseBtn.MouseLeave:Connect(function()
        TS:Create(CloseBtn, TweenInfo.new(.2), {ImageColor3=Color3.fromRGB(44, 44, 44)}):Play()
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        if gethui() then 
            for i, v in ipairs(gethui():GetChildren()) do if v.Name == InterfaceName then v:Destroy() end end
        elseif syn.unprotect_gui then
            for i, v in ipairs(CGUI:GetChildren()) do syn.unprotect_gui(v); v:Destroy() end
        else
            for i, v in ipairs(CGUI:GetChildren()) do if v.Name == InterfaceName then v:Destroy() end end
        end
    end)

    local ComponentHandler = {}
    local Components = {}

    -- Boolean
    function ComponentHandler:CreateBoolean(options)
        options = options or {Name=options.Name, Value=options.Value, OnChanged=options.OnChanged}
        local booleanDebounce = false
        local booleanComp = Templates:WaitForChild("Boolean"):Clone()
        booleanComp.Parent = Window:WaitForChild("Container"):WaitForChild("Components")
        booleanComp.Visible = true
        booleanComp:WaitForChild("Name").Text = options.Name

        options.update = function()
            if options.Value then
                TS:Create(booleanComp.Display, TweenInfo.new(.2), {BackgroundColor3=Color3.fromRGB(60,63,65)}):Play()
                TS:Create(booleanComp.Display.State, TweenInfo.new(.2, Enum.EasingStyle.Cubic), {BackgroundColor3=Color3.fromRGB(119,126,130), Position=UDim2.new(1,-18,0.5,0)}):Play()
            else
                TS:Create(booleanComp.Display, TweenInfo.new(.2), {BackgroundColor3=Color3.fromRGB(25,26,27)}):Play()
                TS:Create(booleanComp.Display.State, TweenInfo.new(.2, Enum.EasingStyle.Cubic), {BackgroundColor3=Color3.fromRGB(77,81,84), Position=UDim2.new(0,4,0.5,0)}):Play()
            end
        end

        booleanComp.Display.OnMouse.MouseButton1Click:Connect(function()
            if not booleanDebounce then
                booleanDebounce = true
                options.Value = not options.Value
                options.update()
                pcall(options.OnChanged, options.Value)
                task.wait(.2)
                booleanDebounce = false
            end
        end)

        table.insert(Components, options)
    end

    -- Button
    function ComponentHandler:CreateButton(options)
        options = options or {Name=options.Name, OnClick=options.OnClick}
        local buttonDebounce = false
        local buttonComp = Templates:WaitForChild("Button"):Clone()
        buttonComp.Parent = Window:WaitForChild("Container"):WaitForChild("Components")
        buttonComp.Visible = true
        buttonComp.Name.Text = options.Name

        local function clickEffect(x, y)
            local frame = Instance.new("Frame", buttonComp)
            frame.Size = UDim2.new(0,10,0,10)
            frame.Position = UDim2.new(0,x-buttonComp.AbsolutePosition.X,0.5,0)
            frame.BackgroundColor3 = Color3.fromRGB(44,44,44)
            frame.AnchorPoint = Vector2.new(0.5,0.5)
            frame.ZIndex = 1
            frame.Visible = true
            local corner = Instance.new("UICorner", frame)
            corner.CornerRadius = UDim.new(1,0)
            TS:Create(frame, TweenInfo.new(1), {Size=UDim2.new(0,100,0,100), BackgroundTransparency=1}):Play()
            TS:Create(frame, TweenInfo.new(1), {BackgroundTransparency=1}).Completed:Connect(function() frame:Destroy() end)
        end

        buttonComp.OnMouse.MouseButton1Down:Connect(function()
            if not buttonDebounce then
                buttonDebounce = true
                pcall(options.OnClick)
                local mpos = UIS:GetMouseLocation()
                clickEffect(mpos.X, mpos.Y)
                task.wait(.1)
                buttonDebounce = false
            end
        end)
    end

    -- Slider
    function ComponentHandler:CreateSlider(options)
        options = options or {Name=options.Name, Value=options.Value, Range=options.Range, OnChanged=options.OnChanged}
        local dragging = false
        local sliderComp = Templates:WaitForChild("Slider"):Clone()
        sliderComp.Parent = Window.Container.Components
        sliderComp.Visible = true
        sliderComp.Name.Text = options.Name

        local fill = sliderComp.ParentFrame.FillFrame

        local function updateSlider(val)
            val = math.clamp(val, options.Range[1], options.Range[2])
            local perc = (val - options.Range[1])/(options.Range[2]-options.Range[1])
            TS:Create(fill, TweenInfo.new(.2), {Size=UDim2.new(perc,0,1,0)}):Play()
            pcall(options.OnChanged, val)
        end

        sliderComp.ParentFrame.OnMouse.MouseButton1Down:Connect(function() dragging=true end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType.Name=="MouseMovement" then
                local x = math.clamp(input.Position.X, sliderComp.ParentFrame.AbsolutePosition.X, sliderComp.ParentFrame.AbsolutePosition.X+sliderComp.ParentFrame.AbsoluteSize.X)
                updateSlider((x - sliderComp.ParentFrame.AbsolutePosition.X)/(sliderComp.ParentFrame.AbsoluteSize.X)*(options.Range[2]-options.Range[1])+options.Range[1])
            end
        end)
        UIS.InputEnded:Connect(function(input) if input.UserInputType.Name=="MouseButton1" then dragging=false end end)

        table.insert(Components, options)
    end

    -- TODO: Add Dropdown, Keybind, TextInput here for Exotic Hub expansion

    task.defer(function()
        local dragging=false; local startPos; local startInput
        local function move(input)
            local delta=input.Position-startInput
            TS:Create(Window, TweenInfo.new(.1), {Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)}):Play()
        end
        Title.InputBegan:Connect(function(input)
            if input.UserInputType.Name=="MouseButton1" then
                dragging=true
                startInput=input.Position
                startPos=Window.Position
                input.Changed:Connect(function()
                    if input.UserInputState.Name=="End" then dragging=false end
                end)
            end
        end)
        Title.InputChanged:Connect(function(input) if dragging then move(input) end end)
        UIS.InputBegan:Connect(function(i) if i.KeyCode==Enum.KeyCode.RightShift then OPEN=not OPEN; Window.Visible=OPEN end end)
    end)

    return ComponentHandler
end

return InterfaceManager
