# frozen_string_literal: true

module Import
  class GithubService < Import::BaseService
    include ActiveSupport::NumberHelper
    include Gitlab::Utils::StrongMemoize

    MINIMUM_IMPORT_SCOPE = 'repo'
    COLLAB_IMPORT_SCOPES = %w[admin:org read:org].freeze

    attr_accessor :client
    attr_reader :params, :current_user

    def execute(access_params, provider)
      context_error = validate_context
      return context_error if context_error

      if provider == :github # we skip scope validation for Gitea importer calls
        token = access_params[:github_access_token]

        if Gitlab::GithubImport.fine_grained_personal_token?(token)
          Gitlab::GithubImport::Logger.info(
            message: 'Fine grained GitHub personal access token used.'
          )
          warning = s_('GithubImport|Fine-grained personal access tokens are not officially supported. ' \
                       'It is recommended to use a classic token instead.')
        elsif Gitlab::GithubImport.classic_personal_token?(token)
          scope_error = validate_scopes
          return scope_error if scope_error
        end
      end

      project = create_project(access_params, provider)
      track_access_level('github')

      if project.persisted?
        store_import_settings(project)
        success(project, warning: warning)
      elsif project.errors[:import_source_disabled].present?
        error(project.errors[:import_source_disabled], :forbidden)
      else
        error(project_save_error(project), :unprocessable_entity)
      end
    rescue Octokit::Error => e
      log_error(e)
    end

    def create_project(access_params, provider)
      Gitlab::LegacyGithubImport::ProjectCreator.new(
        repo,
        project_name,
        target_namespace,
        current_user,
        type: provider,
        **access_params
      ).execute(extra_project_attrs)
    end

    def repo
      @repo ||= client.repository(params[:repo_id].to_i)
    end

    def project_name
      @project_name ||= params[:new_name].presence || repo[:name]
    end

    def target_namespace
      @target_namespace ||= Namespace.find_by_full_path(target_namespace_path)
    end

    def extra_project_attrs
      {}
    end

    def oversized?
      repository_size_limit > 0 && repo[:size] > repository_size_limit
    end

    def oversize_error_message
      s_('GithubImport|"%{repository_name}" size (%{repository_size}) is larger than the limit of %{limit}.') % {
        repository_name: repo[:name],
        repository_size: number_to_human_size(repo[:size]),
        limit: number_to_human_size(repository_size_limit)
      }
    end

    def repository_size_limit
      strong_memoize :repository_size_limit do
        namespace_limit = target_namespace.repository_size_limit.to_i

        if namespace_limit > 0
          namespace_limit
        else
          Gitlab::CurrentSettings.repository_size_limit.to_i
        end
      end
    end

    def url
      @url ||= params[:github_hostname]
    end

    def allow_local_requests?
      Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
    end

    def blocked_url?
      Gitlab::HTTP_V2::UrlBlocker.blocked_url?(
        url,
        allow_localhost: allow_local_requests?,
        allow_local_network: allow_local_requests?,
        schemes: %w[http https],
        deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
        outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist # rubocop:disable Naming/InclusiveLanguage -- existing setting
      )
    end

    private

    def validate_scopes
      scopes = client.octokit.scopes

      unless scopes.include?(MINIMUM_IMPORT_SCOPE)
        return log_and_return_error('Invalid Scope', format(s_("GithubImport|Your GitHub access token does not have the correct scope to import. Please use a token with the '%{scope}' scope."), scope: 'repo'), :unprocessable_entity)
      end

      collaborators_import = params.dig(:optional_stages, :collaborators_import) || false # if not set, default to false to skip collaborator import validation

      return if collaborators_import == false || scopes.intersection(COLLAB_IMPORT_SCOPES).any?

      log_and_return_error('Invalid scope', format(s_("GithubImport|Your GitHub access token does not have the correct scope to import collaborators. Please use a token with the '%{scope}' scope."), scope: 'read:org'), :unprocessable_entity)
    end

    def validate_context
      if blocked_url?
        log_and_return_error("Invalid URL: #{url}", _("Invalid URL: %{url}") % { url: url }, :bad_request)
      elsif target_namespace.nil?
        error(s_('GithubImport|Namespace or group to import repository into does not exist.'), :unprocessable_entity)
      elsif !authorized?
        error(s_('GithubImport|You are not allowed to import projects in this namespace.'), :unprocessable_entity)
      elsif oversized?
        error(oversize_error_message, :unprocessable_entity)
      end
    end

    def target_namespace_path
      raise ArgumentError, s_('GithubImport|Target namespace is required') if params[:target_namespace].blank?

      params[:target_namespace]
    end

    def log_error(exception)
      Gitlab::GithubImport::Logger.error(
        message: 'Import failed due to a GitHub error',
        status: exception.response_status,
        error: exception.response_body
      )

      error(s_('GithubImport|Import failed due to a GitHub error: %{original} (HTTP %{code})') % { original: exception.response_body, code: exception.response_status }, :unprocessable_entity)
    end

    def log_and_return_error(message, translated_message, http_status)
      Gitlab::GithubImport::Logger.error(
        message: 'Error while attempting to import from GitHub',
        error: message
      )

      error(translated_message, http_status)
    end

    def store_import_settings(project)
      Gitlab::GithubImport::Settings
        .new(project)
        .write(
          timeout_strategy: params[:timeout_strategy] || ProjectImportData::PESSIMISTIC_TIMEOUT,
          optional_stages: params[:optional_stages],
          extended_events: Feature.enabled?(:github_import_extended_events, current_user)
        )
    end
  end
end

Import::GithubService.prepend_mod_with('Import::GithubService')
