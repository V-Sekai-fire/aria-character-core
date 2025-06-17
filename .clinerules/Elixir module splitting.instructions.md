## Elixir Module Splitting Guidelines

### The Principle

To maintain a clean, readable, and maintainable codebase, large Elixir modules should be split into smaller, more focused units. This adheres to the Single Responsibility Principle, making code easier to understand, test, and evolve.

### When to Split

Consider splitting a module if it exhibits one or more of the following characteristics:

*   **Excessive Line Count**: While not a strict rule, modules exceeding 200-300 lines often indicate multiple responsibilities.
*   **Multiple Distinct Responsibilities**: The module handles logically separate concerns (e.g., data management, business logic, external integrations, utility functions).
*   **High Cognitive Load**: It's difficult to understand the module's purpose or how its functions relate without significant effort.
*   **Frequent Changes in Unrelated Areas**: Changes to one part of the module frequently require changes in seemingly unrelated parts, suggesting poor cohesion.

### How to Split

Follow these steps to effectively split a large Elixir module:

1.  **Identify Logical Units**:
    *   Analyze the existing module's functions, types, and data structures.
    *   Group related functionalities into cohesive, single-responsibility units.
    *   Consider creating sub-modules for each identified unit (e.g., `MyModule.SubmoduleA`, `MyModule.SubmoduleB`).

2.  **Create New Sub-modules and Files**:
    *   For each logical unit, create a new `.ex` file within a logical directory structure (e.g., `lib/my_app/my_module/submodule_a.ex`).
    *   Define the new sub-module (e.g., `defmodule MyApp.MyModule.SubmoduleA do ... end`).

3.  **Migrate Code**:
    *   Move the functions, types, and data structures belonging to each logical unit from the original module to its respective new sub-module.
    *   Ensure all necessary `alias` statements are added to the new sub-modules.

4.  **Transform Original Module into a Facade**:
    *   The original large module should become a thin facade.
    *   It should `alias` the new sub-modules.
    *   It should delegate calls to the appropriate sub-modules. For example, if `MyModule.function_a()` moved to `MyModule.SubmoduleA`, the original `MyModule` would have `def function_a(args), do: SubmoduleA.function_a(args)`.
    *   Consider using `defdelegate` for simpler delegation.

5.  **Update Internal References**:
    *   Within the original facade module, update any internal calls to now use the aliased sub-modules (e.g., `SubmoduleA.some_function()`).

6.  **Update External References**:
    *   Identify all other modules in the codebase that call functions from the original large module.
    *   Update these external references to call the original module (now the facade) or, if appropriate and the sub-module's functionality is truly independent, directly call the new sub-modules.

7.  **Verify and Test**:
    *   Run all existing tests to ensure no regressions have been introduced.
    *   Write new tests for the new sub-modules if their functionality warrants independent testing.
    *   Ensure the application compiles without warnings (`mix compile --warnings-as-errors`).

### Benefits

*   **Improved Readability**: Smaller files are easier to read and understand.
*   **Enhanced Maintainability**: Changes are localized, reducing the risk of unintended side effects.
*   **Better Testability**: Individual units can be tested in isolation.
*   **Clearer Responsibilities**: Each module has a well-defined purpose.
*   **Easier Collaboration**: Multiple developers can work on different parts of the module simultaneously with fewer merge conflicts.
