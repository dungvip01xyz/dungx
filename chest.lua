wait(5)
local args = {
    [1] = "SetTeam",
    [2] = "Pirates"
}
game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer(unpack(args))
wait(5)
_G.AutoCollectChest = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- CHỐNG AFK
-- ============================================================

function PreventAFK()
    LocalPlayer.Idled:Connect(function()
        print("|COKKA DEBUG| AFK detected, prevented +1")

        local VirtualInputManager = game:GetService("VirtualInputManager")

        VirtualInputManager:SendMouseButtonEvent(
            0, 0, 0, true, game, 1
        )

        task.wait(1)

        VirtualInputManager:SendMouseButtonEvent(
            0, 0, 0, false, game, 1
        )
    end)
end

PreventAFK()


local FLY_HEIGHT = 100 -- độ cao bay lên
local SPEED = 170       -- tốc độ


-- ============================================================
-- TWEEN 1 ĐOẠN
-- ============================================================

local function TweenTo(targetCFrame)
    local character = LocalPlayer.Character
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local distance = (targetCFrame.Position - root.Position).Magnitude

    if distance < 1 then
        return
    end

    local tweenInfo = TweenInfo.new(
        distance / SPEED,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    local tween = TweenService:Create(
        root,
        tweenInfo,
        {
            CFrame = targetCFrame
        }
    )

    _G.CurrentTween = tween

    tween:Play()
    tween.Completed:Wait()

    _G.CurrentTween = nil
end

function Tween2(targetCFrame)

    local character = LocalPlayer.Character
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local startPos = root.Position
    local targetPos = targetCFrame.Position

    -- ========================================================
    -- ĐIỂM 1: BAY THẲNG LÊN
    -- ========================================================

    local height = math.max(startPos.Y, targetPos.Y) + FLY_HEIGHT

    local pointUp = Vector3.new(
        startPos.X,
        height,
        startPos.Z
    )

    print("↑ Bay lên:", pointUp)

    TweenTo(CFrame.new(pointUp))


    -- ========================================================
    -- ĐIỂM 2: BAY NGANG
    -- Giữ nguyên độ cao
    -- ========================================================

    local pointAboveChest = Vector3.new(
        targetPos.X,
        height,
        targetPos.Z
    )

    print("→ Bay ngang:", pointAboveChest)

    TweenTo(
        CFrame.new(pointAboveChest)
    )


    -- ========================================================
    -- ĐIỂM 3: BAY THẲNG XUỐNG RƯƠNG
    -- ========================================================

    print("↓ Hạ xuống:", targetPos)

    TweenTo(
        CFrame.new(targetPos)
    )

    task.wait(0.3)
end


-- ============================================================
-- AUTO COLLECT CHEST
-- ============================================================

task.spawn(function()

    while task.wait(0.1) do

        if not _G.AutoCollectChest then
            continue
        end

        local character = LocalPlayer.Character

        if not character then
            continue
        end

        local root = character:FindFirstChild("HumanoidRootPart")

        if not root then
            continue
        end


        -- ====================================================
        -- TÌM RƯƠNG GẦN NHẤT
        -- ====================================================

        local currentPosition = root.Position

        local chests = CollectionService:GetTagged("_ChestTagged")

        local nearestChest = nil
        local nearestDistance = math.huge


        for _, chest in ipairs(chests) do

            if chest
                and chest.Parent
                and not chest:GetAttribute("IsDisabled")
            then

                local chestPosition = chest:GetPivot().Position

                local distance =
                    (chestPosition - currentPosition).Magnitude

                if distance < nearestDistance then

                    nearestDistance = distance
                    nearestChest = chest

                end
            end
        end
        if nearestChest then

            local chestPosition =
                nearestChest:GetPivot().Position

            local target = CFrame.new(chestPosition)

            Tween2(target)

        end

    end

end)
