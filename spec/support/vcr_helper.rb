def vcr_with_auth(casette)
  VCR.use_cassette('obtain_endpoints', :allow_unused_http_interactions => true) do
    VCR.use_cassette('obtain_token', :allow_playback_repeats => false, :allow_unused_http_interactions => true) do
      VCR.use_cassette(casette, :allow_unused_http_interactions => true) do
        yield
      end
    end
  end
end
