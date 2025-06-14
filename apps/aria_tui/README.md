# Aria TUI

A dedicated Terminal User Interface (TUI) application for the Aria Timestrike game, featuring a fully responsive grid system, clean separation of concerns, and professional terminal display.

## Features

### 🎯 Responsive Grid System
- **Breakpoint-based layouts**: XS, SM, MD, LG, XL with automatic detection
- **Dynamic column allocation**: 1-3 columns based on terminal width
- **Adaptive panel sizing**: Compact and expanded modes for different screen sizes
- **Professional borders**: Clean box-drawing characters with proper alignment

### 🏗️ Clean Architecture
- **Separation of concerns**: Data/model layer separate from display logic
- **Modular design**: Independent TUI client and display modules
- **Umbrella app**: Completely isolated from game engine and timestrike logic
- **Mix task integration**: Simple `mix tui` command to launch

### 🎨 Enhanced Display
- **Rich ANSI colors**: Professional color scheme with semantic highlighting
- **Unicode support**: Emojis and special characters for better UX
- **Real-time updates**: 100ms tick interval with smooth terminal refresh
- **Interactive controls**: Keyboard shortcuts for game control

## Installation

This is an umbrella app within the Aria Character Core project. The TUI depends on:

```elixir
def deps do
  [
    {:aria_timestrike, path: "../aria_timestrike"},
    {:aria_engine, path: "../aria_engine"}
  ]
end
```

## Usage

### Launching the TUI

```bash
# From the project root
mix tui

# Or from within the aria_tui app
cd apps/aria_tui
mix tui
```

### Keyboard Controls

- **SPACE** - Interrupt/Replan current agent actions
- **P** - Pause/Resume game simulation
- **Q** - Quit the TUI
- **R** - Refresh display (available on larger screens)

## Architecture

### Grid System

The responsive grid system automatically adapts to terminal dimensions:

```elixir
# Breakpoints (terminal width)
@grid %{
  xs: %{min_width: 60, max_width: 79, columns: 1},
  sm: %{min_width: 80, max_width: 99, columns: 2},
  md: %{min_width: 100, max_width: 119, columns: 2},
  lg: %{min_width: 120, max_width: 159, columns: 3},
  xl: %{min_width: 160, max_width: 9999, columns: 3}
}
```

### Layout Configuration

Each breakpoint defines:
- **Header height**: Title and status bar space
- **Controls height**: Input/control panel space  
- **Status height**: Message/feedback panel space
- **Content height**: Remaining space for game content
- **Panel distribution**: How content is split across columns

### Module Structure

```
aria_tui/
├── lib/
│   ├── aria_tui.ex              # Main entry point
│   ├── aria_tui/
│   │   ├── tui_client.ex        # TUI client logic and game loop
│   │   └── tui_display.ex       # Responsive display and grid system
│   └── mix/
│       └── tasks/
│           └── tui.ex           # Mix task for launching TUI
└── mix.exs                      # Dependencies and configuration
```

## Display System

### Responsive Panels

The TUI renders different panel layouts based on screen size:

**XS/SM (1-2 columns)**: Stacked compact panels
- Agents panel (compact format)
- Map/Game state panel
- Combined status and controls

**MD/LG/XL (2-3 columns)**: Side-by-side expanded panels
- Left: Agents panel (detailed format)
- Center: Map panel (if 3 columns)
- Right: Game state and status panels

### Panel Types

1. **Header Panel**: Game title, tick counter, status indicators
2. **Controls Panel**: Keyboard shortcuts and help text
3. **Status Panel**: Messages, notifications, game feedback
4. **Agents Panel**: Agent positions, actions, and status
5. **Map Panel**: Spatial representation of game world

### Color Scheme

The TUI uses a professional color palette:
- **Bright Cyan**: Borders and structural elements
- **Bright White**: Headers and important text
- **Bright Yellow**: Interactive controls and highlights
- **Green**: Success states and positive indicators
- **Red**: Errors and critical alerts
- **Gray**: Secondary text and comments

## Development

### Building

```bash
# Compile with warnings as errors (enforced)
mix compile --warnings-as-errors

# Run tests
mix test

# Generate docs
mix docs
```

### Code Quality

This app enforces strict code quality:
- **Warnings as errors**: All compilation warnings must be fixed
- **Clean module boundaries**: No circular dependencies
- **Consistent naming**: Following Elixir conventions
- **Documentation**: All public functions documented

### Testing the Grid System

You can test the responsive behavior by resizing your terminal window while the TUI is running. The layout will automatically adapt to show the optimal number of columns and panel configurations.

## Architecture Decisions

### Why a Separate Umbrella App?

1. **Clean separation**: TUI logic isolated from game engine
2. **Independent deployment**: Can be excluded from server deployments
3. **Focused dependencies**: Only includes what's needed for terminal display
4. **Easier testing**: UI logic can be tested in isolation

### Why Responsive Grid System?

1. **Better UX**: Adapts to different terminal sizes and preferences
2. **Professional appearance**: Looks good on both small and large terminals
3. **Efficient space usage**: Makes best use of available screen real estate
4. **Accessibility**: Works well with screen readers and terminal multiplexers

### Why Real-time Updates?

1. **Immediate feedback**: Players can see actions and changes as they happen
2. **Better engagement**: More interactive and responsive feel
3. **Debugging aid**: Easier to observe game state changes during development

## Future Enhancements

- **Configurable refresh rate**: Allow users to adjust tick interval
- **Theme support**: Multiple color schemes and display modes
- **Panel customization**: User-configurable panel layouts
- **Mouse support**: Click interactions for terminals that support it
- **Sound integration**: Audio feedback for events (if terminal supports it)
- **Logging integration**: Display logs in dedicated panel
- **Performance metrics**: Show FPS, memory usage, etc.

---

For more information about the Aria Character Core project, see the main project README.

