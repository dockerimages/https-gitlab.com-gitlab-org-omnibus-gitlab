require 'chef_helper'

describe AddressHelper do
  let(:fake_ip_address_list) do
    [
      Addrinfo.ip("10.0.0.4"),
      Addrinfo.ip("103.0.0.4")
    ]
  end
  before { allow(Socket).to receive(:ip_address_list).and_return(fake_ip_address_list) }

  describe "#private_ipv4_list" do
    it 'returns private ip list' do
      expect(AddressHelper.private_ipv4_list).to eq ['10.0.0.4']
    end
  end

  describe "#public_ipv4_list" do
    it 'returns public ip list' do
      expect(AddressHelper.public_ipv4_list).to eq ['103.0.0.4']
    end
  end
end
