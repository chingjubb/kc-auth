module Kc
  module Common
    class PublicKeyResolverStub
      def initialize(public_key)
        @public_key = public_key
      end

      def find_public_keys(_realm_id = nil)
        @public_key
      end
    end
  end
end
