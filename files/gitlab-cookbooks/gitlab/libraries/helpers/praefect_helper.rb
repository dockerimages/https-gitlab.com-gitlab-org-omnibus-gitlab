class PraefectHelper < BaseHelper
  attr_reader :node

  def running_in_geo?
    Gitlab['geo_primary_role']['enable'] || Gitlab['geo_secondary_role']['enable'] ||
      node['gitlab']['geo-postgresql']['enable']
  end

  def create_database?
    !running_in_geo? && node['praefect']['manage_database'] &&
      !node['praefect']['sql_database'].nil?
  end

  def create_database_user?
    create_database? &&
      !node['praefect']['pgbouncer_user'].nil? && !node['praefect']['pgbouncer_user_password'].nil?
  end
end
