
samples = %w(Ruby Java Python Go)
samples.each do |sample|
  Category.create(name: sample)
end