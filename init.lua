require("hs.ipc")  -- enables the `hs` command-line tool
hs.autoLaunch(true)

-- NVIDIA Inference Hub (OpenAI-compatible LiteLLM gateway)
local HUB_URL = "https://inference-api.nvidia.com/v1/chat/completions"
local HUB_MODEL = "azure/anthropic/eccn-claude-haiku-5-5"

-- Key lives in the macOS Keychain, never in this repo:
--   security add-generic-password -s nv-inference-hub -a "$USER" -w
local function hubKey()
  local out = hs.execute("security find-generic-password -s nv-inference-hub -a \"$USER\" -w")
  return out and out:gsub("%s+$", "") or ""
end

local CHAT_HTML = [[
<!doctype html><html><head><meta charset="utf-8"><style>
  :root { color-scheme: light dark; }
  body { margin: 0; font: 14px -apple-system, sans-serif; display: flex; flex-direction: column; height: 100vh; }
  #log { flex: 1; overflow-y: auto; padding: 12px; }
  .msg { white-space: pre-wrap; margin: 0 0 10px; padding: 8px 10px; border-radius: 8px; }
  .user { background: rgba(10,132,255,.15); }
  .assistant { background: rgba(128,128,128,.15); }
  .pending { opacity: .6; font-style: italic; }
  #bar { display: flex; gap: 6px; padding: 8px; border-top: 1px solid rgba(128,128,128,.3); }
  textarea { flex: 1; font: inherit; height: 44px; resize: none; }
  button { font: inherit; }
</style></head><body>
  <div id="log"></div>
  <div id="bar">
    <textarea id="input" placeholder="Answer or ask a follow-up (Enter to send, Esc to close)"></textarea>
    <button id="copy" title="Copy last reply">Copy</button>
  </div>
<script>
  const log = document.getElementById("log"), input = document.getElementById("input");
  const post = (m) => webkit.messageHandlers.hub.postMessage(m);
  function add(role, text) {
    document.querySelectorAll(".pending").forEach(e => e.remove());
    const d = document.createElement("div");
    d.className = "msg " + role; d.textContent = text;
    log.appendChild(d); log.scrollTop = log.scrollHeight;
  }
  input.addEventListener("keydown", e => {
    if (e.key === "Enter" && !e.shiftKey && input.value.trim()) {
      e.preventDefault(); post({action: "send", text: input.value}); input.value = "";
    }
  });
  document.addEventListener("keydown", e => { if (e.key === "Escape") post({action: "close"}); });
  document.getElementById("copy").onclick = () => post({action: "copy"});
  input.focus();
</script></body></html>
]]

-- One chat window at a time; holds the conversation for follow-ups
local chat = { view = nil, messages = {} }

local function js(fn, ...)
  local args = {}
  for i, v in ipairs({...}) do args[i] = hs.json.encode({v}):sub(2, -2) end
  chat.view:evaluateJavaScript(fn .. "(" .. table.concat(args, ",") .. ")")
end

local function askHub()
  js("add", "assistant pending", "Thinking...")
  local body = hs.json.encode({ model = HUB_MODEL, messages = chat.messages })
  local headers = { ["Authorization"] = "Bearer " .. hubKey(), ["Content-Type"] = "application/json" }
  hs.http.asyncPost(HUB_URL, body, headers, function(status, resp)
    if not chat.view then return end
    local ok, data = pcall(hs.json.decode, resp or "")
    local reply = ok and data and data.choices and data.choices[1].message.content
    if status ~= 200 or not reply then
      js("add", "assistant", "Error " .. tostring(status) .. ": " .. tostring(resp))
      return
    end
    table.insert(chat.messages, { role = "assistant", content = reply })
    js("add", "assistant", reply)
  end)
end

local function send(text, shown)
  table.insert(chat.messages, { role = "user", content = text })
  js("add", "user", shown or text)
  askHub()
end

local function closeChat()
  if chat.view then chat.view:delete() end
  chat.view, chat.messages = nil, {}
end

local function openChat(title, onReady)
  closeChat()
  local uc = hs.webview.usercontent.new("hub"):setCallback(function(msg)
    local m = msg.body
    if m.action == "send" then send(m.text)
    elseif m.action == "close" then closeChat()
    elseif m.action == "copy" then
      local last = chat.messages[#chat.messages]
      if last and last.role == "assistant" then
        hs.pasteboard.setContents(last.content)
        hs.alert.show("Copied")
      end
    end
  end)
  local f = hs.screen.mainScreen():frame()
  local w, h = 560, 520
  chat.view = hs.webview.new({ x = f.x + (f.w - w) / 2, y = f.y + (f.h - h) / 2, w = w, h = h }, {}, uc)
    :windowTitle(title)
    :windowStyle({ "titled", "closable", "resizable" })
    :closeOnEscape(true)
    :allowTextEntry(true)
    :level(hs.drawing.windowLevels.floating)
    :navigationCallback(function(event)
      if event == "didFinishNavigation" and onReady then onReady() end
    end)
    :html(CHAT_HTML)
    :show()
  chat.view:hswindow():focus()
end

-- Helper: copy selection and start a Hub chat about it
local function aiAction(title, buildPrompt)
  hs.eventtap.keyStroke({"cmd"}, "c")
  hs.timer.doAfter(0.3, function()
    local text = hs.pasteboard.getContents()
    if not text or text == "" then
      hs.notify.new({title=title, informativeText="No text selected!"}):send()
      return
    end
    openChat(title, function() send(buildPrompt(text), title .. ":\n\n" .. text) end)
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
