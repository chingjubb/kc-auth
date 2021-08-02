RSpec.describe Kc::Auth::Context do
  let(:config)     { {} }
  let(:raw_token)  { "raw_jwt_token" }
  let(:env)        { {} }
  let(:claims)     { { iat: 1234, sub: "user_xyz", exp: 7980 } }

  before(:each) do
    @ctx = described_class.new(config, env, raw_token, claims)
  end

  describe "#context" do
    context "attributes" do
      it "should have the initial token claims" do
        expect(@ctx.attributes).to include(claims)
      end

      it "should raise an error if being overwritten" do
        expect do
          @ctx.attributes[:sub] = "user_abc"
        end.to raise_error(RuntimeError, "can't modify frozen Hash")
      end

      it "should allow adding more attributes" do
        val = Time.now
        @ctx.set_attr(:signed_in_at, val)
        expect(@ctx.attributes).to include({ signed_in_at: val })
      end
    end

    context "props" do
      it "can be mutated" do
        expect(@ctx.props).to be_empty
        val = Time.now
        @ctx.props[:current_time] = val
        expect(@ctx.props).to include({ current_time: val })
        new_val = val + 500
        @ctx.props[:current_time] = new_val
        expect(@ctx.props).to include({ current_time: new_val })
      end
    end
  end
end
