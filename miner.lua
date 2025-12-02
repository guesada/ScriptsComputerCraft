-- ============================================
-- MINER.LUA - Sistema Completo de Mineração
-- ComputerCraft Mining Script
-- API: https://computercraft.info/wiki/Turtle_(API)
-- ============================================

-- Verifica se está rodando em uma turtle
if not turtle then
    print("ERRO: Este programa deve ser executado em uma Turtle!")
    return
end

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
local TORCH_SLOT = 2
local FIRST_MINING_SLOT = 3

-- Configurações
local MIN_FUEL_LEVEL = 100
local TORCH_INTERVAL = 8

-- ============================================
-- VARIÁVEIS GLOBAIS
-- ============================================

local blocksMinedCount = 0
local currentDepth = 0
local torchCounter = 0

-- ============================================
-- FUNÇÕES UTILITÁRIAS
-- ============================================

local function log(message)
    print("[MINER] " .. message)
end

-- Verifica e reabastece combustível
local function checkFuel()
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" then
        return true
    end
    
    if fuelLevel < MIN_FUEL_LEVEL then
        log("Combustivel baixo: " .. fuelLevel)
        turtle.select(FUEL_SLOT)
        if turtle.getItemCount(FUEL_SLOT) > 0 then
            turtle.refuel(1)
            log("Reabastecido! Nivel: " .. turtle.getFuelLevel())
            return true
        else
            log("AVISO: Sem combustivel no slot " .. FUEL_SLOT)
            return false
        end
    end
    return true
end

-- Verifica se um item é valioso
local function isValuableItem(slot)
    local item = turtle.getItemDetail(slot)
    if not item then 
        return false 
    end
    
    return VALUABLE_ORES[item.name] or KEEP_ITEMS[item.name]
end

-- Descarta itens não valiosos
local function discardJunk()
    local discarded = 0
    for slot = FIRST_MINING_SLOT, 16 do
        if turtle.getItemCount(slot) > 0 and not isValuableItem(slot) then
            turtle.select(slot)
            turtle.drop()
            discarded = discarded + 1
        end
    end
    if discarded > 0 then
        log("Descartados " .. discarded .. " tipos de itens")
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
    return emptySlots <= 1
end

-- ============================================
-- FUNÇÕES DE MOVIMENTO
-- ============================================

local function safeDigForward()
    local attempts = 0
    while attempts < 10 do
        if turtle.detect() then
            if not turtle.dig() then
                return false
            end
            sleep(0.5)
            attempts = attempts + 1
        else
            return true
        end
    end
    return true
end

local function safeDigUp()
    local attempts = 0
    while attempts < 10 do
        if turtle.detectUp() then
            if not turtle.digUp() then
                return false
            end
            sleep(0.5)
            attempts = attempts + 1
        else
            return true
        end
    end
    return true
end

local function safeDigDown()
    local attempts = 0
    while attempts < 10 do
        if turtle.detectDown() then
            if not turtle.digDown() then
                return false
            end
            sleep(0.5)
            attempts = attempts + 1
        else
            return true
        end
    end
    return true
end

local function forward()
    if not checkFuel() then
        return false
    end
    
    safeDigForward()
    
    if turtle.forward() then
        blocksMinedCount = blocksMinedCount + 1
        return true
    end
    
    return false
end

local function up()
    if not checkFuel() then
        return false
    end
    
    safeDigUp()
    return turtle.up()
end

local function down()
    if not checkFuel() then
        return false
    end
    
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
    -- Minera frente, cima e baixo
    safeDigForward()
    safeDigUp()
    safeDigDown()
    
    if not forward() then
        return false
    end
    
    currentDepth = currentDepth + 1
    
    -- Minera cima
    safeDigUp()
    up()
    
    -- Minera direita superior
    turnRight()
    safeDigForward()
    turnLeft()
    
    -- Minera esquerda superior
    turnLeft()
    safeDigForward()
    turnRight()
    
    -- Volta para o meio
    down()
    
    -- Minera direita meio
    turnRight()
    safeDigForward()
    turnLeft()
    
    -- Minera esquerda meio
    turnLeft()
    safeDigForward()
    turnRight()
    
    -- Minera baixo
    safeDigDown()
    down()
    
    -- Minera direita inferior
    turnRight()
    safeDigForward()
    turnLeft()
    
    -- Minera esquerda inferior
    turnLeft()
    safeDigForward()
    turnRight()
    
    -- Volta para o centro
    up()
    
    -- Coloca tocha
    placeTorch()
    
    -- Gerenciamento de inventário
    if isInventoryFull() then
        log("Inventario cheio! Descartando itens...")
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
    log("De volta a base!")
end

-- ============================================
-- FUNÇÃO PRINCIPAL
-- ============================================

local function main()
    log("=================================")
    log("Sistema de Mineracao Automatica")
    log("=================================")
    log("Profundidade: " .. depth .. " blocos")
    log("Largura: " .. width .. " tuneis")
    log("=================================")
    log("Setup:")
    log("  Slot 1: Combustivel (carvao)")
    log("  Slot 2: Tochas")
    log("  Slots 3-16: Mineracao")
    log("=================================")
    
    -- Verifica combustível inicial
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel ~= "unlimited" and fuelLevel < 100 then
        log("ERRO: Combustivel insuficiente!")
        log("Coloque carvao no slot 1")
        return
    end
    
    sleep(2)
    
    -- Inicia mineração
    for tunnel = 1, width do
        log("Iniciando tunel " .. tunnel .. " de " .. width)
        currentDepth = 0
        torchCounter = 0
        
        for i = 1, depth do
            if not dig3x3() then
                log("Erro ao minerar. Abortando...")
                break
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
    
    -- Estatísticas finais
    log("=================================")
    log("MINERACAO CONCLUIDA!")
    log("=================================")
    log("Blocos minerados: " .. blocksMinedCount)
    
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel ~= "unlimited" then
        log("Combustivel restante: " .. fuelLevel)
    end
    
    log("=================================")
end

-- Executa o programa
main()
