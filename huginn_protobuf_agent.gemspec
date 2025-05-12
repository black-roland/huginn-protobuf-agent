# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "huginn_protobuf_agent"
  spec.version       = '1.0'
  spec.authors       = ["Black Roland"]
  spec.email         = ["mail@roland.black"]

  spec.summary       = %q{Huginn agent to decode Protobuf messages}
  spec.description   = %q{A Huginn agent that decodes base64-encoded Protobuf messages using specified proto files}
  spec.homepage      = "https://github.com/black-roland/huginn-protobuf-agent"
  spec.license       = "MPL-2.0"

  spec.files         = Dir['LICENSE', 'README.md', 'lib/**/*']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = Dir['spec/**/*.rb'].reject { |f| f[%r{^spec/huginn}] }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 2.1.0"
  spec.add_development_dependency "rake", "~> 12.3.3"

  spec.add_runtime_dependency "huginn_agent"
  spec.add_runtime_dependency "google-protobuf", "~> 4.30"
  spec.add_runtime_dependency "base64", "~> 0.2"
end
