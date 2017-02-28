local actualCategory = 1

local tabs = {
	{name="Wszystkie",contain={FLOGS_CONNECT,FLOGS_DISCONNECT,FLOGS_TOOL,FLOGS_FADMIN,FLOGS_ULX,FLOGS_CHAT,FLOGS_DMG_ENTITY,FLOGS_PROPSPAWN,FLOGS_DARKRP_ADDLAW,FLOGS_DARKRP_ARREST,FLOGS_DARKRP_UNARREST,FLOGS_DARKRP_DEMOTE,FLOGS_DARKRP_DOORRAM,FLOGS_DARKRP_HITMAN,FLOGS_DARKRP_LOCKPICK,FLOGS_DARKRP_NAME,FLOGS_DARKRP_PURCHASE,FLOGS_DARKRP_WANTED,FLOGS_DARKRP_WARRANT}},
	{name="ULX",contain={FLOGS_ULX}},
	{name="Serwerowe",isCategory=true,contain={FLOGS_PROPSPAWN,FLOGS_DMG_ENTITY,FLOGS_CHAT,FLOGS_TOOL,FLOGS_CONNECT,FLOGS_DISCONNECT}},
	{name="Narzędzia",contain={FLOGS_TOOL}},
	{name="Chat",contain={FLOGS_CHAT}},
	{name="Obrażenia",contain={FLOGS_DMG_ENTITY}},
	{name="Spawn propa",contain={FLOGS_PROPSPAWN}},
	{name="Dołączenia",contain={FLOGS_CONNECT}},
	{name="Odłączenia",contain={FLOGS_DISCONNECT}},
	{name="DarkRP",isCategory=true,contain={FLOGS_DARKRP_ADDLAW,FLOGS_DARKRP_ARREST,FLOGS_DARKRP_UNARREST,FLOGS_DARKRP_DEMOTE,FLOGS_DARKRP_DOORRAM,FLOGS_DARKRP_HITMAN,FLOGS_DARKRP_LOCKPICK,FLOGS_DARKRP_NAME,FLOGS_DARKRP_PURCHASE,FLOGS_DARKRP_WANTED,FLOGS_DARKRP_WARRANT}},
	{name="Prawo",contain={FLOGS_DARKRP_ADDLAW}},
	{name="Aresztowania",contain={FLOGS_DARKRP_ARREST,FLOGS_DARKRP_UNARREST}},
	{name="Demote",contain={FLOGS_DARKRP_DEMOTE}},
	{name="Door Ram",contain={FLOGS_DARKRP_DOORRAM}},
	{name="Hitman",contain={FLOGS_DARKRP_HITMAN}},
	{name="Lockpick",contain={FLOGS_DARKRP_LOCKPICK}},
	{name="Nazwa",contain={FLOGS_DARKRP_NAME}},
	{name="Kupna",contain={FLOGS_DARKRP_PURCHASE}},
	{name="Wanted",contain={FLOGS_DARKRP_WANTED}},
	{name="Warrant",contain={FLOGS_DARKRP_WARRANT}},
}

surface.CreateFont( "Roboto16b", { font = "Roboto", size = 16, weight = 800 })

local PANEL = {}

function PANEL:Init()
	self:SetSize(900,600)
	self:MakePopup()
	self:Center()
	self:SetTitle("")

	self.tabs = {}
	for i,k in pairs(tabs) do
		self.tabs[i] = vgui.Create("DButton",self)
		self.tabs[i]:SetWide(200)
		self.tabs[i]:SetPos(0,25 + (i-1) * 22)
		self.tabs[i]:SetText(k.name)
		self.tabs[i]:SetColor(Color(255,255,255))
		self.tabs[i].Paint = function(bt)
			if k.isCategory then
				draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(114, 39, 39, 255))
			else
				draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(80, 80, 80, 255))
			end
		end
		self.tabs[i].DoClick = function()
			-- 
			-- 
			self:SetTab(i)
		end
	end

	self.topic = vgui.Create("DLabel",self)
	self.topic:SetText(tabs[actualCategory].name)
	self.topic:SetContentAlignment( 5 )
	self.topic:SetFont("Roboto16b")
	self.topic:SetColor(Color(255,255,255))
	self.topic:SetPos(200,25)
	self.topic:SetSize(self:GetWide()-200,44)
	self.topic.Paint = function(bt)
		draw.RoundedBox(0, 0, 0, bt:GetWide(), bt:GetTall(), Color(114, 39, 39, 255))
	end

	self.main = vgui.Create("DPanel",self)
	self.main:SetPos(200,69)
	self.main:SetSize(self:GetWide() - 200,self:GetTall() - 120)
	self.main.Paint = function(bt) end

	self.pag = vgui.Create("DPanel",self)
	self.pag:SetPos((self:GetWide()-200)/2 + 200 - 250,self:GetTall() - 50 + 9)
	self.pag:SetSize(500,30)
	self.pag:SetVisible(false)

	self.pag.center = vgui.Create("DNumSlider",self.pag)
	self.pag.center:SetDecimals( 0 )
	self.pag.center:SetSize( self.pag:GetWide(), self.pag:GetTall() )
	self.pag.center:SetText( "Strona" )
	self.pag.center:SetMin( 1 )
	self.pag.center.Label:SetWide(10)
	self.pag.center.Label:Dock(NODOCK)
	self.pag.center.Label:SetVisible(false)

	self:SetTab(actualCategory)
end

function PANEL:SetTab(id)
	actualCategory = id
	self.topic:SetText(tabs[id].name)
	self.main:Clear()
	self.page = 1
	self.pag.center:SetValue(1)

	net.Start("FLOGS_GetData")
		net.WriteInt(self.page,16)
		net.WriteTable(tabs[id].contain)
	net.SendToServer()
end

function PANEL:Paint()
	draw.RoundedBox(4, 0, 0, self:GetWide(), self:GetTall(), Color(37, 41, 53, 255))
	draw.RoundedBoxEx(4, 0, 0, self:GetWide(), 25, Color(30, 144, 255, 255),true,true)
	draw.SimpleText("FLogs","Roboto16b",10,12,Color(255,255,255,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
	draw.RoundedBox(0, 0, 25, 200, self:GetTall()-25, Color(69, 99, 147, 255))
end

function PANEL:ShowPaggination(page,count)
	if math.ceil(count/30) <= 1 then
		self.pag.center:SetVisible(false)
		self.pag:SetVisible(false)
		return
	end
	
	self.pag:SetVisible(true)
	self.pag.center:SetVisible(true)
	self.pag.center:SetMax( math.ceil(count/30) )
	if self.pag.center:GetValue() < 1 then
		self.pag.center:SetValue(1)
	end
	
	function self.pag.center.OnValueChanged(t,pg)
		if math.Round(pg) == self.page then return end
		self.page = math.Round(pg)
		net.Start("FLOGS_GetData")
			net.WriteInt(self.page,16)
			net.WriteTable(tabs[actualCategory].contain)
		net.SendToServer()
	end
end

vgui.Register("flogs.main",PANEL,"DFrame")

local panel
concommand.Add("flogs_open",function()
	if panel then
		panel:Remove()
		panel = nil
	end
	panel = vgui.Create("flogs.main")
end)

net.Receive("FLOGS_SendData",function()
	local dat = net.ReadTable()
	if not panel then return end

	panel.main:Clear()
	panel.main.cont= {}

	local tall = (panel:GetTall() - 120) / 30

	for i,k in pairs(dat) do

		panel.main.cont[i] = vgui.Create("DPanel",panel.main)
		panel.main.cont[i]:SetWide(panel.main:GetWide())
		panel.main.cont[i]:SetPos(0,(i-1) * tall)
		panel.main.cont[i]:SetTall(tall)
		panel.main.cont[i].Paint = function(dt)
			draw.RoundedBox(0, 0, 0, dt:GetWide(), dt:GetTall(), Color(255, 255, 255, 255))
			draw.RoundedBox(0, 0, 0, dt:GetWide(), 1, Color(150, 150, 150, 255))
		end

		panel.main.cont[i].name = vgui.Create("DLabel",panel.main.cont[i])
		panel.main.cont[i].name:SetPos(10,0)
		panel.main.cont[i].name:SetText(k.user)
		panel.main.cont[i].name:SetWide(180)
		panel.main.cont[i].name:SetColor(Color(60,60,60))

		panel.main.cont[i].text = vgui.Create("DLabel",panel.main.cont[i])
		panel.main.cont[i].text:SetPos(190,0)
		panel.main.cont[i].text:SetText(k.message)
		panel.main.cont[i].text:SetWide(panel.main:GetWide()- 10 - 180 - 60)
		panel.main.cont[i].text:SetColor(Color(60,60,60))

		panel.main.cont[i].date = vgui.Create("DLabel",panel.main.cont[i])
		panel.main.cont[i].date:SetPos(panel.main:GetWide() - 110,0)
		panel.main.cont[i].date:SetWide(108)
		panel.main.cont[i].date:SetText(os.date("%H:%M:%S %d/%m/%Y",tonumber(k.date)))
		panel.main.cont[i].date:SetColor(Color(60,60,60))
	end
end)

net.Receive("FLOGS_SendPages",function()
	local count = net.ReadInt(16)
	if not panel then return end
	panel:ShowPaggination(panel.page,count)
end)