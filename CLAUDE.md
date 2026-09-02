# Project: Music Interactive Cheatsheet (MIC)
MIC is an interactive cheatsheet to help music composing beginner in learning the relative of keys, chords, etc of music theory.


# Tech stack
Godot 4.7.2, GDScript + Python 3.14 tooling scripts (venv in /tools/.venv)

# Commands
- Playtest (manual): open the project in the Godot editor and press F5
- Verify/run project: use the Godot MCP server (run_project with this 
  project's path), then check for errors with get_debug_output
- Activate Python tooling env: source tools/.venv/bin/activate
- Run tooling scripts: python tools/script_name.py

# Architecture
- Always propose the architecture/approach before implementing a new 
  feature — don't start coding until I confirm the direction.
# Conventions
- Comment all non-trivial code — explain why, not just what.
- Python: follow PEP 8.
- GDScript: follow Godot's official style guide (snake_case functions/vars, 
  PascalCase class/node names, tabs for indentation).

# Workflow
- Work directly in this project folder — never a separate branch/copy.
- Don't run tests/builds unless I explicitly ask.