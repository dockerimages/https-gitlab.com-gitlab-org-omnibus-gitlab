require 'spec_helper'
require 'gitlab/docker_image_memory_measurer'

describe Gitlab::DockerImageMemoryMeasurer do
  let(:image_reference) { 'mocked_image_reference' }
  let(:measurer) { described_class.new(image_reference, debug_output_dir) }
  let(:delete_debug_output_dir) { FileUtils.remove_dir(debug_output_dir, true) }
  let(:create_debug_output_dir) { FileUtils.mkdir_p(debug_output_dir) unless debug_output_dir.nil? }

  before(:each) do
    create_debug_output_dir
  end

  after(:each) do
    delete_debug_output_dir
  end

  describe '.new' do
    context 'debug_output_dir is specified' do
      let(:debug_output_dir) { 'tmp/measure_log_folder' }

      it 'set debug output file names' do
        expect(measurer.container_log_file).to eq('tmp/measure_log_folder/container_setup.log')
        expect(measurer.pid_command_map_file).to eq('tmp/measure_log_folder/pid_command_map.txt')
        expect(measurer.smem_result_file).to eq('tmp/measure_log_folder/smem_result.txt')
      end
    end

    context 'debug_output_dir is not specified' do
      let(:debug_output_dir) { nil }

      it 'set debug output file names' do
        expect(measurer.container_log_file).to eq('/dev/null')
        expect(measurer.pid_command_map_file).to be_nil
        expect(measurer.smem_result_file).to be_nil
      end
    end
  end

  describe '.run_command' do
    let(:debug_output_dir) { 'tmp/measure' }

    context 'command succeed' do
      it 'return the stdout_to_hash_array result' do
        allow(measurer).to receive(:stdout_to_hash_array).and_return('mock_return_of_stdout_to_hash_array')
        command_ret = measurer.run_command('ls', 'separator', 'tmp/measure/log_file.txt')
        expect(command_ret).to eq('mock_return_of_stdout_to_hash_array')
      end
    end

    context 'command fail' do
      it 'should raise error' do
        allow(measurer).to receive(:stdout_to_hash_array).and_return('mock_return_of_stdout_to_hash_array')
        expect { measurer.run_command('invalid_command_fds', 'separator', 'tmp/measure/log_file.txt') }.to raise_error(Errno::ENOENT, 'No such file or directory - invalid_command_fds')
      end
    end
  end

  describe '.append_to_file' do
    let(:debug_output_dir) { 'tmp/measure' }
    let(:filepath) { File.join(debug_output_dir, 'test_file.txt') }

    context 'file not exist' do
      let(:content) { 'content to write to file' }

      it 'should write the content to file' do
        FileUtils.rm_f(filepath)

        measurer.append_to_file(filepath, content)
        expect(File.exist?(filepath)).to be true
        expect(File.read(filepath)).to eq(content)
      end
    end

    context 'file exist' do
      let(:content) { 'content to write to file' }
      let(:old_content) { "old content in file\n" }

      it 'should append the content to file' do
        File.write(filepath, old_content)

        measurer.append_to_file(filepath, content)
        expect(File.exist?(filepath)).to be true
        expect(File.read(filepath)).to eq(old_content + content)
      end
    end
  end

  describe '.stdout_to_hash_array' do
    let(:debug_output_dir) { nil }

    context 'use customised separator' do
      let(:stdout) do
        <<-STDOUTSTRING
           PID<Pid_Command_Separator>COMMAND
           1<Pid_Command_Separator>/bin/bash /assets/wrapper
           23<Pid_Command_Separator>runsv sshd
           24<Pid_Command_Separator>svlogd -tt /var/log/gitlab/sshd
        STDOUTSTRING
      end
      let(:separator) { /<Pid_Command_Separator>/ }
      let(:expected_ret) do
        [
          { 'PID' => '1', 'COMMAND' => '/bin/bash /assets/wrapper' },
          { 'PID' => '23', 'COMMAND' => 'runsv sshd' },
          { 'PID' => '24', 'COMMAND' => 'svlogd -tt /var/log/gitlab/sshd' }
        ]
      end

      it 'return hash array' do
        expect(measurer.stdout_to_hash_array(stdout, separator)).to eq(expected_ret)
      end
    end

    context 'use space as separator' do
      let(:stdout) do
        <<-STDOUTSTRING
           PID User     Swap      USS      PSS      RSS     Command
           316 git      3504      432      443     1452     /opt/gitlab/embedded/bin/gi
           312 git       148      240      523     2476     /bin/bash /opt/gitlab/embed
        STDOUTSTRING
      end
      let(:separator) { /\s+/ }
      let(:expected_ret) do
        [
          { 'PID' => '316', 'User' => 'git', 'Command' => '/opt/gitlab/embedded/bin/gi', 'Swap' => '3504', 'USS' => '432', 'PSS' => '443', 'RSS' => '1452' },
          { 'PID' => '312', 'User' => 'git', 'Command' => '/bin/bash', 'Swap' => '148', 'USS' => '240', 'PSS' => '523', 'RSS' => '2476' }
        ]
      end

      it 'return hash array' do
        expect(measurer.stdout_to_hash_array(stdout, separator)).to eq(expected_ret)
      end
    end

    context 'give empty stdout' do
      let(:stdout) do
        <<-STDOUTSTRING
           PID<Pid_Command_Separator>COMMAND
        STDOUTSTRING
      end
      let(:separator) { /<Pid_Command_Separator>/ }
      let(:expected_ret) { [] }

      it 'return hash array' do
        expect(measurer.stdout_to_hash_array(stdout, separator)).to eq(expected_ret)
      end
    end
  end

  describe '.find_component' do
    let(:debug_output_dir) { nil }
    let(:component_command_patterns) { { 'c1' => /p1/, 'c2' => /p2/, 'c3' => /p3/ } }

    context 'command match exactly one pattern' do
      let(:command) { 'p1' }

      it 'return the component name' do
        allow(measurer).to receive(:component_command_patterns).and_return(component_command_patterns)
        expect(measurer.find_component(command)).to eq('c1')
      end
    end

    context 'command match no pattern' do
      let(:command) { 'p4' }

      it 'return nil' do
        allow(measurer).to receive(:component_command_patterns).and_return(component_command_patterns)
        expect(measurer.find_component(command)).to be_nil
      end
    end

    context 'command match two patterns' do
      let(:command) { 'p1 p2' }

      it 'raise error' do
        allow(measurer).to receive(:component_command_patterns).and_return(component_command_patterns)
        expect { measurer.find_component(command) }.to raise_error(SystemExit, /matches more than one components/)
      end
    end
  end

  describe '.add_full_command_and_component_to_smem_result_hash' do
    let(:debug_output_dir) { nil }
    let(:component_command_patterns) { { 'c1' => /^runsv sshd/, 'c2' => /^\/bin\/bash \/assets\/wrapper/, 'c3' => /p3/ } }
    let(:pid_command_hash_array) do
      [
        { 'PID' => '1', 'COMMAND' => '/bin/bash /assets/wrapper' },
        { 'PID' => '23', 'COMMAND' => 'runsv sshd' },
        { 'PID' => '24', 'COMMAND' => 'svlogd -tt /var/log/gitlab/sshd' }
      ]
    end
    let(:smem_result_hash_array) do
      [
        { 'PID' => '23', 'User' => 'git', 'Command' => 'runsv', 'Swap' => '3504', 'USS' => '432', 'PSS' => '443', 'RSS' => '1452' },
        { 'PID' => '1', 'User' => 'git', 'Command' => '/bin/bash', 'Swap' => '148', 'USS' => '240', 'PSS' => '523', 'RSS' => '2476' }
      ]
    end
    let(:expected_ret) do
      [
        { 'PID' => '23', 'User' => 'git', 'Command' => 'runsv', 'Swap' => '3504', 'USS' => '432', 'PSS' => '443', 'RSS' => '1452', 'COMMAND' => 'runsv sshd', 'COMPONENT' => 'c1' },
        { 'PID' => '1', 'User' => 'git', 'Command' => '/bin/bash', 'Swap' => '148', 'USS' => '240', 'PSS' => '523', 'RSS' => '2476', 'COMMAND' => '/bin/bash /assets/wrapper', 'COMPONENT' => 'c2' }
      ]
    end

    it 'should return updated hash with command and component' do
      allow(measurer).to receive(:component_command_patterns).and_return(component_command_patterns)
      expect(measurer.add_full_command_and_component_to_smem_result_hash(pid_command_hash_array, smem_result_hash_array)).to eq(expected_ret)
    end
  end

  describe '.sum_memory_by_component' do
    let(:debug_output_dir) { nil }

    context 'given smem hash array' do
      let(:smem_result_hash_array) do
        [
          { 'PID' => '23', 'User' => 'User23', 'Command' => 'runsv23', 'Swap' => '3504', 'USS' => '100', 'PSS' => '1000', 'RSS' => '10000', 'COMMAND' => 'COMMAND23', 'COMPONENT' => 'c1' },
          { 'PID' => '24', 'User' => 'User24', 'Command' => 'runsv24', 'Swap' => '3504', 'USS' => '200', 'PSS' => '2000', 'RSS' => '20000', 'COMMAND' => 'COMMAND24', 'COMPONENT' => nil },
          { 'PID' => '27', 'User' => 'User27', 'Command' => 'runsv27', 'Swap' => '3504', 'USS' => '20', 'PSS' => '200', 'RSS' => '2000', 'COMMAND' => 'COMMAND27', 'COMPONENT' => nil },
          { 'PID' => '25', 'User' => 'User25', 'Command' => 'runsv25', 'Swap' => '3505', 'USS' => '400', 'PSS' => '4000', 'RSS' => '40000', 'COMMAND' => 'COMMAND25', 'COMPONENT' => 'c1' },
          { 'PID' => '26', 'User' => 'User26', 'Command' => 'runsv26', 'Swap' => '3504', 'USS' => '800', 'PSS' => '8000', 'RSS' => '80000', 'COMMAND' => 'COMMAND26', 'COMPONENT' => 'c2' },
        ]
      end
      let(:expected_ret) do
        {
          'c1' => { 'USS' => 500.0, 'PSS' => 5000.0, 'RSS' => 50000.0 },
          nil => { 'USS' => 220.0, 'PSS' => 2200.0, 'RSS' => 22000.0 },
          'c2' => { 'USS' => 800.0, 'PSS' => 8000.0, 'RSS' => 80000.0 }
        }
      end

      it 'return component memory usage hash' do
        expect(measurer.sum_memory_by_component(smem_result_hash_array)).to eq(expected_ret)
      end
    end
  end

  describe '.smem_sum_hash_as_metrics' do
    let(:debug_output_dir) { nil }

    context 'given smem summarised hash with some nil component' do
      let(:smem_sum_hash) do
        {
          'c1' => { 'USS' => 500.0, 'PSS' => 5000.0, 'RSS' => 50000.0 },
          nil => { 'USS' => 220.0, 'PSS' => 2200.0, 'RSS' => 22000.0 },
          'c2' => { 'USS' => 800.0, 'PSS' => 8000.0, 'RSS' => 80000.0 }
        }
      end
      let(:expected_ret) do
        [
          "uss_size_kb{component=\"c1\"} 500.0",
          "pss_size_kb{component=\"c1\"} 5000.0",
          "rss_size_kb{component=\"c1\"} 50000.0",
          "uss_size_kb{component=\"c2\"} 800.0",
          "pss_size_kb{component=\"c2\"} 8000.0",
          "rss_size_kb{component=\"c2\"} 80000.0"
        ]
      end

      it 'return metrics ignore nil component' do
        expect(measurer.smem_sum_hash_as_metrics(smem_sum_hash)).to eq(expected_ret)
      end
    end
  end
end
