# NOT let DelayedJob re-attempt a failed job AND ALSO not let DJ delete failed jobs
#Delayed::Worker.destroy_failed_jobs = false
#Delayed::Worker.max_attempts = 1
#Delayed::Worker.delay_jobs = !Rails.env.test?