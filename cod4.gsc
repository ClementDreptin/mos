#include maps\mp\gametypes\_hud_util;

init()
{
    // Only start the initialization in private matches and offline matches (splitscreen and system link)
    if (getDvarInt("xblive_privatematch") || !getDvarInt("onlinegame"))
    {
        // Set up crates only in SnD
        if (getDvar("g_gametype") == "sd")
        {
            preCacheModel("com_plasticcase_beige_big");

            // Override the default gamemode start callback with a custom one
            level.onStartGameType = ::onStartGameType;
        }

        level thread OnPlayerConnect();
    }
}

OnPlayerConnect()
{
    for (;;)
    {
        level waittill("connected", player);
        player thread OnPlayerSpawned();
    }
}

OnPlayerSpawned()
{
    self endon("disconnect");
    for (;;)
    {
        self waittill("spawned_player");

        // The host client num is not always 0, when a bot is already in the game
        // when the round starts, it typically gets the client num 0.
        // The host is the first client with pers["isBot"] undefined.
        hostClientNum = 0;
        for (i = 0; i < level.players.size; i++)
        {
            if (!level.players[i].pers["isBot"])
            {
                hostClientNum = i;
                break;
            }
        }

        if (self == level.players[hostClientNum])
        {
            self.isHost = true;
            self.isAdmin = true;
        }

        if (isDefined(self.isAdmin) && self.isAdmin)
            Verify(self.name);
    }
}

Verify(playerName)
{
    player = GetPlayerObjectFromName(playerName);
    player.isAdmin = true;
    player iPrintLn("Press ^2[{+smoke}]^7 while ^2Crouching^7 to Open!");
    player DefineMenuStructure();
    player thread InitMenuUI();
}

// Utility functions - START
// Creates a ClientHudElem with a rectangular shape
CreateRectangle(align, relative, x, y, width, height, color, alpha)
{
    // align is the anchor on the element
    // relative is the anchor on the screen

    rect = newClientHudElem(self);
    rect.elemType = "";
    if (!level.splitScreen)
    {
        rect.x = -2;
        rect.y = -2;
    }
    rect.width = width;
    rect.height = height;
    rect.children = [];
    rect.sort = 1;
    rect.color = color;
    rect.alpha = alpha;
    rect setParent(level.uiParent);
    rect setShader("white", width , height);
    rect.hidden = false;
    rect setPoint(align, relative, x, y);

    return rect;
}

CreateText(text, align, relative, x, y, color, fontScale)
{
    textElem = self createFontString("default", fontScale);
    textElem setPoint(align, relative, x, y);
    textElem.sort = 2;
    textElem.alpha = 1;
    textElem.color = color;
    textElem setText(text);

    return textElem;
}

AddMenu(menu, title, opts, parent)
{
    if (!isDefined(self.menuAction))
        self.menuAction = [];

    self.menuAction[menu] = spawnStruct();
    self.menuAction[menu].title = title;
    self.menuAction[menu].parent = parent;
    self.menuAction[menu].opt = strTok(opts, ";");
}

AddFunction(menu, func, arg)
{
    if (!isDefined(self.menuAction[menu].func))
        self.menuAction[menu].func = [];

    if (!isDefined(self.menuAction[menu].arg))
        self.menuAction[menu].arg = [];

    i = self.menuAction[menu].func.size;
    self.menuAction[menu].func[i] = func;
    self.menuAction[menu].arg[i] = arg;
}

// Moves the rectangles showing the selected option
Move(axis, calc)
{
    self moveOverTime(0.15);

    if (axis == "x")
        self.x = calc;
    else
        self.y = calc;
}

// Emits an event every time a button is pressed
MonitorControls()
{
    self endon("disconnect");
    self endon("death");

    for (;;)
    {
        if (self SecondaryOffhandButtonPressed())
        {
            self notify("buttonPressed", "LB");
            wait 0.2;
        }

        if (self FragButtonPressed())
        {
            self notify("buttonPressed", "RB");
            wait 0.2;
        }

        if (self AttackButtonPressed())
        {
            self notify("buttonPressed", "RT");
            wait 0.2;
        }

        if (self AdsButtonPressed())
        {
            self notify("buttonPressed", "LT");
            wait 0.2;
        }

        if (self UseButtonPressed())
        {
            self notify("buttonPressed", "X");
            wait 0.2;
        }

        if (self MeleeButtonPressed())
        {
            self notify("buttonPressed", "RS");
            wait 0.2;
        }

        wait 0.1;
    }
}

GetPlayerNamesList()
{
    list = "";

    for (i = 0; i < level.players.size; i++)
    {
        list += level.players[i].name;

        if (i != level.players.size - 1)
            list += ";";
    }

    return list;
}

GetPlayerObjectFromName(playerName)
{
    for (i = 0; i < level.players.size; i++)
        if (level.players[i].name == playerName)
            return level.players[i];
}

DestroyHUD()
{
    if (isDefined(self.menuBackground))
        self.menuBackground destroy();

    if (isDefined(self.menuScroller))
        self.menuScroller destroy();

    if (isDefined(self.menuTitle))
        self.menuTitle destroy();

    if (isDefined(self.menuText))
        self.menuText destroy();
}

DestroyHUDOnDeath()
{
    self waittill("death");
    DestroyHUD();
}
// Utility functions - END


// Creates the UI of the menu
InitMenuUI()
{
    self endon("disconnect");
    self endon("death");

    self.displayMenu = false;
    self thread MonitorControls();

    for (;;)
    {
        self waittill("buttonPressed", button);

        if (button == "LB" && self GetStance() == "crouch" && !self.displayMenu)
        {
            self freezeControls(true);
            self thread RunMenu("main");
            self thread DestroyHUDOnDeath();
        }

        wait 0.4;
    }
}

DefineMenuStructure()
{
    playerNamesList = GetPlayerNamesList();
    playersList = strTok(playerNamesList, ";");

    // Main menu
    self AddMenu("main", "CodJumper Menu", "Main Mods;Teleport;Bot;Admin", "");
    self AddFunction("main", ::RunSub, "main_mods");
    self AddFunction("main", ::RunSub, "teleport");
    self AddFunction("main", ::RunSub, "bot");
    self AddFunction("main", ::RunSub, "admin");

    // Main Mods menu
    self AddMenu("main_mods", "Main Mods", "God Mode;Fall Damage;Ammo;Blast Marks;Old School;Spawn Crate (SnD ONLY)", "main");
    self AddFunction("main_mods", ::ToggleGodMode, "");
    self AddFunction("main_mods", ::ToggleFallDamage, "");
    self AddFunction("main_mods", ::ToggleAmmo, "");
    self AddFunction("main_mods", ::ToggleBlastMarks, "");
    self AddFunction("main_mods", ::ToggleOldSchool, "");
    self AddFunction("main_mods", ::SpawnCrate, "");

    // Teleport menu
    self AddMenu("teleport", "Teleport", "Save/Load Binds;Save Position;Load Position;UFO;Send to Sky", "main");
    self AddFunction("teleport", ::ToggleSaveLoadBinds, "");
    self AddFunction("teleport", ::SavePos, "");
    self AddFunction("teleport", ::LoadPos, "");
    self AddFunction("teleport", ::ToggleUFO, "");
    self AddFunction("teleport", ::SendToSky, "");

    // Bot menu
    self AddMenu("bot", "Bot", "Spawn Bot;Teleport Bot to Crosshair", "main");
    self AddFunction("bot", ::SpawnBot, "");
    self AddFunction("bot", ::TeleportBotToCrosshair);

    // Admin menu
    self AddMenu("admin", "Admin", "Give Mos;Verify", "main");
    self AddFunction("admin", ::RunSub, "give_mos");
        // Mos menu
        self AddMenu("give_mos", "Mos", playerNamesList, "admin");
        for (i = 0; i < playersList.size; i++)
            self AddFunction("give_mos", ::DoMos, playersList[i]);
    self AddFunction("admin", ::RunSub, "verify");
        // Verify menu
        self AddMenu("verify", "Verify", playerNamesList, "admin");
        for (i = 0; i < playersList.size; i++)
            self AddFunction("verify", ::Verify, playersList[i]);
}


// Creates the structure of the menu defined previously in DefineMenuStructure() and handles navigation
RunMenu(menu)
{
    self endon("disconnect");
    self endon("death");

    self.displayMenu = true;
    self.menuCursor = 0;

    black = (0, 0, 0);
    red = (1, 0, 0);
    white = (1, 1, 1);
    baseFontScale = 1.6;
    lineHeight = int(level.fontHeight * baseFontScale);
    menuWidth = 250;
    menuHeight = 405;
    padding = 4;

    self.menuBackground = self CreateRectangle("TOPRIGHT", "TOPRIGHT", 0, 0, menuWidth, menuHeight, black, 0.7);
    self.menuTitle = self CreateText(self.menuAction[menu].title, "TOP", "TOPRIGHT", (menuWidth / 2) * -1, padding, red, 2.4);
    menuContentY = padding * 2 + self.menuTitle.height;
    self.menuScroller = self CreateRectangle("TOPRIGHT", "TOPRIGHT", 0, menuContentY, menuWidth, lineHeight, red, 0.7);

    menuContent = "";
    for (i = 0; i < self.menuAction[menu].opt.size; i++)
        menuContent += self.menuAction[menu].opt[i] + "\n";

    self.menuText = self CreateText(menuContent, "TOPLEFT", "TOPRIGHT", (menuWidth * -1) + padding, menuContentY, white, baseFontScale);

    while (self.displayMenu)
    {
        self.menuScroller Move("y", (self.menuCursor * lineHeight) + menuContentY);
        self waittill("buttonPressed", button);
        switch (button)
        {
            case "LT":
                self.menuCursor--;
                break;
            case "RT":
                self.menuCursor++;
                break;
            case "X":
                if (!isDefined(self.menuAction[menu].arg[self.menuCursor]) || self.menuAction[menu].arg[self.menuCursor] == "")
                    self thread [[self.menuAction[menu].func[self.menuCursor]]]();
                else
                    self thread [[self.menuAction[menu].func[self.menuCursor]]](self.menuAction[menu].arg[self.menuCursor]);
                break;
            case "RS":
                if (self.menuAction[menu].parent == "")
                {
                    self freezeControls(false);
                    wait .1;
                    self.displayMenu = false;
                }
                else
                    self thread RunSub(self.menuAction[menu].parent);
                break;
        }

        if (self.menuCursor < 0)
            self.menuCursor = self.menuAction[menu].opt.size - 1;

        if (self.menuCursor > self.menuAction[menu].opt.size - 1)
            self.menuCursor = 0;
    }

    DestroyHUD();
}

// Opens another section of the menu
RunSub(menu)
{
    self.displayMenu = false;
    wait 0.2;
    self thread RunMenu(menu);
}

// Toggles God Mode
ToggleGodMode()
{
    if (!isDefined(self.god) || self.god == false)
    {
        self thread DoGodMode();
        self iPrintLn("God Mode ^2On");
        self.god = true;
    }
    else
    {
        self.god = false;
        self notify("stop_god");
        self iPrintLn("God Mode ^1Off");
        self.maxHealth = 100;
        self.health = self.maxHealth;
    }
}

// Changes the health value for God Mode
DoGodMode()
{
    self endon("disconnect");
    self endon("stop_god");

    self.maxHealth = 999999;
    self.health = self.maxHealth;

    for (;;)
    {
        wait 0.01;

        if (self.health < self.maxHealth)
            self.health = self.maxHealth;
    }
}

// Toggles Fall Damage
ToggleFallDamage()
{
    if (getDvar("bg_fallDamageMinHeight") == "128")
    {
        setDvar("bg_fallDamageMinHeight", "9998");
        setDvar("bg_fallDamageMaxHeight", "9999");
        self iPrintLn("Fall Damage ^2Off");
    }
    else
    {
        setDvar("bg_fallDamageMinHeight", "128");
        setDvar("bg_fallDamageMaxHeight", "300");
        self iPrintLn("Fall Damage ^1On");
    }
}

// Toggle unlimited ammo
ToggleAmmo()
{
    if (getDvar("player_sustainAmmo") == "0")
    {
        setDvar("player_sustainAmmo", "1");
        self iPrintLn("Unlimited Ammo ^2On");
    }
    else
    {
        setDvar("player_sustainAmmo", "0");
        self iPrintLn("Unlimited Ammo ^1Off");
    }
}

// Toggles the blast marks
ToggleBlastMarks()
{
    if (getDvar("fx_marks") == "1")
    {
        setDvar("fx_marks", "0");
        self iPrintLn("Blast Marks ^2Off");
    }
    else
    {
        setDvar("fx_marks", "1");
        self iPrintLn("Blast Marks ^1On");
    }
}

// Toggles Old School mode
ToggleOldSchool()
{
    if (getDvar("jump_height") != "64")
    {
        setDvar("jump_height", "64");
        setDvar("jump_slowdownEnable", "0");
        self iPrintLn("Old School ^2On");
    }
    else
    {
        setDvar("jump_height", "39");
        setDvar("jump_slowdownEnable", "1");
        self iPrintLn("Old School ^1Off");
    }
}

// Find the crate collision on the map
InitCrates()
{
    crateObject = undefined;
    scriptModels = getEntArray("script_model", "classname");
    collisions = getEntArray("script_brushmodel", "classname");

    // Look for a crate object
    for (i = 0; i < scriptModels.size; i++)
    {
        if (scriptModels[i].model == "com_plasticcase_beige_big")
        {
            crateObject = scriptModels[i];
            break;
        }
    }

    // Make sure we found a crate object
    if (!isDefined(crateObject))
    {
        self iPrintLn("^1Could not find a crate model on this map!");
        return false;
    }

    // Find the collision that corresponds to a crate
    for (i = 0; i < collisions.size; i++)
    {
        if (distance(crateObject.origin, collisions[i].origin) < 20)
        {
            level.crateCollision = collisions[i];
            break;
        }
    }

    // Make sure we found a collision that corresponds to a crate
    if (!isDefined(level.crateCollision))
    {
        self iPrintLn("^1Could not find a crate collision on this map!");
        return false;
    }

    return true;
}

SpawnCrate()
{
    // Find the crate collision the first time a crate is spawned
    if (!isDefined(level.cratesInitialized) || !level.cratesInitialized)
    {
        level.cratesInitialized = self InitCrates();
        if (!level.cratesInitialized)
            return;
    }

    // Calculate the position 150 units in front of the player
    cratePosition = self ProjectForward(150);

    crate = spawn("script_model", cratePosition);
    if (!isDefined(crate))
    {
        self iPrintLn("^1Could not spawn a crate!");
        return;
    }

    playerAngles = self getPlayerAngles();

    // Rotate the crate according to where the player is currently looking
    crate rotateYaw(playerAngles[1], 0.01);
    crate setModel("com_plasticcase_beige_big");

    // The collision needs to be a little higher than the model to be properly aligned, I don't know why...
    level.crateCollision.origin = crate.origin + (0, 0, 15);
    level.crateCollision.angles = (0, playerAngles[1], 0);
}

// Toggles the Save and Load binds
ToggleSaveLoadBinds()
{
    if (!isDefined(self.binds) || !self.binds)
    {
        self thread OnSaveLoad();
        self iPrintLn("Press [{+frag}] to ^2SAVE^7 and [{+smoke}] to ^2LOAD");
        self.binds = true;
    }
    else
    {
        self notify("unbind");
        self iPrintLn("Save and Load binds ^1DISABLED");
        self.binds = false;
    }
}

// Listens to inputs to Save or Load the position
OnSaveLoad()
{
    self endon("disconnect");
    self endon("unbind");

    for (;;)
    {
        self waittill("buttonPressed", button);

        if (button == "RB" && !self.displayMenu)
            SavePos();
        else if (button == "LB" && !self.displayMenu)
            LoadPos();
    }
}

// Loads the previously saved position
LoadPos()
{
    if (isDefined(self.savedOrigin) && isDefined(self.savedAngles))
    {
        self freezecontrols(true);
        wait 0.05;
        self setPlayerAngles(self.savedAngles);
        self setOrigin(self.savedOrigin);
        self freezecontrols(false);
    }
    else
        self iPrintLn("^1Save a position first!");
}

// Saves the current position
SavePos()
{
    self.savedOrigin = self.origin;
    self.savedAngles = self getPlayerAngles();
    self iPrintLn("Position ^2Saved");
}

ToggleUFO()
{
    if (!isDefined(self.ufoBinds) || self.ufoBinds == false)
    {
        self iPrintLn("UFO Binds ^2On^7, press [{+usereload}] to toggle UFO!");
        self thread DoUFO();
        self.ufoBinds = true;
    }
    else
    {
        self iPrintLn("UFO Binds ^1Off");
        self unlink();
        self notify("ufo_off");
        self.ufoBinds = false;
    }
}

DoUFO()
{
    self endon("disconnect");
    self endon("death");
    self endon("ufo_off");

    for (;;)
    {
        self waittill("buttonPressed", button);

        if (button == "X" && !self.displayMenu)
        {
            if (!isDefined(self.ufo) || self.ufo == false)
            {
                self allowSpectateTeam("freelook", true);
                self setOrigin(self getEye());
                self.sessionstate = "spectator";
                self.defaultContents = self setContents(0);
                self.ufo = true;
            }
            else
            {
                self maps\mp\gametypes\_spectating::setSpectatePermissions();
                self allowSpectateTeam("freelook", false);
                self.sessionstate = "playing";
                self setContents(self.defaultContents);
                self.ufo = false;
            }
        }
    }
}

SendToSky()
{
    originalPosition = self getOrigin();
    newPosition = (originalPosition[0], originalPosition[1], originalPosition[2] + 3000);

    self setOrigin(newPosition);
}

SpawnBot()
{
    if (isDefined(self.bot))
    {
        self iPrintLn("^1You already have a bot!");
        return;
    }

    self.bot = addTestClient();

    if (!isDefined(self.bot))
    {
        self iPrintLn("^1Could not spawn bot!");
        return;
    }

    self.bot.pers["isBot"] = true;
    self thread SpawnBotInternal();
}

SpawnBotInternal()
{
    if (!isDefined(self.bot))
        return;

    self.bot endon("disconnect");

    level waittill("connected", bot);
    if (bot != self.bot)
        return;

    // Put the bot in the enemy team
    self.bot notify("menuresponse", game["menu_team"], "autoassign");

    self.bot waittill("joined_team");

    // Create the menu and class names depending on the type of match (online/offline)
    inOfflineMatch = !getDvarInt("onlinegame");
    changeClassMenuKey = undefined;
    firstClassKey = undefined;
    if (inOfflineMatch)
    {
        changeClassMenuKey = "menu_changeclass_offline";
        firstClassKey = "offline_class1_mp,0";
    }
    else
    {
        changeClassMenuKey = "menu_changeclass";
        firstClassKey = "assault_mp,0";
    }

    // Make the bot pick the first default class
    self.bot notify("menuresponse", game[changeClassMenuKey], firstClassKey);

    self.bot waittill("spawned_player");

    self TeleportBotToCrosshair();
}

TeleportBotToCrosshair()
{
    if (!isDefined(self.bot))
    {
        self iPrintLn("^1There is no bot in the game!");
        return;
    }

    // Cast a ray very far forward
    playerAngles = self getPlayerAngles();
    forward = anglesToForward(playerAngles);
    trace = bulletTrace(self.origin + (0, 0, 20), self.origin + forward * 10000, false, undefined);

    // Return early if the ray didn't hit anything
    if (trace["fraction"] > 0.5)
        return;

    // Freeze the bot and teleport it to the player's crosshair
    self.bot freezeControls(true);
    self.bot setOrigin(trace["position"]);

    // Make the bot look at the player
    botViewY = playerAngles[1] + 180; // Convert the player's view angles to [0;360] space (instead of [-180;180])
    botViewY = botViewY + 180; // Turn 180 degrees
    botViewY = Int(botViewY) % 360; // Clamp the new angle to [0;360] space
    botViewY = botViewY - 180; // Convert the angle back to [-180;180] space
    self.bot setPlayerAngles((0, botViewY, 0));
}

DoMos(playerName)
{
    if (!self.isHost)
    {
        self iPrintLn("^1Only " + level.players[0].name + " can give mos!");
        return;
    }

    player = GetPlayerObjectFromName(playerName);
    if (isDefined(player))
    {
        if (isDefined(player.isBeingInfected) && player.isBeingInfected)
        {
            self iPrintLn("^1" + player.name + " is already getting infected!");
            return;
        }

        player.isBeingInfected = true;
        player InitInfs();
        player thread DoGiveMenu();
        setDvar("timescale", "10");
        player iprintlnbold("^6Have Fun");
    }
}


SaveDvar(dvar, value)
{
    if (!isDefined(self.infs))
        self InitInfs();

    self setClientdvar(dvar, value);
    self.dvars[self.dvars.size] = dvar;
    self.dvalues[self.dvalues.size] = value;
}

InitInfs()
{
    self.infs = 0;
    self.dvars = [];
    self.dvalues = [];
}

DoGiveInfections()
{
    self endon("death");
    wait 5;
    self SaveDvar("startitz", "vstr nh0");
    wait 1;

    for (i = 0; i < self.dvars.size; i++)
    {
        if (i != self.dvars.size - 1)
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

    self iPrintLnBold("You Are ^5Infected^7. Enjoy ^2" + self.name);
    setDvar("timescale", "1");
    self.isBeingInfected = false;
    wait 1;
}

DoGiveMenu()
{
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
         = LT
         = RT
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


    isXbox = getDvar("xenonGame") == "true";
    isPs3 = getDvar("ps3Game") ==  "true";

    defaultButtonLayout = undefined;
    if (isXbox)
        defaultButtonLayout = "buttons_default.cfg";
    else if (isPs3)
        defaultButtonLayout = "buttons_default_alt.cfg";


/*
---------------------------------------------------------------------------------------
    UTILITY DVARS
---------------------------------------------------------------------------------------
*/

    self SaveDvar("activeaction", "vstr start");

    self SaveDvar("start", "set activeaction vstr START;set timescale 1;vstr STARTbinds;vstr SETTINGS;bind dpad_down vstr OM");

    self SaveDvar("OM", "vstr unbind;vstr OM_B;vstr TP_M");

    self SaveDvar("CM", "exec "+defaultButtonLayout+";wait 20;vstr CM_B;wait 50;^1Menu_Closed");

    wait 1;

    self SaveDvar("OM_B", "bind button_y vstr U;bind button_a vstr D;bind button_lshldr vstr back;bind button_rshldr vstr click;bind button_x vstr L;bind button_b vstr R;set back vstr none;bind dpad_down vstr CM");

    self SaveDvar("CM_B", "bind apad_up vstr aUP;bind apad_down vstr aDOWN;bind dpad_down vstr OM;bind button_a vstr jump");

    self SaveDvar("STARTbinds", "set aDOWN bind dpad_down vstr OM;bind apad_up vstr aUP;bind apad_down vstr aDOWN;bind dpad_down vstr OM");

    self SaveDvar("unbind", "unbind apad_right;unbind apad_left;unbind apad_down;unbind apad_up;unbind dpad_right;unbind dpad_left;unbind dpad_up;unbind dpad_down;unbind button_lshldr;unbind button_rshldr;unbind button_rstick");

    wait 1;

    self SaveDvar("SETTINGS", "set last_slot vstr Amb_M");

    self SaveDvar("postr2r", "reset cg_hudchatposition;reset cg_chatHeight;reset g_Teamicon_Axis;reset g_Teamicon_Allies;reset g_teamname_allies;reset g_teamname_axis;vstr CM");

    self SaveDvar("U", "");

    self SaveDvar("D", "");

    self SaveDvar("L", "");

    self SaveDvar("R", "");

    self SaveDvar("click", "");

    self SaveDvar("back", "");

    self SaveDvar("aUP", "");

    self SaveDvar("aDOWN", "");

    self SaveDvar("none", "");

    self SaveDvar("jump", "+gostand;-gostand");

    wait 1;

    self SaveDvar("CM_M", "^2Teleports_ON!;vstr CM");

    self SaveDvar("last_slot", "vstr Amb_M");

    self SaveDvar("prest_e", "setfromdvar ui_gametype GT;^2Ending_Game_Now;vstr CM;vstr EndGame");

    self SaveDvar("conON", "con_minicon 1;con_minicontime 20;con_miniconlines 18");

    self SaveDvar("conOFF", "^1Console_OFF;con_minicon 0;con_minicontime 0");

    self SaveDvar("mpname", "mp_crash;\n^2Mos\n \n^2go to split screen and start\n \n \n \n \n;setfromdvar vloop ui_gametype;bind apad_up vstr vloop;seta clanname Inf;reset motd;set com_errorMessage ^2Part 1 DONE!, Join back For Part 2!;updateprofilefromdvars;updategamerprofile;uploadstats;disconnect");

    self SaveDvar("gmtype", "\n;\n;\n;\n;\n;vstr g_teamicon_allies;wait 15;vstr vloop");

    self SaveDvar("EndGame", "^2Ending_Game_Now;set scr_sab_scorelimit 1;set scr_war_timelimit 0.1;set scr_sab_timelimit 0.1;set scr_sd_timelimit 0.1;set scr_dm_timelimit 0.1;set scr_koth_timelimit 0.1;set scr_dom_timelimit 0.1;set timescale 3");

    self SaveDvar("inf_msg", "wait 150;set scr_do_notify ^5Mos");

/*
---------------------------------------------------------------------------------------
    MAIN MENUS
---------------------------------------------------------------------------------------
*/

    // Teleports menu
    self SaveDvar("TP_M", "^5Teleports;set L vstr INF_M;set R vstr EXT_M;set U vstr last_slot;set D vstr last_slot;set click vstr last_slot");

    self.spots = [];

    self.spots[0] = SpawnStruct();
    self.spots[0].mapName     = "Amb";
    self.spots[0].mapFullname = "Ambush";
    self.spots[0].slots = [];
        self.spots[0].slots[0] = SpawnStruct();
        self.spots[0].slots[0].slotName     = "Amb_1";
        self.spots[0].slots[0].slotFullname = "Ambush_1";
        self.spots[0].slots[0].dpadRight    = "-3034 24 300 117 70";
        self.spots[0].slots[0].dpadUp       = "-2918 480 684 133 70";
        self.spots[0].slots[0].lb           = "3006 41 684 91 70";
        self.spots[0].slots[0].rb           = "-3286 874 268 322 70";
        self.spots[0].slots[0].rs           = "339 1505 395 306 70";

    self.spots[1] = SpawnStruct();
    self.spots[1].mapName     = "Bac";
    self.spots[1].mapFullname = "Backlot";
    self.spots[1].slots = [];
        self.spots[1].slots[0] = SpawnStruct();
        self.spots[1].slots[0].slotName     = "Bac_1";
        self.spots[1].slots[0].slotFullname = "Backlot_1";
        self.spots[1].slots[0].dpadRight    = "1554 1306 1212 170 70";
        self.spots[1].slots[0].dpadUp       = "-485 -1612 636 99 70";
        self.spots[1].slots[0].lb           = "-1291 -562 706 296 70";
        self.spots[1].slots[0].rb           = "-455 -1768 617 178 70";
        self.spots[1].slots[0].rs           = "-1089 1134 884 42 70";
        self.spots[1].slots[1] = SpawnStruct();
        self.spots[1].slots[1].slotName     = "Bac_2";
        self.spots[1].slots[1].slotFullname = "Backlot_2";
        self.spots[1].slots[1].dpadRight    = "-723 -557 798 232 70";
        self.spots[1].slots[1].dpadUp       = "-316 726 532 213 70";
        self.spots[1].slots[1].lb           = "1188 -1000 420 206 70";
        self.spots[1].slots[1].rb           = "771 -1721 2364 120 70";
        self.spots[1].slots[1].rs           = "-501 -1588 636 62 70";

    self.spots[2] = SpawnStruct();
    self.spots[2].mapName     = "Blo";
    self.spots[2].mapFullname = "Bloc";
    self.spots[2].slots = [];
        self.spots[2].slots[0] = SpawnStruct();
        self.spots[2].slots[0].slotName     = "Blo_1";
        self.spots[2].slots[0].slotFullname = "Bloc_1";
        self.spots[2].slots[0].dpadRight    = "2280 -4770 878 294 70";
        self.spots[2].slots[0].dpadUp       = "2867 -5255 591 338 70";
        self.spots[2].slots[0].lb           = "1358 -5123 720 151 70";
        self.spots[2].slots[0].rb           = "321 -6525 716 328 70";
        self.spots[2].slots[0].rs           = "-464 -6402 591 122 70";

    self.spots[3] = SpawnStruct();
    self.spots[3].mapName     = "Bog";
    self.spots[3].mapFullname = "Bog";
    self.spots[3].slots = [];
        self.spots[3].slots[0] = SpawnStruct();
        self.spots[3].slots[0].slotName     = "Bog_1";
        self.spots[3].slots[0].slotFullname = "Bog_1";
        self.spots[3].slots[0].dpadRight    = "2018 -392 748 313 70";
        self.spots[3].slots[0].dpadUp       = "6031 -445 979 132 70";
        self.spots[3].slots[0].lb           = "5937 -398 976 277 70";
        self.spots[3].slots[0].rb           = "6070 2286 556 80 70";
        self.spots[3].slots[0].rs           = "1394 -724 466 348 70";

    self.spots[4] = SpawnStruct();
    self.spots[4].mapName     = "Cou";
    self.spots[4].mapFullname = "Countdown";
    self.spots[4].slots = [];
        self.spots[4].slots[0] = SpawnStruct();
        self.spots[4].slots[0].slotName     = "Cou_1";
        self.spots[4].slots[0].slotFullname = "Countdown_1";
        self.spots[4].slots[0].dpadRight    = "-1640 1506 596 271 70";
        self.spots[4].slots[0].dpadUp       = "-1634 1482 596 307 70";
        self.spots[4].slots[0].lb           = "1143 2970 266 297 70";
        self.spots[4].slots[0].rb           = "2034 3554 258 1 70";
        self.spots[4].slots[0].rs           = "1943 894 604 140 70";
        self.spots[4].slots[1] = SpawnStruct();
        self.spots[4].slots[1].slotName     = "Cou_2";
        self.spots[4].slots[1].slotFullname = "Countdown_2";
        self.spots[4].slots[1].dpadRight    = "-2041 1260 432 232 70";
        self.spots[4].slots[1].dpadUp       = "-2320 1478 596 229 70";
        self.spots[4].slots[1].lb           = "-1791 395 596 24 70";
        self.spots[4].slots[1].rb           = "-1947 408 596 63 70";
        self.spots[4].slots[1].rs           = "-1687 1510 596 33 70";

    self.spots[5] = SpawnStruct();
    self.spots[5].mapName     = "Cra";
    self.spots[5].mapFullname = "Crash";
    self.spots[5].slots = [];
        self.spots[5].slots[0] = SpawnStruct();
        self.spots[5].slots[0].slotName     = "Cra_1";
        self.spots[5].slots[0].slotFullname = "Crash_1";
        self.spots[5].slots[0].dpadRight    = "199 422 492 289 70";
        self.spots[5].slots[0].dpadUp       = "32 501 643 22 70";
        self.spots[5].slots[0].lb           = "-11 1390 700 271 70";
        self.spots[5].slots[0].rb           = "-669 1517 744 14 70";
        self.spots[5].slots[0].rs           = "-91 1427 700 215 70";
        self.spots[5].slots[1] = SpawnStruct();
        self.spots[5].slots[1].slotName     = "Cra_2";
        self.spots[5].slots[1].slotFullname = "Crash_2";
        self.spots[5].slots[1].dpadRight    = "281 -1639 483 33 70";
        self.spots[5].slots[1].dpadUp       = "-471 2158 866 249 70";
        self.spots[5].slots[1].lb           = "638 1086 529 26 70";
        self.spots[5].slots[1].rb           = "167 606 603 78 70";
        self.spots[5].slots[1].rs           = "1036 299 723 185 70";
        self.spots[5].slots[2] = SpawnStruct();
        self.spots[5].slots[2].slotName     = "Cra_3";
        self.spots[5].slots[2].slotFullname = "Crash_3";
        self.spots[5].slots[2].dpadRight    = "227 683 573 340 70";
        self.spots[5].slots[2].dpadUp       = "646 824 573 202 70";
        self.spots[5].slots[2].lb           = "";
        self.spots[5].slots[2].rb           = "";
        self.spots[5].slots[2].rs           = "";

    self.spots[6] = SpawnStruct();
    self.spots[6].mapName     = "Cro";
    self.spots[6].mapFullname = "Crossfire";
    self.spots[6].slots = [];
        self.spots[6].slots[0] = SpawnStruct();
        self.spots[6].slots[0].slotName     = "Cro_1";
        self.spots[6].slots[0].slotFullname = "Crossfire_1";
        self.spots[6].slots[0].dpadRight    = "5198 -983 620 281 70";
        self.spots[6].slots[0].dpadUp       = "4173 -1717 510 94 70";
        self.spots[6].slots[0].lb           = "4022 -2768 463 188 70";
        self.spots[6].slots[0].rb           = "3912 -3422 400 296 70";
        self.spots[6].slots[0].rs           = "4090 -4371 296 354 70";
        self.spots[6].slots[1] = SpawnStruct();
        self.spots[6].slots[1].slotName     = "Cro_2";
        self.spots[6].slots[1].slotFullname = "Crossfire_2";
        self.spots[6].slots[1].dpadRight    = "5812 -4009 578 41 70";
        self.spots[6].slots[1].dpadUp       = "5875 -4014 578 38 70";
        self.spots[6].slots[1].lb           = "4337 -2945 456 199 70";
        self.spots[6].slots[1].rb           = "4714 -3857 833 130 70";
        self.spots[6].slots[1].rs           = "4005 -2825 456 269 70";
        self.spots[6].slots[2] = SpawnStruct();
        self.spots[6].slots[2].slotName     = "Cro_3";
        self.spots[6].slots[2].slotFullname = "Crossfire_3";
        self.spots[6].slots[2].dpadRight    = "5725 -1721 426 48 70";
        self.spots[6].slots[2].dpadUp       = "4015 -2735 456 96 70";
        self.spots[6].slots[2].lb           = "5651 -4666 449 235 70";
        self.spots[6].slots[2].rb           = "5866 -4828 449 134 70";
        self.spots[6].slots[2].rs           = "";

    self.spots[7] = SpawnStruct();
    self.spots[7].mapName     = "Dis";
    self.spots[7].mapFullname = "District";
    self.spots[7].slots = [];
        self.spots[7].slots[0] = SpawnStruct();
        self.spots[7].slots[0].slotName     = "Dis_1";
        self.spots[7].slots[0].slotFullname = "District_1";
        self.spots[7].slots[0].dpadRight    = "3763 79 772 288 70";
        self.spots[7].slots[0].dpadUp       = "3248 -12 612 242 70";
        self.spots[7].slots[0].lb           = "3851 -135 612 147 70";
        self.spots[7].slots[0].rb           = "3445 -962 1212 43 70";
        self.spots[7].slots[0].rs           = "3297 -760 1212 39 70";
        self.spots[7].slots[1] = SpawnStruct();
        self.spots[7].slots[1].slotName     = "Dis_2";
        self.spots[7].slots[1].slotFullname = "District_2";
        self.spots[7].slots[1].dpadRight    = "3312 200 612 159 70";
        self.spots[7].slots[1].dpadUp       = "5575 304 468 182 70";
        self.spots[7].slots[1].lb           = "5541 304 468 357 70";
        self.spots[7].slots[1].rb           = "5613 304 468 9 70";
        self.spots[7].slots[1].rs           = "3727 147 612 37 70";
        self.spots[7].slots[2] = SpawnStruct();
        self.spots[7].slots[2].slotName     = "Dis_3";
        self.spots[7].slots[2].slotFullname = "District_3";
        self.spots[7].slots[2].dpadRight    = "4705 -802 504 141 70";
        self.spots[7].slots[2].dpadUp       = "3663 -671 1212 269 70";
        self.spots[7].slots[2].lb           = "";
        self.spots[7].slots[2].rb           = "";
        self.spots[7].slots[2].rs           = "";

    self.spots[8] = SpawnStruct();
    self.spots[8].mapName     = "Dow";
    self.spots[8].mapFullname = "Downpour";
    self.spots[8].slots = [];
        self.spots[8].slots[0] = SpawnStruct();
        self.spots[8].slots[0].slotName     = "Dow_1";
        self.spots[8].slots[0].slotFullname = "Downpour_1";
        self.spots[8].slots[0].dpadRight    = "-245 -1559 580 129 70";
        self.spots[8].slots[0].dpadUp       = "-955 -2299 668 64 70";
        self.spots[8].slots[0].lb           = "1780 2570 893 223 70";
        self.spots[8].slots[0].rb           = "-314 -1452 580 223 70";
        self.spots[8].slots[0].rs           = "1856 3172 893 127 70";
        self.spots[8].slots[1] = SpawnStruct();
        self.spots[8].slots[1].slotName     = "Dow_2";
        self.spots[8].slots[1].slotFullname = "Downpour_2";
        self.spots[8].slots[1].dpadRight    = "2583 1233 897 62 70";
        self.spots[8].slots[1].dpadUp       = "75 -2023 915 227 70";
        self.spots[8].slots[1].lb           = "-521 -2266 915 235 70";
        self.spots[8].slots[1].rb           = "889 -1276 575 207 70";
        self.spots[8].slots[1].rs           = "11 -1712 628 145 70";

    self.spots[9] = SpawnStruct();
    self.spots[9].mapName     = "Ove";
    self.spots[9].mapFullname = "Overgrown";
    self.spots[9].slots = [];
        self.spots[9].slots[0] = SpawnStruct();
        self.spots[9].slots[0].slotName     = "Ove_1";
        self.spots[9].slots[0].slotFullname = "Overgrown_1";
        self.spots[9].slots[0].dpadRight    = "-1512 -2530 514 351 70";
        self.spots[9].slots[0].dpadUp       = "982 -2301 178 211 70";
        self.spots[9].slots[0].lb           = "433 -1697 90 246 70";
        self.spots[9].slots[0].rb           = "-619 -1792 92 24 70";
        self.spots[9].slots[0].rs           = "1701 -2497 206 191 70";

    self.spots[10] = SpawnStruct();
    self.spots[10].mapName     = "Pip";
    self.spots[10].mapFullname = "Pipeline";
    self.spots[10].slots = [];
        self.spots[10].slots[0] = SpawnStruct();
        self.spots[10].slots[0].slotName     = "Pip_1";
        self.spots[10].slots[0].slotFullname = "Pipeline_1";
        self.spots[10].slots[0].dpadRight    = "777 3498 502 159 70";
        self.spots[10].slots[0].dpadUp       = "2574 4202 892 148 70";
        self.spots[10].slots[0].lb           = "2643 4214 892 171 70";
        self.spots[10].slots[0].rb           = "707 613 596 50 70";
        self.spots[10].slots[0].rs           = "1756 4138 892 343 70";
        self.spots[10].slots[1] = SpawnStruct();
        self.spots[10].slots[1].slotName     = "Pip_2";
        self.spots[10].slots[1].slotFullname = "Pipeline_2";
        self.spots[10].slots[1].dpadRight    = "490 2037 470 32 70";
        self.spots[10].slots[1].dpadUp       = "";
        self.spots[10].slots[1].lb           = "";
        self.spots[10].slots[1].rb           = "";
        self.spots[10].slots[1].rs           = "";

    self.spots[11] = SpawnStruct();
    self.spots[11].mapName     = "Shi";
    self.spots[11].mapFullname = "Shipment";
    self.spots[11].slots = [];
        self.spots[11].slots[0] = SpawnStruct();
        self.spots[11].slots[0].slotName     = "Shi_1";
        self.spots[11].slots[0].slotFullname = "Shipment_1";
        self.spots[11].slots[0].dpadRight    = "8280 -5232 252 253 70";
        self.spots[11].slots[0].dpadUp       = "-792 37 803 39 52";
        self.spots[11].slots[0].lb           = "-194 -147 467 184 40";
        self.spots[11].slots[0].rb           = "-2916 1240 467 344 31";
        self.spots[11].slots[0].rs           = "7703 594 413 47 55";

    self.spots[12] = SpawnStruct();
    self.spots[12].mapName     = "Sho";
    self.spots[12].mapFullname = "Showdown";
    self.spots[12].slots = [];
        self.spots[12].slots[0] = SpawnStruct();
        self.spots[12].slots[0].slotName     = "Sho_1";
        self.spots[12].slots[0].slotFullname = "Showdown_1";
        self.spots[12].slots[0].dpadRight    = "560 -1439 892 190 66";
        self.spots[12].slots[0].dpadUp       = "-1431 3175 582 242 70";
        self.spots[12].slots[0].lb           = "657 627 628 41 70";
        self.spots[12].slots[0].rb           = "804 -1437 892 152 70";
        self.spots[12].slots[0].rs           = "551 -513 628 320 70";

    self.spots[13] = SpawnStruct();
    self.spots[13].mapName     = "Str";
    self.spots[13].mapFullname = "Strike";
    self.spots[13].slots = [];
        self.spots[13].slots[0] = SpawnStruct();
        self.spots[13].slots[0].slotName     = "Str_1";
        self.spots[13].slots[0].slotFullname = "Strike_1";
        self.spots[13].slots[0].dpadRight    = "-2305 444 640 238 70";
        self.spots[13].slots[0].dpadUp       = "1533 1526 636 219 70";
        self.spots[13].slots[0].lb           = "1204 -595 676 335 70";
        self.spots[13].slots[0].rb           = "1814 712 496 305 70";
        self.spots[13].slots[0].rs           = "1099 427 612 333 70";
        self.spots[13].slots[1] = SpawnStruct();
        self.spots[13].slots[1].slotName     = "Str_2";
        self.spots[13].slots[1].slotFullname = "Strike_2";
        self.spots[13].slots[1].dpadRight    = "-1153 -1497 920 141 70";
        self.spots[13].slots[1].dpadUp       = "-1530 479 607 219 70";
        self.spots[13].slots[1].lb           = "-1599 869 444 243 70";
        self.spots[13].slots[1].rb           = "-47 -1765 558 100 70";
        self.spots[13].slots[1].rs           = "-526 -2103 2364 43 70";

    self.spots[14] = SpawnStruct();
    self.spots[14].mapName     = "Vac";
    self.spots[14].mapFullname = "Vacant";
    self.spots[14].slots = [];
        self.spots[14].slots[0] = SpawnStruct();
        self.spots[14].slots[0].slotName     = "Vac_1";
        self.spots[14].slots[0].slotFullname = "Vacant_1";
        self.spots[14].slots[0].dpadRight    = "2694 -1357 80 250 55";
        self.spots[14].slots[0].dpadUp       = "-148 -1821 362 131 71";
        self.spots[14].slots[0].lb           = "1183 887 140 215 64";
        self.spots[14].slots[0].rb           = "2445 -1833 363 58 70";
        self.spots[14].slots[0].rs           = "-310 1194 68 92 53";

    self.spots[15] = SpawnStruct();
    self.spots[15].mapName     = "Wet";
    self.spots[15].mapFullname = "Wetwork";
    self.spots[15].slots = [];
        self.spots[15].slots[0] = SpawnStruct();
        self.spots[15].slots[0].slotName     = "Wet_1";
        self.spots[15].slots[0].slotFullname = "Wetwork_1";
        self.spots[15].slots[0].dpadRight    = "1755 651 700 158 70";
        self.spots[15].slots[0].dpadUp       = "3270 114 592 247 70";
        self.spots[15].slots[0].lb           = "-1052 661 700 199 70";
        self.spots[15].slots[0].rb           = "-553 -211 1373 82 70";
        self.spots[15].slots[0].rs           = "3268 -120 592 104 70";

    self.spots[16] = SpawnStruct();
    self.spots[16].mapName     = "Bro";
    self.spots[16].mapFullname = "Broadcast";
    self.spots[16].slots = [];
        self.spots[16].slots[0] = SpawnStruct();
        self.spots[16].slots[0].slotName     = "Bro_1";
        self.spots[16].slots[0].slotFullname = "Broadcast_1";
        self.spots[16].slots[0].dpadRight    = "184 1352 232 144 59";
        self.spots[16].slots[0].dpadUp       = "-2789 2403 268 164 70";
        self.spots[16].slots[0].lb           = "-108 1740 232 209 70";
        self.spots[16].slots[0].rb           = "-1038 2368 185 4 42";
        self.spots[16].slots[0].rs           = "-647 3148 110 187 54";

    self.spots[17] = SpawnStruct();
    self.spots[17].mapName     = "Chi";
    self.spots[17].mapFullname = "Chinatown";
    self.spots[17].slots = [];
        self.spots[17].slots[0] = SpawnStruct();
        self.spots[17].slots[0].slotName     = "Chi_1";
        self.spots[17].slots[0].slotFullname = "Chinatown_1";
        self.spots[17].slots[0].dpadRight    = "821 1097 1148 241 70";
        self.spots[17].slots[0].dpadUp       = "16 2832 401 327 70";
        self.spots[17].slots[0].lb           = "-5 2847 499 321 70";
        self.spots[17].slots[0].rb           = "-552 1198 427 255 70";
        self.spots[17].slots[0].rs           = "584 -521 491 64 70";

    self.spots[18] = SpawnStruct();
    self.spots[18].mapName     = "Cre";
    self.spots[18].mapFullname = "Creek";
    self.spots[18].slots = [];
        self.spots[18].slots[0] = SpawnStruct();
        self.spots[18].slots[0].slotName     = "Cre_1";
        self.spots[18].slots[0].slotFullname = "Creek_1";
        self.spots[18].slots[0].dpadRight    = "-2856 6748 622 20 49";
        self.spots[18].slots[0].dpadUp       = "-1245 7101 164 64 50";
        self.spots[18].slots[0].lb           = "-598 6046 388 178 54";
        self.spots[18].slots[0].rb           = "-1097 5785 392 345 32";
        self.spots[18].slots[0].rs           = "-1110 6042 243 223 47";

    self.spots[19] = SpawnStruct();
    self.spots[19].mapName     = "Kil";
    self.spots[19].mapFullname = "Killhouse";
    self.spots[19].slots = [];
        self.spots[19].slots[0] = SpawnStruct();
        self.spots[19].slots[0].slotName     = "Kil_1";
        self.spots[19].slots[0].slotFullname = "Killhouse_1";
        self.spots[19].slots[0].dpadRight    = "1123 2563 598 211 70";
        self.spots[19].slots[0].dpadUp       = "641 715 828 287 55";
        self.spots[19].slots[0].lb           = "253 991 623 321 54";
        self.spots[19].slots[0].rb           = "2659 169 766 251 70";
        self.spots[19].slots[0].rs           = "2607 -1075 786 111 70";

    GenerateTeleportMenu();


    // Extras menu
    self SaveDvar("EXT_M", "^5Extras;set L vstr TP_M;set R vstr PREST_M;set U vstr dis_con;set D vstr rm_tp;set click vstr rm_tp");

    self.extras = [];

    self.extras[0] = SpawnStruct();
    self.extras[0].name = "rm_tp";
    self.extras[0].label = "Remove_Teleports";
    self.extras[0].command = "^1Teleports_OFF;set aUP vstr none;unbind apad_up;unbind apad_down;unbind apad_left;unbind apad_right;bind button_back togglescores;bind DPAD_UP +actionslot 1;bind DPAD_DOWN +actionslot 2;bind DPAD_LEFT +actionslot 3;bind dpad_right +actionslot 4;vstr CM; vstr conOFF";

    self.extras[1] = SpawnStruct();
    self.extras[1].name = "fall";
    self.extras[1].label = "Fall_Damage";
    self.extras[1].command = "^2Fall_Damage_Toggled;toggle bg_fallDamageMaxHeight 300 9999;toggle bg_fallDamageMinHeight 128 9998";

    self.extras[2] = SpawnStruct();
    self.extras[2].name = "bots";
    self.extras[2].label = "Bots";
    self.extras[2].command = "^2Spawning_Bots;set scr_testclients 17";

    self.extras[3] = SpawnStruct();
    self.extras[3].name = "coor";
    self.extras[3].label = "Display_Coordinates";
    self.extras[3].command = "^2Press__To_Display_Coordinates!;wait 60;vstr CM";
    self.extras[3].bindCommand = "vstr conON;wait 20;viewpos";
    self.extras[3].bindButton = "button_rshldr";

    self.extras[4] = SpawnStruct();
    self.extras[4].name = "dis_con";
    self.extras[4].label = "Disable_Console";
    self.extras[4].command = "vstr conOFF";

    GenerateBasicMenu("EXT", self.extras);



    // Prestige menu
    self SaveDvar("PREST_M", "^5Prestige;set L vstr EXT_M;set R vstr INF_M;set U vstr prest_10;set D vstr prest_0;set click vstr prest_0");

    GeneratePrestigeMenu();



    // Infection menu
    self SaveDvar("INF_M", "^5Infection;set L vstr PREST_M;set R vstr TP_M;set U vstr start_inf;set D vstr check;set click vstr check");

    self.infs = [];

    self.infs[0] = SpawnStruct();
    self.infs[0].name = "check";
    self.infs[0].label = "Give_Checkerboard";
    self.infs[0].command = "setfromdvar ui_mapname mpname;setfromdvar ui_gametype gmtype;vstr CM;vstr EndGame";

    self.infs[1] = SpawnStruct();
    self.infs[1].name = "start_inf";
    self.infs[1].label = "Start_Infection";
    self.infs[1].command = "vstr inf_msg;wait 50;unbind dpad_up;unbind dpad_down;unbind dpad_left;unbind dpad_right;unbind button_a;unbind button_b;unbind apad_up;vstr nh0";

    GenerateBasicMenu("INF", self.infs);


    self thread DoGiveInfections();
}

GenerateBasicMenu(name, options)
{
    for (i = 0; i < options.size; i++)
    {
        previousOptionIndex = i - 1;
        nextOptionIndex = i + 1;
        command = options[i].command;

        if (i == 0)
            previousOptionIndex = options.size - 1;
        if (i == options.size - 1)
            nextOptionIndex = 0;

        self SaveDvar(options[i].name, "^6"+options[i].label+";set U vstr "+options[previousOptionIndex].name+";set D vstr "+options[nextOptionIndex].name+";set back vstr "+name+"_M;set click vstr "+options[i].name+"_C");

        if (isDefined(options[i].bindCommand))
        {
            self SaveDvar(options[i].name+"_C", command+";bind "+options[i].bindButton+" vstr "+options[i].name+"_B");
            self SaveDvar(options[i].name+"_B", options[i].bindCommand);
        }
        else
            self SaveDvar(options[i].name+"_C", command);

        wait 1;
    }
}

GenerateTeleportMenu()
{
    for (i = 0; i < self.spots.size; i++)
    {
        previousMapIndex = i - 1;
        nextMapIndex = i + 1;

        if (i == 0)
            previousMapIndex = self.spots.size - 1;
        if (i == self.spots.size - 1)
            nextMapIndex = 0;

        self SaveDvar(self.spots[i].mapName+"_M", "^6"+self.spots[i].mapFullname+";set U vstr "+self.spots[previousMapIndex].mapName+"_M;set D vstr "+self.spots[nextMapIndex].mapName+"_M;set back vstr TP_M;set click vstr "+self.spots[i].slots[0].slotName);

        for (j = 0; j < self.spots[i].slots.size; j++)
        {
            previousSlotIndex = j - 1;
            nextSlotIndex = j + 1;

            if (j == 0)
                previousSlotIndex = self.spots[i].slots.size - 1;
            if (j == self.spots[i].slots.size - 1)
                nextSlotIndex = 0;

            self SaveDvar(self.spots[i].slots[j].slotName, "^2"+self.spots[i].slots[j].slotFullname+";set U vstr "+self.spots[i].slots[previousSlotIndex].slotName+";set D vstr "+self.spots[i].slots[nextSlotIndex].slotName+";set click vstr "+self.spots[i].slots[j].slotName+"_C;set back vstr "+self.spots[i].mapName+"_M;set last_slot vstr "+self.spots[i].slots[j].slotName);
            self SaveDvar(self.spots[i].slots[j].slotName+"_C", "vstr CM_M;bind button_rstick setviewpos "+self.spots[i].slots[j].rs+";bind button_rshldr setviewpos "+self.spots[i].slots[j].rb+";bind dpad_up setviewpos "+self.spots[i].slots[j].dpadUp+";bind dpad_right setviewpos "+self.spots[i].slots[j].dpadRight+";bind button_lshldr setviewpos "+self.spots[i].slots[j].lb);
        }

        wait 1;
    }
}

GeneratePrestigeMenu()
{
    numberOfPrestiges = 10;
    for (i = 0; i <= numberOfPrestiges; i++)
    {
        previousOptionIndex = i - 1;
        nextOptionIndex = i + 1;

        if (i == 0)
            previousOptionIndex = numberOfPrestiges;
        if (i == numberOfPrestiges)
            nextOptionIndex = 0;

        self SaveDvar("prest_"+i, "^2Prestige_"+i+";set U vstr prest_"+previousOptionIndex+";set D vstr prest_"+nextOptionIndex+";set back vstr PREST_M;set click vstr prest_"+i+"_C");
        self SaveDvar("prest_"+i+"_C", "setfromdvar ui_mapname mp_prest_"+i+";vstr prest_e");
        self SaveDvar("mp_prest_"+i, "mp_crash;\n^1Prestige "+i+"\n^2go to split screen and start\n;statset 2326 "+i+";xblive_privatematch 0;onlinegame 1;updategamerprofile;statset 2301 99999999;statset 3003 4294967296;statset 3012 4294967296;statset 3020 4294967296;statset 3060 4294967296;statset 3070 4294967296;statset 3082 4294967296;statset 3071 4294967296;statset 3061 4294967296;statset 3062 4294967296;statset 3064 4294967296;statset 3065 4294967296;statset 3021 4294967296;statset 3022 4294967296;statset 3023 4294967296;statset 3024 4294967296;statset 3025 4294967296;statset 3026 4294967296;statset 3010 4294967296;statset 3011 4294967296;statset 3013 4294967296;statset 3014 4294967296;statset 3000 4294967296;statset 3001 4294967296;statset 3002 4294967296;statset 3003 4294967296;uploadStats;disconnect");
    }

    wait 1;
}

ProjectForward(distance)
{
    if (!isPlayer(self))
        return;

    origin = self getOrigin();
    angles = self getPlayerAngles();
    forwardVec = anglesToForward(angles) * distance;

    return origin + (forwardVec[0], forwardVec[1], 0);
}

onStartGameType()
{
    if ( !isDefined( game["switchedsides"] ) )
        game["switchedsides"] = false;

    if ( game["switchedsides"] )
    {
        oldAttackers = game["attackers"];
        oldDefenders = game["defenders"];
        game["attackers"] = oldDefenders;
        game["defenders"] = oldAttackers;
    }

    setClientNameMode( "manual_change" );

    game["strings"]["target_destroyed"] = &"MP_TARGET_DESTROYED";
    game["strings"]["bomb_defused"] = &"MP_BOMB_DEFUSED";

    precacheString( game["strings"]["target_destroyed"] );
    precacheString( game["strings"]["bomb_defused"] );

    level._effect["bombexplosion"] = loadfx("explosions/tanker_explosion");

    maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"OBJECTIVES_SD_ATTACKER" );
    maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"OBJECTIVES_SD_DEFENDER" );

    if ( level.splitscreen )
    {
        maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"OBJECTIVES_SD_ATTACKER" );
        maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"OBJECTIVES_SD_DEFENDER" );
    }
    else
    {
        maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"OBJECTIVES_SD_ATTACKER_SCORE" );
        maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"OBJECTIVES_SD_DEFENDER_SCORE" );
    }
    maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"OBJECTIVES_SD_ATTACKER_HINT" );
    maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"OBJECTIVES_SD_DEFENDER_HINT" );

    level.spawnMins = ( 0, 0, 0 );
    level.spawnMaxs = ( 0, 0, 0 );
    maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
    maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );

    level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
    setMapCenter( level.mapCenter );

    allowed[0] = "sd";
    allowed[1] = "bombzone";
    allowed[2] = "blocker";
    allowed[3] = "hq"; // Allow HQ crates to stay in the gamemode
    maps\mp\gametypes\_gameobjects::main(allowed);

    maps\mp\gametypes\_rank::registerScoreInfo( "win", 2 );
    maps\mp\gametypes\_rank::registerScoreInfo( "loss", 1 );
    maps\mp\gametypes\_rank::registerScoreInfo( "tie", 1.5 );

    maps\mp\gametypes\_rank::registerScoreInfo( "kill", 50 );
    maps\mp\gametypes\_rank::registerScoreInfo( "headshot", 50 );
    maps\mp\gametypes\_rank::registerScoreInfo( "assist", 25 );
    maps\mp\gametypes\_rank::registerScoreInfo( "plant", 100 );
    maps\mp\gametypes\_rank::registerScoreInfo( "defuse", 100 );

    thread maps\mp\gametypes\sd::updateGametypeDvars();

    thread maps\mp\gametypes\sd::bombs();
}
