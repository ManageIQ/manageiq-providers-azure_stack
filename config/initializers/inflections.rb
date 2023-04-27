# TODO: Revisit if we should rename these classes and change how we "locate" these constants
# See: https://github.com/ManageIQ/manageiq-providers-azure_stack/blob/6cd355f74ccaca8c503c5026d2974b808cf241eb/app/models/manageiq/providers/azure_stack/inventory.rb#L16
Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    'v2017_03_09' => "V2017_03_09",
    'v2018_03_01' => "V2018_03_01"
  )
end
