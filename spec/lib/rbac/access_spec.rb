describe RBAC::Access do
  let(:app_name) { 'catalog' }
  let(:resource) { "portfolio" }
  let(:verb) { "read" }
  let(:attr_filter1) { double(:value => 25) }
  let(:attr_filter2) { double(:value => 26) }
  let(:attr_filter3) { double(:value => 27) }
  let(:resource_def1) { double(:attribute_filter => attr_filter1) }
  let(:resource_def2) { double(:attribute_filter => attr_filter2) }
  let(:resource_def3) { double(:attribute_filter => attr_filter3) }
  let(:access1) { double(:permission => "#{app_name}:#{resource}:read", :resource_definition => [resource_def1, resource_def3]) }
  let(:access2) { double(:permission => "#{app_name}:#{resource}:write", :resource_definition => [resource_def2]) }
  let(:access3) { double(:permission => "#{app_name}:#{resource}:order", :resource_definition => []) }
  let(:acls) { [access1, access2, access3] }

  let(:rbac_access) { described_class.new(resource, verb) }
  let(:api_instance) { double }
  let(:rs_class) { class_double("RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
  end

  it "fetches the array of plans" do
    with_modified_env :APP_NAME => app_name do
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :get_principal_access, {}, app_name).and_return(acls)
      svc_obj = rbac_access.process
      expect(svc_obj.acl.count).to eq(1)
      expect(svc_obj.accessible?).to be_truthy
      expect(svc_obj.id_list).to match_array([25, 27])
    end
  end
end
