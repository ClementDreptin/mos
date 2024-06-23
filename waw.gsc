#include maps\mp\gametypes\_hud_util;

init()
{
    // Only start the initialization in private matches and offline matches (splitscreen and system link)
    if (getDvarInt("xblive_privatematch") || !getDvarInt("onlinegame"))
        level thread OnPlayerConnect();
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

            setDvar("player_bayonetLaunchProof", "0");
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
CreateRectangle(align, relative, x, y, width, height, color, alpha  )
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
    self.inMenu = false;
    self thread MonitorControls();

    for (;;)
    {
        self waittill("buttonPressed", button);

        if (button == "LB" && self GetStance() == "crouch" && !self.inMenu)
        {
            self.inMenu = true;
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
    self AddMenu("main_mods", "Main Mods", "God Mode;Fall Damage;Ammo;Blast Marks;Old School;Move Bomb (SnD ONLY)", "main");
    self AddFunction("main_mods", ::ToggleGodMode, "");
    self AddFunction("main_mods", ::ToggleFallDamage, "");
    self AddFunction("main_mods", ::ToggleAmmo, "");
    self AddFunction("main_mods", ::ToggleBlastMarks, "");
    self AddFunction("main_mods", ::ToggleOldSchool, "");
    self AddFunction("main_mods", ::MoveBomb, "");

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
    self AddFunction("admin", ::RunSub, "Verify");
        // Verify menu
        self AddMenu("Verify", "Verify", playerNamesList, "admin");
        for (i = 0; i < playersList.size; i++)
            self AddFunction("Verify", ::Verify, playersList[i]);
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
                    self.inMenu = false;
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

InitBomb()
{
    entities = getEntArray();
    bombBrushModels = [];

    // Loop through all the entities
    for (i = 0; i < entities.size; i++)
    {
        if (!isDefined(entities[i].script_gameobjectname))
            continue;

        // Look for the bomb zones
        if (entities[i].script_gameobjectname == "bombzone")
        {
            // Save the first bomb script model
            if (entities[i].classname == "script_model")
                level.bomb = entities[i];

            // Save all the bomb brush models
            if (entities[i].classname == "script_brushmodel")
                bombBrushModels[bombBrushModels.size] = entities[i];
        }
    }

    // Make sure we found a bomb
    if (!isDefined(level.bomb) || bombBrushModels.size == 0)
    {
        self iPrintLn("^1Couldn't find a bomb on this map!");
        return;
    }

    // Find the corresponding bomb brush model for the bomb script model
    for (i = 0; i < bombBrushModels.size; i++)
    {
        if (distance(level.bomb.origin, bombBrushModels[i].origin) < 50)
        {
            level.bombBrushModel = bombBrushModels[i];
            break;
        }
    }
    if (!isDefined(level.bombBrushModel))
    {
        self iPrintLn("^1Couldn't find a brush model for this bomb!");
        return;
    }

    // Link to bomb brush model to the bomb script model
    level.bombBrushModel linkTo(level.bomb);
}

MoveBomb()
{
    // Setup the bomb object the first time the bomb is moved
    if (!isDefined(level.bomb))
        self InitBomb();

    // Move the bomb 150 units in front, and 15 below the player
    // The bomb has to be placed a little lower because it's too high to jump on it
    level.bomb.origin = self ProjectForward(150) - (0, 0, 15);

    // Rotate the bomb according to where the player is currently looking
    playerAngles = self getPlayerAngles();
    bombAngles = (level.bomb.angles[0], playerAngles[1] + 90, level.bomb.angles[2]);
    level.bomb rotateTo(bombAngles, 0.01);
}

FreezePosition(position, angles)
{
    self endon("death");
    self endon("disconnect");

    for (;;)
    {
        self forceTeleport(position, angles);
        wait 0.05;
    }
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

        if (button == "RB" && !self.inMenu)
            SavePos();
        else if (button == "LB" && !self.inMenu)
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

        if (button == "X" && !self.inMenu)
        {
            if (!isDefined(self.ufo) || self.ufo == false)
            {
                self allowSpectateTeam("freelook", true);
                self setClientDvar("cg_drawSpectatorMessages", 0);
                self setOrigin(self getEye());
                self.sessionstate = "spectator";
                self.ufo = true;
            }
            else
            {
                self allowSpectateTeam("freelook", false);
                self setClientDvar("cg_drawSpectatorMessages", 1);
                self.sessionstate = "playing";
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
        setDvar("timescale", "2");
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

    self SaveDvar("SETTINGS", "set last_slot vstr Air_M;set player_bayonetLaunchProof 0");

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

    self SaveDvar("last_slot", "vstr Air_M");

    self SaveDvar("prest_e", "setfromdvar ui_gametype GT;^2Ending_Game_Now;vstr CM;vstr EndGame");

    self SaveDvar("conON", "con_minicon 1;con_minicontime 20;con_miniconlines 18");

    self SaveDvar("conOFF", "^1Console_OFF;con_minicon 0;con_minicontime 0");

    self SaveDvar("mp_prepatch", "mp_dome;\n^2Prepatch Bounces\n^2Prepatch Bayonet Lunges\n \n \n^2go to split screen and start\n \n \n ;set player_bayonetLaunchProof 0");

    self SaveDvar("mpname", "mp_dome;\n^2Mos\n \n^2go to split screen and start\n \n \n \n \n;setfromdvar vloop ui_gametype;bind apad_up vstr vloop;seta clanname Inf;reset motd;set com_errorMessage ^2Part 1 DONE!, Join back For Part 2!;updateprofilefromdvars;updategamerprofile;uploadstats;disconnect");

    self SaveDvar("gmtype", "\n;\n;\n;\n;\n;vstr g_teamicon_allies;wait 15;vstr vloop");

    self SaveDvar("EndGame", "^2Ending_Game_Now;set scr_koth_timelimit 0.1;set scr_ctf_timelimit 0.1;set scr_sd_timelimit 0.1;set scr_dm_timelimit 0.1;set scr_war_timelimit 0.1;set scr_dom_timelimit 0.1;set scr_sab_timelimit 0.1;set scr_ffa_timelimit 0.1;set timescale 3");

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
        self.spots[0].slots[1] = SpawnStruct();
        self.spots[0].slots[1].slotName     = "Air_2";
        self.spots[0].slots[1].slotFullname = "Airfield_2";
        self.spots[0].slots[1].dpadRight    = "171 1393 185 90 53";
        self.spots[0].slots[1].dpadUp       = "-20 1742 230 57 66";
        self.spots[0].slots[1].lb           = "44 2028 189 110 55";
        self.spots[0].slots[1].rb           = "2525 1130 216 116 52";
        self.spots[0].slots[1].rs           = "856 2366 568 274 70";
        self.spots[0].slots[2] = SpawnStruct();
        self.spots[0].slots[2].slotName     = "Air_3";
        self.spots[0].slots[2].slotFullname = "Airfield_3";
        self.spots[0].slots[2].dpadRight    = "2854 5270 390 350 70";
        self.spots[0].slots[2].dpadUp       = "1595 3957 194 117 69";
        self.spots[0].slots[2].lb           = "1820 3481 201 339 46";
        self.spots[0].slots[2].rb           = "1762 1560 203 176 51";
        self.spots[0].slots[2].rs           = "883 2430 409 100 70";

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
        self.spots[1].slots[1].rb           = "-1662 -963 716 142 70";
        self.spots[1].slots[1].rs           = "-525 -1225 284 20 70";

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
        self.spots[2].slots[3].dpadRight    = "2840 -2787 318 90 70";
        self.spots[2].slots[3].dpadUp       = "2880 -1486 258 304 54";
        self.spots[2].slots[3].lb           = "3098 -1799 177 327 70";
        self.spots[2].slots[3].rb           = "3031 -1546 280 131 70";
        self.spots[2].slots[3].rs           = "1562 -2584 544 239 70";
        self.spots[2].slots[4] = SpawnStruct();
        self.spots[2].slots[4].slotName     = "Cas_5";
        self.spots[2].slots[4].slotFullname = "Castle_5";
        self.spots[2].slots[4].dpadRight    = "3016 -2105 174 59 70";
        self.spots[2].slots[4].dpadUp       = "2853 -2492 295 111 70";
        self.spots[2].slots[4].lb           = "4040 -274 363 193 70";
        self.spots[2].slots[4].rb           = "4399 -1245 -91 71 70";
        self.spots[2].slots[4].rs           = "944 -2722 544 205 70";
        self.spots[2].slots[5] = SpawnStruct();
        self.spots[2].slots[5].slotName     = "Cas_6";
        self.spots[2].slots[5].slotFullname = "Castle_6";
        self.spots[2].slots[5].dpadRight    = "1508 -295 17 246 70";
        self.spots[2].slots[5].dpadUp       = "1508 -763 16 115 70";
        self.spots[2].slots[5].lb           = "1848 -1574 -32 341 51";
        self.spots[2].slots[5].rb           = "3232 -1513 260 253 56";
        self.spots[2].slots[5].rs           = "-664 -2465 -70 129 63";
        self.spots[2].slots[6] = SpawnStruct();
        self.spots[2].slots[6].slotName     = "Cas_7";
        self.spots[2].slots[6].slotFullname = "Castle_7";
        self.spots[2].slots[6].dpadRight    = "2457 -2620 214 127 70";
        self.spots[2].slots[6].dpadUp       = "1681 -3184 544 176 70";
        self.spots[2].slots[6].lb           = "2614 -2949 210 225 70";
        self.spots[2].slots[6].rb           = "4470 -753 -89 261 70";
        self.spots[2].slots[6].rs           = "3123 -652 -158 32 70";

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
        self.spots[3].slots[1].lb           = "-1839 1852 -199 341 70";
        self.spots[3].slots[1].rb           = "-809 -1046 140 308 70";
        self.spots[3].slots[1].rs           = "-3314 642 67 104 70";
        self.spots[3].slots[2] = SpawnStruct();
        self.spots[3].slots[2].slotName     = "Cli_3";
        self.spots[3].slots[2].slotFullname = "Cliffside_3";
        self.spots[3].slots[2].dpadRight    = "-3219 141 -22 164 67";
        self.spots[3].slots[2].dpadUp       = "-3816 1022 -14 229 48";
        self.spots[3].slots[2].lb           = "-3641 -152 -21 305 63";
        self.spots[3].slots[2].rb           = "-3857 846 32 185 70";
        self.spots[3].slots[2].rs           = "834 -1076 140 358 70";

    self.spots[4] = SpawnStruct();
    self.spots[4].mapName     = "Cou";
    self.spots[4].mapFullname = "Courtyard";
    self.spots[4].slots = [];
        self.spots[4].slots[0] = SpawnStruct();
        self.spots[4].slots[0].slotName     = "Cou_1";
        self.spots[4].slots[0].slotFullname = "Courtyard_1";
        self.spots[4].slots[0].dpadRight    = "5662 -744 358 357 69";
        self.spots[4].slots[0].dpadUp       = "5084 -1409 351 64 70";
        self.spots[4].slots[0].lb           = "4579 -1386 265 87 31";
        self.spots[4].slots[0].rb           = "5668 -54 358 352 70";
        self.spots[4].slots[0].rs           = "4943 183 366 310 70";

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
        self.spots[5].slots[1] = SpawnStruct();
        self.spots[5].slots[1].slotName     = "Dom_2";
        self.spots[5].slots[1].slotFullname = "Dome_2";
        self.spots[5].slots[1].dpadRight    = "-664 2524 431 105 45";
        self.spots[5].slots[1].dpadUp       = "737 3119 477 277 48";
        self.spots[5].slots[1].lb           = "89 351 832 231 70";
        self.spots[5].slots[1].rb           = "-840 2436 -673 77 40";
        self.spots[5].slots[1].rs           = "979 1628 530 97 41";

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
        self.spots[6].slots[2].dpadUp       = "4625 5377 251 35 45";
        self.spots[6].slots[2].lb           = "4508 5317 375 343 70";
        self.spots[6].slots[2].rb           = "2078 7221 528 218 70";
        self.spots[6].slots[2].rs           = "2218 7220 526 219 62";
        self.spots[6].slots[3] = SpawnStruct();
        self.spots[6].slots[3].slotName     = "Dow_4";
        self.spots[6].slots[3].slotFullname = "Downfall_4";
        self.spots[6].slots[3].dpadRight    = "-1038 9226 636 240 70";
        self.spots[6].slots[3].dpadUp       = "3114 8142 291 339 70";
        self.spots[6].slots[3].lb           = "1211 9478 636 178 70";
        self.spots[6].slots[3].rb           = "-860 7838 636 223 70";
        self.spots[6].slots[3].rs           = "1115 8515 459 18 70";
        self.spots[6].slots[4] = SpawnStruct();
        self.spots[6].slots[4].slotName     = "Dow_5";
        self.spots[6].slots[4].slotFullname = "Downfall_5";
        self.spots[6].slots[4].dpadRight    = "1700 9645 636 42 70";
        self.spots[6].slots[4].dpadUp       = "1762 9701 636 269 70";
        self.spots[6].slots[4].lb           = "1419 9634 636 3 70";
        self.spots[6].slots[4].rb           = "1407 8295 428 181 70";
        self.spots[6].slots[4].rs           = "1167 8573 665 144 70";
        self.spots[6].slots[5] = SpawnStruct();
        self.spots[6].slots[5].slotName     = "Dow_6";
        self.spots[6].slots[5].slotFullname = "Downfall_6";
        self.spots[6].slots[5].dpadRight    = "2391 8161 178 46 55";
        self.spots[6].slots[5].dpadUp       = "1721 10617 434 16 70";
        self.spots[6].slots[5].lb           = "1808 10616 434 13 70";
        self.spots[6].slots[5].rb           = "-765 6987 417 188 60";
        self.spots[6].slots[5].rs           = "3108 8963 772 30 70";
        self.spots[6].slots[6] = SpawnStruct();
        self.spots[6].slots[6].slotName     = "Dow_7";
        self.spots[6].slots[6].slotFullname = "Downfall_7";
        self.spots[6].slots[6].dpadRight    = "2252 8804 1188 128 70";
        self.spots[6].slots[6].dpadUp       = "-1506 9914 636 214 70";
        self.spots[6].slots[6].lb           = "-1468 9646 636 45 70";
        self.spots[6].slots[6].rb           = "182 10964 1340 38 70";
        self.spots[6].slots[6].rs           = "1905 11142 476 316 70";
        self.spots[6].slots[7] = SpawnStruct();
        self.spots[6].slots[7].slotName     = "Dow_8";
        self.spots[6].slots[7].slotFullname = "Downfall_8";
        self.spots[6].slots[7].dpadRight    = "1445 11012 1340 321 70";
        self.spots[6].slots[7].dpadUp       = "2011 11311 754 274 70";
        self.spots[6].slots[7].lb           = "3362 10962 1340 110 70";
        self.spots[6].slots[7].rb           = "3571 10963 1340 111 70";
        self.spots[6].slots[7].rs           = "-2152 8053 1116 282 70";

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
        self.spots[7].slots[1].rb           = "205 -1289 1743 312 70";
        self.spots[7].slots[1].rs           = "204 -1700 1743 49 70";
        self.spots[7].slots[2] = SpawnStruct();
        self.spots[7].slots[2].slotName     = "Han_3";
        self.spots[7].slots[2].slotFullname = "Hanger_3";
        self.spots[7].slots[2].dpadRight    = "-81 -1145 1257 290 70";
        self.spots[7].slots[2].dpadUp       = "-32 -1158 1257 264 70";
        self.spots[7].slots[2].lb           = "-1078 -745 1257 98 70";
        self.spots[7].slots[2].rb           = "-1191 -691 1257 5 70";
        self.spots[7].slots[2].rs           = "752 -2503 1074 267 70";
        self.spots[7].slots[3] = SpawnStruct();
        self.spots[7].slots[3].slotName     = "Han_4";
        self.spots[7].slots[3].slotFullname = "Hanger_4";
        self.spots[7].slots[3].dpadRight    = "-70 -1182 1257 248 70";
        self.spots[7].slots[3].dpadUp       = "";
        self.spots[7].slots[3].lb           = "";
        self.spots[7].slots[3].rb           = "";
        self.spots[7].slots[3].rs           = "";

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
        self.spots[8].slots[2] = SpawnStruct();
        self.spots[8].slots[2].slotName     = "Mak_3";
        self.spots[8].slots[2].slotFullname = "Makin_3";
        self.spots[8].slots[2].dpadRight    = "-11131 -17727 412 162 70";
        self.spots[8].slots[2].dpadUp       = "-10840 -17557 366 282 61";
        self.spots[8].slots[2].lb           = "-12008 -16434 202 338 70";
        self.spots[8].slots[2].rb           = "-10370 -15707 429 342 70";
        self.spots[8].slots[2].rs           = "-8684 -16138 396 229 70";

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
        self.spots[9].slots[2].rb           = "4696 634 -508 43 70";
        self.spots[9].slots[2].rs           = "-331 1604 -1153 212 70";
        self.spots[9].slots[3] = SpawnStruct();
        self.spots[9].slots[3].slotName     = "Out_4";
        self.spots[9].slots[3].slotFullname = "Outskirts_4";
        self.spots[9].slots[3].dpadRight    = "-782 -673 -1263 110 62";
        self.spots[9].slots[3].dpadUp       = "-1479 -555 -1577 171 59";
        self.spots[9].slots[3].lb           = "-485 629 -893 297 70";
        self.spots[9].slots[3].rb           = "2658 1048 -1100 282 60";
        self.spots[9].slots[3].rs           = "1525 1722 -995 312 68";
        self.spots[9].slots[4] = SpawnStruct();
        self.spots[9].slots[4].slotName     = "Out_5";
        self.spots[9].slots[4].slotFullname = "Outskirts_5";
        self.spots[9].slots[4].dpadRight    = "-1338 -2077 -1339 126 70";
        self.spots[9].slots[4].dpadUp       = "-1909 -374 -1176 64 70";
        self.spots[9].slots[4].lb           = "-1906 -404 -1176 56 70";
        self.spots[9].slots[4].rb           = "818 185 -748 89 70";
        self.spots[9].slots[4].rs           = "-1414 1604 -1236 269 70";

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
        self.spots[10].slots[2] = SpawnStruct();
        self.spots[10].slots[2].slotName     = "Rou_3";
        self.spots[10].slots[2].slotFullname = "Roundhouse_3";
        self.spots[10].slots[2].dpadRight    = "1854 -167 564 27 70";
        self.spots[10].slots[2].dpadUp       = "1771 514 564 22 70";
        self.spots[10].slots[2].lb           = "2946 -682 628 319 70";
        self.spots[10].slots[2].rb           = "756 -3527 572 49 70";
        self.spots[10].slots[2].rs           = "-757 -1848 257 142 70";
        self.spots[10].slots[3] = SpawnStruct();
        self.spots[10].slots[3].slotName     = "Rou_4";
        self.spots[10].slots[3].slotFullname = "Roundhouse_4";
        self.spots[10].slots[3].dpadRight    = "-572 -693 628 324 70";
        self.spots[10].slots[3].dpadUp       = "-619 -992 628 321 70";
        self.spots[10].slots[3].lb           = "2028 -6505 -93 326 54";
        self.spots[10].slots[3].rb           = "2141 -2011 604 122 70";
        self.spots[10].slots[3].rs           = "2876 -3489 572 225 70";

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
        self.spots[11].slots[2] = SpawnStruct();
        self.spots[11].slots[2].slotName     = "See_3";
        self.spots[11].slots[2].slotFullname = "Seelow_3";
        self.spots[11].slots[2].dpadRight    = "1922 2278 542 348 70";
        self.spots[11].slots[2].dpadUp       = "4042 6887 552 50 70";
        self.spots[11].slots[2].lb           = "1725 1990 542 32 70";
        self.spots[11].slots[2].rb           = "4215 1235 180 87 70";
        self.spots[11].slots[2].rs           = "3901 828 69 160 70";
        self.spots[11].slots[3] = SpawnStruct();
        self.spots[11].slots[3].slotName     = "See_4";
        self.spots[11].slots[3].slotFullname = "Seelow_4";
        self.spots[11].slots[3].dpadRight    = "833 448 177 209 70";
        self.spots[11].slots[3].dpadUp       = "2141 2469 299 127 70";
        self.spots[11].slots[3].lb           = "571 2625 542 213 70";
        self.spots[11].slots[3].rb           = "604 2558 542 165 70";
        self.spots[11].slots[3].rs           = "3214 1963 542 303 70";
        self.spots[11].slots[4] = SpawnStruct();
        self.spots[11].slots[4].slotName     = "See_5";
        self.spots[11].slots[4].slotFullname = "Seelow_5";
        self.spots[11].slots[4].dpadRight    = "1244 859 177 68 70";
        self.spots[11].slots[4].dpadUp       = "";
        self.spots[11].slots[4].lb           = "";
        self.spots[11].slots[4].rb           = "";
        self.spots[11].slots[4].rs           = "";

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
        self.spots[12].slots[3].dpadRight    = "657 -2832 -20 16 70";
        self.spots[12].slots[3].dpadUp       = "1670 -3617 52 53 70";
        self.spots[12].slots[3].lb           = "1951 -1588 -114 160 70";
        self.spots[12].slots[3].rb           = "1292 -626 -87 171 66";
        self.spots[12].slots[3].rs           = "1648 -1479 70 147 70";
        self.spots[12].slots[4] = SpawnStruct();
        self.spots[12].slots[4].slotName     = "Uph_5";
        self.spots[12].slots[4].slotFullname = "Upheaval_5";
        self.spots[12].slots[4].dpadRight    = "-357 1945 46 314 70";
        self.spots[12].slots[4].dpadUp       = "11 -2802 -122 149 70";
        self.spots[12].slots[4].lb           = "-1706 -3506 1118 153 70";
        self.spots[12].slots[4].rb           = "";
        self.spots[12].slots[4].rs           = "";

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
    self.extras[2].name = "FPS";
    self.extras[2].label = "FPS_Bind";
    self.extras[2].command = "^2Press_DPAD_LEFT_To_Toggle_FPS!;wait 60;vstr CM";
    self.extras[2].bindCommand = "toggle r_vsync";
    self.extras[2].bindButton = "dpad_left";

    self.extras[3] = SpawnStruct();
    self.extras[3].name = "bots";
    self.extras[3].label = "Bots";
    self.extras[3].command = "^2Spawning_Bots;set scr_testclients 17";

    self.extras[4] = SpawnStruct();
    self.extras[4].name = "coor";
    self.extras[4].label = "Display_Coordinates";
    self.extras[4].command = "^2Press__To_Display_Coordinates!;wait 60;vstr CM";
    self.extras[4].bindCommand = "vstr conON;wait 20;viewpos";
    self.extras[4].bindButton = "button_rshldr";

    self.extras[5] = SpawnStruct();
    self.extras[5].name = "dis_con";
    self.extras[5].label = "Disable_Console";
    self.extras[5].command = "vstr conOFF";

    GenerateBasicMenu("EXT", self.extras);



    // Prestige menu
    self SaveDvar("PREST_M", "^5Prestige;set L vstr EXT_M;set R vstr INF_M;set U vstr prest_10;set D vstr prest_0;set click vstr prest_0");

    GeneratePrestigeMenu();



    // Infection menu
    self SaveDvar("INF_M", "^5Infection;set L vstr PREST_M;set R vstr TP_M;set U vstr start_inf;set D vstr prepatch;set click vstr prepatch");

    self.infs = [];

    self.infs[0] = SpawnStruct();
    self.infs[0].name = "prepatch";
    self.infs[0].label = "Prepatch_Only";
    self.infs[0].command = "setfromdvar ui_mapname mp_prepatch;vstr CM;vstr EndGame";

    self.infs[1] = SpawnStruct();
    self.infs[1].name = "check";
    self.infs[1].label = "Give_Checkerboard";
    self.infs[1].command = "setfromdvar ui_mapname mpname;setfromdvar ui_gametype gmtype;vstr CM;vstr EndGame";

    self.infs[2] = SpawnStruct();
    self.infs[2].name = "start_inf";
    self.infs[2].label = "Start_Infection";
    self.infs[2].command = "vstr inf_msg;wait 50;unbind dpad_up;unbind dpad_down;unbind dpad_left;unbind dpad_right;unbind button_a;unbind button_b;unbind apad_up;vstr nh0";

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
        self SaveDvar("mp_prest_"+i, "mp_dome;\n^1Prestige "+i+"\n^2go to split screen and start\n;statset 2326 "+i+";xblive_privatematch 0;onlinegame 1;updategamerprofile;statset 2301 99999999;statset 3003 4294967296;statset 3012 4294967296;statset 3020 4294967296;statset 3060 4294967296;statset 3070 4294967296;statset 3082 4294967296;statset 3071 4294967296;statset 3061 4294967296;statset 3062 4294967296;statset 3064 4294967296;statset 3065 4294967296;statset 3021 4294967296;statset 3022 4294967296;statset 3023 4294967296;statset 3024 4294967296;statset 3025 4294967296;statset 3026 4294967296;statset 3010 4294967296;statset 3011 4294967296;statset 3013 4294967296;statset 3014 4294967296;statset 3000 4294967296;statset 3001 4294967296;statset 3002 4294967296;statset 3003 4294967296;uploadStats;disconnect");
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
