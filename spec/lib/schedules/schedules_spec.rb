require 'rails_helper'

describe 'Scheduling' do
  let(:schedule) { Sidekiq.get_schedule('schedule') }

  before do
    Dir['lib/schedules/*.rb'].each { |file| require file.gsub('lib/', '') }

    Sidekiq.schedule = YAML.load_file('./schedule.yml')
  end

  it 'loads all the class names' do
    schedule.each do |cron_job_name, options|
      next if cron_job_name == 'class'
      expect { options['class'].constantize }.not_to raise_error
    end
  end
end
