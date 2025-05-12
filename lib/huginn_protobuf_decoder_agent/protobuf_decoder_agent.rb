# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

module Agents
  class ProtobufDecoderAgent < Agent
    include FormConfigurable

    default_schedule "never"
    can_dry_run!
    cannot_be_scheduled!

    description <<-MD
      The Protobuf Decoder agent decodes incoming base64-encoded Protobuf messages using specified proto file and message type.

      ### Options:
      `proto_file` - Full path to the .proto file (required)<br>
      `message_type` - Full name of the Protobuf message type (including package name, e.g. "meshtastic.ServiceEnvelope") (required)<br>
      `input_key` - Key in the payload containing the base64-encoded Protobuf message (default: 'payload')<br>
      `output_key` - Key where the decoded message will be stored in the output (default: 'decoded')

      ### Example:
      For Meshtastic MQTT messages:
      `proto_file`: "/path/to/meshtastic/mqtt.proto"<br>
      `message_type`: "meshtastic.ServiceEnvelope"<br>
      `input_key`: "payload"<br>
      `output_key`: "decoded"
    MD

    def default_options
      {
        'proto_file' => '/path/to/meshtastic/mqtt.proto',
        'message_type' => 'package.MessageType',
        'input_key' => 'payload',
        'output_key' => 'decoded'
      }
    end

    form_configurable :proto_file, type: :string
    form_configurable :message_type, type: :string
    form_configurable :input_key, type: :string
    form_configurable :output_key, type: :string

    def working?
      true
    end

    def validate_options
      errors.add(:base, 'proto_file is required') unless options['proto_file'].present?
      errors.add(:base, 'message_type is required') unless options['message_type'].present?
      errors.add(:base, 'input_key must be a string') unless options['input_key'].is_a?(String)
      errors.add(:base, 'output_key must be a string') unless options['output_key'].is_a?(String)

      if options['proto_file'].present? && !File.exist?(options['proto_file'])
        errors.add(:base, "proto_file '#{options['proto_file']}' does not exist")
      end
    end

    def receive(incoming_events)
      require 'google/protobuf'

      interpolate_with_each(incoming_events) do |event|
        proto_file = interpolated['proto_file']
        message_type = interpolated['message_type']
        input_key = interpolated['input_key'] || 'payload'
        output_key = interpolated['output_key'] || 'decoded'

        # Get the base64-encoded data from the event
        base64_data = event.payload[input_key]
        unless base64_data
          error("Input key '#{input_key}' not found in event payload")
          next
        end

        begin
          # Decode base64 to binary protobuf
          binary_data = Base64.decode64(base64_data)

          # Load protobuf definition and decode message
          decoded_message = decode_protobuf(binary_data, proto_file, message_type)

          # Create event with decoded message
          create_event payload: event.payload.merge(output_key => decoded_message)
        rescue => e
          error("Error decoding Protobuf message: #{e.message}\n#{e.backtrace.join("\n")}")
          next
        end
      end
    end

    private

    def decode_protobuf(binary_data, proto_file, message_type)
      # Load the proto file and build descriptor pool
      descriptor_pool = Google::Protobuf::DescriptorPool.new
      descriptor_pool.build_from_file(proto_file)

      # Get the message class
      message_class = descriptor_pool.lookup(message_type).msgclass

      # Decode the binary data
      message = message_class.decode(binary_data)

      # Convert to Ruby hash
      protobuf_to_hash(message)
    end

    def protobuf_to_hash(message)
      # Recursively convert protobuf message to hash
      result = {}
      message.to_h.each do |key, value|
        if value.is_a?(Google::Protobuf::Message)
          result[key] = protobuf_to_hash(value)
        elsif value.is_a?(Google::Protobuf::RepeatedField)
          result[key] = value.map { |v| v.is_a?(Google::Protobuf::Message) ? protobuf_to_hash(v) : v }
        else
          result[key] = value
        end
      end
      result
    end
  end
end
