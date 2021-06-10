class PraefectHelper < BaseHelper
  attr_reader :node

  def create_database?
    !node['gitlab']['geo-postgresql']['enable'] && node['praefect']['manage_database'] &&
      !node['praefect']['sql_database'].nil?
  end

  def create_database_user?
    create_database? &&
      !node['praefect']['pgbouncer_user'].nil? && !node['praefect']['pgbouncer_user_password'].nil?
  end
end
