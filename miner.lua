-- ============================================
-- MINER.LUA - Sistema Completo de Mineração
-- ComputerCraft Mining Script
-- ============================================

local args = {...}
local depth = tonumber(args[1]) or 64
local width = tonumber(args[2]) or 1

-- ============================================
-- CONFIGURAÇÕES
-- ============================================

-- Minérios valiosos (não descartar)
local VALUABLE_ORES = {
    ["minecraft:coal_ore"] = true,
    ["minecraft:iron_ore"] = true,
    ["minecraft:gold_ore"] = true,
    ["minecraft:diamond_ore"] = true,
    ["minecraft:emerald_ore"] = true,
    ["minecraft:lapis_ore"] = true,
    ["minecraft:redstone_ore"] = true,
    ["minecraft:copper_ore"] = true,
    ["minecraft:deepslate_coal_ore"] = true,
    ["minecraft:deepslate_iron_ore"] = true,
    ["minecraft:deepslate_gold_ore"] = true,
    ["minecraft:deepslate_diamond_ore"] = true,
    ["minecraft:deepslate_emerald_ore"] = true,
    ["minecraft:deepslate_lapis_ore"] = true,
    ["minecraft:deepslate_redstone_ore"] = true,
    ["minecraft:deepslate_copper_ore"] = true,
    ["minecraft:nether_quartz_ore"] = true,
    ["minecraft:nether_gold_ore"] = true,
    ["minecraft:ancient_debris"] = true,
}

-- Itens para manter (não descartar)
local KEEP_ITEMS = {
    ["minecraft:coal"] = true,
    ["minecraft:iron_ore"] = true,
    ["minecraft:raw_iron"] = true,
    ["minecraft:gold_ore"] = true,
    ["minecraft:raw_gold"] = true,
    ["minecraft:diamond"] = true,
    ["minecraft:emerald"] = true,
    ["minecraft:lapis_lazuli"] = true,
    ["minecraft:redstone"] = true,
    ["minecraft:copper_ore"] = true,
    ["minecraft:raw_copper"] = true,
    ["minecraft:quartz"] = true,
    ["minecraft:gold_nugget"] = true,
    ["minecraft:ancient_debris"] = true,
    ["minecraft:netherite_scrap"] = true,
}

-- Slots reservados
local FUEL_SLOT = 1
local CHEST_SLOT = 2
local TORCH_SLOT = 3
local FIRST_MINING_SLOT = 4

-- Configurações
local MIN_FUEL_LEVEL = 100
local TORCH_INTERVAL = 8
local INVENTORY_FULL_THRESHOLD = 14

-- ============================================
-- VARIÁVEIS GLOBAIS
-- ============================================

local blocksMinedCount = 0
local oresFoundCount = 0
local currentDepth = 0
local torchCounter = 0
local homeChest = nil

-- ============================================
-- FUNÇÕES UTILITÁRIAS
-- ============================================

local function log(message)
    print("[MINER] " .. message)
end

-- Verifica e reabastece combustível
local function checkFuel()
    if turtle.getFuelLevel() < MIN_FUEL_LEVEL then
        log("Combustível baixo: " .. turtle.getFuelLevel())
        turtle.select(FUEL_SLOT)
        if turtle.getItemCount(FUEL_SLOT) > 0 then
            turtle.refuel(1)
            log("Reabastecido! Nível: " .. turtle.getFuelLevel())
        else
            log("AVISO: Sem combustível no slot " .. FUEL_SLOT)
        end
    end
end

-- Verifica se um item é valioso
local function isValuableItem(slot)
    local item = turtle.getItemDetail(slot)
    if not item then return false end
    
    return VALUABLE_ORES[item.name] or KEEP_ITEMS[item.name]
end

-- Descarta itens não valiosos
local function discardJunk()
    local discarded = 0
    for slot = FIRST_MINING_SLOT, 16 do
        turtle.select(slot)
        if turtle.getItemCount(slot) > 0 and not isValuableItem(slot) then
            turtle.drop()
            discarded = discarded + 1
        end
    end
    if discarded > 0 then
        log("Descartados " .. discarded .. " tipos de itens inúteis")
    end
    turtle.select(FIRST_MINING_SLOT)
end

-- Verifica se o inventário está cheio
local function isInventoryFull()
    local emptySlots = 0
    for slot = FIRST_MINING_SLOT, 16 do
        if turtle.getItemCount(slot) == 0 then
            emptySlots = emptySlots + 1
        end
    end
    return emptySlots <= 2
end

-- Compacta inventário
local function compactInventory()
    for slot = FIRST_MINING_SLOT, 16 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            for targetSlot = FIRST_MINING_SLOT, slot - 1 do
                if turtle.getItemCount(targetSlot) > 0 then
                    turtle.transferTo(targetSlot)
                    if turtle.getItemCount(slot) == 0 then
                        break
                    end
                end
            end
        end
    end
    turtle.select(FIRST_MINING_SLOT)
end

-- Descarrega itens em um baú
local function unloadToChest()
    log("Descarregando itens no baú...")
    for slot = FIRST_MINING_SLOT, 16 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            turtle.drop()
        end
    end
    turtle.select(FIRST_MINING_SLOT)
    log("Itens descarregados!")
end

-- ============================================
-- FUNÇÕES DE MOVIMENTO
-- ============================================

local function safeDigForward()
    local attempts = 0
    while turtle.detect() and attempts < 10 do
        turtle.dig()
        sleep(0.4)
        attempts = attempts + 1
    end
end

local function safeDigUp()
    local attempts = 0
    while turtle.detectUp() and attempts < 10 do
        turtle.digUp()
        sleep(0.4)
        attempts = attempts + 1
    end
end

local function safeDigDown()
    local attempts = 0
    while turtle.detectDown() and attempts < 10 do
        turtle.digDown()
        sleep(0.4)
        attempts = attempts + 1
    end
end

local function forward()
    checkFuel()
    safeDigForward()
    if turtle.forward() then
        blocksMinedCount = blocksMinedCount + 1
        return true
    end
    return false
end

local function up()
    checkFuel()
    safeDigUp()
    return turtle.up()
end

local function down()
    checkFuel()
    safeDigDown()
    return turtle.down()
end

local function turnRight()
    turtle.turnRight()
end

local function turnLeft()
    turtle.turnLeft()
end

local function turnAround()
    turnRight()
    turnRight()
end

-- ============================================
-- FUNÇÕES DE MINERAÇÃO
-- ============================================

-- Detecta minérios ao redor
local function detectOres()
    local oresFound = false
    
    -- Frente
    if turtle.inspect then
        local success, data = turtle.inspect()
        if success and data and data.name and VALUABLE_ORES[data.name] then
            oresFound = true
            oresFoundCount = oresFoundCount + 1
        end
    end
    
    -- Cima
    if turtle.inspectUp then
        local success, data = turtle.inspectUp()
        if success and data and data.name and VALUABLE_ORES[data.name] then
            oresFound = true
            oresFoundCount = oresFoundCount + 1
        end
    end
    
    -- Baixo
    if turtle.inspectDown then
        local success, data = turtle.inspectDown()
        if success and data and data.name and VALUABLE_ORES[data.name] then
            oresFound = true
            oresFoundCount = oresFoundCount + 1
        end
    end
    
    return oresFound
end

-- Coloca tocha se necessário
local function placeTorch()
    torchCounter = torchCounter + 1
    if torchCounter >= TORCH_INTERVAL then
        turtle.select(TORCH_SLOT)
        if turtle.getItemCount(TORCH_SLOT) > 0 then
            turnAround()
            turtle.place()
            turnAround()
            log("Tocha colocada!")
        end
        turtle.select(FIRST_MINING_SLOT)
        torchCounter = 0
    end
end

-- Minera um túnel 3x3
local function dig3x3()
    -- Centro (já está na posição)
    detectOres()
    safeDigForward()
    safeDigUp()
    safeDigDown()
    
    if not forward() then
        return false
    end
    
    currentDepth = currentDepth + 1
    
    -- Cima
    detectOres()
    up()
    
    -- Direita superior
    turnRight()
    detectOres()
    safeDigForward()
    turnLeft()
    
    -- Esquerda superior
    turnLeft()
    detectOres()
    safeDigForward()
    turnRight()
    
    -- Volta para baixo
    down()
    
    -- Direita meio
    turnRight()
    detectOres()
    safeDigForward()
    turnLeft()
    
    -- Esquerda meio
    turnLeft()
    detectOres()
    safeDigForward()
    turnRight()
    
    -- Baixo
    detectOres()
    down()
    
    -- Direita inferior
    turnRight()
    detectOres()
    safeDigForward()
    turnLeft()
    
    -- Esquerda inferior
    turnLeft()
    detectOres()
    safeDigForward()
    turnRight()
    
    -- Volta para o centro
    up()
    
    -- Coloca tocha
    placeTorch()
    
    -- Gerenciamento de inventário
    if isInventoryFull() then
        compactInventory()
        discardJunk()
    end
    
    return true
end

-- Retorna para a base
local function returnToBase()
    log("Retornando para a base...")
    turnAround()
    
    for i = 1, currentDepth do
        if not turtle.forward() then
            safeDigForward()
            turtle.forward()
        end
    end
    
    turnAround()
    log("De volta à base!")
end

-- ============================================
-- FUNÇÃO PRINCIPAL
-- ============================================

local function main()
    log("=================================")
    log("Sistema de Mineração Automática")
    log("=================================")
    log("Profundidade: " .. depth .. " blocos")
    log("Largura: " .. width .. " túneis")
    log("=================================")
    
    -- Verifica se há baú embaixo
    if turtle.inspectDown then
        local success, data = turtle.inspectDown()
        if success and data and data.name and string.find(data.name, "chest") then
            homeChest = true
            log("Baú detectado! Retorno automático ativado.")
        end
    end
    
    -- Inicia mineração
    for tunnel = 1, width do
        log("Iniciando túnel " .. tunnel .. " de " .. width)
        currentDepth = 0
        torchCounter = 0
        
        for i = 1, depth do
            if not dig3x3() then
                log("Erro ao minerar. Abortando...")
                break
            end
            
            -- Verifica inventário cheio
            if isInventoryFull() then
                if homeChest then
                    returnToBase()
                    down()
                    unloadToChest()
                    up()
                    
                    -- Volta para a posição
                    for j = 1, currentDepth do
                        forward()
                    end
                else
                    log("Inventário cheio! Descartando itens inúteis...")
                    discardJunk()
                end
            end
            
            if i % 10 == 0 then
                log("Progresso: " .. i .. "/" .. depth .. " blocos")
            end
        end
        
        -- Retorna
        returnToBase()
        
        -- Prepara próximo túnel
        if tunnel < width then
            turnRight()
            for i = 1, 4 do
                forward()
            end
            turnLeft()
        end
    end
    
    -- Retorna para descarregar
    if homeChest then
        down()
        unloadToChest()
        up()
    end
    
    -- Estatísticas finais
    log("=================================")
    log("MINERAÇÃO CONCLUÍDA!")
    log("=================================")
    log("Blocos minerados: " .. blocksMinedCount)
    log("Minérios encontrados: " .. oresFoundCount)
    log("Combustível restante: " .. turtle.getFuelLevel())
    log("=================================")
end

-- Executa o programa
main()
