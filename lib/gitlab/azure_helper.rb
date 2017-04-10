require 'azure_mgmt_compute'
include Azure::ARM::Compute
include Azure::ARM::Compute::Models

class AzureHelper
  def initialize(version, type)
    # version specifies the GitLab version being processed
    # type specifies whether it is CE or EE being processed

    @version = version
    @type = type || 'ce'
    @tenant_id = ENV["ARM_TENANT_ID"]
    @client_id = ENV["ARM_CLIENT_ID"]
    @secret = ENV["ARM_CLIENT_SECRET"]
    @subscription_id = ENV["ARM_SUBSCRIPTION_ID"]
    @resource_group_name = ENV["ARM_RESOURCE_GROUP"]
    @storage_account = ENV["ARM_STORAGE_ACCOUNT"]

    # Create client for performing actions
    token_provider = MsRestAzure::ApplicationTokenProvider.new(@tenant_id, @client_id, @secret)
    credentials = MsRest::TokenCredentials.new(token_provider)
    @client = ComputeManagementClient.new(credentials)
    @client.subscription_id = subscription_id
  end

  def create_vhd
    output = `support/packer/packer-build.sh #{@version} #{@type} azure"`

    # Packer generates a lot of output, which contains the created VHD's
    # URI in the following format
    # OSDiskUri: <path to vhd>. It needs to be extracted to be used in
    # following steps
    vhd = output.match("OSDiskUri: (?<uri>.*)\n")["vhd"]
    vhd
  end

  def process
    vhd = create_vhd

    image = Image.new
    image.location = "East US"
    storage_profile = StorageProfile.new

    ref = ImageReference.new
    ref.publisher = 'Canonical'
    ref.offer = 'UbuntuServer'
    ref.sku = '16.04-LTS'
    storage_profile.image_reference = ref

    os_disk = ImageOSDisk.new
    os_disk.blob_uri = vhd
    os_disk.os_type = "Linux"
    os_disk.os_state = "Generalized"
    storage_profile.os_disk = os_disk

    image.storage_profile = storage_profile
    @client.images.create_or_update(@resource_group_name, "GitLab #{@type.upcase} #{@version}", image)
  end
end
