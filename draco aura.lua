-- Khai báo trước các service để tối ưu truy cập
local dwCamera = workspace.CurrentCamera
local dwRunService = game:GetService("RunService")
local dwUIS = game:GetService("UserInputService")
local dwEntities = game:GetService("Players")
local dwLocalPlayer = dwEntities.LocalPlayer
local dwMouse = dwLocalPlayer:GetMouse()
local dwWorkspace = game:GetService("Workspace")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Danh sách whitelist cố định (người dùng không bị xóa)
local whitelistUsers = {"gaulovecandy"}

-- Danh sách whitelist tạm thời (team, Allies)
local whitelistTeam = {}

-- Cấu hình
getgenv().settings = getgenv().settings or {
    Aimbot_Draw_FOV = true,
    Aimbot_FOV_Radius = 100,
    Aimbot_FOV_Color = Color3.fromRGB(255, 255, 255),
    FOV_CrossColor = Color3.fromRGB(255, 0, 0),
    FOV_CrossSize = 10,
    MaxDistance = 900,
    AuraLoopDelay = 0.1,
    Mode = 1 -- 1 là tấn công cả người chơi lẫn NPC, 2 là tấn công mỗi người chơi, 3 là tấn công mỗi NPC
}

-- Hàm kiểm tra người dùng có trong whitelist cố định hay không
local function isWhitelisted(playerName)
    return table.find(whitelistUsers, playerName:lower()) ~= nil
end

-- Hàm kiểm tra người dùng có trong whitelist team tạm thời hay không
local function isWhitelistedTeam(playerName)
    return table.find(whitelistTeam, playerName:lower()) ~= nil
end

-- Hàm cập nhật danh sách whitelist team từ team và Allies
local function updateWhitelistTeam()
    whitelistTeam = {} -- Làm mới danh sách team mỗi lần cập nhật

    -- Lấy team của người chơi
    local playerTeam = dwLocalPlayer.Team

    -- Nếu người chơi thuộc team Marines (Hải quân), thêm đồng đội cùng team vào whitelistTeam
    if playerTeam and playerTeam.Name == "Marines" then
        for _, player in ipairs(dwEntities:GetPlayers()) do
            if player.Team == playerTeam and player ~= dwLocalPlayer then
                if not isWhitelistedTeam(player.Name) then
                    table.insert(whitelistTeam, player.Name:lower())
                    print("Đã thêm đồng đội Hải quân vào whitelistTeam:", player.Name)
                end
            end
        end
    end

    -- Nếu người chơi thuộc team Pirates (Hải tặc), kiểm tra danh sách liên minh (Allies)
    if playerTeam and playerTeam.Name == "Pirates" then
        -- Đường dẫn đến Frame trong ScrollingFrame
        local alliesFrame = dwLocalPlayer:FindFirstChild("PlayerGui")
            and dwLocalPlayer.PlayerGui:FindFirstChild("Main")
            and dwLocalPlayer.PlayerGui.Main:FindFirstChild("Allies")
            and dwLocalPlayer.PlayerGui.Main.Allies:FindFirstChild("Container")
            and dwLocalPlayer.PlayerGui.Main.Allies.Container:FindFirstChild("Allies")
            and dwLocalPlayer.PlayerGui.Main.Allies.Container.Allies:FindFirstChild("ScrollingFrame")
            and dwLocalPlayer.PlayerGui.Main.Allies.Container.Allies.ScrollingFrame:FindFirstChild("Frame")

        -- Kiểm tra nếu Frame tồn tại
        if alliesFrame then
            for _, child in ipairs(alliesFrame:GetChildren()) do
                -- Kiểm tra nếu file con là ImageButton
                if child:IsA("ImageButton") then
                    local allyName = child.Name -- Tên ImageButton chính là tên đồng minh
                    print("Đã tìm thấy đồng minh:", allyName) -- In ra tên đồng minh
                    if not isWhitelistedTeam(allyName) then
                        table.insert(whitelistTeam, allyName:lower()) -- Thêm đồng minh vào whitelistTeam
                    end
                end
            end
        else
            print("Không tìm thấy Frame chứa danh sách liên minh.")
        end
    end
end

-- Hàm xóa danh sách whitelist team khi tắt tool
local function clearWhitelistTeam()
    whitelistTeam = {} -- Làm sạch danh sách team tạm thời
end

-- Drawing cho FOV và Crosshair
local fovcircle = Drawing.new("Circle")
local crossTop = Drawing.new("Line")
local crossBottom = Drawing.new("Line")
local crossLeft = Drawing.new("Line")
local crossRight = Drawing.new("Line")

-- Thiết lập ban đầu
local function initializeDrawings()
    fovcircle.Visible = false
    fovcircle.Radius = getgenv().settings.Aimbot_FOV_Radius
    fovcircle.Color = getgenv().settings.Aimbot_FOV_Color
    fovcircle.Thickness = 1
    fovcircle.Filled = false
    fovcircle.Transparency = 1

    for _, cross in pairs({crossTop, crossBottom, crossLeft, crossRight}) do
        cross.Visible = false
        cross.Thickness = 2
        cross.Color = getgenv().settings.FOV_CrossColor
    end
end

initializeDrawings()

-- Công cụ kích hoạt aura
local tool = Instance.new("Tool")
tool.Name = "Draco Aura"
tool.RequiresHandle = false
tool.Parent = dwLocalPlayer.Backpack

-- Toggle hiển thị FOV
local function toggleAimbotDisplay(visible)
    fovcircle.Visible = visible
    for _, cross in pairs({crossTop, crossBottom, crossLeft, crossRight}) do
        cross.Visible = visible
    end
end

-- Highlight mục tiêu
local function createHighlight(target)
    if not target:FindFirstChild("Highlight") then
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(0, 255, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0.5
        highlight.Parent = target
    end
end

local function removeHighlight(target)
    local highlight = target:FindFirstChild("Highlight")
    if highlight then
        highlight:Destroy()
    end
end

-- Gửi yêu cầu aura đến server
local function callAuraFunction(target)
    if not target:FindFirstChild("HumanoidRootPart") then return end
    local rootPartPosition = target.HumanoidRootPart.Position

    replicatedStorage:WaitForChild("Remotes"):WaitForChild("CommE"):FireServer("Soru", CFrame.new(rootPartPosition), CFrame.new(rootPartPosition))
end

-- Biến trạng thái
local activeTargets = {}
local attacking = false

-- Sự kiện khi tool được kích hoạt
tool.Activated:Connect(function()
    dwUIS.MouseIconEnabled = false
    toggleAimbotDisplay(true)
    attacking = true

    -- Cập nhật danh sách whitelist team khi tool được kích hoạt
    updateWhitelistTeam()
end)

-- Sự kiện khi tool bị tắt
tool.Unequipped:Connect(function()
    dwUIS.MouseIconEnabled = true
    toggleAimbotDisplay(false)
    attacking = false

    -- Xóa danh sách whitelist team tạm thời
    clearWhitelistTeam()

    -- Gỡ bỏ highlight của các mục tiêu còn lại
    for target in pairs(activeTargets) do
        removeHighlight(target)
        activeTargets[target] = nil
    end
end)

-- Xử lý Aura chính
dwRunService.Heartbeat:Connect(function()
    local mousePosition = Vector2.new(dwMouse.X, dwMouse.Y + 56)
    fovcircle.Position = mousePosition

    local centerX = mousePosition.X
    local centerY = mousePosition.Y

    crossTop.From = Vector2.new(centerX, centerY - getgenv().settings.FOV_CrossSize)
    crossTop.To = Vector2.new(centerX, centerY - getgenv().settings.FOV_CrossSize / 2)
    crossBottom.From = Vector2.new(centerX, centerY + getgenv().settings.FOV_CrossSize / 2)
    crossBottom.To = Vector2.new(centerX, centerY + getgenv().settings.FOV_CrossSize)
    crossLeft.From = Vector2.new(centerX - getgenv().settings.FOV_CrossSize, centerY)
    crossLeft.To = Vector2.new(centerX - getgenv().settings.FOV_CrossSize / 2, centerY)
    crossRight.From = Vector2.new(centerX + getgenv().settings.FOV_CrossSize / 2, centerY)
    crossRight.To = Vector2.new(centerX + getgenv().settings.FOV_CrossSize, centerY)

    if attacking then
        local nearbyTargets = {}

        -- Chế độ 1: Tấn công cả người chơi và NPC
        if getgenv().settings.Mode == 1 or getgenv().settings.Mode == 2 then
            for _, player in ipairs(dwEntities:GetPlayers()) do
                if player ~= dwLocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    if not isWhitelisted(player.Name) and not isWhitelistedTeam(player.Name) then
                        table.insert(nearbyTargets, player.Character)
                    end
                end
            end
        end

        -- Chế độ 1 hoặc 3: Tấn công NPC
        if getgenv().settings.Mode == 1 or getgenv().settings.Mode == 3 then
            if dwWorkspace:FindFirstChild("Enemies") then
                for _, npc in ipairs(dwWorkspace.Enemies:GetChildren()) do
                    if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") then
                        table.insert(nearbyTargets, npc)
                    end
                end
            end
        end

        -- Kiểm tra các mục tiêu nằm trong FOV và phạm vi
        local validTargets = {}
        for _, target in ipairs(nearbyTargets) do
            local rootPart = target.HumanoidRootPart
            local targetPosition, onScreen = dwCamera:WorldToViewportPoint(rootPart.Position)

            if onScreen then
                local distance2D = (Vector2.new(targetPosition.X, targetPosition.Y) - mousePosition).Magnitude
                local distance3D = (rootPart.Position - dwLocalPlayer.Character.HumanoidRootPart.Position).Magnitude

                if distance2D <= getgenv().settings.Aimbot_FOV_Radius and distance3D <= getgenv().settings.MaxDistance and target.Humanoid.Health > 0 then
                    createHighlight(target)
                    table.insert(validTargets, target)
                else
                    removeHighlight(target)
                end
            else
                removeHighlight(target)
            end
        end

        -- Xử lý từng mục tiêu
        local delayPerTarget = #validTargets > 0 and getgenv().settings.AuraLoopDelay / #validTargets or 0
        for _, target in ipairs(validTargets) do
            if not activeTargets[target] then
                activeTargets[target] = true
                coroutine.wrap(function()
                    while activeTargets[target] and attacking and target.Humanoid.Health > 0 do
                        callAuraFunction(target)
                        task.wait(delayPerTarget)
                    end
                    activeTargets[target] = nil
                end)()
            end
        end
    end
end)
