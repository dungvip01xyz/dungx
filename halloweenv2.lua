
-- SET TEAM
local ReplicatedStorage = game:GetService("ReplicatedStorage")

task.wait(5)

pcall(function()
    ReplicatedStorage.Remotes.CommF_:InvokeServer(
        "SetTeam",
        "Pirates"
    )
end)

task.wait(5)

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Folder = workspace:WaitForChild("PumpkinHunt")
local Net = ReplicatedStorage.Modules.Net

local RegisterAttack = Net["RE/RegisterAttack"]
local RegisterHit = Net["RE/RegisterHit"]

-- CONFIG
local Running = true

local ScanDelay = 0.1
local AttackDelay = 0.05

local FlyHeight = 15
local FlySpeed = 220

getgenv().AutoSelectMelee = true
getgenv().PumpkinNoClip = true

-- VARIABLES
local CurrentTarget
local AlignPosition
local AlignOrientation
local Attachment

local FlightToken = 0
local CharacterToken = 0

local CurrentCharacter
local NoclipConnection

-- CHARACTER
local function GetCharacter()
    local Char = Player.Character
    if not Char then return end

    local HRP = Char:FindFirstChild("HumanoidRootPart")
    local Humanoid = Char:FindFirstChildOfClass("Humanoid")

    if not HRP or not Humanoid then return end
    if Humanoid.Health <= 0 then return end

    return Char, HRP, Humanoid
end

-- CLEAN FLIGHT
local function StopFlight()
    FlightToken += 1

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

-- NOCLIP
local function ApplyNoClip(Char)
    if not Char then return end

    local function SetPart(Obj)
        if Obj:IsA("BasePart") then
            Obj.CanCollide = false
        end
    end

    for _, Obj in ipairs(Char:GetDescendants()) do
        SetPart(Obj)
    end

    Char.DescendantAdded:Connect(function(Obj)
        if Running and getgenv().PumpkinNoClip then
            SetPart(Obj)
        end
    end)
end

-- RESPAWN HANDLER
local function OnCharacterAdded(Char)
    CharacterToken += 1

    StopFlight()

    CurrentTarget = nil
    CurrentCharacter = Char

    task.spawn(function()
        local HRP = Char:WaitForChild("HumanoidRootPart", 15)
        local Humanoid = Char:WaitForChild("Humanoid", 15)

        if not HRP or not Humanoid then return end
        if Player.Character ~= Char then return end

        ApplyNoClip(Char)

        -- Nhảy trạng thái ban đầu
        Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end)
end

Player.CharacterAdded:Connect(OnCharacterAdded)

Player.CharacterRemoving:Connect(function()
    CharacterToken += 1
    StopFlight()
    CurrentTarget = nil
end)

if Player.Character then
    OnCharacterAdded(Player.Character)
end

-- NOCLIP CONTINUOUS
NoclipConnection = RunService.Stepped:Connect(function()
    if not Running or not getgenv().PumpkinNoClip then
        return
    end

    local Char = Player.Character
    if not Char then return end

    for _, Obj in ipairs(Char:GetDescendants()) do
        if Obj:IsA("BasePart") then
            Obj.CanCollide = false
        end
    end
end)

-- AUTO SELECT MELEE
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

                        if Humanoid and Humanoid.Health > 0 then
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

-- GET PUMPKINS
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

        if #Obj:GetChildren() > 0 and not GetRoot(Obj) then
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
            local Distance =
                (HRP.Position - Data.Root.Position).Magnitude

            if Distance < MinDistance then
                MinDistance = Distance
                Nearest = Data
            end
        end
    end

    return Nearest
end

-- START FLIGHT
local function StartFlight(Data)
    if not IsValid(Data) then return end

    local Char, HRP, Humanoid = GetCharacter()
    if not HRP then return end

    StopFlight()

    local MyToken = FlightToken
    local MyCharacter = Char
    local Target = Data.Root

    -- Nhảy một lần khi chuyển mục tiêu
    Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

    -- ATTACHMENT
    Attachment = Instance.new("Attachment")
    Attachment.Name = "PumpkinFlightAttachment"
    Attachment.Parent = HRP

    -- ALIGN POSITION
    AlignPosition = Instance.new("AlignPosition")
    AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
    AlignPosition.Attachment0 = Attachment
    AlignPosition.ApplyAtCenterOfMass = true
    AlignPosition.MaxForce = 1000000
    AlignPosition.MaxVelocity = FlySpeed
    AlignPosition.Responsiveness = 12
    AlignPosition.RigidityEnabled = false
    AlignPosition.Position = Target.Position + Vector3.new(0, FlyHeight, 0)
    AlignPosition.Parent = HRP

    -- ALIGN ORIENTATION
    AlignOrientation = Instance.new("AlignOrientation")
    AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    AlignOrientation.Attachment0 = Attachment
    AlignOrientation.MaxTorque = 1000000
    AlignOrientation.Responsiveness = 10
    AlignOrientation.RigidityEnabled = false
    AlignOrientation.Parent = HRP

    _G.Clip2 = true

    -- FOLLOW TARGET
    task.spawn(function()
        while Running
            and FlightToken == MyToken
            and Player.Character == MyCharacter
            and IsValid(Data)
            and Target.Parent
            and AlignPosition
            and AlignPosition.Parent do

            local Position =
                Target.Position + Vector3.new(0, FlyHeight, 0)

            AlignPosition.Position = Position

            AlignOrientation.CFrame = CFrame.lookAt(
                HRP.Position,
                Vector3.new(
                    Target.Position.X,
                    HRP.Position.Y,
                    Target.Position.Z
                )
            )

            task.wait(0.03)
        end
    end)
end

-- ATTACK
local function Attack(Data, MyCharacter)
    while Running
        and IsValid(Data)
        and Player.Character == MyCharacter do

        local Char, HRP, Humanoid = GetCharacter()

        if not Char or Char ~= MyCharacter then
            break
        end

        pcall(function()
            RegisterAttack:FireServer(0.5, 1)

            for _, Part in ipairs(Data.Parts) do
                if not Running
                    or not IsValid(Data)
                    or Player.Character ~= MyCharacter then
                    break
                end

                if Part.Parent then
                    RegisterHit:FireServer(Part)
                end
            end

            if IsValid(Data) then
                RegisterHit:FireServer(Data.Root)
            end
        end)

        task.wait(AttackDelay)
    end
end

-- MAIN LOOP
task.spawn(function()
    while Running do
        local Char, HRP, Humanoid = GetCharacter()

        if not Char then
            task.wait(0.2)
            continue
        end

        local Target = FindNearest()

        if Target then
            CurrentTarget = Target

            StartFlight(Target)

            -- Attack until pumpkin disappears or character dies
            Attack(Target, Char)

            StopFlight()
            CurrentTarget = nil

            task.wait(ScanDelay)
        else
            StopFlight()
            CurrentTarget = nil
            task.wait(ScanDelay)
        end
    end
end)
