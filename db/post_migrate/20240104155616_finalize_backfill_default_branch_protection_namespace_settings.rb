# frozen_string_literal: true

class FinalizeBackfillDefaultBranchProtectionNamespaceSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillBranchProtectionNamespaceSetting'

  milestone '16.8'
  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :namespace_settings,
      column_name: :namespace_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # noop
  end
end
