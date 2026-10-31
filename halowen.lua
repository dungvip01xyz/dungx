wait(5)
local args = {
    [1] = "SetTeam",
    [2] = "Pirates"
}
game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer(unpack(args))
wait(5)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local AutoPumpkin = true
local AutoClick = true
local LockCamera = true
local currentTween = nil
local currentTarget = nil
local running = true
local cameraConnection = nil
local CoreGui = game:GetService("CoreGui")

pcall(function()
    CoreGui:FindFirstChild("PumpkinGUI"):Destroy()
end)

local gui = Instance.new("ScreenGui")
gui.Name = "PumpkinGUI"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(215, 205)
frame.Position = UDim2.new(0, 15, 0, 15)
frame.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 9)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundTransparency = 1
title.Text = "PUMPKIN HUNT"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 16
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -10, 0, 25)
status.Position = UDim2.fromOffset(5, 32)
status.BackgroundTransparency = 1
status.Text = "LOCK CAMERA: ON"
status.TextColor3 = Color3.fromRGB(100, 220, 130)
status.TextSize = 12
status.Parent = frame

local function CreateButton(name, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 38)
    btn.Position = UDim2.fromOffset(10, y)
    btn.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 14
    btn.Parent = frame

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local pumpkinBtn = CreateButton("AUTO PUMPKIN", 62)
local clickBtn = CreateButton("AUTO CLICK", 107)
local lockBtn = CreateButton("LOCK CAMERA", 152)

local function UpdateButton(btn, name, value)
    btn.Text = name .. (value and ": ON" or ": OFF")
    btn.BackgroundColor3 = value
        and Color3.fromRGB(35, 145, 75)
        or Color3.fromRGB(150, 45, 45)
end

-- KIEM TRA PUMPKIN
local function IsValid(part)
    return part
        and part.Parent
        and part:IsDescendantOf(workspace)
end
-- Auto Buso Haki
getgenv().AutoBuso = true

spawn(function()
    while task.wait(0.5) do
        if getgenv().AutoBuso then
            pcall(function()
                local plr = game.Players.LocalPlayer
                local char = plr.Character
                
                if char and not char:FindFirstChild("HasBuso") then
                    game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Buso")
                end
            end)
        end
    end
end)
getgenv().AutoSelectMelee = true

spawn(function()
    while task.wait(0.5) do
        if getgenv().AutoSelectMelee then
            pcall(function()
                local plr = game.Players.LocalPlayer
                
                -- Ưu tiên lấy Melee trong Character trước
                local equipped = plr.Character and plr.Character:FindFirstChildOfClass("Tool")
                if equipped and equipped.ToolTip == "Melee" then
                    return -- Đã cầm Melee rồi thì thôi
                end
                
                -- Tìm Melee trong Backpack
                for _, tool in pairs(plr.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.ToolTip == "Melee" then
                        plr.Character.Humanoid:EquipTool(tool)
                        break
                    end
                end
            end)
        end
    end
end)
-- TIM PUMPKIN GAN NHAT
local function FindPumpkin()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not root then return nil end

    local nearest = nil
    local minDistance = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "Pumpkin" then
            local part = obj:IsA("BasePart") and obj
                or obj:FindFirstChildWhichIsA("BasePart", true)

            if IsValid(part) then
                local distance = (part.Position - root.Position).Magnitude

                if distance < minDistance then
                    minDistance = distance
                    nearest = part
                end
            end
        end
    end

    return nearest
end

-- HUY TWEEN
local function CancelTween()
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
end

-- TWEEN
local function Tween2(part)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not root or not IsValid(part) then return end

    local distance = (part.Position - root.Position).Magnitude

    local tween = TweenService:Create(
        root,
        TweenInfo.new(
            math.max(distance / 350, 0.05),
            Enum.EasingStyle.Linear
        ),
        {CFrame = part.CFrame}
    )

    currentTween = tween
    tween:Play()

    while AutoPumpkin do
        if not IsValid(part) then break end
        if not root.Parent or LocalPlayer.Character ~= char then break end

        if (root.Position - part.Position).Magnitude <= 5 then
            break
        end

        if tween.PlaybackState ~= Enum.PlaybackState.Playing then
            break
        end

        task.wait(0.05)
    end

    if currentTween == tween then
        tween:Cancel()
        currentTween = nil
    end
end

-- AUTO PUMPKIN
task.spawn(function()
    while running do
        if AutoPumpkin then
            local part = FindPumpkin()

            if part then
                currentTarget = part
                status.Text = "Dang den Pumpkin..."

                Tween2(part)
            else
                currentTarget = nil
                status.Text = "Dang tim Pumpkin..."
                CancelTween()
            end

            task.wait(0.05)
        else
            task.wait(0.2)
        end
    end
end)

-- AUTO CLICK GIUA MAN HINH
task.spawn(function()
    while running do
        if AutoClick then
            local camera = workspace.CurrentCamera

            if camera then
                local x = camera.ViewportSize.X / 2
                local y = camera.ViewportSize.Y / 2

                pcall(function()
                    VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
                    task.wait(0.05)
                    VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
                end)
            end
        end

        task.wait(0.05)
    end
end)

-- LOCK CAMERA
local function StartLockCamera()
    if cameraConnection then
        cameraConnection:Disconnect()
    end

    cameraConnection = RunService.RenderStepped:Connect(function()
        if not LockCamera then return end

        local camera = workspace.CurrentCamera
        if not camera then return end

        local part = currentTarget

        if not IsValid(part) then
            part = FindPumpkin()
        end

        if part then
            local cameraPosition = camera.CFrame.Position

            camera.CFrame = CFrame.lookAt(
                cameraPosition,
                part.Position
            )
        end
    end)
end

local function StopLockCamera()
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end

    local camera = workspace.CurrentCamera

    if camera then
        camera.CameraType = Enum.CameraType.Custom
    end
end

-- BUTTON PUMPKIN
pumpkinBtn.MouseButton1Click:Connect(function()
    AutoPumpkin = not AutoPumpkin

    UpdateButton(pumpkinBtn, "AUTO PUMPKIN", AutoPumpkin)

    if not AutoPumpkin then
        CancelTween()
        currentTarget = nil
        status.Text = "Da dung Pumpkin"
    else
        status.Text = "Dang tim Pumpkin..."
    end
end)

-- BUTTON CLICK
clickBtn.MouseButton1Click:Connect(function()
    AutoClick = not AutoClick
    UpdateButton(clickBtn, "AUTO CLICK", AutoClick)
end)

-- BUTTON LOCK
lockBtn.MouseButton1Click:Connect(function()
    LockCamera = not LockCamera

    UpdateButton(lockBtn, "LOCK CAMERA", LockCamera)

    if LockCamera then
        StartLockCamera()
    else
        StopLockCamera()
    end
end)
UpdateButton(lockBtn, "LOCK CAMERA", true)
StartLockCamera()
print("PUMPKIN GUI LOADED")
