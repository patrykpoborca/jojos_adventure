# AI Agents Documentation

**Last Updated**: 2025-12-23

This directory contains configurations and guidelines for AI agents working on Memory Lane.

## Available Agents

| Agent | Specialization | When to Use |
|-------|----------------|-------------|
| [Project Guardian](./project-guardian-agent.md) | Code Quality, Design Compliance | After implementing features, before commits |

## Agent Coordination

### Workflow Integration

```
1. Developer/AI starts feature
        ↓
2. Implementation complete
        ↓
3. Project Guardian reviews
        ↓
4. Fix any issues
        ↓
5. Final review & commit
```

### Agent Capabilities Matrix

| Capability | Project Guardian |
|------------|-----------------|
| Code Review | Yes |
| Design System Check | Yes |
| Test Coverage | Yes |
| Git Hook Validation | Yes |
| Feature Implementation | No |
| Architecture Decisions | No |

## General Guidelines for AI Agents

### Before Starting Any Task

1. **Read Context**
   - `.ai/README.md` - Navigation hub
   - `.ai/product/domain-terminology.md` - Correct naming
   - `.ai/technical/architecture-overview.md` - System understanding

2. **Find Feature Docs**
   - Check `.ai/features/{feature_name}/` for specs
   - Review acceptance criteria
   - Check implementation status

3. **Understand Standards**
   - Read `.ai/standards/feature-development.md`
   - Follow coding conventions
   - Update changelogs

### During Implementation

1. **Use Correct Terminology**
   - Always use terms from domain-terminology.md
   - Don't invent new names without consensus

2. **Follow Patterns**
   - Use established Flame patterns
   - Match existing code style
   - Keep game logic in components, UI in widgets

3. **Document Changes**
   - Update changelog with every commit
   - Add code comments for complex logic
   - Keep implementation_todo.md current

### After Completion

1. **Self-Review**
   - Check against acceptance criteria
   - Verify design compliance
   - Ensure tests pass

2. **Request Guardian Review**
   - Run project guardian checks
   - Address any findings
   - Document decisions

## Communication Patterns

### Status Updates

When reporting progress, include:
- Current task
- Completion percentage
- Blockers (if any)
- Next steps

### Asking for Clarification

When ambiguity exists:
1. State what you understand
2. List options you see
3. Ask specific question
4. Suggest a default if no response

### Reporting Issues

When finding problems:
1. Describe the issue clearly
2. Explain impact/severity
3. Suggest solutions if possible
4. Link to relevant docs/code

## Adding New Agents

To add a new specialized agent:

1. Create `agents/{agent-name}-agent.md`
2. Define specialization and scope
3. List responsibilities
4. Add to this README's agent table
5. Document coordination patterns

## Related Documentation

- [Project Guardian Agent](./project-guardian-agent.md)
- [Feature Development Standards](../standards/feature-development.md)
- [Domain Terminology](../product/domain-terminology.md)
