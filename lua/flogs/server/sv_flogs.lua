FLogs = FLogs or {}

function FLogs:Init()
	MySQLite.initialize( FLogs.dbconfig )
end
FLogs:Init()

FLogs.Query = function(query,callback)
	if !query then return end
	if type(query) != "string" then return end
	MySQLite.query(query,callback)
end

hook.Add("PlayerInitialSpawn","FRMG_Connect_Store",function(ply)
	FLogs.Query([[SELECT * FROM ]]..FLogs.tables.users..[[ WHERE steamid=']]..ply:SteamID()..[[']],function(callback)
		if not callback then
			FLogs.Query([[INSERT INTO ]]..FLogs.tables.users..[[ (steamid,name) VALUES(']]..ply:SteamID()..[[',']]..ply:Nick()..[[')]])
		else
			if callback[1] ~= ply:Nick() then
				FLogs.Query([[UPDATE ]]..FLogs.tables.users..[[ SET name=']]..ply:Nick()..[[' WHERE steamid=']]..ply:SteamID()..[[']])
			end
		end
	end)
end)

function FLogs:AddLog(ply,type,log)
	if not log then log = "" end
	FLogs.Query([[
		INSERT INTO ]]..FLogs.tables.main..[[ (date,category,message,steamid)
		VALUES(]]..os.time()..[[,]]..type..[[,']]..log..[[',']]..ply:SteamID()..[[')
	]])
end

hook.Add("DatabaseInitialized","FLogs_DBInit",function()
	// Main logs
	FLogs.Query([[
		CREATE TABLE IF NOT EXISTS ]] .. FLogs.tables.main .. [[(
			id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
			date INTEGER,
			category INTEGER,
			message TEXT,
			steamid TEXT
		)
	]])
	// Users
	FLogs.Query([[
		CREATE TABLE IF NOT EXISTS ]] .. FLogs.tables.users .. [[(
			id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
			steamid VARCHAR(30),
			name TEXT
		)
	]])
end)

/*---------------------------------------------------------------------------
									Hooki
---------------------------------------------------------------------------*/

// CONNECT
hook.Add( "PlayerInitialSpawn", "FLOGS_CONNECT", function( ply )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	FLogs:AddLog( ply, FLOGS_CONNECT)
end)

// DISCONNECT
hook.Add( "PlayerDisconnected", "FLOGS_DISCONNECT", function( ply )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	FLogs:AddLog( ply, FLOGS_DISCONNECT)
end)

// TOOL
hook.Add( "CanTool", "FLOGS_TOOL", function( ply, _, tool )
	if !tool then return end
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	FLogs:AddLog( ply, FLOGS_TOOL, tool)
end)

// FADMIN
-- hook.Add( "FAdmin_OnCommandExecuted", "FLOGS_FADMIN", function( Player, Cmd, Args, Res )
-- 	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
-- end)

// ULX
hook.Add( "ULibCommandCalled", "FLOGS_ULX", function( ply, cmd, args )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if not cmd or string.len(cmd) <= 0 then return end
	cmd = string.Split(cmd," ")
	if string.lower(cmd[1]) != "ulx" or not cmd[2] or string.len(cmd[2]) <= 0 then return end
	table.remove(cmd,1)
	cmd = table.concat(cmd," ")
	args = table.concat(args, " ")

	FLogs:AddLog( ply, FLOGS_ULX, util.TableToJSON({command=cmd,arguments=args}))
end)

// Chat
hook.Add( "PlayerSay", "FLOGS_CHAT", function( ply, msg, tm )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !msg then return "" end
	if tm then msg = "(" .. team.GetName(ply:Team()) .. ") " .. msg end

	FLogs:AddLog(ply, FLOGS_CHAT, msg)
end)

// DBG
hook.Add( "EntityTakeDamage", "FLOGS_DMG_ENTITY", function( ply, dmginfo )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	local damage = math.Round( dmginfo:GetDamage() )

	local actualhp = ply:Health() - damage
	local attacker, weapon, typ, strprop

	if dmginfo:GetAttacker():IsValid() then
		if dmginfo:GetAttacker():IsPlayer() or dmginfo:GetAttacker():GetClass() == "prop_physics" then
			attacker = dmginfo:GetAttacker()
			if attacker:IsPlayer() then
				weapon = attacker:GetActiveWeapon()
				typ = "player"
			else
				weapon = dmginfo:GetAttacker()
				if isfunction( weapon.CPPIGetOwner ) and weapon:CPPIGetOwner() and weapon:CPPIGetOwner():IsValid() and weapon:CPPIGetOwner():IsPlayer() then
					attacker = weapon:CPPIGetOwner()
				end
				typ = "prop"
				strprop = weapon:GetModel()
			end
		end
	end

	if dmginfo:GetInflictor():IsValid() then		
		if dmginfo:GetInflictor():IsPlayer() then			
			attacker = dmginfo:GetInflictor()
			if isfunction(dmginfo.GetActiveWeapon) then
				weapon = dmginfo:GetActiveWeapon()
			end
			typ = "player"
		elseif dmginfo:GetInflictor():GetClass() == "prop_physics" then
			if isfunction(weapon.CPPIGetOwner) and weapon:CPPIGetOwner() and weapon:CPPIGetOwner():IsValid() and weapon:CPPIGetOwner():IsPlayer() then
				attacker = weapon:CPPIGetOwner()
				typ = "prop"
				strprop = weapon:GetModel()
			end
		elseif dmginfo:GetInflictor():IsVehicle() then
			attacker = nil
			weapon = dmginfo:GetInflictor()
			if weapon:GetDriver() and weapon:GetDriver():IsValid() then
				attacker = weapon:GetDriver()
			end
			typ = "vehicle"
		end
	end

	if !weapon or type( weapon ) == "string" or weapon:IsValid() then
		if dmginfo:GetAttacker():IsWeapon() or dmginfo:GetAttacker().Projectile then
			weapon = DmgInfo:GetAttacker()
		end
		if dmginfo:GetInflictor():IsWeapon() or dmginfo:GetInflictor().Projectile then
			weapon = dmginfo:GetInflictor()
		end
	end

	if !weapon or type( weapon ) == "string" or !weapon:IsValid() then
		weapon = tostring( dmginfo:GetInflictor() )
	end

	if !attacker or type( attacker ) == "string" or !attacker:IsValid() then
		attacker = nil
	end

	if dmginfo:IsFallDamage() then
		weapon = nil
		attacker = nil
		typ = "falldmg"
	end

	local wepinfo = weapon
	if weapon and type( weapon ) != "string" and weapon:IsValid() then
		wepinfo = weapon:GetClass()
	end
	if attacker and attacker:IsPlayer() then
		attacker = attacker:SteamID()
	end
	local insval = {}
	if !ply:Alive() or ( actualhp <= 0 and ply:Armor() <= 0 ) then
		insval = {weapon=weapon,type=typ,attacker=attacker,killed=true,model=strprop}
	else
		insval = {weapon=weapon,type=typ,attacker=attacker,killed=false,model=strprop}
	end

	FLogs:AddLog(ply, FLOGS_DMG_ENTITY, util.TableToJSON(insval))
end)

hook.Add( "PlayerDeath", "FLOGS_DMG_ENTITY_PLY", function( ply, _, killer )
	
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !killer or !killer:IsValid() or !killer:IsPlayer() then return end
	
	if killer == ply then
		FLogs:AddLog(ply, FLOGS_DMG_ENTITY, util.TableToJSON({type="himself",killed=true}))
	end
	
end)

// Spawning props

hook.Add( "PlayerSpawnProp", "FLOGS_PROPSPAWN", function( ply, class )
	
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !class then return end
	FLogs:AddLog( ply, FLOGS_PROPSPAWN, class)
end)

/*---------------------------------------------------------------------------
							Darkrp Hooks
---------------------------------------------------------------------------*/
local function findTheMayor()
	local mj = {}
	for _, k in pairs(player.GetAll()) do
		if k:Team() == TEAM_MAYOR then
			return k
		end
	end
end

// Add law
hook.Add( "addLaw", "FLOGS_DARKRP_ADDLAW", function( idx, law )
	if !idx then return end
	if !law then return end
	if !TEAM_MAYOR then return end
	local ply = findTheMayor()
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	FLogs:AddLog( ply, FLOGS_DARKRP_ADDLAW, law)
end)

// Arrest player
hook.Add( "playerArrested", "FLOGS_DARKRP_ARREST", function( ply, time, pol )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !pol or !pol:IsValid() or !pol:IsPlayer() then return end
	if !time then time = 0 return end
	FLogs:AddLog( ply, FLOGS_DARKRP_ARREST, util.TableToJSON({arrestedby=pol:SteamID(),time=time}))
end)

// UnArrest
hook.Add( "playerUnArrested", "FLOGS_DARKRP_UNARREST", function( ply, pl )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !pl or !pl:IsValid() or !pl:IsPlayer() then return end
	FLogs:AddLog( ply, FLOGS_DARKRP_UNARREST, pl:SteamID())
end)

// Demote
hook.Add( "onPlayerDemoted", "FLOGS_DARKRP_DEMOTE", function( demoter, demoted, reason )
	if !demoter or !demoter:IsValid() or !demoter:IsPlayer() then return end
	if !demoted or !demoted:IsValid() or !demoted:IsPlayer() then return end
	if !reason then reason = "" return end

	FLogs:AddLog( demoted, FLOGS_DARKRP_DEMOTE, util.TableToJSON({reason=reason,demoter=demoter:SteamID()}))
end)

// DoorRam
hook.Add( "onDoorRamUsed", "FLOGS_DARKRP_DOORRAM", function( su, ply, trace )
	
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if type( su ) != "boolean" then return end
	if !trace then return end
	if !trace.Entity or !trace.Entity:IsValid() then return end
	local doorowner
	if isfunction(trace.Entity.getDoorOwner) then
		doorowner = trace.Entity:getDoorOwner()
	end 

	FLogs:AddLog( ply, FLOGS_DARKRP_DOORRAM, util.TableToJSON({succeed=su,owner=doorowner}))
	
end)

// Hit accepted
hook.Add( "onHitAccepted", "FLOGS_DARKRP_HITMAN_ACCEPT", function( ply, tar, cust )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !tar or !tar:IsValid() or !tar:IsPlayer() then return end
	if !cust or !cust:IsValid() or !cust:IsPlayer() then return end
	
	FLogs:AddLog( ply, FLOGS_DARKRP_HITMAN, util.TableToJSON({action="hitaccept",target=tar,customer=cust}))
end)

// Hit done
hook.Add( "onHitCompleted", "FLOGS_DARKRP_HITMAN_COMPLETED", function( ply, tar, cust )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !tar or !tar:IsValid() or !tar:IsPlayer() then return end
	if !cust or !cust:IsValid() or !cust:IsPlayer() then return end
	
	FLogs:AddLog( ply, FLOGS_DARKRP_HITMAN, util.TableToJSON({action="hitdone",target=tar,customer=cust}))
end)

// Hit failed
hook.Add( "onHitFailed", "FLOGS_DARKRP_HITMAN_FAILED", function( ply, tar, reason )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !tar or !tar:IsValid() or !tar:IsPlayer() then return end
	
	FLogs:AddLog( ply, FLOGS_DARKRP_HITMAN, util.TableToJSON({action="hitfailed",target=tar,reason=reason}))
end)

// Lockpick
hook.Add( "onLockpickCompleted", "FLOGS_DARKRP_LOCKPICK", function( ply, su, ent )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if type( su ) != "boolean" then return end
	if !ent or !ent:IsValid() then return end
	
	FLogs:AddLog( ply, FLOGS_DARKRP_LOCKPICK, util.TableToJSON({succeed=su,entity=ent:GetClass()}))
end)

// Name
hook.Add( "onPlayerChangedName", "FLOGS_DARKRP_NAME", function( ply, old, new )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !old then return end
	if !new then return end
	
	FLogs:AddLog( ply, FLOGS_DARKRP_NAME, util.TableToJSON({oldname=old,newname=new}))
	
end)

// PURCHASE 

hook.Add( "playerBoughtCustomEntity", "FLOGS_DARKRP_PURCHASE_ENTITY", function( ply, enttab, _ )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !enttab then return end
	if !enttab.name or !enttab.price then return end
	FLogs:AddLog( ply, FLOGS_DARKRP_PURCHASE, util.TableToJSON({price=enttab.price,name=enttab.name,entity=enttab.ent,type="entity"}))
end)
hook.Add( "playerBoughtPistol", "FLOGS_DARKRP_PURCHASE_WEAPON", function( ply, enttab, _ )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !enttab then return end
	if !enttab.name or !enttab.price then return end
	FLogs:AddLog( ply, FLOGS_DARKRP_PURCHASE, util.TableToJSON({price=enttab.price,name=enttab.name,entity=enttab.ent,type="weapon"}))
end)
hook.Add( "playerBoughtShipment", "FLOGS_DARKRP_PURCHASE_SHIPMENT", function( ply, enttab, _ )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !enttab then return end
	if !enttab.name or !enttab.price then return end
	
	FLogs:AddLog( ply, FLOGS_DARKRP_PURCHASE, util.TableToJSON({price=enttab.price,name=enttab.name,entity=enttab.ent,type="shipment"}))
end)

// Wanted
hook.Add( "playerWanted", "FLOGS_DARKRP_WANTED", function( ply, officer, reason )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !officer or !officer:IsValid() or !officer:IsPlayer() then return end
	FLogs:AddLog( ply, FLOGS_DARKRP_WANTED, util.TableToJSON({type="wanted",officer=officer:SteamID(),reason=reason}))
end)
hook.Add( "PlayerWanted", "FLOGS_DARKRP_WANTED_S", function( ply, officer, reason )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !officer or !officer:IsValid() or !officer:IsPlayer() then return end
	FLogs:AddLog( ply, FLOGS_DARKRP_WANTED, util.TableToJSON({type="wanted",officer=officer:SteamID(),reason=reason}))
end)
hook.Add( "playerUnWanted", "FLOGS_DARKRP_WANTED_UNWANTED", function( ply, officer )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !officer or !officer:IsValid() or !officer:IsPlayer() then return end
	FLogs:AddLog( ply, FLOGS_DARKRP_WANTED, util.TableToJSON({type="unwanted",officer=officer:SteamID()}))
end)
hook.Add( "PlayerUnWanted", "FLOGS_DARKRP_WANTED_UNWANTED_S", function( ply, officer )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !officer or !officer:IsValid() or !officer:IsPlayer() then return end
	FLogs:AddLog( ply, FLOGS_DARKRP_WANTED, util.TableToJSON({type="unwanted",officer=officer:SteamID()}))
end)

// Warrant
hook.Add( "playerWarranted", "FLOGS_DARKRP_WARRANT", function( ply, officer, reason )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !officer or !officer:IsValid() or !officer:IsPlayer() then return end
	FLogs:AddLog( ply, FLOGS_DARKRP_WARRANT, util.TableToJSON({type="warrant",officer=officer:SteamID(),reason=reason}))
end)
hook.Add( "PlayerWarranted", "FLOGS_DARKRP_WARRANT_S", function( ply, officer, reason )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !officer or !officer:IsValid() or !officer:IsPlayer() then return end
	FLogs:AddLog( ply, FLOGS_DARKRP_WARRANT, util.TableToJSON({type="warrant",officer=officer:SteamID(),reason=reason}))
end)
hook.Add( "playerUnWarranted", "FLOGS_DARKRP_WARRANT_S", function( ply, officer )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !officer or !officer:IsValid() or !officer:IsPlayer() then return end
	FLogs:AddLog( ply, FLOGS_DARKRP_WARRANT, util.TableToJSON({type="unwarrant",officer=officer:SteamID()}))
end)
hook.Add( "PlayerUnWarranted", "FLOGS_DARKRP_WARRANT_S", function( ply, officer )
	if !ply or !ply:IsValid() or !ply:IsPlayer() then return end
	if !officer or !officer:IsValid() or !officer:IsPlayer() then return end
	FLogs:AddLog( ply, FLOGS_DARKRP_WARRANT, util.TableToJSON({type="unwarrant",officer=officer:SteamID()}))
end)

/*---------------------------------------------------------------------------
							Sending data to client
---------------------------------------------------------------------------*/

util.AddNetworkString( "FLOGS_GetData" )
util.AddNetworkString( "FLOGS_SendData" )
util.AddNetworkString( "FLOGS_SendPages" )

local function sendData(dat,ply)
	local users = {}
	for i,k in pairs(dat) do
		if table.HasValue(users,k.steamid) then continue end

		table.insert(users,k.steamid)
		local dq = util.JSONToTable(k.message)

		if k.category == FLOGS_DMG_ENTITY then
			if dq.attacker then
				if table.HasValue(users,dq.attacker) then continue end
				table.insert(users,dq.attacker)
			end
			continue
		end
		if k.category == FLOGS_DARKRP_ARREST then
			if dq.arrestedby then
				if table.HasValue(users,dq.arrestedby) then continue end
				table.insert(users,dq.arrestedby)
			end
			continue
		end
		if k.category == FLOGS_DARKRP_UNARREST then
			if table.HasValue(users,k.message) then continue end
			table.insert(users,k.message)
			continue
		end
		if k.category == FLOGS_DARKRP_DEMOTE then
			local dq = util.JSONToTable(k.message)
			if table.HasValue(users,dq.demoter) then continue end
			table.insert(users,dq.demoter)
			continue
		end
		if k.category == FLOGS_DARKRP_HITMAN_ACCEPT or  k.category == FLOGS_DARKRP_HITMAN_COMPLETED then
			if not table.HasValue(users,k.target) then table.insert(users,k.target) end
			if not table.HasValue(users,k.customer) then table.insert(users,k.customer) end
			continue
		end
		if k.category == FLOGS_DARKRP_HITMAN_FAILED then
			-- target, customer
			if not table.HasValue(users,k.target) then table.insert(users,k.target) end
			continue
		end
		if k.category == FLOGS_DARKRP_WANTED or k.category == FLOGS_DARKRP_WARRANT then
			local dq = util.JSONToTable(k.message)
			if not table.HasValue(users,dq.officer) then table.insert(users,dq.officer) end
		end
	end
	local where = "steamid='"..string.Implode("' OR steamid='",users).."'"
	FLogs.Query([[SELECT * FROM ]]..FLogs.tables.users..[[ WHERE ]] .. where,function(callback)
		// Sort by steamid
		if not callback then return end
		local usersteam = {}
		for i,k in pairs(callback) do
			usersteam[k.steamid] = k
		end

		// Prepare messages
		local messages = {}
		for i,k in pairs(dat) do
			if k.category == FLOGS_CONNECT then
				table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Dołączył do serwera"})
				continue
			end
			if k.category == FLOGS_DISCONNECT then
				table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Wyszedł z serwera"})
				continue
			end
			if k.category == FLOGS_TOOL then
				table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Użył narzędzia " .. k.message})
				continue
			end
			if k.category == FLOGS_ULX then
				local dq = util.JSONToTable(k.message)
				table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Użył komendy ulx " .. dq.command .. " " .. dq.arguments})
				continue
			end
			if k.category == FLOGS_CHAT then
				table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message=k.message})
				continue
			end
			if k.category == FLOGS_DMG_ENTITY then
				local dq = util.JSONToTable(k.message)
				local msq = ""
				if dq.killed and dq.killed == true then
					msq = "Został zabity przez "
				else
					msq = "Został zraniony przez "
				end
				if dq.type == "player" then
					msq = msq .. "gracza"
					-- table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Został zabity przez ".. usersteam[dq.attacker].name .. " używając broni " .. dq.weapon})
				elseif dq.type == "vehicle" then
					msq = msq .. "pojazd"
				elseif dq.type == "prop" then
					msq = msq .. "prop"
				end

				if dq.attacker then
					msq = msq .. " " .. usersteam[dq.attacker].name
				end

				if dq.weapon then
					msq = msq .. " używając broni " .. dq.weapon
				end

				if dq.model then
					msq = msq .. " " .. dq.model
				end

				if dq.type == "falldmg" then
					if dq.killed and dq.killed == true then
						msq = "Zabił się spadając z wysokości"
					else
						msq = "Zranił się spadając wysokości"
					end
				end
				if dq.type == "himself" then
					msq = "Zabił sam siebie"
				end
				table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message=msq})
				continue
			end
			if k.category == FLOGS_PROPSPAWN then
				table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Zespawnował prop " .. k.message})
				continue
			end
			if k.category == FLOGS_DARKRP_ADDLAW then
				table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Dodał prawo " .. k.message})
				continue
			end
			if k.category == FLOGS_DARKRP_ARREST then
				local dq = util.JSONToTable(k.message)
				table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Został aresztowany przez " .. usersteam[dq.arrestedby].name .. " na " .. dq.time .. " sekund" })
				continue
			end
			if k.category == FLOGS_DARKRP_UNARREST then
				table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Został odaresztowany przez "..usersteam[dq.arrestedby].name })
				continue
			end
			if k.category == FLOGS_DARKRP_DEMOTE then
				local dq = util.JSONToTable(k.message)
				table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Dostał demote od "..usersteam[dq.demoter].name .. " za " .. dq.reason })
				continue
			end
			if k.category == FLOGS_DARKRP_DOORRAM then
				local dq = util.JSONToTable(k.message)
				local msq = "Użuł door rama"
				if dq.owner then
					msq = msq .. " na drzwiach gracza " .. usersteam[k.owner]
				end
				if dq.succeed then
					msq = msq .. " (Udało się)"
				else
					msq = msq .. " (Nie udało się)"
				end
				table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message=msq })
				continue
			end
			if k.category == FLOGS_DARKRP_HITMAN then
				local dq = util.JSONToTable(k.message)
				if dq.action == "hitaccept" then
					table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Zaakceptował hita od gracza " .. usersteam[dq.customer].name .. " na " .. usersteam[dq.target].name})
				end
				if dq.action == "hitdone" then
					table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Wykonoał hita od gracza " .. usersteam[dq.customer].name .. " na " .. usersteam[dq.target].name})
				end
				if dq.action == "hitfailed" then
					table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Nie wykonał hita na " .. usersteam[dq.target].name .. " ("..dq.reason..")"})
				end
				continue
			end
			if k.category == FLOGS_DARKRP_LOCKPICK then
				local dq = util.JSONToTable(k.message)
				if succeed and succeed == true then
					table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Użył lockpicka na " .. dq.entity .. " (Udało się)" })
				else
					table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Użył lockpicka na " .. dq.entity .. " (Nie udało się)" })
				end
				continue
			end
			if k.category == FLOGS_DARKRP_NAME then
				local dq = util.JSONToTable(k.message)
				table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Zmienił nick z " .. dq.oldname .. " na " .. dq.newname })
				continue
			end
			if k.category == FLOGS_DARKRP_PURCHASE then
				local dq = util.JSONToTable(k.message)
				if dq.type == "shipment" then
					table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Kupił shipment " .. dq.name .. " za " .. dq.price .. " (" .. dq.entity .. ")" })
				end
				if dq.type == "entity" then
					table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Kupił entity " .. dq.name .. " za " .. dq.price .. " (" .. dq.entity .. ")" })
				end
				if dq.type == "weapon" then
					table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Kupił broń " .. dq.name .. " za " .. dq.price .. " (" .. dq.entity .. ")" })
				end
				continue
			end
			if k.category == FLOGS_DARKRP_WANTED then
				local dq = util.JSONToTable(k.message)
				if dq.type == "wanted" then
					table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Zaczął być poczukiwany przez " .. usersteam[dq.officer].name .. " (".. dq.reason ..")" })
				end
				if dq.type == "unwanted" then
					table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Przestał być poszukiwany przez " .. usersteam[dq.officer].name })
				end
				continue
			end
			if k.category == FLOGS_DARKRP_WARRANT then
				local dq = util.JSONToTable(k.message)
				if dq.type == "warrant" then
					table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Otrzymał warrant od " .. usersteam[dq.officer].name .. " (" .. dq.reason .. ")" })
				else
					table.insert(messages,{user=usersteam[k.steamid].name,date=k.date,message="Otrzymał unwarrant od " .. usersteam[dq.officer].name })
				end
				continue
			end
		end

		net.Start("FLOGS_SendData")
			net.WriteTable(messages)
		net.Send(ply)
	end)
end

net.Receive("FLOGS_GetData",function(_,ply)
	if not ply:IsAdmin() and not ply:IsSuperAdmin() then return end
	local page = net.ReadInt(16) -- Page
	local getData = net.ReadTable() -- Table data
	local prepareData = "category="..getData[1]
	for i,k in pairs(getData) do
		if i == 1 then continue end
		prepareData=prepareData .. " OR category="..k
	end

	local offset = (page - 1) * 30
	FLogs.Query([[SELECT * FROM ]]..FLogs.tables.main..[[ WHERE ]] .. prepareData .. [[ ORDER BY date DESC LIMIT 30 OFFSET ]] .. offset,function(callback)
		if not callback then return end		
		sendData(callback,ply)
		// Get rows
		FLogs.Query([[SELECT COUNT(*) AS count FROM ]]..FLogs.tables.main..[[ WHERE ]] .. prepareData,function(vb)
			if not vb then return end

			net.Start("FLOGS_SendPages")
				net.WriteInt(vb[1].count,16)
			net.Send(ply)
		end)
	end)
end)