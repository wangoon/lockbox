require "forwardable"
require "dalli"

module Lockbox
  # don't extend Redis at the moment
  # so we can confirm operations are safe before adding
  class Dalli
    extend Forwardable
    def_delegators :@dalli, :delete, :flush, :flush_all

    # TODO add option to blind index keys
    def initialize(servers = nil, key: nil, algorithm: nil, encryption_key: nil, decryption_key: nil, padding: false, previous_versions: nil, **options)
      @lockbox = Lockbox.new(
        key: key,
        algorithm: algorithm,
        encryption_key: encryption_key,
        decryption_key: decryption_key,
        padding: padding,
        previous_versions: previous_versions
      )
      @dalli = ::Dalli::Client.new(servers, options)
    end

    def set(key, value, *args)
      @dalli.set(key, encrypt(value), *args)
    end

    def get(key, *args)
      decrypt(@dalli.get(key, *args))
    end

    def get_multi(*keys)
      @dalli.get_multi(*keys).transform_values { |v| decrypt(v) }
    end

    private

    def encrypt(value)
      value.nil? ? value : @lockbox.encrypt(value)
    end

    def decrypt(value)
      value.nil? || value.empty? ? value : @lockbox.decrypt(value)
    end
  end
end
