# Design Document: Tool System Refactoring

## Overview

This design refactors the tool system architecture to support both Draw mode and Life mode tools with appropriate interfaces for each. The current BaseTool class was designed for Draw mode tools (working with DrawLayer and Color) but Life mode tools need a different interface (working with SpriteMesh and InputEvent). This refactoring separates the tool hierarchies while maintaining type safety, signal-based communication, and the existing RefCounted architecture.

The refactoring addresses five critical issues:
1. Tool hierarchy mismatch between Draw and Life modes
2. Lack of type safety in tool storage and properties
3. Broken properties-to-tool communication pattern
4. Missing MeshProperties UI implementation
5. Absent input routing in LifeContainer

## Architecture

### High-Level Architecture

The tool system follows a service-based architecture with three main layers:

1. **Tool Layer**: RefCounted tool classes (DrawTool, LifeTool) containing pure logic
2. **Properties Layer**: Resource-based property classes that store configuration and emit signals
3. **Service Layer**: ToolService manages tool instances, properties, and active tool state
4. **Container Layer**: DrawContainer and LifeContainer route input events to appropriate tools

```
┌─────────────────────────────────────────────────────────────┐
│                        ToolService                          │
│  ┌──────────────────┐         ┌──────────────────┐        │
│  │ draw_tool_       │         │ life_tool_       │        │
│  │ instances        │         │ instances        │        │
│  │ (DrawTool)       │         │ (LifeTool)       │        │
│  └──────────────────┘         └──────────────────┘        │
│  ┌──────────────────┐         ┌──────────────────┐        │
│  │ draw_properties  │         │ life_properties  │        │
│  │ (Resource)       │         │ (Resource)       │        │
│  └──────────────────┘         └──────────────────┘        │
└─────────────────────────────────────────────────────────────┘
                    │                        │
                    ▼                        ▼
         ┌──────────────────┐    ┌──────────────────┐
         │  DrawContainer   │    │  LifeContainer   │
         │  (routes input)  │    │  (routes input)  │
         └──────────────────┘    └──────────────────┘
```

### Tool Hierarchy Separation


**DrawTool Hierarchy** (for Draw mode):
```
RefCounted
    └── DrawTool (base class for draw tools)
        ├── BrushTool
        ├── EraserTool
        ├── FillTool
        └── SelectionTool
```

**LifeTool Hierarchy** (for Life mode):
```
RefCounted
    └── LifeTool (base class for life tools)
        ├── MeshTool
        ├── BudTool (future)
        └── StickTool (future)
```

The hierarchies are completely separate. DrawTool and LifeTool both extend RefCounted but have different interfaces appropriate for their respective modes.

### Signal-Based Communication

Properties communicate with tools through Godot signals rather than service lookups:

```
┌──────────────────┐
│ BrushProperties  │
│   (Resource)     │
│                  │
│  signal size_    │──────┐
│  changed(int)    │      │
│                  │      │
│  signal shape_   │──┐   │
│  changed(int)    │  │   │
└──────────────────┘  │   │
                      │   │
                      ▼   ▼
              ┌──────────────────┐
              │    BrushTool     │
              │  (RefCounted)    │
              │                  │
              │  _on_size_       │
              │  changed()       │
              │                  │
              │  _on_shape_      │
              │  changed()       │
              └──────────────────┘
```

This eliminates the need for `Services.tool.get_tool_property()` calls and creates a cleaner, more reactive architecture.

## Components and Interfaces

### DrawTool (renamed from BaseTool)

```gdscript
class_name DrawTool extends RefCounted

var preview_position: Vector2i = Vector2i(-1, -1)
var preview_color: Color = Color.TRANSPARENT
var undo_redo: UndoRedo

func on_press(position: Vector2i, layer: DrawLayer, color: Color) -> void
func on_drag(position: Vector2i, layer: DrawLayer, color: Color) -> void
func on_release(position: Vector2i, layer: DrawLayer, color: Color) -> void
func on_hover(position: Vector2i) -> void
func on_mouse_exit(layer: DrawLayer) -> void
func should_draw_preview() -> bool
```

Interface designed for pixel-based drawing operations with DrawLayer and Color.

### LifeTool

```gdscript
class_name LifeTool extends RefCounted

var undo_redo: UndoRedo

func handle_input(event: InputEvent, item: SpriteMesh) -> void
func should_draw_preview() -> bool
```

Interface designed for mesh manipulation operations with InputEvent and SpriteMesh.

### Tool Properties Resources


**BrushProperties**:
```gdscript
class_name BrushProperties extends Resource

signal size_changed(new_size: int)
signal shape_changed(new_shape: int)

@export var size: int = 1:
    set(value):
        size = clamp(value, 1, 10)
        size_changed.emit(size)

@export var shape: int = 0:  # 0=square, 1=circle
    set(value):
        shape = value
        shape_changed.emit(shape)
```

**EraserProperties**:
```gdscript
class_name EraserProperties extends Resource

signal size_changed(new_size: int)

@export var size: int = 1:
    set(value):
        size = clamp(value, 1, 10)
        size_changed.emit(size)
```

**FillProperties**:
```gdscript
class_name FillProperties extends Resource

signal contiguous_changed(new_contiguous: bool)

@export var contiguous: bool = true:
    set(value):
        contiguous = value
        contiguous_changed.emit(contiguous)
```

**MeshProperties**:
```gdscript
class_name MeshProperties extends Resource

signal create_polygon_requested()
signal make_mesh_requested()
signal clear_vertices_requested()
signal vertex_count_changed(count: int)

var vertex_count: int = 0:
    set(value):
        vertex_count = value
        vertex_count_changed.emit(vertex_count)
```

All properties extend Resource for future serialization support and use Godot's property setters to automatically emit signals on value changes.

### ToolService Refactored

```gdscript
class_name ToolService extends Node

# Separate storage for each tool type
var draw_tool_instances: Dictionary = {}  # ToolType.Type -> DrawTool
var life_tool_instances: Dictionary = {}  # ToolType.Type -> LifeTool

# Typed property storage
var draw_properties: Dictionary = {}  # ToolType.Type -> Resource
var life_properties: Dictionary = {}  # ToolType.Type -> Resource

var active_draw_tool: DrawTool = null
var active_life_tool: LifeTool = null

func get_active_draw_tool() -> DrawTool
func get_active_life_tool() -> LifeTool
func get_draw_property(tool_type: ToolType.Type) -> Resource
func get_life_property(tool_type: ToolType.Type) -> Resource
```

Type-safe getters ensure compile-time type checking and clear separation between Draw and Life tools.

### Input Routing

**DrawContainer** (existing pattern):
```gdscript
func _gui_input(event: InputEvent) -> void:
    var active_tool = Services.tool.get_active_draw_tool()
    if not active_tool:
        return
    
    var pixel_pos = Vector2i(floor(mouse_pos))
    
    if event.is_action_pressed("action"):
        active_tool.on_press(pixel_pos, active_layer, use_color)
```

**LifeContainer** (new implementation):
```gdscript
func _gui_input(event: InputEvent) -> void:
    var active_tool = Services.tool.get_active_life_tool()
    if not active_tool or not active_item:
        return
    
    active_tool.handle_input(event, active_item)
```

Both containers check for tool existence and required context before routing.

## Data Models

### Tool Type Enumeration

The existing ToolType.Type enum will be extended to clearly separate Draw and Life tools:

```gdscript
enum Type {
    # Draw mode tools
    ARROW,
    BRUSH,
    ERASER,
    FILL,
    SELECTION,
    
    # Life mode tools
    MESH,
    BUD,      # future
    STICK     # future
}
```

### Property-Tool Binding

Each tool type maps to a specific property type:

| Tool Type | Property Type | Signals |
|-----------|---------------|---------|
| BRUSH | BrushProperties | size_changed, shape_changed |
| ERASER | EraserProperties | size_changed |
| FILL | FillProperties | contiguous_changed |
| MESH | MeshProperties | create_polygon_requested, make_mesh_requested, clear_vertices_requested |

### SpriteMesh Data Structure

SpriteMesh (existing) stores mesh data for Life mode:

```gdscript
class_name SpriteMesh extends MeshInstance2D

var vertex: PackedVector2Array = []
var uv: PackedVector2Array = []
var index: PackedInt32Array = []
```

MeshTool operations modify these arrays, and MeshProperties UI triggers those operations.


## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system - essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

### Property 1: Property Changes Emit Signals

*For any* Tool_Properties Resource and any property field, when the property value is changed, a signal SHALL be emitted with the new value.

**Validates: Requirements 2.6, 3.1**

This property ensures the signal-based communication pattern works correctly. When testing, generate random property instances (BrushProperties, EraserProperties, FillProperties, MeshProperties), change their values, and verify the appropriate signals are emitted with correct values.

### Property 2: Tool Behavior Reflects Property Changes

*For any* tool and its associated properties, when a property value changes and the signal is emitted, the tool's subsequent behavior SHALL reflect the new property value.

**Validates: Requirements 3.2**

This property ensures tools correctly respond to property changes. Test by connecting tools to their properties, changing property values, and verifying tool operations use the new values (e.g., changing brush size should affect the number of pixels drawn).

### Property 3: Tool Type Returns Correct Instance Type

*For any* tool type requested from ToolService, the returned instance SHALL be of the correct tool class type (BrushTool for BRUSH, MeshTool for MESH, etc.).

**Validates: Requirements 4.6**

This property ensures type-safe tool retrieval. Test by requesting each tool type and verifying the returned instance is the correct class.

### Property 4: Input Routing Passes Correct Parameters

*For any* InputEvent in LifeContainer with an active LifeTool and active SpriteMesh, the event and mesh SHALL both be passed to the tool's handle_input method.

**Validates: Requirements 5.1, 5.2**

This property ensures input routing works correctly. Test by simulating various input events with different SpriteMesh instances and verifying both parameters are passed to handle_input.

### Property 5: MeshProperties Buttons Emit Signals

*For any* MeshProperties button (Create Polygon, Make Mesh, Clear Vertices), when the button is pressed, the corresponding signal SHALL be emitted.

**Validates: Requirements 6.5, 6.6, 6.7**

This property ensures UI button interactions trigger the correct signals. Test by simulating button presses and verifying the appropriate signals are emitted.

### Property 6: MeshProperties Button State Reflects Selection

*For any* MeshProperties instance, when no SpriteMesh is selected, all operation buttons SHALL be disabled, and when a SpriteMesh is selected, all operation buttons SHALL be enabled.

**Validates: Requirements 6.8, 6.9**

This property ensures button state management works correctly. Test by toggling SpriteMesh selection and verifying button disabled states change accordingly.

### Property 7: Vertex Count Label Updates

*For any* MeshProperties instance, when the vertex count value changes, the vertex count label SHALL display the new count.

**Validates: Requirements 6.10**

This property ensures the UI label stays synchronized with the data. Test by changing vertex counts and verifying the label text updates.

### Property 8: Draw Tool Behavior Preservation

*For any* existing Draw mode tool (BrushTool, EraserTool, FillTool, SelectionTool) and any valid operation, the tool SHALL produce the same result after the BaseTool → DrawTool refactoring as it did before.

**Validates: Requirements 7.4, 7.5, 8.1, 8.2, 8.3, 8.4**

This property ensures backward compatibility during migration. Test by capturing operation results before refactoring and comparing with results after refactoring for the same inputs.

### Property 9: Property Value Migration Preservation

*For any* tool property value before conversion to typed Resources, the value SHALL remain the same after conversion to the new Resource-based system.

**Validates: Requirements 8.5**

This property ensures data integrity during migration. Test by recording property values before migration and verifying they match after migration.

### Property 10: Tool Selection Behavior Preservation

*For any* tool selection operation, the behavior SHALL remain unchanged after ToolService refactoring.

**Validates: Requirements 8.6**

This property ensures tool selection continues to work correctly. Test by performing tool selections and verifying the correct tool becomes active with the same behavior as before refactoring.

### Property 11: New LifeTool Storage

*For any* new LifeTool instance added to ToolService, the tool SHALL be stored in the life_tool_instances collection and retrievable via get_active_life_tool.

**Validates: Requirements 10.2**

This property ensures new Life tools are managed correctly. Test by adding various LifeTool subclasses and verifying they're stored and retrievable correctly.

### Property 12: LifeContainer Routes Any LifeTool Subclass

*For any* LifeTool subclass set as active, LifeContainer input routing SHALL successfully pass events to the tool's handle_input method.

**Validates: Requirements 10.3**

This property ensures the input routing is polymorphic and works with any LifeTool implementation. Test by creating different LifeTool subclasses and verifying input routing works for all of them.


## Error Handling

### Tool Instance Errors

**Missing Tool Instance**:
- When a tool type is requested but no instance exists, ToolService SHALL return null
- Containers SHALL check for null before routing input
- Log warning: "[ToolService] No tool instance for: {tool_type}"

**Invalid Tool Type**:
- When an invalid tool type is passed to ToolService, return null
- Do not crash or throw exceptions
- Log warning with the invalid type

### Property Errors

**Property Signal Connection Failures**:
- If a property signal fails to connect to a tool method, log error
- Tool should continue functioning with default property values
- Error format: "[ToolService] Failed to connect {property}.{signal} to {tool}"

**Invalid Property Values**:
- Property setters SHALL clamp values to valid ranges (e.g., size: 1-10)
- Invalid values SHALL be corrected automatically, not rejected
- No error messages needed for auto-correction

### Input Routing Errors

**Missing Context**:
- DrawContainer SHALL check for active_layer before routing to DrawTool
- LifeContainer SHALL check for active_item before routing to LifeTool
- If context is missing, silently skip routing (no error needed)

**Null Tool Reference**:
- Containers SHALL check if active tool is null before calling methods
- If null, skip input routing without error
- This is expected behavior when no tool is selected

### Migration Errors

**Property Migration**:
- If a dictionary property value cannot be converted to Resource, use default value
- Log warning: "[ToolService] Could not migrate property {name}, using default"
- Continue migration for other properties

**Tool Reference Updates**:
- If a file still references BaseTool after migration, Godot will show compile error
- This is intentional - ensures all references are updated
- No runtime error handling needed

## Testing Strategy

### Dual Testing Approach

This refactoring requires both unit tests and property-based tests:

**Unit Tests** focus on:
- Specific examples of tool operations (brush draws at position, eraser clears pixel)
- Edge cases (empty SpriteMesh, null layer, boundary positions)
- Error conditions (invalid tool types, missing context)
- UI interactions (button clicks, signal emissions)
- Integration between components (ToolService ↔ Properties ↔ Tools)

**Property-Based Tests** focus on:
- Universal properties across all inputs (any property change emits signal)
- Behavior preservation during migration (all tools work the same before/after)
- Type safety guarantees (correct types returned for all tool requests)
- Input routing correctness (all events routed with correct parameters)

Together, unit tests catch concrete bugs in specific scenarios while property tests verify general correctness across the entire input space.

### Property-Based Testing Configuration

**Library**: Use GdUnit4 with its property-based testing support (fuzzer framework)

**Test Configuration**:
- Minimum 100 iterations per property test
- Each property test must reference its design document property
- Tag format: **Feature: tool-system-refactoring, Property {number}: {property_text}**

**Example Property Test Structure**:
```gdscript
func test_property_changes_emit_signals() -> void:
    # Feature: tool-system-refactoring, Property 1: Property Changes Emit Signals
    var fuzzer = Fuzzers.random_value()
    
    for i in range(100):
        var size = fuzzer.next_int(1, 10)
        var properties = BrushProperties.new()
        var signal_emitted = false
        
        properties.size_changed.connect(func(new_size): signal_emitted = true)
        properties.size = size
        
        assert_bool(signal_emitted).is_true()
```

### Testing Phases

**Phase 1: Property Resource Tests**
- Test signal emissions for all property types
- Test property value clamping and validation
- Test property-to-tool signal connections

**Phase 2: Tool Hierarchy Tests**
- Test DrawTool interface compliance for all draw tools
- Test LifeTool interface compliance for all life tools
- Test tool instance creation and storage

**Phase 3: Service Layer Tests**
- Test type-safe tool retrieval
- Test property storage and retrieval
- Test tool selection behavior

**Phase 4: Input Routing Tests**
- Test DrawContainer routing to DrawTool
- Test LifeContainer routing to LifeTool
- Test edge cases (null tool, null context)

**Phase 5: Migration Tests**
- Test backward compatibility for all draw tools
- Test property value preservation
- Test tool selection behavior preservation

**Phase 6: Integration Tests**
- Test complete workflows (select tool → change property → perform operation)
- Test MeshProperties UI → MeshTool operation flow
- Test tool switching between Draw and Life modes

### Manual Testing

Some aspects require manual verification:
- UI layout and visual appearance of MeshProperties
- Cursor behavior during tool operations
- Preview rendering quality
- Performance with large meshes or complex selections

These should be tested manually after automated tests pass.
