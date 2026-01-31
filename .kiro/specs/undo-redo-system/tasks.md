# Implementation Plan: Undo/Redo System

## Overview

Реализация системы Undo/Redo с Command Pattern для редактора пиксельарта. Система интегрируется с существующей архитектурой EventBus + Services, используя QuickTools для горячих клавиш.

## Tasks

- [ ] 1. Create base Command Pattern infrastructure
  - [x] 1.1 Create BaseCommand class
    - Implement abstract execute() and undo() methods
    - Add memory usage tracking and description fields
    - _Requirements: 1.1, 1.3, 1.4_
  
  - [ ]* 1.2 Write property test for BaseCommand interface
    - **Property 3: Command Interface Compliance**
    - **Validates: Requirements 1.3**
  
  - [x] 1.3 Create UndoRedoService class
    - Implement command stack management (undo/redo stacks)
    - Add execute_command(), undo(), redo() methods
    - Implement stack size limitation (50 commands default)
    - _Requirements: 4.1, 4.2, 4.4, 7.1_
  
  - [ ]* 1.4 Write property test for stack management
    - **Property 5: Undo/Redo Stack Management**
    - **Property 6: Stack Size Limitation**
    - **Validates: Requirements 4.1, 4.3, 4.4**

- [ ] 2. Implement Tool Commands
  - [x] 2.1 Create PixelCommand base class
    - Implement pixel change storage and application logic
    - Add memory optimization for pixel data
    - _Requirements: 2.1, 2.2, 2.3, 7.4_
  
  - [x] 2.2 Create BrushCommand and EraseCommand classes
    - Implement brush/eraser specific pixel operations
    - Handle different brush shapes and sizes
    - _Requirements: 2.1, 2.2_
  
  - [ ] 2.3 Create FillCommand class
    - Implement flood fill area calculation and storage
    - Handle contiguous/non-contiguous modes
    - _Requirements: 2.3_
  
  - [ ] 2.4 Create SelectionMoveCommand class
    - Implement selection area pixel movement
    - Store moved pixels for proper undo
    - _Requirements: 2.4_
  
  - [ ]* 2.5 Write property tests for tool commands
    - **Property 1: Command Creation for Tool Operations**
    - **Property 4: Round-trip Operation Consistency**
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 1.4**

- [ ] 3. Implement Layer Commands
  - [ ] 3.1 Create CreateLayerCommand class
    - Store layer creation data and handle undo
    - Manage active layer state changes
    - _Requirements: 3.1_
  
  - [ ] 3.2 Create DeleteLayerCommand class
    - Save complete layer data for restoration
    - Handle layer index and pixel data backup
    - _Requirements: 3.2_
  
  - [ ] 3.3 Create LayerVisibilityCommand class
    - Store visibility state changes
    - _Requirements: 3.3_
  
  - [ ] 3.4 Create MoveLayerCommand class
    - Handle layer reordering operations
    - _Requirements: 3.4_
  
  - [ ] 3.5 Create ClearLayerCommand class
    - Save all layer pixels for restoration
    - _Requirements: 3.5_
  
  - [ ]* 3.6 Write property tests for layer commands
    - **Property 2: Command Creation for Layer Operations**
    - **Property 4: Round-trip Operation Consistency**
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6**

- [ ] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Integrate with existing services
  - [ ] 5.1 Add UndoRedoService to Services registry
    - Register service in Services.gd
    - Initialize service in app.gd
    - _Requirements: 1.1_
  
  - [ ] 5.2 Add EventBus events for undo/redo
    - Add undo_availability_changed, redo_availability_changed events
    - Add command_executed, command_undone events
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_
  
  - [ ] 5.3 Integrate with ToolService operations
    - Hook into tool operations to create commands
    - Modify existing tool workflows to use command pattern
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  
  - [ ] 5.4 Integrate with LayerService operations
    - Hook into layer operations to create commands
    - Modify existing layer workflows to use command pattern
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
  
  - [ ]* 5.5 Write property tests for EventBus integration
    - **Property 7: EventBus Integration**
    - **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5**

- [ ] 6. Add keyboard shortcuts support
  - [ ] 6.1 Extend QuickTools class for undo/redo shortcuts
    - Add undo and redo action handling
    - Integrate with UndoRedoService
    - _Requirements: 6.1, 6.2_
  
  - [ ] 6.2 Add input map actions for undo/redo
    - Define "undo" and "redo" actions in project settings
    - Set default key bindings (Ctrl+Z, Ctrl+Y)
    - _Requirements: 6.1, 6.2_
  
  - [ ]* 6.3 Write property tests for keyboard shortcuts
    - **Property 8: Keyboard Shortcut Handling**
    - **Validates: Requirements 6.3, 6.4**

- [ ] 7. Implement UI state synchronization
  - [ ] 7.1 Add undo/redo availability tracking
    - Update UI elements based on stack availability
    - Handle AppState synchronization after operations
    - _Requirements: 4.5, 8.3, 8.4_
  
  - [ ]* 7.2 Write property tests for UI synchronization
    - **Property 9: UI State Synchronization**
    - **Validates: Requirements 8.3, 8.4**

- [ ] 8. Add memory management and optimization
  - [ ] 8.1 Implement command memory tracking
    - Track memory usage of commands in stack
    - Implement automatic cleanup of old commands
    - _Requirements: 7.2, 7.4_
  
  - [ ] 8.2 Add pixel data compression
    - Optimize storage of identical pixel areas
    - Implement efficient diff storage for large operations
    - _Requirements: 7.4_
  
  - [ ]* 8.3 Write property tests for memory management
    - **Property 10: Memory Management**
    - **Validates: Requirements 7.2, 7.4**

- [ ] 9. Final integration and testing
  - [ ] 9.1 Wire all components together
    - Ensure all services communicate properly
    - Test complete undo/redo workflows
    - _Requirements: 1.1, 8.1, 8.2_
  
  - [ ]* 9.2 Write integration tests
    - Test end-to-end undo/redo scenarios
    - Test edge cases with deleted layers
    - _Requirements: 8.5_

- [ ] 10. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- QuickTools class will be extended instead of creating new shortcut system