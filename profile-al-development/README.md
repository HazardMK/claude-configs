# AL Development Profile - Full Lifecycle

**Version:** 2.21.0

Claude Code profile for Microsoft Dynamics 365 Business Central AL development with intelligent complexity routing and proportional planning.

## Overview

This profile provides a document-driven development workflow with specialized agents for each phase of AL development: planning, implementation, testing, and support.

## Key Features

- **Document-Driven Workflow** - All agents collaborate via `.dev/` markdown files
- **Project Memory System** - 40-60% faster workflows via `.dev/project-context.md`
- **Smart Complexity Routing** - Automatically matches workflow to task complexity
- **Proportional Planning** - Simple tasks get concise plans, complex tasks get comprehensive docs
- **Full Lifecycle Coverage** - Requirements → Design → Implementation → Testing
- **MCP Integration** - BC Intelligence, Microsoft Docs, AL Dependency navigation
- **Automated Workflows** - Complete development cycles with single commands
- **Clean Context** - Agents write detailed files, return concise summaries

## Quick Start

### Enable in Your AL Project

In your AL project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "my-configs": {
      "source": {
        "source": "directory",
        "path": "/home/stefan/claude-configs"
      }
    }
  },
  "enabledPlugins": {
    "profile-al-development@my-configs": true
  }
}
```

### Run Full Development Cycle

```
/dev-cycle "Add customer credit limit validation"
```

This runs the complete pipeline:
1. Requirements engineering
2. BC solution design
3. Implementation planning
4. Code implementation
5. Code review
6. Diagnostics fixing
7. Test creation
8. Test review

All results in `.dev/` directory.

## Available Commands

### Estimation & Planning

- `/estimate "[description]"` - Complete estimation workflow (interview → experts → planning → hours)
- `/estimate --quick "[description]"` - Quick estimate (skip interview)
- `/interview` - Deep requirements gathering (40+ questions)
- `/plan "[description]"` - Planning phase only (requirements → design → plan)

### Quick Fix (⚡ Fastest)

- `/fix "[error or bug]"` - Quick bug fix workflow (5 min: locate → fix → verify, no planning)

### Full Workflows

- `/dev-cycle "[description]"` - Complete development cycle
- `/develop` - Development phase only (implement → review → fix)
- `/test` - Testing phase only (create tests → review)

### On-Demand Support

- `/bc-expert "[question]"` - Consult BC specialists
- `/docs-lookup "[topic]"` - Search Microsoft Docs
- `/nav-baseapp "[query]"` - Explore base app objects

## Development Phases

### Phase 1: Planning & Design

**Agents:**
1. **requirements-engineer** - Extract and document requirements
2. **solution-planner** - Design BC-integrated solution + create implementation plan

**Output:**
- `.dev/01-requirements.md`
- `.dev/02-solution-plan.md`

### Phase 2: Development & Quality

**Agents:**
3. **al-developer** - Write AL code
4. **code-reviewer** - Review code quality
5. **diagnostics-fixer** - Fix compiler diagnostics

**Output:**
- `.dev/03-code-review.md`
- `.dev/04-diagnostics.md`
- AL source files

### Phase 3: Testing & Validation

**Agents:**
6. **test-engineer** - Create comprehensive tests
7. **test-reviewer** - Review test coverage

**Output:**
- `.dev/05-test-plan.md`
- `.dev/06-test-review.md`
- Test codeunits

### Support Agents (On-Demand)

**Agents:**
8. **bc-expert** - BC specialist consultation
9. **docs-lookup** - Microsoft Docs search
10. **dependency-navigator** - Base app exploration

**Output:**
- `.dev/expert-[topic].md`
- `.dev/docs-[topic].md`
- `.dev/nav-[topic].md`

**Note:** solution-planner uses BC Intelligence, MS Docs, and AL Dependency MCP tools internally.

## Automated Test Execution (v2.20+)

Agents can now automatically compile, publish, and execute tests during TDD workflow:

### Requirements

1. **bc-publish** - Publishes .app files to BC server
2. **bc-test** - Executes test codeunits via OData API
3. **.bcconfig.json** - BC server configuration

### Setup

Install bc-publish and bc-test utilities (or ensure they're in PATH):

```bash
# Create .bcconfig.json in your project root
bc-publish --init
```

Edit `.bcconfig.json`:

```json
{
  "server": "http://localhost",
  "port": 7048,
  "instance": "BC",
  "tenant": "default",
  "username": "admin",
  "password": "Admin123!",
  "apiInstance": "BC",
  "apiPassword": "your-web-service-access-key",
  "schemaUpdateMode": "synchronize"
}
```

### TDD Workflow with Automated Testing

When using TDD workflow (`/develop` with test specifications):

1. **RED Phase**: Agent writes failing test, compiles, publishes, runs → verifies FAIL → asks user to approve
2. **GREEN Phase**: Agent implements code, compiles, publishes, runs → verifies PASS → asks user to approve
3. **REFACTOR Phase**: Agent refactors, compiles, publishes, runs all tests → verifies all PASS → asks user to approve

This automation maintains TDD discipline while eliminating manual deployment steps.

### Advanced bc-test Features

**Auto-Detection:**
- bc-test automatically detects test codeunit range from app.json
- No need to specify codeunit IDs manually

**File Output:**
- `-o file.txt`: Write detailed results to file (human-readable)
- `-o file.json -f json`: Export as JSON for CI/CD integration
- Console shows summary only for clean conversation

**Failures-Only Filter:**
- `--failures-only`: Focus on failed tests only
- Smart default: Console output shows failures-only by default

**Examples:**
```bash
# Auto-detect range, show failures only (default)
bc-test

# Save all results to file
bc-test -o .dev/test-results.txt

# Export as JSON for CI/CD
bc-test -o results.json -f json

# Focus on failures
bc-test --failures-only
```

## MCP Server Configuration

This profile uses three MCP servers:

### BC Code Intelligence MCP
- BC specialist consultations
- Best practices and patterns
- Architecture guidance

### Microsoft Docs MCP
- Official AL documentation
- API references
- Breaking changes information

### AL Dependency MCP
- Base app object navigation
- Event discovery
- Dependency analysis

## Directory Structure

```
profile-al-development/
├── .claude-plugin/
│   └── plugin.json           # Plugin metadata
├── agents/                   # Specialized agents (10 total)
│   ├── requirements-engineer.md
│   ├── solution-planner.md
│   ├── al-developer.md
│   ├── code-reviewer.md
│   ├── diagnostics-fixer.md
│   ├── test-engineer.md
│   ├── test-reviewer.md
│   ├── bc-expert.md
│   ├── docs-lookup.md
│   └── dependency-navigator.md
├── commands/                 # Slash commands
│   ├── dev-cycle.md
│   ├── plan.md
│   ├── develop.md
│   ├── test.md
│   ├── bc-expert.md
│   ├── docs-lookup.md
│   └── nav-baseapp.md
├── CLAUDE.md                 # Main profile instructions
├── .mcp.json                 # MCP server configuration
└── README.md                 # This file
```

## Typical Workflow

### Quick Bug Fix (5 minutes)

```bash
# Fast track for small bugs
/fix "Email validation fails for john.doe@example.com"

# Reviews:
# - Locates the issue in code
# - Shows proposed fix
# - You approve
# - Runs diagnostics
# - Done! Ready to commit
```

### Starting a New Feature

```bash
# 1. Run full development cycle
/dev-cycle "Add field validation for customer emails"

# 2. Review output files
cat .dev/01-requirements.md
cat .dev/02-solution-plan.md

# 3. Implementation, review, diagnostics run automatically

# 4. Review code and test results
cat .dev/03-code-review.md
cat .dev/06-test-review.md

# 5. Done! Code, tests, and documentation all in place
```

### Planning Only

```bash
# Create solution plan without coding
/plan "Add dashboard for sales analytics"

# Review plan
cat .dev/02-solution-plan.md

# Later, implement the plan
/develop
```

### Getting BC Expert Help

```bash
# Consult BC specialist
/bc-expert "Best practice for extending posting routines?"

# Review consultation
cat .dev/expert-posting-routines.md
```

### Exploring Base App

```bash
# Find extension points
/nav-baseapp "Find all Customer table events"

# Review findings
cat .dev/nav-customer-events.md
```

## AL Coding Standards

This profile enforces BC best practices:

- **PascalCase** naming
- **Table extensions** over base modifications
- **Event subscribers** for base app integration
- **SetLoadFields** for performance
- **XML documentation** on public procedures
- **DataClassification** on all fields

See `CLAUDE.md` for complete standards.

## Output Files

All agent work documented in `.dev/`:

```
.dev/
├── 01-requirements.md      # What to build
├── 02-solution-plan.md     # Complete solution (design + implementation)
├── 03-code-review.md       # Code quality review
├── 04-diagnostics.md       # Compiler fixes
├── 05-test-plan.md         # Test strategy
├── 06-test-review.md       # Test coverage review
├── session-log.md          # Agent activity log
├── expert-*.md             # BC specialist consultations
├── docs-*.md               # Microsoft Docs lookups
└── nav-*.md                # Base app explorations
```

## Agent Collaboration

Agents read previous outputs to maintain context:

```
requirements-engineer → 01-requirements.md
                              ↓
solution-planner → 02-solution-plan.md (reads 01, uses MCP tools)
                              ↓
al-developer → AL code (reads 02)
                              ↓
code-reviewer → 03-code-review.md (reads code)
                              ↓
[and so on...]
```

## Benefits

### Document-Driven
- Complete audit trail
- Easy to review and iterate
- Persistent context across sessions

### Clean Main Conversation
- Agents write to files, not chat
- Concise status updates only
- No context pollution

### Full Lifecycle
- Every phase covered
- Nothing falls through cracks
- Consistent quality

### MCP Integration
- Official Microsoft documentation
- BC specialist expertise
- Base app understanding

## Customization

### Project-Specific Settings

In your project's `.claude/CLAUDE.md`:

```markdown
# Project-Specific AL Guidelines

## Object Number Range
- Tables: 50100-50199
- Codeunits: 50100-50199
- Pages: 50100-50199

## Custom Prefix
- All objects: `ACME`

@/home/stefan/claude-configs/profile-al-development/CLAUDE.md
```

The `@` import loads the profile, your settings augment it.

## Troubleshooting

### Plugin Not Loading
```bash
# Verify registration
cat ~/.claude/settings.json

# Check plugin valid
cat ~/claude-configs/profile-al-development/.claude-plugin/plugin.json
```

### Agents Not Working
- Ensure MCP servers are configured
- Check `.mcp.json` paths
- Verify BC Intelligence MCP is running

### ALCops MCP Server Crashes on Startup (version mismatch)

`alcops-mcp` (ALCops.Mcp, alpha) auto-downloads the *latest* BC DevTools from NuGet, but as of
`0.1.0-alpha.9` it's internally pinned to an older version (`17.0.33.55542`). The mismatch
causes a `FileNotFoundException` for `Microsoft.Dynamics.Nav.CodeAnalysis` on startup.

**Fix:** install the matching pinned BC DevTools version and point `BCDEVELOPMENTTOOLSPATH` at
it (this is what the path in `.mcp.json` expects to exist):

```bash
dotnet tool install --tool-path ~/.alcops/devtools-17.0.33.55542 --version 17.0.33.55542 Microsoft.Dynamics.BusinessCentral.Development.Tools
```

If `alcops-mcp` starts crashing again after an ALCops.Mcp update, check what version it now
expects and reinstall the pinned devtools at that version instead, updating both the
`--version` above and the folder name in `.mcp.json`'s `BCDEVELOPMENTTOOLSPATH`:

```bash
grep -A1 '"Microsoft.Dynamics.Nav.CodeAnalysis"' ~/.dotnet/tools/.store/alcops.mcp/*/alcops.mcp/*/tools/*/any/ALCops.Mcp.deps.json
```

### Clean Slate
```bash
# Remove work directory to start fresh
rm -rf .dev/
```

## Recommended Hooks

Desktop notifications for when Claude needs your attention or finishes work. Add to your user or project settings (not in the plugin):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "AskUserQuestion",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send -t 7000 'Claude Code' 'Question: Waiting for your answer'"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "notify-send -t 5000 'Claude Code' 'Done: Ready for input'"
          }
        ]
      }
    ]
  }
}
```

**Note:** These hooks go in `~/.claude/settings.json` (user) or `.claude/settings.json` (project), not in the plugin itself. Replace `notify-send` with your system's notification command if not on Linux.

## Requirements

- Claude Code CLI
- AL Language extension
- BC development environment
- MCP servers (optional but recommended):
  - BC Code Intelligence MCP
  - Microsoft Docs MCP
  - AL Dependency MCP

## Contributing

Improvements to this profile benefit all your AL projects. After making changes:

```bash
cd ~/claude-configs
git add profile-al-development/
git commit -m "Improve [aspect]"
git push
```

On other computers:
```bash
cd ~/claude-configs
git pull
```

## Resources

- [AL Language Documentation](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-programming-in-al)
- [BC Best Practices](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dev-best-practices)
- [Claude Code Profiles](https://docs.anthropic.com/claude/docs/claude-code)

---

**Full-lifecycle AL development with intelligent agents and document-driven workflow.**
