# frozen_string_literal: true

RSpec.describe VisitsConsumer do
  subject(:consumer) { karafka.consumer_for(:attendance) }
  let(:attendances) do
    Array.new(2) do
      {
        id: SecureRandom.uuid,
        visited_at: Time.zone.now,
        visitor_id: visitor_id,
        page_path: '/'
      }
    end
  end

  # Publish two visits of one user
  before { visits.each { |visit| karafka.produce(visit.to_json) } }

  it 'expects to save the attendance' do
    expect { consumer.consume }.to change(Attendance, :count).by(attendance_events.count)
  end
end
