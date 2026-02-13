# Fracture

An MCP (Model Context Protocol) server that provides Discord tools. Built with the [MCP Ruby SDK](https://github.com/modelcontextprotocol/ruby-sdk) and [discordrb](https://github.com/shardlab/discordrb).

## Requirements

- Ruby 4.0+
- A Discord bot token ([create one here](https://discord.com/developers/applications))

## Installation

```bash
git clone https://github.com/yourusername/fracture.git
cd fracture
bundle install
```

## Configuration

Set your Discord bot token as an environment variable:

```bash
export DISCORD_BOT_TOKEN=your_token_here
```

### Claude Desktop

Add to your Claude Desktop MCP config (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "fracture": {
      "command": "ruby",
      "args": ["/path/to/fracture/fracture.rb"],
      "env": {
        "DISCORD_BOT_TOKEN": "your_token_here"
      }
    }
  }
}
```

On Windows, you may also need to set `DISCORDRB_NONACL=1` in the `env` block.

## Usage

Run the server directly over stdio:

```bash
ruby fracture.rb
```

The server communicates via stdin/stdout using the MCP JSON-RPC protocol.

## Tools

### Guilds

| Tool | Description | Arguments |
|------|-------------|-----------|
| `get_guilds` | Lists all guilds (servers) the bot is a member of. Returns each guild's ID and name. | None |
| `get_guild` | Gets detailed information about a specific guild, including its categories, channels, and members. For guilds with fewer than 100 members, full member details are returned; otherwise only the member count is included. | `guild_id` (string, required) |
| `get_guild_members` | Lists all members of a guild. Reserved for large servers with more than 100 members. Returns each member's ID, username, and display name. | `guild_id` (string, required) |

### Bans

| Tool | Description | Arguments |
|------|-------------|-----------|
| `ban_user` | Bans a user from a guild. | `guild_id` (string, required), `user_id` (string, required), `reason` (string, required) |
| `unban_user` | Unbans a user from a guild. | `guild_id` (string, required), `user_id` (string, required), `reason` (string, required) |
| `get_guild_bans` | Lists all bans for a guild. Returns each ban's user ID and reason. | `guild_id` (string, required) |

### Members

| Tool | Description | Arguments |
|------|-------------|-----------|
| `get_member` | Gets detailed information about a guild member, including their roles, status, join date, voice state, and more. | `guild_id` (string, required), `member_id` (string, required) |
| `add_role` | Adds a role to a guild member. | `guild_id` (string, required), `member_id` (string, required), `role_id` (string, required) |
| `remove_role` | Removes a role from a guild member. | `guild_id` (string, required), `member_id` (string, required), `role_id` (string, required) |

### Messages

| Tool | Description | Arguments |
|------|-------------|-----------|
| `send_message` | Sends a message to a channel or user via DM. Specify either `guild_id` + `channel_id` for a channel message, or `user_id` for a DM. At least one of `content` or `attachments` must be provided. | `guild_id` (string, optional), `channel_id` (string, optional), `user_id` (string, optional), `content` (string, optional), `attachments` (string[], optional) |
| `edit_message` | Edits an existing message in a channel or DM. | `message_id` (string, required), `content` (string, required), `guild_id` (string, optional), `channel_id` (string, optional), `user_id` (string, optional) |
| `delete_message` | Deletes a message from a channel or DM. | `message_id` (string, required), `guild_id` (string, optional), `channel_id` (string, optional), `user_id` (string, optional) |

### Roles

| Tool | Description | Arguments |
|------|-------------|-----------|
| `get_guild_roles` | Gets all roles for a guild, including decoded permissions for each role. | `guild_id` (string, required) |
| `create_role` | Creates a new role in a guild. | `guild_id` (string, required), `name` (string, required), `colour` (integer, optional), `hoist` (boolean, optional), `mentionable` (boolean, optional), `permissions` (string[], optional) |
| `delete_role` | Deletes a role from a guild. | `guild_id` (string, required), `role_id` (string, required) |

### Categories

| Tool | Description | Arguments |
|------|-------------|-----------|
| `get_categories` | Gets all categories for a guild, including their channels and permission overwrites. | `guild_id` (string, required) |
| `create_category` | Creates a new category in a guild. | `guild_id` (string, required), `name` (string, required), `position` (integer, required) |
| `edit_category` | Edits a category's name and/or position. At least one of `name` or `position` should be provided. | `guild_id` (string, required), `category_id` (string, required), `name` (string, optional), `position` (integer, optional) |
| `delete_category` | Deletes a category from a guild. | `guild_id` (string, required), `category_id` (string, required) |

### Channels

| Tool | Description | Arguments |
|------|-------------|-----------|
| `create_channel` | Creates a new text channel in a guild, optionally under a category. | `guild_id` (string, required), `name` (string, required), `category_id` (string, optional) |
| `rename_channel` | Renames a channel in a guild. | `guild_id` (string, required), `channel_id` (string, required), `name` (string, required) |
| `delete_channel` | Deletes a channel from a guild. | `guild_id` (string, required), `channel_id` (string, required) |

### Permissions

| Tool | Description | Arguments |
|------|-------------|-----------|
| `define_overwrite` | Defines a permission overwrite for a role or user on a channel or category. The `type` determines the target: `role`, `channel`, `category`, or `user`. The `target_id` is the complementary target (e.g., if type is `role`, target_id is the channel or category). | `guild_id` (string, required), `type` (string, required — one of `role`, `channel`, `category`, `user`), `id` (string, required), `target_id` (string, required), `allowed` (string[], required), `denied` (string[], required), `reason` (string, required) |

#### Available Permissions

`create_instant_invite`, `kick_members`, `ban_members`, `administrator`, `manage_channels`, `manage_server`, `add_reactions`, `view_audit_log`, `priority_speaker`, `stream`, `read_messages`, `send_messages`, `send_tts_messages`, `manage_messages`, `embed_links`, `attach_files`, `read_message_history`, `mention_everyone`, `use_external_emoji`, `view_server_insights`, `connect`, `speak`, `mute_members`, `deafen_members`, `move_members`, `use_voice_activity`, `change_nickname`, `manage_nicknames`, `manage_roles`, `manage_webhooks`, `manage_emojis`

## Development

```bash
# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop
```

## License

MIT
