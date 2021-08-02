require_relative "../../lib/kc/auth"

RSpec.describe Kc::Auth do
  it "has a version number" do
    expect(Kc::Common::VERSION).not_to be nil
  end
end
