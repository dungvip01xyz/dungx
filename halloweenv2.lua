wait(5)
local args = {
    [1] = "SetTeam",
    [2] = "Pirates"
}
game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer(unpack(args))
wait(5)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

local FlyHeight = 8
local FlySpeed = 220

local CurrentTarget
local AlignPosition
local AlignOrientation
local Attachment
local JumpedTarget

getgenv().AutoSelectMelee = true

-- NOCLIP
getgenv().PumpkinNoClip = true

local NoclipConnection

NoclipConnection = RunService.Stepped:Connect(function()
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

-- CHARACTER
local function GetCharacter()
    local Char = Player.Character
    if not Char then return end

    local HRP = Char:FindFirstChild("HumanoidRootPart")
    local Humanoid = Char:FindFirstChildOfClass("Humanoid")

    if not HRP or not Humanoid then return end

    return Char, HRP, Humanoid
end

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

-- NEAREST PUMPKIN
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

-- REMOVE FLIGHT
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

-- START FLIGHT
local function StartFlight(Target)
    local Char, HRP, Humanoid = GetCharacter()
    if not HRP or not Target or not Target.Parent then return end

    StopFlight()

    -- Jump once when changing target
    if JumpedTarget ~= Target then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        JumpedTarget = Target
    end

    -- Attachment
    Attachment = Instance.new("Attachment")
    Attachment.Name = "PumpkinFlightAttachment"
    Attachment.Parent = HRP

    -- AlignPosition
    AlignPosition = Instance.new("AlignPosition")
    AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
    AlignPosition.Attachment0 = Attachment
    AlignPosition.ApplyAtCenterOfMass = true
    AlignPosition.MaxForce = 1000000
    AlignPosition.MaxVelocity = FlySpeed
    AlignPosition.Responsiveness = 12
    AlignPosition.RigidityEnabled = false
    AlignPosition.Parent = HRP

    -- AlignOrientation
    AlignOrientation = Instance.new("AlignOrientation")
    AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    AlignOrientation.Attachment0 = Attachment
    AlignOrientation.MaxTorque = 1000000
    AlignOrientation.Responsiveness = 10
    AlignOrientation.RigidityEnabled = false
    AlignOrientation.Parent = HRP

    _G.Clip2 = true

    -- Update position continuously
    task.spawn(function()
        while Running
            and IsValid(CurrentTarget)
            and CurrentTarget == CurrentTarget
            and AlignPosition do

            if not Target.Parent then break end

            local Position =
                Target.Position + Vector3.new(0, FlyHeight, 0)

            AlignPosition.Position = Position
            AlignOrientation.CFrame = CFrame.lookAt(
                HRP.Position,
                Vector3.new(Target.Position.X, HRP.Position.Y, Target.Position.Z)
            )

            task.wait(0.03)
        end
    end)
end

-- ATTACK
local function Attack(Data)
    while Running and IsValid(Data) do
        pcall(function()
            RegisterAttack:FireServer(0.5, 1)

            for _, Part in ipairs(Data.Parts) do
                if not Running or not IsValid(Data) then
                    return
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
        local Target = FindNearest()

        if Target then
            CurrentTarget = Target

            StartFlight(Target.Root)

            -- Attack until target disappears
            Attack(Target)

            -- Stop old flight
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
