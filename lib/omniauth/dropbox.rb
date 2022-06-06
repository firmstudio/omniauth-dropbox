# frozen_string_literal: true

require_relative "dropbox/version"
require_relative "strategies/dropbox"

module Omniauth
  module Dropbox
    class Error < StandardError; end
  end
end
