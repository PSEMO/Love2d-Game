local backgroundImage = nil
local CharX = 200
local CharY = 200

local DefaultSpeed = 80
local CurrentSpeed = 80
local DashMultiplier = 8

local Vertical = 0
local Horizontal = 0

local Bullets = {}
local BulletSpeed = 300

local SeedCreatingValue = os.time()

local Enemies = {}
local CurrentEnemyCount = 1
local EnemyCount = 10

local Particles = {}


---------
local isDashing = false
local canDash = true
local DashingCoolDownStopwatch = 0
local DashingDurationStopwatch = 0
local DashingDuration = 0.15
local DashingCoolDown = 1.4

local DashUISize = 200
local DefaultDashUISize = 200

local DashUIColorR = 0
local DashUIColorG = 255
---------

---------
local canShoot = true
local ShootingCoolDownStopwatch = 0
local ShootingCoolDown = 0.65

local ShootUISize = 200
local DefaultShootUISize = 200

local ShootUIColorR = 0
local ShootUIColorG = 255
---------

function love.load()

    love.mouse.setVisible(false)
    backgroundImage = love.graphics.newImage("Test.png")

-- Creates "EnemyCount" ammount of random enemy information and sorts them into a table
    while CurrentEnemyCount <= EnemyCount
    do
        local Enemy = 
        {
            PosX = RandNumber() * 800, PosY = RandNumber() * 600, Radius = (RandNumber() * 40) + 10, ColorR = (RandNumber() * 100) + 155, 
            ColorG = (RandNumber() * 100) + 155, ColorB = (RandNumber() * 100) + 155, label = "Enemy", index = CurrentEnemyCount
        }

        table.insert(Enemies,Enemy)

        CurrentEnemyCount = CurrentEnemyCount + 1

        --Sorts player biggest to smallest so that smaller objects are drawen last
        --Therefor they appear on top of bigger ones
        if CurrentEnemyCount > EnemyCount 
        then
            table.sort (Enemies, function (k1, k2) return k1.Radius > k2.Radius end )
        end
    end
end

function love.draw()

-- Background
    love.graphics.push()
    love.graphics.setColor(0, 0, 1)
    love.graphics.draw(backgroundImage, 0, 0)
    love.graphics.pop()

-- Draws Enemies using predetermined information
    for i,CurrentEnemy in pairs(Enemies)
    do
        love.graphics.push()
        love.graphics.setColor(love.math.colorFromBytes(CurrentEnemy.ColorR, CurrentEnemy.ColorG, CurrentEnemy.ColorB))
        love.graphics.translate(CurrentEnemy.PosX, CurrentEnemy.PosY)
        love.graphics.circle("fill", 0, 0, CurrentEnemy.Radius)
        love.graphics.pop()
    end

-- Draws Bullets using information that is determined on shoot
    for i,CurrentBullet in pairs(Bullets)
    do
        love.graphics.push()
        love.graphics.setColor(1, 0, 0)
        love.graphics.translate(CurrentBullet.PosX, CurrentBullet.PosY)
        love.graphics.circle("fill", 0, 0, CurrentBullet.Radius)
        love.graphics.pop()
    end

-- Draws Particles using information that is determined on createCorpse
    for pIndex, Particle in pairs(Particles)
    do
        love.graphics.push()
        love.graphics.setColor(love.math.colorFromBytes(Particle.ColorR, Particle.ColorG, Particle.ColorB))
        love.graphics.translate(Particle.PosX, Particle.PosY)
        love.graphics.circle("fill", 0, 0, Particle.Radius)
        love.graphics.pop()
    end

-- Character
    love.graphics.push()
    love.graphics.setColor(love.math.colorFromBytes(255, 255, 255))

    love.graphics.translate(CharX, CharY)
    local radian = CalculateRadian(CharX, CharY, love.mouse.getX(), love.mouse.getY())
    love.graphics.rotate(radian)

    love.graphics.rectangle("fill", -5, -5, 10, 10) -- Player
    love.graphics.rectangle("fill", 0, -5/2, 10, 5) -- Barrel
    love.graphics.pop()

-- Dash UI Element --Bunlari translate ile daha temiz kodla TODO****CorpseAngle***********************
    love.graphics.push()
    love.graphics.setColor(love.math.colorFromBytes(DashUIColorR, DashUIColorG, 0))
    love.graphics.rectangle("fill", 10, 300 - (DashUISize / 2), 15, DashUISize, 5, 5)
    love.graphics.pop()

-- Shoot UI Element
    love.graphics.push()
    love.graphics.setColor(love.math.colorFromBytes(ShootUIColorR, ShootUIColorG, 0))
    love.graphics.rectangle("fill", 775, 300 - (ShootUISize / 2), 15, ShootUISize, 5, 5)
    love.graphics.pop()

-- Cursor
    -- Mid Cursor
    love.graphics.push()
    love.graphics.setColor(1, 1, 1)
    love.graphics.translate(love.mouse.getX(), love.mouse.getY())
    love.graphics.circle("fill", 0, 0, 4)
    -- Inner Cursor
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", 0, 0, 2)
    -- Outer Cursor
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", 0, 0, 5)
    love.graphics.pop()

end

function love.update(dt)

--Particle Updating
    for pIndex, Particle in pairs(Particles)
    do
        if Particle.timer > Particle.dissappearTime then

            table.remove(Particles, pIndex)
            Particle = nil
        else
            Particle.PosX = Particle.PosX + (Particle.directionX * Particle.speed * (1 - (Particle.timer / Particle.dissappearTime))) * dt
            Particle.PosY = Particle.PosY + (Particle.directionY * Particle.speed * (1 - (Particle.timer / Particle.dissappearTime))) * dt
            Particle.timer = Particle.timer + dt
        end
    end
--Reloading & Reaload UI managing
    if canShoot
    then
        if love.mouse.isDown(1) then
            canShoot = false

            ShootUIColorR = 255
            ShootUIColorG = 0

            ShootUISize = 0

            Shoot()
        end
    else
        ShootUISize = (ShootingCoolDownStopwatch / ShootingCoolDown) * DefaultShootUISize

        ShootingCoolDownStopwatch = ShootingCoolDownStopwatch + dt
        if ShootingCoolDownStopwatch > ShootingCoolDown
        then
            canShoot = true
            ShootingCoolDownStopwatch = 0

            ShootUIColorR = 0
            ShootUIColorG = 255

            ShootUISize = DefaultShootUISize
        end
    end

--Bullet Updating
    for i,CurrentBullet in pairs(Bullets)
    do
        if CurrentBullet.Timer > 3 then
            table.remove(Bullets, i)
            CurrentBullet = nil
        else
            CurrentBullet.Timer = CurrentBullet.Timer + dt
            CurrentBullet.PosX = CurrentBullet.PosX + (CurrentBullet.directionX * dt * BulletSpeed)
            CurrentBullet.PosY = CurrentBullet.PosY + (CurrentBullet.directionY * dt * BulletSpeed)
        end
    end
    
--Basic dashing and regranting controlls & Dash UI managing.
    if canDash then
        if love.keyboard.isDown("lshift") and ((not(Vertical == 0)) or (not(Horizontal == 0))) then
            canDash = false
            isDashing = true
        end
    else
        DashUISize = DefaultDashUISize * (1 - (DashingCoolDown - DashingCoolDownStopwatch) / DashingCoolDown)

        DashingCoolDownStopwatch = DashingCoolDownStopwatch + dt
        if DashingCoolDownStopwatch > DashingCoolDown
        then
            DashingCoolDownStopwatch = 0
            canDash = true

            DashUISize = DefaultDashUISize

            DashUIColorR = 0
            DashUIColorG = 255
        end
    end

--While not dashing; checks inputs and changes position by changing "vertical" and "horizontal" values.
    if not isDashing
    then
        if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
            if (not love.keyboard.isDown("right") and not love.keyboard.isDown("d")) then
                Vertical = -1
            else
                Vertical = 0
            end
        elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
            Vertical = 1
        else
            Vertical = 0
        end
        
        if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
            if (not love.keyboard.isDown("down") and not love.keyboard.isDown("s")) then
                Horizontal = -1
            else
                Horizontal = 0
            end
        elseif love.keyboard.isDown("down") or love.keyboard.isDown("s") then
            Horizontal = 1
        else
            Horizontal = 0
        end
    else
        
--If it's dashing we just lock movement, boost our current speed, and check if the duration is longer than it is supposed to be w/ a stopwatch.
        if DashingDurationStopwatch > DashingDuration
        then
            CurrentSpeed = DefaultSpeed
            DashingDurationStopwatch = 0
            isDashing = false

            DashUIColorR = 255
            DashUIColorG = 0

            DashUISize = 0
        else
            DashingDurationStopwatch = DashingDurationStopwatch + dt
            CurrentSpeed = DefaultSpeed * DashMultiplier

            DashUISize = DefaultDashUISize * (DashingDuration - DashingDurationStopwatch) / DashingDuration
        end
    end

--This causes our position to change.
    CharX = CharX + CurrentSpeed * dt * Vertical
    CharY = CharY + CurrentSpeed * dt * Horizontal
--
    CheckCollisions()
end

--Collisions
function CheckCollisions()

    for a,CurrBt in pairs(Bullets)
    do
        if(not (CurrBt == nil)) then
            for b,CurrEy in pairs(Enemies)
            do
                if(not (CurrBt == nil)) then
                    if(CalculateDifference(CurrBt.PosX, CurrBt.PosY, CurrEy.PosX, CurrEy.PosY) < (CurrBt.Radius + CurrEy.Radius))
                    then
                        CreateCorpse(CurrBt, CurrEy)

                        table.remove(Bullets, a)
                        CurrBt = nil
                    
                        table.remove(Enemies, b)
                        CurrEy = nil
                    end
                end
            end
        end
    end
end

function CreateCorpse(Bullet, Corpse)

--For Corpse
    local CorpseParticleCount = 0

    while CorpseParticleCount <= Corpse.Radius
    do
        local signX = 1
        if RandNumber() < 0.5 then
            signX = -1
        end
        local signY = 1
        if RandNumber() < 0.5 then
            signY = -1
        end

        local NewParticle = 
        {
            PosX = Corpse.PosX + ((RandNumber() * Corpse.Radius * 0.666) * signX), PosY = Corpse.PosY  + ((RandNumber() * Corpse.Radius / 2) * signY),
            Radius = 2, ColorR = Corpse.ColorR, ColorG = Corpse.ColorG, ColorB = Corpse.ColorB,
            label = "Particle", timer = 0, speed = (RandNumber() * BulletSpeed * 0.5) + 150, dissappearTime = (RandNumber() * 3),
            directionX = 0, directionY = 0
        }
        
        print("Bullet: " .. Bullet.PosX .. ", " .. Bullet.PosY)
        print("NewParticle: " .. NewParticle.PosX .. ", " .. NewParticle.PosY)

        dir = CalculateDirection(Bullet.PosX, Bullet.PosY, NewParticle.PosX, NewParticle.PosY)
        NewParticle.directionX = dir.X
        NewParticle.directionY = dir.Y

        table.insert(Particles, NewParticle)
        CorpseParticleCount = CorpseParticleCount + 1
    end
end

--VectorDifference
function CalculateDifference(x1, y1, x2, y2)

    local difX = x2 - x1
    local difY = y2 - y1
    
    return math.sqrt(difX * difX + difY * difY)
end

--Converts degree to radian value
function AngleToRaidan(value)
    return value * 0.01745329251 -- π / 180°
end

--Converts degree to radian value
function RaidanToAngle(value)
    return value * 57.2957795131 -- 180° / π
end

--Spawns a bullet to shoot
function Shoot()
    
    Direction = CalculateDirection(CharX, CharY, love.mouse.getX(), love.mouse.getY())

    local NewBullet = 
    {
        PosX = CharX, PosY = CharY, Radius = 4, label = "Bullet",
        directionX = Direction.X, directionY = Direction.Y, Timer = 0
    }

    table.insert(Bullets, NewBullet)
end

--Calculates radian in between via magic.
function CalculateRadian(x1, y1, x2, y2)

    return math.atan2(y2 - y1, x2 - x1)
end

--Calculates position to be with magnitude of 1
function PosFromRadian(a)

    dir = { X = math.sin(a), Y = math.cos(a) }
    return dir
end

--Calculates the vector2 values between two positions
function CalculateDirection(x1, y1, x2, y2)

    local DiffX = x2 - x1
    local DiffY = y2 - y1

    local Magnitude = math.sqrt(DiffX * DiffX + DiffY * DiffY)

    local dirX = DiffX / Magnitude
    local dirY = DiffY / Magnitude

    dir = { X = dirX, Y = dirY}

    return dir
end

function RandNumber()

    SeedCreatingValue = SeedCreatingValue + 1
    math.randomseed(SeedCreatingValue)

    return math.random()
end