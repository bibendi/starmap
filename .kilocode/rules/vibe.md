# Rule: Loading contextual task data from .vibe/

Whenever the user refers to a task by its number (e.g. "001", "task 001", "issue 002"),
follow this procedure:

1. Locate the folder `.vibe/{task_number}_*` in the project.
   - Example: if the user says "task 005", you should look for `.vibe/005_*`
   - If multiple match, pick the first lexicographically or ask the user to clarify.

2. Read the following files **if present**:
   - `task.md` — general overview and goal of the task
   - `plan.md` — main plan and substeps
   - All files matching `stage_*.md` — stage-specific details
   - (Optionally) any other `.md` file in that folder as supporting context

3. Use that information to help the user in answering or continuing the conversation.

Example interaction:
User: "Continue implementation for task 003"
Agent:
- Loads `.vibe/003_task_name/`
- Reads `story.md` and `plan.md`
- Uses their content to understand what "implementation" refers to
