require 'rails_helper'

RSpec.describe ContactSubmission, type: :model do
  describe "validations" do
    it "is valid with all required fields" do
      expect(build(:contact_submission)).to be_valid
    end

    it "is invalid without a name" do
      expect(build(:contact_submission, name: nil)).not_to be_valid
    end

    it "is invalid with a malformed email" do
      expect(build(:contact_submission, email: "not-an-email")).not_to be_valid
    end

    it "is invalid when message is too short" do
      expect(build(:contact_submission, message: "Hi")).not_to be_valid
    end

    it "is invalid with an unknown category" do
      expect(build(:contact_submission, category: "unknown")).not_to be_valid
    end

    it "allows nil category" do
      expect(build(:contact_submission, category: nil)).to be_valid
    end
  end
end
