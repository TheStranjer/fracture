# frozen_string_literal: true

RSpec.describe Fracture::Tools::Permissions do
  describe '.bits_to_array' do
    it 'converts a bits value to an array of permission names' do
      result = described_class.bits_to_array(0x00000006)
      expect(result).to contain_exactly('kick_members', 'ban_members')
    end

    it 'returns an empty array for zero' do
      expect(described_class.bits_to_array(0)).to eq([])
    end

    it 'decodes all permissions from full bits' do
      all_bits = (0..30).sum { |bit| 1 << bit }
      result = described_class.bits_to_array(all_bits)
      expect(result.length).to eq(31)
      expect(result).to include('administrator', 'send_messages', 'manage_roles')
    end

    it 'decodes a complex permission set' do
      bits = (1 << 10) | (1 << 11) | (1 << 14) | (1 << 16)
      result = described_class.bits_to_array(bits)
      expect(result).to contain_exactly('read_messages', 'send_messages', 'embed_links', 'read_message_history')
    end
  end

  describe '.array_to_bits' do
    it 'converts an array of permission names to a bits value' do
      result = described_class.array_to_bits(%w[kick_members ban_members])
      expect(result).to eq(0x00000006)
    end

    it 'returns zero for an empty array' do
      expect(described_class.array_to_bits([])).to eq(0)
    end

    it 'ignores unknown permission names' do
      result = described_class.array_to_bits(%w[kick_members fake_permission])
      expect(result).to eq(2)
    end

    it 'round-trips with bits_to_array' do
      original = %w[send_messages read_messages manage_roles]
      bits = described_class.array_to_bits(original)
      result = described_class.bits_to_array(bits)
      expect(result).to match_array(original)
    end
  end
end
