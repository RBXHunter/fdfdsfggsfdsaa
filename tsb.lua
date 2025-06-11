local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Создание UI для кнопки
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.Name = "MasterLoaderGui"

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 100, 0, 50)
button.Position = UDim2.new(0, 10, 0, 10)
button.Text = "Kill Script"
button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Parent = screenGui

-- Переменная для отслеживания состояния скриптов
_G.isScriptEnabled = true -- Глобальная переменная для всех скриптов

-- Список скриптов для загрузки
local scripts = {
    "https://raw.githubusercontent.com/RBXHunter/fdfdsfggsfdsaa/refs/heads/main/2sposobka",
    "https://raw.githubusercontent.com/RBXHunter/fdfdsfggsfdsaa/refs/heads/main/Runbost",
    "https://raw.githubusercontent.com/RBXHunter/fdfdsfggsfdsaa/refs/heads/main/anims",
    "https://raw.githubusercontent.com/RBXHunter/fdfdsfggsfdsaa/refs/heads/main/Teleport",
    "https://raw.githubusercontent.com/RBXHunter/fdfdsfggsfdsaa/refs/heads/main/sidewaysdash"
}

-- Функция для загрузки скриптов
local function loadScripts()
    for i, url in ipairs(scripts) do
        local success, result = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if success then
            print("Loaded scripts")
        else
            warn("Failed to load scripts")
        end
        wait(0.2) -- Задержка 0.2 секунды между загрузками
    end
end

-- Загружаем скрипты
loadScripts()

-- Обработка нажатия кнопки
button.MouseButton1Click:Connect(function()
    _G.isScriptEnabled = false -- Отключаем выполнение всех скриптов
    screenGui:Destroy() -- Удаляем интерфейс
    print("All scripts and UI disabled")
end)
