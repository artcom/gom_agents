RSpec::Matchers.define :be_one_of do |*elements|
  match do |container|
    elements.include? container
  end

  failure_message_for_should do |container|
    "Expected '#{container}' to be one of #{elements}."
  end
end
