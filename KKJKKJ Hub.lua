-- 🔥 Importar Fluent UI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- 🎮 Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ⚙️ Configurações Otimizadas
local StepAmountToTP = 1000 
local totalTime = 0.1
local SafeTPGuarantee = 3
local NEARBY_DISTANCE = 15
local CLOSE_BASE_SPEED = 45 -- Velocidade específica para fechar base
local SAFETP_SPEED = 45 -- Velocidade do SafeTP

-- 📡 Estado
local enabled = false
local closeBaseLoopEnabled = false
local currentTeleportTask = nil
local currentCloseBaseTask = nil
local savedBaseCFrame = nil -- CFrame da base salva
local savedCloseBaseCFrame = nil -- CFrame para fechar base
local rebirthNumber = 1 -- Número de rebirths (1-9)

-- 🌟 Criar Janela Fluent
local Window = Fluent:CreateWindow({
    Title = "KKJKKJ Hub",
    SubTitle = "Feito por: ChatGPT😎😎😎🤓🤓🤓🤓🤓🤓🤓🤓😎😎😎",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- 📋 Criar Abas
local Tabs = {
    Main = Window:AddTab({ Title = "🏠 Principal", Icon = "home" }),
    Settings = Window:AddTab({ Title = "⚙️ Configurações", Icon = "settings" }),
    Info = Window:AddTab({ Title = "ℹ️ Informações", Icon = "info" })
}

-- 🔍 Função para obter Character e HRP atualizados
local function getCharacterAndHRP()
    local character = LocalPlayer.Character
    if not character then return nil, nil end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil end
    
    return character, hrp
end

-- 🎯 Gerar posição aleatória próxima à base baseada na distância configurada
local function getRandomNearbyPosition(basePosition)
    local angle = math.random() * math.pi * 2
    local distance = math.random(5, NEARBY_DISTANCE) -- Distância entre 5 e o valor configurado
    
    local offsetX = math.cos(angle) * distance
    local offsetZ = math.sin(angle) * distance
    
    -- Pequena variação na altura para tornar o movimento mais natural
    local offsetY = math.random(-2, 2)
    
    return basePosition + Vector3.new(offsetX, offsetY, offsetZ)
end

-- 🚀 Teleporte suave genérico usando StepAmountToTP - CORRIGIDO
local function executeSmoothTeleport(startPosition, targetPosition, useSteps, customSpeed)
    local character, hrp = getCharacterAndHRP()
    if not character or not hrp then return false end
    
    local distance = (targetPosition - startPosition).Magnitude
    
    if distance > 1 then
        -- Usar velocidade customizada se fornecida
        local speed = customSpeed or SAFETP_SPEED -- Usar velocidade padrão do SafeTP se não especificada
        local adjustedDuration = distance / speed
        adjustedDuration = math.max(0.1, math.min(adjustedDuration, 3.0)) -- Limites ajustados
        
        local steps = useSteps or StepAmountToTP
        local stepDelay = adjustedDuration / steps
        
        -- Movimento suave
        for step = 1, steps do
            character, hrp = getCharacterAndHRP()
            if not character or not hrp then break end
            
            local progress = step / steps
            local stepPos = startPosition:Lerp(targetPosition, progress)
            
            -- Variação vertical para movimento mais natural
            local verticalVariation = math.sin(progress * math.pi) * 0.5
            stepPos = stepPos + Vector3.new(0, verticalVariation, 0)
            
            local originalRotation = hrp.CFrame - hrp.CFrame.Position
            hrp.CFrame = CFrame.new(stepPos) * originalRotation
            
            task.wait(stepDelay)
        end
        
        return true
    else
        -- Se já estiver próximo, só ajustar posição final
        hrp.CFrame = CFrame.new(targetPosition) * (hrp.CFrame - hrp.CFrame.Position)
        return true
    end
end

-- 🚀 Teleporte com Velocidade Consistente e Loop Anti-Detecção Baseado em Distância
local function teleportSmooth(basePosition, steps, duration)
    local character, hrp = getCharacterAndHRP()
    if not character or not hrp then 
        Fluent:Notify({
            Title = "SafeTP",
            Content = "❌ Character ou HumanoidRootPart não encontrado",
            Duration = 3
        })
        return 
    end
    
    local currentPosition = hrp.Position
    
    -- 🔄 Loop infinito com movimento baseado na distância próxima
    while enabled do
        -- Gerar nova posição aleatória dentro do raio configurado
        local targetPosition = getRandomNearbyPosition(basePosition)
        
        -- Usar função genérica de teleporte suave com velocidade do SafeTP
        local success = executeSmoothTeleport(currentPosition, targetPosition, steps, SAFETP_SPEED)
        
        if success then
            -- Atualizar posição atual
            currentPosition = targetPosition
        end
        
        -- ⏸️ Parada estratégica na nova posição
        if enabled then
            task.wait(math.random(0.1, 0.5)) -- Pausa aleatória entre 0.1 e 0.5 segundos
        end
        
        if not enabled then break end
    end
end

-- 🕐 Função para calcular tempo baseado no rebirth
local function getCloseBaseInterval()
    return 50 + (rebirthNumber * 10) -- rebirth 1 = 60s, rebirth 2 = 70s, etc.
end

-- 📦 Função para executar um teleporte suave para fechar base (usando StepAmountToTP) - CORRIGIDO
local function executeCloseBaseTeleport()
    local character, hrp = getCharacterAndHRP()
    if character and hrp then
        local currentPos = hrp.Position
        local targetPos = savedCloseBaseCFrame.Position
        
        -- Usar a função genérica de teleporte suave com velocidade específica para fechar base
        local success = executeSmoothTeleport(currentPos, targetPos, StepAmountToTP, CLOSE_BASE_SPEED)
        
        if success then
            -- Ajustar para o CFrame exato final
            hrp.CFrame = savedCloseBaseCFrame
            
            -- Resetar o personagem após fechar a base
            task.wait(0.1) -- Pequena pausa antes do reset
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.Health = 0
            end
        end
        
        return success
    end
    return false
end

-- 📦 Loop para fechar base automaticamente
local function startCloseBaseLoop()
    if not savedCloseBaseCFrame then
        Fluent:Notify({
            Title = "SafeTP",
            Content = "❌ Local de 'Fechar Base' não foi salvo!",
            Duration = 3
        })
        closeBaseLoopEnabled = false
        return
    end

    currentCloseBaseTask = task.spawn(function()
        local interval = getCloseBaseInterval()
        
        Fluent:Notify({
            Title = "SafeTP",
            Content = "🔄 Loop Fechar Base iniciado! Intervalo: " .. interval .. "s (Rebirth: " .. rebirthNumber .. ", Vel: " .. CLOSE_BASE_SPEED .. ")",
            Duration = 3
        })
        
        -- Primeira execução imediata
        if closeBaseLoopEnabled then
            local success = executeCloseBaseTeleport()
            if success and closeBaseLoopEnabled then
                Fluent:Notify({
                    Title = "SafeTP",
                    Content = "📦 Base fechada! Resetando... Próximo em " .. interval .. "s (Vel: " .. CLOSE_BASE_SPEED .. ")",
                    Duration = 2
                })
            end
        end
        
        -- Loop com timer
        while closeBaseLoopEnabled do
            -- Aguardar o intervalo
            task.wait(interval)
            
            if not closeBaseLoopEnabled then break end
            
            -- Executar teleporte
            local success = executeCloseBaseTeleport()
            if success and closeBaseLoopEnabled then
                Fluent:Notify({
                    Title = "SafeTP",
                    Content = "📦 Base fechada automaticamente! Resetando... Próximo em " .. interval .. "s (Vel: " .. CLOSE_BASE_SPEED .. ")",
                    Duration = 2
                })
            end
        end
        
        Fluent:Notify({
            Title = "SafeTP",
            Content = "🛑 Loop Fechar Base interrompido",
            Duration = 2
        })
        currentCloseBaseTask = nil
    end)
end

-- 📦 Teleporte instantâneo para fechar base
local function teleportToCloseBase()
    if not savedCloseBaseCFrame then
        Fluent:Notify({
            Title = "SafeTP",
            Content = "❌ Local de 'Fechar Base' não foi salvo!",
            Duration = 3
        })
        return
    end

    local character, hrp = getCharacterAndHRP()
    if character and hrp then
        hrp.CFrame = savedCloseBaseCFrame
        Fluent:Notify({
            Title = "SafeTP",
            Content = "📦 Teleportado para o local de Fechar Base!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "SafeTP",
            Content = "⚠️ Character ou HRP não encontrado!",
            Duration = 3
        })
    end
end

-- ⚙️ SafeTP com Loop Contínuo Baseado em Distância
local function SafeTPToBase()
    if not savedBaseCFrame then
        Fluent:Notify({
            Title = "SafeTP",
            Content = "❌ Nenhuma base foi salva! Clique em 'Copiar Base para Roubar' primeiro",
            Duration = 4
        })
        return
    end
    
    local basePosition = savedBaseCFrame.Position

    currentTeleportTask = task.spawn(function()
        Fluent:Notify({
            Title = "SafeTP",
            Content = "🔄 Iniciando Loop SafeTP (Movimento Aleatório - Raio: " .. NEARBY_DISTANCE .. ", Vel: " .. SAFETP_SPEED .. ")",
            Duration = 3
        })
        
        -- Loop infinito até desativar
        teleportSmooth(basePosition, StepAmountToTP, totalTime)
        
        Fluent:Notify({
            Title = "SafeTP",
            Content = "🛑 Loop SafeTP interrompido",
            Duration = 2
        })
        currentTeleportTask = nil
    end)
end

-- 🎮 Interface Principal

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- 📍 GERENCIAMENTO DE BASES
-- ═══════════════════════════════════════════════════════════════════════════════════════════
Tabs.Main:AddParagraph({
    Title = "📍 Gerenciamento de Bases",
    Content = "Configure as posições da base para roubar e o local para fechar base."
})

-- 🏠 Botão para salvar posição da base
Tabs.Main:AddButton({
    Title = "🏠 Copiar Base para Roubar",
    Description = "Salva sua posição atual como centro do movimento aleatório",
    Callback = function()
        local character, hrp = getCharacterAndHRP()
        if character and hrp then
            savedBaseCFrame = hrp.CFrame
            Fluent:Notify({
                Title = "SafeTP",
                Content = "✅ Base salva! Centro: " .. math.floor(hrp.Position.X) .. ", " .. math.floor(hrp.Position.Y) .. ", " .. math.floor(hrp.Position.Z) .. " (Raio: " .. NEARBY_DISTANCE .. ")",
                Duration = 4
            })
        else
            Fluent:Notify({
                Title = "SafeTP",
                Content = "❌ Erro ao salvar base - Character não encontrado",
                Duration = 3
            })
        end
    end
})

-- 💾 Botão para salvar local de fechar base
Tabs.Main:AddButton({
    Title = "💾 Salvar Local de Fechar Base",
    Description = "Salva o CFrame atual para teleporte de fechamento da base",
    Callback = function()
        local _, hrp = getCharacterAndHRP()
        if hrp then
            savedCloseBaseCFrame = hrp.CFrame
            Fluent:Notify({
                Title = "SafeTP",
                Content = "✅ Local de 'Fechar Base' salvo com sucesso!",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "SafeTP",
                Content = "⚠️ HRP não encontrado!",
                Duration = 3
            })
        end
    end
})

-- 🗑️ Botão para limpar base salva
Tabs.Main:AddButton({
    Title = "🗑️ Limpar Bases Salvas",
    Description = "Remove todas as bases salvas da memória",
    Callback = function()
        savedBaseCFrame = nil
        savedCloseBaseCFrame = nil
        Fluent:Notify({
            Title = "SafeTP",
            Content = "🗑️ Todas as bases foram limpas da memória!",
            Duration = 2
        })
    end
})

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- 🚀 SAFETP - MOVIMENTO ALEATÓRIO
-- ═══════════════════════════════════════════════════════════════════════════════════════════
Tabs.Main:AddParagraph({
    Title = "🚀 SafeTP - Movimento Aleatório",
    Content = "Sistema de movimento aleatório para roubar bases de forma segura."
})

-- 🔄 Toggle principal
local MainToggle = Tabs.Main:AddToggle("SafeTPToggle", {
    Title = "🔄 Loop SafeTP",
    Description = "Ativar/Desativar o loop de movimento aleatório",
    Default = false
})

MainToggle:OnChanged(function(Value)
    enabled = Value
    
    if enabled then
        MainToggle:SetTitle("📡 Loop SafeTP")
        
        if currentTeleportTask then
            task.cancel(currentTeleportTask)
            currentTeleportTask = nil
        end
        
        SafeTPToBase()
        
        Fluent:Notify({
            Title = "SafeTP",
            Content = "🔄 Loop SafeTP Ativado! (Movimento Aleatório - Raio: " .. NEARBY_DISTANCE .. ", Vel: " .. SAFETP_SPEED .. ")",
            Duration = 2
        })
    else
        MainToggle:SetTitle("🔄 Loop SafeTP")
        
        if currentTeleportTask then
            task.cancel(currentTeleportTask)
            currentTeleportTask = nil
        end
        
        Fluent:Notify({
            Title = "SafeTP",
            Content = "🛑 Loop SafeTP Desativado!",
            Duration = 2
        })
    end
end)

-- 📏 Slider para configurar raio de movimento
local DistanceSlider = Tabs.Main:AddSlider("DistanceSlider", {
    Title = "📏 Raio de Movimento",
    Description = "Distância máxima para movimento aleatório do SafeTP",
    Default = NEARBY_DISTANCE,
    Min = 5,
    Max = 50,
    Rounding = 0,
    Callback = function(Value)
        NEARBY_DISTANCE = Value
        if savedBaseCFrame then
            Fluent:Notify({
                Title = "SafeTP",
                Content = "📏 Raio atualizado para: " .. Value,
                Duration = 2
            })
        end
    end
})

-- 🏃 Slider para velocidade do SafeTP
local SafeTPSpeedSlider = Tabs.Main:AddSlider("SafeTPSpeedSlider", {
    Title = "🏃 Velocidade SafeTP",
    Description = "Velocidade do movimento aleatório do SafeTP",
    Default = SAFETP_SPEED,
    Min = 10,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        SAFETP_SPEED = Value
        Fluent:Notify({
            Title = "SafeTP",
            Content = "🏃 Velocidade SafeTP: " .. Value,
            Duration = 2
        })
    end
})

-- 🎯 Botão de Execução Manual
Tabs.Main:AddButton({
    Title = "🚀 Teste SafeTP",
    Description = "Testar um movimento aleatório (não loop)",
    Callback = function()
        if not enabled and savedBaseCFrame then
            local character, hrp = getCharacterAndHRP()
            if character and hrp then
                local basePosition = savedBaseCFrame.Position
                local start = hrp.Position
                local targetPosition = getRandomNearbyPosition(basePosition)
                
                -- Movimento único de teste usando função genérica
                task.spawn(function()
                    local success = executeSmoothTeleport(start, targetPosition, StepAmountToTP, SAFETP_SPEED)
                    
                    if success then
                        Fluent:Notify({
                            Title = "SafeTP",
                            Content = "✅ Teste concluído! Movido para posição aleatória no raio de " .. NEARBY_DISTANCE .. " (Steps: " .. StepAmountToTP .. ", Vel: " .. SAFETP_SPEED .. ")",
                            Duration = 3
                        })
                    end
                end)
            end
        elseif enabled then
            Fluent:Notify({
                Title = "SafeTP",
                Content = "⚠️ Desative o loop primeiro!",
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "SafeTP",
                Content = "❌ Nenhuma base salva!",
                Duration = 2
            })
        end
    end
})

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- 📦 SISTEMA FECHAR BASE
-- ═══════════════════════════════════════════════════════════════════════════════════════════
Tabs.Main:AddParagraph({
    Title = "📦 Sistema Fechar Base",
    Content = "Sistema automático para fechar base baseado no número de rebirths."
})

-- 📦 Botão para teleportar para fechar base
Tabs.Main:AddButton({
    Title = "📦 Fechar Base (Teleportar)",
    Description = "Teleporta instantaneamente para o local salvo como Fechar Base",
    Callback = function()
        teleportToCloseBase()
    end
})

-- 🔄 Toggle para loop de fechar base
local CloseBaseToggle = Tabs.Main:AddToggle("CloseBaseLoopToggle", {
    Title = "🔄 Loop Fechar Base",
    Description = "Ativar/Desativar o loop automático para fechar base",
    Default = false
})

CloseBaseToggle:OnChanged(function(Value)
    closeBaseLoopEnabled = Value
    
    if closeBaseLoopEnabled then
        CloseBaseToggle:SetTitle("📡 Loop Fechar Base")
        
        if currentCloseBaseTask then
            task.cancel(currentCloseBaseTask)
            currentCloseBaseTask = nil
        end
        
        startCloseBaseLoop()
        
        local interval = getCloseBaseInterval()
        Fluent:Notify({
            Title = "SafeTP",
            Content = "🔄 Loop Fechar Base Ativado! Intervalo: " .. interval .. "s (Vel: " .. CLOSE_BASE_SPEED .. ")",
            Duration = 2
        })
    else
        CloseBaseToggle:SetTitle("🔄 Loop Fechar Base")
        
        if currentCloseBaseTask then
            task.cancel(currentCloseBaseTask)
            currentCloseBaseTask = nil
        end
        
        Fluent:Notify({
            Title = "SafeTP",
            Content = "🛑 Loop Fechar Base Desativado!",
            Duration = 2
        })
    end
end)

-- 🔢 Slider para número de rebirths
local RebirthSlider = Tabs.Main:AddSlider("RebirthSlider", {
    Title = "🔢 Número de Rebirths",
    Description = "Define o intervalo do Loop Fechar Base (1=60s, 2=70s...)",
    Default = rebirthNumber,
    Min = 1,
    Max = 9,
    Rounding = 0,
    Callback = function(Value)
        rebirthNumber = Value
        local interval = getCloseBaseInterval()
        Fluent:Notify({
            Title = "SafeTP",
            Content = "🔢 Rebirth: " .. Value .. " | Intervalo: " .. interval .. "s",
            Duration = 2
        })
    end
})

-- 🏃 Slider para velocidade do Loop Fechar Base
local CloseBaseSpeedSlider = Tabs.Main:AddSlider("CloseBaseSpeedSlider", {
    Title = "🏃 Velocidade Fechar Base",
    Description = "Velocidade do teleporte para fechar base (maior = mais rápido)",
    Default = CLOSE_BASE_SPEED,
    Min = 10,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        CLOSE_BASE_SPEED = Value
        Fluent:Notify({
            Title = "SafeTP",
            Content = "🏃 Velocidade Fechar Base: " .. Value,
            Duration = 2
        })
    end
})

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- ⚙️ CONFIGURAÇÕES AVANÇADAS
-- ═══════════════════════════════════════════════════════════════════════════════════════════
Tabs.Settings:AddParagraph({
    Title = "⚙️ Configurações de Teleporte",
    Content = "Ajuste os parâmetros técnicos do sistema de teleporte para melhor performance."
})

local StepsInput = Tabs.Settings:AddInput("StepsInput", {
    Title = "⚡ Steps do Teleporte",
    Description = "Quantidade de steps para o teleporte (afeta SafeTP e Fechar Base)",
    Default = tostring(StepAmountToTP),
    Placeholder = "Digite a quantidade de steps (100-10000)",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local numValue = tonumber(Value)
        if numValue and numValue >= 100 and numValue <= 10000 then
            StepAmountToTP = numValue
            Fluent:Notify({
                Title = "SafeTP",
                Content = "✅ Steps atualizado para: " .. numValue .. " (afeta ambos os sistemas)",
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "SafeTP",
                Content = "❌ Valor inválido! Use entre 100 e 10000",
                Duration = 3
            })
        end
    end
})

local TimeSlider = Tabs.Settings:AddSlider("TimeSlider", {
    Title = "⏱️ Tempo Base",
    Description = "Tempo base do teleporte (substituído pelo cálculo de velocidade)",
    Default = totalTime,
    Min = 0.1,
    Max = 3.0,
    Rounding = 1,
    Callback = function(Value)
        totalTime = Value
        Fluent:Notify({
            Title = "SafeTP",
            Content = "⏱️ Tempo base atualizado para: " .. Value .. "s (velocidade tem prioridade)",
            Duration = 2
        })
    end
})

-- ℹ️ Informações
Tabs.Info:AddParagraph({
    Title = "🔄 SafeTP Hub - Movimento Aleatório",
    Content = "Script de teleporte com movimento aleatório baseado em distância.\n\n" ..
              "• Movimento aleatório dentro do raio configurado\n" ..
              "• Pausa aleatória entre 0.1s e 0.5s\n" ..
              "• Velocidades independentes para SafeTP e Fechar Base\n" ..
              "• Estratégia anti-detecção avançada\n" ..
              "• Sistema de base como centro do movimento\n" ..
              "• Loop automático para fechar base baseado em rebirths\n" ..
              "• Ambos os sistemas usam o mesmo valor de Steps\n" ..
              "• Loop Fechar Base reseta o personagem automaticamente"
})

Tabs.Info:AddParagraph({
    Title = "📖 Como Usar",
    Content = "1. Vá até a base que deseja roubar\n" ..
              "2. Clique em 'Copiar Base para Roubar' para definir o centro\n" ..
              "3. Salve o local de 'Fechar Base' na posição desejada\n" ..
              "4. Ajuste o 'Raio de Movimento' e 'Número de Rebirths'\n" ..
              "5. Configure as velocidades independentes para SafeTP e Fechar Base\n" ..
              "6. Configure os 'Steps do Teleporte'\n" ..
              "7. Ative o 'Loop SafeTP' para movimento aleatório\n" ..
              "8. Ative o 'Loop Fechar Base' para fechamento automático\n" ..
              "9. Use o botão de teste para verificar movimentos\n" ..
              "10. O sistema resetará automaticamente após fechar a base"
})

Tabs.Info:AddParagraph({
    Title = "⚙️ Sistema de Rebirths",
    Content = "• Rebirth 1: Fecha base a cada 60 segundos\n" ..
              "• Rebirth 2: Fecha base a cada 70 segundos\n" ..
              "• Rebirth 3: Fecha base a cada 80 segundos\n" ..
              "• Rebirth 4: Fecha base a cada 90 segundos\n" ..
              "• E assim por diante até Rebirth 9 (140s)\n" ..
              "• Usa o mesmo sistema de movimento suave do SafeTP\n" ..
              "• Velocidade de teleporte configurável independentemente\n" ..
              "• Reseta o personagem automaticamente após cada fechamento"
})

Tabs.Info:AddParagraph({
    Title = "⚙️ Funcionamento Técnico - ATUALIZADO",
    Content = "• Velocidades independentes: SafeTP e Fechar Base têm sliders separados\n" ..
              "• Cálculo de duração baseado em: distância ÷ velocidade\n" ..
              "• Função genérica executeSmoothTeleport() com parâmetro de velocidade\n" ..
              "• SafeTP usa SAFETP_SPEED, Fechar Base usa CLOSE_BASE_SPEED\n" ..
              "• Steps do Teleporte afeta a suavidade de ambos os sistemas\n" ..
              "• Movimento natural com variações verticais\n" ..
              "• Base salva serve como centro do movimento circular\n" ..
              "• Sistema de reset automático após fechar base\n" ..
              "• Notificações mostram as velocidades atuais"
})

-- 🔄 Reconectar quando character respawnar
LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("HumanoidRootPart")
    Fluent:Notify({
        Title = "SafeTP",
        Content = "🔄 Character respawnado, SafeTP pronto!",
        Duration = 2
    })
end)

-- 💾 Gerenciamento de Configurações
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("SafeTPConfig")
SaveManager:SetFolder("SafeTPConfig/saves")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

SaveManager:LoadAutoloadConfig()
