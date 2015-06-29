namespace :yata do
  desc "gets all the languages translations"
  task :fetch_translations do
    get_translations
  end
end
