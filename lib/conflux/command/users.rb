require 'conflux/command/abstract_command'
require_relative '../api/users'

class Conflux::Command::Users < Conflux::Command::AbstractCommand

  def index
    users = Conflux::Api::Users.new.for_team(@args[1])
    puts to_table(users, ['email', 'name', 'role'])
  end

  def add
    email = @args[0]
    team_slug = @args[2]

    Conflux::Api::Users.new.invite(email, team_slug)

    display "Successfully added #{email} to #{team_slug}."
  end

  #----------------------------------------------------------------------------

  module CommandInfo

    module Index
      DESCRIPTION = 'List users for one of your teams'
      VALID_ARGS = [ ['-t', 'TEAM'] ]
    end

    module Add
      DESCRIPTION = 'Add a user to a conflux team by email'
      VALID_ARGS = [ ['EMAIL', '-t', 'TEAM'] ]
    end

  end

end