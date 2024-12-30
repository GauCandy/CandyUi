getgenv().settings = {
    -- vòng tròn aim bot
    Aimbot_FOV_Radius = 100,
    -- màu vòng tròn ngoài
    Aimbot_FOV_Color = Color3.fromRGB(255, 255, 0),
    -- màu tâm
    FOV_CrossColor = Color3.fromRGB(255, 0, 0),
    -- độ dày của tâm
    FOV_CrossSize = 15,
    -- tầm đánh tối đa
    MaxDistance = 900,
    -- tốc độ đánh chỉnh 0 cũng được
    -- địch die rất nhanh cả mana của you
    AuraLoopDelay = 0.1,
    -- chế độ tấn công
    -- 1 Player&Npc
    -- 2 Chỉ Player
    -- 3 chỉ Npc
    Mode = 1
}
loadstring(game:HttpGet(('https://raw.githubusercontent.com/GauCandy/CandyUi/refs/heads/main/draco%20aura.lua'),true))()

