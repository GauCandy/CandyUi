
local tool = Instance.new("Tool")
tool.Name = "Draco aura"
tool.RequiresHandle = false
tool.CanBeDropped = false

local selectedTarget = nil
local highlight = nil
local circle = nil
local renderSteppedConnection = nil

-- Tạo vòng tròn 2D
local function createCircle()
    if not circle then
        circle = Drawing.new("Circle")
        circle.Visible = true
        circle.Color = Color3.fromRGB(0, 255, 0)
        circle.Thickness = 2
        circle.Filled = false
        circle.Radius = CIRCLE_RADIUS -- Sử dụng giá trị bán kính từ cấu hình
    end
end

-- Kiểm tra mục tiêu có phải là NPC trong Enemies
local function isNPC(target)
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    return enemiesFolder and target:IsDescendantOf(enemiesFolder)
end

-- Kiểm tra mục tiêu có phải là người chơi và không phải người dùng hiện tại
local function isPlayer(target)
    local playerFromTarget = game.Players:GetPlayerFromCharacter(target)
    local localPlayer = game.Players.LocalPlayer
    return playerFromTarget and playerFromTarget ~= localPlayer
end

-- Kiểm tra nếu mục tiêu nằm trong vòng tròn
local function isTargetInCircle(target, mousePos)
    local camera = workspace.CurrentCamera
    local targetPos, onScreen = camera:WorldToViewportPoint(target.Position)
    if not onScreen then return false end

    local distance = (Vector2.new(targetPos.X, targetPos.Y) - mousePos).Magnitude
    return distance <= circle.Radius
end

-- Tạo highlight mục tiêu
local function createHighlight(target)
    if highlight then
        highlight:Destroy()
    end
    highlight = Instance.new("Highlight")
    highlight.Adornee = target
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.Parent = game.CoreGui
end

-- Tấn công mục tiêu bằng Soru
local function attackTarget(target, rootPart)
    if not target or not rootPart then return end
    local humanoid = target:FindFirstChildOfClass("Humanoid")
    local targetRoot = target:FindFirstChild("HumanoidRootPart")

    if humanoid and targetRoot and humanoid.Health > 0 then
        local args = {
            [1] = "Soru",
            [2] = rootPart.CFrame,
            [3] = targetRoot.CFrame,
            [4] = tick(),
            [5] = math.random(100000, 999999)
        }

        -- Gửi lệnh đến server để thực hiện Soru
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommE"):FireServer(unpack(args))
    end
end

-- Kích hoạt Tool
tool.Activated:Connect(function()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    if not rootPart then
        warn("Không tìm thấy HumanoidRootPart của nhân vật.")
        return
    end

    createCircle()

    local mouse = player:GetMouse()

    -- Nếu đã kết nối RenderStepped thì ngắt kết nối trước
    if renderSteppedConnection then
        renderSteppedConnection:Disconnect()
    end

    -- Kết nối RenderStepped để di chuyển vòng tròn theo chuột
    renderSteppedConnection = game:GetService("RunService").RenderStepped:Connect(function()
        -- Di chuyển vòng tròn theo chuột
        circle.Position = Vector2.new(mouse.X, mouse.Y)

        -- Tìm mục tiêu gần nhất trong vòng tròn
        local closestTarget = nil
        local closestDistance = math.huge

        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
                local targetPart = obj:FindFirstChild("HumanoidRootPart")
                local distanceToPlayer = (targetPart.Position - rootPart.Position).Magnitude
                if distanceToPlayer <= MAX_DISTANCE and isTargetInCircle(targetPart, Vector2.new(mouse.X, mouse.Y)) then
                    local camera = workspace.CurrentCamera
                    local targetPos = camera:WorldToViewportPoint(targetPart.Position)
                    local distanceToCircle = (Vector2.new(targetPos.X, targetPos.Y) - circle.Position).Magnitude

                    if distanceToCircle < closestDistance then
                        closestDistance = distanceToCircle
                        closestTarget = obj
                    end
                end
            end
        end

        if closestTarget and (isNPC(closestTarget) or isPlayer(closestTarget)) then
            selectedTarget = closestTarget
            createHighlight(closestTarget)
        else
            if highlight then
                highlight:Destroy()
                highlight = nil
            end
            selectedTarget = nil
        end

        -- Nếu mục tiêu là NPC, tự động tấn công
        if selectedTarget and isNPC(selectedTarget) then
            attackTarget(selectedTarget, rootPart)
        elseif selectedTarget and isPlayer(selectedTarget) and AUTO_ATTACK_PLAYER then
            -- Nếu mục tiêu là người chơi và AUTO_ATTACK_PLAYER = true, tự động tấn công
            attackTarget(selectedTarget, rootPart)
        end
    end)

    -- Khi click chuột, kiểm tra và tấn công người chơi
    mouse.Button1Down:Connect(function()
        if selectedTarget and isPlayer(selectedTarget) and not AUTO_ATTACK_PLAYER then
            attackTarget(selectedTarget, rootPart)
        end
    end)
end)

-- Khi Tool bị vô hiệu hóa (cất đi)
tool.Unequipped:Connect(function()
    if highlight then
        highlight:Destroy()
        highlight = nil
    end
    if circle then
        circle:Remove()
        circle = nil
    end
    if renderSteppedConnection then
        renderSteppedConnection:Disconnect()
        renderSteppedConnection = nil
    end
    selectedTarget = nil
end)

-- Đưa Tool vào ba lô
local function giveToolToPlayer()
    local player = game.Players.LocalPlayer
    local backpack = player:WaitForChild("Backpack")
    tool.Parent = backpack
end

giveToolToPlayer()
