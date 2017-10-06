
class Jenkins
  class << self
    def url
      "https://jenkins.#{$WORKSPACE_SETTINGS[:domain_name]}"
    end
  end
end
