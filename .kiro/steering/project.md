---
inclusion: auto
name: project
description: Current Godot project architecture. Use when you need to understand project architecture, dependencies and principles. Important when working with project tasks or planning new features.
---

# AnimApp — Architecture Documentation

## 1. Architectural Overview

### Engine Version
Godot 4.6

### Architectural Style
Service-based architecture with Event-Driven Communication and Reactive State Management

The application follows a hybrid architectural pattern combining:
- Service Locator pattern for dependency management
- Event Bus for decoupled communication
- Reactive state management through AppState
- Pure domain logic (RefCounted tools) separated from presentation

### Core Principles
- Low coupling through EventBus and Services locator
- High cohesion within service boundaries
- Separation of concerns: UI, Services, Core Logic, Data
- Data-driven state management with automatic event emission
- Pure logic classes (RefCounted) for tools - no Node dependencies

---

## 2. High-Level System Map

### Runtime Layers

1. **Global Layer** (Autoload Singletons)
   - EventBus: Central event dispatcher
   - Services: Service locator registry
   - AppState: Reactive global state
   - History: Undo/redo management
   - ProjectManager: Project save/load coordination

2. **Service Layer** (Application Logic)
   - ToolService: Tool selection and management
   - LayerService: Layer CRUD operations
   - CanvasService: Drawing operations and pixel manipulation
   - ColorService: Color state management
   - CursorService: Cursor visual state
   - TreeService: Tree/hierarchy management (Life mode)
   - LifeService: Life simulation logic

3. **Core Domain Layer** (Pure Logic / RefCounted)
   - BaseTool: Abstract tool interface
   - BrushTool, EraserTool, FillTool, SelectionTool: Drawing tools
   - MeshTool, LifeTool: Life simulation tools
   - All tools are RefCounted (no Node dependencies)

4. **Data Layer** (Resources)
   - ProjectData: Serializable project state
   - DrawLayerData: Layer serialization format

5. **Presentation Layer** (UI / Scenes)
   - UI CanvasLayer: Main UI container
   - Panels: ToolPanel, LayersPanel, PropertiesPanel, TimelinePanel
   - Tool Properties: BrushProperties, FillProperties, MeshProperties
   - Dialogs: NewProjectDialog, FileDialogs

6. **Rendering / View Layer**
   - DrawContainer + DrawCanvas (SubViewport): Main drawing surface
   - LifeContainer + LifeCanvas (SubViewport): Life simulation view
   - CanvasRenderer: Coordinates rendering for draw mode
   - LifeRenderer: Coordinates rendering for life mode
   - DrawLayer: Individual layer texture rendering
   - SpriteMesh: Mesh representation of sprite layers (Life mode)

### Layer Interaction Flow

```
User Input → UI Components → EventBus → Services → Core Logic → DrawLayer → Canvas Rendering
                                ↓
                            AppState (Reactive)
                                ↓
                            UI Updates
```

---

## 3. Global Systems (Autoloads)

### EventBus
Type: Autoload Singleton

Responsibility:
- Centralized event dispatcher for loose coupling
- Defines all application-wide signals
- Enables components to communicate without direct references

Owns State:
- None (stateless event dispatcher)

Communicates via:
- Signals (emit/connect pattern)
- Categories: Tool events, Layer events, Canvas events, Color events, Camera events, UI events, History events, System events

Used by:
- All services (emit and subscribe)
- UI components (subscribe)
- Core logic (indirectly through services)

### Services
Type: Autoload Singleton (Service Locator)

Responsibility:
- Central registry for all application services
- Provides global access point: `Services.tool`, `Services.layer`, etc.
- Service registration during initialization

Owns State:
- References to all service instances (tool, layer, canvas, color, cursor, tree)

Communicates via:
- Direct method calls (register, are_all_ready)
- Services accessed via property references

Used by:
- All components needing service access
- Services themselves (cross-service communication)

### AppState
Type: Autoload Singleton (Reactive State Container)

Responsibility:
- Centralized reactive state management
- Automatic event emission on state changes through setters
- Single source of truth for application state

Owns State:
- current_tab: Active tab index
- current_tool: Selected tool type
- active_layer_id: Currently selected layer
- active_item_id: Selected item (Life mode)
- primary_color, secondary_color: Drawing colors
- canvas_size: Canvas dimensions
- camera_zoom, camera_position: Camera state
- focused_element: UI focus tracking
- Flags: is_drawing, is_dragging_camera, is_color_picking

Communicates via:
- Setters emit EventBus signals automatically
- Getters provide read access

Used by:
- Services (read/write state)
- UI components (read state, display updates)
- Tools (read state for operations)

### History
Type: Autoload Singleton

Responsibility:
- Undo/redo management using Godot's UndoRedo
- Provides global undo_redo instance

Owns State:
- undo_redo: UndoRedo instance (max 77 steps)

Communicates via:
- Direct access to undo_redo instance
- Services create actions via History.undo_redo

Used by:
- Services (create undo/redo actions)
- Tools (access through services)

### ProjectManager
Type: Autoload Singleton

Responsibility:
- Project save/load coordination
- Auto-save functionality (60s timer + tab switch)
- Project lifecycle management (new, save, load, close)

Owns State:
- current_project_path: Active project file path
- _save_in_progress: Save operation lock
- _auto_save_timer: Timer for periodic saves

Communicates via:
- Signals: project_saved, project_loaded, project_closed, auto_save_triggered, auto_save_completed, auto_save_failed
- Direct calls to Services (canvas, layer)
- EventBus for coordination

Used by:
- UI (menu actions)
- AppState (auto-save on tab change)
- Services (data collection for save)

---

## 4. Services Layer

### ToolService
Type: Service / Manager

Responsibility:
- Tool instance management and lifecycle (separated by mode: Draw/Life)
- Tool selection and activation
- Typed property resource management via signal-based communication
- Tool action coordination (start, update, finish)

Depends on:
- EventBus (tool_selected, layer_selected, tab_changed)
- AppState (current_tool, is_drawing)
- DrawTool instances (BrushTool, EraserTool, FillTool, SelectionTool)
- LifeTool instances (MeshTool)
- Property resources (BrushProps, EraserProps, FillProps, MeshProps)

Side effects:
- Creates tool instances on initialization (separated by draw_tool_instances and life_tool_instances)
- Creates typed property resources and connects them to tools via signals
- Updates AppState.current_tool
- Switches active tool based on mode (active_draw_tool vs active_life_tool)

Notes:
- Refactored from dictionary-based properties to typed Resource classes
- Signal-based communication pattern: Properties emit signals → Tools listen and update internal state
- Each tool connects to its property resource via `connect_to_properties()`

### LayerService
Type: Service / Manager

Responsibility:
- Layer CRUD operations (create, delete, rename, reorder)
- Layer visibility management
- Layer ID generation and recycling
- Undo/redo support for layer operations

Depends on:
- EventBus (layer events)
- AppState (active_layer_id, layer_count)
- History (undo_redo)
- Services.canvas (for image restoration)

Side effects:
- Manages layer data dictionary
- Emits layer lifecycle events
- Creates undo/redo actions
- Recycles freed layer IDs

### CanvasService
Type: Service / Manager

Responsibility:
- DrawLayer creation and management
- Canvas resizing operations
- Image import/export
- Pixel-level operations coordination

Depends on:
- EventBus (layer_created, layer_deleted, canvas_resized)
- AppState (canvas_size)
- DrawCanvas (SubViewport reference)
- DrawLayer instances

Side effects:
- Creates/destroys DrawLayer nodes
- Modifies SubViewport children
- File I/O (save/load images)
- Image format conversion

### ColorService
Type: Service / Manager

Responsibility:
- Color state management
- Primary/secondary color coordination
- Color swap functionality

Depends on:
- EventBus (primary_color_changed, secondary_color_changed)
- AppState (primary_color, secondary_color)

Side effects:
- Updates AppState colors
- Handles swap_colors input action

### CursorService
Type: Service / Manager

Responsibility:
- Custom cursor visual state
- Tool-specific cursor icons
- Cursor override for UI interactions (hover, drag)

Depends on:
- EventBus (tool_selected, ui_element_hovered)
- AppState (current_tool)
- CursorSprite instance
- Tool icon resources

Side effects:
- Creates CursorSprite in CursorLayer
- Updates cursor texture
- Shows/hides cursor

### TreeService
Type: Service / Manager

Responsibility:
- Tree/hierarchy management for Life mode
- Node relationship tracking

Depends on:
- EventBus (tree-related events)

Side effects:
- Manages tree data structures

### LifeService
Type: Service / Manager

Responsibility:
- Life simulation logic coordination
- Life canvas initialization and reference management

Depends on:
- LifeCanvas (SubViewport reference)

Side effects:
- Stores reference to life_canvas SubViewport
- Minimal implementation (initialization only)

---

## 5. Core Domain Layer

### DrawTool (formerly BaseTool)
Type: RefCounted (Pure Logic, Base Class for Draw Mode Tools)

Responsibility:
- Abstract interface for all Draw mode tools
- Defines tool lifecycle: on_press, on_drag, on_release, on_hover, on_mouse_exit, on_resize
- Preview data management (preview_position, preview_color)
- Canvas bounds checking via limits_check()

Depends on:
- History.undo_redo (for undo/redo support)
- Services.tool (for resize operations)
- AppState (for canvas_size bounds checking)

Constraints:
- No Node dependencies (RefCounted)
- No direct scene tree manipulation
- Receives data (position, layer, color) and performs operations
- Works with DrawLayer for pixel manipulation

Notes:
- Renamed from BaseTool to clarify separation from LifeTool
- All Draw mode tools extend this class

---

### BrushTool
Type: RefCounted (extends DrawTool)

Responsibility:
- Pixel drawing with configurable size and shape
- Square and circle brush shapes
- Color blending with alpha support
- Preview rendering

Depends on:
- DrawTool (base class)
- BrushProps (property resource via signals)
- DrawLayer (pixel operations)

Properties:
- _brush_size: int (1-10, updated via signal)
- _brush_shape: int (0=square, 1=circle, updated via signal)

Signal Handlers:
- _on_size_changed: Updates _brush_size
- _on_shape_changed: Updates _brush_shape

Constraints:
- Pure logic, no UI dependencies
- Operates on DrawLayer.image directly
- Signal-based property updates via connect_to_properties()

---

### EraserTool
Type: RefCounted (extends DrawTool)

Responsibility:
- Pixel erasing (set to transparent)
- Configurable eraser size
- Preview rendering

Depends on:
- DrawTool (base class)
- EraserProps (property resource via signals)
- DrawLayer (pixel operations)

Properties:
- _eraser_size: int (1-10, updated via signal)

Signal Handlers:
- _on_size_changed: Updates _eraser_size

Constraints:
- Similar to BrushTool but sets alpha to 0
- Signal-based property updates via connect_to_properties()

---

### FillTool
Type: RefCounted (extends DrawTool)

Responsibility:
- Flood fill algorithm
- Contiguous/non-contiguous fill modes
- Preview rendering (position only)

Depends on:
- DrawTool (base class)
- FillProps (property resource via signals)
- DrawLayer (pixel operations)

Properties:
- _is_contiguous: bool (updated via signal)

Signal Handlers:
- _on_contiguous_changed: Updates _is_contiguous

Operations:
- _flood_fill_contiguous: Flood fill for connected regions
- _flood_fill_all: Fill all pixels of target color
- _colors_match: Color comparison with alpha handling

Constraints:
- Operates on entire image data
- Signal-based property updates via connect_to_properties()

---

### SelectionTool
Type: RefCounted (extends DrawTool)

Responsibility:
- Rectangular selection
- Selection movement
- Copy/paste operations

Depends on:
- DrawTool (base class)
- LayerService (for operations)

Constraints:
- Manages selection state internally
- Coordinates with LayerService for operations

Notes:
- Not refactored in current iteration (still extends DrawTool)

---

### LifeTool
Type: RefCounted (Base Class for Life Mode Tools)

Responsibility:
- Abstract base class for Life mode tools
- Provides common interface for Life tool operations
- Undo/redo support through History

Depends on:
- History.undo_redo (for undo/redo support)

Interface:
- handle_input(event, item): Process input events for SpriteMesh items
- should_draw_preview(answer): Return whether preview should be drawn

Constraints:
- RefCounted (no Node dependencies)
- Works with SpriteMesh items instead of DrawLayer
- Different input model than DrawTool (event-based vs position-based)

Notes:
- Minimal base implementation
- Designed for Life mode tool hierarchy

---

### MeshTool
Type: RefCounted (extends LifeTool)

Responsibility:
- Vertex manipulation for SpriteMesh polygons
- Polygon creation from sprite images (convex hull)
- Mesh generation via Delaunay triangulation
- UV coordinate calculation and synchronization

Depends on:
- LifeTool (base class)
- MeshProps (property resource via signals)
- SpriteMesh (operates on SpriteMesh instances)
- History.undo_redo (inherited from LifeTool)
- Geometry2D (triangulation, convex hull)

Properties:
- mode: Mode enum (SELECT, ADD, REMOVE - not fully implemented)
- active_item: SpriteMesh (current working item)

Operations:
- add_point: Add vertex to polygon
- remove_point: Remove vertex from polygon
- make_mesh: Generate ArrayMesh from vertices using Delaunay triangulation
- create_polygon: Auto-generate convex hull polygon from sprite texture
- _copy_uv: Synchronize UV coordinates with vertices
- _uvs_from_vertices: Calculate normalized UV coordinates

Signal Handlers:
- _on_create_polygon_requested: Triggers create_polygon()
- _on_make_mesh_requested: Triggers make_mesh()
- _on_clear_vertices_requested: Clears vertex/uv/index arrays

Constraints:
- Operates on SpriteMesh items (not DrawLayer)
- Pure logic, no direct scene tree manipulation
- Signal-based communication with MeshProps

Notes:
- Roadmap indicates need for better communication pattern with MeshProperties
- Current signal-based approach implemented but may need iteration

---

### Property Resources

#### BrushProps
Type: Resource (Tool Property)

Responsibility:
- Store and manage BrushTool properties
- Emit signals on property changes

Signals:
- size_changed(new_size: int)
- shape_changed(new_shape: int)

Properties:
- size: int (1-10, clamped)
- shape: int (0=square, 1=circle)

---

#### EraserProps
Type: Resource (Tool Property)

Responsibility:
- Store and manage EraserTool properties
- Emit signals on property changes

Signals:
- size_changed(new_size: int)

Properties:
- size: int (1-10, clamped)

---

#### FillProps
Type: Resource (Tool Property)

Responsibility:
- Store and manage FillTool properties
- Emit signals on property changes

Signals:
- contiguous_changed(new_contiguous: bool)

Properties:
- contiguous: bool

---
Notes:
- Roadmap indicates dissatisfaction with current communication approach

---

## 6. Scene & UI Architecture

### Scene Composition Strategy
- Single main scene (app.tscn) with all UI components
- SubViewport pattern for isolated rendering contexts:
  - DrawCanvas: Main drawing surface
  - LifeCanvas: Life simulation surface
- CanvasLayer for UI overlay
- Node-based service instances (not autoloads, registered with Services)

### UI Control Flow
- Input routing: UI → EventBus → Services → Core Logic
- State updates: Core Logic → AppState → EventBus → UI
- Direct UI interactions: Buttons/Controls → EventBus signals
- Tool actions: DrawContainer/LifeContainer → CanvasRenderer/LifeRenderer → Tool instances

### UI Component Organization
- ToolPanel: Vertical tool selector
- LayersPanel: Layer list with CRUD buttons
- PropertiesPanel: Tool-specific property editors (BrushProperties, FillProperties, MeshProperties)
- TimelinePanel: Animation timeline (future feature)
- WindowPanel: Window controls
- MainTabs: Mode switcher (Draw, Life, Evo)
- SwatchPicker: Color picker
- Dialogs: File operations and project creation

### Scene Components (Rendering Layer)

#### LifeContainer
Type: SubViewportContainer (Scene Component)

Responsibility:
- Life mode canvas container and viewport management
- SpriteMesh creation from DrawLayer images on tab switch
- Image trimming and positioning for Life mode
- Root item hierarchy management
- Active item tracking and input routing to LifeTool

Depends on:
- LifeCanvas (SubViewport child)
- CanvasCamera (for camera control)
- EventBus (canvas_resized, tab_changed, item_selected)
- AppState (canvas_size)
- Services.canvas (get_all_layers)
- Services.tool (get_active_life_tool)
- DrawLayer (source for SpriteMesh creation)
- SpriteMesh (creation and management)

Operations:
- _items_from_layers: Creates SpriteMesh instances from DrawLayer images
- _gui_input: Routes input events to active LifeTool via handle_input()

Side effects:
- Creates SpriteMesh instances from DrawLayer images on tab switch
- Adds SpriteMesh to root_item hierarchy
- Trims images to used rect (optimization via get_used_rect() and blit_rect())
- Manages LifeCanvas size synchronization
- Tracks active_item for tool operations

Notes:
- Implements roadmap goal: "Инициализация Life режима при переключении вкладки"
- Image trimming preserves positions via rect.position offset

#### LifeRenderer
Type: Node2D (Scene Component)

Responsibility:
- Visual preview rendering for Life mode tools
- Vertex/point visualization with state-based icons
- Mouse position tracking and smoothing
- Tool-specific rendering coordination

Depends on:
- EventBus (tool_selected)
- Services.tool (get_active_tool)
- LifeContainer (mouse position, boundary checking)
- MeshTool (tool type checking)
- Vertex icon textures (exported)

Side effects:
- Draws vertex icons on canvas
- Updates every frame when visible
- Smoothed mouse cursor rendering

#### SpriteMesh
Type: MeshInstance2D (Scene Component / Data Model)

Responsibility:
- Mesh representation of sprite layers in Life mode
- Vertex, UV, and index data storage

Owns State:
- vertex: PackedVector2Array (polygon vertices)
- uv: PackedVector2Array (UV coordinates)
- index: PackedInt32Array (triangle indices)
- Mouse tracking: mouse_pixel_pos, first_vertex, last_vertex, active_vertex

Depends on:
- MeshInstance2D (base class)

#### MeshProperties
Type: ToolProperties (UI Component)

Responsibility:
- UI panel for MeshTool-specific properties
- Currently minimal implementation (placeholder)

Depends on:
- ToolProperties (base class)

Notes:
- Roadmap indicates need for better communication pattern between MeshProperties and MeshTool
- Current approach through Services.tool.get_tool_properties() is not preferred

---

## 7. Data Flow

### Input Flow
1. User interacts with UI (button click, canvas mouse event)
2. UI component emits EventBus signal or calls Service method
3. Service updates AppState (triggers reactive events)
4. Service coordinates with Core Logic (tools)
5. Core Logic operates on DrawLayer/Canvas
6. DrawLayer updates texture
7. EventBus signals propagate to UI for visual updates

### State Change Propagation
1. Service modifies AppState property (e.g., `AppState.current_tool = ToolType.Type.BRUSH`)
2. AppState setter emits EventBus signal (e.g., `EventBus.tool_selected.emit(value)`)
3. Subscribed components receive signal
4. UI updates visual state
5. Services react to state changes

### Drawing Operation Flow
1. User mouse event on DrawContainer
2. CanvasRenderer captures event
3. CanvasRenderer calls active DrawTool method (on_press/on_drag/on_release)
4. DrawTool operates on DrawLayer.image (pixel manipulation)
5. DrawTool calls DrawLayer.update_image() or start_changes()/finish_changes()
6. DrawLayer updates ImageTexture
7. Visual update appears on canvas

### Life Mode Operation Flow
1. User mouse event on LifeContainer
2. LifeContainer captures event via _gui_input()
3. LifeContainer gets active LifeTool from Services.tool
4. LifeContainer calls LifeTool.handle_input(event, active_item)
5. LifeTool operates on SpriteMesh (vertex/mesh manipulation)
6. SpriteMesh updates mesh data (vertex, uv, index)
7. Visual update appears on canvas

### Tool Property Flow
1. UI component changes property (e.g., brush size slider)
2. UI updates property resource (e.g., BrushProps.size = 5)
3. Property resource setter emits signal (e.g., size_changed.emit(5))
4. Tool receives signal via connected handler (e.g., _on_size_changed(5))
5. Tool updates internal state (e.g., _brush_size = 5)
6. Next tool operation uses updated property

### Save/Load Flow
1. User triggers save via DrawMenu
2. ProjectManager.save_project() called
3. ProjectManager collects data from Services:
   - LayerService.get_all_layers()
   - CanvasService.get_all_layer_images()
   - AppState properties
4. Data packaged into ProjectData resource
5. ResourceSaver.save() writes to disk
6. Load reverses process: ResourceLoader → restore methods → EventBus signals → UI updates

### Mutations and Side Effects
- Mutations allowed: Services, DrawLayer, AppState
- Side effects occur: File I/O (ProjectManager, CanvasService), Scene tree manipulation (CanvasService, CursorService), Texture updates (DrawLayer)
- Pure logic: All Tool classes (RefCounted)

---

## 8. Dependency Rules

Explicit architectural constraints:

1. **UI must not depend on Service internals**
   - UI communicates via EventBus signals only
   - UI reads AppState for display
   - UI calls Service public methods only

2. **Core (Tools) must not reference UI**
   - Tools are RefCounted, no Node dependencies
   - Tools receive data through method parameters
   - Tools operate on DrawLayer.image directly

3. **Services must not depend on UI components**
   - Services emit EventBus signals for UI updates
   - Services update AppState for reactive UI
   - Services manage Node instances (DrawLayer) but not UI nodes

4. **Autoloads must not depend on Scene instances**
   - Autoloads provide global state and coordination
   - Scene instances register with autoloads (Services.register)
   - Autoloads use signals for scene communication

5. **Data layer must not depend on Services or UI**
   - ProjectData, DrawLayerData are pure Resource classes
   - Serialization/deserialization is data-only

6. **Tools must access Services through Services locator**
   - Tools use `Services.tool.get_tool_property()` not direct references
   - Tools use `History.undo_redo` for undo/redo

7. **EventBus is one-way: emit only, no return values**
   - Services emit events, don't expect responses
   - UI subscribes to events, doesn't emit back to services directly

---

## 9. Extension Points

Where new systems can be added safely:

### New Service
1. Create service class extending Node
2. Implement service logic
3. Register in Services autoload: `Services.register("new_service", self)`
4. Add property to Services.gd: `var new_service: NewService = null`
5. Subscribe to relevant EventBus signals
6. Emit events for state changes

### New Tool
1. Create tool class extending BaseTool (RefCounted)
2. Implement tool interface: on_press, on_drag, on_release, on_hover
3. Add tool type to ToolType.Type enum
4. Register in ToolService.tool_instances
5. Create tool properties in ToolService.tool_properties
6. Add tool button to UI ToolPanel
7. (Optional) Create tool properties UI panel

### New Data Model
1. Create Resource class extending Resource
2. Add @export properties for serialization
3. Implement to_dict/from_dict if needed
4. Integrate with ProjectData for save/load

---

## 10. Known Architectural Risks

### Tight Coupling Areas
- CanvasService and DrawLayer: Direct node manipulation
- ProjectManager and Services: Requires knowledge of all services for save/load
- UI.gd and tab groups: Manual group management for tab switching
- LifeContainer and DrawLayer: Direct dependency for SpriteMesh creation
- LifeRenderer and MeshTool: Type checking for tool-specific rendering
- Tool-Property communication: Signal-based pattern implemented but may need iteration (roadmap note)

### Refactoring Candidates
- DrawLayer: Could be abstracted to interface for different layer types
- Layer ordering: Currently UI-managed, could move to LayerService
- File dialogs: Scattered across DrawMenu, could centralize
- SpriteMesh: Currently in tests/ directory, should move to proper location (assets/core or assets/life)
- MeshProps communication: Roadmap indicates dissatisfaction with current pattern, may need redesign

### Performance Bottlenecks
- Large canvas sizes: Pixel-by-pixel operations in tools
- Image serialization: PackedByteArray for every layer on save
- Undo/redo: Stores full image data for layer operations
- Fill tool: Flood fill on large areas can be slow

### Architectural Debt
- Services locator antipattern: Global state, harder to test
- EventBus: Many signals, can be hard to trace data flow
- AppState reactive setters: Implicit behavior, not obvious from call sites
- Mixed responsibilities: CanvasService handles both drawing and file I/O
- SpriteMesh location: Class in tests/ directory violates project structure
- LifeService minimal implementation: Currently only stores reference, needs expansion for Life mode features

### Recent Improvements
- ✅ Tool system refactored: BaseTool → DrawTool/LifeTool separation
- ✅ Typed property resources: Replaced dictionary-based properties with Resource classes
- ✅ Signal-based communication: Tools connect to property resources via signals
- ✅ Mode-specific tool storage: draw_tool_instances vs life_tool_instances

### Future Considerations
- Animation system: Timeline panel exists but not implemented
- Evo mode: Tab exists but no implementation
- Life mode completion: TreePanel synchronization with SpriteMesh (roadmap)
- Mesh editing: Full MeshTool functionality with preview rendering
- Camera limits: CanvasCamera bounds need fixing (roadmap note)
- Endless Canvas: Dynamic canvas sizing for Life mode (roadmap)
- Tool-Property pattern: May need further iteration based on user feedback