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
                
                local equipped = plr.Character and plr.Character:FindFirstChildOfClass("Tool")
                if equipped and equipped.ToolTip == "Melee" then
                    return
                end
                
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
    wait(1)
    local human = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if human then
        human:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not root or not IsValid(part) then return end

    local distance = (part.Position - root.Position).Magnitude

    local tween = TweenService:Create(
        root,
        TweenInfo.new(
            math.max(distance / 100, 0.05),
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
                Tween2(part)
            else
                currentTarget = nil
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

StartLockCamera()
print("PUMPKIN SCRIPT LOADED")
