require_relative 'spec_helper'
require 'json'
require 'uri'

describe host(URI(external_url).host) do
  it 'is defined', precheck: true do
    expect(subject.name).not_to be_nil, "Please define an external_url"
  end

  it 'is a resolvable external_url', precheck: true do
    expect(subject).to be_resolvable.by('dns'), %(External url "#{subject.name}" is not resolvable by the local resolver)
  end
end
