# frozen_string_literal: true

module Organizations
  class PathValidator < ::NamespacePathValidator
    def self.path_regex
      Gitlab::PathRegex.organization_path_regex
    end

    def build_full_path_to_validate_against_reserved_names?
      # full paths cannot be built for organizations because organizations do not have a parent
      # and it does not include the `Routable` concern.
      false
    end
  end
end
