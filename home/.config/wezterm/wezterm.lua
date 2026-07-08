local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "rose-pine-moon"
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 15.0
config.window_background_opacity = 0.8
config.macos_window_background_blur = 50
config.hide_tab_bar_if_only_one_tab = false -- Keep tab bar visible to display status info
config.window_decorations = "RESIZE"

-- Dim and desaturate inactive panes to make the active pane pop
config.inactive_pane_hsb = {
  saturation = 0.6,
  brightness = 0.6,
}

config.colors = {
  selection_bg = "#56526e",
  selection_fg = "#e0def4",
  split = "#44415a", -- clean divider line color between panes
}

-- Keep track of closed tabs and panes to allow reopening them
local closed_entities = {}

-- Helper to safely execute a git command in the pane's working directory
local function run_git_cmd(cwd, cmd)
  local handle = io.popen("git -C " .. string.format("%q", cwd) .. " " .. cmd .. " 2>/dev/null")
  if not handle then return nil end
  local result = handle:read("*a")
  handle:close()
  return result
end

-- Retrieve git stats (files changed, additions, removals)
local function get_git_stats(cwd)
  local status_out = run_git_cmd(cwd, "status --porcelain")
  if not status_out or status_out == "" then
    return nil
  end

  -- Count changed/untracked files
  local files_changed = 0
  for _ in status_out:gmatch("[^\r\n]+") do
    files_changed = files_changed + 1
  end

  -- Sum additions and removals
  local numstat_out = run_git_cmd(cwd, "diff HEAD --numstat")
  local additions = 0
  local removals = 0

  if numstat_out then
    for line in numstat_out:gmatch("[^\r\n]+") do
      local add, rem = line:match("^(%d+)%s+(%d+)")
      if add and rem then
        additions = additions + tonumber(add)
        removals = removals + tonumber(rem)
      end
    end
  end

  return {
    files = files_changed,
    additions = additions,
    removals = removals
  }
end

-- Show git status, branch, additions/removals in the top-right status bar
wezterm.on("update-right-status", function(window, pane)
  local cwd_uri = pane:get_current_working_dir()
  if not cwd_uri then
    window:set_right_status("")
    return
  end

  local cwd = cwd_uri.file_path

  -- Get git branch
  local branch = run_git_cmd(cwd, "branch --show-current")
  if not branch then
    window:set_right_status("")
    return
  end
  branch = branch:gsub("%s+", "")

  if branch ~= "" then
    local format = {}
    table.insert(format, { Foreground = { Color = "#ea9a97" } }) -- Rose (Branch name)
    table.insert(format, { Text = "   " .. branch })

    local stats = get_git_stats(cwd)
    if stats then
      table.insert(format, { Foreground = { Color = "#6e6a86" } }) -- Muted separator
      table.insert(format, { Text = "  │  " })

      table.insert(format, { Foreground = { Color = "#9ccfd8" } }) -- Foam (File icon)
      table.insert(format, { Text = " " })

      table.insert(format, { Foreground = { Color = "#e0def4" } }) -- Text (File count)
      table.insert(format, { Text = tostring(stats.files) .. "  •  " })

      table.insert(format, { Foreground = { Color = "#a6da95" } }) -- Green (Additions)
      table.insert(format, { Text = "+" .. tostring(stats.additions) .. " " })

      table.insert(format, { Foreground = { Color = "#f38ba8" } }) -- Red (Removals)
      table.insert(format, { Text = "-" .. tostring(stats.removals) })
    end

    table.insert(format, { Text = "  " })
    window:set_right_status(wezterm.format(format))
  else
    window:set_right_status("")
  end
end)

config.keys = {
  {
    key = 'd',
    mods = 'CMD',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'd',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'k',
    mods = 'CMD',
    action = wezterm.action.Multiple {
      wezterm.action.ClearScrollback 'ScrollbackAndViewport',
      wezterm.action.SendKey { key = 'l', mods = 'CTRL' },
    },
  },
  {
    key = 'w',
    mods = 'CMD',
    action = wezterm.action_callback(function(window, pane)
      local mux_window = window:mux_window()
      if mux_window then
        local tabs = mux_window:tabs()
        local active_tab = mux_window:active_tab()
        if not active_tab then return end

        local cwd_uri = pane:get_current_working_dir()
        local cwd = cwd_uri and cwd_uri.file_path or nil
        local panes = active_tab:panes()

        if #panes > 1 then
          -- If there are multiple panes, close the active pane first
          table.insert(closed_entities, {
            type = 'pane',
            cwd = cwd,
          })
          window:perform_action(wezterm.action.CloseCurrentPane { confirm = false }, pane)
        else
          -- If there is only one pane in this tab, close the tab
          if #tabs > 1 then
            table.insert(closed_entities, {
              type = 'tab',
              cwd = cwd,
            })
            window:perform_action(wezterm.action.CloseCurrentTab { confirm = false }, pane)
          else
            -- Last pane of the last tab: confirm before quitting WezTerm
            window:perform_action(wezterm.action.CloseCurrentTab { confirm = true }, pane)
          end
        end
      end
    end),
  },
  {
    key = 'w',
    mods = 'CMD|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      if #closed_entities > 0 then
        local last_closed = table.remove(closed_entities)
        if last_closed.type == 'tab' then
          window:perform_action(
            wezterm.action.SpawnCommandInNewTab {
              cwd = last_closed.cwd,
            },
            pane
          )
        elseif last_closed.type == 'pane' then
          pane:split {
            direction = 'Right',
            cwd = last_closed.cwd,
          }
        end
      end
    end),
  },
  {
    key = 'LeftArrow',
    mods = 'CMD|SHIFT',
    action = wezterm.action.MoveTabRelative(-1),
  },
  {
    key = 'RightArrow',
    mods = 'CMD|SHIFT',
    action = wezterm.action.MoveTabRelative(1),
  },
  {
    key = 'LeftArrow',
    mods = 'CMD',
    action = wezterm.action_callback(function(window, pane)
      local tab = window:active_tab()
      if tab then
        local target_pane = tab:get_pane_direction("Left")
        if target_pane then
          target_pane:activate()
        else
          window:perform_action(wezterm.action.ActivateTabRelative(-1), pane)
        end
      end
    end),
  },
  {
    key = 'RightArrow',
    mods = 'CMD',
    action = wezterm.action_callback(function(window, pane)
      local tab = window:active_tab()
      if tab then
        local target_pane = tab:get_pane_direction("Right")
        if target_pane then
          target_pane:activate()
        else
          window:perform_action(wezterm.action.ActivateTabRelative(1), pane)
        end
      end
    end),
  },
  {
    key = 'UpArrow',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection('Up'),
  },
  {
    key = 'DownArrow',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection('Down'),
  },
  {
    key = 'Enter',
    mods = 'SHIFT',
    action = wezterm.action.SendString("\x1b[13;2u"),
  },
  {
    key = 'Enter',
    mods = 'CMD',
    action = wezterm.action.ToggleFullScreen,
  },
}

return config
