ESX				= nil
local DoorInfo	= {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('b1g_doorlock:updateState')
AddEventHandler('b1g_doorlock:updateState', function(doorID, state)
	local xPlayer = ESX.GetPlayerFromId(source)

	if type(doorID) ~= 'number' then
		return
	end

	if not IsAuthorized(xPlayer.job.name, Config.DoorList[doorID]) then
		return
	end

	DoorInfo[doorID] = {}

	DoorInfo[doorID].state = state
	DoorInfo[doorID].doorID = doorID

	TriggerClientEvent('b1g_doorlock:setState', -1, doorID, state)
end)

function IsAuthorized(jobName, doorID)
	for i=1, #doorID.authorizedJobs, 1 do
		if doorID.authorizedJobs[i] == jobName then
			return true
		end
	end

	return false
end

ESX.RegisterServerCallback('b1g_doorlock:getDoorInfo', function(source, cb)
	cb(DoorInfo, #DoorInfo)
end)