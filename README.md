# Huginn Protobuf Agent

A Huginn agent that decodes base64-encoded Protobuf messages using specified proto files.

## Installation

Add this string to your Huginn's `.env` `ADDITIONAL_GEMS` configuration:

```ruby
huginn_protobuf_agent(github: black-roland/huginn-protobuf-agent)
```

Then execute:

```bash
bundle
```

## Usage

### Configuration

1. Add the Protobuf Decoder Agent to your Huginn scenario
2. Set the `proto_file` option to the full path of your .proto file
3. Specify the `message_type` (including package name)
4. Configure input/output keys as needed

### Example

For Meshtastic MQTT messages:
- `proto_file`: "/path/to/meshtastic/mqtt.proto"
- `message_type`: "meshtastic.ServiceEnvelope"
- `input_key`: "payload"
- `output_key`: "decoded_message"

Input payload:
```json
{
  "payload": "Cgl0ZXN0IGRhdGE="
}
```

Output:
```json
{
  "payload": "Cgl0ZXN0IGRhdGE=",
  "decoded": {
    "field1": "value1",
    "field2": 123
  }
}
```

## Development

To set up development environment:

```bash
bundle install
```

Running `rake` will clone and set up Huginn in `spec/huginn` to run the specs.

To modify the Huginn repository and branch used for testing, edit the `Rakefile`:

```ruby
HuginnAgent.load_tasks(branch: 'master', remote: 'https://github.com/huginn/huginn.git')
```

After setup, run tests with:

```bash
rake spec
```

To install this gem locally:

```bash
bundle exec rake install
```

## Contributing

1. Fork the project (https://github.com/black-roland/huginn-protobuf-agent/fork)
2. Create your feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Create a new Pull Request
