-- miner.lua - Túnel 3x3 com retorno

local args = {...}
local depth = tonumber(args[1])

if not depth then
    print("Uso: miner <profundidade>")
    return
end

-- Checa combustível
local function checkFuel()
    if turtle.getFuelLevel() == 0 then
        print("Sem combustível! Coloque carvão no slot 1.")
        if turtle.getItemCount(1) > 0 then
            turtle.select(1)
            turtle.refuel()
        end
    end
end

local function dig3x3()
    -- Centro
    turtle.dig()
    turtle.forward()

    -- Parte de cima
    turtle.digUp()

    -- Lado direito
    turtle.turnRight()
    turtle.dig()
    turtle.forward()
    turtle.digUp()
    turtle.turnLeft()

    -- Volta para o centro
    turtle.back()

    -- Lado esquerdo
    turtle.turnLeft()
    turtle.dig()
    turtle.forward()
    turtle.digUp()
    turtle.turnRight()

    -- Volta para o centro
    turtle.back()
end

-- Começa a mineração
print("Minerando "..depth.." blocos de profundidade...")

for i = 1, depth do
    checkFuel()
    dig3x3()
end

-- Voltar ao ponto inicial
print("Voltando...")
turtle.turnLeft()
turtle.turnLeft()

for i = 1, depth do
    turtle.forward()
end

turtle.turnLeft()
turtle.turnLeft()

print("Finalizado!")
