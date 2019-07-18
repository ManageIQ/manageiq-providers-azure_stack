require 'ms_rest_azure'
require 'azure_mgmt_resources'

describe ManageIQ::Providers::AzureStack::CloudManager::OrchestrationStack do
  supported_api_versions do |api_version|
    let(:ems)      { FactoryBot.create(:ems_azure_stack_with_authentication, :provider_region => 'region', :subscription => '123') }
    let(:template) { FactoryBot.create(:orchestration_template_azure_stack, :content => '{}') }
    let(:client)   { Azure::Resources::Profiles.const_get(api_version)::Mgmt::Client.new }

    before do
      allow_any_instance_of(MsRestAzure::Common::Configurable).to receive(:reset!)
      allow(ems).to receive(:connect).with(:service => :Resources).and_return(client)
    end

    subject do
      FactoryBot.create(:orchestration_stack_azure_stack,
                        :ext_management_system => ems,
                        :name                  => 'stack-name',
                        :resource_group        => 'resource-group')
    end

    describe '.raw_create_stack' do
      context 'when succeeds' do
        it 'properly constructs and invokes API' do
          expect(client).to receive_message_chain(:resource_groups, :create_or_update) do |resource_group, props|
            expect(resource_group).to eq('resource-group')
            expect(props.location).to eq('region')
          end
          expect(client).to receive_message_chain(:deployments, :create_or_update_async) do |resource_group, stack_name, deployment|
            expect(resource_group).to eq('resource-group')
            expect(stack_name).to eq('stack-name')
            expect(deployment.properties).to have_attributes(
              :template   => {},
              :mode       => 'mode',
              :parameters => { 'param1' => { 'value' => 'value1' } }
            )
          end

          options = {
            :resource_group => 'resource-group',
            :mode           => 'mode',
            :parameters     => { 'param1' => 'value1' }
          }
          ems_ref = described_class.raw_create_stack(ems, 'stack-name', template, options)
          expect(ems_ref).to eq('/subscriptions/123/resourcegroups/resource-group/providers/microsoft.resources/deployments/stack-name')
        end
      end

      context 'when API fails' do
        it 'MIQ error is raised' do
          expect(client).to receive_message_chain(:resource_groups, :create_or_update).and_raise(ArgumentError)
          expect { described_class.raw_create_stack(ems, 'stack-name', template, {}) }.to raise_error(MiqException::MiqOrchestrationProvisionError)
        end
      end
    end

    describe '.raw_update_stack' do
      context 'when succeeds' do
        it 'properly constructs and invokes API' do
          expect(client).to receive_message_chain(:resource_groups, :create_or_update) do |resource_group, props|
            expect(resource_group).to eq('resource-group')
            expect(props.location).to eq('region')
          end
          expect(client).to receive_message_chain(:deployments, :create_or_update_async) do |resource_group, stack_name, deployment|
            expect(resource_group).to eq('resource-group')
            expect(stack_name).to eq('stack-name')
            expect(deployment.properties).to have_attributes(
              :template   => {},
              :mode       => 'mode',
              :parameters => { 'param1' => { 'value' => 'value1' } }
            )
          end

          options = {
            :resource_group => 'resource-group',
            :mode           => 'mode',
            :parameters     => { 'param1' => 'value1' }
          }
          ems_ref = subject.raw_update_stack(template, options)
          expect(ems_ref).to eq('/subscriptions/123/resourcegroups/resource-group/providers/microsoft.resources/deployments/stack-name')
        end
      end

      context 'when API fails' do
        it 'MIQ error is raised' do
          expect(client).to receive_message_chain(:resource_groups, :create_or_update).and_raise(ArgumentError)
          expect { subject.raw_update_stack(template, {}) }.to raise_error(MiqException::MiqOrchestrationUpdateError)
        end
      end
    end

    describe '.raw_delete_stack' do
      context 'when succeeds' do
        it 'properly constructs and invokes API' do
          expect(client).to receive_message_chain(:deployments, :delete) do |resource_group, name|
            expect(resource_group).to eq('resource-group')
            expect(name).to eq('stack-name')
          end
          subject.raw_delete_stack
        end
      end

      context 'when API fails' do
        it 'MIQ error is raised' do
          expect(client).to receive_message_chain(:deployments, :delete).and_raise(ArgumentError)
          expect { subject.raw_delete_stack }.to raise_error(MiqException::MiqOrchestrationDeleteError)
        end
      end
    end

    describe '.raw_status' do
      let(:deployment) { double('deployment', :properties => double(:provisioning_state => status)) }

      context 'when stack not exist' do
        it 'properly constructs and invokes API' do
          expect(client).to receive_message_chain(:deployments, :get).and_raise(
            MsRestAzure::AzureOperationError.new('msg').tap { |e| e.error_code = 'DeploymentNotFound' }
          )
          expect { subject.raw_status }.to raise_error(MiqException::MiqOrchestrationStackNotExistError)
        end
      end

      context 'when succeeds' do
        let(:status) { 'Succeeded' }
        it 'properly constructs and invokes API' do
          expect(client).to receive_message_chain(:deployments, :get).with('resource-group', 'stack-name').and_return(deployment)
          status = subject.raw_status
          expect(status).to have_attributes(:status => 'succeeded', :reason => 'OK')
        end
      end

      context 'when fails' do
        let(:status) { 'Failed' }
        let(:operation) do
          double(
            'operation',
            :properties => double(
              :provisioning_state => status,
              :status_message     => {
                'error' => {
                  'code'    => 'CODE',
                  'target'  => 'TARGET',
                  'message' => 'MESSAGE'
                }
              }
            )
          )
        end
        it 'properly constructs and invokes API' do
          expect(client).to receive_message_chain(:deployments, :get).with('resource-group', 'stack-name').and_return(deployment)
          expect(client).to receive_message_chain(:deployment_operations, :list).with('resource-group', 'stack-name').and_return([operation])
          status = subject.raw_status
          expect(status).to have_attributes(:status => 'failed', :reason => '[CODE][TARGET] MESSAGE')
        end
      end

      context 'when API fails' do
        it 'MIQ error is raised' do
          expect(client).to receive_message_chain(:deployments, :get).and_raise(ArgumentError)
          expect { subject.raw_status }.to raise_error(MiqException::MiqOrchestrationStatusError)
        end
      end
    end
  end
end
