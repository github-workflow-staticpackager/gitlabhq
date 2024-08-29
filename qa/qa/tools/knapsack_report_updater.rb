# frozen_string_literal: true

module QA
  module Tools
    class KnapsackReportUpdater
      include Support::API
      include Ci::Helpers

      GITLAB_PROJECT_ID = 278964
      UPDATE_BRANCH_NAME = "qa-knapsack-master-report-update"

      def self.run
        new.update_master_report
      end

      # Create master_report.json merge request
      #
      # @return [void]
      def update_master_report
        create_branch
        create_commit
        create_mr
      end

      private

      # Gitlab access token
      #
      # @return [String]
      def gitlab_access_token
        @gitlab_access_token ||= ENV["GITLAB_ACCESS_TOKEN"] || raise("Missing GITLAB_ACCESS_TOKEN env variable")
      end

      # Gitlab api url
      #
      # @return [String]
      def gitlab_api_url
        @gitlab_api_url ||= ENV["CI_API_V4_URL"] || raise("Missing CI_API_V4_URL env variable")
      end

      # Create branch for knapsack report update
      #
      # @return [void]
      def create_branch
        logger.info("Creating branch '#{UPDATE_BRANCH_NAME}' branch")
        api_post("repository/branches", {
          branch: UPDATE_BRANCH_NAME,
          ref: "master"
        })
      end

      # Create update commit for knapsack report
      #
      # @return [void]
      def create_commit
        logger.info("Creating master_report.json update commit")
        api_post("repository/commits", {
          branch: UPDATE_BRANCH_NAME,
          commit_message: "Update master_report.json for E2E tests",
          actions: [
            {
              action: "update",
              file_path: "qa/knapsack/master_report.json",
              content: JSON.pretty_generate(Support::KnapsackReport.merged_report.sort.to_h)
            }
          ]
        })
      end

      # Create merge request with updated knapsack master report
      #
      # @return [void]
      def create_mr
        logger.info("Creating merge request")
        resp = api_post("merge_requests", {
          source_branch: UPDATE_BRANCH_NAME,
          target_branch: "master",
          title: "Update master_report.json for E2E tests",
          remove_source_branch: true,
          squash: true,
          labels: "Quality,team::Test and Tools Infrastructure,type::maintenance,maintenance::pipelines",
          description: <<~DESCRIPTION
            Update fallback knapsack report with latest spec runtime data.

            @gl-quality/qe-maintainers please review and merge.
          DESCRIPTION
        })

        logger.info("Merge request created: #{resp[:web_url]}")
      end

      # Api update request
      #
      # @param [String] path
      # @param [Hash] payload
      # @return [Hash, Array]
      def api_post(path, payload)
        response = post("#{gitlab_api_url}/projects/#{GITLAB_PROJECT_ID}/#{path}", payload, {
          headers: { "PRIVATE-TOKEN" => gitlab_access_token }
        })
        raise "Api request to #{path} failed! Body: #{response.body}" unless success?(response.code)

        parse_body(response)
      end
    end
  end
end
