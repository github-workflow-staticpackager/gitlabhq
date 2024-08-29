# frozen_string_literal: true

class AddPartitioningConstraintForCiJobArtifacts2 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '16.9'
  disable_ddl_transaction!
  TABLE_NAME = :ci_job_artifacts
  PARENT_TABLE_NAME = :p_ci_job_artifacts
  FIRST_PARTITION = [100, 101]
  PARTITION_COLUMN = :partition_id

  def up
    prepare_constraint_for_list_partitioning(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end

  def down
    revert_preparing_constraint_for_list_partitioning(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end
end
