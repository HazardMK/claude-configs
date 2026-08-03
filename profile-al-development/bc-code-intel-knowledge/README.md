# Personal AL Coding Standards - Knowledge Layer

This directory contains personal coding standards that will be enforced across all Business Central AL development projects.

## Structure

```
bc-code-intel-knowledge/
├── domains/
│   └── coding-standards/
│       └── personal-coding-standards.md  # Complete coding standards documentation
└── specialists/
    ├── roger-reviewer.md  # Enhanced to enforce standards in reviews
    └── sam-coder.md       # Enhanced to follow standards in code generation
```

## Quick Reference - Your Coding Standards

### 1. Naming Conventions
- **PascalCase for everything**: All identifiers must use PascalCase (e.g., `CustomerData`, `TotalAmount`)
- **No spaces**: Never use spaces in names (wrong: `"Customer Data"`, correct: `CustomerData`)
- **No special characters**: No underscores, hyphens, or other special chars

### 2. Namespace Strategy
- Use AppSource affix as base namespace: `namespace ABC.Sales;`
- Object names do NOT include the affix (namespace provides it)
- Extensions also do NOT include affix in object name

### 3. Affix Rules (PREFIXES ONLY)
- **Custom tables**: Fields DON'T need affixes
- **Table extensions**: Fields MUST have prefix affixes (e.g., `ABCCustomField`)
- **Never use suffixes**: Always `ABCFieldName`, never `FieldNameABC`

## Examples

### ✅ CORRECT

```al
namespace ABC.Sales;

// Custom table - no affixes on fields
table 50100 CustomerData
{
    fields
    {
        field(1; CustomerNo; Code[20]) { }
        field(2; CustomerName; Text[100]) { }
    }
}

// Extension - no affix in object name, but fields need prefixes
tableextension 50100 SalesHeader extends "Sales Header"
{
    fields
    {
        field(50100; ABCCustomField; Text[50]) { }
        field(50101; ABCDiscountRate; Decimal) { }
    }
}
```

### ❌ INCORRECT

```al
namespace ABC.Sales;

table 50100 "Customer Data"  // Wrong: contains spaces
table 50100 ABCCustomerData  // Wrong: duplicate affix

tableextension 50100 SalesHeaderABC extends "Sales Header"  // Wrong: affix in name
{
    fields
    {
        field(50100; CustomFieldABC; Text[50]) { }  // Wrong: suffix
        field(50101; "ABC Custom Field"; Text[50]) { }  // Wrong: spaces
    }
}
```

## Updating Standards

To add new rules:
1. Edit `domains/coding-standards/personal-coding-standards.md`
2. Add the rule with clear examples
3. Specialists will automatically enforce new rules

## Last Updated

2025-11-06
