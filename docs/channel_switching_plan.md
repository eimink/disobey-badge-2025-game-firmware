# Channel Switching for Badge-to-Badge Games

**Date:** January 23, 2026  
**Status:** Planning phase

## Overview
Implement dynamic WiFi channel switching to reduce interference during peer-to-peer games at the conference with 600 badges.

**Problem:** 
- All badges on channel 1 = massive interference/congestion
- Two badges playing TicTacToe need reliable communication
- Solution: Switch to a private channel during gameplay

**Example Game:** TicTacToe (`tictac`) - multiplayer game between two badges

---

## Channel Strategy

### Default Channel: 1
- **Used for:** Discovery, beacons, finding opponents
- **All badges:** Broadcast on channel 1
- **Scanner screen:** Shows nearby badges on channel 1

### Game Channels: 2-13
- **Used for:** Active peer-to-peer gameplay
- **Assignment:** Randomly select or negotiate between two badges
- **Range:** Channels 2-13 (avoid 1 for discovery)

### Switching Flow
```
Badge A                          Badge B
  |                                |
  |-- Scanning on Ch1 ----------->|
  |<- See each other ------------->|
  |                                |
  |-- Select opponent ------------->|
  |-- Agree on Ch7 --------------->|  (negotiation)
  |                                |
  |== Switch to Ch7 ==============>|
  |<= Play game on Ch7 ==========>|  (isolated communication)
  |                                |
  |-- Game ends ------------------>|
  |== Switch back to Ch1 =========>|
  |<- Resume scanning ------------->|
```

---

## Implementation Architecture

### 1. Channel Manager (New Module)

**Location:** `/workspace/frozen_firmware/modules/bdg/channel_manager.py`

**Purpose:** Centralized channel management

**Features:**
- Store current channel state
- Switch channel for sta and espnow
- Restore original channel
- Random channel selection (2-13)
- Channel negotiation protocol

```python
class ChannelManager:
    def __init__(self, sta, espnow):
        self.sta = sta
        self.espnow = espnow
        self.default_channel = 1
        self.current_channel = 1
        self.game_channels = list(range(2, 14))  # Channels 2-13
    
    def get_random_game_channel(self):
        """Get a random channel for game (not default channel)"""
        import random
        return random.choice(self.game_channels)
    
    def switch_to_game_channel(self, channel):
        """Switch to specified game channel"""
        # Store current as backup
        self.previous_channel = self.current_channel
        
        # Switch WiFi interface
        self.sta.config(channel=channel)
        
        # ESP-NOW needs to be restarted on new channel
        self.espnow.active(False)
        self.espnow.active(True)
        
        self.current_channel = channel
        print(f"Switched to game channel {channel}")
    
    def restore_default_channel(self):
        """Switch back to default discovery channel"""
        if self.current_channel != self.default_channel:
            self.switch_to_game_channel(self.default_channel)
            print(f"Restored to default channel {self.default_channel}")
    
    def is_on_default_channel(self):
        return self.current_channel == self.default_channel
```

### 2. Connection Protocol Enhancement

**Location:** `/workspace/frozen_firmware/modules/bdg/msg/connection.py`

**Add channel negotiation to OpenConn message:**

```python
@BadgeMsg.register
class OpenConn(BadgeMsg):
    def __init__(self, con_id: int, accept: bool = True, game_channel: int = None):
        super().__init__()
        self.con_id: int = con_id
        self.accept: bool = accept
        self.game_channel: int = game_channel  # NEW: proposed game channel
```

**Negotiation flow:**
1. Badge A sends `OpenConn(con_id=X, game_channel=7)` on channel 1
2. Badge B receives and sends `OpenConn(con_id=X, accept=True, game_channel=7)` on channel 1
3. Both badges switch to channel 7
4. Game communication happens on channel 7
5. On `ConTerm`, both switch back to channel 1

### 3. Game Screen Integration

**Location:** `/workspace/frozen_firmware/modules/badge/games/tictac.py`

**Add channel lifecycle to TicTacToe:**

```python
class TicTacToe(Screen):
    def __init__(self, connection, channel_manager=None):
        super().__init__()
        self.connection = connection
        self.channel_manager = channel_manager
        # ... existing init code
    
    def after_open(self):
        # Switch to game channel when game starts
        if self.channel_manager and self.connection:
            game_channel = self.channel_manager.get_random_game_channel()
            # Negotiate channel through connection
            # ... channel negotiation logic
            self.channel_manager.switch_to_game_channel(game_channel)
        
        # ... existing after_open code
    
    def on_hide(self):
        # Restore default channel when leaving game
        if self.channel_manager:
            self.channel_manager.restore_default_channel()
        
        # ... existing on_hide code
```

---

## Detailed Implementation Steps

### Step 1: Create ChannelManager Module
**File:** `/workspace/frozen_firmware/modules/bdg/channel_manager.py`

- [ ] Create ChannelManager class
- [ ] Implement channel switching logic
- [ ] Handle ESP-NOW restart on channel change
- [ ] Add error handling for invalid channels

### Step 2: Update Message Protocol
**File:** `/workspace/frozen_firmware/modules/bdg/msg/__init__.py`

- [ ] Add `game_channel` field to `OpenConn` message
- [ ] Update serialization/deserialization to handle new field
- [ ] Ensure backward compatibility (game_channel optional)

### Step 3: Update Connection Class
**File:** `/workspace/frozen_firmware/modules/bdg/msg/connection.py`

- [ ] Add ChannelManager reference to Connection class
- [ ] Implement channel negotiation in `connect()` method
- [ ] Switch to game channel after connection established
- [ ] Restore channel in `terminate()` method

### Step 4: Update NowListener
**File:** `/workspace/frozen_firmware/modules/bdg/msg/connection.py`

- [ ] Add ChannelManager reference to NowListener
- [ ] Pass ChannelManager to Connection instances
- [ ] Handle channel switching during connection lifecycle

### Step 5: Update Main Initialization
**File:** `/workspace/frozen_firmware/modules/main.py`

- [ ] Create ChannelManager instance in `start_badge()`
- [ ] Pass ChannelManager to NowListener
- [ ] Pass ChannelManager to BootScr

```python
def start_badge():
    Config.load()
    channel = int(Config.config["espnow"]["ch"])
    
    ButtonEvents.init(BtnConfig)
    init_game_registry()
    
    sta = network.WLAN(network.STA_IF)
    sta.active(True)
    sta.config(channel=channel)
    sta.config(txpower=20)
    
    e = aioespnow.AIOESPNow()
    e.active(True)
    
    # NEW: Create ChannelManager
    from bdg.channel_manager import ChannelManager
    ch_mgr = ChannelManager(sta, e)
    
    quiet()
    
    Screen.change(BootScr, kwargs={
        "ready_cb": start_game, 
        "espnow": e, 
        "sta": sta,
        "channel_manager": ch_mgr  # NEW
    })
```

### Step 6: Update Game Screens
**File:** `/workspace/frozen_firmware/modules/badge/games/tictac.py`

- [ ] Accept `channel_manager` parameter in `__init__`
- [ ] Implement channel switching in `after_open()`
- [ ] Implement channel restoration in `on_hide()`
- [ ] Handle cases where ChannelManager is None (backward compatibility)

### Step 7: Update Game Registry
**File:** `/workspace/frozen_firmware/modules/bdg/game_registry.py`

- [ ] Pass ChannelManager to game screens when launching
- [ ] Update game configuration to include channel_manager in kwargs

---

## Channel Negotiation Protocol

### Simple Approach (Leader-Follower)
**Connection initiator (leader) decides channel:**

1. Badge A (initiator) selects random game channel (e.g., 7)
2. Badge A sends `OpenConn(con_id=2, game_channel=7)` on channel 1
3. Badge B (responder) receives and agrees
4. Badge B sends `OpenConn(con_id=2, accept=True, game_channel=7)` on channel 1
5. **Both badges switch to channel 7**
6. Game proceeds on channel 7
7. On game end, `ConTerm` sent on channel 7
8. **Both badges switch back to channel 1**

### Synchronization
**Critical timing issue:** Both badges must switch at the same time

**Solution:**
- Use a short delay after ACK before switching
- Initiator waits for response ACK before switching
- Both switch after ACK exchanged on channel 1

```python
# Badge A (initiator)
await send_open_conn(channel=7)
await wait_for_ack()
await asyncio.sleep(0.1)  # Brief sync delay
switch_to_channel(7)

# Badge B (responder)
receive_open_conn(channel=7)
await send_ack_with_channel(7)
await asyncio.sleep(0.1)  # Brief sync delay
switch_to_channel(7)
```

---

## Configuration

### Add to config.json
```json
{
  "espnow": {
    "ch": 1,
    "default_channel": 1,
    "game_channels": [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
  }
}
```

### Channel Selection Strategy
- **Random selection:** Simple, spreads load across channels
- **Collision possible:** Two pairs might select same channel (low probability with 12 options)
- **Conference scale:** With ~300 simultaneous games, ~25 pairs per channel average

---

## Edge Cases & Error Handling

### 1. Channel Switch Failure
**Problem:** ESP-NOW restart fails during channel switch

**Solution:**
```python
def switch_to_game_channel(self, channel):
    try:
        self.sta.config(channel=channel)
        self.espnow.active(False)
        self.espnow.active(True)
        self.current_channel = channel
    except Exception as e:
        print(f"Channel switch failed: {e}")
        # Stay on current channel, abort game start
        raise ChannelSwitchError()
```

### 2. Game Interrupted Mid-Play
**Problem:** Badge crashes or user exits game without proper cleanup

**Solution:**
- Implement channel timeout (auto-restore after 5 minutes)
- Use `try/finally` blocks in game screens
- Add channel check on boot (always restore to channel 1)

```python
def on_hide(self):
    try:
        # Game cleanup
        pass
    finally:
        # Always restore channel, even on error
        if self.channel_manager:
            self.channel_manager.restore_default_channel()
```

### 3. Connection Lost During Channel Switch
**Problem:** Badges switch at different times, lose connection

**Solution:**
- Implement retry mechanism with timeout
- If connection fails on game channel, both fall back to channel 1
- Add heartbeat/ping after channel switch to confirm connectivity

### 4. Badge Powered Off While on Game Channel
**Problem:** Badge turns off on channel 7, boots back up on channel 7

**Solution:**
- Always initialize to default channel on boot (main.py)
- Channel state is volatile (not persisted across reboots)

---

## Testing Strategy

### Unit Tests
- [ ] Test ChannelManager channel switching
- [ ] Test OpenConn message serialization with game_channel
- [ ] Test channel negotiation protocol

### Integration Tests
- [ ] Two badges connect and switch channels
- [ ] Play full TicTacToe game on game channel
- [ ] Verify channel restoration on game end
- [ ] Test game termination (graceful and forced)

### Stress Tests
- [ ] Rapid channel switching (start/quit multiple games)
- [ ] Multiple badge pairs on different channels
- [ ] Channel switching under poor signal conditions

### Conference Simulation
- [ ] 10+ badges all on channel 1 (discovery)
- [ ] Launch multiple games simultaneously (different channels)
- [ ] Verify reduced interference during gameplay
- [ ] Measure game connection reliability

---

## Performance Considerations

### Channel Switch Time
- ESP-NOW restart takes ~100-200ms
- Connection re-establishment: ~500ms total
- Acceptable overhead for improved reliability

### Memory Impact
- ChannelManager: ~100 bytes
- OpenConn message extension: +4 bytes per message
- Minimal memory overhead

### Battery Impact
- Channel switching itself: negligible
- Reduced interference = fewer retries = better battery life

---

## Rollout Plan

### Phase 1: Development (test.py)
- [ ] Implement ChannelManager in test environment
- [ ] Test with firmware directory mounted via mpremote
- [ ] Verify channel switching works correctly

### Phase 2: Integration
- [ ] Move ChannelManager to frozen_firmware
- [ ] Update Connection and NowListener classes
- [ ] Update TicTacToe game

### Phase 3: Testing
- [ ] Test with 2 badges (TicTacToe on different channel)
- [ ] Test with 5+ badges (some playing, some discovering)
- [ ] Measure improvement in game connection reliability

### Phase 4: Production
- [ ] Build and deploy firmware with channel switching
- [ ] Document channel behavior for game developers
- [ ] Add channel status to debug screen

---

## Alternative Approaches Considered

### Approach 1: Fixed Channel Assignment
**Idea:** Assign specific channels to specific game types
- TicTacToe = channel 2
- RPS = channel 3
- etc.

**Rejected:** All TicTacToe games would still interfere with each other

### Approach 2: No Channel Switching
**Idea:** Stay on channel 1, improve protocol reliability

**Rejected:** With 600 badges, channel 1 will be too congested for reliable gameplay

### Approach 3: Dynamic Channel Selection Based on Noise
**Idea:** Scan channels, pick quietest one

**Rejected:** Scanning takes time (~3 seconds), complex to implement

---

## Documentation Updates

### For Game Developers
**File:** `/workspace/docs/game_development.md`

Add section:
```markdown
## Multiplayer Games and Channel Switching

When developing multiplayer games, the badge automatically handles
channel switching to reduce interference:

1. Game screens receive `channel_manager` parameter
2. Channel switches automatically on game start
3. Restores default channel on game end

Your game must:
- Accept `channel_manager=None` in `__init__` (optional)
- Call `channel_manager.restore_default_channel()` in `on_hide()`
```

### For Users
**File:** `/workspace/docs/badge_api.md`

Add note about channel behavior during gameplay.

---

## Questions to Resolve

- [ ] Should channel negotiation use ACK-before-switch or delay-based sync?
- [ ] What timeout for channel restoration if game hangs?
- [ ] Should ChannelManager be singleton or instance?
- [ ] Do we need channel status display in UI?
- [ ] Should BeaconMsg continue on game channel or pause?
- [ ] How to handle 3+ player games (future)?

---

## Success Criteria

- [ ] Two badges can play TicTacToe on isolated channel
- [ ] Channel automatically restores to 1 after game
- [ ] No connection drops during channel switch
- [ ] Works reliably with 600 badges at conference
- [ ] Battery impact < 1%
- [ ] Channel switch time < 500ms

---

## Implementation Timeline

**Estimated effort:** 2-3 development days

- Day 1: ChannelManager + Protocol updates (4-6 hours)
- Day 2: Integration + TicTacToe update (4-6 hours)
- Day 3: Testing + Bug fixes (4-6 hours)
