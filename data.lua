local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local FileName = LocalPlayer.Name .. ".json"

local function GetData()
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChild("Humanoid")
    local Energy = Character and Character:FindFirstChild("Energy")

    local Data = LocalPlayer:FindFirstChild("Data")
    local Leaderstats = LocalPlayer:FindFirstChild("leaderstats")

    local function GetValue(parent, name)
        local obj = parent and parent:FindFirstChild(name)
        return obj and obj.Value or nil
    end

    local Bounty = Leaderstats and Leaderstats:FindFirstChild("Bounty/Honor")

    return {
        Name = LocalPlayer.Name,
        DisplayName = LocalPlayer.DisplayName,
        Level = GetValue(Data, "Level"),
        Beli = GetValue(Data, "Beli"),
        Fragments = GetValue(Data, "Fragments"),
        BountyHonor = Bounty and Bounty.Value or nil,

        Health = Humanoid and Humanoid.Health or nil,
        MaxHealth = Humanoid and Humanoid.MaxHealth or nil,

        Energy = GetValue(Character, "Energy"),
        MaxEnergy = Energy and Energy:GetAttribute("MaxValue")
            or (Energy and Energy:FindFirstChild("MaxValue")
                and Energy.MaxValue.Value)
            or nil,

        Race = GetValue(Data, "Race"),
        DevilFruit = GetValue(Data, "DevilFruit"),

        UpdatedAt = os.date("%Y-%m-%d %H:%M:%S")
    }
end

while true do
    local Success, Error = pcall(function()
        local Data = GetData()
        local Json = HttpService:JSONEncode(Data)

        -- Lưu file JSON nếu executor hỗ trợ writefile
        if type(writefile) == "function" then
            writefile(FileName, Json)
        else
            warn("Executor không hỗ trợ writefile!")
            print(Json)
        end
    end)

    if not Success then
        warn("Lỗi lưu JSON:", Error)
    end

    task.wait(5)
end
