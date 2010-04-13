require File.dirname(__FILE__) + '/test_helper.rb'

class TestAsyncRedisModel < Test::Unit::TestCase

  def setup
  end
  
  def test_save
    Thread.new do
      EventMachine::run do
        AsyncRedisModel.client.flushdb do |resp|
          Person.include?("benlm") do |resp|
            assert !resp
            p = Person.new(:id => "benlm", :name => "Ben", :zip => 94107)
            assert_equal "Ben", p.name
            p.create do |resp|
              assert resp
              p2 = Person.new(:id => "benlm")
              p2.load do |resp|
                assert resp
                assert_equal "Ben", p2.name
                assert_equal 94107, p2.zip
                assert_equal nil, p2.age
                Person.include?("benlm") do |resp|
                  assert resp
                  EventMachine::stop_event_loop
                end
              end # p2.load
            end # p.create
          end # Person.include?
        end # flushdb
      end # EventMachine::run
    end.join
  end
  
  def test_indexes
    Thread.new do
      EventMachine::run do
        AsyncRedisModel.client.flushdb do |resp|
          p1 = Person.new(:id => "p1", :name => "Person 1", :zip => 94107)
          p1.create do |resp|
            p2 = Person.new(:id => "p2", :name => "Person 2", :zip => 94107)
            p2.create do |resp|
              p3 = Person.new(:id => "p3", :name => "Person 3", :zip => 94102)
              p3.create do |resp|
                Person.index_members(:zip, 94107) do |resp|
                  assert_equal ["p1", "p2"].sort, resp.sort
                  Person.index_members(:zip, 94102) do |resp|
                    assert_equal ["p3"], resp
                    Person.index_members(:zip, 94103) do |resp|
                      assert_equal [], resp
                      p2.destroy do |resp|
                        assert_equal true, resp
                        Person.index_members(:zip, 94107) do |resp|
                          assert_equal ["p1"], resp
                          p1.zip = 94101
                          p1.save do |resp| 
                            Person.index_members(:zip, 94107) do |resp| 
                              assert_equal [], resp
                              Person.index_members(:zip, 94101) do |resp|
                                assert_equal ["p1"], resp
                                Person.index(:zip, 94101).includes?("p1") do |resp|
                                  assert resp
                                  Person.index(:zip, 94101).includes?("p2") do |resp|
                                    assert !resp
                                    EventMachine::stop_event_loop
                                  end
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end # flushdb
      end # EventMachine::run
    end.join
  end
  
  # def test_performance
  #   Thread.new do
  #     count = 0
  #     EventMachine::run do
  #       AsyncRedisModel.client.flushdb do |resp|
  #         0.upto(999) do |i|
  #           p = Person.new
  #           p.id = "benlm#{i}"
  #           p.name = "Ben"
  #           p.zip = 94107
  #           assert_equal "Ben", p.name
  #           p.create do |resp|
  #             assert resp
  #             count += 1
  #             EventMachine::stop_event_loop if count == 1000
  #           end
  #         end # upto
  #       end # flushdb
  #     end # run
  #   end.join
  # end
  
end
