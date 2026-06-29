class ContactsController < ApplicationController
  def new
    @submission = ContactSubmission.new
  end

  def create
    @submission = ContactSubmission.new(submission_params)
    @submission.ip_address = request.remote_ip

    unless @submission.valid?
      render :new, status: :unprocessable_entity and return
    end

    result = ContactClassifier.new(
      name:    @submission.name,
      email:   @submission.email,
      message: @submission.message
    ).classify

    @submission.category = result[:category]
    @submission.urgent   = result[:urgent]
    @submission.save!

    unless result[:category] == "spam"
      team_email = ContactRouter.team_email_for(result[:category])
      DeliverMailJob.perform_later("ContactMailer", "team_notification", @submission.id, team_email)
      DeliverMailJob.perform_later("ContactMailer", "auto_reply", @submission.id)
    end

    redirect_to contact_path, notice: "Your message has been sent. We'll be in touch soon!"
  end

  private

  def submission_params
    params.require(:contact_submission).permit(:name, :email, :message)
  end
end
