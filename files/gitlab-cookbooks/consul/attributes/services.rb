default['consul']['services'] = []
default['consul']['service_config'] = nil

default['consul']['internal']['service_config']['postgresql'] = {
  'postgresql' => {
    'service' => {
      'name' => "postgresql",
      'address' => '',
      'port' => 5432,
      'check' => {
        'id': 'service:postgresql',
        'interval' => "10s",
        'status': 'failing'
      }
    }
  }
}
default['consul']['internal']['service_config']['repmgr'] = {
  'postgresql' => {
    'service' => {
      'check' => {
        'args' => ['/opt/gitlab/bin/gitlab-ctl', 'repmgr-check-master']
      }
    },
    'watches': [
      {
        'type': 'keyprefix',
        'prefix': 'gitlab/ha/postgresql/failed_masters/',
        'args': ['/opt/gitlab/bin/gitlab-ctl', 'consul', 'watchers', 'handle-failed-master']
      }
    ]
  }
}
default['consul']['internal']['service_config']['patroni'] = {
  'postgresql' => {
    'service' => {
      'check' => {
        'args' => ['/opt/gitlab/bin/gitlab-ctl', 'patroni', 'check-leader']
      }
    }
  }
}
