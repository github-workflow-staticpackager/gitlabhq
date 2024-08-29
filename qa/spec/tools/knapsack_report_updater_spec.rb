# frozen_string_literal: true

RSpec.describe QA::Tools::KnapsackReportUpdater do
  include QA::Support::Helpers::StubEnv

  let(:http_response) { instance_double("HTTPResponse", code: 200, body: {}.to_json) }
  let(:logger) { instance_double("Logger", info: nil) }
  let(:merged_report) { { spec_file: 0.0 } }
  let(:branch) { "qa-knapsack-master-report-update" }

  def request_args(path, payload)
    {
      method: :post,
      url: "https://gitlab.com/api/v4/projects/278964/#{path}",
      payload: payload,
      verify_ssl: false,
      headers: { "PRIVATE-TOKEN" => "token" }
    }
  end

  before do
    allow(RestClient::Request).to receive(:execute).and_return(http_response)
    allow(QA::Support::KnapsackReport).to receive(:merged_report).and_return(merged_report)
    allow(Gitlab::QA::TestLogger).to receive(:logger).and_return(logger)

    stub_env("CI_API_V4_URL", "https://gitlab.com/api/v4")
    stub_env("GITLAB_ACCESS_TOKEN", "token")
  end

  it "creates master report merge request", :aggregate_failures do
    described_class.run

    expect(RestClient::Request).to have_received(:execute).with(request_args("repository/branches", {
      branch: branch,
      ref: "master"
    }))
    expect(RestClient::Request).to have_received(:execute).with(request_args("repository/commits", {
      branch: branch,
      commit_message: "Update master_report.json for E2E tests",
      actions: [
        {
          action: "update",
          file_path: "qa/knapsack/master_report.json",
          content: JSON.pretty_generate(merged_report)
        }
      ]
    }))
    expect(RestClient::Request).to have_received(:execute).with(request_args("merge_requests", {
      source_branch: branch,
      target_branch: "master",
      title: "Update master_report.json for E2E tests",
      remove_source_branch: true,
      squash: true,
      labels: "Quality,team::Test and Tools Infrastructure,type::maintenance,maintenance::pipelines",
      description: <<~DESCRIPTION
        Update fallback knapsack report with latest spec runtime data.

        @gl-quality/qe-maintainers please review and merge.
      DESCRIPTION
    }))
  end
end
