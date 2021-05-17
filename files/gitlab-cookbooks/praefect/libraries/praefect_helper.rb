class PraefectHelper < BaseHelper
  attr_reader :node

  def create_database?
    node['praefect']['create_database'] && !node['praefect']['sql_database'].nil?
  end
end
  