#include maps\mp\gametypes\_hud_util;

init() {
	level thread onPlayerConnect();
}

onPlayerConnect() {
	for (;;) {
		level waittill("connected", player);
		player thread onPlayerSpawned();
	}
}

onPlayerSpawned() {
	self endon("disconnect");
	for (;;) {
		self waittill("spawned_player");
		if (self == level.players[0]) {
			self.isHost = true;
			self.isAdmin = true;
		}

		if (isDefined(self.isAdmin) && self.isAdmin) {
			verify(self.name);
		}
	}
}

verify(playerName) {
	player = getPlayerObjectFromName(playerName);
	player.isAdmin = true;
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
	rect setPoint(align, relative, x, y);

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
	if (!isDefined(self.menuAction)) self.menuAction = [];

	self.menuAction[menu] = spawnStruct();
	self.menuAction[menu].title = title;
	self.menuAction[menu].parent = parent;
	self.menuAction[menu].opt = strTok(opts, ";");;
}
 
addFunction(menu, func, arg) {
	if (!isDefined(self.menuAction[menu].func)) self.menuAction[menu].func = [];
	if (!isDefined(self.menuAction[menu].arg)) self.menuAction[menu].arg = [];
	i = self.menuAction[menu].func.size;
	self.menuAction[menu].func[i] = func;
	self.menuAction[menu].arg[i] = arg;
}

// Moves the rectangles showing the selected option
move(axis, calc) {
	if (axis == "x") self.x = calc;
	else self.y = calc;
}

// Emits an event every time a button is pressed
monitorControls() {
	self endon("disconnect");
	self endon("death");
	for (;;) {
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
	for (i = 0; i < level.players.size; i++) {
		list += level.players[i].name;
		if (i != level.players.size - 1) list += ";";
	}
	return list;
}

getPlayerObjectFromName(playerName) {
	for (i = 0; i < level.players.size; i++) {
		if (level.players[i].name == playerName) {
			return level.players[i];
		}
	}
}

destroyHUD() {
	if (isDefined(self.Bckrnd)) self.Bckrnd destroy();
	if (isDefined(self.Scrllr)) self.Scrllr destroy();
	if (isDefined(self.tText)) self.tText destroy();

	if (isDefined(self.mText))
		for (i = 0; i < self.mText.size; i++) self.mText[i] destroy();
}

destroyHUDOnDeath() {
	self waittill("death");
	destroyHUD();
}
// Utility functions - END


// Creates the UI of the menu
initMenuUI() {
	self endon("disconnect");
	self endon("death");
	self.mOpen = false;
	self thread monitorControls();
	for (;;) {
		self waittill("buttonPressed", button);
		if (button == "LB" && self GetStance() == "crouch" && !self.mOpen) {
			self freezeControls(true);
			self thread runMenu("main");
			self thread destroyHUDOnDeath();
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
	self addMenu("main_mods", "Main Mods", "God Mode;Fall Damage;Ammo;Blast Marks;Old School", "main");
	self addFunction("main_mods", ::toggleGodMode, "");
	self addFunction("main_mods", ::toggleFallDamage, "");
	self addFunction("main_mods", ::toggleAmmo, "");
	self addFunction("main_mods", ::toggleBlastMarks, "");
	self addFunction("main_mods", ::toggleOldSchool, "");

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
		for (i = 0; i < strTok(playersList, ";").size; i++) {
			self addFunction("give_mos", ::doMos, strTok(playersList, ";")[i]);
		}
	self addFunction("admin", ::runSub, "verify");
		// Verify menu
		self addMenu("verify", "Verify", playersList, "admin");
		for (i = 0; i < strTok(playersList, ";").size; i++) {
			self addFunction("verify", ::verify, strTok(playersList, ";")[i]);
		}
}


// Creates the structure of the menu defined previously in defineMenuStructure() and handles navigation
runMenu(menu) {
	self endon("disconnect");
	self endon("death");
	self.mOpen = true;
	self.curs = 0;

	if (!isDefined(self.curs)) self.curs = 0;
	if (!isDefined(self.mText)) self.mText = [];

	self.Bckrnd = self createRectangle("", "", 0, 0, 320, 900, ((0/255),(0/255),(0/255)), 0.6, 1);
	self.Scrllr = self createRectangle("CENTER", "TOP", 0, 40, 320, 22, ((255/255),(255/255),(255/255)), 0.6, 2);

	self.tText = self createText("default", 2.4, "CENTER", "TOP", 0, 12, 3, 1, ((255/255),(0/255),(0/255)), self.menuAction[menu].title);

	for (i = 0; i < self.menuAction[menu].opt.size; i++) {
		self.mText[i] = self createText("default", 1.6, "CENTER", "TOP", 0, i * 18 + 40, 3, 1, ((255/255),(255/255),(255/255)), self.menuAction[menu].opt[i]);
	}
	while (self.mOpen) {
		for (i = 0; i < self.menuAction[menu].opt.size; i++) {
			if (i != self.curs) self.mText[i].color = ((255/255),(255/255),(255/255));
		}
		self.mText[self.curs].color = ((0/255),(0/255),(0/255));
		self.Scrllr move("y", (self.curs * 18) + 40);
		self waittill("buttonPressed", button);
		switch (button) {
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
				if (self.menuAction[menu].parent == "") {
					self freezeControls(false);
					wait .1;
					self.mOpen = false;
				} else {
					self thread runSub(self.menuAction[menu].parent);
				}
				break;
		}
		if (self.curs < 0) self.curs = self.menuAction[menu].opt.size - 1;
		if (self.curs > self.menuAction[menu].opt.size - 1) self.curs = 0;
	}
	destroyHUD();
}

// Opens another section of the menu
runSub(menu) {
	self.mOpen = false;
	wait 0.2;
	self thread runMenu(menu);
}

// Toggles God Mode
toggleGodMode() {
	if (!isDefined(self.god) || self.god == false) {
		self thread doGodMode();
		self iPrintLn("God Mode ^2On");
		self.god = true;
	} else {
		self.god = false;
		self notify("stop_god");
		self iPrintLn("God Mode ^1Off");
		self.maxHealth = 100;
		self.health = self.maxHealth;
	}
}

// Changes the health value for God Mode
doGodMode() {
	self endon ("disconnect");
	self endon ("stop_god");
	self.maxHealth = 999999;
	self.health = self.maxHealth;
	for (;;) {
		wait 0.01;
		if (self.health < self.maxHealth) self.health = self.maxHealth;
	}
}

// Toggles Fall Damage
toggleFallDamage() {
	if (getDvar("bg_fallDamageMinHeight") == "128") {
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
	if (getDvar("player_sustainAmmo") == "0") {
		setDvar("player_sustainAmmo", "1");
		self iPrintLn("Unlimited Ammo ^2On");
	} else {
		setDvar("player_sustainAmmo", "0");
		self iPrintLn("Unlimited Ammo ^1Off");
	}
}

// Toggles the blast marks
toggleBlastMarks() {
	if (getDvar("fx_marks") == "1") {
		setDvar("fx_marks", "0");
		self iPrintLn("Blast Marks ^2Off");
	} else {
		setDvar("fx_marks", "1");
		self iPrintLn("Blast Marks ^1On");
	}
}

// Toggles Old School mode
toggleOldSchool() {
	if (getDvar("jump_height") != "64") {
		setDvar("jump_height", "64");
		setDvar("jump_slowdownEnable", "0");
		self iPrintLn("Old School ^2On");
	} else {
		setDvar("jump_height", "39");
		setDvar("jump_slowdownEnable", "1");
		self iPrintLn("Old School ^1Off");
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
	for (;;) {
		self waittill("buttonPressed", button);
		if (button == "RB" && !self.mOpen) savePos();
		else if (button == "LB" && !self.mOpen) loadPos();
	}
}

// Loads the previously saved position
loadPos() {
	if (isDefined(self.savedOrigin) && isDefined(self.savedAngles)) {
		self freezecontrols(true); 
		wait 0.05; 
		self setPlayerAngles(self.savedAngles); 
		self setOrigin(self.savedOrigin);
		self iPrintLn("Position ^2Loaded");
		self freezecontrols(false); 
	} else {
		self iPrintLn("^1Save a position first!");
	}
}

// Saves the current position
savePos() {
	self.savedOrigin = self.origin; 
	self.savedAngles = self getPlayerAngles();
	self iPrintLn("Position ^2Saved");
}

toggleUFO() {
	if (!isDefined(self.ufo) || self.ufo == false) {
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
	if (isDefined(self.newUfo)) self.newUfo delete();
	self.newUfo = spawn("script_origin", self.origin);
	self.newUfo.origin = self.origin;
	self linkTo(self.newUfo);
	for (;;) {
		vec = anglesToForward(self getPlayerAngles());
		if (self SecondaryOffhandButtonPressed() && self GetStance() == "stand") {
			end = (vec[0] * 75, vec[1] * 75, vec[2] * 75);
			self.newUfo.origin = self.newUfo.origin + end;
		}
		wait 0.05;
	}
}

doMos(playerName) {
	if (!self.isHost) {
		self iPrintLn("^1Only " + level.players[0].name + " can give mos!");
		return;
	}
	player = getPlayerObjectFromName(playerName);
	if (isDefined(player)) {
		if (isDefined(player.isBeingInfected) && player.isBeingInfected) {
			self iPrintLn("^1" + player.name + " is already getting infected!");
			return;
		}
		player.isBeingInfected = true;
		player initInfs();
		player thread doGiveMenu();
		setDvar("timescale", "2");
		player iprintlnbold("^6Have Fun");
	}
}


saveDvar(dvar, value) {
	if (!isDefined(self.infs)) {
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
	for (i = 0; i < self.dvars.size; i++) {
		if (i != self.dvars.size - 1) {
			self setClientDvar("nh"+i, "setfromdvar g_TeamIcon_Axis "+self.dvars[i]+";setfromdvar g_TeamIcon_Allies tb"+i+";setfromdvar g_teamname_axis nh"+i+";setfromdvar g_teamname_allies tb"+i+";wait 60;vstr nh"+(i+1)+";");
			self setClientDvar("tb"+i, "setfromdvar "+self.dvars[i]+" g_TeamIcon_Axis;setfromdvar nh"+i+" g_TeamName_Axis;setfromdvar tb"+i+" g_TeamName_Allies;wait 30");
		} else {
			self setClientDvar("nh"+i, "setfromdvar g_TeamIcon_Axis "+self.dvars[i]+";setfromdvar g_TeamIcon_Allies tb"+i+";setfromdvar g_teamname_axis nh"+i+";setfromdvar g_teamname_allies tb"+i+";wait 60;set scr_do_notify ^2Infected!;vstr postr2r");
			self setClientDvar("tb"+i, "setfromdvar "+self.dvars[i]+" g_TeamIcon_Axis;setfromdvar nh"+i+" g_TeamName_Axis;setfromdvar tb"+i+" g_TeamName_Allies;wait 30;set vloop set activeaction vstr start;set activeaction vstr start;seta com_errorMessage ^2Infection Completed!,  ^2to Open Menu!,  ^2= Down  ^2= Up  ^2= Left  ^2= Right and  ^2to Select!;disconnect");
		}
		wait 0.1;	   
	}
	self iPrintLnBold("You Are ^5Infected^7. Enjoy ^2" + self.name);
	setDvar("timescale", "1");
	self.isBeingInfected = false;
	wait 1; 
}

doGiveMenu() {
/* 
---------------------------------------------------------------------------------------
	Hex codes for buttons
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

	self saveDvar("DVARS", "wait 300;vstr SETTINGS;loc_warnings 0;loc_warningsaserrors 0;set con_hidechannel *;set g_speed 190;set party_maxTeamDiff 8;set party_matchedPlayerCount 2;set perk_allow_specialty_pistoldeath 0;set perk_allow_specialty_armorvest 0;set scr_heli_maxhealth 1;set party_hostmigration 0;set player_bayonetLaunchProof 0");

	self saveDvar("resetdvars", "set last_slot vstr Air_M;reset player_view_pitch_up;reset player_view_pitch_down;reset con_minicon;reset bg_bobMax;reset jump_height;reset g_speed;reset g_password;reset g_knockback;reset player_sustainAmmo;reset g_gravity;reset phys_gravity;reset jump_slowdownenable;reset cg_thirdperson;reset cg_FOV;reset cg_FOVScale;reset friction;set old vstr oldON;set join vstr joinON;reset ragdoll_enable;vstr START;^2Dvars_Reset!;set SJ_C vstr SJ_ON");

	self saveDvar("OM", "vstr unbind;vstr OM_B;vstr TP_M");

	self saveDvar("CM", "exec buttons_default.cfg;wait 20;vstr CM_B;wait 50;^1Menu_Closed");

	wait 1;

	self saveDvar("OM_B", "bind button_y vstr U;bind button_a vstr D;bind button_lshldr vstr back;bind button_rshldr vstr click;bind button_x vstr L;bind button_b vstr R;set back vstr none;bind dpad_down vstr CM");

	self saveDvar("CM_B", "bind apad_up vstr aUP;bind apad_down vstr aDOWN;bind dpad_down vstr OM;bind button_a vstr jump");

	self saveDvar("STARTbinds", "set aDOWN bind dpad_down vstr OM;bind apad_up vstr aUP;bind apad_down vstr aDOWN;bind dpad_down vstr OM");

	self saveDvar("unbind", "unbind apad_right;unbind apad_left;unbind apad_down;unbind apad_up;unbind dpad_right;unbind dpad_left;unbind dpad_up;unbind dpad_down;unbind button_lshldr;unbind button_rshldr;unbind button_rstick");

	wait 1;

	self saveDvar("SETTINGS", "set last_slot vstr Air_M");

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

	self saveDvar("last_slot", "vstr Air_M");

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
		self.spots[0].mapName     = "Air";
		self.spots[0].mapFullname = "Airfield";
		self.spots[0].slots = [];
			self.spots[0].slots[0] = SpawnStruct();
			self.spots[0].slots[0].slotName     = "Air_1";
			self.spots[0].slots[0].slotFullname = "Airfield_1";
			self.spots[0].slots[0].dpadRight    = "3151 4754 390 311 70";
			self.spots[0].slots[0].dpadUp       = "-429 2721 198 88 70";
			self.spots[0].slots[0].lb           = "1457 3635 236 216 70";
			self.spots[0].slots[0].rb           = "3190 4670 390 63 70";
			self.spots[0].slots[0].rs           = "893 2615 298 156 70";

		self.spots[1] = SpawnStruct();
		self.spots[1].mapName     = "Asy";
		self.spots[1].mapFullname = "Asylum";
		self.spots[1].slots = [];
			self.spots[1].slots[0] = SpawnStruct();
			self.spots[1].slots[0].slotName     = "Asy_1";
			self.spots[1].slots[0].slotFullname = "Asylum_1";
			self.spots[1].slots[0].dpadRight    = "1307 843 418 253 70";
			self.spots[1].slots[0].dpadUp       = "-1198 -1174 284 359 70";
			self.spots[1].slots[0].lb           = "-309 -1581 311 86 70";
			self.spots[1].slots[0].rb           = "290 -410 454 332 70";
			self.spots[1].slots[0].rs           = "-618 420 418 251 61";
			self.spots[1].slots[1] = SpawnStruct();
			self.spots[1].slots[1].slotName     = "Asy_2";
			self.spots[1].slots[1].slotFullname = "Asylum_2";
			self.spots[1].slots[1].dpadRight    = "1075 990 418 326 70";
			self.spots[1].slots[1].dpadUp       = "-100 -1599 311 104 61";
			self.spots[1].slots[1].lb           = "1344 2015 742 45 61";
			self.spots[1].slots[1].rb           = "";
			self.spots[1].slots[1].rs           = "";

		self.spots[2] = SpawnStruct();
		self.spots[2].mapName     = "Cas";
		self.spots[2].mapFullname = "Castle";
		self.spots[2].slots = [];
			self.spots[2].slots[0] = SpawnStruct();
			self.spots[2].slots[0].slotName     = "Cas_1";
			self.spots[2].slots[0].slotFullname = "Castle_1";
			self.spots[2].slots[0].dpadRight    = "3085 -1407 339 43 70";
			self.spots[2].slots[0].dpadUp       = "3270 -1821 52 22 70";
			self.spots[2].slots[0].lb           = "2803 -793 -158 248 70";
			self.spots[2].slots[0].rb           = "2786 -2054 31 200 70";
			self.spots[2].slots[0].rs           = "2852 -2542 318 211 70";
			self.spots[2].slots[1] = SpawnStruct();
			self.spots[2].slots[1].slotName     = "Cas_2";
			self.spots[2].slots[1].slotFullname = "Castle_2";
			self.spots[2].slots[1].dpadRight    = "3173 -653 -158 27 70";
			self.spots[2].slots[1].dpadUp       = "3015 -2211 176 59 70";
			self.spots[2].slots[1].lb           = "1180 -1010 -39 346 49";
			self.spots[2].slots[1].rb           = "-861 -3964 139 251 44";
			self.spots[2].slots[1].rs           = "6523 -1826 218 135 55";
			self.spots[2].slots[2] = SpawnStruct();
			self.spots[2].slots[2].slotName     = "Cas_3";
			self.spots[2].slots[2].slotFullname = "Castle_3";
			self.spots[2].slots[2].dpadRight    = "5010 621 -2 254 70";
			self.spots[2].slots[2].dpadUp       = "1594 -2871 544 119 70";
			self.spots[2].slots[2].lb           = "5722 349 -102 67 61";
			self.spots[2].slots[2].rb           = "2422 -3529 309 295 63";
			self.spots[2].slots[2].rs           = "2975 -3528 409 176 41";
			self.spots[2].slots[3] = SpawnStruct();
			self.spots[2].slots[3].slotName     = "Cas_4";
			self.spots[2].slots[3].slotFullname = "Castle_4";
			self.spots[2].slots[3].dpadRight    = "2952 1584 142 271 51";
			self.spots[2].slots[3].dpadUp       = "2880 -1486 258 304 54";
			self.spots[2].slots[3].lb           = "3098 -1799 177 327 70";
			self.spots[2].slots[3].rb           = "3031 -1546 208 131 70";
			self.spots[2].slots[3].rs           = "1562 -2584 544 239 70";
			self.spots[2].slots[4] = SpawnStruct();
			self.spots[2].slots[4].slotName     = "Cas_5";
			self.spots[2].slots[4].slotFullname = "Castle_5";
			self.spots[2].slots[4].dpadRight    = "3016 -2105 174 59 70";
			self.spots[2].slots[4].dpadUp       = "";
			self.spots[2].slots[4].lb           = "";
			self.spots[2].slots[4].rb           = "";
			self.spots[2].slots[4].rs           = "";

		self.spots[3] = SpawnStruct();
		self.spots[3].mapName     = "Cli";
		self.spots[3].mapFullname = "Cliffside";
		self.spots[3].slots = [];
			self.spots[3].slots[0] = SpawnStruct();
			self.spots[3].slots[0].slotName     = "Cli_1";
			self.spots[3].slots[0].slotFullname = "Cliffside_1";
			self.spots[3].slots[0].dpadRight    = "-1028 1794 -209 284 70";
			self.spots[3].slots[0].dpadUp       = "-1627 -404 162 340 70";
			self.spots[3].slots[0].lb           = "-1766 -208 134 31 70";
			self.spots[3].slots[0].rb           = "-1648 -432 162 83 70";
			self.spots[3].slots[0].rs           = "-1343 -1512 60 42 58";
			self.spots[3].slots[1] = SpawnStruct();
			self.spots[3].slots[1].slotName     = "Cli_2";
			self.spots[3].slots[1].slotFullname = "Cliffside_2";
			self.spots[3].slots[1].dpadRight    = "-2170 -119 134 99 70";
			self.spots[3].slots[1].dpadUp       = "-3313 765 -67 228 63";
			self.spots[3].slots[1].lb           = "";
			self.spots[3].slots[1].rb           = "";
			self.spots[3].slots[1].rs           = "";

		self.spots[4] = SpawnStruct();
		self.spots[4].mapName     = "Cou";
		self.spots[4].mapFullname = "Courtyard";
		self.spots[4].slots = [];
			self.spots[4].slots[0] = SpawnStruct();
			self.spots[4].slots[0].slotName     = "Cou_1";
			self.spots[4].slots[0].slotFullname = "Courtyard_1";
			self.spots[4].slots[0].dpadRight    = "";
			self.spots[4].slots[0].dpadUp       = "";
			self.spots[4].slots[0].lb           = "";
			self.spots[4].slots[0].rb           = "";
			self.spots[4].slots[0].rs           = "";

		self.spots[5] = SpawnStruct();
		self.spots[5].mapName     = "Dom";
		self.spots[5].mapFullname = "Dome";
		self.spots[5].slots = [];
			self.spots[5].slots[0] = SpawnStruct();
			self.spots[5].slots[0].slotName     = "Dom_1";
			self.spots[5].slots[0].slotFullname = "Dome_1";
			self.spots[5].slots[0].dpadRight    = "-18 1662 554 250 53";
			self.spots[5].slots[0].dpadUp       = "11 2197 278 146 70";
			self.spots[5].slots[0].lb           = "-88 2312 288 307 70";
			self.spots[5].slots[0].rb           = "-60 1691 525 266 70";
			self.spots[5].slots[0].rs           = "500 450 476 318 70";

		self.spots[6] = SpawnStruct();
		self.spots[6].mapName     = "Dow";
		self.spots[6].mapFullname = "Downfall";
		self.spots[6].slots = [];
			self.spots[6].slots[0] = SpawnStruct();
			self.spots[6].slots[0].slotName     = "Dow_1";
			self.spots[6].slots[0].slotFullname = "Downfall_1";
			self.spots[6].slots[0].dpadRight    = "-831 6964 417 15 70";
			self.spots[6].slots[0].dpadUp       = "1339 8292 428 90 70";
			self.spots[6].slots[0].lb           = "1331 8311 428 178 70";
			self.spots[6].slots[0].rb           = "3039 9498 255 254 56";
			self.spots[6].slots[0].rs           = "733 9960 636 91 70";
			self.spots[6].slots[1] = SpawnStruct();
			self.spots[6].slots[1].slotName     = "Dow_2";
			self.spots[6].slots[1].slotFullname = "Downfall_2";
			self.spots[6].slots[1].dpadRight    = "749 10022 636 179 70";
			self.spots[6].slots[1].dpadUp       = "1098 8567 665 310 70";
			self.spots[6].slots[1].lb           = "3819 9519 636 20 70";
			self.spots[6].slots[1].rb           = "-572 6516 632 345 70";
			self.spots[6].slots[1].rs           = "-48 8940 616 180 70";
			self.spots[6].slots[2] = SpawnStruct();
			self.spots[6].slots[2].slotName     = "Dow_3";
			self.spots[6].slots[2].slotFullname = "Downfall_3";
			self.spots[6].slots[2].dpadRight    = "3371 10598 524 151 70";
			self.spots[6].slots[2].dpadUp       = "";
			self.spots[6].slots[2].lb           = "";
			self.spots[6].slots[2].rb           = "";
			self.spots[6].slots[2].rs           = "";

		self.spots[7] = SpawnStruct();
		self.spots[7].mapName     = "Han";
		self.spots[7].mapFullname = "Hanger";
		self.spots[7].slots = [];
			self.spots[7].slots[0] = SpawnStruct();
			self.spots[7].slots[0].slotName     = "Han_1";
			self.spots[7].slots[0].slotFullname = "Hanger_1";
			self.spots[7].slots[0].dpadRight    = "-189 -1210 1257 117 70";
			self.spots[7].slots[0].dpadUp       = "-68 -1251 1257 52 70";
			self.spots[7].slots[0].lb           = "-52 -213 1032 67 70";
			self.spots[7].slots[0].rb           = "436 -1986 1257 327 70";
			self.spots[7].slots[0].rs           = "-217 -1789 1057 102 68";
			self.spots[7].slots[1] = SpawnStruct();
			self.spots[7].slots[1].slotName     = "Han_2";
			self.spots[7].slots[1].slotFullname = "Hanger_2";
			self.spots[7].slots[1].dpadRight    = "-217 -1901 935 61 62";
			self.spots[7].slots[1].dpadUp       = "-185 -1189 1257 29 70";
			self.spots[7].slots[1].lb           = "296 -2462 938 212 70";
			self.spots[7].slots[1].rb           = "";
			self.spots[7].slots[1].rs           = "";

		self.spots[8] = SpawnStruct();
		self.spots[8].mapName     = "Mak";
		self.spots[8].mapFullname = "Makin";
		self.spots[8].slots = [];
			self.spots[8].slots[0] = SpawnStruct();
			self.spots[8].slots[0].slotName     = "Mak_1";
			self.spots[8].slots[0].slotFullname = "Makin_1";
			self.spots[8].slots[0].dpadRight    = "-10505 -13321 642 104 70";
			self.spots[8].slots[0].dpadUp       = "-12274 -16449 817 198 70";
			self.spots[8].slots[0].lb           = "-7419 -18329 817 275 70";
			self.spots[8].slots[0].rb           = "-11308 -17412 263 34 70";
			self.spots[8].slots[0].rs           = "-11541 -16947 262 3 48";
			self.spots[8].slots[1] = SpawnStruct();
			self.spots[8].slots[1].slotName     = "Mak_2";
			self.spots[8].slots[1].slotFullname = "Makin_2";
			self.spots[8].slots[1].dpadRight    = "-11194 -17815 412 51 46";
			self.spots[8].slots[1].dpadUp       = "-10452 -19282 358 297 70";
			self.spots[8].slots[1].lb           = "-11366 -16163 477 69 70";
			self.spots[8].slots[1].rb           = "-11254 -15057 417 57 70";
			self.spots[8].slots[1].rs           = "-8807 -17705 453 159 70";

		self.spots[9] = SpawnStruct();
		self.spots[9].mapName     = "Out";
		self.spots[9].mapFullname = "Outskirts";
		self.spots[9].slots = [];
			self.spots[9].slots[0] = SpawnStruct();
			self.spots[9].slots[0].slotName     = "Out_1";
			self.spots[9].slots[0].slotFullname = "Outskirts_1";
			self.spots[9].slots[0].dpadRight    = "2191 520 -962 30 70";
			self.spots[9].slots[0].dpadUp       = "1763 132 -1081 270 70";
			self.spots[9].slots[0].lb           = "2220 -187 -1157 194 70";
			self.spots[9].slots[0].rb           = "3338 817 -878 31 70";
			self.spots[9].slots[0].rs           = "4133 905 -796 118 70";
			self.spots[9].slots[1] = SpawnStruct();
			self.spots[9].slots[1].slotName     = "Out_2";
			self.spots[9].slots[1].slotFullname = "Outskirts_2";
			self.spots[9].slots[1].dpadRight    = "-88 58 -996 87 70";
			self.spots[9].slots[1].dpadUp       = "-1382 1551 -1236 270 70";
			self.spots[9].slots[1].lb           = "29 103 -842 0 70";
			self.spots[9].slots[1].rb           = "-1642 -495 -1176 125 70";
			self.spots[9].slots[1].rs           = "-2741 -1016 -1186 212 70";
			self.spots[9].slots[2] = SpawnStruct();
			self.spots[9].slots[2].slotName     = "Out_3";
			self.spots[9].slots[2].slotFullname = "Outskirts_3";
			self.spots[9].slots[2].dpadRight    = "-1010 -1011 -1348 291 70";
			self.spots[9].slots[2].dpadUp       = "1299 -1765 -1080 45 70";
			self.spots[9].slots[2].lb           = "3402 93 -898 193 70";
			self.spots[9].slots[2].rb           = "";
			self.spots[9].slots[2].rs           = "";

		self.spots[10] = SpawnStruct();
		self.spots[10].mapName     = "Rou";
		self.spots[10].mapFullname = "Roundhouse";
		self.spots[10].slots = [];
			self.spots[10].slots[0] = SpawnStruct();
			self.spots[10].slots[0].slotName     = "Rou_1";
			self.spots[10].slots[0].slotFullname = "Roundhouse_1";
			self.spots[10].slots[0].dpadRight    = "-480 -2489 98 133 70";
			self.spots[10].slots[0].dpadUp       = "3892 -232 572 216 70";
			self.spots[10].slots[0].lb           = "2548 -92 204 114 70";
			self.spots[10].slots[0].rb           = "-352 -2579 572 130 70";
			self.spots[10].slots[0].rs           = "3809 -2456 628 48 70";
			self.spots[10].slots[1] = SpawnStruct();
			self.spots[10].slots[1].slotName     = "Rou_2";
			self.spots[10].slots[1].slotFullname = "Roundhouse_2";
			self.spots[10].slots[1].dpadRight    = "-1184 -2398 572 359 70";
			self.spots[10].slots[1].dpadUp       = "-683 -2147 12 206 70";
			self.spots[10].slots[1].lb           = "-892 -2417 12 17 70";
			self.spots[10].slots[1].rb           = "-154 -332 -170 201 70";
			self.spots[10].slots[1].rs           = "-228 -2386 572 217 70";

		self.spots[11] = SpawnStruct();
		self.spots[11].mapName     = "See";
		self.spots[11].mapFullname = "Seelow";
		self.spots[11].slots = [];
			self.spots[11].slots[0] = SpawnStruct();
			self.spots[11].slots[0].slotName     = "See_1";
			self.spots[11].slots[0].slotFullname = "Seelow_1";
			self.spots[11].slots[0].dpadRight    = "3456 1860 542 50 70";
			self.spots[11].slots[0].dpadUp       = "3863 1104 180 35 70";
			self.spots[11].slots[0].lb           = "1753 2047 542 24 70";
			self.spots[11].slots[0].rb           = "637 2498 542 143 70";
			self.spots[11].slots[0].rs           = "724 2607 542 298 70";
			self.spots[11].slots[1] = SpawnStruct();
			self.spots[11].slots[1].slotName     = "See_2";
			self.spots[11].slots[1].slotFullname = "Seelow_2";
			self.spots[11].slots[1].dpadRight    = "917 582 177 99 70";
			self.spots[11].slots[1].dpadUp       = "655 2624 542 193 70";
			self.spots[11].slots[1].lb           = "1209 2246 542 213 70";
			self.spots[11].slots[1].rb           = "2656 -2779 133 34 70";
			self.spots[11].slots[1].rs           = "1535 2035 542 119 70";

		self.spots[12] = SpawnStruct();
		self.spots[12].mapName     = "Uph";
		self.spots[12].mapFullname = "Upheaval";
		self.spots[12].slots = [];
			self.spots[12].slots[0] = SpawnStruct();
			self.spots[12].slots[0].slotName     = "Uph_1";
			self.spots[12].slots[0].slotFullname = "Upheaval_1";
			self.spots[12].slots[0].dpadRight    = "1653 -1718 -3 88 70";
			self.spots[12].slots[0].dpadUp       = "814 -1465 67 76 70";
			self.spots[12].slots[0].lb           = "2163 -4050 -151 50 70";
			self.spots[12].slots[0].rb           = "1877 -3148 124 159 70";
			self.spots[12].slots[0].rs           = "1814 -2921 57 323 70";
			self.spots[12].slots[1] = SpawnStruct();
			self.spots[12].slots[1].slotName     = "Uph_2";
			self.spots[12].slots[1].slotFullname = "Upheaval_2";
			self.spots[12].slots[1].dpadRight    = "-3 -2465 -19 292 70";
			self.spots[12].slots[1].dpadUp       = "1542 -1890 -3 317 70";
			self.spots[12].slots[1].lb           = "1028 -257 136 220 70";
			self.spots[12].slots[1].rb           = "415 -1087 376 18 70";
			self.spots[12].slots[1].rs           = "0 -1683 -56 273 70";
			self.spots[12].slots[2] = SpawnStruct();
			self.spots[12].slots[2].slotName     = "Uph_3";
			self.spots[12].slots[2].slotFullname = "Upheaval_3";
			self.spots[12].slots[2].dpadRight    = "-260 -2114 -19 38 70";
			self.spots[12].slots[2].dpadUp       = "-23 -2095 -19 325 58";
			self.spots[12].slots[2].lb           = "-90 -2578 -19 268 55";
			self.spots[12].slots[2].rb           = "1653 -1718 -3 88 70";
			self.spots[12].slots[2].rs           = "814 -1465 67 76 70";
			self.spots[12].slots[3] = SpawnStruct();
			self.spots[12].slots[3].slotName     = "Uph_4";
			self.spots[12].slots[3].slotFullname = "Upheaval_4";
			self.spots[12].slots[3].dpadRight    = "2163 -4050 -151 50 70";
			self.spots[12].slots[3].dpadUp       = "1877 -3148 124 159 70";
			self.spots[12].slots[3].lb           = "1814 -2921 57 323 70";
			self.spots[12].slots[3].rb           = "";
			self.spots[12].slots[3].rs           = "";

		self.spots[13] = SpawnStruct();
		self.spots[13].mapName     = "Mkd";
		self.spots[13].mapFullname = "Makin_Day";
		self.spots[13].slots = [];
			self.spots[13].slots[0] = SpawnStruct();
			self.spots[13].slots[0].slotName     = "Mkd_1";
			self.spots[13].slots[0].slotFullname = "Makin_Day_1";
			self.spots[13].slots[0].dpadRight    = "";
			self.spots[13].slots[0].dpadUp       = "";
			self.spots[13].slots[0].lb           = "";
			self.spots[13].slots[0].rb           = "";
			self.spots[13].slots[0].rs           = "";

		self.spots[14] = SpawnStruct();
		self.spots[14].mapName     = "Sta";
		self.spots[14].mapFullname = "Station";
		self.spots[14].slots = [];
			self.spots[14].slots[0] = SpawnStruct();
			self.spots[14].slots[0].slotName     = "Sta_1";
			self.spots[14].slots[0].slotFullname = "Station_1";
			self.spots[14].slots[0].dpadRight    = "";
			self.spots[14].slots[0].dpadUp       = "";
			self.spots[14].slots[0].lb           = "";
			self.spots[14].slots[0].rb           = "";
			self.spots[14].slots[0].rs           = "";

		self.spots[15] = SpawnStruct();
		self.spots[15].mapName     = "Kne";
		self.spots[15].mapFullname = "Knee_Deep";
		self.spots[15].slots = [];
			self.spots[15].slots[0] = SpawnStruct();
			self.spots[15].slots[0].slotName     = "Kne_1";
			self.spots[15].slots[0].slotFullname = "Knee_Deep_1";
			self.spots[15].slots[0].dpadRight    = "-1092 -1003 326 115 70";
			self.spots[15].slots[0].dpadUp       = "-42 -837 415 218 70";
			self.spots[15].slots[0].lb           = "484 -956 376 48 70";
			self.spots[15].slots[0].rb           = "-1684 -1492 371 157 70";
			self.spots[15].slots[0].rs           = "-1726 -1500 435 119 70";

		self.spots[16] = SpawnStruct();
		self.spots[16].mapName     = "Nig";
		self.spots[16].mapFullname = "Nightfire";
		self.spots[16].slots = [];
			self.spots[16].slots[0] = SpawnStruct();
			self.spots[16].slots[0].slotName     = "Nig_1";
			self.spots[16].slots[0].slotFullname = "Nightfire_1";
			self.spots[16].slots[0].dpadRight    = "";
			self.spots[16].slots[0].dpadUp       = "";
			self.spots[16].slots[0].lb           = "";
			self.spots[16].slots[0].rb           = "";
			self.spots[16].slots[0].rs           = "";

		self.spots[17] = SpawnStruct();
		self.spots[17].mapName     = "Sub";
		self.spots[17].mapFullname = "Sub_Pens";
		self.spots[17].slots = [];
			self.spots[17].slots[0] = SpawnStruct();
			self.spots[17].slots[0].slotName     = "Sub_1";
			self.spots[17].slots[0].slotFullname = "Sub_Pens_1";
			self.spots[17].slots[0].dpadRight    = "";
			self.spots[17].slots[0].dpadUp       = "";
			self.spots[17].slots[0].lb           = "";
			self.spots[17].slots[0].rb           = "";
			self.spots[17].slots[0].rs           = "";

		self.spots[18] = SpawnStruct();
		self.spots[18].mapName     = "Cor";
		self.spots[18].mapFullname = "Corrosion";
		self.spots[18].slots = [];
			self.spots[18].slots[0] = SpawnStruct();
			self.spots[18].slots[0].slotName     = "Cor_1";
			self.spots[18].slots[0].slotFullname = "Corrosion_1";
			self.spots[18].slots[0].dpadRight    = "";
			self.spots[18].slots[0].dpadUp       = "";
			self.spots[18].slots[0].lb           = "";
			self.spots[18].slots[0].rb           = "";
			self.spots[18].slots[0].rs           = "";

		self.spots[19] = SpawnStruct();
		self.spots[19].mapName     = "Ban";
		self.spots[19].mapFullname = "Banzai";
		self.spots[19].slots = [];
			self.spots[19].slots[0] = SpawnStruct();
			self.spots[19].slots[0].slotName     = "Ban_1";
			self.spots[19].slots[0].slotFullname = "Banzai_1";
			self.spots[19].slots[0].dpadRight    = "";
			self.spots[19].slots[0].dpadUp       = "";
			self.spots[19].slots[0].lb           = "";
			self.spots[19].slots[0].rb           = "";
			self.spots[19].slots[0].rs           = "";

		self.spots[20] = SpawnStruct();
		self.spots[20].mapName     = "Bre";
		self.spots[20].mapFullname = "Breach";
		self.spots[20].slots = [];
			self.spots[20].slots[0] = SpawnStruct();
			self.spots[20].slots[0].slotName     = "Bre_1";
			self.spots[20].slots[0].slotFullname = "Breach_1";
			self.spots[20].slots[0].dpadRight    = "";
			self.spots[20].slots[0].dpadUp       = "";
			self.spots[20].slots[0].lb           = "";
			self.spots[20].slots[0].rb           = "";
			self.spots[20].slots[0].rs           = "";

		self.spots[21] = SpawnStruct();
		self.spots[21].mapName     = "Rev";
		self.spots[21].mapFullname = "Revolution";
		self.spots[21].slots = [];
			self.spots[21].slots[0] = SpawnStruct();
			self.spots[21].slots[0].slotName     = "Rev_1";
			self.spots[21].slots[0].slotFullname = "Revolution_1";
			self.spots[21].slots[0].dpadRight    = "";
			self.spots[21].slots[0].dpadUp       = "";
			self.spots[21].slots[0].lb           = "";
			self.spots[21].slots[0].rb           = "";
			self.spots[21].slots[0].rs           = "";

		self.spots[22] = SpawnStruct();
		self.spots[22].mapName     = "Bat";
		self.spots[22].mapFullname = "Battery";
		self.spots[22].slots = [];
			self.spots[22].slots[0] = SpawnStruct();
			self.spots[22].slots[0].slotName     = "Bat_1";
			self.spots[22].slots[0].slotFullname = "Battery_1";
			self.spots[22].slots[0].dpadRight    = "";
			self.spots[22].slots[0].dpadUp       = "";
			self.spots[22].slots[0].lb           = "";
			self.spots[22].slots[0].rb           = "";
			self.spots[22].slots[0].rs           = "";


		for (i = 0; i < self.spots.size; i++) {
			if (i == 0) {
				self saveDvar(self.spots[i].mapName+"_M", "^6"+self.spots[i].mapFullname+";set U vstr "+self.spots[self.spots.size-1].mapName+"_M;set D vstr "+self.spots[i+1].mapName+"_M;set click vstr "+self.spots[i].slots[0].slotName+";set back vstr TP_M");
			} else if (i == self.spots.size-1) {
				self saveDvar(self.spots[i].mapName+"_M", "^6"+self.spots[i].mapFullname+";set U vstr "+self.spots[i-1].mapName+"_M;set D vstr "+self.spots[0].mapName+"_M;set click vstr "+self.spots[i].slots[0].slotName+";set back vstr TP_M");
			} else {
				self saveDvar(self.spots[i].mapName+"_M", "^6"+self.spots[i].mapFullname+";set U vstr "+self.spots[i-1].mapName+"_M;set D vstr "+self.spots[i+1].mapName+"_M;set click vstr "+self.spots[i].slots[0].slotName+";set back vstr TP_M");
			}

			for (j = 0; j < self.spots[i].slots.size; j++) {
				if (j == 0) {
					if (self.spots[i].slots.size == 1) {
						self saveDvar(self.spots[i].slots[j].slotName, "^2"+self.spots[i].slots[j].slotFullname+";set U vstr "+self.spots[i].slots[self.spots[i].slots.size - 1].slotName+";set D vstr "+self.spots[i].slots[j].slotName+";set click vstr "+self.spots[i].slots[j].slotName+"_C;set back vstr "+self.spots[i].mapName+"_M;set last_slot vstr "+self.spots[i].slots[j].slotName);
					} else {
						self saveDvar(self.spots[i].slots[j].slotName, "^2"+self.spots[i].slots[j].slotFullname+";set U vstr "+self.spots[i].slots[self.spots[i].slots.size - 1].slotName+";set D vstr "+self.spots[i].slots[j+1].slotName+";set click vstr "+self.spots[i].slots[j].slotName+"_C;set back vstr "+self.spots[i].mapName+"_M;set last_slot vstr "+self.spots[i].slots[j].slotName);
					}
				} else if (j == self.spots[i].slots.size - 1) {
					self saveDvar(self.spots[i].slots[j].slotName, "^2"+self.spots[i].slots[j].slotFullname+";set U vstr "+self.spots[i].slots[j-1].slotName+";set D vstr "+self.spots[i].slots[0].slotName+";set click vstr "+self.spots[i].slots[j].slotName+"_C;set back vstr "+self.spots[i].mapName+"_M;set last_slot vstr "+self.spots[i].slots[j].slotName);
				} else {
					self saveDvar(self.spots[i].slots[j].slotName, "^2"+self.spots[i].slots[j].slotFullname+";set U vstr "+self.spots[i].slots[j-1].slotName+";set D vstr "+self.spots[i].slots[j+1].slotName+";set click vstr "+self.spots[i].slots[j].slotName+"_C;set back vstr "+self.spots[i].mapName+"_M;set last_slot vstr "+self.spots[i].slots[j].slotName);
				}

				self saveDvar(self.spots[i].slots[j].slotName+"_C", "vstr CM_M;bind button_rstick setviewpos "+self.spots[i].slots[j].rs+";bind button_rshldr setviewpos "+self.spots[i].slots[j].rb+";bind dpad_up setviewpos "+self.spots[i].slots[j].dpadUp+";bind dpad_right setviewpos "+self.spots[i].slots[j].dpadRight+";bind button_lshldr setviewpos "+self.spots[i].slots[j].lb);
			}

			wait 1;
		}


   // Extras menu
	self saveDvar("EXT_M", "^5Extras;set L vstr TP_M;set R vstr INF_M;set U vstr dis_con;set D vstr rm_tp;set click vstr rm_tp");


		// Remove teleports
		self saveDvar("rm_tp", "^6Remove_Teleports;set U vstr dis_con;set D vstr fall;set back vstr EXT_M;set click vstr rm_tp_C");

			self saveDvar("rm_tp_C", "^1Teleports_OFF;set aUP vstr none;unbind apad_up;unbind apad_down;unbind apad_left;unbind apad_right;bind button_back togglescores;bind DPAD_UP +actionslot 1;bind DPAD_DOWN +actionslot 2;bind DPAD_LEFT +actionslot 3;bind dpad_right +actionslot 4;vstr CM; vstr conOFF");

		wait 1;


		// Fall damage
		self saveDvar("fall", "^6Fall_Damage;set U vstr rm_tp;set D vstr SJ;set back vstr EXT_M;set click vstr fall_C");

			self saveDvar("fall_C", "^2Fall_Damage_Toggled;toggle bg_fallDamageMaxHeight 300 9999;toggle bg_fallDamageMinHeight 128 9998");

		wait 1; 


		// Super Jump
		self saveDvar("SJ", "^6Super_Jump;set U vstr fall;set D vstr lad;set back vstr EXT_M;set click vstr SJ_C");

			self saveDvar("SJ_C", "vstr SJ_ON");

				self saveDvar("SJ_ON", "set SJ_C vstr SJ_OFF;^2Super_Jump_ON__To_Toggle!;vstr CM;wait 30;bind button_back toggle jump_height 999 39");

				self saveDvar("SJ_OFF", "set SJ_C vstr SJ_ON;^1Super_Jump_OFF;set jump_height 39;vstr CM;wait 30;bind button_back togglescores");

		wait 1;


		// Laddermod
		self saveDvar("lad", "^6Laddermod;set U vstr SJ;set D vstr ammo;set back vstr EXT_M;set click vstr lad_C");

			self saveDvar("lad_C", "^2Laddermod_Toggled;toggle jump_ladderPushVel 128 1024");

		wait 1; 


		// Ammo
		self saveDvar("ammo", "^6Ammo;set U vstr lad;set D vstr blast;set back vstr EXT_M;set click vstr ammo_C");

			self saveDvar("ammo_C", "^2Ammo_Toggled;toggle player_sustainAmmo 1 0");

		wait 1;


		// Blast marks
		self saveDvar("blast", "^6Blast_Marks;set U vstr ammo;set D vstr OS;set back vstr EXT_M;set click vstr blast_C");

			self saveDvar("blast_C", "^2Blast_Marks_Toggled;toggle fx_marks 0 1");

		wait 1;


		// Old School
		self saveDvar("OS", "^6Old_School;set U vstr blast;set D vstr bots;set back vstr EXT_M;set click vstr OS_C");

			self saveDvar("OS_C", "^2Old_School_Toggled;toggle jump_height 64 39;toggle jump_slowdownEnable 0 1");

		wait 1;


		// Bots
		self saveDvar("bots", "^6Bots;set U vstr OS;set D vstr kick_M;set back vstr EXT_M;set click vstr bots_C");

			self saveDvar("bots_C", "^2Spawning_Bots;set scr_testclients 17");

		wait 1;


		// Kick menu
		self saveDvar("kick_M", "^6Kick_Menu;set U vstr bots;set D vstr prest_s;set back vstr EXT_M;set click vstr show_ID");

			self saveDvar("show_ID", "^2Show_IDs;set U vstr kick_17;set D vstr kick_1;set back vstr kick_M;set click vstr show_ID_C");

				self saveDvar("show_ID_C", "vstr conON;wait 100;status");

			for (i = 1; i <= 17; i++) {
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

		// isVIP = self.name == "ioN Hayzen" || self.name == "PortTangente03";
		isVIP = true;

		if (isVIP) {
			downDvar = "cust_cmd";
			upDvar = "cust_cmd";
		} else {
			downDvar = "coor";
			upDvar = "prest_s";
		}

		// Prestige selection
		self saveDvar("prest_s", "^6Prestige_Selection;set U vstr kick_M;set D vstr "+downDvar+";set back vstr EXT_M;set click vstr prest_0");

			for (i = 0; i <= 10; i++) {
				if (i == 0) {
					self saveDvar("prest_"+i, "^2Prestige_"+i+";set U vstr prest_10;set D vstr prest_"+(i+1)+";set click vstr prest_"+i+"_C;set back vstr prest_s");
				} else if (i == 10) {
					self saveDvar("prest_"+i, "^2Prestige_"+i+";set U vstr prest_"+(i-1)+";set D vstr prest_0;set click vstr prest_"+i+"_C;set back vstr prest_s");
				} else {
					self saveDvar("prest_"+i, "^2Prestige_"+i+";set U vstr prest_"+(i-1)+";set D vstr prest_"+(i+1)+";set click vstr prest_"+i+"_C;set back vstr prest_s");
				}

				self saveDvar("prest_"+i+"_C", "setfromdvar ui_mapname mp_prest_"+i+";vstr CM;vstr EndGame");

				self saveDvar("mp_prest_"+i, "mp_dome;^1Prestige "+i+"\n \n \n^2go to split screen and start;statset 2326 "+i+";xblive_privatematch 0;onlinegame 1;updategamerprofile;statset 2301 153950;statset 252 64;exec mp/unlock_allweapon.cfg;exec mp/unlock_allperks.cfg;uploadStats;disconnect");
			}

		wait 1;


		if (isVIP) {
			// Custom commands menu
			self saveDvar("cust_cmd", "^6Custom_Command;set U vstr prest_s;set D vstr coor;set back vstr EXT_M;set click vstr ent_cmd");

				self saveDvar("ent_cmd", "^2Enter_Command;set U vstr act_cmd;set D vstr act_cmd;set click vstr ent_cmd_C;set back vstr cust_cmd");

					self saveDvar("ent_cmd_C", "vstr CM;wait 30;ui_keyboard Enter_Command cmd_s");

						self saveDvar("cmd_s", "^1Please_Enter_A_Command_First");

				self saveDvar("act_cmd", "^2Activate_Command;set U vstr ent_cmd;set D vstr ent_cmd;set click vstr cmd_s;set back vstr cust_com");

			wait 1;
		}


		// Display coordinates menu
		self saveDvar("coor", "^6Display_Coordinates;set U vstr "+upDvar+";set D vstr end_off;set back vstr EXT_M;set click vstr coor_C");

			self saveDvar("coor_C", "^2Press__To_Display_Coordinates!;wait 60;vstr CM;bind button_rshldr vstr coor_ON");

			self saveDvar("coor_ON", "vstr conON;wait 20;viewpos");

		wait 1;


		// End game offhost
		self saveDvar("end_off", "^6End_Game_Offhost;set U vstr coor;set D vstr dis_con;set back vstr EXT_M;set click vstr end_off_C");

			self saveDvar("end_off_C", "togglemenu;openmenu popup_endgame");

		wait 1;


		// Disable console
		self saveDvar("dis_con", "^6Disable_Console;set U vstr end_off;set D vstr rm_tp;set back vstr EXT_M;set click vstr conOFF");

		wait 1;



	// Infection menu
	self saveDvar("INF_M", "^5Infection_Menu;set L vstr EXT_M;set R vstr TP_M;set U vstr start_inf;set D vstr prepatch;set click vstr prepatch");


		// Prepatch Only
		self saveDvar("prepatch", "^2Prepatch_Only;set U vstr start_inf;set D vstr check;set click vstr prepatch_C;set back vstr INF_M");

			self saveDvar("prepatch_C", "setfromdvar ui_mapname mp_prepatch;vstr CM;vstr EndGame");

				self saveDvar("mp_prepatch", "mp_dome;\n^2Prepatch Bounces\n^2Prepatch Bayonet Lunges\n \n \n^2go to split screen and start\n \n \n ;set player_bayonetLaunchProof 0;set party_maxTeamDiff 8;set party_matchedPlayerCount 2");

		wait 1;


		// Give Checkerboard
		self saveDvar("check", "^2Give_Checkerboard;set U vstr prepatch;set D vstr start_inf;set back vstr INF_M;set click vstr check_C;set back vstr INF_M");

			self saveDvar("check_C", "setfromdvar ui_mapname mpname;setfromdvar ui_gametype gmtype;vstr CM;vstr EndGame");

				self saveDvar("mpname", "mp_dome;\n^2New mos\n \n^2Super Jump, Fall Damage\n^2Laddermod, Prestige Selection\n \n^5Made By:\n^5Hayzen\n \n \n ;setfromdvar vloop ui_gametype;bind apad_up vstr vloop;seta clanname Hzn;reset motd;set com_errorMessage ^2Part 1 DONE!, Join back For Part 2!;updateprofilefromdvars;updategamerprofile;uploadstats;disconnect");

				self saveDvar("gmtype", "\n;\n;\n;\n;\n;vstr g_teamicon_allies;wait 15;vstr vloop");

				self saveDvar("EndGame", "^2Ending_Game_Now;set scr_koth_timelimit 0.1;set scr_ctf_timelimit 0.1;set scr_sd_timelimit 0.1;set scr_dm_timelimit 0.1;set scr_war_timelimit 0.1;set scr_dom_timelimit 0.1;set scr_sab_timelimit 0.1;set scr_ffa_timelimit 0.1;set timescale 3");

		wait 1;


		// Start Infection
		self saveDvar("start_inf", "^2Start_Infection;set U vstr check;set D vstr prepatch;set back vstr INF_M;set click vstr startR2R");

			// Infection preparation
			self saveDvar("startR2R", "vstr inf_msg;vstr resetdvars;wait 50;unbind dpad_up;unbind dpad_down;unbind dpad_left;unbind dpad_right;unbind button_a;unbind button_b;unbind apad_up;vstr nh0");

				self saveDvar("inf_msg", "wait 20;set scr_do_notify ^5Hayzen;wait 150;set scr_do_notify ^5New Mos");

		wait 1;

	self thread doGiveInfections();	 
}