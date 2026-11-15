# GitHub publishing

- When the user asks to push their edits to GitHub, inspect the working tree and diff, then commit all intended user changes and push the current branch to its configured GitHub remote.
- Include the relevant Codex-authored changes made for that request in the same publication when appropriate.
- Do not include ignored files, generated build output, secrets, or unrelated changes. If the intended changes are unclear or include sensitive data, stop and ask before publishing.

# Godot development

- Follow Godot best practices and build gameplay from reusable scenes composed through the scene tree.
- Keep levels and their important objects visually editable in the Godot editor whenever practical; prefer editor-authored scenes and resources over hard-coded layouts.
- Make runtime behavior easy to inspect in the editor, using clear scene structure, meaningful node names, and visible/debuggable state where appropriate.
- Avoid replacing editor-friendly scene workflows with code-only level construction unless the task specifically calls for procedural content.
