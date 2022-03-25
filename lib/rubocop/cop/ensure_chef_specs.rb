# frozen_string_literal: true

require 'rubocop'
require 'pathname'

module Rubocop
  module Cop
    class EnsureChefSpecs < ::RuboCop::Cop::Cop
      include RuboCop::Cop::RangeHelp

      ROOT_DIR = File.expand_path(File.join(__dir__, '../../../'))
      COOKBOOKS_DIR = 'files/gitlab-cookbooks'

      def on_new_investigation
        file_path = Pathname.new(processed_source.file_path).relative_path_from(ROOT_DIR)
        spec_file = get_spec_file(file_path)
        spec_file_path = File.join(ROOT_DIR, spec_file)

        return if File.exist?(spec_file_path)

        add_offense(source_range(processed_source.buffer, 0, 0),
                    location: source_range(processed_source.buffer, 0, 0),
                    message: "Code file does not have a spec file. Create one at `#{spec_file}`")
      end

      private

      def get_spec_file(file_path)
        # Just return a file that is sure to exist
        return '.' unless file_path.to_s.start_with?(COOKBOOKS_DIR)

        dir, file = file_path.relative_path_from('files/gitlab-cookbooks').split
        "spec/chef/cookbooks/#{dir}/#{File.basename(file, '.rb')}_spec.rb"
      end
    end
  end
end
