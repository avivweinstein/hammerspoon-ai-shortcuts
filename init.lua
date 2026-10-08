-- Helper: write prompt to temp file and open in Claude Code via iTerm2
local function openInClaude(prompt)
  local f = io.open("/tmp/hs_claude_prompt.txt", "w")
  f:write(prompt)
  f:close()

  hs.osascript.applescript([[
    tell application "iTerm2"
      activate
      create window with default profile
      tell current session of current window
        write text "claude \"$(cat /tmp/hs_claude_prompt.txt)\""
      end tell
    end tell
  ]])
end

-- Helper: copy selection and run an AI action
local function aiAction(title, buildPrompt)
  hs.eventtap.keyStroke({"cmd"}, "c")
  hs.timer.doAfter(0.3, function()
    local text = hs.pasteboard.getContents()
    if not text or text == "" then
      hs.notify.new({title=title, informativeText="No text selected!"}):send()
      return
    end
    hs.notify.new({title=title, informativeText="Opening Claude..."}):send()
    openInClaude(buildPrompt(text))
  end)
end

-- Summarize selected text
-- Trigger: Right Opt + /
hs.hotkey.bind({"ralt"}, "/", function()
  aiAction("Summarize", function(text)
    return "Summarize this:\n\n" .. text
  end)
end)

-- Reply to selected text/conversation
-- Trigger: Right Opt + ,
hs.hotkey.bind({"ralt"}, ",", function()
  aiAction("Reply To", function(text)
    return "I need to reply to the following message or conversation. Before drafting a reply, ask me simple, specific questions one at a time to gather the context you need (e.g. my relationship to the sender, the goal of my reply, any key points I want to make). Keep your questions short and easy to answer. Here is the text:\n\n" .. text
  end)
end)
