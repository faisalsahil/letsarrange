Delayed::Job.scaler = case Rails.env
                      when 'development' then :local
                      when 'test' then :null
                      else
                        :heroku_cedar
                      end
Delayed::Worker.logger = Logger.new(Rails.root.join('log', 'delayed_job.log')) if Rails.env.development?