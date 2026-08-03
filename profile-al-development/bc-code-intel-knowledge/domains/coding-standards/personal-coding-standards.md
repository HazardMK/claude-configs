---
title: "Personal AL Coding Standards"
domain: coding-standards
difficulty: beginner
tags:
  - naming-conventions
  - namespaces
  - appsource-cop
  - code-quality
  - personal-standards
related_topics: []
---

# Personal AL Coding Standards

## CRITICAL: These standards MUST be followed in ALL code generation and reviews

These are personal coding standards that must be strictly enforced across all Business Central AL development.

## Naming Conventions

### **PascalCase Requirement**
- **ALL identifiers** must use PascalCase (leading capital letter)
- This includes:
  - Object names (tables, pages, codeunits, etc.)
  - Variable names
  - Field names
  - Control names
  - Procedure names
  - Parameter names

**Examples:**
```al
// ✅ CORRECT
table 50100 CustomerData
{
    field(1; CustomerName; Text[100]) { }
}

procedure CalculateTotalAmount(SalesAmount: Decimal): Decimal
var
    TaxRate: Decimal;
    TotalAmount: Decimal;
begin
    // ...
end;

// ❌ INCORRECT
table 50100 customer_data  // Wrong: not PascalCase
{
    field(1; customer_name; Text[100]) { }  // Wrong: not PascalCase
}

table 50100 "Customer Data"  // Wrong: contains spaces

procedure calculateTotalAmount(salesAmount: Decimal): Decimal  // Wrong: not PascalCase
var
    tax_rate: Decimal;  // Wrong: not PascalCase
begin
    // ...
end;
```

### **No Special Characters**
- Names must NOT contain special characters
- Allowed: Letters (A-Z, a-z), Numbers (0-9)
- NOT allowed: Underscores (_), hyphens (-), or any other special characters

**Examples:**
```al
// ✅ CORRECT
var
    CustomerNo: Code[20];
    TotalAmount: Decimal;
    IsProcessed: Boolean;

// ❌ INCORRECT
var
    Customer_No: Code[20];     // Wrong: contains underscore
    Total-Amount: Decimal;     // Wrong: contains hyphen
    Is_Processed: Boolean;     // Wrong: contains underscore
```

## Namespace Strategy

### **AppSource Affix as Base Namespace**
- Always use namespaces with your AppSource affix as the base namespace
- The namespace provides the prefix/suffix, so objects DON'T need it

**Example:**
```al
// If your AppSource affix is "ABC"

namespace ABC.Sales;

// ✅ CORRECT - Object names WITHOUT affix (namespace provides it)
table 50100 CustomerData
{
    // ...
}

page 50100 CustomerList
{
    // ...
}

codeunit 50100 SalesManagement
{
    // ...
}

// ❌ INCORRECT - Don't duplicate affix in object name
table 50100 ABCCustomerData  // Wrong: affix already in namespace
table 50100 "Customer Data"  // Wrong: contains spaces
{
    // ...
}
```

### **Namespace Hierarchy**
Organize namespaces hierarchically by functional area:

```al
namespace ABC.Sales;           // Sales-related objects
namespace ABC.Purchasing;      // Purchasing-related objects
namespace ABC.Finance;         // Finance-related objects
namespace ABC.Inventory;       // Inventory-related objects
namespace ABC.Integration;     // Integration-related objects
```

## AppSource Cop Alignment

### **Always Use PREFIXES, Never Suffixes**
- Field names in extensions: Use prefixes on the LEFT side
- Variable names (when needed): Use prefixes on the LEFT side
- All affixes must be prefixes (not suffixes)

**IMPORTANT DISTINCTION:**
- **Custom tables (your own objects)**: Field names DON'T need affixes
- **Table extensions (extending dependencies)**: Field names MUST have prefix affixes

**Examples:**
```al
namespace ABC.Sales;

// ✅ CORRECT - Custom table (no affixes needed on fields)
table 50100 CustomerData
{
    fields
    {
        field(1; CustomerNo; Code[20]) { }  // No affix needed - your table
        field(2; CustomerName; Text[100]) { }  // No affix needed
        field(10; CreditLimit; Decimal) { }  // No affix needed
    }
}

codeunit 50100 SalesManagement
{
    procedure ProcessOrder(SalesHeader: Record "Sales Header")
    var
        TotalAmount: Decimal;  // No affix needed for local vars in your objects
        OrderNo: Code[20];
        ABCCustomAmount: Decimal;  // ✅ Prefix only when disambiguation needed
    begin
        // ...
    end;
}
```

### **When Affixes Are Required**
According to AppSource cop, affixes are required when:
1. Extending standard objects (table extensions, page extensions)
2. Adding new fields to standard tables
3. New variables that might conflict with standard AL

**Extension Example:**
```al
namespace ABC.Sales;

// ✅ CORRECT - Extension name without affix (namespace provides it)
tableextension 50100 SalesHeader extends "Sales Header"
{
    fields
    {
        // ✅ CORRECT - Fields need prefix when extending standard tables
        field(50100; ABCCustomField; Text[50]) { }
        field(50101; ABCSpecialDiscount; Decimal) { }

        // ❌ INCORRECT
        field(50102; CustomField; Text[50]) { }  // Wrong: missing prefix in extension
        field(50103; CustomFieldABC; Text[50]) { }  // Wrong: suffix instead of prefix
        field(50104; "ABC Custom Field"; Text[50]) { }  // Wrong: contains spaces
    }
}

// ✅ CORRECT - Extension name without affix
pageextension 50100 SalesOrder extends "Sales Order"
{
    layout
    {
        addafter(Amount)
        {
            // ✅ CORRECT - Control referencing field with prefix
            field(ABCCustomField; Rec.ABCCustomField) { }
        }
    }
}

// ❌ INCORRECT - Extension names
tableextension 50100 SalesHeaderABC extends "Sales Header"  // Wrong: affix in object name
pageextension 50100 SalesOrderABC extends "Sales Order"  // Wrong: affix in object name
```

## Summary Checklist

When writing or reviewing AL code, ensure:

- [ ] All names use PascalCase (leading capital)
- [ ] No spaces in any identifier names
- [ ] No special characters (underscores, hyphens, etc.) in any identifier names
- [ ] Namespace declared with AppSource affix as base
- [ ] Object names do NOT include affix (namespace provides it)
- [ ] Extension object names do NOT include affix (namespace provides it)
- [ ] Fields in custom tables do NOT need affixes
- [ ] Fields in table extensions MUST have prefix affixes (not suffixes)
- [ ] Variables only need affixes when disambiguation is required (use prefixes)
- [ ] Code aligns with AppSource cop rules

## Evolution

These standards may evolve over time. When new rules are added:
1. Update this document with the new rule
2. Add examples showing correct and incorrect usage
3. Ensure all specialists enforce the new rule going forward

---

**Last Updated**: 2025-11-06
**Status**: Active - Must be followed in all code generation and reviews
