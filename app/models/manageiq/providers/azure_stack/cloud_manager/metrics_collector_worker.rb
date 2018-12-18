class ManageIQ::Providers::AzureStack::CloudManager::MetricsCollectorWorker < ManageIQ::Providers::BaseManager::MetricsCollectorWorker
  require_nested :Runner

  self.default_queue_name = "azure_stack"

  def friendly_name
    @friendly_name ||= "C&U Metrics Collector for AzureStack"
  end
end
