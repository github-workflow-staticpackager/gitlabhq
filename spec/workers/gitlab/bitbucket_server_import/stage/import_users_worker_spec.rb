# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Stage::ImportUsersWorker, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :import_started,
      import_data_attributes: {
        data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
        credentials: { 'base_uri' => 'http://bitbucket.org/', 'user' => 'bitbucket', 'password' => 'password' }
      }
    )
  end

  let(:worker) { described_class.new }

  it_behaves_like Gitlab::BitbucketServerImport::StageMethods

  describe '#perform' do
    context 'when the import succeeds' do
      before do
        allow_next_instance_of(Gitlab::BitbucketServerImport::Importers::UsersImporter) do |importer|
          allow(importer).to receive(:execute)
        end

        allow(Gitlab::BitbucketServerImport::Stage::ImportPullRequestsWorker).to receive(:perform_async).and_return(nil)
      end

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { [project.id] }
      end

      it 'schedules the next stage' do
        expect(Gitlab::BitbucketServerImport::Stage::ImportPullRequestsWorker).to receive(:perform_async)
          .with(project.id)

        worker.perform(project.id)
      end

      it 'logs stage start and finish' do
        expect(Gitlab::BitbucketServerImport::Logger)
          .to receive(:info).with(hash_including(message: 'starting stage', project_id: project.id))
        expect(Gitlab::BitbucketServerImport::Logger)
          .to receive(:info).with(hash_including(message: 'stage finished', project_id: project.id))

        worker.perform(project.id)
      end
    end

    context 'when project does not exists' do
      it 'does not call importer' do
        expect(Gitlab::BitbucketServerImport::Importers::UsersImporter).not_to receive(:new)

        worker.perform(-1)
      end
    end

    context 'when project import state is not `started`' do
      it 'does not call importer' do
        project = create(:project, :import_canceled)

        expect(Gitlab::BitbucketServerImport::Importers::UsersImporter).not_to receive(:new)

        worker.perform(project.id)
      end
    end

    context 'when the importer fails' do
      it 'does not schedule the next stage and raises error' do
        exception = StandardError.new('Error')

        allow_next_instance_of(Gitlab::BitbucketServerImport::Importers::UsersImporter) do |importer|
          allow(importer).to receive(:execute).and_raise(exception)
        end

        expect(Gitlab::Import::ImportFailureService)
          .to receive(:track).with(
            project_id: project.id,
            exception: exception,
            error_source: described_class.name,
            fail_import: false
          ).and_call_original

        expect { worker.perform(project.id) }
          .to change { Gitlab::BitbucketServerImport::Stage::ImportUsersWorker.jobs.size }.by(0)
          .and raise_error(exception)
      end
    end
  end
end
