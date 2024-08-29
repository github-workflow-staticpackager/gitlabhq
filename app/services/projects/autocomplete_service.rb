# frozen_string_literal: true

module Projects
  class AutocompleteService < BaseService
    include LabelsAsHash
    def issues
      IssuesFinder.new(current_user, project_id: project.id, state: 'opened').execute.select([:iid, :title])
    end

    def milestones
      finder_params = {
        project_ids: [@project.id],
        state: :active,
        order: { due_date: :asc, title: :asc }
      }

      finder_params[:group_ids] = @project.group.self_and_ancestors.select(:id) if @project.group

      MilestonesFinder.new(finder_params).execute.select([:iid, :title, :due_date])
    end

    def merge_requests
      MergeRequestsFinder.new(current_user, project_id: project.id, state: 'opened').execute.select([:iid, :title])
    end

    def commands(noteable)
      return [] unless noteable && current_user

      QuickActions::InterpretService.new(container: project, current_user: current_user).available_commands(noteable)
    end

    def snippets
      SnippetsFinder.new(current_user, project: project).execute.select([:id, :title])
    end

    def contacts(target)
      available_contacts = Crm::ContactsFinder.new(current_user, group: project.group).execute
        .select([:id, :email, :first_name, :last_name, :state])

      contact_hashes = available_contacts.as_json

      return contact_hashes unless target.is_a?(Issue)

      ids = target.customer_relations_contacts.ids # rubocop:disable CodeReuse/ActiveRecord

      contact_hashes.each do |hash|
        hash[:set] = ids.include?(hash['id'])
      end

      contact_hashes
    end

    def labels_as_hash(target)
      super(target, project_id: project.id, include_ancestor_groups: true)
    end
  end
end

Projects::AutocompleteService.prepend_mod_with('Projects::AutocompleteService')
