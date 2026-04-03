# Hammerspoon AI Shortcuts

Keyboard macros that send highlighted text to Claude Code (via iTerm2) for AI assistance.

## Setup

1. Install [Hammerspoon](https://www.hammerspoon.org/)
2. Install [iTerm2](https://iterm2.com/)
3. Install [Claude Code](https://claude.ai/code) and ensure `claude` is in your PATH
4. Copy `init.lua` to `~/.hammerspoon/init.lua`
5. Open Hammerspoon and click **Reload Config**

## Shortcuts

| Shortcut | Action | Prompt |
|---|---|---|
| `Right Opt + /` | **Summarize** | Summarizes the selected text |
| `Right Opt + .` | **Rephrase** | Rephrases in a clean, concise, professional tone while preserving all original ideas |
| `Right Opt + ,` | **Reply To** | Asks clarifying questions to help draft a reply to the selected message or conversation |

## How it works

1. Highlight any text on screen
2. Press a shortcut
3. The text is copied and a prompt is built around it
4. iTerm2 opens a new window and runs `claude "<prompt>"` via Claude Code CLI
5. An interactive Claude session starts with your text already submitted

## Adding new shortcuts

Each shortcut follows the same pattern in `init.lua`:

```lua
hs.hotkey.bind({"ralt"}, "KEY", function()
  aiAction("Title", function(text)
    return "Your prompt here:\n\n" .. text
  end)
end)
```

## Reloading config

After any change to `init.lua`, click the Hammerspoon icon in the menu bar and select **Reload Config**.
