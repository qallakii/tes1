class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "noreply@crewitdrive.local")
  layout "mailer"
end
