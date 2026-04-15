# frozen_string_literal: true

class DropGoodJobTables < ActiveRecord::Migration[8.1]
  def up
    %w[good_job_executions good_jobs good_job_batches
       good_job_processes good_job_settings].each do |t|
      drop_table t, if_exists: true
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
