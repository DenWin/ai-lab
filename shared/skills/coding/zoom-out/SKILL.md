---
name: zoom-out
description: Tell the agent to zoom out and give broader context or a higher-level perspective. Use when you're unfamiliar with a section of code or need to understand how it fits into the bigger picture.
disable-model-invocation: true
upstream-author: mattpocock
upstream-repo: https://github.com/mattpocock/skills
upstream-path: skills/engineering/zoom-out/SKILL.md
upstream-commit: aaf2453fbdfe7a15c07f11d861224f34ab4b53cb
---

I don't know this area of code well. Go up a layer of abstraction. Give me a map of all the relevant modules and callers, using the project's domain glossary vocabulary.

If a filesystem is available, read the code to build the map. If not, work from the code and context I've shared in the conversation, and name anything you'd need me to paste for a complete map.
