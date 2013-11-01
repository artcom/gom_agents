guard :rspec, all_on_start: true do
  watch('spec/spec_helper.rb')  { "spec" }
  watch(%r{^spec\/.+_spec\.rb$})
  
  # watch(%r{^lib\/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  
  # watch(%r{^lib\/([a-zA-Z_]+)\.rb$}) { |m|
  #   Dir["spec/**/#{m[1]}*_spec.rb"]
  # }
  
  watch(%r{^lib\/gom_agents\/(.+)\.rb$}) { |m|
    Dir[
      #{}"spec/**/#{m[1]}_*_spec.rb",
      "spec/**/#{m[1]}*_spec.rb"
    ]#.uniq
  }
end

guard :rubocop, all_on_start: true do
  watch(%r{.+\.rb$})
  watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
end

guard 'bundler' do
  watch('Gemfile')
  # Uncomment next line if Gemfile contain `gemspec' command
  # watch(/^.+\.gemspec/)
end
