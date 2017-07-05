require 'openssl'

module GitlabSpec
  module Macros

    def gitlab_converge(recipe)
      ChefSpec::SoloRunner.new { compile_stubs }.converge(recipe) { converge_stubs }
    end

    def compile_stubs
      stub_command('id -Z').and_return(false)
      stub_command("grep 'CS:123456:respawn:/opt/gitlab/embedded/bin/runsvdir-start' /etc/inittab").and_return('')
      stub_command(%r{\(test -f /var/opt/gitlab/gitlab-rails/upgrade-status/db-migrate-\h+-\) && \(cat /var/opt/gitlab/gitlab-rails/upgrade-status/db-migrate-\h+- | grep -Fx 0\)}).and_return(false)
      stub_command("getenforce | grep Disabled").and_return(true)
      stub_command("semodule -l | grep '^#gitlab-7.2.0-ssh-keygen\\s'").and_return(true)
      stub_command(%r{set \-x \&\& \[ \-d "[^"]\" \]}).and_return(false)
      stub_command(%r{set \-x \&\& \[ "\$\(stat \-\-printf='[^']*' \$\(readlink -f /[^\)]*\)\) }).and_return(false)
      stub_command('/opt/gitlab/embedded/bin/psql --version').and_return("fake_version")
      # Prevent chef converge from reloading the storage helper library, which would override our helper stub
      mock_file_load(%r{gitlab/libraries/storage_directory_helper})
      mock_file_load(%r{gitlab/libraries/helper})
      allow_any_instance_of(Chef::Recipe).to receive(:system).with('/sbin/init --version | grep upstart')
      allow_any_instance_of(Chef::Recipe).to receive(:system).with('systemctl | grep "\-\.mount"')
    end

    def converge_stubs
      allow(VersionHelper).to receive(:version).and_call_original
      allow(VersionHelper).to receive(:version).with('/opt/gitlab/embedded/bin/psql --version').and_return('fake_psql_version')
      allow_any_instance_of(PgHelper).to receive(:database_version).and_return("9.2")
    end

    def stub_gitlab_rb(config)
      config.each do |key, value|
        value = Mash.from_hash(value) if value.is_a?(Hash)
        allow(Gitlab).to receive(:[]).with(key.to_s).and_return(value)
      end
    end

    def stub_service_success_status(service, value)
      allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/init/#{service} status").and_return(value)
    end

    def stub_service_failure_status(service, value)
      allow_any_instance_of(OmnibusHelper).to receive(:failure?).with("/opt/gitlab/init/#{service} status").and_return(value)
    end

    def stub_should_notify?(service, value)
      allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(value)
      stub_service_success_status(service, value)
    end

    def stub_env_var(var, value)
      allow(ENV).to receive(:[]).with(var).and_return(value)
    end

    # a small helper function that creates a SHA1 fingerprint from a private or
    # public key.
    def create_fingerprint_from_key(key, passphrase = nil)
      new_key = OpenSSL::PKey::RSA.new(key, passphrase)
      new_key_digest = OpenSSL::Digest::SHA1.new(new_key.public_key.to_der).to_s.scan(/../).join(':')
      new_key_digest
    end

    def create_fingerprint_from_public_key(public_key)
      ::SSHKeygen::PublicKeyReader.new(public_key).key_fingerprint
    end
  end
end
