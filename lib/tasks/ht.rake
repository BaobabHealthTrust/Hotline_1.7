namespace :ht do
  desc "ht create"

  task create: :environment do
  	puts 'creating'
  end

  desc "ht migrate"
  
  task migrate: :environment do
  	puts 'migrating'
  end

  desc "ht seed"
  
  task seed: :environment do
  	puts 'initialising data'
  end

end
