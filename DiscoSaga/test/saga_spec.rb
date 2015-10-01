require 'rspec'
require 'DiscoSaga'

RSpec.describe 'Saga' do

  it 'should capture all data' do
    s = DiscoSaga::Meta::Saga.new
    t1 = s.trigger :ev1
    t2 = s.trigger :ev2
    s.where t1.abc == t2.efg
    r = s.result :ev3 do |i|
      puts "hello"
    end
    s.where r.abc == t1.abc
    s.where r.efg == t2.efg
    expect(s.conditions.length).to eq(3)
  end
end

### source
class MySaga
  DiscoSaga::acts_as_saga do |s|
    t1 = s.trigger :ev1
    t2 = s.trigger :ev2
    s.where t1.abc == t2.efg

    r = s.result :ev3 do |i|
      evD = Event.index_one(:evD, :company, i.ev1.company)
      { name: i.ev1.name,
        address: i.ev2.address,
        ip: evD.ip }
    end
    s.job :mySagaJob do |job|
      Event.run! Cmd3.new
    end
    s.where r.abc == t1.abc
    s.where r.efg == t2.efg
  end

  ### generated code
=begin
  include EventHandler

  Event.create_index :ev1, :abc
  Event.create_index :ev2, :efg
  Event.create_index :ev3, :abc, :efg

  TriggerArg = Struct.new :ev1, :ev2

  handle :ev1 do |ev1|
    Event.index_all(:ev2, :efg, ev1.abc).each do |ev2|
      trigger_ev3(ev1, ev2)
    end
  end

  handle :ev2 do |ev2|
    Event.index_all(:ev1, :abc, ev2.efg).each do |ev1|
      trigger_ev3(ev1, ev2)
    end
  end

  def trigger_ev3(ev1, ev2)
    return if Event.index_exists :ev3, :abc_and_efg, ev1.abc, ev2.efg
    data = result.trigger.call(TriggerArg.new ev1, ev2)
    Jobs.run! :mySagaJob, data
  end

  after_job :mySagaJob do |job|
    Event.run! Cmd3.new
  end
=end

end



# meta stuff
=begin
def event ev
  store ev
  invoke ev
  sagas ev
end

def replay
  Events.each do |ev| invoke ev end
  Events.each do |ev| sagas ev end
end
=end
