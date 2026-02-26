# Implementation Plan: Tool System Refactoring

## Overview

This implementation plan refactors the tool system in phases to maintain backward compatibility while introducing type-safe properties, separate tool hierarchies, and proper input routing for Life mode. The approach prioritizes incremental changes with testing at each step to ensure existing functionality remains intact.

## Tasks

- [ ] 1. Create typed property Resource classes
  - [x] 1.1 Create BrushProps Resource class with size and shape fields
    - Extend Resource base class
    - Add @export var size: int with setter that emits size_changed signal
    - Add @export var shape: int with setter that emits shape_changed signal
    - Clamp size to range 1-10 in setter
    - _Requirements: 2.1, 2.2, 2.6_
  
  - [ ]* 1.2 Write property test for BrushProps signal emissions
    - **Property 1: Property Changes Emit Signals**
    - **Validates: Requirements 2.6, 3.1**
  
  - [x] 1.3 Create EraserProps Resource class with size field
    - Extend Resource base class
    - Add @export var size: int with setter that emits size_changed signal
    - Clamp size to range 1-10 in setter
    - _Requirements: 2.1, 2.3, 2.6_
  
  - [x] 1.4 Create FillProps Resource class with contiguous field
    - Extend Resource base class
    - Add @export var contiguous: bool with setter that emits contiguous_changed signal
    - _Requirements: 2.1, 2.4, 2.6_
  
  - [x] 1.5 Create MeshProps Resource class with operation signals
    - Extend Resource base class
    - Add signals: create_polygon_requested, make_mesh_requested, clear_vertices_requested
    - Add vertex_count: int with setter that emits vertex_count_changed signal
    - Add methods to emit operation signals: request_create_polygon(), request_make_mesh(), request_clear_vertices()
    - _Requirements: 2.1, 2.5, 2.6_

- [ ] 2. Update ToolService for type-safe property storage
  - [x] 2.1 Add typed property dictionaries to ToolService
    - Add draw_properties: Dictionary for DrawTool properties
    - Add life_properties: Dictionary for LifeTool properties
    - Initialize BrushProps, EraserProps, FillProps instances in _ready()
    - Initialize MeshProps instance in _ready()
    - Migrate existing dictionary values to new Resource instances
    - _Requirements: 4.4, 8.5_
  
  - [ ]* 2.2 Write property test for property value migration
    - **Property 9: Property Value Migration Preservation**
    - **Validates: Requirements 8.5**
  
  - [x] 2.3 Add type-safe property getter methods
    - Add get_draw_property(tool_type: ToolType.Type) -> Resource
    - Add get_life_property(tool_type: ToolType.Type) -> Resource
    - Return null if property doesn't exist for tool type
    - _Requirements: 4.4_
  
  - [x] 2.4 Remove old get_tool_property and set_tool_property methods
    - Delete get_tool_property(property: String) method
    - Delete set_tool_property(property: String, value) method
    - Delete tool_properties Dictionary
    - _Requirements: 3.3_


- [ ] 3. Rename BaseTool to DrawTool and update references
  - [x] 3.1 Rename base_tool.gd file to draw_tool.gd
    - Rename file in assets/core/tools/
    - Update class_name to DrawTool
    - Keep all existing methods and functionality
    - _Requirements: 7.1, 7.4_
  
  - [x] 3.2 Update all Draw tool subclasses to extend DrawTool
    - Update BrushTool: change "extends BaseTool" to "extends DrawTool"
    - Update EraserTool: change "extends BaseTool" to "extends DrawTool"
    - Update FillTool: change "extends BaseTool" to "extends DrawTool"
    - Update SelectionTool: change "extends BaseTool" to "extends DrawTool"
    - _Requirements: 7.2, 7.5_
  
  - [x] 3.3 Update DrawContainer to reference DrawTool
    - Change type checks from "is BaseTool" to "is DrawTool"
    - Update variable type hints from BaseTool to DrawTool
    - _Requirements: 7.3_
  
  - [ ]* 3.4 Write property tests for Draw tool behavior preservation
    - **Property 8: Draw Tool Behavior Preservation**
    - **Validates: Requirements 7.4, 7.5, 8.1, 8.2, 8.3, 8.4**

- [ ] 4. Update Draw tools to use signal-based property communication
  - [x] 4.1 Update BrushTool to connect to BrushProps signals
    - Remove Services.tool.get_tool_property("size") calls
    - Remove Services.tool.get_tool_property("shape") calls
    - Add _brush_size: int and _brush_shape: int member variables
    - Add _on_size_changed(new_size: int) method to update _brush_size
    - Add _on_shape_changed(new_shape: int) method to update _brush_shape
    - Connect to BrushProps signals in initialization
    - Update _draw_brush to use member variables instead of service calls
    - _Requirements: 3.1, 3.2, 3.3, 8.1_
  
  - [x] 4.2 Update EraserTool to connect to EraserProps signals
    - Remove Services.tool.get_tool_property("size") calls
    - Add _eraser_size: int member variable
    - Add _on_size_changed(new_size: int) method
    - Connect to EraserProps.size_changed signal
    - Update _draw_eraser to use member variable
    - _Requirements: 3.1, 3.2, 3.3, 8.2_
  
  - [x] 4.3 Update FillTool to connect to FillProps signals
    - Remove Services.tool.get_tool_property("contiguous") calls
    - Add _is_contiguous: bool member variable
    - Add _on_contiguous_changed(new_contiguous: bool) method
    - Connect to FillProps.contiguous_changed signal
    - Update on_press to use member variable
    - _Requirements: 3.1, 3.2, 3.3, 8.3_
  
  - [ ]* 4.4 Write property test for tool behavior reflecting property changes
    - **Property 2: Tool Behavior Reflects Property Changes**
    - **Validates: Requirements 3.2**

- [x] 5. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.


- [ ] 6. Update ToolService for type-safe tool management
  - [x] 6.1 Add separate tool instance storage
    - Add draw_tool_instances: Dictionary = {} for DrawTool instances
    - Add life_tool_instances: Dictionary = {} for LifeTool instances
    - Migrate existing tool_instances to draw_tool_instances
    - Add MeshTool to life_tool_instances
    - _Requirements: 4.1, 4.5_
  
  - [x] 6.2 Add type-safe tool getter methods
    - Add get_active_draw_tool() -> DrawTool method
    - Add get_active_life_tool() -> LifeTool method
    - Update active_tool to active_draw_tool and active_life_tool
    - Return null if no tool is active
    - _Requirements: 4.2, 4.3, 4.6_
  
  - [ ]* 6.3 Write property test for tool type correctness
    - **Property 3: Tool Type Returns Correct Instance Type**
    - **Validates: Requirements 4.6**
  
  - [x] 6.4 Update tool selection logic
    - Update _on_tool_selected to set active_draw_tool or active_life_tool based on tool type
    - Check if tool is in draw_tool_instances or life_tool_instances
    - Log warning if tool instance not found
    - _Requirements: 4.6, 8.6_
  
  - [ ]* 6.5 Write property test for tool selection behavior preservation
    - **Property 10: Tool Selection Behavior Preservation**
    - **Validates: Requirements 8.6**
  
  - [x] 6.6 Connect tool properties to tools during initialization
    - Connect BrushProps signals to BrushTool methods
    - Connect EraserProps signals to EraserTool methods
    - Connect FillProps signals to FillTool methods
    - Connect MeshProps signals to MeshTool methods
    - _Requirements: 3.4_

- [ ] 7. Implement LifeContainer input routing
  - [x] 7.1 Add input routing to LifeContainer
    - Add _gui_input(event: InputEvent) method
    - Get active_life_tool from Services.tool.get_active_life_tool()
    - Check if active_tool and active_item exist before routing
    - Call active_tool.handle_input(event, active_item)
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  
  - [x] 7.2 Add active_item tracking to LifeContainer
    - Add active_item: SpriteMesh member variable
    - Subscribe to EventBus.item_selected signal
    - Update active_item when item selection changes
    - Set active_item to null when no item is selected
    - _Requirements: 5.2, 5.4_
  
  - [ ]* 7.3 Write property test for input routing
    - **Property 4: Input Routing Passes Correct Parameters**
    - **Validates: Requirements 5.1, 5.2**
  
  - [ ]* 7.4 Write property test for LifeTool polymorphism
    - **Property 12: LifeContainer Routes Any LifeTool Subclass**
    - **Validates: Requirements 10.3**

- [x] 8. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.


- [ ] 9. Implement MeshProps UI
  - [x] 9.1 Create MeshProps UI scene
    - Add VBoxContainer as root
    - Add Label for vertex count display
    - Add Button for "Create Polygon" operation
    - Add Button for "Make Mesh" operation
    - Add Button for "Clear Vertices" operation
    - Set up button signals to call MeshProps methods
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  
  - [x] 9.2 Implement MeshProps UI script logic
    - Update mesh_properties.gd to extend ToolProperties
    - Add reference to MeshProps Resource
    - Connect button pressed signals to Resource operation methods
    - Update vertex count label when vertex_count_changed signal emits
    - Implement button enable/disable logic based on active_item state
    - Subscribe to EventBus.item_selected to track selection state
    - _Requirements: 6.5, 6.6, 6.7, 6.8, 6.9, 6.10_
  
  - [ ]* 9.3 Write property test for MeshProps button signals
    - **Property 5: MeshProps Buttons Emit Signals**
    - **Validates: Requirements 6.5, 6.6, 6.7**
  
  - [ ]* 9.4 Write property test for button state management
    - **Property 6: MeshProps Button State Reflects Selection**
    - **Validates: Requirements 6.8, 6.9**
  
  - [ ]* 9.5 Write property test for vertex count label updates
    - **Property 7: Vertex Count Label Updates**
    - **Validates: Requirements 6.10**

- [ ] 10. Update MeshTool to use MeshProps signals
  - [x] 10.1 Connect MeshTool to MeshProps signals
    - Add _on_create_polygon_requested() method that calls create_polygon(active_item)
    - Add _on_make_mesh_requested() method that calls make_mesh(active_item)
    - Add _on_clear_vertices_requested() method that clears vertex array
    - Connect to MeshProps signals during tool initialization
    - Update vertex count in MeshProps after operations
    - _Requirements: 3.2, 3.4_
  
  - [x] 10.2 Remove direct MeshTool method calls from UI
    - Ensure all MeshTool operations are triggered by signals
    - Remove any direct method calls from UI components
    - _Requirements: 3.3_

- [ ] 11. Update BrushProps UI to use Resource
  - [x] 11.1 Update brush_properties.gd to use BrushProps Resource
    - Add reference to BrushProps Resource instance
    - Connect UI controls to Resource property setters
    - Subscribe to Resource signals to update UI when properties change externally
    - Remove direct Services.tool.set_tool_property() calls
    - _Requirements: 3.1, 3.2_

- [ ] 12. Update existing tool property UI components
  - [x] 12.1 Create or update EraserProps UI component
    - Follow same pattern as BrushProps
    - Connect to EraserProps Resource
    - _Requirements: 3.1, 3.2_
  
  - [x] 12.2 Create or update FillProps UI component
    - Follow same pattern as BrushProps
    - Connect to FillProps Resource
    - _Requirements: 3.1, 3.2_

- [x] 13. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.


- [ ] 14. Update DrawContainer to use type-safe tool access
  - [x] 14.1 Replace get_active_tool() with get_active_draw_tool()
    - Update all Services.tool.get_active_tool() calls to Services.tool.get_active_draw_tool()
    - Update type checks from "is BaseTool" to "is DrawTool"
    - Update variable type hints to DrawTool
    - _Requirements: 4.2, 7.3_
  
  - [ ]* 14.2 Write unit tests for DrawContainer input routing
    - Test input routing with each draw tool type
    - Test edge cases (null tool, null layer)
    - _Requirements: 5.5_

- [ ] 15. Implement property-tool signal connections in tools
  - [x] 15.1 Add signal connection initialization to BrushTool
    - Add connect_to_properties(properties: BrushProps) method
    - Connect properties.size_changed to _on_size_changed
    - Connect properties.shape_changed to _on_shape_changed
    - Call from ToolService after tool creation
    - _Requirements: 3.2, 3.4_
  
  - [x] 15.2 Add signal connection initialization to EraserTool
    - Add connect_to_properties(properties: EraserProps) method
    - Connect properties.size_changed to _on_size_changed
    - Call from ToolService after tool creation
    - _Requirements: 3.2, 3.4_
  
  - [x] 15.3 Add signal connection initialization to FillTool
    - Add connect_to_properties(properties: FillProps) method
    - Connect properties.contiguous_changed to _on_contiguous_changed
    - Call from ToolService after tool creation
    - _Requirements: 3.2, 3.4_
  
  - [x] 15.4 Add signal connection initialization to MeshTool
    - Add connect_to_properties(properties: MeshProps) method
    - Connect properties.create_polygon_requested to _on_create_polygon_requested
    - Connect properties.make_mesh_requested to _on_make_mesh_requested
    - Connect properties.clear_vertices_requested to _on_clear_vertices_requested
    - Call from ToolService after tool creation
    - _Requirements: 3.2, 3.4_
  
  - [ ]* 15.5 Write property test for signal-based tool communication
    - **Property 2: Tool Behavior Reflects Property Changes**
    - **Validates: Requirements 3.2**

- [ ] 16. Update ToolService to manage tool-property connections
  - [x] 16.1 Add property-tool connection logic to ToolService._ready()
    - Get BrushProps and connect to BrushTool
    - Get EraserProps and connect to EraserTool
    - Get FillProps and connect to FillTool
    - Get MeshProps and connect to MeshTool
    - Call connect_to_properties() on each tool with its properties
    - _Requirements: 3.4_
  
  - [x] 16.2 Remove EventBus.tool_property_changed signal usage
    - Remove tool_property_changed signal emission from ToolService
    - Remove tool_property_changed signal connections from property UI components
    - Properties now communicate directly through their own signals
    - _Requirements: 3.3_

- [x] 17. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.


- [ ] 18. Finalize ToolService type-safe architecture
  - [x] 18.1 Update tool instance initialization
    - Move BrushTool, EraserTool, FillTool, SelectionTool to draw_tool_instances
    - Move MeshTool to life_tool_instances
    - Remove old tool_instances Dictionary
    - _Requirements: 4.1, 4.5_
  
  - [x] 18.2 Update active tool tracking
    - Replace active_tool with active_draw_tool and active_life_tool
    - Update _on_tool_selected to set the appropriate active tool based on type
    - Update _on_tab_changed to handle mode switching
    - _Requirements: 4.2, 4.3_
  
  - [ ]* 18.3 Write property test for new LifeTool storage
    - **Property 11: New LifeTool Storage**
    - **Validates: Requirements 10.2**

- [x] 19. Verify backward compatibility
  - [ ]* 19.1 Write integration tests for complete draw workflows
    - Test: Select brush → change size → draw → verify pixels
    - Test: Select eraser → change size → erase → verify transparency
    - Test: Select fill → toggle contiguous → fill → verify area
    - Test: Select selection → select area → move → verify pixels moved
    - _Requirements: 8.1, 8.2, 8.3, 8.4_
  
  - [ ]* 19.2 Write integration tests for MeshTool workflow
    - Test: Select mesh tool → create polygon → verify vertices
    - Test: Select mesh tool → add vertices → make mesh → verify triangulation
    - Test: Select mesh tool → add vertices → clear → verify empty
    - _Requirements: 6.5, 6.6, 6.7_

- [ ] 20. Final integration and cleanup
  - [x] 20.1 Remove deprecated code
    - Remove any remaining BaseTool references
    - Remove old dictionary-based property access methods
    - Clean up unused EventBus signals if any
    - _Requirements: 7.2, 3.3_
  
  - [x] 20.2 Update tool registration for future extensibility
    - Ensure ToolService can easily add new DrawTool subclasses
    - Ensure ToolService can easily add new LifeTool subclasses
    - Document the pattern for adding new tools
    - _Requirements: 10.1, 10.2_
  
  - [x] 20.3 Verify all components work together
    - Test switching between Draw and Life modes
    - Test tool selection in both modes
    - Test property changes affecting tool behavior
    - Test MeshProps UI triggering MeshTool operations
    - _Requirements: 1.1, 1.2, 2.1, 3.1, 4.1, 5.1, 6.5_

- [x] 21. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster implementation
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation throughout the refactoring
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- The refactoring maintains backward compatibility at each step
- All tools remain RefCounted with no Node dependencies
- Signal-based communication eliminates service lookup dependencies
