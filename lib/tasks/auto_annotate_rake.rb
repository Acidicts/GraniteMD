if Rails.env.development?
  desc "Annotate models with the current database schema"
  task :annotate_models do
    system("bundle exec annotaterb models")
  end

  # Annotate after the migration has been applied so the annotations match the new schema.
  if Rake::Task.task_defined?("db:migrate")
    Rake::Task["db:migrate"].enhance do
      Rake::Task[:annotate_models].invoke
    end
  end
end
