require 'spec_helper'

describe Conflux do

  it 'has a version number' do
  expect(Conflux::VERSION).not_to be nil
  end

  it 'has a generator' do
    generator = Conflux::Generators::ConfluxGenerator.new
    expect(generator).not_to be nil
  end

end
