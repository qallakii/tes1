class UserMailer < ApplicationMailer
  def invite_link(user, url)
    @user = user
    @url = url

    mail(to: @user.email, subject: "You're invited to CV Share")
  end

  def password_reset_link(user, url)
    @user = user
    @url = url

    mail(to: @user.email, subject: "Reset your CV Share password")
  end
end
