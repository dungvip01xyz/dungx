local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local gui = Instance.new("ScreenGui")
gui.Name = "HopServerGUI"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 150, 0, 35)
button.Position = UDim2.new(0, 10, 0, 10)

button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 15
button.Text = "Hop Server"
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = button

local function HopServer()
    button.Text = "Finding..."

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

    if not success or not result then
        button.Text = "Error"
        task.wait(2)
        button.Text = "Hop Server"
        return
    end

    for _, server in ipairs(result.data or {}) do
        local jobId = tostring(server.id)
        local playing = tonumber(server.playing) or 0
        local maxPlayers = tonumber(server.maxPlayers) or 0

        if jobId ~= currentJobId
            and playing < maxPlayers then

            button.Text = "Teleport..."

            local ok = pcall(function()
                ReplicatedStorage.__ServerBrowser:InvokeServer(
                    "teleport",
                    jobId
                )
            end)

            if not ok then
                button.Text = "Failed"
                task.wait(2)
                button.Text = "Hop Server"
            end

            return
        end
    end

    button.Text = "No Server"
    task.wait(2)
    button.Text = "Hop Server"
end

button.MouseButton1Click:Connect(HopServer)
