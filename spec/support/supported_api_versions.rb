def supported_api_versions(&block)
  ManageIQ::Providers::AzureStack::CloudManager::SUPPORTED_API_VERSIONS.each do |api_version|
    context api_version do
      let(:api_version) { api_version }
      class_exec(api_version, &block)
    end
  end
end
