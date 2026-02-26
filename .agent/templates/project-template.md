---
inclusion: auto
name: project
description: Current Godot project architecture. Use when you need to understand project architecture, dependencies and principles. Important when working with project tasks or planning new features.
---

# PROJECT_NAME — Architecture Documentation

## 1. Architectural Overview

### Engine Version
Godot X.X

### Architectural Style
(e.g. Service-based, Event-driven, MVC-like, ECS-like, Hybrid)

### Core Principles
- Low coupling
- High cohesion
- Separation of concerns
- Data-driven where applicable

---

## 2. High-Level System Map

### Runtime Layers

- Global Layer (autoload singletons)
- Service Layer (application logic)
- Core Domain Layer (pure logic / RefCounted)
- Presentation Layer (UI / Scenes)
- Rendering / View Layer
- Tooling / Editor Extensions (if any)

Brief explanation of how layers interact.

---

## 3. Global Systems (Autoloads)

For each:

### ClassName
Type: Autoload Singleton

Responsibility:
- 

Owns State:
- 

Communicates via:
- Signals
- Direct calls
- EventBus (if used)

Used by:
- 

---

## 4. Services Layer

### ClassName
Type: Service / Manager

Responsibility:
- 

Depends on:
- 

Side effects:
- (file IO, scene instantiation, resource mutation, etc.)

---

## 5. Core Domain Layer

(Pure logic classes, RefCounted, data models)

### ClassName
Type: RefCounted / Resource / Data Model

Responsibility:
- 

Constraints:
- No UI references
- No direct scene tree manipulation (if applicable)

---

## 6. Scene & UI Architecture

### Scene Composition Strategy
- How scenes are structured
- Composition vs inheritance usage

### UI Control Flow
- Input routing model
- How UI communicates with services

---

## 7. Data Flow

Describe:

- How input flows through the system
- How state changes propagate
- Where mutations are allowed
- Where side effects occur

Optional diagrams in text form.

---

## 8. Dependency Rules

Explicit architectural constraints:

- UI must not depend on Services internals
- Core must not reference UI
- Autoloads must not depend on Scene instances
- etc.

---

## 9. Extension Points

Where new systems can be added safely:

- New Service
- New Tool
- New Scene Module
- New Data Model

---

## 10. Known Architectural Risks

(Optional)

- Tight coupling areas
- Refactoring candidates
- Performance bottlenecks