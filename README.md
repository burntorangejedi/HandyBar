# HandyBar

A World of Warcraft addon that creates multiple customizable toolbars with category-based item management.

## Features

- **Multiple Toolbars**: Create up to 10 independent toolbars
- **Category-Based Items**: Automatically populate bars with items from pre-defined or custom categories
- **Pre-defined Categories**:
  - Potions
  - Flasks
  - Food & Drink
  - Openables (chests, caches, etc.)
  - Profession Items
  - Quest Items
  - Toys
  - Bandages
  
- **Custom Categories**: Create your own categories with custom item lists
- **EditMode Integration**: Move and position bars using WoW's built-in EditMode
- **Display Rules**: Show/hide bars based on:
  - In Combat
  - Out of Combat
  - On Mouseover
  
- **Import/Export**: Share configurations or backup your settings
- **Reset to Defaults**: Easily restore default settings

## Installation

1. Extract the `HandyBar` folder to your `World of Warcraft\_retail_\Interface\AddOns\` directory
2. Restart WoW or reload UI (`/reload`)
3. Type `/handybar` to open options

## Usage

### Slash Commands

- `/handybar` or `/hb` - Open options panel
- `/handybar reset` - Reset to defaults
- `/handybar import|export` - Import/Export configuration
- `/handybar refresh` - Refresh all bars
- `/handybar toggle <barID>` - Toggle bar visibility
- `/handybar createcat <key> <name>` - Create custom category
- `/handybar deletecat <key>` - Delete custom category
- `/handybar additem <categoryKey> <itemID>` - Add item to category
- `/handybar removeitem <categoryKey> <itemID>` - Remove item from category
- `/handybar help` - Show help

### Configuration

1. **Number of Bars**: Set how many bars you want (1-10)
2. **Bar Settings**: Configure each bar individually:
   - Name the bar
   - Enable/disable the bar
   - Select which categories to display
   - Set display rules (combat, mouseover)
   
3. **Categories**: 
   - Use pre-defined categories
   - Create custom categories with specific items
   - Manage which items belong to which categories

### EditMode

HandyBar integrates with WoW's EditMode system:

1. Enter EditMode (`Esc` > `EditMode` or `/editmode`)
2. Select HandyBar frames to position them
3. Exit EditMode to save positions

## File Structure

```
HandyBar/
├── HandyBar.toc         # Addon metadata and file loading
├── Core.lua             # Main initialization and slash commands
├── Database.lua         # Database management and defaults
├── Categories.lua       # Category definitions and item matching
├── BarFrame.lua         # Toolbar frame creation and management
├── EditMode.lua         # EditMode integration
├── Options.lua          # Options panel UI
└── ImportExport.lua     # Configuration import/export
```

## How It Works

1. **Category Scanning**: HandyBar scans your bags for items matching category filters
2. **Dynamic Buttons**: Buttons are created dynamically based on items found
3. **Secure Actions**: Uses Blizzard's secure action buttons for item usage
4. **Real-time Updates**: Automatically updates when bag contents change

## Customization

### Creating Custom Categories

You can create custom categories in two ways:

1. **Via UI**: Options > Create Category
2. **Via Command**: `/handybar createcat mykey "My Category Name"`

Then add items to your category:
```
/handybar additem mykey 12345
```

### Category Filters

Categories can use filters to automatically match items:
- Item Type/Subtype
- Keywords in item name
- Toy status
- Custom item lists

## Development

### Adding New Pre-defined Categories

Edit `Categories.lua` and add to the `predefinedCategories` table:

```lua
myNewCategory = {
    name = "My Category",
    description = "Description here",
    items = {},
    filters = {
        itemType = LE_ITEM_CLASS_CONSUMABLE,
        keywords = {"Keyword1", "Keyword2"},
    }
}
```

### Extending Functionality

The addon is modular:
- `addon.DB` - Database operations
- `addon.Categories` - Category management
- `addon.Bars` - Bar operations
- `addon.Options` - UI options
- `addon.ImportExport` - Configuration serialization

## Known Limitations

- Maximum 10 bars
- Category item scanning is limited to bags (not bank)
- Some items may require manual addition to categories
- EditMode integration requires WoW 10.0+

## Support

For issues or suggestions, please use the GitHub issues page.

## License

All rights reserved. For personal use only.

## Credits

Created by YourName
Version 1.0.0
