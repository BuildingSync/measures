require 'openstudio'

class ExportBuildingSync < OpenStudio::Ruleset::ReportingUserScript
  def name
    'Export BuildingSync XML'
  end

  # define the arguments that the user will input
  def arguments
    args = OpenStudio::Ruleset::OSArgumentVector.new

    args
  end

  # define what happens when the prototype-buildingsync is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments, user_arguments)

    runner.registerInfo 'Running BuildingSync XML exporter'

    true
  end
end

ExportBuildingSync.new.registerWithApplication
