local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local function HopServer()
    local placeId = game.PlaceId
    local currentJobId = game.JobId

    local url =
        "https://games.roblox.com/v1/games/"
        .. placeId
        .. "/servers/Public?sortOrder=Asc&limit=100"

    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success or not result or not result.data then
        warn("Không lấy được danh sách server")
        return
    end

    for _, server in ipairs(result.data) do
        local jobId = tostring(server.id)
        local playing = tonumber(server.playing) or 0
        local maxPlayers = tonumber(server.maxPlayers) or 0

        if jobId ~= currentJobId and playing < maxPlayers then
            print("Đang hop sang:", jobId)

            pcall(function()
                ReplicatedStorage.__ServerBrowser:InvokeServer(
                    "teleport",
                    jobId
                )
            end)

            return
        end
    end

    warn("Không tìm thấy server phù hợp")
end


local function fixlag()
    local Lighting = game:GetService("Lighting")
    local Workspace = game:GetService("Workspace")
    local Terrain = Workspace.Terrain

    local sky = Lighting:FindFirstChild("FantasySky")
    if sky then
        sky:Destroy()
    end

    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 0

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 0

    for _, v in ipairs(game:GetDescendants()) do

        if v:IsA("Part")
        or v:IsA("UnionOperation")
        or v:IsA("CornerWedgePart")
        or v:IsA("TrussPart") then

            v.Material = Enum.Material.Plastic
            v.Reflectance = 0

        elseif v:IsA("Decal")
        or v:IsA("Texture") then

            v.Transparency = 1

        elseif v:IsA("ParticleEmitter")
        or v:IsA("Trail") then

            v.Lifetime = NumberRange.new(0)

        elseif v:IsA("Explosion") then

            v.BlastPressure = 1
            v.BlastRadius = 1

        elseif v:IsA("Fire")
        or v:IsA("SpotLight")
        or v:IsA("Smoke")
        or v:IsA("Sparkles") then

            v.Enabled = false

        elseif v:IsA("MeshPart") then

            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            v.TextureID = "rbxassetid://10385902758728957"
        end
    end

    for _, e in ipairs(Lighting:GetChildren()) do

        if e:IsA("BlurEffect")
        or e:IsA("SunRaysEffect")
        or e:IsA("ColorCorrectionEffect")
        or e:IsA("BloomEffect")
        or e:IsA("DepthOfFieldEffect") then

            e.Enabled = false
        end
    end
end


task.wait(30)


local playerNames = getgenv().CheckpPlayer or {}

for _, playerName in ipairs(playerNames) do

    if playerName == LocalPlayer.Name then
        continue
    end

    local player = Players:FindFirstChild(playerName)

    if player then

        print(playerName .. " đang ở trong server -> Hop")

        HopServer()

        break
    end
end
