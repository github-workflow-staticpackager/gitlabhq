# frozen_string_literal: true

module Packages
  module Npm
    class CreatePackageService < ::Packages::CreatePackageService
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      PACKAGE_JSON_NOT_ALLOWED_FIELDS = %w[readme readmeFilename licenseText contributors exports].freeze
      DEFAULT_LEASE_TIMEOUT = 1.hour.to_i

      ERROR_REASON_INVALID_PARAMETER = :invalid_parameter
      ERROR_REASON_PACKAGE_EXISTS = :package_already_exists
      ERROR_REASON_PACKAGE_LEASE_TAKEN = :package_lease_taken
      ERROR_REASON_PACKAGE_PROTECTED = :package_protected

      def execute
        return error('Version is empty.', ERROR_REASON_INVALID_PARAMETER) if version.blank?
        return error('Attachment data is empty.', ERROR_REASON_INVALID_PARAMETER) if attachment['data'].blank?
        return error('Package already exists.', ERROR_REASON_PACKAGE_EXISTS) if current_package_exists?
        return error('Package protected.', ERROR_REASON_PACKAGE_PROTECTED) if current_package_protected?
        return error('File is too large.', ERROR_REASON_INVALID_PARAMETER) if file_size_exceeded?

        package = try_obtain_lease do
          ApplicationRecord.transaction { create_npm_package! }
        end

        unless package
          return error('Could not obtain package lease. Please try again.', ERROR_REASON_PACKAGE_LEASE_TAKEN)
        end

        ServiceResponse.success(payload: { package: package })
      end

      private

      def error(message, reason)
        ServiceResponse.error(message: message, reason: reason)
      end

      def create_npm_package!
        package = create_package!(:npm, name: name, version: version)

        ::Packages::CreatePackageFileService.new(package, file_params).execute
        ::Packages::CreateDependencyService.new(package, package_dependencies).execute
        ::Packages::Npm::CreateTagService.new(package, dist_tag).execute

        create_npm_metadatum!(package)

        package
      end

      def create_npm_metadatum!(package)
        package.create_npm_metadatum!(package_json: package_json)
      rescue ActiveRecord::RecordInvalid => e

        if package.npm_metadatum && package.npm_metadatum.errors.added?(:package_json, :too_large)
          Gitlab::ErrorTracking.track_exception(e, field_sizes: field_sizes_for_error_tracking)
        end

        raise
      end

      def current_package_exists?
        project.packages
               .npm
               .with_name(name)
               .with_version(version)
               .not_pending_destruction
               .exists?
      end

      def current_package_protected?
        return false if Feature.disabled?(:packages_protected_packages, project)

        user_project_authorization_access_level = current_user.max_member_access_for_project(project.id)
        project.package_protection_rules.for_push_exists?(access_level: user_project_authorization_access_level,
          package_name: name, package_type: :npm)
      end

      def name
        params[:name]
      end

      def version
        params[:versions].each_key.first
      end
      strong_memoize_attr :version

      def version_data
        params[:versions][version]
      end

      def package_json
        version_data.except(*PACKAGE_JSON_NOT_ALLOWED_FIELDS)
      end

      def dist_tag
        params['dist-tags'].each_key.first
      end

      def package_file_name
        "#{name}-#{version}.tgz"
      end
      strong_memoize_attr :package_file_name

      def attachment
        params['_attachments'][package_file_name]
      end
      strong_memoize_attr :attachment

      # TODO (technical debt): Extract the package size calculation to its own component and unit test it separately.
      def calculated_package_file_size
        # This calculation is based on:
        # 1. 4 chars in a Base64 encoded string are 3 bytes in the original string. Meaning 1 char is 0.75 bytes.
        # 2. The encoded string may have 1 or 2 extra '=' chars used for padding. Each padding char means 1 byte less in
        #    the original string.
        # Reference:
        # - https://blog.aaronlenoir.com/2017/11/10/get-original-length-from-base-64-string/
        # - https://en.wikipedia.org/wiki/Base64#Decoding_Base64_with_padding
        encoded_data = attachment['data']
        ((encoded_data.length * 0.75) - encoded_data[-2..].count('=')).to_i
      end
      strong_memoize_attr :calculated_package_file_size

      def file_params
        {
          file: CarrierWaveStringFile.new(Base64.decode64(attachment['data'])),
          size: calculated_package_file_size,
          file_sha1: version_data[:dist][:shasum],
          file_name: package_file_name,
          build: params[:build]
        }
      end

      def package_dependencies
        _version, versions_data = params[:versions].first
        versions_data
      end

      def file_size_exceeded?
        project.actual_limits.exceeded?(:npm_max_file_size, calculated_package_file_size)
      end

      # used by ExclusiveLeaseGuard
      def lease_key
        "packages:npm:create_package_service:packages:#{project.id}_#{name}_#{version}"
      end

      # used by ExclusiveLeaseGuard
      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end

      def field_sizes
        package_json.transform_values do |value|
          value.to_s.size
        end
      end
      strong_memoize_attr :field_sizes

      def filtered_field_sizes
        field_sizes.select do |_, size|
          size >= ::Packages::Npm::Metadatum::MIN_PACKAGE_JSON_FIELD_SIZE_FOR_ERROR_TRACKING
        end
      end
      strong_memoize_attr :filtered_field_sizes

      def largest_fields
        field_sizes
            .sort_by { |a| a[1] }
            .reverse[0..::Packages::Npm::Metadatum::NUM_FIELDS_FOR_ERROR_TRACKING - 1]
            .to_h
      end
      strong_memoize_attr :largest_fields

      def field_sizes_for_error_tracking
        filtered_field_sizes.empty? ? largest_fields : filtered_field_sizes
      end
    end
  end
end
