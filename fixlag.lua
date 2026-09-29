-- FPS / Lag Optimizer
-- Đặt vào StarterPlayer > StarterPlayerScripts

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- Giảm chất lượng ánh sáng
Lighting.GlobalShadows = false
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0

-- Tắt các hiệu ứng hậu kỳ
for _, obj in ipairs(Lighting:GetChildren()) do
    if obj:IsA("BloomEffect")
        or obj:IsA("BlurEffect")
        or obj:IsA("ColorCorrectionEffect")
        or obj:IsA("SunRaysEffect")
        or obj:IsA("DepthOfFieldEffect") then

        obj.Enabled = false
    end
end

-- Giảm các hiệu ứng particle/trail
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("ParticleEmitter") then
        obj.Enabled = false

    elseif obj:IsA("Trail") then
        obj.Enabled = false

    elseif obj:IsA("Beam") then
        obj.Enabled = false
    end
end

print("FPS Optimizer: ON")
