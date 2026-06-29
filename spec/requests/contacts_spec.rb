require 'rails_helper'

RSpec.describe "Contacts", type: :request do
  describe "GET /contact" do
    it "renders the contact form" do
      get contact_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /contact" do
    let(:valid_params) do
      { contact_submission: { name: "Jane Smith", email: "jane@example.com", message: "I have a question about pricing." } }
    end

    let(:invalid_params) do
      { contact_submission: { name: "", email: "bad", message: "Hi" } }
    end

    context "with valid params" do
      before do
        allow_any_instance_of(ContactClassifier).to receive(:classify).and_return({ category: "sales", urgent: false })
        allow(DeliverMailJob).to receive(:perform_later)
      end

      it "saves the submission and redirects" do
        expect { post contact_path, params: valid_params }.to change(ContactSubmission, :count).by(1)
        expect(response).to redirect_to(contact_path)
      end

      it "sets the category from the classifier" do
        post contact_path, params: valid_params
        expect(ContactSubmission.last.category).to eq("sales")
      end

      it "sets the urgency from the classifier" do
        allow_any_instance_of(ContactClassifier).to receive(:classify).and_return({ category: "sales", urgent: true })
        post contact_path, params: valid_params
        expect(ContactSubmission.last.urgent).to be(true)
      end
    end

    context "with spam classification" do
      before do
        allow_any_instance_of(ContactClassifier).to receive(:classify).and_return({ category: "spam", urgent: false })
      end

      it "saves the submission but does not send emails" do
        expect(ContactMailer).not_to receive(:team_notification)
        expect(ContactMailer).not_to receive(:auto_reply)
        post contact_path, params: valid_params
      end
    end

    context "with invalid params" do
      it "re-renders the form with errors" do
        post contact_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
