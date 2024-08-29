# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Settings, feature_category: :importers do
  subject(:settings) { described_class.new(project) }

  let_it_be(:project) { create(:project) }

  let(:optional_stages) do
    {
      single_endpoint_issue_events_import: true,
      single_endpoint_notes_import: false,
      attachments_import: false,
      collaborators_import: false
    }
  end

  describe '.stages_array' do
    let(:expected_list) do
      stages = described_class::OPTIONAL_STAGES
      [
        {
          name: 'single_endpoint_notes_import',
          label: stages[:single_endpoint_notes_import][:label],
          selected: false,
          details: stages[:single_endpoint_notes_import][:details]
        },
        {
          name: 'attachments_import',
          label: stages[:attachments_import][:label].strip,
          selected: false,
          details: stages[:attachments_import][:details]
        },
        {
          name: 'collaborators_import',
          label: stages[:collaborators_import][:label].strip,
          selected: true,
          details: stages[:collaborators_import][:details]
        }
      ]
    end

    it 'returns stages list as array' do
      expect(described_class.stages_array(project.owner)).to match_array(expected_list)
    end

    context 'when `github_import_extended_events` feature flag is disabled' do
      let(:expected_list_with_deprecated_options) do
        stages = described_class::OPTIONAL_STAGES

        expected_list.concat(
          [
            {
              name: 'single_endpoint_issue_events_import',
              label: stages[:single_endpoint_issue_events_import][:label],
              selected: false,
              details: stages[:single_endpoint_issue_events_import][:details]
            }
          ])
      end

      before do
        stub_feature_flags(github_import_extended_events: false)
      end

      it 'returns stages list as array' do
        expect(described_class.stages_array(project.owner)).to match_array(expected_list_with_deprecated_options)
      end
    end
  end

  describe '#write' do
    let(:data_input) do
      {
        optional_stages: {
          single_endpoint_issue_events_import: true,
          single_endpoint_notes_import: 'false',
          attachments_import: nil,
          collaborators_import: false,
          foo: :bar
        },
        timeout_strategy: "optimistic"
      }.stringify_keys
    end

    it 'puts optional steps and timeout strategy into projects import_data' do
      project.build_or_assign_import_data(credentials: { user: 'token' })

      settings.write(data_input)

      expect(project.import_data.data['optional_stages'])
        .to eq optional_stages.stringify_keys
      expect(project.import_data.data['timeout_strategy'])
        .to eq("optimistic")
    end
  end

  describe '#enabled?' do
    it 'returns is enabled or not specific optional stage' do
      project.build_or_assign_import_data(data: { optional_stages: optional_stages })

      expect(settings.enabled?(:single_endpoint_issue_events_import)).to eq true
      expect(settings.enabled?(:single_endpoint_notes_import)).to eq false
      expect(settings.enabled?(:attachments_import)).to eq false
      expect(settings.enabled?(:collaborators_import)).to eq false
    end
  end

  describe '#disabled?' do
    it 'returns is disabled or not specific optional stage' do
      project.build_or_assign_import_data(data: { optional_stages: optional_stages })

      expect(settings.disabled?(:single_endpoint_issue_events_import)).to eq false
      expect(settings.disabled?(:single_endpoint_notes_import)).to eq true
      expect(settings.disabled?(:attachments_import)).to eq true
      expect(settings.disabled?(:collaborators_import)).to eq true
    end
  end

  describe '#extended_events?' do
    it 'when extended_events is set to true' do
      project.build_or_assign_import_data(data: { extended_events: true })

      expect(settings.extended_events?).to eq(true)
    end

    it 'when extended_events is set to false' do
      project.build_or_assign_import_data(data: { extended_events: false })

      expect(settings.extended_events?).to eq(false)
    end

    it 'when extended_events is not present' do
      project.build_or_assign_import_data(data: {})

      expect(settings.extended_events?).to eq(false)
    end
  end
end
