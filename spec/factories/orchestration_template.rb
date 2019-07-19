FactoryBot.define do
  factory :orchestration_template_azure_stack,
          :parent => :orchestration_template,
          :class  => 'ManageIQ::Providers::AzureStack::CloudManager::OrchestrationTemplate' do
    content { File.read(ManageIQ::Providers::AzureStack::Engine.root.join('spec', 'fixtures', 'orchestration_templates', 'deployment.json')) }
  end
end
