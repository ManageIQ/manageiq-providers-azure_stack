module ManageIQ::Providers::AzureStack::ManagerMixin
  extend ActiveSupport::Concern

  SUPPORTED_API_VERSIONS = %w[V2017_03_09 V2018_03_01].freeze
  SUPPORTED_SERVICES = %i[Resources Compute Network Monitor].freeze

  def connect(options = {})
    raise _('no credentials defined') if missing_credentials?(options[:auth_type])

    base_url     = options[:base_url]     || self.base_url
    tenant       = options[:tenant]       || azure_tenant_id
    username     = options[:user]         || authentication_userid(options[:auth_type])
    password     = options[:pass]         || authentication_password(options[:auth_type])
    subscription = options[:subscription] || self.subscription
    service      = options[:service]      || :Resources
    api_version  = options[:api_version]  || self.api_version
    ad_settings  = options[:ad_settings]  || active_directory_settings(base_url)
    token        = options[:token]        || nil

    raise _("Unsupported API version: %{api_version}") % {:api_version => api_version} unless api_version_supported?(api_version)
    raise _("Unsupported service: %{service}") % {:service => service} unless service_supported?(service)

    # Gem currently delievers no API profile for :Monitor other than :Latest
    api_version = :Latest if service == :Monitor

    self.class.raw_connect(base_url, tenant, username, password, subscription, service, api_version,
                           :ad_settings => ad_settings, :token => token)
  end

  def verify_credentials(_auth_type = nil, options = {})
    self.options = nil # clear cached options
    self.class.connection_rescue_block do
      connection = connect(options)
      self.class.validate_connection(connection)
    end
  end

  def base_url
    scheme = security_protocol == 'non-ssl' ? 'http' : 'https'
    self.port ||= scheme == 'http' ? 80 : 443
    "#{scheme}://#{hostname}:#{self.port}"
  end

  def active_directory_settings(base_url = nil)
    require 'ms_rest_azure' # connect() invokes us prior raw_connect() where Azure gems are normally imported

    unless options && options[:active_directory_settings]
      settings = self.class.active_directory_settings_api(base_url || self.base_url)
      self.options ||= {}
      self.options[:active_directory_settings] = {
        :authentication_endpoint => settings.authentication_endpoint,
        :token_audience          => settings.token_audience
      }
      update(:options => self.options)
    end

    settings = self.options[:active_directory_settings]
    MsRestAzure::ActiveDirectoryServiceSettings.new.tap do |ad|
      ad.authentication_endpoint = settings[:authentication_endpoint]
      ad.token_audience          = settings[:token_audience]
    end
  end

  def provider_region
    unless self[:provider_region]
      compute_provider = connect.providers.get('Microsoft.Compute')
      self[:provider_region] = compute_provider&.resource_types&.first&.locations&.first
      update(:provider_region => self[:provider_region])
    end
    self[:provider_region]
  end

  def api_version_supported?(api_version)
    SUPPORTED_API_VERSIONS.include?(api_version)
  end

  def service_supported?(service)
    SUPPORTED_SERVICES.include?(service)
  end

  module ClassMethods
    def params_for_create
      @params_for_create ||= {
        :title  => "Configure Azure Stack",
        :fields => [
          {
            :component  => "text-field",
            :name       => "endpoints.default.base_url",
            :label      => "URL",
            :isRequired => true,
            :validate   => [{:type => "required-validator"}]
          },
          {
            :component  => "text-field",
            :name       => "endpoints.default.tenant",
            :label      => "Tenant",
            :isRequired => true,
            :validate   => [{:type => "required-validator"}]
          },
          {
            :component => "text-field",
            :name      => "endpoints.default.username",
            :label     => "Username",
            :isRequired => true,
            :validate   => [{:type => "required-validator"}]
          },
          {
            :component  => "text-field",
            :name       => "endpoints.default.password",
            :label      => "Password",
            :type       => "password",
            :isRequired => true,
            :validate   => [{:type => "required-validator"}]
          },
          {
            :component  => "text-field",
            :name       => "endpoints.default.subscription",
            :label      => "Subscription",
            :isRequired => true,
            :validate   => [{:type => "required-validator"}]
          },
          {
            :component  => "text-field",
            :name       => "endpoints.default.api_version",
            :label      => "API Version",
            :isRequired => true,
            :validate   => [{:type => "required-validator"}]
          }
        ]
      }.freeze
    end

    def verify_credentials(args)
      default_endpoint = args.dig("endpoints", "default")
      base_url, tenant, username, password, subscription, api_version = default_endpoint.values_at(
        "base_url", "tenant", "username", "password", "subscription", "api_version"
      )

      !!raw_connect(base_url, tenant, username, password, subscription, :Resources, api_version, :validate => true)
    end

    def raw_connect(base_url, tenant, username, password, subscription, service, api_version, ad_settings: nil, token: nil, validate: false)
      require 'ms_rest_azure'
      require 'azure_mgmt_resources'
      require 'azure_mgmt_compute'
      require 'azure_mgmt_network'
      require 'azure_mgmt_monitor'
      require 'patches/ms_rest_azure/password_token_provider' # https://github.com/Azure/azure-sdk-for-ruby/pull/2039

      ad_settings ||= active_directory_settings_api(base_url)
      token       ||= token(tenant, username, MiqPassword.try_decrypt(password), ad_settings)

      options = {
        :subscription_id           => subscription,
        :credentials               => token,
        :active_directory_settings => ad_settings,
        :base_url                  => base_url
      }

      connection = Azure.const_get(service)::Profiles.const_get(api_version)::Mgmt::Client.new(options)

      validate_connection(connection) if validate

      connection
    end

    def connection_rescue_block
      yield
    rescue MsRestAzure::AzureOperationError => err
      msg = JSON.parse(err.message)['message']
      # Hide ugly exception name fragments from user, displaying actuall message only
      msg.sub!('MsRestAzure::AzureOperationError: ', '')
      msg.sub!('SubscriptionNotFound: ', '')
      raise MiqException::MiqInvalidCredentialsError, _(msg)
    rescue MiqException::MiqInvalidCredentialsError
      raise # Raise before falling into catch-all block below
    rescue StandardError => err
      _log.error("Error Class=#{err.class.name}, Message=#{err.message}, Backtrace=#{err.backtrace}")
      raise err, _("Unexpected response returned from system: %{error_message}") % {:error_message => err.message}
    end

    # Fetch authentication endpoint as per
    # https://docs.microsoft.com/en-us/azure/azure-stack/user/azure-stack-version-profiles-ruby
    def active_directory_settings_api(base_url)
      log = "#{base_url}/metadata/endpoints?api-version=1.0 for Active Directory settings"

      response = Faraday.new(:url => base_url).get do |req|
        req.path = '/metadata/endpoints'
        req.params = { 'api-version' => '1.0' }
        req.headers['Content-Type'] = 'application/json'
        req.options.timeout = api_connection_timeout
      end
      result = JSON.parse(response.body)

      raise MiqException::MiqInvalidCredentialsError, _("Bad response from %{log}: %{result}") % {:log => log, :result => result} unless response.success?

      MsRestAzure::ActiveDirectoryServiceSettings.new.tap do |settings|
        settings.authentication_endpoint = result.dig('authentication', 'loginEndpoint')
        settings.token_audience = result.dig('authentication', 'audiences', 0)
      end
    rescue JSON::ParserError
      raise MiqException::MiqInvalidCredentialsError, _("Bad response from %{log}") % {:log => log}
    rescue Faraday::ConnectionFailed => err
      msg = err.message
      msg = msg.sub('execution expired', 'Connection timeout') # original timeout message is horrible
      raise MiqException::MiqInvalidCredentialsError, _("Could not reach %{log}: %{msg}") % {:log => log, :msg => msg}
    end

    def token(tenant, username, password, ad_settings)
      token = MsRestAzure::PasswordTokenProvider.new(
        tenant,
        '1950a258-227b-4e31-a9cf-717495945fc2', # hard-coded for all Azure Stack environments
        username,
        password,
        ad_settings
      )
      MsRest::TokenCredentials.new(token)
    end

    def validate_connection(connection)
      connection_rescue_block do
        Timeout.timeout(api_connection_timeout) { connection.providers.get('Microsoft.Compute') }
        true
      end
    rescue Timeout::Error
      raise MiqException::MiqInvalidCredentialsError, _("Timeout reached when accessing %{url}") % {:url => connection.base_url}
    end

    def api_connection_timeout
      my_settings.api_connection_timeout.to_i_with_method
    end
  end
end
