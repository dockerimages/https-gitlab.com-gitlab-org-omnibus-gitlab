require 'aws-sdk'

class S3Cache

  def initialize
    set_env_variables
  end

  def fetch
    return "ccache directory already available. " if cache_exists?

    # New branch - pull ccache from master
    # New tag - figure out which stable branch
    @ref = find_matching_cache_ref
    puts @ref
    success = fetch_from_s3
    unpack if success
  end

  # CI_BUILD_REF_SLUG=$'\''8-15-stable'\''
  # CI_BUILD_NAME=$'\''Ubuntu 16.04 branch'\''
  def set_env_variables
    @aws_access_key_id = get_env_variable('CACHE_AWS_ACCESS_KEY_ID')
    @aws_secret_access_key = get_env_variable('CACHE_AWS_SECRET_ACCESS_KEY')
    @aws_region = get_env_variable('CACHE_AWS_S3_REGION')
    @aws_bucket = get_env_variable('CACHE_AWS_BUCKET')
    @build_name = get_env_variable('CI_BUILD_NAME')
    @build_ref = get_env_variable('CI_BUILD_REF_NAME')
    @project_id = get_env_variable('CI_PROJECT_ID')
  end

  def cache_key_directory
    "#{@build_name}/#{@build_ref}"
  end

  def get_env_variable(var)
    value = ENV[var]
    raise "#{var} cannot be read!" if value.nil?
    value.chomp
  end

  # Non-smart check whether we already have the ccache directory. eg.
  # When we are reusing existing build machine
  # When runner restored previously existing cache
  def cache_exists?
    File.exists?('ccache')
  end

  # Checking the ref to see whether we have a tag or branch
  # We have tags in the form of '8.16.5+ee.1' or '8.17.0+rc1.ce.0'
  # Try to get the version by fetching the part before +
  # If we don't get a semver compatible result, we want to fetch from master
  def find_matching_cache_ref
    tag = @build_ref.split("+")
    version = tag.first
    rest = tag.last
    semver = version.split(".")

    if semver.count != 3
      "master"
    else
      major = semver[0]
      minor = semver[1]
      edition = "-ee" if is_ee?(rest.split("."))

      "#{major}-#{minor}-stable#{edition}"
    end
  end

  def is_ee?(rest)
    rest.include?('ee')
  end

  def fetch_from_s3
    s3 = Aws::S3::Client.new(region: @aws_region, credentials: aws_credentials)

    puts "Attempting to fetch #{key_name} to #{@ref}"
    object = s3.get_object(bucket: @aws_bucket, key: key_name, response_target: @ref)
  rescue Aws::S3::Errors::NoSuchKey => e
    puts "Did not find the file in the bucket: #{e}"
    false
  end

  def aws_credentials
    Aws::Credentials.new(@aws_access_key_id, @aws_secret_access_key)
  end

  # This is the name of the file we want to fetch from S3
  def key_name
    "project/#{@project_id}/#{@build_name}/#{@ref}"
  end

  def unpack
    `unzip -o #{@ref}`
  end
end
