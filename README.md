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

| Tool | Description | Arguments |
|------|-------------|-----------|
| `get_guilds` | Lists all Discord guilds (servers) the bot is a member of. Returns each guild's ID and name. | None |

## Development

```bash
# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop
```

## License

MIT
