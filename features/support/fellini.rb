# Implementation of the Screenplay pattern, inspired by:
#
# * https://www.infoq.com/articles/Beyond-Page-Objects-Test-Automation-Serenity-Screenplay
# * http://serenity-js.org/
# * https://github.com/serenity-bdd/serenity-core/tree/master/serenity-screenplay

module Fellini
  class Actor
    def self.named(name)
      new(name)
    end

    def initialize(name)
      @name = name
      @abilities = {}
    end

    def can(do_something)
      @abilities[do_something.class] = do_something
      self
    end

    def attempts_to(*tasks)
      tasks.each do |task|
        task.perform_as(self)
      end
    end

    def to_s
      "#<#{self.class}:#{@name}>"
    end
  end

  class Ability
  end

  class Performable
    def perform_as(actor)
      raise "Implement #perform_as in #{self.class}"
    end
  end

  class Task < Performable
    def self.instrumented(klass, *arguments)
      klass.new(*arguments)
    end
  end

  class Interaction < Performable
    def self.instrumented(klass, *arguments)
      klass.new(*arguments)
    end
  end
end