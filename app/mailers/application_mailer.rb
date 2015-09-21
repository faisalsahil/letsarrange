class ApplicationMailer < ActionMailer::Base
  default from: "\"lets arrange\" <#{ ENV['MAIL_FROM'] }>"
end
