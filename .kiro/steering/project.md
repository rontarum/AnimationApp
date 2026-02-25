---
inclusion: manual
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
- Tool instance management and lifecycle
- Tool selection and activation
- Tool property management (size, shape, etc.)
- Tool action coordination (start, update, finish)

Depends on:
- EventBus (tool_selected, layer_selected, tab_changed)
- AppState (current_tool, is_drawing)
- Tool instances (BrushTool, EraserTool, FillTool, SelectionTool, MeshTool)

Side effects:
- Creates tool instances on initialization
- Emits tool_property_changed events
- Updates AppState.current_tool

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

### BaseTool
Type: RefCounted (Pure Logic)

Responsibility:
- Abstract interface for all drawing tools
- Defines tool lifecycle: on_press, on_drag, on_release, on_hover, on_mouse_exit, on_resize
- Preview data management
- Canvas bounds checking

Constraints:
- No Node dependencies (RefCounted)
- No direct scene tree manipulation
- Receives data (position, layer, color) and performs operations
- Access to History.undo_redo for undo/redo support

### BrushTool
Type: RefCounted (extends BaseTool)

Responsibility:
- Pixel drawing with configurable size and shape
- Square and circle brush shapes
- Color blending with alpha support
- Preview rendering

Constraints:
- Pure logic, no UI dependencies
- Operates on DrawLayer.image directly
- Uses Services.tool for property access

### EraserTool
Type: RefCounted (extends BaseTool)

Responsibility:
- Pixel erasing (set to transparent)
- Configurable eraser size

Constraints:
- Similar to BrushTool but sets alpha to 0

### FillTool
Type: RefCounted (extends BaseTool)

Responsibility:
- Flood fill algorithm
- Contiguous/non-contiguous fill modes

Constraints:
- Operates on entire image data
- No preview rendering

### SelectionTool
Type: RefCounted (extends BaseTool)

Responsibility:
- Rectangular selection
- Selection movement
- Copy/paste operations

Constraints:
- Manages selection state internally
- Coordinates with LayerService for operations

### LifeTool
Type: RefCounted (Base Class for Life Tools)

Responsibility:
- Abstract base class for Life mode tools
- Provides common interface for Life tool operations
- Undo/redo support through History

Constraints:
- RefCounted (no Node dependencies)
- Defines handle_input(event, item) interface
- Provides should_draw_preview() method

### MeshTool
Type: RefCounted (extends LifeTool)

Responsibility:
- Vertex manipulation for SpriteMesh polygons
- Polygon creation from sprite images (convex hull)
- Mesh generation via Delaunay triangulation
- UV coordinate calculation and synchronization

Depends on:
- LifeTool (base class)
- SpriteMesh (operates on SpriteMesh instances)
- History.undo_redo (inherited from LifeTool)
- Geometry2D (triangulation, convex hull)

Operations:
- add_point: Add vertex to polygon
- remove_point: Remove vertex from polygon
- make_mesh: Generate ArrayMesh from vertices using Delaunay triangulation
- create_polygon: Auto-generate convex hull polygon from sprite texture
- _copy_uv: Synchronize UV coordinates with vertices
- _uvs_from_vertices: Calculate normalized UV coordinates

Constraints:
- Operates on SpriteMesh items (not DrawLayer)
- Pure logic, no direct scene tree manipulation
- Mode enum: SELECT, ADD, REMOVE (not fully implemented)

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

Depends on:
- LifeCanvas (SubViewport child)
- CanvasCamera (for camera control)
- EventBus (canvas_resized, tab_changed)
- AppState (canvas_size)
- Services.canvas (get_all_layers)
- DrawLayer (source for SpriteMesh creation)

Side effects:
- Creates SpriteMesh instances from DrawLayer images
- Adds SpriteMesh to root_item hierarchy
- Trims images to used rect (optimization)
- Manages LifeCanvas size synchronization

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
3. CanvasRenderer calls active tool method (on_press/on_drag/on_release)
4. Tool operates on DrawLayer.image (pixel manipulation)
5. Tool calls DrawLayer.update_image() or start_changes()/finish_changes()
6. DrawLayer updates ImageTexture
7. Visual update appears on canvas

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

### Refactoring Candidates
- DrawLayer: Could be abstracted to interface for different layer types
- Tool property management: Currently dictionary-based, could use typed classes (noted in roadmap for MeshProperties)
- Layer ordering: Currently UI-managed, could move to LayerService
- File dialogs: Scattered across DrawMenu, could centralize
- SpriteMesh: Currently in tests/ directory, should move to proper location (assets/core or assets/life)
- LifeTool separation: Roadmap suggests splitting BaseTool into DrawTool and LifeTool hierarchies

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
- Tool properties communication: MeshProperties → MeshTool communication pattern needs redesign (roadmap note)
- SpriteMesh location: Class in tests/ directory violates project structure
- LifeService minimal implementation: Currently only stores reference, needs expansion for Life mode features

### Future Considerations
- Animation system: Timeline panel exists but not implemented
- Evo mode: Tab exists but no implementation
- Life mode completion: TreePanel synchronization with SpriteMesh (roadmap)
- Mesh editing: Full MeshTool functionality with preview rendering
- Camera limits: CanvasCamera bounds need fixing (roadmap note)
- Endless Canvas: Dynamic canvas sizing for Life mode (roadmap)