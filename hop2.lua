local function HopServer()
    local placeId = game.PlaceId
    local currentJobId = game.JobId
    local url =
        "https://games.roblox.com/v1/games/"
        .. placeId
        .. "/servers/Public?sortOrder=Asc&limit=100"

    local success, result = pcall(function()
        return HttpService:JSONDecode(
            game:HttpGet(url)
        )
    end)

    for _, server in ipairs(result.data or {}) do
        local jobId = tostring(server.id)
        local playing = tonumber(server.playing) or 0
        local maxPlayers = tonumber(server.maxPlayers) or 0

        if jobId ~= currentJobId
            and playing < maxPlayers then

            local ok = pcall(function()
                ReplicatedStorage.__ServerBrowser:InvokeServer(
                    "teleport",
                    jobId
                )
            end)

            return
        end
    end
end
function fixlag()
    local lighting = game:GetService("Lighting")
    local g = game
    local w = g.Workspace
    local l = g.Lighting
    local t = w.Terrain
    if lighting:FindFirstChild("FantasySky") then
        lighting.FantasySky:Destroy()
    end
    t.WaterWaveSize = 0
    t.WaterWaveSpeed = 0
    t.WaterReflectance = 0
    t.WaterTransparency = 0
    l.GlobalShadows = false
    l.FogEnd = 9e9
    l.Brightness = 0
    for _, v in pairs(g:GetDescendants()) do
        if v:IsA("Part") or v:IsA("Union") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then 
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
        elseif v:IsA("Explosion") then
            v.BlastPressure = 1
            v.BlastRadius = 1
        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false
        elseif v:IsA("MeshPart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            v.TextureID = "rbxassetid://10385902758728957"
        end
    end
    for _, e in pairs(l:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or 
           e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
            e.Enabled = false
        end
    end
    for _, v in pairs(game:GetService("Workspace").Camera:GetDescendants()) do
        if v:IsA("Part") and v.Material == Enum.Material.Water then
            v.Transparency = 1
            v.Material = Enum.Material.Plastic
        end
    end
end
wait(30)
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer -- Lấy người chơi đang chạy script
local playerNames = getgenv().CheckpPlayer
for _, playerName in ipairs(playerNames) do 
    if playerName == localPlayer.Name then
        print("Tên tôi có trong danh sách, bỏ qua kiểm tra.") 
    else
        local player = Players:FindFirstChild(playerName)
        if player then
            print(playerName .. " đang ở trong server, tôi thoát game.")
            HopServer()
            break -- Dừng vòng lặp ngay khi tìm thấy người cần tránh
        else
            print(playerName .. " không có trong server, tôi ở lại.")
            fixlag()
        end
    end
end
