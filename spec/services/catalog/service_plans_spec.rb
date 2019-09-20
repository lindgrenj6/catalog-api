describe Catalog::ServicePlans, :type => :service do
  let(:service_offering_ref) { "998" }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => service_offering_ref) }
  let(:params) { portfolio_item.id }
  let(:service_plans) { described_class.new(params) }

  before do
    allow(ManageIQ::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
  end

  around do |example|
    with_modified_env(:TOPOLOGICAL_INVENTORY_URL => "http://localhost") do
      example.call
    end
  end

  describe "#process" do
    let(:service_plan_response) { TopologicalInventoryApiClient::ServicePlansCollection.new(:data => data) }

    before do
      stub_request(:get, "http://localhost/api/topological-inventory/v1.0/service_offerings/998/service_plans")
        .to_return(:status => 200, :body => service_plan_response.to_json, :headers => default_headers)
    end

    context "when there are service plans based on the service offering" do
      let(:plan1) do
        TopologicalInventoryApiClient::ServicePlan.new(
          :name               => "Plan A",
          :id                 => "1",
          :description        => "Plan A",
          :create_json_schema => {}
        )
      end
      let(:plan2) do
        TopologicalInventoryApiClient::ServicePlan.new(
          :name               => "Plan B",
          :id                 => "2",
          :description        => "Plan B",
          :create_json_schema => {}
        )
      end
      let(:data) { [plan1, plan2] }

      it "fetches the array of plans" do
        expect(service_plans.process.items.count).to eq(2)
        expect(service_plans.process.items.first["name"]).to eq("Plan A")
      end
    end

    context "when there are no service plans based on the service offering" do
      let(:data) { [] }
      let(:items) { service_plans.process.items }

      it "returns an array with one object" do
        expect(items.count).to eq(1)
      end

      it "returns an array with one object with an ID of 'DNE'" do
        expect(items.first["id"]).to eq("DNE")
      end

      it "returns an array with one object with a service_offering_id" do
        expect(items.first["service_offering_id"]).to eq("998")
      end

      it "returns an array with one object with a relatively empty create_json_schema" do
        expect(items.first["create_json_schema"]).to eq("type" => "object", "properties" => {})
      end
    end

    context "invalid portfolio item" do
      let(:params) { 1 }
      let(:data) { [] }

      it "raises exception" do
        expect { service_plans.process }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
