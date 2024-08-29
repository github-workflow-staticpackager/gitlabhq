# frozen_string_literal: true

require 'spec_helper'
require 'request_store'

RSpec.describe 'getting Work Item counts by state', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:work_item_opened1) { create(:work_item, namespace: group) }
  let_it_be(:work_item_opened2) { create(:work_item, namespace: group, author: current_user) }
  let_it_be(:work_item_closed1) { create(:work_item, :closed, namespace: group) }
  let_it_be(:work_item_closed2) { create(:work_item, :closed, namespace: group) }

  let(:params) { {} }

  subject(:query_counts) { post_graphql(query, current_user: current_user) }

  context 'with work items count data' do
    let(:work_item_counts) { graphql_data.dig('group', 'workItemStateCounts') }

    context 'with group permissions' do
      before_all do
        group.add_developer(current_user)
      end

      it_behaves_like 'a working graphql query' do
        before do
          query_counts
        end
      end

      it 'returns the correct counts for each state' do
        query_counts

        expect(work_item_counts).to eq(
          'all' => 4,
          'opened' => 2,
          'closed' => 2
        )
      end

      context 'when filters are provided' do
        context 'when filtering by author username' do
          let(:params) { { 'authorUsername' => current_user.username } }

          it 'returns the correct counts for each state' do
            query_counts

            expect(work_item_counts).to eq(
              'all' => 1,
              'opened' => 1,
              'closed' => 0
            )
          end
        end

        context 'when filtering by search' do
          let(:params) { { search: 'foo', in: [:TITLE] } }

          it 'returns an error for filters that are not supported' do
            query_counts

            expect(graphql_errors).to contain_exactly(
              hash_including('message' => 'Searching is not available for work items at the namespace level yet')
            )
          end
        end
      end

      context 'when the namespace_level_work_items feature flag is disabled' do
        before do
          stub_feature_flags(namespace_level_work_items: false)
        end

        it 'does not return work item counts' do
          query_counts

          expect_graphql_errors_to_be_empty
          expect(work_item_counts).to be_nil
        end
      end
    end

    context 'without group permissions' do
      it 'does not return work item counts' do
        query_counts

        expect_graphql_errors_to_be_empty
        expect(work_item_counts).to be_nil
      end
    end
  end

  def query(args: params)
    fields = <<~QUERY
      #{all_graphql_fields_for('WorkItemStateCountsType'.classify)}
    QUERY

    graphql_query_for(
      'group',
      { 'fullPath' => group.full_path },
      query_graphql_field('workItemStateCounts', args, fields)
    )
  end
end
