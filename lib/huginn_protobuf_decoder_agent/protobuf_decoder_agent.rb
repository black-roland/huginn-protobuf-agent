# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

require 'google/protobuf'
require 'base64'

module Agents
  class ProtobufDecoderAgent < Agent
    default_schedule "never"
    can_dry_run!
    cannot_be_scheduled!

    description <<-MD
      The Protobuf Decoder Agent decodes a base64-encoded binary Protobuf payload using a specified proto file.

      ### Options

      `source_key`: The key in the incoming payload containing the base64-encoded Protobuf data (required, supports Liquid templating).<br>
      `proto_file`: The path to the `.proto` file (e.g., `/var/lib/huginn/meshtastic/protobufs/meshtastic/mqtt.proto`) (required).<br>
      `message_type`: The fully-qualified Protobuf message type (e.g., `meshtastic.ServiceEnvelope`) to deserialize the payload (required).<br>
      `output_key`: The key in the output payload where the decoded data will be stored (default: `decoded`).

      ### Example:

      For Meshtastic MQTT messages:

      `proto_file`: "/var/lib/huginn/meshtastic/protobufs/meshtastic/mqtt.proto"<br>
      `message_type`: "meshtastic.ServiceEnvelope"<br>
      `source_key`: "payload"<br>
      `output_key`: "decoded"
    MD

    def default_options
      {
        'source_key' => 'payload',
        'proto_file' => '/var/lib/huginn/meshtastic/protobufs/meshtastic/mqtt.proto',
        'message_type' => 'meshtastic.ServiceEnvelope',
        'output_key' => 'decoded'
      }
    end

    def working?
      true
    end

    def validate_options
      errors.add(:base, 'source_key is missing') unless options['source_key'].present?
      errors.add(:base, 'source_key must be a string') unless options['source_key'].is_a?(String)
      errors.add(:base, 'proto_file is missing') unless options['proto_file'].present?
      errors.add(:base, 'proto_file must be a string') unless options['proto_file'].is_a?(String)
      errors.add(:base, 'message_type is missing') unless options['message_type'].present?
      errors.add(:base, 'message_type must be a string') unless options['message_type'].is_a?(String)
      errors.add(:base, 'output_key must be a string') unless options['output_key'].is_a?(String)

      # Validate proto_file existence
      if options['proto_file'].present? && !File.exist?(options['proto_file'])
        errors.add(:base, "Proto file '#{options['proto_file']}' does not exist")
      end
    end

    def receive(incoming_events)
      interpolate_with_each(incoming_events) do |event|
        begin
          # Extract options
          source_key = interpolated['source_key']
          proto_file = interpolated['proto_file']
          message_type = interpolated['message_type']
          output_key = interpolated['output_key'] || 'decoded'

          # Get base64-encoded data
          base64_data = event.payload[source_key]
          unless base64_data.is_a?(String)
            log "Invalid data for key '#{source_key}': expected a base64 string"
            next
          end

          # Decode base64
          begin
            binary_data = Base64.decode64(base64_data)
          rescue ArgumentError => e
            log "Failed to decode base64 data: #{e.message}"
            next
          end

          # Load proto file
          load_proto_file(proto_file)

          # Resolve the message class
          message_class = resolve_message_class(message_type)
          unless message_class
            log "Failed to resolve Protobuf message type: #{message_type}"
            next
          end

          # Deserialize the Protobuf message
          decoded_message = message_class.decode(binary_data)

          # Convert to hash for output
          decoded_hash = decoded_message.to_h

          # Create output event
          create_event payload: event.payload.merge({ output_key => decoded_hash })
        rescue StandardError => e
          log "Error processing event: #{e.message}"
          next
        end
      end
    end

    private

    def load_proto_file(proto_file)
      unless File.exist?(proto_file)
        raise "Proto file '#{proto_file}' does not exist"
      end

      # Get the directory for resolving imports
      proto_dir = File.dirname(proto_file)

      # Read the proto file content
      proto_content = File.read(proto_file)

      # Create a descriptor pool
      pool = Google::Protobuf::DescriptorPool.new

      # Define an importer to handle imported proto files
      importer = proc do |filename|
        import_path = File.join(proto_dir, filename)
        unless File.exist?(import_path)
          raise "Imported proto file '#{filename}' not found in '#{proto_dir}'"
        end
        File.read(import_path)
      end

      # Add the proto file to the pool
      pool.add_file(
        proto_file,
        syntax: :proto3,
        importer: importer
      )

      pool
    rescue StandardError => e
      raise "Failed to load proto file '#{proto_file}': #{e.message}"
    end

    def resolve_message_class(message_type)
      descriptor = Google::Protobuf::DescriptorPool.generated_pool.lookup(message_type)
      descriptor.msgclass if descriptor
    rescue NameError => e
      log "Failed to resolve message type '#{message_type}': #{e.message}"
      nil
    end
  end
end
