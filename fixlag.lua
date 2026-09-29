--// Blox Fruits FPS Optimizer
--// Giữ lại Chest / Rương
--// Không Destroy object, chỉ ẩn để hạn chế lỗi game

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local KEEP_NAMES = {
    "chest",
    "treasure",
    "chest1",
    "chest2",
    "chest3",
    "golden chest",
    "legendary chest",
    "mythical chest"
}

local function isChest(obj)
    local name = obj.Name:lower()

    for _, keyword in ipairs(KEEP_NAMES) do
        if name:find(keyword, 1, true) then
            return true
        end
    end

    return false
end

--// Ẩn BasePart không phải Chest
local function optimizePart(obj)
    if not obj:IsA("BasePart") then
        return
    end

    if isChest(obj) then
        return
    end

    obj.LocalTransparencyModifier = 1
    obj.CastShadow = false
end

--// Tắt hiệu ứng nặng
local function optimizeEffect(obj)
    if obj:IsA("ParticleEmitter")
        or obj:IsA("Trail")
        or obj:IsA("Beam")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles") then

        obj.Enabled = false
    end
end

--// Xử lý toàn bộ Workspace
for _, obj in ipairs(Workspace:GetDescendants()) do
    optimizePart(obj)
    optimizeEffect(obj)
end

--// Tắt post-processing
for _, obj in ipairs(Lighting:GetChildren()) do
    if obj:IsA("BloomEffect")
        or obj:IsA("BlurEffect")
        or obj:IsA("ColorCorrectionEffect")
        or obj:IsA("DepthOfFieldEffect")
        or obj:IsA("SunRaysEffect") then

        obj.Enabled = false
    end
end

--// Giảm shadow
Lighting.GlobalShadows = false
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0

--// Tự động xử lý object mới xuất hiện
Workspace.DescendantAdded:Connect(function(obj)
    task.wait()

    optimizePart(obj)
    optimizeEffect(obj)
end)

print("================================")
print(" Blox Fruits FPS Optimizer ON")
print(" Chest/Rương: GIỮ")
print(" Map/Object khác: ẨN")
print(" Particle/Effect: TẮT")
print(" Shadow: TẮT")
print("================================")
