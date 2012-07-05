--[[============================================================================

Render Pattern Sequencer selection to Sample version 0.1.

Released under a CC-BY license.
http://creativecommons.org/licenses/by/3.0/

============================================================================]]--

-- Globals used throughout
local master_track = nil
local device_bypass_states = {}


-- Just a helper method to find the master track
function find_master()
  for index, track in ipairs(renoise.song().tracks) do
    if track.type == renoise.Track.TRACK_TYPE_MASTER then
      master_track = track
    end
  end
end


-- Renders Pattern Sequencer selection to disk
function render_pattern_sequencer_selection()
  -- Finds/sets the start and end positions for the selection
  local s_pos = renoise.SongPos()
  local e_pos = renoise.SongPos()
  s_pos.sequence = renoise.song().sequencer.selection_range[1]
  e_pos.sequence = renoise.song().sequencer.selection_range[2]
  e_pos.line = renoise.song().patterns[renoise.song().sequencer:pattern(e_pos.sequence)].number_of_lines

  find_master()
  bypass_master()

  -- Renders to file using the above start/end positions
  local file = os.tmpname('wav')
  renoise.song():render({start_pos = s_pos, end_pos = e_pos}, file, function() make_sample(file) end)
end

-- When rendering is complete, this loads and processes the file
function make_sample(_file)
  -- Creates an instrument to contain the sample
  local inst = renoise.song():insert_instrument_at(#renoise.song().instruments + 1)
  inst.name = "Rendered Pattern Sequence selection"

  -- Loads file to and changes attributes of the sample
  inst.samples[1].sample_buffer:load_from(_file)
  inst.samples[1].autoseek = true
  inst.samples[1].name = "..."

  reset_master()
end


-- Saves original device bypass states on the master track to table
function bypass_master()
  for index, device in ipairs(master_track.devices) do
    if device.name == "MasterTrackVolPan" then -- Skip TrackVolPan device
    else
      table.insert(device_bypass_states, device.is_active) -- Saves device bypass state to table
      device.is_active = false -- Bypasses device
    end
  end
end


-- Recalls original device bypass states on the master from table
function reset_master()
    for index, device in ipairs(master_track.devices) do
      if device.name == "MasterTrackVolPan" then -- Skip TrackVolPan device
      else
        device.is_active = device_bypass_states[index - 1] -- Recalls device bypass state from table
      end
    end
    device_bypass_states = {}
end


--[ Housekeeping ]-------------------------------------------

renoise.tool():add_menu_entry {
  name = "Pattern Sequencer:Render Selection to Sample...",
  invoke = render_pattern_sequencer_selection
}