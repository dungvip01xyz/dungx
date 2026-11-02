-- Chỉ Attack Pumpkin quanh nhân vật
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

local Folder = workspace:WaitForChild("PumpkinHunt")
local Net = ReplicatedStorage.Modules.Net
local RegisterAttack = Net["RE/RegisterAttack"]
local RegisterHit = Net["RE/RegisterHit"]

local Range = 40          -- Tầm đánh
local AttackDelay = 0.04
task.wait(5)

local args = {
    [1] = "SetTeam",
    [2] = "Pirates"
}

game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer(unpack(args))

task.wait(5)

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Folder = workspace:WaitForChild("PumpkinHunt")

-- CONFIG
local Running = true
local ScanDelay = 0.1

local FlyHeight = 8
local FlySpeed = 350

getgenv().AutoSelectMelee = true
getgenv().PumpkinNoClip = true

local CurrentTarget
local AlignPosition
local AlignOrientation
local Attachment
local JumpedTarget
getgenv().PumpkinAttack = true

local function GetHRP()
    local Char = Player.Character
    if not Char then return end
    return Char:FindFirstChild("HumanoidRootPart")
end

local function GetRoot(Model)
    return Model:FindFirstChild("RootPart", true) or Model:FindFirstChild("HumanoidRootPart", true)
end

local function IsPumpkinPart(Part)
    return Part:IsA("BasePart") and Part.Name:lower():find("pumpkin")
end

local function GetNearbyPumpkins()
    local Result = {}
    local HRP = GetHRP()
    if not HRP then return Result end

    local function Check(Model)
        if not Model:IsA("Model") then return end
        local Root = GetRoot(Model)
        if not Root then return end

        if (HRP.Position - Root.Position).Magnitude > Range then return end

        local Parts = {}
        for _, v in ipairs(Model:GetDescendants()) do
            if IsPumpkinPart(v) then
                table.insert(Parts, v)
            end
        end
        if #Parts == 0 then
            table.insert(Parts, Root)
        end

        table.insert(Result, {Root = Root, Parts = Parts})
    end

    for _, Obj in ipairs(Folder:GetChildren()) do
        Check(Obj)
        for _, Child in ipairs(Obj:GetChildren()) do
            Check(Child)
        end
    end
    return Result
end

-- Hàm Attack
local function AttackPumpkin()
    local Nearby = GetNearbyPumpkins()
    if #Nearby == 0 then return end

    pcall(function()
        RegisterAttack:FireServer(0.5, 1)

        for _, Data in ipairs(Nearby) do
            if not getgenv().PumpkinAttack then return end
            for _, Part in ipairs(Data.Parts) do
                if Part and Part.Parent then
                    RegisterHit:FireServer(Part)
                end
            end
            if Data.Root and Data.Root.Parent then
                RegisterHit:FireServer(Data.Root)
            end
        end
    end)
end

-- Chạy liên tục
task.spawn(function()
    while getgenv().PumpkinAttack do
        if Player.Character and Player.Character.Parent then
            AttackPumpkin()
        end
        task.wait(AttackDelay)
    end
end)

print("Attack Pumpkin đã bật")
-- SET TEAM PIRATES


-- CHARACTER
local function GetCharacter()
    local Char = Player.Character
    if not Char then return end

    local HRP = Char:FindFirstChild("HumanoidRootPart")
    local Humanoid = Char:FindFirstChildOfClass("Humanoid")

    if not HRP or not Humanoid then return end

    return Char, HRP, Humanoid
end

-- 1. AUTO SELECT MELEE
task.spawn(function()
    while Running do
        if getgenv().AutoSelectMelee then
            pcall(function()
                local Char = Player.Character
                local Backpack = Player:FindFirstChild("Backpack")

                if not Char or not Backpack then return end

                local Equipped = Char:FindFirstChildOfClass("Tool")

                if Equipped and Equipped.ToolTip == "Melee" then
                    return
                end

                for _, Tool in ipairs(Backpack:GetChildren()) do
                    if Tool:IsA("Tool") and Tool.ToolTip == "Melee" then
                        local Humanoid = Char:FindFirstChildOfClass("Humanoid")

                        if Humanoid then
                            Humanoid:EquipTool(Tool)
                        end

                        break
                    end
                end
            end)
        end

        task.wait(0.5)
    end
end)

-- 2. NOCLIP
RunService.Stepped:Connect(function()
    if not Running or not getgenv().PumpkinNoClip then
        return
    end

    local Char = Player.Character
    if not Char then return end

    for _, Part in ipairs(Char:GetDescendants()) do
        if Part:IsA("BasePart") then
            Part.CanCollide = false
        end
    end
end)

-- PUMPKIN ROOT
local function GetRoot(Model)
    return Model:FindFirstChild("RootPart", true)
end

local function IsPumpkinPart(Part)
    return Part:IsA("BasePart")
        and Part.Name:match("^pumpkinv%d+%.%d+$") ~= nil
end

local function IsValid(Data)
    return Data
        and Data.Model
        and Data.Model.Parent
        and Data.Root
        and Data.Root.Parent
end

-- 3. GET PUMPKINS
local function GetPumpkins()
    local Result = {}

    local function Check(Model)
        if not Model:IsA("Model") then return end

        local Root = GetRoot(Model)
        if not Root then return end

        local Parts = {}

        for _, Obj in ipairs(Model:GetDescendants()) do
            if IsPumpkinPart(Obj) then
                table.insert(Parts, Obj)
            end
        end

        if #Parts > 0 then
            table.insert(Result, {
                Model = Model,
                Root = Root,
                Parts = Parts
            })
        end
    end

    for _, Obj in ipairs(Folder:GetChildren()) do
        Check(Obj)

        if not GetRoot(Obj) then
            for _, Child in ipairs(Obj:GetChildren()) do
                Check(Child)
            end
        end
    end

    return Result
end

-- FIND NEAREST
local function FindNearest()
    local _, HRP = GetCharacter()
    if not HRP then return end

    local Nearest
    local MinDistance = math.huge

    for _, Data in ipairs(GetPumpkins()) do
        if IsValid(Data) then
            local Distance = (HRP.Position - Data.Root.Position).Magnitude

            if Distance < MinDistance then
                MinDistance = Distance
                Nearest = Data
            end
        end
    end

    return Nearest
end

-- STOP FLIGHT
local function StopFlight()
    if AlignPosition then
        AlignPosition:Destroy()
        AlignPosition = nil
    end

    if AlignOrientation then
        AlignOrientation:Destroy()
        AlignOrientation = nil
    end

    if Attachment then
        Attachment:Destroy()
        Attachment = nil
    end

    _G.Clip2 = false
end

-- 4 + 5. FLY TO PUMPKIN / JUMP ON TARGET CHANGE
local function StartFlight(Target)
    local Char, HRP, Humanoid = GetCharacter()

    if not HRP or not Target or not Target.Parent then return end

    StopFlight()

    if JumpedTarget ~= Target then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        JumpedTarget = Target
    end

    Attachment = Instance.new("Attachment")
    Attachment.Name = "PumpkinFlightAttachment"
    Attachment.Parent = HRP

    AlignPosition = Instance.new("AlignPosition")
    AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
    AlignPosition.Attachment0 = Attachment
    AlignPosition.ApplyAtCenterOfMass = true
    AlignPosition.MaxForce = 1000000
    AlignPosition.MaxVelocity = FlySpeed
    AlignPosition.Responsiveness = 12
    AlignPosition.RigidityEnabled = false
    AlignPosition.Parent = HRP

    AlignOrientation = Instance.new("AlignOrientation")
    AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    AlignOrientation.Attachment0 = Attachment
    AlignOrientation.MaxTorque = 1000000
    AlignOrientation.Responsiveness = 10
    AlignOrientation.RigidityEnabled = false
    AlignOrientation.Parent = HRP

    _G.Clip2 = true

    task.spawn(function()
        while Running
            and CurrentTarget
            and CurrentTarget.Root == Target
            and Target.Parent
            and AlignPosition do

            local Position = Target.Position + Vector3.new(0, FlyHeight, 0)

            AlignPosition.Position = Position

            AlignOrientation.CFrame = CFrame.lookAt(
                HRP.Position,
                Vector3.new(Target.Position.X, HRP.Position.Y, Target.Position.Z)
            )

            task.wait(0.03)
        end
    end)
end

-- MAIN LOOP
-- MAIN LOOP FAST SCAN
task.spawn(function()
    while Running do
        local _, HRP = GetCharacter()

        if HRP then
            -- Kiểm tra mục tiêu hiện tại
            if CurrentTarget and not IsValid(CurrentTarget) then
                CurrentTarget = nil
                JumpedTarget = nil
                StopFlight()
            end

            -- Tìm Pumpkin gần nhất
            local Target = FindNearest()

            if Target and IsValid(Target) then
                local Changed = not CurrentTarget
                    or CurrentTarget.Model ~= Target.Model

                if Changed then
                    CurrentTarget = Target
                    StartFlight(Target.Root)
                end
            else
                if CurrentTarget then
                    CurrentTarget = nil
                    JumpedTarget = nil
                    StopFlight()
                end
            end
        end

        task.wait(0.03)
    end
end)

-- CHARACTER RESPAWN
Player.CharacterAdded:Connect(function()
    StopFlight()
    CurrentTarget = nil
    JumpedTarget = nil
end)

print("Pumpkin Auto Fly đã bật")
