# frozen_string_literal: true

class AddFkForAutoCanceledByIdBigintBetweenPCiBuildsAndCiPipelines < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.9'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_builds
  TARGET_TABLE_NAME = :ci_pipelines
  COLUMN = :auto_canceled_by_id_convert_to_bigint
  TARGET_COLUMN = :id
  FK_NAME = :fk_dd3c83bdee

  def up
    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME, TARGET_TABLE_NAME,
      column: [COLUMN],
      target_column: [TARGET_COLUMN],
      validate: false,
      reverse_lock_order: true,
      on_delete: :nullify,
      name: FK_NAME
    )

    prepare_partitioned_async_foreign_key_validation(
      SOURCE_TABLE_NAME, [COLUMN],
      name: FK_NAME
    )
  end

  def down
    unprepare_partitioned_async_foreign_key_validation(
      SOURCE_TABLE_NAME, [COLUMN],
      name: FK_NAME
    )

    Gitlab::Database::PostgresPartitionedTable.each_partition(SOURCE_TABLE_NAME) do |partition|
      with_lock_retries do
        remove_foreign_key_if_exists(
          partition.identifier, TARGET_TABLE_NAME,
          name: FK_NAME,
          reverse_lock_order: true
        )
      end
    end

    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE_NAME, TARGET_TABLE_NAME,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end
  end
end
