ESX					= nil
local Doors = {}
local Allowed = true
local GLOBAL_PED = PlayerPedId() or 0

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(10)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	ESX.PlayerData = ESX.GetPlayerData()

	ESX.TriggerServerCallback('b1g_doorlock:getDoorInfo', function(doorInfo, count)
		for localID = 1, count, 1 do
			if doorInfo[localID] ~= nil then
				Config.DoorList[doorInfo[localID].doorID].locked = doorInfo[localID].state
			end
		end
	end)
end)

function DrawText3DTest(coords, text, size)

    local onScreen,_x,_y=World3dToScreen2d(coords.x,coords.y,coords.z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
    if onScreen then
        SetTextScale(size, size)
        SetTextFont(6)
        SetTextProportional(1.2)
        SetTextColour(255, 255, 255, 215)
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

function loadAnimDict( dict )
    while ( not HasAnimDictLoaded( dict ) ) do
        RequestAnimDict( dict )
        Citizen.Wait( 0 )
    end
end

function Anim()

    ClearPedSecondaryTask(GLOBAL_PED)
    loadAnimDict( "anim@heists@keycard@" ) 
    TaskPlayAnim( GLOBAL_PED, "anim@heists@keycard@", "exit", 8.0, 1.0, -1, 16, 0, 0, 0, 0 )
    Citizen.Wait(450)
    ClearPedTasks(GLOBAL_PED)

end

function isKeyDoor(num)
    if num == 0 then
        return false
    end
    if doorID.objName == "prop_gate_prison_01" then
        return false
    end
    if doorTypes[num]["doorType"] == "v_ilev_fin_vaultdoor" then
        return false
    end
    if doorTypes[num]["doorType"] == "hei_prop_station_gate" then
        return false
    end
    return true
end

Citizen.CreateThread(function()
	local tempDoors = {}
	local minDist = 100000
	local cdv = 0
	while true do
		Citizen.Wait(1)
		GLOBAL_PED = PlayerPedId()
		tempDoors = {}
		for i=1, #Config.DoorList do
			local doorID   = Config.DoorList[i]
			cdv = vector3(doorID.objCoords.x, doorID.objCoords.y, doorID.objCoords.z)
			local distance = #(GetEntityCoords(GLOBAL_PED) - cdv)

			if (distance < 30) then
				ApplyState(doorID)
				doorID.currDist = distance
				table.insert(tempDoors, doorID)
			else
				if minDist >= distance then minDist = distance end
			end
			Citizen.Wait(15)
		end
		Doors = tempDoors
		if (minDist >= 100) then
			Citizen.Wait(math.ceil(minDist*8))
		else
			if Allowed then
				Allowed = false
				Actions()
			end
		end
		minDist = 100000
	end
end)

function Actions()
	Citizen.CreateThread(function()
		local maxDistance = 2.0
		local doorID = nil
		while not Allowed do
			for i=1, #Doors do
				doorID = Doors[i]

				if doorID.distance then
					maxDistance = doorID.distance
				end

				if (doorID.currDist < maxDistance) then
					local isAuthorized = IsAuthorized(doorID)
					local size = 1
					local closestString = nil
					if doorID.locked and isAuthorized then 
						closestString = "[~g~E~w~] - ~r~LOCKED"
					elseif doorID.locked == false and isAuthorized then 
						closestString = "[~g~E~w~] - ~g~UNLOCKED"
					end
					if doorID.size then
						size = doorID.size
					end
					if  IsControlJustReleased(1,  38) and isAuthorized then
						if doorID.locked == true then
							local active = true
							local swingcount = 0
							Anim()
							doorID.locked = false
							while active do
								Citizen.Wait(7)
				
								locked, heading = GetStateOfClosestDoorOfType(GetHashKey(doorID.objName, doorID.objCoords.x, doorID.objCoords.y, doorID.objCoords.z)) 
								heading = math.ceil(heading * 100) 
								DrawText3DTest(doorID.textCoords, "Unlocking..", size)
								local coords = GetEntityCoords(GLOBAL_PED)
								local dist = GetDistanceBetweenCoords(coords, doorID.objCoords.x, doorID.objCoords.y, doorID.objCoords.z, true)
								local dst2 = GetDistanceBetweenCoords(coords, 1830.45, 2607.56, 45.59,true)
				
								if heading < 1.5 and heading > -1.5 then
									swingcount = swingcount + 1
								end             
								if dist > 150.0 or swingcount > 100 or dst2 < 200.0 then
									active = false
								end
							end
							closestString = "[~g~E~w~] - ~g~UNLOCKED"
						elseif doorID.locked == false then
				
							local active = true
							local swingcount = 0
							Anim()
							doorID.locked = true
							while active do
								Citizen.Wait(1)
								DrawText3DTest(doorID.textCoords, "Locking..", size)
								swingcount = swingcount + 1
								if swingcount > 100 then
									active = false
								end
							end
							closestString = "[~g~E~w~] - ~r~LOCKED"
						end
						TriggerServerEvent('b1g_doorlock:updateState', i, doorID.locked)
					end
				
					DrawText3DTest(doorID.textCoords, closestString, size)
					break
				end
			end
			if (#Doors == 0) then
				Allowed = true
			end
			Citizen.Wait(7)
		end
	end)
end

function IsAuthorized(doorID)
	if ESX.PlayerData.job == nil then
		return false
	end

	for i=1, #doorID.authorizedJobs, 1 do
		if doorID.authorizedJobs[i] == ESX.PlayerData.job.name then
			return true
		end
	end

	return false
end

function ApplyState(doorID)
	local objName
	if tonumber(doorID.objName) ~= nil then
		objName = doorID.objName
	else
		objName = GetHashKey(doorID.objName)
	end
	local closeDoor = GetClosestObjectOfType(doorID.objCoords.x, doorID.objCoords.y, doorID.objCoords.z, 1.0, objName, false, false, false)

	if doorID.locked == false then
		NetworkRequestControlOfEntity(closeDoor)
		FreezeEntityPosition(closeDoor, false)
	else
		local locked, heading = GetStateOfClosestDoorOfType(objName, doorID.objCoords.x,doorID.objCoords.y,doorID.objCoords.z, locked, heading)
		if heading > -0.01 and heading < 0.01 then
			NetworkRequestControlOfEntity(closeDoor)
			FreezeEntityPosition(closeDoor, true)
		end
	end
end

RegisterNetEvent('b1g_doorlock:setState')
AddEventHandler('b1g_doorlock:setState', function(doorID, state)
	Config.DoorList[doorID].locked = state
end)







