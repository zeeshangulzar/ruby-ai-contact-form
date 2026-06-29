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

    category = ContactClassifier.new(
      name:    @submission.name,
      email:   @submission.email,
      message: @submission.message
    ).classify

    @submission.category = category
    @submission.save!

    unless category == "spam"
      team_email = ContactRouter.team_email_for(category)
      ContactMailer.team_notification(@submission, team_email).deliver_now
      ContactMailer.auto_reply(@submission).deliver_now
    end

    redirect_to contact_path, notice: "Your message has been sent. We'll be in touch soon!"
  end

  private

  def submission_params
    params.require(:contact_submission).permit(:name, :email, :message)
  end
end
