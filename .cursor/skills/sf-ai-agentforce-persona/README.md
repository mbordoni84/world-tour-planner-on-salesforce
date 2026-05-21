# sf-ai-agentforce-persona

> Deep persona design skill for Salesforce Agentforce agents.

Design AI agent personas using the **Identity + Dimensions + Settings** framework. A 7-step interactive questionnaire covering identity traits, archetype selections (Register, Voice, Tone), settings (Brevity, Empathy Level, Humor), chatting style, phrase book generation, scoring, and Agent Builder encoding.

## Quick Start

```
/sf-ai-agentforce-persona
```

## Output

Three Markdown files:
- **Persona document** (`generated/[agent-name]-persona.md`) — design artifact defining who the agent is
- **Scorecard** (`generated/[agent-name]-persona-scorecard.md`) — 50-point rubric evaluation
- **Encoding output** (`generated/[agent-name]-persona-encoding.md`) — Agent Builder field values, platform settings, reusable instruction blocks

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Skill definition and 7-step workflow |
| `references/persona-framework.md` | Identity + dimensions + settings reference |
| `references/persona-encoding-guide.md` | How to encode persona into Agentforce Agent Builder |
| `assets/persona-template.md` | Persona document output template |
| `assets/persona-encoding-template.md` | Agent Builder encoding output template |
| `CREDITS.md` | Attribution and source repo link |
| `LICENSE` | MIT license (cascadi) |

## Framework Overview

- **Identity** — 3-5 adjectives that anchor every decision
- **Register** — Subordinate / Peer / Advisor / Coach
- **Voice** — Formal / Professional / Conversational / Personable
- **Brevity** — Terse / Concise / Moderate / Expansive
- **Tone** — Clinical Analyst / Matter-of-Fact / Encouraging Realist
- **Empathy Level** — Minimal / Moderate / High
- **Humor** — None / Dry / Warm / Playful
- **Chatting Style** — Emoji, Formatting, Punctuation, Capitalization
- **Tone Boundaries** — What the agent must never sound like

## Credits

Original framework by **cascadi** — see [CREDITS.md](CREDITS.md).

## License

MIT — See [LICENSE](LICENSE)
