require "spec_helper"

describe OmniAuth::Strategies::Dropbox do
  subject do
    described_class.new({})
  end

  describe "production client options" do
    it { expect(subject.options.name).to eq("dropbox") }
    it { expect(subject.options.client_options.site).to eq("https://api.dropboxapi.com") }
    it { expect(subject.options.client_options.authorize_url).to eq("https://www.dropbox.com/oauth2/authorize") }
    it { expect(subject.options.client_options.token_url).to eq("https://api.dropboxapi.com/oauth2/token") }
  end

  describe "callback phase instance methods" do
    let(:uuid) { "dbid:AAC88SYYkeQCySGXL54IEmZ7osFTvkJTWaI" }
    let(:email) { "foo@example.com" }
    let(:response_params) { {"account_id" => uuid} }
    let(:account_response) { {"account_id" => uuid, "email" => email, "email_verified" => true} }
    let(:account_json) { double(:json, parsed: account_response) }
    let(:access_token) { double("AccessToken", params: response_params, get: account_json) }

    before do
      allow(subject).to receive(:access_token).and_return(access_token)
      allow(access_token).to receive(:post).and_return(account_json)
    end

    describe "#uid" do
      it "returns uuid from the info hash" do
        expect(subject.uid).to eq(uuid)
      end
    end

    describe "#extra" do
      it "includes the information returned from the account endpoint" do
        expect(subject.extra["email"]).to eq(email)
        expect(subject.extra["account_id"]).to eq(uuid)
        expect(subject.extra["email_verified"]).to eq(true)
      end
    end
  end
end
