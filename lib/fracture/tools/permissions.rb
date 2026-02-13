# frozen_string_literal: true

module Fracture
  module Tools
    module Permissions
      PERMISSION_BITS = {
        0 => :create_instant_invite,
        1 => :kick_members,
        2 => :ban_members,
        3 => :administrator,
        4 => :manage_channels,
        5 => :manage_server,
        6 => :add_reactions,
        7 => :view_audit_log,
        8 => :priority_speaker,
        9 => :stream,
        10 => :read_messages,
        11 => :send_messages,
        12 => :send_tts_messages,
        13 => :manage_messages,
        14 => :embed_links,
        15 => :attach_files,
        16 => :read_message_history,
        17 => :mention_everyone,
        18 => :use_external_emoji,
        19 => :view_server_insights,
        20 => :connect,
        21 => :speak,
        22 => :mute_members,
        23 => :deafen_members,
        24 => :move_members,
        25 => :use_voice_activity,
        26 => :change_nickname,
        27 => :manage_nicknames,
        28 => :manage_roles,
        29 => :manage_webhooks,
        30 => :manage_emojis
      }.freeze

      def self.bits_to_array(bits_value)
        PERMISSION_BITS.each_with_object([]) do |(bit, name), arr|
          arr << name.to_s if (bits_value >> bit) & 1 == 1
        end
      end

      def self.array_to_bits(permissions_array)
        permissions_array.sum do |name|
          bit = PERMISSION_BITS.key(name.to_sym)
          bit ? (1 << bit) : 0
        end
      end
    end
  end
end
