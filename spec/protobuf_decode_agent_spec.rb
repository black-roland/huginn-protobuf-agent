# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::ProtobufDecodeAgent do
  before(:each) do
    @valid_options = Agents::ProtobufDecodeAgent.new.default_options
    @checker = Agents::ProtobufDecodeAgent.new(:name => "ProtobufDecodeAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
