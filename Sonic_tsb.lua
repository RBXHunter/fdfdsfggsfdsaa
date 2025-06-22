-- Главный скрипт загрузки эксплойтов с единым управлением
-- Хостится на raw GitHub: https://raw.githubusercontent.com/username/repository/main/MasterExploitLoader.lua

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local task = task

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Интерфейс
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MasterExploitGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 120, 0, 40)
button.Position = UDim2.new(0, 10, 0, 10)
button.Text = "Kill Script"
button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.SourceSansBold
button.TextSize = 16
button.Parent = screenGui

-- Глобальный флаг для управления скриптами
_G.isScriptEnabled = true

-- Список соединений для очистки
local connections = {}

-- Список скриптов (замените ссылки на реальные raw GitHub ссылки)
local scripts = {
    "https://raw.githubusercontent.com/username/repository/main/4sposobka_sonic.lua",
    "https://raw.githubusercontent.com/username/repository/main/2sposobka_sonic.lua",
    "https://raw.githubusercontent.com/username/repository/main/3sposobka_sonic.lua",
    "https://raw.githubusercontent.com/username/repository/main/1sposobka_sonic.lua",
}

-- Функция для очистки индикаторов
local function clearIndicators()
    for _, model in pairs(workspace.Live:GetChildren()) do
        if model:FindFirstChild("TargetGui") then
            model.TargetGui:Destroy()
        end
    end
end

-- Функция для остановки всех анимаций
local function stopAllAnimations()
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                if track.IsPlaying then
                    track:Stop()
                end
            end
        end
    end
end

-- Функция для остановки движения
local function stopMovement()
    local character = player.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.Velocity = Vector3.new(0, 0, 0)
        end
    end
end

-- Загрузка и выполнение скриптов
local function loadScripts()
    for i, url in ipairs(scripts) do
        if not _G.isScriptEnabled then break end

        local success, result = pcall(function()
            local code = game:HttpGet(url)
            local func = loadstring(code)
            if func then
                func()
            end
        end)

        if success then
            print("✅ Скрипт #" .. i .. " загружен: " .. url)
        else
            warn("⚠️ Ошибка загрузки скрипта #" .. i .. ": " .. url .. " | " .. tostring(result))
        end

        task.wait(0.2)
    end
end

-- Отслеживание новых персонажей для очистки при возрождении
local characterConnection = player.CharacterAdded:Connect(function(character)
    if not _G.isScriptEnabled then return end
    -- Очистка индикаторов при появлении нового персонажа
    clearIndicators()
    stopAllAnimations()
    stopMovement()
end)
table.insert(connections, characterConnection)

-- Запуск скриптов
task.spawn(loadScripts)

-- Обработка кнопки "Kill Script"
button.MouseButton1Click:Connect(function()
    _G.isScriptEnabled = false
    -- Отключение всех соединений
    for _, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
    -- Очистка эффектов
    clearIndicators()
    stopAllAnimations()
    stopMovement()
    -- Удаление интерфейса
    if screenGui then
        screenGui:Destroy()
    end
    print("🛑 Все скрипты отключены, эффекты очищены, интерфейс удалён")
end)

-- Очистка при выходе игрока
game:BindToClose(function()
    _G.isScriptEnabled = false
    for _, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
    clearIndicators()
    stopAllAnimations()
    stopMovement()
    if screenGui then
        screenGui:Destroy()
    end
end)
