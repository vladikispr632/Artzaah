-- SADHUB | Stage Sniper (с авто-загрузкой после телепорта)
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local placeId = game.PlaceId

-- ⚠️ СЮДА ВСТАВЬ ССЫЛКУ НА СВОЙ СКРИПТ (откуда он будет скачиваться после ТП)
-- Например: "https://raw.githubusercontent.com/vladikispr632/Babft-script/refs/heads/main/sniper.lua"
local scriptUrl = "https://raw.githubusercontent.com/vladikispr632/Artzaah/refs/heads/main/README.lua" 

-- ===== СПИСОК ЭТАПОВ =====
local stages = {
    {name = "Stage Entrance", display = "Stage Entrance", emoji = "🏁", imageId = "", internal = "Entrance"},
    {name = "Tribal Stage", display = "Tribal Stage", emoji = "🌴", imageId = "", internal = "Tribal"},
    {name = "Crystal Cave", display = "Crystal Cave", emoji = "💎", imageId = "", internal = "Cave"},
    {name = "Trench Stage", display = "Trench Stage", emoji = "🌊", imageId = "", internal = "Trench"},
    {name = "Arcade Stage", display = "Arcade Stage", emoji = "🕹️", imageId = "", internal = "Arcade"},
    {name = "Lighthouse Stage", display = "Lighthouse Stage", emoji = "🗼", imageId = "", internal = "Lighthouse"},
    {name = "Enchanted Forest", display = "Enchanted Forest (Грибы)", emoji = "🍄", imageId = "", internal = "Enchanted"},
    {name = "Treasure", display = "Treasure (Финал)", emoji = "💰", imageId = "", internal = "Treasure"},
}

-- ===== СОСТОЯНИЕ =====
_G.SADHUB_SEARCHING = _G.SADHUB_SEARCHING or false
_G.SADHUB_TARGET_STAGE = _G.SADHUB_TARGET_STAGE or nil
_G.SADHUB_VISITED = _G.SADHUB_VISITED or {}

-- ===== ФУНКЦИЯ ПРОВЕРКИ =====
local function hasStage(internalKeyword)
    local stagesFolder = workspace:FindFirstChild("BoatStages")
    if not stagesFolder then return false end
    local normal = stagesFolder:FindFirstChild("NormalStages")
    if not normal then return false end
    
    for _, child in ipairs(normal:GetDescendants()) do
        if child.Name:lower():find(internalKeyword:lower()) then
            return true
        end
    end
    return false
end

-- ===== ПОИСК И ТЕЛЕПОРТ С АВТО-ЗАГРУЗКОЙ =====
local function hopToServerWithStage(targetInternal)
    if _G.SADHUB_SEARCHING then return end
    _G.SADHUB_SEARCHING = true
    _G.SADHUB_TARGET_STAGE = targetInternal
    
    task.spawn(function()
        local cursor = ""
        local found = false
        
        while _G.SADHUB_SEARCHING do
            local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
            if cursor ~= "" then url = url .. "&cursor=" .. cursor end
            
            local success, response = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(url))
            end)
            
            if not success or not response then
                warn("[SADHUB] Ошибка получения серверов")
                break
            end
            
            for _, server in ipairs(response.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId and not _G.SADHUB_VISITED[server.id] then
                    _G.SADHUB_VISITED[server.id] = true
                    
                    -- ⚡ МАГИЯ АВТО-ЗАГРУЗКИ ⚡
                    -- Формируем код, который выполнится на НОВОМ сервере
                    local autoLoadCode = string.format([[
                        _G.SADHUB_SEARCHING = true
                        _G.SADHUB_TARGET_STAGE = "%s"
                        loadstring(game:HttpGet("%s"))()
                    ]], targetInternal, scriptUrl)
                    
                    -- Проверяем поддержку функции в твоем инжекторе (Delta её поддерживает)
                    if syn and syn.queue_on_teleport then
                        syn.queue_on_teleport(autoLoadCode)
                    elseif queue_on_teleport then
                        queue_on_teleport(autoLoadCode)
                    else
                        warn("[SADHUB] Твой инжектор не поддерживает queue_on_teleport!")
                    end
                    
                    -- Телепортируемся
                    TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
                    found = true
                    break
                end
            end
            
            if found then break end
            cursor = response.nextPageCursor or ""
            if cursor == "" or cursor == nil then break end
        end
        
        if not found and _G.SADHUB_SEARCHING then
            _G.SADHUB_SEARCHING = false
            warn("[SADHUB] Свободных серверов не найдено")
        end
    end)
end

-- ===== ПРОВЕРКА ПРИ ЗАГРУЗКЕ (ПРОДОЛЖЕНИЕ ПОИСКА) =====
task.spawn(function()
    task.wait(4) -- Ждем загрузки игры
    if _G.SADHUB_SEARCHING and _G.SADHUB_TARGET_STAGE then
        if hasStage(_G.SADHUB_TARGET_STAGE) then
            _G.SADHUB_SEARCHING = false
            print("[SADHUB] ✅ Этап найден! Поиск остановлен.")
            -- Пытаемся обновить текст в панели, если она загрузилась
            local gui = player.PlayerGui:FindFirstChild("SADHUB_Sniper")
            if gui then
                local status = gui:FindFirstChild("StatusLabel", true)
                if status then
                    status.Text = "✅ Этап найден! Остановлено."
                    status.TextColor3 = Color3.fromRGB(100, 255, 100)
                end
            end
        else
            print("[SADHUB] Этапа нет. Ищем дальше...")
            hopToServerWithStage(_G.SADHUB_TARGET_STAGE)
        end
    end
end)

-- ===== ИНТЕРФЕЙС =====
local old = player.PlayerGui:FindFirstChild("SADHUB_Sniper")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "SADHUB_Sniper"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 99
gui.Parent = player.PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 480, 0, 450)
main.Position = UDim2.new(0.5, -240, 0.5, -225)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 80, 120)
stroke.Thickness = 1.5
stroke.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
title.Text = "🔍 SADHUB | Auto Sniper"
title.TextColor3 = Color3.fromRGB(240, 240, 250)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = main
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -100)
scroll.Position = UDim2.new(0, 10, 0, 50)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 1, -40)
statusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
statusLabel.Text = _G.SADHUB_SEARCHING and ("🔍 Ищем: " .. tostring(_G.SADHUB_TARGET_STAGE)) or "Выберите этап"
statusLabel.TextColor3 = _G.SADHUB_SEARCHING and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(180, 180, 190)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.Parent = main
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)

for i, stage in ipairs(stages) do
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, 56)
    card.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    card.Parent = scroll
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(0, 40, 0, 40)
    img.Position = UDim2.new(0, 8, 0.5, -20)
    img.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    img.Image = stage.imageId ~= "" and stage.imageId or ""
    img.Parent = card
    Instance.new("UICorner", img).CornerRadius = UDim.new(0, 6)
    
    if stage.imageId == "" then
        local emoji = Instance.new("TextLabel")
        emoji.Size = UDim2.new(1, 0, 1, 0)
        emoji.BackgroundTransparency = 1
        emoji.Text = stage.emoji
        emoji.TextSize = 24
        emoji.Parent = img
    end
    
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -120, 0, 24)
    nameLbl.Position = UDim2.new(0, 58, 0, 8)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = stage.display
    nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 14
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Parent = card
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 28)
    btn.Position = UDim2.new(1, -90, 0.5, -14)
    btn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
    btn.Text = "▶ Найти"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = card
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(function()
        if scriptUrl == "ТВОЯ_ССЫЛКА_СЮДА" then
            statusLabel.Text = "❌ Ошибка: Укажи ссылку на скрипт в коде!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        
        _G.SADHUB_VISITED = {}
        statusLabel.Text = "🔍 Начинаем поиск: " .. stage.display
        statusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        hopToServerWithStage(stage.internal)
    end)
    
    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 60)}):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
    end)
end

main.Size = UDim2.new(0, 0, 0, 0)
TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
    Size = UDim2.new(0, 480, 0, 450)
}):Play()
