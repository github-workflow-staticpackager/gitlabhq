# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportIssueEventsWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  let!(:group) { create(:group, projects: [project]) }
  let(:settings) { ::Gitlab::GithubImport::Settings.new(project.reload) }
  let(:stage_enabled) { true }
  let(:extended_events) { false }

  subject(:worker) { described_class.new }

  before do
    settings.write({
      optional_stages: { single_endpoint_issue_events_import: stage_enabled }, extended_events: extended_events
    })
  end

  it_behaves_like Gitlab::GithubImport::StageMethods

  describe '#import' do
    let(:importer) { instance_double('Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter') }
    let(:client) { instance_double('Gitlab::GithubImport::Client') }

    context 'when stage is enabled' do
      it 'imports issue events' do
        waiter = Gitlab::JobWaiter.new(2, '123')

        expect(Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter)
          .to receive(:new)
          .with(project, client)
          .and_return(importer)

        expect(importer).to receive(:execute).and_return(waiter)

        expect(Gitlab::GithubImport::AdvanceStageWorker)
          .to receive(:perform_async)
          .with(project.id, { '123' => 2 }, 'notes')

        worker.import(client, project)
      end
    end

    context 'when stage is disabled' do
      let(:stage_enabled) { false }

      it 'skips issue events import and calls next stage' do
        expect(Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter).not_to receive(:new)
        expect(Gitlab::GithubImport::AdvanceStageWorker).to receive(:perform_async).with(project.id, {}, 'notes')

        worker.import(client, project)
      end

      context 'when extended_events is enabled' do
        let(:extended_events) { true }

        it 'does not skip the stage' do
          expect_next_instance_of(Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter) do |importer|
            expect(importer).to receive(:execute).and_return(Gitlab::JobWaiter.new)
          end

          worker.import(client, project)
        end
      end
    end
  end
end
