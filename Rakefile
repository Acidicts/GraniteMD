# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

Rails.application.load_tasks

# Rails only auto-loads lib/tasks ending in .rake, so require the .rb task file here.
require_relative "lib/tasks/auto_annotate_rake"
