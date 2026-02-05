# Void Rift Clicker

A dimensional energy harvesting clicker game set in alien space, built with Godot 4.x and C#.

## Quick Start Guide

### Prerequisites
- **Godot 4.2+** with .NET support installed
- **.NET 6.0 SDK** installed

### Opening the Project

1. **Launch Godot 4.x (.NET version)**
   - Make sure you downloaded the ".NET" version of Godot, not the standard version

2. **Import the Project**
   - Click "Import" in the Project Manager
   - Navigate to this folder (`VoidRiftClicker`)
   - Select the `project.godot` file
   - Click "Import & Edit"

3. **Build the C# Project**
   - When the project opens, Godot may ask to build the C# solution
   - Click "Build" or go to `Project → Build Solution` (or press `Alt+B`)
   - Wait for the build to complete (check the Output panel)

4. **Run the Game**
   - Press `F5` or click the Play button (▶) in the top-right
   - The game should launch!

### Troubleshooting

**"Can't find .NET SDK"**
- Install .NET 6.0 SDK from: https://dotnet.microsoft.com/download/dotnet/6.0
- Restart Godot after installation

**"Build Failed"**
- Check the Output panel for specific errors
- Make sure all script files are in the correct folders
- Try `Project → Tools → C# → Create Solution`

**"Scripts not loading"**
- Go to `Project → Project Settings → Autoload`
- Verify all autoloads are listed with correct paths
- The order should be: GameManager, SaveManager, UpgradeManager, AchievementManager, AudioManager

## How to Play

### Basic Controls
- **Left Click** on the portal to harvest Void Energy
- **Press U** to toggle the upgrade panel
- **Ctrl+S** to manually save

### Game Mechanics

**Clicking**
- Click the portal to earn Void Energy
- Maximum 14 clicks per second (prevents auto-clickers)
- Fast clicking (10+ CPS for 5 seconds) activates Frenzy Mode (x2 multiplier)

**Upgrades**
- **Click Upgrades**: Increase energy per click
- **Generators**: Automatically earn energy over time
- **Multipliers**: Multiply all income
- **Special**: Unique abilities and bonuses

**Prestige (Galaxy Reset)**
- When you've earned enough energy, you can perform a "Galaxy Reset"
- This resets most progress but awards permanent "Star Dust"
- Star Dust buys permanent upgrades that persist through resets
- Formula: Star Dust = sqrt(Total Energy / 1 Billion)

## Project Structure

```
VoidRiftClicker/
├── Scenes/           # Godot scene files (.tscn)
│   ├── Main.tscn    # Main game scene
│   ├── UI/          # User interface scenes
│   └── Portal/      # Portal scene
├── Scripts/          # C# code
│   ├── Autoload/    # Singleton managers (always loaded)
│   ├── Core/        # Core systems (BigNumber, etc.)
│   ├── Upgrades/    # Upgrade definitions
│   └── UI/          # UI controllers
├── Resources/        # Game data files
├── Assets/           # Art, audio, fonts
└── project.godot    # Godot project file
```

## Adding Content

### Adding New Upgrades

1. Open `Scripts/Autoload/UpgradeManager.cs`
2. Find the `RegisterAllUpgrades()` method
3. Add a new upgrade using the factory methods:

```csharp
// In RegisterAllUpgrades():
RegisterUpgrade(new ClickUpgrade
{
    Id = "click_my_upgrade",
    DisplayName = "My New Upgrade",
    Description = "Does something cool!",
    ClickPowerBonusValue = 10,
    BaseCostValue = 100,
    CostMultiplier = 1.15
});
```

### Adding Achievements

1. Open `Scripts/Autoload/AchievementManager.cs`
2. Find or create a registration method
3. Add your achievement:

```csharp
Register(new Achievement
{
    Id = "my_achievement",
    Name = "Achievement Name",
    Description = "How to unlock it",
    Category = AchievementCategory.Secret,
    RequiredValue = 100,
    CheckCondition = () => GameManager.Instance?.TotalClicks ?? 0,
    BonusMultiplier = 0.01 // +1% income
});
```

### Adding Sound Effects

1. Place audio files (.ogg or .wav) in `Assets/Audio/SFX/`
2. Name them without extensions in code:

```csharp
AudioManager.Instance.PlaySFX("my_sound"); // Plays my_sound.ogg or my_sound.wav
```

## Save File Location

Saves are stored in Godot's user data directory:
- **Windows**: `%APPDATA%\Godot\app_userdata\Void Rift Clicker\`
- **macOS**: `~/Library/Application Support/Godot/app_userdata/Void Rift Clicker/`
- **Linux**: `~/.local/share/godot/app_userdata/Void Rift Clicker/`

## Steam Integration (Future)

When ready for Steam release:
1. Install the GodotSteam plugin
2. Set up Steamworks account and App ID
3. Configure achievements in Steamworks backend
4. Enable Steam Cloud for save sync

## Credits

Built with Godot Engine 4.x
https://godotengine.org

---

*Click the void, harvest the energy, transcend reality!*
