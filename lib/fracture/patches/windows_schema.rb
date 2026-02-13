# frozen_string_literal: true

# Monkey-patch to skip MCP::Tool::Schema#validate_schema! on Windows.
#
# The json-schema gem's file URI handling is fundamentally broken on Windows:
#   - Addressable::URI.parse("C:/path") treats "C" as the URI scheme
#   - File path resolution produces mangled paths like "C:/c:"
#   - The validator tries to JSON-parse file URIs instead of reading them
#
# Schema validation is a development-time safety net; the MCP protocol
# performs its own validation at runtime. Skipping it on Windows is safe.
return unless Gem.win_platform?

module MCP
  class Tool
    class Schema
      private

      def validate_schema!
        # no-op on Windows due to json-schema gem path handling bugs
      end
    end
  end
end
