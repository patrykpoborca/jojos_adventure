# Feature Development Standards

**Last Updated**: 2025-12-23

## Purpose

Standardized guidelines for implementing features in Memory Lane with AI assistance.

## Directory Structure

Each feature should have its own directory under `.ai/features/`:

```
.ai/features/{feature_name}/
├── feature_description.md    # User stories, acceptance criteria
├── implementation_todo.md    # Technical checklist
├── changelog.md              # Development history
└── {optional_extras}.md      # API docs, diagrams, etc.
```

## File Templates

### feature_description.md

```markdown
# Feature: {Feature Name}

**Status**: Draft | In Progress | Complete | Archived
**Priority**: P0 (Critical) | P1 (High) | P2 (Medium) | P3 (Low)
**Created**: {Date}

## Overview

{One paragraph description of the feature}

## User Stories

### As a {user type}
- I want {goal}
- So that {benefit}

## Acceptance Criteria

- [ ] {Criterion 1}
- [ ] {Criterion 2}
- [ ] {Criterion 3}

## Business Rules

1. {Rule 1}
2. {Rule 2}

## Constraints

- {Technical or design constraint}

## Out of Scope

- {Explicitly excluded functionality}

## Dependencies

- {Other features or systems this depends on}

## Related Documents

- [Link to related doc]
```

### implementation_todo.md

```markdown
# Implementation: {Feature Name}

**Status**: Not Started | In Progress | Complete
**Branch**: feature/{branch-name}
**Assignee**: {Name or AI Agent}

## Technical Approach

{Brief description of implementation strategy}

## Checklist

### Setup
- [ ] Create feature branch
- [ ] Review related code

### Implementation
- [ ] {Task 1}
- [ ] {Task 2}
- [ ] {Task 3}

### Testing
- [ ] Unit tests
- [ ] Widget tests (if UI)
- [ ] Manual testing

### Cleanup
- [ ] Code review
- [ ] Update documentation
- [ ] Update changelog

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/game/x.dart` | Create | New component |
| `lib/game/y.dart` | Modify | Add collision |

## Notes

{Implementation notes, decisions, gotchas}
```

### changelog.md

```markdown
# Changelog: {Feature Name}

All notable changes to this feature.

## [Unreleased]

### Added
- {New functionality}

### Changed
- {Modifications to existing functionality}

### Fixed
- {Bug fixes}

### Removed
- {Removed functionality}

---

## [YYYY-MM-DD] - Initial Implementation

### Added
- Initial feature implementation
- Basic tests

### Notes
- {Any relevant notes about this version}
```

## Development Workflow

### 1. Feature Initialization

```bash
# Create feature directory
mkdir -p .ai/features/{feature_name}

# Create required files from templates
# (or use AI agent to generate)
```

### 2. Planning Phase

1. Write `feature_description.md`
2. Define acceptance criteria
3. Create `implementation_todo.md` with tasks
4. Initialize `changelog.md`

### 3. Implementation Phase

1. Create feature branch
2. Work through `implementation_todo.md` checklist
3. Update changelog with every significant change
4. Mark tasks complete as you go

### 4. Testing Phase

1. Write/run unit tests
2. Manual testing against acceptance criteria
3. Update documentation

### 5. Completion

1. Final changelog update
2. Mark feature status as Complete
3. Create PR (if applicable)
4. Archive to legacy if superseded

## Changelog Guidelines

### Update Frequency

- Update changelog with **every commit**
- Group related changes under single entry
- Add date headers for each work session

### Categories

| Category | Use For |
|----------|---------|
| Added | New features, files, functionality |
| Changed | Modifications to existing code |
| Fixed | Bug fixes |
| Removed | Deleted code or features |
| Security | Security-related changes |
| Deprecated | Soon-to-be removed features |

### Example Entry

```markdown
## [2025-12-23] - Memory Item Glow Effect

### Added
- Pulsing glow shader for memory items
- Glow intensity configuration

### Changed
- Memory item now uses SpriteComponent instead of PositionComponent

### Fixed
- Glow not appearing on first frame
```

## Quality Checklist

Before marking a feature complete:

### Code Quality
- [ ] No analyzer warnings/errors
- [ ] Follows naming conventions
- [ ] No hardcoded values (use constants)
- [ ] No debug prints in production code

### Testing
- [ ] Unit tests written and passing
- [ ] Edge cases covered
- [ ] Manual testing complete

### Documentation
- [ ] Code comments where needed
- [ ] Changelog updated
- [ ] Feature docs complete

### Design
- [ ] Follows design system
- [ ] Uses correct colors/tokens
- [ ] Accessibility considered

### Performance
- [ ] No obvious performance issues
- [ ] Assets optimized
- [ ] No memory leaks

## AI Agent Guidelines

When AI agents work on features:

1. **Start** by reading feature_description.md
2. **Check** domain-terminology.md for correct naming
3. **Follow** implementation_todo.md checklist
4. **Update** changelog.md with every change
5. **Verify** against acceptance criteria

## Related Documentation

- [Standards README](./README.md)
- [Domain Terminology](../product/domain-terminology.md)
- [Technical Architecture](../technical/README.md)
