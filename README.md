# Hammerspoon AI Shortcuts

Keyboard macros that send highlighted text to the NVIDIA Inference Hub and show the answer in a small chat popup.

## Setup

1. Install [Hammerspoon](https://www.hammerspoon.org/)
2. Create a key at https://inference.nvidia.com/key-management
3. Store it in the Keychain (the command prompts for the key):
   `security add-generic-password -s nv-inference-hub -a "$USER" -w`
4. Copy `init.lua` to `~/.hammerspoon/init.lua`
5. Open Hammerspoon, grant Accessibility access, and click **Reload Config**

Change the model with `HUB_MODEL` in `init.lua`.

## Shortcuts

| Shortcut | Action | Prompt |
|---|---|---|
| `Right Opt + /` | **Summarize** | Summarizes the selected text |
| `Right Opt + ,` | **Reply To** | Asks clarifying questions to help draft a reply to the selected message or conversation |

## How it works

1. Highlight any text on screen
2. Press a shortcut
3. The text is copied and a prompt is built around it
4. A chat popup opens and sends the prompt to the Inference Hub
5. Type answers or follow-ups (Enter to send), click **Copy** for the last reply, Esc to close

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
