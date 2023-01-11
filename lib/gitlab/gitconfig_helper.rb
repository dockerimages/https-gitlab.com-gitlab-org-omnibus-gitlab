module Gitconfig
  class Util
    class << self
      def convert_gitconfig(entries_map)
        return [] if entries_map.nil?

        entries_map.flat_map do |section, entries|
          entries.map do |entry|
            # Split up the `foo.bar=value` to obtain the left-hand and
            # right-hand sides of the assignment.
            section_subsection_and_key, value = "#{section}.#{entry}".split('=', 2)
            section_subsection_and_key&.rstrip!
            value&.lstrip!

            raise "Invalid entry detected in omnibus_gitconfig['system']: '#{entry}' should be in the form key=value" if section_subsection_and_key.nil? || value.nil?

            # We need to split up the left-hand side. This can either be of the
            # form `core.gc`, or of the form `http "http://example.com".insteadOf`.
            # We thus split from the right side at the first dot we see.
            key, section_and_subsection = section_subsection_and_key.reverse.split('.', 2)
            key.reverse!

            # And then we need to potentially split the section/subsection if we
            # have `http "http://example.com"` now.
            section, subsection = section_and_subsection.reverse!.split(' ', 2)
            subsection&.gsub!(/\A"|"\Z/, '')

            # So that we have finally split up the section, subsection, key and
            # value. It is fine for the `subsection` to be `nil` here in case there
            # is none.
            {
              section: section,
              subsection: subsection,
              key: key,
              value: value
            }.delete_if { |k, v| v.nil? }
          end
        end
      end
    end
  end
end
