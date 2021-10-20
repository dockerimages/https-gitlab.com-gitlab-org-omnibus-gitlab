## pre-hook for praefect startup
add_global_pre_hook 'skips praefect check' do
  return unless ARGV.include?('start') || ARGV.include?('restart')

  begin
    node_attributes = GitlabCtl::Util.get_node_attributes

    return if node_attributes.dig('praefect', 'env_directory').nil?

    skip_checks = ARGV.include?('--skip-praefect-checks') ? 'true' : 'false'
    File.open(File.join(node_attributes['praefect']['env_directory'], 'PRAEFECT_SKIP_CHECK'), 'w') { |f| f.write(skip_checks) }
  rescue GitlabCtl::Errors::NodeError
    return
  end
end
