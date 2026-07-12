# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a configuration repository for Claude Code plugins. It contains reusable plugin profiles that can be synced across multiple projects and computers via GitHub. The repository does not contain application code - it contains plugin configurations, custom commands, specialized agents, and MCP server configurations.

## Architecture

### Plugin System

This repository uses Claude Code's plugin architecture where:

1. **Plugin profiles** are self-contained directories with a `.claude-plugin/plugin.json` file
2. **Plugins are registered** in project `.claude/settings.json` files via `extraKnownMarketplaces` and `enabledPlugins`
3. **Multiple plugins can be composed** together in a single project
4. **Configuration is additive** - all plugins load together with project-specific settings

### Repository Structure

```
claude-configs/
├── profile-al-development/          # AL/Business Central development profile
│   ├── .claude-plugin/
│   │   ├── plugin.json              # Plugin metadata (name, version, author)
│   │   └── settings.json            # Plugin-specific settings
│   ├── CLAUDE.md                    # AL coding standards and agent orchestration
│   ├── agents/                      # 11 specialized agents for AL development
│   │   ├── requirements-engineer.md
│   │   ├── solution-planner.md
│   │   ├── al-developer.md
│   │   ├── code-reviewer.md
│   │   ├── diagnostics-fixer.md
│   │   ├── test-engineer.md
│   │   ├── test-reviewer.md
│   │   ├── bc-expert.md
│   │   ├── docs-lookup.md
│   │   ├── dependency-navigator.md
│   │   └── interview.md
│   ├── commands/                    # Slash commands (user-invocable)
│   │   ├── dev-cycle.md            # Full development lifecycle
│   │   ├── plan.md                 # Planning phase only
│   │   ├── develop.md              # Development phase only
│   │   ├── test.md                 # Testing phase only
│   │   ├── fix.md                  # Quick bug fix workflow
│   │   ├── estimate.md             # Estimation workflow
│   │   ├── interview.md            # Deep requirements gathering
│   │   ├── diagnostics.md          # Compiler diagnostics
│   │   ├── bc-expert.md            # BC specialist consultation
│   │   ├── docs-lookup.md          # Microsoft Docs search
│   │   └── nav-baseapp.md          # Base app navigation
│   ├── bc-code-intel-knowledge/     # BC Intelligence MCP knowledge base
│   │   ├── specialists/             # Specialist personas
│   │   └── domains/                 # Domain knowledge
│   ├── .mcp.json                    # MCP server configuration
│   └── README.md                    # Profile documentation
├── project-settings-template.json   # Template for project .claude/settings.json
├── .gitignore
└── README.md                        # Repository overview and setup
```

## Key Concepts

### Document-Driven Development (AL Profile)

The AL profile implements a document-driven workflow where:

1. **Agents write to files, not chat** - Keeps main conversation clean
2. **Agents read previous outputs** - Sequential context flow via `.dev/` directory
3. **Persistent documentation** - Full audit trail in markdown files
4. **User approval gates** - Stop between major phases for validation

### Agent Collaboration Pattern

```
User Request
    ↓
requirements-engineer → .dev/01-requirements.md
    ↓
solution-planner → .dev/02-solution-plan.md (uses MCP tools)
    ↓
al-developer → AL source files (reads plan)
    ↓
code-reviewer → .dev/03-code-review.md
    ↓
diagnostics-fixer → .dev/04-diagnostics.md + fixes
    ↓
test-engineer → .dev/05-test-plan.md + test code
    ↓
test-reviewer → .dev/06-test-review.md
```

### MCP Server Integration

The AL profile uses five MCP servers (configured in `profile-al-development/.mcp.json`):

1. **BC Code Intelligence MCP** (`bc-code-intelligence-mcp`)
   - BC specialist consultations via structured personas
   - Knowledge base in `bc-code-intel-knowledge/`
   - Custom config via `bc-code-intel-config.json`

2. **Microsoft Docs MCP** (`microsoft_docs_mcp`)
   - Official AL/BC documentation lookup
   - HTTP-based MCP server

3. **AL Dependency MCP** (`al-mcp-server`)
   - Base app object navigation
   - Event discovery and dependency analysis
   - Runs via npx

4. **ALCops MCP** (`alcops`, command `alcops-mcp`)
   - AL code analysis/linting via ALCops rules
   - Requires `BCDEVELOPMENTTOOLSPATH` pointed at a matching BC devtools version

5. **BC Telemetry Buddy MCP** (`bc-telemetry-buddy`, command `bctb-mcp`)
   - BC telemetry querying and analysis
   - Custom config via `bctb-config.json`

6. **Serena MCP** (optional project-specific MCP)
   - IDE assistant integration
   - Project context awareness

## Common Development Tasks

### Adding a New Plugin Profile

```bash
cd ~/claude-configs
mkdir -p profile-name/{.claude-plugin,commands,agents}

# Create plugin.json
cat > profile-name/.claude-plugin/plugin.json <<EOF
{
  "name": "profile-name",
  "description": "Brief description",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  }
}
EOF

# Add configuration files
# - profile-name/CLAUDE.md
# - profile-name/commands/*.md
# - profile-name/agents/*.md
# - profile-name/.mcp.json (if needed)

git add profile-name/
git commit -m "Add profile-name plugin"
git push
```

### Updating an Existing Plugin

```bash
cd ~/claude-configs

# Edit files (e.g., profile-al-development/CLAUDE.md)
# Make improvements to agents, commands, or instructions

git add profile-al-development/
git commit -m "Improve [specific aspect]"
git push

# On other computers
git pull  # Changes immediately available to all projects
```

### Creating a Command

Commands are user-invocable slash commands stored in `commands/*.md`:

```markdown
# Command: /command-name

Brief description of what this command does.

## Implementation

[Detailed instructions for Claude on how to execute this command]
```

### Creating an Agent

Agents are autonomous subprocesses stored in `agents/*.md`:

```markdown
# Agent: agent-name

Role description and purpose.

## Input

What this agent reads (e.g., .dev/01-requirements.md)

## Output

What this agent produces (e.g., .dev/02-solution.md)

## Process

[Detailed steps the agent should follow]
```

### Testing Plugin Changes

```bash
# In a test AL project
cd ~/path/to/test-project

# Ensure plugin is enabled in .claude/settings.json
cat .claude/settings.json

# Start Claude Code and test the change
claude

# Test specific command
/command-name "test input"
```

## Configuration Hierarchy

Claude Code loads configurations in this order (later overrides earlier):

1. Enterprise managed settings (if configured)
2. User settings (`~/.claude/settings.json`)
3. User plugins (registered in user settings)
4. **Project settings** (`.claude/settings.json`)
5. **Project plugins** (enabled in project settings) ← This repository's plugins load here
6. Local settings (`.claude/settings.local.json` - gitignored)

## File Naming Conventions

- **Commands**: `commands/command-name.md` (kebab-case)
- **Agents**: `agents/agent-name.md` (kebab-case)
- **Config**: `.claude-plugin/plugin.json`, `.mcp.json`
- **Documentation**: `CLAUDE.md` (uppercase), `README.md`

## MCP Configuration Structure

MCP servers are configured in `.mcp.json` at the plugin root:

```json
{
  "mcpServers": {
    "server-name": {
      "type": "stdio|http|sse",
      "command": "executable",
      "args": ["arg1", "arg2"],
      "env": {
        "VAR_NAME": "value"
      }
    }
  }
}
```

## Git Workflow

This repository should be cloned to `~/claude-configs/` and kept synchronized:

```bash
# Initial setup
cd ~
git clone git@github.com:YOUR_USERNAME/claude-configs.git

# Regular sync
cd ~/claude-configs
git pull  # Get updates from other computers
# ... make changes ...
git add .
git commit -m "Descriptive message"
git push  # Share with other computers
```

## Security Considerations

- Never commit credentials, API keys, or certificates
- Use `.gitignore` to prevent accidental commits
- Keep authentication in project-local files (`.env`, gitignored)
- The `.gitignore` already excludes common sensitive patterns

## AL Profile Specifics

### Approval Gates

The AL profile implements mandatory approval gates in workflows:

1. After requirements analysis - user must approve before solution planning
2. After solution planning - user must approve before implementation
3. After code review - user must approve before testing

These gates prevent wasted work and ensure user validation at each phase.

### Iteration Pattern

Development phase uses iterative refinement:

```
al-developer → code
    ↓
code-reviewer → review
    ↓
If Critical/High issues → ITERATE back to al-developer
If Minor issues → Continue to diagnostics-fixer
```

### AL Compilation

The profile includes an `al-compile` bash script that:

- Auto-detects VS Code AL extension and uses matching compiler version
- Auto-detects workspace structure (single vs multi-app)
- Auto-finds all `.alpackages` directories
- Auto-applies ruleset files
- Includes standard analyzers by default
- Handles complex compilation scenarios automatically

Always use `al-compile` instead of manual AL compiler commands.

## Plugin Version Management

Plugins use semantic versioning in `plugin.json`:

- **Major**: Breaking changes (e.g., renamed commands, removed agents)
- **Minor**: New features (e.g., new commands, enhanced agents)
- **Patch**: Bug fixes, documentation improvements

Update the version in `plugin.json` and document changes in the profile's README.md.

## Troubleshooting

### Plugin Not Loading

1. Verify registration in project `.claude/settings.json`
2. Check `extraKnownMarketplaces` path is absolute
3. Validate `plugin.json` syntax
4. Run `/config` in Claude Code to see loaded plugins

### MCP Server Issues

1. Check `.mcp.json` syntax
2. Verify executable paths (e.g., `bc-code-intelligence-mcp` in PATH)
3. Test MCP servers independently
4. Check environment variables are set correctly

### Command Not Found

1. Ensure plugin is enabled in project settings
2. Command files must be in `commands/` directory
3. Command names are kebab-case without `.md` extension
4. Restart Claude Code session if needed

### Changes Not Appearing

1. Settings and CLAUDE.md hot-reload automatically
2. For command/agent changes, start a new Claude Code session
3. Verify changes are committed and pushed
4. On other computers, verify `git pull` was run

## Best Practices

1. **Test before pushing** - Verify changes work in a test project
2. **Clear commit messages** - Describe what changed and why
3. **Update documentation** - Keep READMEs in sync with changes
4. **Semantic versioning** - Increment version in plugin.json
5. **Backward compatibility** - Avoid breaking changes when possible
6. **Scope plugins narrowly** - One technology/domain per plugin
7. **Document agent inputs/outputs** - Clear data flow in agent definitions
8. **Use approval gates** - Stop for user validation at major decision points
