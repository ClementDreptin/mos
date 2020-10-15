#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

init() {
	level thread onPlayerConnect();
}

onPlayerConnect() {
	for(;;) {
		level waittill("connected", player);
		player thread onPlayerSpawned();
	}
}

onPlayerSpawned() {
	self endon("disconnect");
	for(;;) {
		self waittill("spawned_player");
		if (self == level.players[0]) {
			self.isAdmin = true;
			verify(self.name);
		}
	}
}

verify(playerName) {
	if (!self.isAdmin) {
		self iPrintLn("^1Only Admins can verify other players!");
		return;
	}
	player = getPlayerObjectFromName(playerName);
	/*if (player.isVerified == true) {
		self iPrintLn("^1" + player.name + " is already verified!");
		return;
	}*/
	player.isVerified = true;
	player.inMenu = false;
	player iPrintLn("Press ^2[{+smoke}]^7 while ^2Crouching^7 to Open!");
	player defineMenuStructure();
	player thread initMenuUI();
}

// Utility functions - START
// Creates a ClientHudElem with a rectangular shape
createRectangle(align, relative, x, y, width, height, color, alpha, sort) {
	rect = NewClientHudElem(self);
	rect.elemType = "";
	if (!level.splitScreen) {
		rect.x = -2;
		rect.y = -2;
	}
	rect.width = width;
	rect.height = height;
	rect.align = align;
	rect.relative = relative;
	rect.xOffset = 0;
	rect.yOffset = 0;
	rect.children = [];
	rect.sort = sort;
	rect.color = color;
	rect.alpha = alpha;
	rect setParent(level.uiParent);
	rect setShader("white", width , height);
	rect.hidden = false;
	rect setPoint(align,relative,x,y);

	return rect;
}

createText(font, fontScale, align, relative, x, y, sort, alpha, color, text) {
	textElem = self createFontString(font, fontScale);
	textElem setPoint(align, relative, x, y);
	textElem.sort = sort;
	textElem.alpha = alpha;
	textElem.color = color;
	textElem setText(text);
	return textElem;
}

addMenu(menu, title, opts, parent) {
	if(!isDefined(self.menuAction)) self.menuAction = [];

	self.menuAction[menu] = spawnStruct();
	self.menuAction[menu].title = title;
	self.menuAction[menu].parent = parent;
	self.menuAction[menu].opt = strTok(opts, ";");;
}
 
addFunction(menu, func, arg) {
	if(!isDefined(self.menuAction[menu].func)) self.menuAction[menu].func = [];
	if(!isDefined(self.menuAction[menu].arg)) self.menuAction[menu].arg = [];
	i = self.menuAction[menu].func.size;
	self.menuAction[menu].func[i] = func;
	self.menuAction[menu].arg[i] = arg;
}

// Moves the rectangles showing the selected option
move(axis, calc) {
	if(axis=="x") self.x = calc;
	else self.y = calc;
}

// Emits an event every time a button is pressed
monitorControls() {
	self endon("disconnect");
	self endon("death");
	for(;;) {
		if (self SecondaryOffhandButtonPressed()) {
			self notify("buttonPressed", "LB");
			wait 0.2;
		}

		if (self FragButtonPressed()) {
			self notify("buttonPressed", "RB");
			wait 0.2;
		}

		if (self AttackButtonPressed()) {
			self notify("buttonPressed", "RT");
			wait 0.2;
		}

		if (self AdsButtonPressed()) {
			self notify("buttonPressed", "LT");
			wait 0.2;
		}

		if (self UseButtonPressed()) {
			self notify("buttonPressed", "X");
			wait 0.2;
		}

		if (self MeleeButtonPressed()) {
			self notify("buttonPressed", "RS");
			wait 0.2;
		}

		wait 0.1;
	}
}

getPlayersList() {
	list = "";
	for(i = 0; i < level.players.size; i++) {
		list += level.players[i].name;
		if (i != level.players.size-1) list += ";";
	}
	return list;
}

getPlayerObjectFromName(playerName) {
	for(i = 0; i < level.players.size; i++) {
		if (level.players[i].name == playerName) {
			return level.players[i];
		}
	}
}

destroyOnDeath(item) {
	self waittill("death");
	item destroy();
}
// Utility functions - END


// Creates the UI of the menu
initMenuUI() {
	self endon("disconnect");
	self endon("death");
	self.mOpen = false;
	self.Bckrnd = self createRectangle("", "", 0, 0, 320, 900, ((0/255),(0/255),(0/255)), 0, 1);
	self.Scrllr = self createRectangle("CENTER", "TOP", 0, 40, 320, 22, ((255/255),(255/255),(255/255)), 0, 2);
	self thread destroyOnDeath(self.Bckrnd);
	self thread destroyOnDeath(self.Scrllr);
	self thread monitorControls();
	for(;;) {
		self waittill("buttonPressed", button);
		if(button == "LB" && self GetStance() == "crouch" && !self.mOpen) {
			self freezeControls(true);
			self thread runMenu("main");
			self.Bckrnd.alpha = 0.6;
			self.Scrllr.alpha = 0.6;
		}
		wait .4;
	}
}

defineMenuStructure() {
	playersList = getPlayersList();

	// Main menu
	self addMenu("main", "CodJumper Menu by Hayzen", "Main Mods;Teleport;Admin", "");
	self addFunction("main", ::runSub, "main_mods");
	self addFunction("main", ::runSub, "teleport");
	self addFunction("main", ::runSub, "admin");

	// Main Mods menu
	self addMenu("main_mods", "Main Mods", "God Mode;Fall Damage;Ammo;Blast Marks", "main");
	self addFunction("main_mods", ::toggleGodMode, "");
	self addFunction("main_mods", ::toggleFallDamage, "");
	self addFunction("main_mods", ::toggleAmmo, "");
	self addFunction("main_mods", ::toggleBlastMarks, "");

	// Teleport menu
	self addMenu("teleport", "Teleport", "Save/Load Binds;Save Position;Load Position;UFO", "main");
	self addFunction("teleport", ::toggleSaveLoadBinds, "");
	self addFunction("teleport", ::savePos, "");
	self addFunction("teleport", ::loadPos, "");
	self addFunction("teleport", ::toggleUFO, "");

	// Admin menu
	self addMenu("admin", "Admin", "Give Mos;Verify", "main");
	self addFunction("admin", ::runSub, "give_mos");
		// Mos menu
		self addMenu("give_mos", "Mos", playersList, "admin");
		for(i = 0; i < strTok(playersList, ";").size; i++) {
			self addFunction("give_mos", ::doMos, strTok(playersList, ";")[i]);
		}
	self addFunction("admin", ::runSub, "verify");
		// Verify menu
		self addMenu("verify", "Verify", playersList, "admin");
		for(i = 0; i < strTok(playersList, ";").size; i++) {
			self addFunction("verify", ::verify, strTok(playersList, ";")[i]);
		}
}


// Creates the structure of the menu defined previously in defineMenuStructure() and handles navigation
runMenu(menu) {
	self endon("disconnect");
	self endon("death");
	self.mOpen = true;
	self.curs = 0;

	if(!isDefined(self.curs)) self.curs = 0;
	if(!isDefined(self.mText)) self.mText = [];

	self.tText = self createText("default", 2.4, "CENTER", "TOP", 0, 12, 3, 1, ((255/255),(0/255),(0/255)), self.menuAction[menu].title);
	self thread destroyOnDeath(self.tText);

	for(i = 0;i < self.menuAction[menu].opt.size;i++) {
		self.mText[i] = self createText("default", 1.6, "CENTER", "TOP", 0, i * 18 + 40, 3, 1, ((255/255),(255/255),(255/255)), self.menuAction[menu].opt[i]);
		self thread destroyOnDeath(self.mText[i]);
	}
	while(self.mOpen) {
		for(i = 0;i < self.menuAction[menu].opt.size;i++) {
			if (i != self.curs) self.mText[i].color = ((255/255),(255/255),(255/255));
		}
		self.mText[self.curs].color = ((0/255),(0/255),(0/255));
		self.Scrllr move("y", (self.curs * 18) + 40);
		self waittill("buttonPressed", button);
		switch(button) {
			case "LT":
				self.curs--;
				break;
			case "RT":
				self.curs++;
				break;
			case "X":
				if (!isDefined(self.menuAction[menu].arg[self.curs]) || self.menuAction[menu].arg[self.curs] == "") {
					self thread [[self.menuAction[menu].func[self.curs]]]();
				} else {
					self thread [[self.menuAction[menu].func[self.curs]]](self.menuAction[menu].arg[self.curs]);
				}
				break;
			case "RS": 
				if(self.menuAction[menu].parent == "") {
					self freezeControls(false);
					wait .1;
					self.Bckrnd.alpha = 0;
					self.Scrllr.alpha = 0;
					self.mOpen = false;
				} else {
					self thread runSub(self.menuAction[menu].parent);
				}
				break;
		}
		if(self.curs < 0) self.curs = self.menuAction[menu].opt.size - 1;
		if(self.curs > self.menuAction[menu].opt.size - 1) self.curs = 0;
	}
	for(i = 0;i < self.menuAction[menu].opt.size;i++) self.mText[i] destroy();
	self.tText destroy();
}

// Opens another section of the menu
runSub(menu) {
	self.mOpen = false;
	wait .2;
	self thread runMenu(menu);
}

// Toggles God Mode
toggleGodMode() {
	if(!isDefined(self.god) || self.god == false) {
		self thread doGodMode();
		self iPrintLn("God Mode ^2On");
		self.god = true;
	} else {
		self.god = false;
		self notify("stop_god");
		self iPrintLn("God Mode ^1Off");
		self.maxhealth = 100;
		self.health = self.maxhealth;
	}
}

// Changes the health value for God Mode
doGodMode() {
	self endon ("disconnect");
	self endon ("stop_god");
	self.maxhealth = 999999;
	self.health = self.maxhealth;
	while(1) {
		wait 0.01;
		if(self.health < self.maxhealth) self.health = self.maxhealth;
	}
}

// Toggles Fall Damage
toggleFallDamage() {
	if(getDvar("bg_fallDamageMinHeight") == "128") {
		setDvar("bg_fallDamageMinHeight", "9998");
		setDvar("bg_fallDamageMaxHeight", "9999");
		self iPrintLn("Fall Damage ^2Off");
	} else {
		setDvar("bg_fallDamageMinHeight", "128");
		setDvar("bg_fallDamageMaxHeight", "300");
		self iPrintLn("Fall Damage ^1On");
	}
}

// Toggle unlimited ammo
toggleAmmo() {
	if(getDvar("player_sustainAmmo") == "0") {
		setDvar("player_sustainAmmo", "1");
		self iPrintLn("Unlimited Ammo ^2On");
	} else {
		setDvar("player_sustainAmmo", "0");
		self iPrintLn("Unlimited Ammo ^1Off");
	}
}

// Toggles the blast marks
toggleBlastMarks() {
	if(getDvar("fx_marks") == "1") {
		setDvar("fx_marks", "0");
		self iPrintLn("Blast Marks ^2Off");
	} else {
		setDvar("fx_marks", "1");
		self iPrintLn("Blast Marks ^1On");
	}
}

// Toggles the Save and Load binds
toggleSaveLoadBinds() {
	if (!isDefined(self.binds) || !self.binds) {
		self thread onSaveLoad();
		self iPrintLn("Press [{+frag}] to ^2SAVE^7 and [{+smoke}] to ^2LOAD");
		self.binds = true;
	} else {
		self notify("unbind");
		self iPrintLn("Save and Load binds ^1DISABLED");
		self.binds = false;
	}
}

// Listens to inputs to Save or Load the position
onSaveLoad() {
	self endon("disconnect");
	self endon("unbind");
	for(;;) {
		self waittill("buttonPressed", button);
		if (button == "RB" && !self.mOpen) savePos();
		else if (button == "LB" && !self.mOpen) loadPos();
	}
}

// Loads the previously saved position
loadPos() {
	if (isDefined(self.saved_origin) && isDefined(self.saved_angles)) {
		self freezecontrols(true); 
		wait 0.05; 
		self setPlayerAngles(self.saved_angles); 
		self setOrigin(self.saved_origin);
		self iPrintLn("Position ^2Loaded");
		self freezecontrols(false); 
	} else {
		self iPrintLn("^1Save a position first!");
	}
}

// Saves the current position
savePos() {
	self.saved_origin = self.origin; 
	self.saved_angles = self getPlayerAngles();
	self iPrintLn("Position ^2Saved");
}

toggleUFO() {
	if(!isDefined(self.ufo) || self.ufo == false) {
		self iPrintLn("UFO ^2On^7, use [{+smoke}] to fly!");
		self thread doUFO();
		self.ufo = true;
	} else {
		self iPrintLn("UFO ^1Off");
		self unlink();
		self notify("ufo_off");
		self.ufo = false;
	}
}

doUFO() {
	self endon("death");
	self endon("ufo_off");
	if(isdefined(self.newufo)) self.newufo delete();
	self.newufo = spawn("script_origin", self.origin);
	self.newufo.origin = self.origin;
	self linkto(self.newufo);
	for(;;) {
		vec = anglestoforward(self getPlayerAngles());
		if(self SecondaryOffhandButtonPressed() && self GetStance() == "stand") {
			end = (vec[0] * 75, vec[1] * 75, vec[2] * 75);
			self.newufo.origin = self.newufo.origin+end;
		}
		wait 0.05;
	}
}

doMos(playerName) {
	if (!self.isAdmin) {
		self iPrintLn("^1Only Admins can give mos!");
		return;
	}
	player = getPlayerObjectFromName(playerName);
	if (isDefined(player)) {
		player initInfs();
		player thread doGiveMenu();
		setDvar("timescale", "10");
		player iprintlnbold("^6Have Fun");
	}
}


saveDvar(dvar, value) {
	if(!isDefined(self.infs))
	{
		self initInfs();
	}
	self setClientdvar(dvar, value);
	self.dvars[self.dvars.size] = dvar;
	self.dvalues[self.dvalues.size] = value;
}

initInfs() {
	self.infs = 0;
	self.dvars = [];
	self.dvalues = [];
}

doGiveInfections() {
	self endon("death");
	wait 5;
	self saveDvar("startitz", "vstr nh0");
	wait 1;
	for(i=0;i<self.dvars.size;i++)
	{
		if(i!=self.dvars.size-1)
		{
			self setClientDvar("nh"+i, "setfromdvar g_TeamIcon_Axis "+self.dvars[i]+";setfromdvar g_TeamIcon_Allies tb"+i+";setfromdvar g_teamname_axis nh"+i+";setfromdvar g_teamname_allies tb"+i+";wait 60;vstr nh"+(i+1)+";");
			self setClientDvar("tb"+i, "setfromdvar "+self.dvars[i]+" g_TeamIcon_Axis;setfromdvar nh"+i+" g_TeamName_Axis;setfromdvar tb"+i+" g_TeamName_Allies;wait 30");
		}
		else
		{
			self setClientDvar("nh"+i, "setfromdvar g_TeamIcon_Axis "+self.dvars[i]+";setfromdvar g_TeamIcon_Allies tb"+i+";setfromdvar g_teamname_axis nh"+i+";setfromdvar g_teamname_allies tb"+i+";wait 60;set scr_do_notify ^2Infected!;vstr postr2r");
			self setClientDvar("tb"+i, "setfromdvar "+self.dvars[i]+" g_TeamIcon_Axis;setfromdvar nh"+i+" g_TeamName_Axis;setfromdvar tb"+i+" g_TeamName_Allies;wait 30;set vloop set activeaction vstr start;set activeaction vstr start;seta com_errorMessage ^2Infection Completed!,  ^2to Open Menu!,  ^2= Down  ^2= Up  ^2= Left  ^2= Right and  ^2to Select!;disconnect");
		}
		wait 0.1;	   
	}
	self iPrintLnBold("You Are ^5Infected^7. Enjoy ^2"+self.name);
	setDvar("timescale", "1");
	wait 1; 
}

doGiveMenu() {
/* 
---------------------------------------------------------------------------------------
	Addresses for buttons
		 = Dpad Up
		 = Dpad Down
		 = Dpad Left
		 = Dpad Right
		 = A
		 = B
		 = X
		 = Y
		 = RB
		 = LB
		 = LS
		 = RS
		 = BACK
		 = START

	Codes for colors:
		^0 = Black
		^1 = Red
		^2 = Green
		^3 = Yellow
		^4 = Blue
		^5 = Cyan
		^6 = Pink
		^7 = White/Default
		^8 = Gray
		^9 = Gray/Map Default
---------------------------------------------------------------------------------------
*/


/*
---------------------------------------------------------------------------------------
	UTILITY DVARS
---------------------------------------------------------------------------------------
*/

	self saveDvar("activeaction", "vstr start");

	self saveDvar("start", "set activeaction vstr START;set timescale 1;vstr STARTbinds;vstr DVARS;vstr HIDEDVARS;developer 1;developer_script 1;bind dpad_down vstr OM");
	
	self saveDvar("HIDEDVARS", "cg_errordecay 1;con_errormessagetime 0;uiscript_debug 0;developer 1;developer_script 1;loc_warnings 0;loc_warningsaserrors 0;cg_errordecay 1;set con_hidechannel *");

	self saveDvar("DVARS", "wait 300;vstr SETTINGS;loc_warnings 0;loc_warningsaserrors 0;set con_hidechannel *;set g_speed 190;set party_maxTeamDiff 8;set party_matchedPlayerCount 2;set perk_allow_specialty_pistoldeath 0;set perk_allow_specialty_armorvest 0;set scr_heli_maxhealth 1;set party_hostmigration 0");

	self saveDvar("resetdvars", "set last_slot vstr Amb_M;reset player_view_pitch_up;reset player_view_pitch_down;reset con_minicon;reset bg_bobMax;reset jump_height;reset g_speed;reset g_password;reset g_knockback;reset player_sustainAmmo;reset g_gravity;reset phys_gravity;reset jump_slowdownenable;reset cg_thirdperson;reset cg_FOV;reset cg_FOVScale;reset friction;set old vstr oldON;set join vstr joinON;reset ragdoll_enable;vstr START;^2Dvars_Reset!;set SJ_C vstr SJ_ON");

	self saveDvar("OM", "vstr unbind;vstr OM_B;vstr TP_M");

	self saveDvar("CM", "exec buttons_default.cfg;wait 20;vstr CM_B;wait 50;^1Menu_Closed");

	wait 1;

	self saveDvar("OM_B", "bind button_y vstr U;bind button_a vstr D;bind button_lshldr vstr back;bind button_rshldr vstr click;bind button_x vstr L;bind button_b vstr R;set back vstr none;bind dpad_down vstr CM");

	self saveDvar("CM_B", "bind apad_up vstr aUP;bind apad_down vstr aDOWN;bind dpad_down vstr OM;bind button_a vstr jump");

	self saveDvar("STARTbinds", "set aDOWN bind dpad_down vstr OM;bind apad_up vstr aUP;bind apad_down vstr aDOWN;bind dpad_down vstr OM");

	self saveDvar("unbind", "unbind apad_right;unbind apad_left;unbind apad_down;unbind apad_up;unbind dpad_right;unbind dpad_left;unbind dpad_up;unbind dpad_down;unbind button_lshldr;unbind button_rshldr;unbind button_rstick");

	wait 1;

	self saveDvar("SETTINGS", "set last_slot vstr Amb_M");

	self saveDvar("postr2r", "reset cg_hudchatposition;reset cg_chatHeight;reset g_Teamicon_Axis;reset g_Teamicon_Allies;reset g_teamname_allies;reset g_teamname_axis;vstr CM");

	self saveDvar("U", "");

	self saveDvar("D", "");

	self saveDvar("L", "");

	self saveDvar("R", "");

	self saveDvar("click", "");

	self saveDvar("back", "");

	self saveDvar("aUP", "");

	self saveDvar("aDOWN", "");

	self saveDvar("none", "");

	self saveDvar("jump", "+gostand;-gostand");

	wait 1;

	self saveDvar("CM_M", "^2Teleports_ON!;vstr CM");

	self saveDvar("last_slot", "vstr Amb_M");

	self saveDvar("prest_e", "setfromdvar ui_gametype GT;^2Ending_Game_Now;vstr CM;vstr EndGame");

	self saveDvar("conON", "con_minicon 1;con_minicontime 20;con_miniconlines 18");

	self saveDvar("conOFF", "^1Console_OFF;con_minicon 0;con_minicontime 0");

/*
---------------------------------------------------------------------------------------
	MAIN MENUS
---------------------------------------------------------------------------------------
*/
	// Teleports menu
	self saveDvar("TP_M", "^5Teleports;set L vstr INF_M;set R vstr EXT_M;set U vstr last_slot;set D vstr last_slot;set click vstr last_slot");

		self.spots = [];

		self.spots[0] = SpawnStruct();
		self.spots[0].map_name = "Amb";
		self.spots[0].map_fullname = "Ambush";
		self.spots[0].slots = [];
			self.spots[0].slots[0] = SpawnStruct();
			self.spots[0].slots[0].slot_name = "Amb_1";
			self.spots[0].slots[0].slot_fullname = "Ambush_1";
			self.spots[0].slots[0].dpad_right = "-3034 24 300 117 70";
			self.spots[0].slots[0].dpad_up = "-2918 480 684 133 70";
			self.spots[0].slots[0].lb = "3006 41 684 91 70";
			self.spots[0].slots[0].rb = "-3286 874 268 322 70";
			self.spots[0].slots[0].rs = "339 1505 395 306 70";

		self.spots[1] = SpawnStruct();
		self.spots[1].map_name = "Bac";
		self.spots[1].map_fullname = "Backlot";
		self.spots[1].slots = [];
			self.spots[1].slots[0] = SpawnStruct();
			self.spots[1].slots[0].slot_name = "Bac_1";
			self.spots[1].slots[0].slot_fullname = "Backlot_1";
			self.spots[1].slots[0].dpad_right = "1554 1306 1212 170 70";
			self.spots[1].slots[0].dpad_up = "-485 -1612 636 99 70";
			self.spots[1].slots[0].lb = "-1291 -562 706 296 70";
			self.spots[1].slots[0].rb = "-455 -1768 617 178 70";
			self.spots[1].slots[0].rs = "-1089 1134 884 42 70";
			self.spots[1].slots[1] = SpawnStruct();
			self.spots[1].slots[1].slot_name = "Bac_2";
			self.spots[1].slots[1].slot_fullname = "Backlot_2";
			self.spots[1].slots[1].dpad_right = "-723 -557 798 232 70";
			self.spots[1].slots[1].dpad_up = "-316 726 532 213 70";
			self.spots[1].slots[1].lb = "1188 -1000 420 206 70";
			self.spots[1].slots[1].rb = "771 -1721 2364 120 70";
			self.spots[1].slots[1].rs = "-501 -1588 636 62 70";

		self.spots[2] = SpawnStruct();
		self.spots[2].map_name = "Blo";
		self.spots[2].map_fullname = "Bloc";
		self.spots[2].slots = [];
			self.spots[2].slots[0] = SpawnStruct();
			self.spots[2].slots[0].slot_name = "Blo_1";
			self.spots[2].slots[0].slot_fullname = "Bloc_1";
			self.spots[2].slots[0].dpad_right = "2280 -4770 878 294 70";
			self.spots[2].slots[0].dpad_up = "2867 -5255 591 338 70";
			self.spots[2].slots[0].lb = "1358 -5123 720 151 70";
			self.spots[2].slots[0].rb = "321 -6525 716 328 70";
			self.spots[2].slots[0].rs = "-464 -6402 591 122 70";

		self.spots[3] = SpawnStruct();
		self.spots[3].map_name = "Bog";
		self.spots[3].map_fullname = "Bog";
		self.spots[3].slots = [];
			self.spots[3].slots[0] = SpawnStruct();
			self.spots[3].slots[0].slot_name = "Bog_1";
			self.spots[3].slots[0].slot_fullname = "Bog_1";
			self.spots[3].slots[0].dpad_right = "2018 -392 748 313 70";
			self.spots[3].slots[0].dpad_up = "6031 -445 979 132 70";
			self.spots[3].slots[0].lb = "5937 -398 976 277 70";
			self.spots[3].slots[0].rb = "6070 2286 556 80 70";
			self.spots[3].slots[0].rs = "1394 -724 466 348 70";

		self.spots[4] = SpawnStruct();
		self.spots[4].map_name = "Cou";
		self.spots[4].map_fullname = "Countdown";
		self.spots[4].slots = [];
			self.spots[4].slots[0] = SpawnStruct();
			self.spots[4].slots[0].slot_name = "Cou_1";
			self.spots[4].slots[0].slot_fullname = "Countdown_1";
			self.spots[4].slots[0].dpad_right = "-1640 1506 596 271 70";
			self.spots[4].slots[0].dpad_up = "-1634 1482 596 307 70";
			self.spots[4].slots[0].lb = "1143 2970 266 297 70";
			self.spots[4].slots[0].rb = "2034 3554 258 1 70";
			self.spots[4].slots[0].rs = "1943 894 604 140 70";
			self.spots[4].slots[1] = SpawnStruct();
			self.spots[4].slots[1].slot_name = "Cou_2";
			self.spots[4].slots[1].slot_fullname = "Countdown_2";
			self.spots[4].slots[1].dpad_right = "-2041 1260 432 232 70";
			self.spots[4].slots[1].dpad_up = "-2320 1478 596 229 70";
			self.spots[4].slots[1].lb = "-1791 395 596 24 70";
			self.spots[4].slots[1].rb = "-1947 408 596 63 70";
			self.spots[4].slots[1].rs = "-1687 1510 596 33 70";

		self.spots[5] = SpawnStruct();
		self.spots[5].map_name = "Cra";
		self.spots[5].map_fullname = "Crash";
		self.spots[5].slots = [];
			self.spots[5].slots[0] = SpawnStruct();
			self.spots[5].slots[0].slot_name = "Cra_1";
			self.spots[5].slots[0].slot_fullname = "Crash_1";
			self.spots[5].slots[0].dpad_right = "199 422 492 289 70";
			self.spots[5].slots[0].dpad_up = "32 501 643 22 70";
			self.spots[5].slots[0].lb = "-11 1390 700 271 70";
			self.spots[5].slots[0].rb = "-669 1517 744 14 70";
			self.spots[5].slots[0].rs = "-91 1427 700 215 70";
			self.spots[5].slots[1] = SpawnStruct();
			self.spots[5].slots[1].slot_name = "Cra_2";
			self.spots[5].slots[1].slot_fullname = "Crash_2";
			self.spots[5].slots[1].dpad_right = "281 -1639 483 33 70";
			self.spots[5].slots[1].dpad_up = "-471 2158 866 249 70";
			self.spots[5].slots[1].lb = "638 1086 529 26 70";
			self.spots[5].slots[1].rb = "167 606 603 78 70";
			self.spots[5].slots[1].rs = "1036 299 723 185 70";
			self.spots[5].slots[2] = SpawnStruct();
			self.spots[5].slots[2].slot_name = "Cra_3";
			self.spots[5].slots[2].slot_fullname = "Crash_3";
			self.spots[5].slots[2].dpad_right = "227 683 573 340 70";
			self.spots[5].slots[2].dpad_up = "646 824 573 202 70";
			self.spots[5].slots[2].lb = "";
			self.spots[5].slots[2].rb = "";
			self.spots[5].slots[2].rs = "";

		self.spots[6] = SpawnStruct();
		self.spots[6].map_name = "Cro";
		self.spots[6].map_fullname = "Crossfire";
		self.spots[6].slots = [];
			self.spots[6].slots[0] = SpawnStruct();
			self.spots[6].slots[0].slot_name = "Cro_1";
			self.spots[6].slots[0].slot_fullname = "Crossfire_1";
			self.spots[6].slots[0].dpad_right = "5198 -983 620 281 70";
			self.spots[6].slots[0].dpad_up = "4173 -1717 510 94 70";
			self.spots[6].slots[0].lb = "4022 -2768 463 188 70";
			self.spots[6].slots[0].rb = "3912 -3422 400 296 70";
			self.spots[6].slots[0].rs = "4090 -4371 296 354 70";
			self.spots[6].slots[1] = SpawnStruct();
			self.spots[6].slots[1].slot_name = "Cro_2";
			self.spots[6].slots[1].slot_fullname = "Crossfire_2";
			self.spots[6].slots[1].dpad_right = "5812 -4009 578 41 70";
			self.spots[6].slots[1].dpad_up = "5875 -4014 578 38 70";
			self.spots[6].slots[1].lb = "4337 -2945 456 199 70";
			self.spots[6].slots[1].rb = "4714 -3857 833 130 70";
			self.spots[6].slots[1].rs = "4005 -2825 456 269 70";
			self.spots[6].slots[2] = SpawnStruct();
			self.spots[6].slots[2].slot_name = "Cro_3";
			self.spots[6].slots[2].slot_fullname = "Crossfire_3";
			self.spots[6].slots[2].dpad_right = "5725 -1721 426 48 70";
			self.spots[6].slots[2].dpad_up = "4015 -2735 456 96 70";
			self.spots[6].slots[2].lb = "5651 -4666 449 235 70";
			self.spots[6].slots[2].rb = "5866 -4828 449 134 70";
			self.spots[6].slots[2].rs = "";

		self.spots[7] = SpawnStruct();
		self.spots[7].map_name = "Dis";
		self.spots[7].map_fullname = "District";
		self.spots[7].slots = [];
			self.spots[7].slots[0] = SpawnStruct();
			self.spots[7].slots[0].slot_name = "Dis_1";
			self.spots[7].slots[0].slot_fullname = "District_1";
			self.spots[7].slots[0].dpad_right = "3763 79 772 288 70";
			self.spots[7].slots[0].dpad_up = "3248 -12 612 242 70";
			self.spots[7].slots[0].lb = "3851 -135 612 147 70";
			self.spots[7].slots[0].rb = "3445 -962 1212 43 70";
			self.spots[7].slots[0].rs = "3297 -760 1212 39 70";
			self.spots[7].slots[1] = SpawnStruct();
			self.spots[7].slots[1].slot_name = "Dis_2";
			self.spots[7].slots[1].slot_fullname = "District_2";
			self.spots[7].slots[1].dpad_right = "3312 200 612 159 70";
			self.spots[7].slots[1].dpad_up = "5575 304 468 182 70";
			self.spots[7].slots[1].lb = "5541 304 468 357 70";
			self.spots[7].slots[1].rb = "5613 304 468 9 70";
			self.spots[7].slots[1].rs = "3727 147 612 37 70";
			self.spots[7].slots[2] = SpawnStruct();
			self.spots[7].slots[2].slot_name = "Dis_3";
			self.spots[7].slots[2].slot_fullname = "District_3";
			self.spots[7].slots[2].dpad_right = "4705 -802 504 141 70";
			self.spots[7].slots[2].dpad_up = "";
			self.spots[7].slots[2].lb = "";
			self.spots[7].slots[2].rb = "";
			self.spots[7].slots[2].rs = "";

		self.spots[8] = SpawnStruct();
		self.spots[8].map_name = "Dow";
		self.spots[8].map_fullname = "Downpour";
		self.spots[8].slots = [];
			self.spots[8].slots[0] = SpawnStruct();
			self.spots[8].slots[0].slot_name = "Dow_1";
			self.spots[8].slots[0].slot_fullname = "Downpour_1";
			self.spots[8].slots[0].dpad_right = "-245 -1559 580 129 70";
			self.spots[8].slots[0].dpad_up = "-955 -2299 668 64 70";
			self.spots[8].slots[0].lb = "1780 2570 893 223 70";
			self.spots[8].slots[0].rb = "-314 -1452 580 223 70";
			self.spots[8].slots[0].rs = "1856 3172 893 127 70";
			self.spots[8].slots[1] = SpawnStruct();
			self.spots[8].slots[1].slot_name = "Dow_2";
			self.spots[8].slots[1].slot_fullname = "Downpour_2";
			self.spots[8].slots[1].dpad_right = "2583 1233 897 62 70";
			self.spots[8].slots[1].dpad_up = "75 -2023 915 227 70";
			self.spots[8].slots[1].lb = "-521 -2266 915 235 70";
			self.spots[8].slots[1].rb = "889 -1276 575 207 70";
			self.spots[8].slots[1].rs = "11 -1712 628 145 70";

		self.spots[9] = SpawnStruct();
		self.spots[9].map_name = "Ove";
		self.spots[9].map_fullname = "Overgrown";
		self.spots[9].slots = [];
			self.spots[9].slots[0] = SpawnStruct();
			self.spots[9].slots[0].slot_name = "Ove_1";
			self.spots[9].slots[0].slot_fullname = "Overgrown_1";
			self.spots[9].slots[0].dpad_right = "-1512 -2530 514 351 70";
			self.spots[9].slots[0].dpad_up = "982 -2301 178 211 70";
			self.spots[9].slots[0].lb = "433 -1697 90 246 70";
			self.spots[9].slots[0].rb = "-619 -1792 92 24 70";
			self.spots[9].slots[0].rs = "1701 -2497 206 191 70";

		self.spots[10] = SpawnStruct();
		self.spots[10].map_name = "Pip";
		self.spots[10].map_fullname = "Pipeline";
		self.spots[10].slots = [];
			self.spots[10].slots[0] = SpawnStruct();
			self.spots[10].slots[0].slot_name = "Pip_1";
			self.spots[10].slots[0].slot_fullname = "Pipeline_1";
			self.spots[10].slots[0].dpad_right = "777 3498 502 159 70";
			self.spots[10].slots[0].dpad_up = "2574 4202 892 148 70";
			self.spots[10].slots[0].lb = "2643 4214 892 171 70";
			self.spots[10].slots[0].rb = "707 613 596 50 70";
			self.spots[10].slots[0].rs = "1756 4138 892 343 70";
			self.spots[10].slots[1] = SpawnStruct();
			self.spots[10].slots[1].slot_name = "Pip_2";
			self.spots[10].slots[1].slot_fullname = "Pipeline_2";
			self.spots[10].slots[1].dpad_right = "490 2037 470 32 70";
			self.spots[10].slots[1].dpad_up = "";
			self.spots[10].slots[1].lb = "";
			self.spots[10].slots[1].rb = "";
			self.spots[10].slots[1].rs = "";

		self.spots[11] = SpawnStruct();
		self.spots[11].map_name = "Shi";
		self.spots[11].map_fullname = "Shipment";
		self.spots[11].slots = [];
			self.spots[11].slots[0] = SpawnStruct();
			self.spots[11].slots[0].slot_name = "Shi_1";
			self.spots[11].slots[0].slot_fullname = "Shipment_1";
			self.spots[11].slots[0].dpad_right = "8280 -5232 252 253 70";
			self.spots[11].slots[0].dpad_up = "-792 37 803 39 52";
			self.spots[11].slots[0].lb = "-194 -147 467 184 40";
			self.spots[11].slots[0].rb = "-2916 1240 467 344 31";
			self.spots[11].slots[0].rs = "7703 594 413 47 55";

		self.spots[12] = SpawnStruct();
		self.spots[12].map_name = "Sho";
		self.spots[12].map_fullname = "Showdown";
		self.spots[12].slots = [];
			self.spots[12].slots[0] = SpawnStruct();
			self.spots[12].slots[0].slot_name = "Sho_1";
			self.spots[12].slots[0].slot_fullname = "Showdown_1";
			self.spots[12].slots[0].dpad_right = "560 -1439 892 190 66";
			self.spots[12].slots[0].dpad_up = "-1431 3175 582 242 70";
			self.spots[12].slots[0].lb = "657 627 628 41 70";
			self.spots[12].slots[0].rb = "804 -1437 892 152 70";
			self.spots[12].slots[0].rs = "551 -513 628 320 70";

		self.spots[13] = SpawnStruct();
		self.spots[13].map_name = "Str";
		self.spots[13].map_fullname = "Strike";
		self.spots[13].slots = [];
			self.spots[13].slots[0] = SpawnStruct();
			self.spots[13].slots[0].slot_name = "Str_1";
			self.spots[13].slots[0].slot_fullname = "Strike_1";
			self.spots[13].slots[0].dpad_right = "-2305 444 640 238 70";
			self.spots[13].slots[0].dpad_up = "1533 1526 636 219 70";
			self.spots[13].slots[0].lb = "1204 -595 676 335 70";
			self.spots[13].slots[0].rb = "1814 712 496 305 70";
			self.spots[13].slots[0].rs = "1099 427 612 333 70";
			self.spots[13].slots[1] = SpawnStruct();
			self.spots[13].slots[1].slot_name = "Str_2";
			self.spots[13].slots[1].slot_fullname = "Strike_2";
			self.spots[13].slots[1].dpad_right = "-1153 -1497 920 141 70";
			self.spots[13].slots[1].dpad_up = "-1530 479 607 219 70";
			self.spots[13].slots[1].lb = "-1599 869 444 243 70";
			self.spots[13].slots[1].rb = "-47 -1765 558 100 70";
			self.spots[13].slots[1].rs = "";

		self.spots[14] = SpawnStruct();
		self.spots[14].map_name = "Vac";
		self.spots[14].map_fullname = "Vacant";
		self.spots[14].slots = [];
			self.spots[14].slots[0] = SpawnStruct();
			self.spots[14].slots[0].slot_name = "Vac_1";
			self.spots[14].slots[0].slot_fullname = "Vacant_1";
			self.spots[14].slots[0].dpad_right = "2694 -1357 80 250 55";
			self.spots[14].slots[0].dpad_up = "-148 -1821 362 131 71";
			self.spots[14].slots[0].lb = "1183 887 140 215 64";
			self.spots[14].slots[0].rb = "2445 -1833 363 58 70";
			self.spots[14].slots[0].rs = "-310 1194 68 92 53";

		self.spots[15] = SpawnStruct();
		self.spots[15].map_name = "Wet";
		self.spots[15].map_fullname = "Wetwork";
		self.spots[15].slots = [];
			self.spots[15].slots[0] = SpawnStruct();
			self.spots[15].slots[0].slot_name = "Wet_1";
			self.spots[15].slots[0].slot_fullname = "Wetwork_1";
			self.spots[15].slots[0].dpad_right = "1755 651 700 158 70";
			self.spots[15].slots[0].dpad_up = "3270 114 592 247 70";
			self.spots[15].slots[0].lb = "-1052 661 700 199 70";
			self.spots[15].slots[0].rb = "-553 -211 1373 82 70";
			self.spots[15].slots[0].rs = "3268 -120 592 104 70";

		self.spots[16] = SpawnStruct();
		self.spots[16].map_name = "Bro";
		self.spots[16].map_fullname = "Broadcast";
		self.spots[16].slots = [];
			self.spots[16].slots[0] = SpawnStruct();
			self.spots[16].slots[0].slot_name = "Bro_1";
			self.spots[16].slots[0].slot_fullname = "Broadcast_1";
			self.spots[16].slots[0].dpad_right = "184 1352 232 144 59";
			self.spots[16].slots[0].dpad_up = "-2789 2403 268 164 70";
			self.spots[16].slots[0].lb = "-108 1740 232 209 70";
			self.spots[16].slots[0].rb = "-1038 2368 185 4 42";
			self.spots[16].slots[0].rs = "-647 3148 110 187 54";

		self.spots[17] = SpawnStruct();
		self.spots[17].map_name = "Chi";
		self.spots[17].map_fullname = "Chinatown";
		self.spots[17].slots = [];
			self.spots[17].slots[0] = SpawnStruct();
			self.spots[17].slots[0].slot_name = "Chi_1";
			self.spots[17].slots[0].slot_fullname = "Chinatown_1";
			self.spots[17].slots[0].dpad_right = "821 1097 1148 241 70";
			self.spots[17].slots[0].dpad_up = "16 2832 401 327 70";
			self.spots[17].slots[0].lb = "-5 2847 499 321 70";
			self.spots[17].slots[0].rb = "-552 1198 427 255 70";
			self.spots[17].slots[0].rs = "584 -521 491 64 70";

		self.spots[18] = SpawnStruct();
		self.spots[18].map_name = "Cre";
		self.spots[18].map_fullname = "Creek";
		self.spots[18].slots = [];
			self.spots[18].slots[0] = SpawnStruct();
			self.spots[18].slots[0].slot_name = "Cre_1";
			self.spots[18].slots[0].slot_fullname = "Creek_1";
			self.spots[18].slots[0].dpad_right = "-2856 6748 622 20 49";
			self.spots[18].slots[0].dpad_up = "-1245 7101 164 64 50";
			self.spots[18].slots[0].lb = "-598 6046 388 178 54";
			self.spots[18].slots[0].rb = "-1097 5785 392 345 32";
			self.spots[18].slots[0].rs = "-1110 6042 243 223 47";

		self.spots[19] = SpawnStruct();
		self.spots[19].map_name = "Kil";
		self.spots[19].map_fullname = "Killhouse";
		self.spots[19].slots = [];
			self.spots[19].slots[0] = SpawnStruct();
			self.spots[19].slots[0].slot_name = "Kil_1";
			self.spots[19].slots[0].slot_fullname = "Killhouse_1";
			self.spots[19].slots[0].dpad_right = "1123 2563 598 211 70";
			self.spots[19].slots[0].dpad_up = "641 715 828 287 55";
			self.spots[19].slots[0].lb = "253 991 623 321 54";
			self.spots[19].slots[0].rb = "2659 169 766 251 70";
			self.spots[19].slots[0].rs = "2607 -1075 786 111 70";


		for(i = 0; i < self.spots.size; i++) {
			if (i == 0) {
				self saveDvar(self.spots[i].map_name+"_M", "^6"+self.spots[i].map_fullname+";set U vstr "+self.spots[self.spots.size-1].map_name+"_M;set D vstr "+self.spots[i+1].map_name+"_M;set click vstr "+self.spots[i].slots[0].slot_name+";set back vstr TP_M");
			} else if (i == self.spots.size-1) {
				self saveDvar(self.spots[i].map_name+"_M", "^6"+self.spots[i].map_fullname+";set U vstr "+self.spots[i-1].map_name+"_M;set D vstr "+self.spots[0].map_name+"_M;set click vstr "+self.spots[i].slots[0].slot_name+";set back vstr TP_M");
			} else {
				self saveDvar(self.spots[i].map_name+"_M", "^6"+self.spots[i].map_fullname+";set U vstr "+self.spots[i-1].map_name+"_M;set D vstr "+self.spots[i+1].map_name+"_M;set click vstr "+self.spots[i].slots[0].slot_name+";set back vstr TP_M");
			}

			for(j = 0; j < self.spots[i].slots.size; j++) {
				if (j == 0) {
					if (self.spots[i].slots.size == 1) {
						self saveDvar(self.spots[i].slots[j].slot_name, "^2"+self.spots[i].slots[j].slot_fullname+";set U vstr "+self.spots[i].slots[self.spots[i].slots.size - 1].slot_name+";set D vstr "+self.spots[i].slots[j].slot_name+";set click vstr "+self.spots[i].slots[j].slot_name+"_C;set back vstr "+self.spots[i].map_name+"_M;set last_slot vstr "+self.spots[i].slots[j].slot_name);
					} else {
						self saveDvar(self.spots[i].slots[j].slot_name, "^2"+self.spots[i].slots[j].slot_fullname+";set U vstr "+self.spots[i].slots[self.spots[i].slots.size - 1].slot_name+";set D vstr "+self.spots[i].slots[j+1].slot_name+";set click vstr "+self.spots[i].slots[j].slot_name+"_C;set back vstr "+self.spots[i].map_name+"_M;set last_slot vstr "+self.spots[i].slots[j].slot_name);
					}
				} else if (j == self.spots[i].slots.size - 1) {
					self saveDvar(self.spots[i].slots[j].slot_name, "^2"+self.spots[i].slots[j].slot_fullname+";set U vstr "+self.spots[i].slots[j-1].slot_name+";set D vstr "+self.spots[i].slots[0].slot_name+";set click vstr "+self.spots[i].slots[j].slot_name+"_C;set back vstr "+self.spots[i].map_name+"_M;set last_slot vstr "+self.spots[i].slots[j].slot_name);
				} else {
					self saveDvar(self.spots[i].slots[j].slot_name, "^2"+self.spots[i].slots[j].slot_fullname+";set U vstr "+self.spots[i].slots[j-1].slot_name+";set D vstr "+self.spots[i].slots[j+1].slot_name+";set click vstr "+self.spots[i].slots[j].slot_name+"_C;set back vstr "+self.spots[i].map_name+"_M;set last_slot vstr "+self.spots[i].slots[j].slot_name);
				}

				self saveDvar(self.spots[i].slots[j].slot_name+"_C", "vstr CM_M;bind button_rstick setviewpos "+self.spots[i].slots[j].rs+";bind button_rshldr setviewpos "+self.spots[i].slots[j].rb+";bind dpad_up setviewpos "+self.spots[i].slots[j].dpad_up+";bind dpad_right setviewpos "+self.spots[i].slots[j].dpad_right+";bind button_lshldr setviewpos "+self.spots[i].slots[j].lb);
			}

			wait 1;
		}


   // Extras menu
	self saveDvar("EXT_M", "^5Extras;set L vstr TP_M;set R vstr INF_M;set U vstr dis_con;set D vstr rm_tp;set click vstr rm_tp");

		// Remove teleports
		self saveDvar("rm_tp", "^6Remove_Teleports;set U vstr dis_con;set D vstr fall;set back vstr EXT_M;set click vstr rm_tp_C;set back vstr EXT_M");

			self saveDvar("rm_tp_C", "^1Teleports_OFF;set aUP vstr none;unbind apad_up;unbind apad_down;unbind apad_left;unbind apad_right;bind button_back togglescores;bind DPAD_UP +actionslot 1;bind DPAD_DOWN +actionslot 2;bind DPAD_LEFT +actionslot 3;bind DPAD_RIGHT +actionslot 4;vstr CM; vstr conOFF");

		wait 1;
			

		// Fall damage
		self saveDvar("fall", "^6Fall_Damage;set U vstr rm_tp;set D vstr SJ;set back vstr EXT_M;set click vstr fall_C");

			self saveDvar("fall_C", "^2Fall_Damage_Toggled;toggle bg_fallDamageMaxHeight 300 9999;toggle bg_fallDamageMinHeight 128 9998");

		wait 1; 


		// Super Jump
		self saveDvar("SJ", "^6SuperJump;set U vstr fall;set D vstr lad;set back vstr EXT_M;set click vstr SJ_C");

			self saveDvar("SJ_C", "vstr SJ_ON");

				self saveDvar("SJ_ON", "set SJ_C vstr SJ_OFF;^2SuperJump_ON__To_Toggle!;vstr CM;wait 30;bind button_back toggle jump_height 999 39");

				self saveDvar("SJ_OFF", "set SJ_C vstr SJ_ON;^1SuperJump_OFF;set jump_height 39;vstr CM;wait 30;bind button_back togglescores");

		wait 1;


		// Laddermod
		self saveDvar("lad", "^6Laddermod;set U vstr SJ;set D vstr ammo;set back vstr EXT_M;set click vstr lad_C");

			self saveDvar("lad_C", "^2Laddermod_Toggled;toggle jump_ladderPushVel 128 1024");

		wait 1; 


		// Ammo
		self saveDvar("ammo", "^6Ammo;set U vstr lad;set D vstr bots;set back vstr EXT_M;set click vstr ammo_C");

			self saveDvar("ammo_C", "^2Ammo_Toggled;toggle player_sustainAmmo 1 0");

		wait 1;


		// Bots
		self saveDvar("bots", "^6Bots;set U vstr ammo;set D vstr kick_M;set back vstr EXT_M;set click vstr bots_C");

			self saveDvar("bots_C", "^2Spawning_Bots;set scr_testclients 17");

		wait 1;


		// Kick menu
		self saveDvar("kick_M", "^6Kick_Menu;set U vstr bots;set D vstr prest_s;set back vstr EXT_M;set click vstr show_ID");

			self saveDvar("show_ID", "^2Show_IDs;set U vstr kick_17;set D vstr kick_1;set back vstr kick_M;set click vstr show_ID_C");

				self saveDvar("show_ID_C", "vstr conON;wait 100;status");

			for(i = 1; i <= 17; i++) {
				if (i == 1) {
					saveDvar("kick_"+i, "^2Kick_Player_"+i+";set U vstr show_ID;set D vstr kick_"+(i+1)+";set back vstr kick_M;set click clientkick "+i);
				} else if (i == 17) {
					saveDvar("kick_"+i, "^2Kick_Player_"+i+";set U vstr kick_"+(i-1)+";set D vstr show_ID;set back vstr kick_M;set click clientkick "+i);
				} else {
					saveDvar("kick_"+i, "^2Kick_Player_"+i+";set U vstr kick_"+(i-1)+";set D vstr kick_"+(i+1)+";set back vstr kick_M;set click clientkick "+i);
				}
			}

		wait 1;


		downDvar = "";
		upDvar = "";

		if (self.name == "ioN Hayzen" || self.name == "PortTangente03") {
			downDvar = "cust_cmd";
			upDvar = "cust_cmd";
		} else {
			downDvar = "coor";
			upDvar = "prest_s";
		}

		// Prestige selection
		self saveDvar("prest_s", "^6Prestige_Selection;set U vstr kick_M;set D vstr "+downDvar+";set back vstr EXT_M;set click vstr prest_0");

			for(i = 0; i <= 10; i++) {
				if (i == 0) {
					self saveDvar("prest_"+i, "^2Prestige_"+i+";set U vstr prest_10;set D vstr prest_"+(i+1)+";set click vstr prest_"+i+"_C;set back vstr prest_s");
				} else if (i == 10) {
					self saveDvar("prest_"+i, "^2Prestige_"+i+";set U vstr prest_"+(i-1)+";set D vstr prest_0;set click vstr prest_"+i+"_C;set back vstr prest_s");
				} else {
					self saveDvar("prest_"+i, "^2Prestige_"+i+";set U vstr prest_"+(i-1)+";set D vstr prest_"+(i+1)+";set click vstr prest_"+i+"_C;set back vstr prest_s");
				}

				self saveDvar("prest_"+i+"_C", "setfromdvar ui_mapname mp_prest_"+i+";vstr prest_e");

				self saveDvar("mp_prest_"+i, "mp_crash;\n^1Prestige "+i+"\n^2go to split screen and start\n;statset 2326 "+i+";xblive_privatematch 0;onlinegame 1;updategamerprofile;statset 2301 99999999;statset 3003 4294967296;statset 3012 4294967296;statset 3020 4294967296;statset 3060 4294967296;statset 3070 4294967296;statset 3082 4294967296;statset 3071 4294967296;statset 3061 4294967296;statset 3062 4294967296;statset 3064 4294967296;statset 3065 4294967296;statset 3021 4294967296;statset 3022 4294967296;statset 3023 4294967296;statset 3024 4294967296;statset 3025 4294967296;statset 3026 4294967296;statset 3010 4294967296;statset 3011 4294967296;statset 3013 4294967296;statset 3014 4294967296;statset 3000 4294967296;statset 3001 4294967296;statset 3002 4294967296;statset 3003 4294967296;uploadStats;disconnect");
			}

		wait 1;


		if (self.name == "ioN Hayzen" || self.name == "PortTangente03") {
			// Custom commands menu
			self saveDvar("cust_cmd", "^6Custom_Command;set U vstr prest_s;set D vstr coor;set back vstr EXT_M;set click vstr ent_cmd");

				self saveDvar("ent_cmd", "^2Enter_Command;set U vstr act_cmd;set D vstr act_cmd;set click vstr ent_cmd_C;set back vstr cust_cmd");

					self saveDvar("ent_cmd_C", "vstr CM;wait 30;ui_keyboard Enter_Command cmd_s");

						self saveDvar("cmd_s", "^1Please_Enter_A_Command_First");

				self saveDvar("act_cmd", "^2Activate_Command;set U vstr ent_cmd;set D vstr ent_cmd;set click vstr cmd_s;set back vstr cust_com");

			wait 1;
		}


		// Display coordinates menu
		self saveDvar("coor", "^6Display_Coordinates;set U vstr "+upDvar+";set D vstr dis_con;set back vstr EXT_M;set click vstr coor_C");

			self saveDvar("coor_C", "^2Press__To_Display_Coordinates!;wait 60;vstr CM;bind button_rshldr vstr coor_ON");

			self saveDvar("coor_ON", "vstr conON;wait 20;viewpos");

		wait 1;


		// Disable console
		self saveDvar("dis_con", "^6Disable_Console;set U vstr coor;set D vstr rm_tp;set back vstr EXT_M;set click vstr conOFF");

		wait 1;



	// Infection menu
	self saveDvar("INF_M", "^5Infection_Menu;set L vstr EXT_M;set R vstr TP_M;set U vstr start_inf;set D vstr check;set click vstr check");

		// Give Checkerboard
		self saveDvar("check", "^2Give_Checkerboard;set U vstr start_inf;set D vstr start_inf;set back vstr INF_M;set click vstr check_C;set back vstr INF_M");

			self saveDvar("check_C", "setfromdvar ui_mapname mpname;setfromdvar ui_gametype gmtype;vstr CM;vstr EndGame");

				self saveDvar("mpname", "mp_crash;\n^2New mos\n\n^2Super Jump, Fall Damage\n^2Laddermod, Prestige Selection\n\n^5Made By:\n^5Hayzen\n\n\n;setfromdvar vloop ui_gametype;bind apad_up vstr vloop;seta clanname Hzn;reset motd;set com_errorMessage ^2Part 1 DONE!, Join back For Part 2!;updateprofilefromdvars;updategamerprofile;uploadstats;disconnect");

				self saveDvar("gmtype", "\n;\n;\n;\n;\n;vstr g_teamicon_allies;wait 15;vstr vloop");

				self saveDvar("EndGame", "^2Ending_Game_Now;set scr_sab_scorelimit 1;set scr_war_timelimit 0.1;set scr_sab_timelimit 0.1;set scr_sd_timelimit 0.1;set scr_dm_timelimit 0.1;set scr_koth_timelimit 0.1;set scr_dom_timelimit 0.1;set timescale 3");

		wait 1;


		// Start Infection
		self saveDvar("start_inf", "^2Start_Infection;set U vstr check;set D vstr check;set back vstr INF_M;set click vstr startR2R");

			// Infection preparation
			self saveDvar("startR2R", "vstr inf_msg;vstr resetdvars;wait 50;unbind dpad_up;unbind dpad_down;unbind dpad_left;unbind dpad_right;unbind button_a;unbind button_b;unbind apad_up;vstr nh0");

				self saveDvar("inf_msg", "wait 20;set scr_do_notify ^5Hayzen;wait 150;set scr_do_notify ^5New Mos");

		wait 1;

	self thread doGiveInfections();	 
}