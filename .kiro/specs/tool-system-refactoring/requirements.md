# Requirements Document

## Introduction

This specification defines the requirements for refactoring the tool system in a Godot 4.6 pixel art editor. The refactoring addresses critical architectural issues that prevent proper implementation of Life mode tools while maintaining backward compatibility with existing Draw mode tools. The system uses service-based architecture with EventBus communication and RefCounted tools (pure logic, no Node dependencies).

## Glossary

- **Tool_System**: The complete tool management architecture including tool classes, properties, and services
- **DrawTool**: RefCounted class for Draw mode tools (Brush, Eraser, Fill, Selection) that work with DrawLayer and Color
- **LifeTool**: RefCounted class for Life mode tools (Mesh, future Bud/Stick) that work with SpriteMesh and InputEvent
- **Tool_Properties**: Resource-based classes that store tool configuration and emit signals for tool communication
- **ToolService**: Service that manages tool instances, properties, and active tool state
- **DrawContainer**: SubViewportContainer that routes input events to active DrawTool
- **LifeContainer**: SubViewportContainer that routes input events to active LifeTool
- **SpriteMesh**: MeshInstance2D with vertex, uv, and index arrays for Life mode mesh editing
- **DrawLayer**: TextureRect that represents a drawing layer with pixel manipulation methods
- **EventBus**: Centralized event system for loose coupling between components

## Requirements

### Requirement 1: Tool Hierarchy Separation

**User Story:** As a developer, I want separate tool hierarchies for Draw and Life modes, so that each mode can have tools with appropriate interfaces for their specific needs.

#### Acceptance Criteria

1. THE Tool_System SHALL provide a DrawTool class that extends RefCounted for Draw mode tools
2. THE Tool_System SHALL provide a LifeTool class that extends RefCounted for Life mode tools
3. WHEN a Draw mode tool is created, THE DrawTool SHALL provide on_press, on_drag, on_release, and on_hover methods that accept position, DrawLayer, and Color parameters
4. WHEN a Life mode tool is created, THE LifeTool SHALL provide a handle_input method that accepts InputEvent and SpriteMesh parameters
5. THE Tool_System SHALL NOT require LifeTool to inherit from DrawTool or share the same interface
6. THE DrawTool SHALL support the should_draw_preview method for preview rendering
7. THE LifeTool SHALL support the should_draw_preview method for preview rendering

### Requirement 2: Type-Safe Tool Properties

**User Story:** As a developer, I want typed property classes instead of dictionaries, so that I have compile-time type safety and clear property interfaces.

#### Acceptance Criteria

1. THE Tool_System SHALL provide Resource-based property classes for each tool type
2. WHEN a BrushTool is active, THE Tool_System SHALL use a BrushProperties Resource with size and shape fields
3. WHEN an EraserTool is active, THE Tool_System SHALL use an EraserProperties Resource with size field
4. WHEN a FillTool is active, THE Tool_System SHALL use a FillProperties Resource with contiguous field
5. WHEN a MeshTool is active, THE Tool_System SHALL use a MeshProperties Resource with operation methods
6. THE Tool_Properties SHALL emit signals when property values change
7. THE Tool_System SHALL NOT store properties as untyped Dictionary objects

### Requirement 3: Signal-Based Tool Communication

**User Story:** As a developer, I want tools to communicate with their properties through signals, so that the communication is decoupled and doesn't rely on service lookups.

#### Acceptance Criteria

1. WHEN a Tool_Properties value changes, THE Tool_Properties SHALL emit a signal with the new value
2. WHEN a tool receives a property change signal, THE tool SHALL update its behavior accordingly
3. THE Tool_System SHALL NOT require tools to call Services.tool.get_tool_property() for property access
4. THE Tool_Properties SHALL connect directly to tool methods through signals

### Requirement 4: Type-Safe Service Management

**User Story:** As a developer, I want type-safe tool storage and retrieval in ToolService, so that I can catch type errors at compile time and have clear separation between tool types.

#### Acceptance Criteria

1. THE ToolService SHALL store DrawTool instances separately from LifeTool instances
2. THE ToolService SHALL provide a get_active_draw_tool method that returns a DrawTool type
3. THE ToolService SHALL provide a get_active_life_tool method that returns a LifeTool type
4. THE ToolService SHALL store Tool_Properties as typed Resource objects
5. THE ToolService SHALL NOT use untyped Dictionary for tool instance storage
6. WHEN a tool is requested, THE ToolService SHALL return the correctly typed tool instance

### Requirement 5: Input Routing for Life Mode

**User Story:** As a developer, I want LifeContainer to route input events to the active LifeTool, so that Life mode tools can handle user interactions like Draw mode tools do.

#### Acceptance Criteria

1. WHEN an InputEvent occurs in LifeContainer, THE LifeContainer SHALL route the event to the active LifeTool
2. WHEN routing input, THE LifeContainer SHALL pass both the InputEvent and the active SpriteMesh to the LifeTool
3. WHEN no LifeTool is active, THE LifeContainer SHALL NOT attempt to route input
4. WHEN no SpriteMesh is selected, THE LifeContainer SHALL NOT route input to the LifeTool
5. THE LifeContainer SHALL follow the same input routing pattern as DrawContainer

### Requirement 6: MeshProperties User Interface

**User Story:** As a user, I want UI controls in MeshProperties to perform mesh operations, so that I can create polygons and generate meshes from sprites.

#### Acceptance Criteria

1. THE MeshProperties SHALL display a Create Polygon button
2. THE MeshProperties SHALL display a Make Mesh button
3. THE MeshProperties SHALL display a Clear Vertices button
4. THE MeshProperties SHALL display a label showing the current vertex count
5. WHEN the Create Polygon button is pressed, THE MeshProperties SHALL emit a signal to trigger polygon creation
6. WHEN the Make Mesh button is pressed, THE MeshProperties SHALL emit a signal to trigger mesh generation
7. WHEN the Clear Vertices button is pressed, THE MeshProperties SHALL emit a signal to clear all vertices
8. WHEN no SpriteMesh is selected, THE MeshProperties SHALL disable all operation buttons
9. WHEN a SpriteMesh is selected, THE MeshProperties SHALL enable all operation buttons
10. WHEN the vertex count changes, THE MeshProperties SHALL update the vertex count label

### Requirement 7: BaseTool Migration to DrawTool

**User Story:** As a developer, I want to rename BaseTool to DrawTool, so that the class name accurately reflects its purpose for Draw mode tools only.

#### Acceptance Criteria

1. THE Tool_System SHALL rename the BaseTool class to DrawTool
2. WHEN BaseTool is renamed, THE Tool_System SHALL update all references in existing Draw mode tools (BrushTool, EraserTool, FillTool, SelectionTool)
3. WHEN BaseTool is renamed, THE DrawContainer SHALL reference DrawTool instead of BaseTool
4. THE Tool_System SHALL maintain all existing DrawTool functionality after the rename
5. THE Tool_System SHALL NOT break existing Draw mode tool behavior during migration

### Requirement 8: Backward Compatibility During Migration

**User Story:** As a developer, I want existing Draw mode tools to continue working during the refactoring, so that the editor remains functional throughout the migration process.

#### Acceptance Criteria

1. WHEN DrawTool replaces BaseTool, THE existing BrushTool SHALL continue to function correctly
2. WHEN DrawTool replaces BaseTool, THE existing EraserTool SHALL continue to function correctly
3. WHEN DrawTool replaces BaseTool, THE existing FillTool SHALL continue to function correctly
4. WHEN DrawTool replaces BaseTool, THE existing SelectionTool SHALL continue to function correctly
5. WHEN properties are converted to typed Resources, THE existing property values SHALL be preserved
6. WHEN ToolService is updated, THE existing tool selection behavior SHALL remain unchanged

### Requirement 9: RefCounted Architecture Preservation

**User Story:** As a developer, I want all tools to remain RefCounted objects, so that tools have no Node dependencies and can be pure logic classes.

#### Acceptance Criteria

1. THE DrawTool SHALL extend RefCounted
2. THE LifeTool SHALL extend RefCounted
3. THE Tool_Properties SHALL extend Resource
4. THE Tool_System SHALL NOT introduce Node dependencies into tool classes
5. THE Tool_System SHALL NOT introduce Node dependencies into property classes

### Requirement 10: Future Tool Extensibility

**User Story:** As a developer, I want the tool architecture to support future Life mode tools, so that BudTool and StickTool can be added without further refactoring.

#### Acceptance Criteria

1. WHEN a new LifeTool subclass is created, THE LifeTool interface SHALL be sufficient for implementation
2. WHEN a new LifeTool is added to ToolService, THE ToolService SHALL store it in the life_tool_instances collection
3. THE LifeContainer input routing SHALL work with any LifeTool subclass without modification
4. THE Tool_System SHALL support adding new Tool_Properties Resource classes for future tools
