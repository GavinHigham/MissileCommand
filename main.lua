--[[
For missile command, we need to keep track of:
- remaining cities
- missiles
	- location
	- destination
	- velocity, maybe. Saves excess computation.
- explosions
	- duration
	- size
- missile cooldown
	- enemy incoming rate
	- player fire rate
- "level"

- every frame we need to:
	for each missile, check for containment against all explosions
- for each city, check for containment against all explosions
- check if we're out of cities

later I need to add some kind of missile/explosion pools for memory management
]]

cities = {}
missiles = {}
explosions = {}
cooldownMax = 4.0
cooldown = 0.0
explosionGrowthRate = 1.0
maxExplosionRadius = 110.0
missileSpread = 20

function love.load()

end

function normalized(x, y)
	local magnitude = math.sqrt(x*x + y*y)
	if magnitude ~= 0.0 then
		x = x / magnitude
		y = y / magnitude
	end
	return x, y
end

function newExplosion(posX, posY)
	table.insert(explosions, {posX = posX, posY = posY, r = 0.0})
end

function isInExplosion(missile)
	local isInExplosion = false
	for i,explosion in pairs(explosions) do
		local dx = missile.posX - explosion.posX
		local dy = missile.posY - explosion.posY
		if (dx*dx + dy*dy) < (explosion.r*explosion.r) then
			isInExplosion = true
		end
	end
	return isInExplosion
end

function newMissile(posX, posY, targetX, targetY, speed)
	local vx = targetX - posX
	local vy = targetY - posY
	local distance = vx*vx + vy*vy
	if distance ~= 0 then distance = math.sqrt(distance) end
	vx, vy = normalized(vx, vy)
	local newMissile = {
		startX = posX,
		startY = posY,
		targetDistance = distance,
		posX = posX,
		posY = posY,
		vx = vx*speed,
		vy = vy*speed,
		isAlive = true
	}
	table.insert(missiles, newMissile)
end

function newEnemyMissile()
	local posX = math.random(0.0, love.graphics.getWidth())
	local posY = 0.0
	local targetX = math.random(0, love.graphics.getWidth())
	local targetY = love.graphics.getHeight()
	local speed = 0.7
	newMissile(posX, posY, targetX, targetY, speed)
end

function deleteFill(someTable, index)
	someTable[index] = someTable[#someTable]
	someTable[#someTable] = nil
end

function updateMissiles(missiles)
	for i,missile in pairs(missiles) do
		missile.posX = missile.posX + missile.vx
		missile.posY = missile.posY + missile.vy
		local dx = missile.posX - missile.startX
		local dy = missile.posY - missile.startY
		local distance2 = dx*dx + dy*dy
		if distance2 > missile.targetDistance*missile.targetDistance or isInExplosion(missile) then
			newExplosion(missile.posX, missile.posY)
			deleteFill(missiles, i)
		end
	end
	print("Number of active missiles: " .. #missiles)
end

function updateExplosions(explosions)
	for i,explosion in pairs(explosions) do
		explosion.r = explosion.r + explosionGrowthRate
		if explosion.r >= maxExplosionRadius then
			deleteFill(explosions, i)
		end
	end
	print("Number of active explosions: " .. #explosions)
end

function love.update(dt)
	if cooldown <= 0.0 then
		newEnemyMissile()
		cooldown = cooldownMax
	else
		cooldown = cooldown - dt
	end
	updateMissiles(missiles)
	updateExplosions(explosions)
end

function love.mousepressed(x, y, button)
	newMissile(love.graphics.getWidth()/2, love.graphics.getHeight(), x, y, 3.0)
	
	--[[
	newMissile(love.graphics.getWidth()/2, love.graphics.getHeight(), x+missileSpread, y, 3.0)
	newMissile(love.graphics.getWidth()/2, love.graphics.getHeight(), x-missileSpread, y, 3.0)
	newMissile(love.graphics.getWidth()/2, love.graphics.getHeight(), x+2*missileSpread, y, 3.0)
	newMissile(love.graphics.getWidth()/2, love.graphics.getHeight(), x-2*missileSpread, y, 3.0)
	]]
end

function love.draw()
	love.graphics.setColor(255, 255, 255, 255)
	for i,missile in pairs(missiles) do
		love.graphics.line(missile.startX, missile.startY, missile.posX, missile.posY)
	end
	for i,explosion in pairs(explosions) do
		love.graphics.circle("line", explosion.posX, explosion.posY, explosion.r, 120)
	end
end