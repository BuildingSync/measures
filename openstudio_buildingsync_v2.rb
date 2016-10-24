

class SimpleElement
  attr_accessor :text, :children

  def text
    return @text
  end

  def attributes
    return @attributes
  end

  def children
    return @children
  end

  def specify_attributes
    @attributes = {}
  end

  def update_attributes; end

  def specify_children
    @children = {}
  end

  def update_children; end

  def initialize(args=nil)
    if(args.nil?)
      #do nothing, TODO: log the user supplied nothing
      self.text = nil
      update_attributes
      specify_children
    else
      self.text
      update_attributes
      #puts "initilizing...", args
      post_initialize(args)
    end
  end
  #initializes the simplest of elements with text that is passed in
  def post_initialize(args)
    begin
      specify_children()
      specify_attributes()
      if(!args.nil?)
        if(args.is_a?(Hash))
          if(args.has_key? :children)
            bulk_children(args[:children])
          end
          if(args.has_key? :attributes)
            #puts "Has attributes"
            args[:attributes].keys.each do |a|
              #puts "Writing attribute:", a
              @attributes[a] = args[:attributes][a] #TODO, this should have better error checking in it, like is a field required but is passed nil?
            end
          end
          if(args.has_key? :text)
            #puts "Added text", args[:text]
            @text = args[:text]
          else
            #TODO #put error that the proper hash keys were not identified.
          end
        end
      else
        #TODO give some indication that no arguments were provided
      end
      #TODO - make this active only on a boolean, possibly filter
      delete_unwanted_children()
    rescue => error
      puts "Could not create the BuildingSync element properly."
      puts error.inspect, error.backtrace
    end
  end


  def bulk_children(args)
    begin
      args.keys.each do |k|
       #puts "Working on " + k.to_s
       if k.to_s == "Schedules"
        #puts "Working on " + k.to_s
        #puts "Children", @children
        #puts "Full Arguments", args
      end
       
        if(args[k][:value].is_a?(Array))
          #puts "Value is an array"
          args[k][:value].each do |c|
            if k.to_s == "Delivery"
              #puts "Children: #{@children[k]}"
            end
            #puts "Starting to #put array for key #{k}:"
            #puts "Children: #{@children[k]}"
            @children[k][:value] << c
          end
        else
          if(@children.has_key? k)
            #puts "Has key"
            if(args[k][:value].is_a?(Array))
              type_match = true
              args[k][:value].each do |a|
                if(@children[k].has_key? :type)
                  #puts "Has key type"
                  if(a.class.name != @children[k][:type])
                    #puts "Type mismatch #{a.class.name} and #{@children[k][:type]}"
                    type_match = false
                    break
                  end
                else
                  if(a.class.name != k)
                    type_match = false
                    break
                  end
                end
              end #end loop
              if(type_match)
                @children[k][:value] = args[k][:value]
              else
                #TODO: #put something to alert user that they supplied the wrong class for children
              end
            else #it is an object
              #puts "Looking for an object."
              if(@children[k].has_key? :type)
                #puts 'a type for this object'
                #puts "Key #{k} Assiging value: ", args[k][:value]
                @children[k][:value] = args[k][:value]
                  # if(k === @children[k][:type]) #deprecated
                  #   #puts "Key #{k} Assiging value: ", args[k][:value]
                  #   @children[k][:value] = args[k][:value]
                  # end
              else
                #puts 'There is no additional type for this object.' + k.to_s
                #puts "Key #{k} Assiging value: ", args[k][:value]
                @children[k][:value] = args[k][:value]
              end
            end
          else
            raise "Could not find the child element: #{k} in all children #{@children.keys}"
          end
        end
      end #end of keys outer loop
    rescue => error
      puts error.inspect, error.backtrace
      puts "Problem bulking children"
    ensure

    end
  end

  #filter children that have nil or empty array
  def delete_unwanted_children
    @children.keys.each do |key|
      if(@children[key][:value].class.name === "Array")
        if(@children[key][:value].empty?)
          @children.tap { |hs| hs.delete(key) }
        end
      else
        if(@children[key][:value].nil?)
          @children.tap { |hs| hs.delete(key) }
        end
      end
    end
  end

end

class IDOnlyElement < SimpleElement
  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { required:true, value: nil }
  end
end

class EnumeratedElement < SimpleElement

  private 
  attr_writer :enums

  def specify_enums
    @enums = []
  end

  def post_initialize(args)
    begin
      specify_enums()
      if(@enums.include? args[:text])
        @text = args[:text]
      else
        #TODO: #put some type of warning to alert user unable to assign the text
        raise "Text defined for this #{self.class} enumeration is not valid.  #{args}  Check BuildingSync for valid enums."
      end
      delete_enums()
    rescue => error
      puts "Could not create the BuildingSync Enumerated element properly."
      puts error.inspect, error.backtrace
    end
  end

  def delete_enums
    @enums = []
  end


end

class ACAdjusted < EnumeratedElement
  def specify_enums
    @enums = ["During the day",
              "At night",
              "During sleeping and unoccupied hours",
              "Seasonal",
              "Never-rarely",
              "Other",
              "Unknown"]
  end
end

class AirCooled < SimpleElement
  def specify_children
    @children = {}
    @children[:EvaporativelyCooled] = { required: false, value: nil }
    @children[:CondensingFanSpeedOperation] = { required: false, value: nil }
    @children[:CondensingTemperature] = { required: false, value: nil }
    @children[:SplitCondenser] = { required: false, value: nil }
    @children[:DesignAmbientTemperature] = { required: false, value: nil }
    @children[:DesignTemperatureDifference] = { required: false, value: nil }
  end
end

class AnnualCoolingEfficiencyValue < SimpleElement; end
class AnnualCoolingEfficiencyUnits < EnumeratedElement
  def specify_enums
    @enums = ["COP",
        "EER",
        "SEER",
        "kW/ton",
        "Other"]
  end
end

class AirDeliveryType < EnumeratedElement
  def specify_enums
    @enums = ["Central fan",
              "Induction units",
              "Low pressure under floor",
              "Local fan",
              "Other",
              "Unknown"]
  end
end

class AirSideEconomizer < SimpleElement
  def specify_children 
    @children = {}
    @children[:AirSideEconomizerType] = { required: false, value: nil }
    @children[:EconomizerControl] = { required: false, value: nil }
    @children[:EconomizerDryBulbControlPoint] = { required: false, value: nil }
    @children[:EconomizerEnthalpyControlPoint] = { required: false, value: nil }
    #TODO: Add More as required
  end
end

class AirSideEconomizerType < EnumeratedElement
  def specify_enums
    @enums = ["Dry bulb temperature",
              "Enthalpy",
              "Demand controlled ventilation",
              "Nonintegrated",
              "Other",
              "Unknown"]

  end
end

class AnnualCoolingEfficiencyValue < SimpleElement; end

class AnnualCoolingEfficiencyUnits < EnumeratedElement
  def specify_enums
    @enums = ["COP",
              "EER",
              "SEER",
              "kW/ton",
              "Other"
    ]
  end
end

class AspectRatio < SimpleElement;end


class Audits < SimpleElement
  def specify_children
    @children = {}
    @children[:Audit] = { required: true,value: [] } 
  end
end


class Audit < SimpleElement
  def specify_children
    @children = {}
    @children[:Sites] = { required:false, value: nil }
    @children[:Systems] = { required:false, value: nil }
    @children[:Schedules] = { required:false, value: [] } #TODO: are the following really arrays?  Documentation is ambig.
    @children[:Measures] = { required:false, type: 'MeasureType', value: [] }
    @children[:Report] = { required:false, value: nil }
    @children[:Contacts] = { required:false, type: 'ContactType', value: [] }
  end

  def specify_attributes
    @attributes = {}
    @attributes = {"ID" => {value: nil} }
  end

end

class Boiler < SimpleElement
  def specify_children
    @children = {}
    @children[:BoilerType] = { required:false, value: nil }
    @children[:CondensingOperation] =  { required:false, value: nil }
    @children[:OutputCapacity] = { required:false, value: nil }
    @children[:ThermalEfficiency] = { required:false, value: nil }
    @children[:CapacityUnits] =  { required:false, value: nil }
    @children[:BoilerLWT] = { required:false, value: nil }
    @children[:HotWaterResetControl] = { required:false, value: nil }   
  end
end

class BoilerLWT < SimpleElement; end

class BoilerType < EnumeratedElement
  def specify_enums
    @enums = [ "Steam", "Hot water", "Other", "Unknown"]
  end
end

class CapacityUnits < EnumeratedElement
  def specify_enums
    @enums = ["cfh",
        "ft3/min",
        "kcf/h",
        "MCF/day",
        "gpm",
        "W",
        "kW",
        "hp",
        "MW",
        "Btu/hr",
        "cal/h",
        "ft-lbf/h",
        "ft-lbf/min",
        "Btu/s",
        "kBtu/hr",
        "MMBtu/hr",
        "therms/h",
        "lbs/h",
        "Klbs/h",
        "Mlbs/h",
        "Cooling ton",
        "Other"
    ]
  end
end

class CeilingArea < SimpleElement; end
class CeilingInsulatedArea < SimpleElement; end

class CeilingID < SimpleElement
  def specify_children 
    @children = {}
    @children[:CeilingArea] = { required:false, value: nil }
    @children[:CeilingInsulatedArea] = { required:false, value: nil }
    @children[:ThermalZoneID] = { required:false, value: nil }
    @children[:SpaceID] = { required:false, value: nil }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { required:true, text: nil }
  end

end

class CeilingSystems < SimpleElement
  def specify_children
    @children = {}
    @children[:CeilingSystem] = { required:false, type:  "CeilingSystemType", value: [] }
  end
end

class CeilingSystemType < SimpleElement
  def specify_children
    @children = {}
    @children[:CeilingConstruction] = { required: false, type: "CeilingConstructionType",value: nil }
    @children[:CeilingFinish] = { required: false, value: nil }
    @children[:CeilingColor] = { required: false, value: nil }
    @children[:CeilingInsulation] = { required: false, value:  [] }
    @children[:CeilingRValue] = { required: false, value: nil }
    @children[:CeilingUFactor] = { required: false, value: nil }
    @children[:CeilingFramingMaterial] = { required: false, value: nil }
    @children[:CeilingFramingSpacing] = { required: false, value: nil }
    @children[:CeilingFramingDepth] = { required: false, value: nil }
    @children[:CeilingFramingFactor] = { required: false, value: nil }
    @children[:CeilingVisibleAbsorbtance] = { required: false, value: nil }
    @children[:Quantity] = { required: false, value: nil }
    @children[:YearInstalled] = { required: false, value: nil }
    #@children[:UserDefinedFields] = { required: false, value: nil }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:ID] = { required:false, text: nil }
  end
end

class CentralAirDistribution < SimpleElement
  def specify_children
    @children={}
    @children[:AirDeliveryType] = { required: false, value: nil }
    @children[:TerminalUnit] = { required: false, value: nil }
    @children[:ReheatSource] = { required: false, value: nil }
    @children[:ReheatPlantID] = { required: false, value: nil }
    #TODO add ReheatControlMethod
  end
end

class ChilledWaterSupplyTemperature < SimpleElement; end

class Chiller < SimpleElement
  def specify_children
    @children={}
    @children[:ChillerType] = { required: false, value: nil }
    @children[:ChillerCompressorDriver] = { required: false, value: nil }
    @children[:CondenserPlantIDs] = { required: false, value: nil }
    @children[:AnnualCoolingEfficiencyValue] = { required: false, value: nil }
    @children[:AnnualCoolingEfficiencyUnits] = { required: false, value: nil }
    @children[:ChilledWaterSupplyTemperature] = { required: false, value: nil }
    @children[:Quantity] = { required: false, value: nil }
  end
end

class ChillerCompressorDriver < EnumeratedElement
  def specify_enums
    @enums = ["Electric Motor",
              "Steam",
              "Gas Turbine",
              "Other",
              "Unknown"
    ]
  end
end

class ChillerType < EnumeratedElement
  def specify_enums
    @enums = ["Vapor compression",
              "Absorption",
              "Other",
              "Unknown"
    ]
  end
end

class CompressorStaging < EnumeratedElement
  def specify_enums
    @enums = ["Single stage",
        "Multiple discrete stages",
        "Variable",
        "Modulating",
        "Other",
        "Unknown"]
  end
end

class CondenserPlantID < SimpleElement
  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { required:false, text: nil }
  end
end

class CondenserPlantIDs < SimpleElement
  def specify_children
    @children = {}
    @children[:CondenserPlantID] = { required: false, value: [] }
  end
end

class CondenserPlantType < SimpleElement
  def specify_children
    @children = {}
    @children[:AirCooled] = { required: false, value: nil }
    @children[:WaterCooled] = { required: false, value: nil }
    @children[:GroundSource] = { required: false, value: nil }
    @children[:GlycolCooledDryCooler] = { required: false, value: nil }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:ID] = { required:false, text: nil }
  end
end

class CondensingOperation < SimpleElement; end

class CondensingTemperature < SimpleElement; end
class CondenserWaterTemperature < SimpleElement; end


class ConditionedVolume < SimpleElement; end

class CoolingDeliveryID < SimpleElement
  def specify_attributes
    @attributes = {}
    @attributes[:ID] = { required: false, value: nil }
  end

end

class CoolingPlantType < SimpleElement
  def specify_children
    @children = {}
    @children[:Chiller] = { required: false, value:[]}
  end
end

class CoolingSource < SimpleElement
  def specify_children
    @children={}
    @children[:CoolingSourceType] = { required: false, value: nil }
    @children[:CoolingMedium] = { required: false, value: nil }
    @children[:PrimaryFuel] = { required: false, type:"FuelTypes", value: nil }
    @children[:AnnualCoolingEfficiencyValue] = { required: false, value: nil }
    @children[:AnnualCoolingEfficiencyUnits] = { required: false, value: nil }
  end

  def specify_attributes
    @attributes={}
    @attributes[:ID] = { required: false, value: nil }
  end
end

class CoolingSourceType < SimpleElement
  def specify_children
    @children={}
    @children[:CoolingPlantID] = { required: false, value: nil }
    @children[:DX] = { required: false, value: nil }
    #TODO: Add more as required
  end
end

class CoolingPlantID < SimpleElement
  def specify_attributes
    @attributes = {}
    @attributes[:ID] = { required: false, value: nil }
  end
end

class CoolingMedium < EnumeratedElement
  def specify_enums
    @enums = ["Chilled water",
              "Refrigerant",
              "Air",
              "Glycol",
              "Other",
              "Unknown"]
  end
end

class DaylightingIlluminanceSetpoint < SimpleElement; end
class DaylitFloorArea < SimpleElement; end

class DayStartTime < SimpleElement; end
class DayEndTime < SimpleElement; end

class DayType < EnumeratedElement
  def specify_enums
    @enums = ["AllWeek",
              "Weekday",
              "Weekend",
              "Saturday",
              "Sunday",
              "Holiday",
              "Monday",
              "Tuesday",
              "Wednesday",
              "Thursday",
              "Friday"]
  end
end

class Delivery < SimpleElement
  def specify_children
    @children={}
    @children[:DeliveryType] ={ required: false, value: nil }
    @children[:HeatingSourceID] = { required: false, value: nil }
    @children[:CoolingSourceID] = { required: false, value: nil }
    @children[:Quantity] = { required: false, value: nil }
  end
  def specify_attributes
    @attributes={}
    @attributes[:ID] = { required: false, value: nil }
  end
end

class DeliveryType < SimpleElement
  def specify_children
    @children= {}
    @children[:FanBased] = { required: false, value: nil }
    #TODO: Add more as required
  end
end




class HeatingSourceID < IDOnlyElement; end
class CoolingSourceID < IDOnlyElement; end

class DoorID < SimpleElement 
  def specify_children
    @children = {}
    @children[:FenestrationArea] = { required: false, value: nil }
  end

  def specify_attributes 
    @attributes = {}
    @attributes[:IDref] = { required:true, text: nil }
  end
end

class DeliveryID < IDOnlyElement; end

class DesignStaticPressure < SimpleElement; end
class DuctSystems < SimpleElement
  def specify_children
    @children = {}
    @children[:DuctSystem] = { required: false, type:"DuctSystemType", value:[] } #TODO: this is DuctSystems in the XSD, is that correct?
  end
end

class DuctSystemType < SimpleElement
  def specify_children
    @children = {}
    @children[:Quantity] = { required: false, value: nil }
    @children[:HeatingDeliveryID] = { required: false, value: nil }
    @children[:CoolingDeliveryID] = { required: false, value: nil }
    @children[:Location] = { required: false, value: nil }
    @children[:LinkedPremises] = { required: false, value: nil }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:ID] = { required: false, text: nil}
  end
end

class DX < SimpleElement 
  def specify_children
    @children = {}
    @children[:DXSystemType] = { required: false, value: nil }
    @children[:CompressorStaging] = { required: false, value: nil }
    @children[:CondenserPlantID] = { required: false, value: nil }
  end
end

class DXSystemType < EnumeratedElement
  def specify_enums
    @enums = ["Split DX air conditioner",
              "Packaged terminal air conditioner (PTAC)",
              "Split heat pump",
              "Packaged terminal heat pump (PTHP)",
              "Variable refrigerant flow",
              "Packaged/unitary direct expansion/RTU",
              "Packaged/unitary heat pump",
              "Single package vertical air conditioner",
              "Single package vertical heat pump",
              "Other",
              "Unknown"]
  end
end

class EconomizerControl < EnumeratedElement
  def specify_enums
    @enums = ["Fixed",
              "Differential",
              "Other",
              "Unknown"]
  end
end

class EconomizerDryBulbControlPoint < SimpleElement; end
class EconomizerEnthalpyControlPoint < SimpleElement; end

class Facilities < SimpleElement
  #initialize the Facility Children with a simple type or array
  def specify_children
    @children = {}
    @children[:Facility] = { required:true,type: 'FacilityType',value: [] }
  end  
end

class FacilityClassification < EnumeratedElement
  def specify_enums
    @enums = ["Commercial",
              "Residential",
              "Mixed use commercial",
              "Other"]
  end
end

class FacilityType < SimpleElement

    def specify_children
      @children = {}
      @children[:PremisesName] = { required:false,value: nil }
      @children[:PremisesNotes] = { required:false,value: nil } 
      @children[:PremisesName] = { required:false,value: nil } 
      @children[:PremisesIdentifiers] = { required:false,value: nil } 
      @children[:FacilityClassification] = { required:false,value: nil } 
      @children[:OccupancyClassification] = { required:false,value: nil } 
      @children[:OccupancyLevels] = { required:false,value: nil } 
      @children[:SpatialUnits] = { required:false,value: [] } 
      @children[:Ownership] = { required:false,value: nil } 
      @children[:OwnershipStatus] = { required:false,value: nil } 
      @children[:PrimaryContactID] = { required:false,value: nil } 
      @children[:PubliclySubsidize] = { required:false,value: nil } 
      @children[:FederalBuilding] = { required:false,value: nil } 
      @children[:PortfolioManager] = { required:false,value: nil } 
      @children[:NumberOfBusinesses] = { required:false,value: nil } 
      @children[:FloorsAboveGrade] = { required:false,value: nil } 
      @children[:FloorsBelowGrade] = { required:false,value: nil } 
      @children[:FloorAreas] = { required:false,value: [] } 
      @children[:AspectRatio] = { required:false,value: nil } 
      @children[:Perimeter] = { required:false,value: nil } 
      @children[:HeightDistribution] = { required:false,value: nil } 
      @children[:HorizontalSurroundings] = { required:false,value: nil }
      @children[:VerticalSurroundings] = { required:false,value: nil }  
      @children[:Assessment] = { required:false,value: nil } 
      @children[:YearOfConstruction] = { required:false,value: nil } 
      @children[:YearOccupied] = { required:false,value: nil } 
      @children[:YearOfLastEnergyAudit] = { required:false,value: nil } 
      @children[:RetrocommissioningDate] = { required:false,value: nil } 
      @children[:YearOfLastRetrofit] = { required:false,value: nil } 
      @children[:YearOfLastMajorRemodel] = { required:false,value: nil } 
      @children[:PercentOccupiedByOwner] = { required:false,value: nil } 
      @children[:OperatorType] = { required:false,value: nil } 
      @children[:Subsections] = { required:false,value: [] } 
      @children[:UserDefinedFields] = { required:false,value: [] } 
    end 

end

class FanBased < SimpleElement
  def specify_children
    @children = {}
    @children[:FanBasedDistributionType] = { required: false, value: nil }
    @children[:AirSideEconomizer] = { required: false, value: nil }
  end
end

class FanBasedDistributionType < SimpleElement
  def specify_children
    @children = {}
    @children[:CentralAirDistribution] = { required: false, value: nil }
    #TODO: Add more as required
  end
end

class FanApplication < EnumeratedElement
  def specify_enums
    @enums = ["Supply",
            "Return",
            "Exhaust",
            "Other",
            "Unknown"]
  end
end

class FanControlType < EnumeratedElement
  def specify_enums
    @enums = ["Variable Volume",
              "Stepped",
              "Constant Volume",
              "Other",
              "Unknown"]
  end
end

class FanEfficiency < SimpleElement; end

class FanPlacement < EnumeratedElement 
  def specify_enums
    @enums = ["Series",
              "Parallel",
              "Draw Through",
              "Blow Through",
              "Other",
              "Unknown"]
  end
end

class FanPowerMinimumRatio < SimpleElement; end

class FanSystemType < SimpleElement
  def specify_children
    @children = {}
    @children[:FanEfficiency] = { required: false, value: nil }
    @children[:DesignStaticPressure] = { required: false, value: nil }
    @children[:FanApplication] = { required: false, value: nil }
    @children[:FanControlType] = { required: false, value: nil }
    @children[:FanPowerMinimumRatio] = { required: false, value: nil }
    @children[:MotorLocationRelativeToAirStream] = { required: false, value: nil }
    @children[:FanPlacement] = { required: false, value: nil }
    @children[:Quantity] = { required: false, value: nil }
    @children[:Location] = { required: false, value: nil }
    @children[:LinkedSystemID] = { required: false, value: nil }
    #TODO: Add more children as required.
  end
  def specify_attributes
    @attributes = {}
    @attributes[:ID] = { required:false, text: nil }
  end
end

class FanSystems < SimpleElement
  def specify_children
    @children = {}
    @children[:FanSystem] = { required: false, type:"FanSystemType", value: [] }
  end
end

class FenestrationArea < SimpleElement; end

class FenestrationSystems < SimpleElement
  def specify_children
    @children = {}
    @children[:FenestrationSystem] = { required:false, type: "FenestrationSystemType",value: [] }
  end
end

class FenestrationSystemType < SimpleElement
  def specify_children
    @children = {}
    @children[:FenestrationType] = { required:false,value: nil } 
    @children[:FenestrationFrameMaterial] = { required:false,value: nil } 
    @children[:FenestrationOperation] = { required:false,value: nil } 
    @children[:WeatherStripped] = { required:false,value: nil } #bool
    @children[:TightnessFitCondition] = { required:false,value: nil } 
    @children[:GlassType] = { required:false,value: nil } 
    @children[:FenestrationGasFill] = { required:false,value: nil } 
    @children[:FenestrationGlassLayers] = { required:false,value: nil } 
    @children[:FenestrationRValue] = { required:false,value: nil } 
    @children[:FenestrationUFactor] = { required:false,value: nil } 
    @children[:SolarHeatGainCoefficient] = { required:false,value: nil }
    @children[:VisibleTransmittance] = { required:false,value: nil }  
    @children[:ThirdPartyCertification] = { required:false,value: nil } 
    @children[:Quantity] = { required:false,value: nil } 
    @children[:YearInstalled] = { required:false,value: nil } 
    @children[:Manufacturer] = { required:false,value: nil } 
    @children[:ModelNumber] = { required:false,value: nil } 
    #@children[:UserDefinedFields] = { required:false,value: nil } 
  end

  def specify_attributes
    @attributes = {}
    @attributes[:ID] = { required:false, text: nil }
    @attributes[:Status] = { required:false, text: nil }
  end
end

class FloorAreas < SimpleElement
  def specify_children
    @children = {}
    @children[:FloorArea] = { required:false, value: [] }
  end
end

class FloorArea < SimpleElement
  def specify_children
    @children = {}
    @children[:FloorAreaType] = { required:false, value: nil }
    @children[:FloorAreaCustomName] = { required:false, value: nil }
    @children[:FloorAreaValue] = { required:false, value: nil }
    @children[:Story] = { required:false, value: nil }
  end
end

class FloorAreaCustomName < SimpleElement; end
class FloorAreaValue < SimpleElement; end

class FloorAreaType < EnumeratedElement
  def specify_enums
    @enums = ["Gross",
              "Net",
              "Finished",
              "Footprint",
              "Rentable",
              "Occupied",
              "Lighted",
              "Daylit",
              "Heated",
              "Cooled",
              "Conditioned",
              "Unconditioned",
              "Semi-conditioned",
              "Heated and Cooled",
              "Heated only",
              "Cooled only",
              "Ventilated",
              "Enclosed",
              "Non-Enclosed",
              "Open",
              "Lot",
              "Custom"]
  end
end

class FloorToFloorHeight < SimpleElement; end
class FloorToCeilingHeight < SimpleElement; end
class FloorsAboveGrade < SimpleElement; end
class FloorsBelowGrade < SimpleElement; end
class FloorsPartiallyBelowGrade < SimpleElement; end

class FootprintShape < EnumeratedElement
  def specify_enums
    @enums = ["Rectangular",
              "L-Shape",
              "U-Shape",
              "H-Shape",
              "T-Shape",
              "O-Shape",
              "Other",
              "Unknown"
    ]
  end
end

class FoundationArea < SimpleElement; end

class FoundationID < SimpleElement
  def specify_children 
    @children = {}
    @children[:FoundationArea] = { required:false, value: nil }
    @children[:ThermalZoneID] = { required:false, value: nil }
    @children[:SpaceID] = { required:false, value: nil }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { required:true, text: nil }
  end

end

class FoundationSystems < SimpleElement 
  def specify_children 
    @children = {}
    @children[:FoundationSystem] = { required:false, type:  "FoundationSystemType",value: [] }
  end
end

class FoundationSystemType < SimpleElement
  def specify_children
    @children = {}
    @children[:GroundCoupling] = { required:true, value:  [] }
    @children[:FloorCovering] = { required:true, value: nil }
    @children[:FloorConstructionType] = { required:true, type:  "EnvelopeConstructionType",value: nil }
    @children[:PlumbingPenetrationSealing] = { required:true, value: nil }
    @children[:YearInstalled] = { required:true, value: nil }
    @children[:Quantity] = { required:true, value: nil }
    #@children[:UserDefinedFields] = { required:true, value: nil }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:ID] = { required:false, text: nil }
    @attributes[:Status] = { required:false, text: nil }
  end
end

class FuelTypes < EnumeratedElement
  def specify_enums
    @enums = ["Electricity",
      "Natural gas",
      "Fuel oil",
      "Fuel oil no 1",
      "Fuel oil no 2",
      "Fuel oil no 4",
      "Fuel oil no 5 and no 6",
      "District steam",
      "District hot water",
      "District chilled water",
      "Propane",
      "Liquid propane",
      "Kerosene",
      "Diesel",
      "Coal",
      "Coal anthracite",
      "Coal bituminous",
      "Coke",
      "Wood",
      "Wood pellets",
      "Hydropower",
      "Biofuel",
      "Wind",
      "Geothermal",
      "Solar",
      "Biomass",
      "Hydrothermal",
      "Dry steam",
      "Flash steam",
      "Ethanol",
      "Biodiesel",
      "Waste heat",
      "Other",
      "Unknown"]
  end
end

class Furnace < SimpleElement
  def specify_children
    @children = {}
  end
  def specify_attributes 
    @children = {}
  end
end

class HeatLowered < SimpleElement; end

class HeatingAndCoolingSystems < SimpleElement
  def specify_children
    @children={}
    @children[:ZoningSystemType] = { required: false, value: nil}
    @children[:HeatingSource] = { required: false, value: [] }
    @children[:CoolingSource] = { required: false, value: [] }
    @children[:Delivery] = { required: false, value: [] }
    #TODO: add more as necessary
  end
end

class HeatPump < SimpleElement
  def specify_children
    @children = {}
    @children[:HeatPumpType] = { required: false, value: nil }
    @children[:HeatPumpBackupHeatingSwitchoverTemperature] = { required: false, value: nil }
    @children[:HeatPumpBackupSystemFuel] = { required: false, value: nil }
    @children[:HeatPumpBackupAFUE] = { required: false, value: nil }
  end
end

class HeatPumpBackupAFUE < SimpleElement; end

class HeatPumpBackupHeatingSwitchoverTemperature < SimpleElement; end

class HeatPumpBackupSystemFuel < EnumeratedElement
  def specify_enums
    @enums = [] #TODO, this is currently undefined in the XSD
  end
end

class HeatPumpType < EnumeratedElement
  def specify_enums
    @enums = ["Split",
              "Packaged Terminal",
              "Packaged Unitary",
              "Other",
              "Unknown"]
  end
end

class HeatingSource < SimpleElement
  def specify_children
    @children={}
    @children[:HeatingSourceType] = { required: false, value: nil }
    @children[:HeatingMedium] = { required: false, value: nil}
    @children[:PrimaryFuel] = { required: false, type:"FuelTypes", value: nil}
    @children[:Quantity] = { required: false, value: nil}
    #TODO: Add others as necessary
  end
end

class HeatingSourceType < SimpleElement
  def specify_children
    @children = {}
    @children[:SourceHeatingPlantID] = { required: false, value: nil}
    @children[:Furnace] = { required: false, value: nil }
    @children[:HeatPump] = { required: false, value: nil }
    @children[:OtherCombination] = { required: false, value: nil }
    #TODO: Add more as needed
  end
end

class HeatingMedium < EnumeratedElement
  def specify_enums
    @enums = ["Hot water",
              "Steam",
              "Refrigerant",
              "Air",
              "Glycol",
              "Other",
              "Unknown"]
  end
end

class HeatingDeliveryID < IDOnlyElement; end

class HeatingPlantType < SimpleElement 
  def specify_children
    @children = {}
    @children[:Boiler] = { required: false, value:nil }
    #TODO, add more children elements as required
  end

  def specify_attributes
    @attributes = {}
    @attributes[:ID] = { required: false, text: nil}
  end
end

class HotWaterResetControl < EnumeratedElement
  def specify_enums
    @enums = ["During the day",
              "At night",
              "During sleeping and unoccupied hours",
              "Seasonal",
              "Never-rarely",
              "Other",
              "Unknown"
    ]
  end
end

class HVACScheduleID < IDOnlyElement; end

class HVACSystems < SimpleElement
  def specify_children
    @children = {}
    @children[:HVACSystem] = { required: false, type:"HVACSystemType", value: [] }
  end
end

class HVACSystemType < SimpleElement
  def specify_children
    @children = {}
    @children[:Plants] = { required: false, value: nil }
    @children[:HeatingAndCoolingSystems] = { required: false, value: nil }
    @children[:DuctSystems] = { required: false, value: nil }
    @children[:OtherHVACSystems] = { required: false, value: nil }
    #TODO: Add other children as needed
  end
  def specify_attributes
    @attributes = {}
    @attributes[:ID] = { require: false, text: nil } 
  end
end

class InstalledPower < SimpleElement; end

class LightingSystems < SimpleElement
  def specify_children
    @children = {}
    @children[:LightingSystem] = { required: false, type:"LightingSystemType", value: [] }
  end
end

class LightingSystemType < SimpleElement
  def specify_children
    @children = {}
    @children[:InstalledPower] = { required: false, value: nil }
    @children[:LinkedPremises] = { required: false, value: nil }
    @children[:Location] = { required: false, value: nil}
    #TODO: add more fields as required
  end
  def specify_attributes
    @attributes = {}
  end

end

class LinkedSpaceID < SimpleElement
  def specify_children
    @children = {}
    @children[:LinkedScheduleID] = { required: false, value: [] } #TODO: Investigate
  end
  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { required: true, text: nil }
  end
end

class LinkedScheduleID < IDOnlyElement; end

class LinkedSystemID < IDOnlyElement; end

class LinkedThermalZoneID < IDOnlyElement; end

class LinkedPremises < SimpleElement
  def specify_children
    @children = {}
    @children[:Space] = { required: false, value: nil }
    @children[:ThermalZone] = { required: false, value: nil }
    #TODO - add more fields as required
  end
end

class Location < EnumeratedElement
  def specify_enums
    @enums = ["Interior",
              "Exterior",
              "Closet",
              "Garage",
              "Attic",
              "Other",
              "Unknown"
    ]
  end
end

class Longitude < SimpleElement; end
class Latitude < SimpleElement; end

class MotorLocationRelativeToAirStream < SimpleElement; end

class SlabArea < SimpleElement; end

class OccupancyLevels < SimpleElement
    
    def specify_children 
      @children = {}
      @children[:OccupancyLevel] = { required: false, value: nil }
    end

end

class OccupancyLevel < SimpleElement

    def specify_children
      @children = {}
      @children[:OccupantType] = { required:false, value: nil }
      @children[:OccupantQuantityType] = { required:false, value: nil }
      @children[:OccupantQuantity] = { required:false, value: nil }
    end

end

class OccupantType < EnumeratedElement
  def specify_enums
    @enums = ["Family household",
              "Married couple, no children",
              "Male householder, no spouse",
              "Female householder, no spouse",
              "Cooperative household",
              "Nonfamily household",
              "Single male",
              "Single female",
              "Student community",
              "Military community",
              "Independent seniors community",
              "Special accessibility needs community",
              "Government subsidized community",
              "Therapeutic community",
              "No specific occupant type",
              "For-profit organization",
              "Religious organization",
              "Non-profit organization",
              "Government organization",
              "Federal government",
              "State government",
              "Local government",
              "Property",
              "Animals",
              "Other",
              "Vacant",
              "Unknown"]
  end
end

class OccupantQuantityType < EnumeratedElement
  def specify_enums
    @enums = ["Peak total occupants",
              "Adults",
              "Children",
              "Average residents",
              "Workers on main shift",
              "Full-time equivalent workers",
              "Average daily salaried labor hours",
              "Registered students",
              "Staffed beds",
              "Licensed beds",
              "Capacity",
              "Capacity percentage"]
  end
end

class OccupancyClassification < EnumeratedElement
  def specify_enums
    @enums = ["Manufactured home",
                  "Single family",
                  "Multifamily",
                  "Multifamily with commercial",
                  "Multifamily individual unit",
                  "Residential",
                  "Health care-Pharmacy",
                  "Health care-Skilled nursing facility",
                  "Health care-Residential treatment center",
                  "Health care-Inpatient hospital",
                  "Health care-Outpatient rehabilitation",
                  "Health care-Diagnostic center",
                  "Health care-Outpatient non-diagnostic",
                  "Health care-Outpatient surgical",
                  "Health care-Veterinary",
                  "Health care-Morgue or mortuary",
                  "Health care",
                  "Gas station",
                  "Convenience store",
                  "Food sales-Grocery store",
                  "Food sales",
                  "Laboratory-Testing",
                  "Laboratory-Medical",
                  "Laboratory",
                  "Vivarium",
                  "Office",
                  "Bank",
                  "Courthouse",
                  "Public safety station",
                  "Public safety-Detention center",
                  "Public safety-Correctional facility",
                  "Public safety",
                  "Warehouse-Refrigerated",
                  "Warehouse-Unrefrigerated",
                  "Warehouse-Self-storage",
                  "Warehouse",
                  "Assembly-Religious",
                  "Assembly-Cultural entertainment",
                  "Assembly-Social entertainment",
                  "Assembly-Arcade or casino without lodging",
                  "Assembly-Convention center",
                  "Assembly-Stadium",
                  "Assembly-Public",
                  "Recreation-Pool",
                  "Recreation-Fitness center",
                  "Recreation-Ice rink",
                  "Recreation-Indoor sport",
                  "Recreation",
                  "Education-Higher",
                  "Education-Secondary",
                  "Education-Primary",
                  "Education-Preschool or daycare",
                  "Education",
                  "Food service-Fast",
                  "Food service-Full",
                  "Food service-Limited",
                  "Food service-Institutional",
                  "Food service",
                  "Lodging-Institutional",
                  "Lodging with extended amenities",
                  "Lodging with limited amenities",
                  "Lodging",
                  "Retail-Mall",
                  "Retail-Strip mall",
                  "Retail-Enclosed mall",
                  "Retail-Dry goods retail",
                  "Retail-Hypermarket",
                  "Retail",
                  "Service-Postal",
                  "Service-Repair",
                  "Service-Laundry or dry cleaning",
                  "Service-Studio",
                  "Service-Beauty and health",
                  "Service-Production and assembly",
                  "Service",
                  "Transportation terminal",
                  "Central Plant",
                  "Water treatment-Wastewater",
                  "Water treatment-Drinking water and distribution",
                  "Water treatment",
                  "Energy generation plant",
                  "Industrial manufacturing plant",
                  "Utility",
                  "Industrial",
                  "Agricultural estate",
                  "Mixed-use commercial",
                  "Parking",
                  "Attic",
                  "Basement",
                  "Dining area",
                  "Living area",
                  "Sleeping area",
                  "Laundry area",
                  "Lodging area",
                  "Dressing area",
                  "Restroom",
                  "Auditorium",
                  "Classroom",
                  "Day room",
                  "Sport play area",
                  "Stage",
                  "Spectator area",
                  "Office work area",
                  "Non-office work area",
                  "Common area",
                  "Reception area",
                  "Waiting area",
                  "Transportation waiting area",
                  "Lobby",
                  "Conference room",
                  "Computer lab",
                  "Data center",
                  "Printing room",
                  "Media center",
                  "Telephone data entry",
                  "Darkroom",
                  "Courtroom",
                  "Kitchen",
                  "Kitchenette",
                  "Refrigerated storage",
                  "Bar",
                  "Dance floor",
                  "Security room",
                  "Shipping and receiving",
                  "Mechanical room",
                  "Chemical storage room",
                  "Non-chemical storage room",
                  "Janitorial closet",
                  "Vault",
                  "Corridor",
                  "Deck",
                  "Courtyard",
                  "Atrium",
                  "Other",
                  "Unknown"]
  end
end

class OccupantQuantity < SimpleElement; end

class OccupantsActivityLevel < EnumeratedElement 
  def specify_enums
    @enums = ["Low","High","Unknown"]
  end
end

class OtherCombination < SimpleElement; end
class OutputCapacity < SimpleElement; end
class PartialOperationPercentage < SimpleElement; end
class PercentageOfCommonSpace < SimpleElement; end
class PercentOfWindowAreaShaded < SimpleElement; end
class PerimeterZoneDepth < SimpleElement; end
class PremisesName < SimpleElement; end
class PremisesNotes < SimpleElement; end
class PremisesIdentifiers < SimpleElement; end

class Plants < SimpleElement
  def specify_children
    @children = {}
    @children[:HeatingPlantType] = { required: false, value:[] }
    @children[:CoolingPlantType] = { required: false, value:[] }
    @children[:CondenserPlant] = { required: false, type:"CondenserPlantType", value:[] }
  end

end

class PlugLoad < SimpleElement #should this be plugloadtype
  def specify_children
    @children = {}
    @children[:PlugLoadType] = { required:false, value: nil }
    @children[:PlugLoadNominalPower] = { required: false, value: nil }
    @children[:LinkedPremises] = { required: false, value: nil }
    @children[:Location] = { required: false, value: nil}
  end
end

class PlugLoadNominalPower < SimpleElement; end

class PlugLoads < SimpleElement
  def specify_children
    @children = {}
    @children[:PlugLoad] = { required: false, value:[]} #TODO why is plugloadtype defined twice?
  end
end

class PlugLoadType < EnumeratedElement
  def specify_enums
    @enums = ["Personal Computer",
              "Task Lighting",
              "Printing",
              "Cash Register",
              "Audio",
              "Display",
              "Set Top Box",
              "Business Equipment",
              "Other",
              "Unknown"]
  end
end

class PumpApplication < EnumeratedElement
  def specify_enums
    @enums = ["Boiler",
            "Chilled Water",
            "Domestic Hot Water",
            "Solar Hot Water",
            "Condenser",
            "Cooling Tower",
            "Ground Loop",
            "Pool",
            "Recirculation",
            "Process Hot Water",
            "Process Cold Water",
            "Potable Cold Water",
            "Refrigerant",
            "Air",
            "Other",
            "Unknown"]
  end
end

class PumpingConfiguration < EnumeratedElement
  def specify_enums
    @enums = ["Primary",
              "Secondary",
              "Tertiary",
              "Backup",
              "Other",
              "Unknown"]
  end
end

class PumpControlType < EnumeratedElement
  def specify_enums
    @enums = ["Constant Volume",
              "Variable Volume",
              "VFD",
              "Multi-Speed",
              "Other",
              "Unknown"]
  end
end

class PumpOperation < EnumeratedElement
  def specify_enums
    @enums = ["On Demand",
              "Standby",
              "Schedule",
              "Other",
              "Unknown"]
  end
end

class PumpEfficiency < SimpleElement; end


class PumpSystemType < SimpleElement
  def specify_children
    @children = {}
    @children[:PumpEfficiency] = { required:false, value: nil }
    @children[:PumpControlType] = { required:false, value: nil }
    @children[:PumpOperation] = { required:false, value: nil }
    @children[:PumpingConfiguration] = { required:false, value: nil }
    @children[:PumpApplication] = { required:false, value: nil }
    @children[:Quantity] = { required:false, value: nil }
    @children[:LinkedSystemID] = { required:false, value: nil }
    #TODO: Add more as required
  end

  def specify_attributes
    @attributes = {}
    @attributes[:ID] ={ required:false, value: nil }
  end
end

class PumpSystems < SimpleElement
  def specify_children 
    @children = {}
    @children[:PumpSystem] = { required:false, type:"PumpSystemType", value: [] }
  end
end

class Quantity < SimpleElement; end

class ReheatSource < EnumeratedElement
  def specify_enums
    @enums = ["Heating plant",
              "Local electric resistance",
              "Local gas",
              "Other",
              "Unknown"]
  end
end
class ReheatPlantID < IDOnlyElement; end

class RoofID < SimpleElement
  def specify_children 
    @children = {}
    @children[:RoofArea] = { required:false, value: nil }
    @children[:RoofInsulatedArea] = { required:false, value: nil }
    @children[:SkylightID] = { required:false, value: [] }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { required:true, text: nil }
  end

end

class RoofArea < SimpleElement; end
class RoofInsulatedArea < SimpleElement; end


class RoofSystems < SimpleElement
  def specify_children
    @children = {}
    @children[:RoofSystem] = { required:true, type: "RoofSystemType", value:  [] }
  end
end

class RoofSystemType < SimpleElement
  def specify_children
    @children = {}
    @children[:RoofConstruction] = { required: false, type: "EnvelopeConstructionType",value: nil }
    @children[:SpecialRoofClassification] = { required: false, value: nil }
    @children[:RoofFinish] = { required: false, value: nil }
    @children[:RoofColor] = { required: false, value: nil }
    @children[:RoofInsulation] = { required: false, value:  [] }
    @children[:RoofRValue] = { required: false, value: nil }
    @children[:RoofUFactor] = { required: false, value: nil }
    @children[:RoofFramingMaterial] = { required: false, value: nil }
    @children[:RoofFramingSpacing] = { required: false, value: nil }
    @children[:RoofFramingDepth] = { required: false, value: nil }
    @children[:RoofFramingFactor] = { required: false, value: nil }
    @children[:RoofSlope] = { required: false, value: nil }
    @children[:RoofExteriorSolarAbsorbtance] = { required: false, value: nil }
    @children[:RoofExteriorThermalAbsorbtance] = { required: false, value: nil }
    @children[:Quantity] = { required: false, value: nil }
    @children[:YearInstalled] = { required: false, value: nil }
    #@children[:UserDefinedFields] = { required: false, value: nil }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:ID] = { required:false, text: nil }
  end
end

class ScheduleCategory < EnumeratedElement
  def specify_enums
    @enums = ["Business",
              "Occupied",
              "Unoccupied",
              "Sleeping",
              "Public access",
              "Setback",
              "Operating",
              "HVAC equipment",
              "Cooling equipment",
              "Heating equipment",
              "Lighting",
              "Cooking equipment",
              "Miscellaneous equipment",
              "On-peak",
              "Off-peak",
              "Super off-peak",
              "Other"]
  end
end

class ScheduleDetails < SimpleElement
  def specify_children
    @children = {}
    @children[:DayType] = { required:false,value: nil }
    @children[:ScheduleCategory] = { required:false,value: nil }
    @children[:DayStartTime] = { required:false,value: nil }
    @children[:DayEndTime] = { required:false,value: nil }
    @children[:PartialOperationPercentage] = { required:false,value: nil }

  end
end

class ScheduleType < SimpleElement
  def specify_children
    @children = {}
    @children[:SchedulePeriodBeginDate] = { required:false,value: nil }
    @children[:SchedulePeriodEndDate] = { required:false,value: nil }
    @children[:ScheduleDetails] = { required:false,value: [] }
    @children[:UserDefinedFields] = { required:false,value: nil }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { required:true, text: nil }
  end
end

class SchedulePeriodBeginDate < SimpleElement; end

class SchedulePeriodEndDate < SimpleElement; end

class Schedules < SimpleElement
  def specify_children
    @children = {}
    @children[:Schedule] = { required:false, type: "ScheduleType", value: [] }
  end
end

class SkylightID < SimpleElement; 
  def specify_children
    @children={}
    @children[:PercentSkylightArea] = { required:false,value: nil }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { required:true, text: nil }
  end
end

class Story < SimpleElement; end

class SetpointTemperatureHeating < SimpleElement; end
class SetbackTemperatureHeating < SimpleElement; end
class SetpointTemperatureCooling < SimpleElement; end
class SetupTemperatureCooling < SimpleElement; end

class SideA1Orientation < SimpleElement; end

class Sides < SimpleElement
  def specify_children
    @children = {}
    @children[:Side]= { required:false, value: [] }
  end

end

class Side < SimpleElement
  def specify_children
    @children =  {}
    @children[:SideNumber] = { required: false, value: nil}
    @children[:SideLength] = { required: false, value: nil}
    @children[:WallID] = { required: false, value: nil}
    @children[:WindowID] = { required: false, value:  []}
    @children[:DoorID] = { required: false, value: nil}
    @children[:ThermalZoneID] = { required: false, value: nil}
  end
end

class SideLength < SimpleElement; end

class SideNumber < EnumeratedElement
  def specify_enums
    @enums = ["A1",
              "A2",
              "A3",
              "B1",
              "B2",
              "B3",
              "C1",
              "C2",
              "C3",
              "D1",
              "D2",
              "D3",
              "AO1",
              "BO1"]
  end
end

class Sites < SimpleElement
  def specify_children
    @children = {}
    @children[:Site] = { required:false, type:"SiteType", value: [] } 
  end
end


class SiteType < SimpleElement
  def specify_children
    @children = {}
    @children[:PremisesNotes] = { required:false,value: nil } 
    @children[:PremisesName] = { required:false,value: nil } 
    @children[:PremisesIdentifiers] = { required:false,value: nil } 
    @children[:OccupancyClassification] = { required:false,value: nil } 
    @children[:WeatherStationID] = { required:false,value: nil } 
    @children[:WeatherStationName] = { required:false,value: nil } 
    @children[:WeatherStationCategory] = { required:false,value: nil } 
    @children[:Latitude] = { required:false,value: nil } 
    @children[:Longitude] = { required:false,value: nil } 
    @children[:ClimateZoneType] = { required:false,value: nil } 
    @children[:Facilities] = { required:false,value: nil  }
    #TODO: Add OwnershipStatus, Ownershipd, PrimaryContactID, Address
  end
    
  def specify_attributes
    @attributes = {}
    @attributes[:ID] = { required:true, text: nil }
  end
end

class SourceHeatingPlantID < SimpleElement
  def specify_attributes
    @attributes = {}
    @attributes[:ID] = { required: false, value: nil }
  end
end

#a special category for LinkedPremises
class Space < SimpleElement
  def specify_children
    @children = {}
    @children[:LinkedSpaceID] = { required: false, value: [] }
  end
end

class SpaceID < IDOnlyElement; end

class Spaces < SimpleElement
  def specify_children
    @children = {}
    @children[:Space] = {  required: false, type:"SpaceType", value: [] }
  end
end

class SpaceType < SimpleElement
  def specify_children
    @children = {}
    @children[:PremisesNotes] = { required:false,value: nil } 
    @children[:PremisesName] = { required:false,value: nil } 
    @children[:PremisesIdentifiers] = { required:false,value: nil } 
    @children[:FacilityClassification] = { required:false,value: nil } 
    @children[:OccupancyClassification] = { required:false,value: nil } 
    @children[:OccupancyLevels] = { required:false,value: nil } 
    @children[:OccupancyScheduleID] = { required:false,value: nil } 
    @children[:OccupantsActivityLevel] = { required:false,value: nil } 
    @children[:DaylitFloorArea] = { required:false,value: nil } 
    @children[:DaylightingIlluminanceSetpoint] = { required:false,value: nil } 
    @children[:PrimaryContactID] = { required:false,value: nil } 
    @children[:FloorAreas] = { required:false,value: [] } 
    @children[:PercentageOfCommonSpace] = { required:false,value: nil } 
    @children[:ConditionedVolume] = { required:false,value: nil } 
    @children[:UserDefinedFields] = { required:false,value: [] } 
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { required:true, text: nil }
  end
end

class Subsections < SimpleElement
  def specify_children
    @children = {}
    @children[:Subsection] = { required:false, value: [] }
    @children[:UserDefinedFields] = { required:false, value: nil }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { required:true, text: nil }
  end

end

class Subsection < SimpleElement
  def specify_children
    @children = {}
    @children[:PremisesName] = { required:false,value: nil }
    @children[:PremisesNotes] = { required:false,value: nil } 
    @children[:PremisesName] = { required:false,value: nil } 
    @children[:PremisesIdentifiers] = { required:false,value: nil } 
    @children[:FacilityClassification] = { required:false,value: nil } 
    @children[:OccupancyClassification] = { required:false,value: nil } 
    @children[:OccupancyLevels] = { required:false,value: nil } 
    @children[:PrimaryContactID] = { required:false,value: nil } 
    @children[:YearOfConstruction] = { required:false,value: nil } 
    @children[:FootprintShape] = { required:false,value: nil } 
    @children[:Story] = { required:false,value: nil } 
    @children[:FloorAreas] = { required:false,value: [] } 
    @children[:ThermalZoneLayout] = { required:false,value: nil } 
    @children[:PerimeterZoneDepth] = { required:false,value: nil } 
    @children[:SideA1Orientation] = { required:false,value: nil } 
    @children[:Sides] = { required:false,value: [] } 
    @children[:RoofID] = { required:false,value: [] } 
    @children[:CeilingID] = { required:false,value: [] } 
    @children[:FoundationID] = { required:false,value: [] } 
    @children[:XOffset] = { required:false,value: nil } 
    @children[:YOffset] = { required:false,value: nil } 
    @children[:ZOffset] = { required:false,value: nil } 
    @children[:FloorsAboveGrade] = { required:false,value: nil } 
    @children[:FloorsBelowGrade] = { required:false,value: nil } 
    @children[:FloorsPartiallyBelowGrade] = { required:false,value: nil } 
    @children[:FloorToFloorHeight] = { required:false,value: nil } 
    @children[:FloorToCeilingHeight] = { required:false,value: nil } 
    @children[:ThermalZones] = { required:false, value: nil } 
    @children[:UserDefinedFields] = { required:false,value: nil } 
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { required:true, text: nil }
  end
  
end

class Systems < SimpleElement
  def specify_children
    @children = {}
    @children[:HVACSystems] = { required:false, value: nil }
    @children[:LightingSystems] = { required:false, value: nil }
    
    @children[:WallSystems] = { required:false, value: nil }
    @children[:RoofSystems] = { required:false, value: nil }
    @children[:CeilingSystems] = { required:false, value: nil }
    @children[:FenestrationSystems] = { required:false, value: nil }
    @children[:FoundationSystems] = { required:false, value: nil }
    @children[:PlugLoads] = { required:false, value: nil }
    @children[:PumpSystems] = { required: false, value: nil }
    @children[:FanSystems] = { required: false, value: nil }
    #TODO: add more systems as needed
    #@children[:DomesticHotWaterSystems] = { required:false, value: nil }
    #@children[:CookingSystems] = { required:false, value: nil }
  end
end

class TerminalUnit < EnumeratedElement
  def specify_enums
    @enums = ["CAV terminal box with reheat",
              "VAV terminal box fan powered no reheat",
              "VAV terminal box fan powered with reheat",
              "VAV terminal box not fan powered no reheat",
              "VAV terminal box not fan powered with reheat",
              "Automatically controlled register",
              "Manually controlled register",
              "Uncontrolled register",
              "Other",
              "Unknown"]
  end
end

class ThermalEfficiency < SimpleElement; end

class ThermalZone < SimpleElement
  def specify_children
    @children = {}
    @children[:LinkedThermalZoneID] = { required: false, value: [] }
  end
end

class ThermalZones < SimpleElement
  def specify_children
    @children = {}
    @children[:ThermalZone] = { required:false, type: 'ThermalZoneType', value: [] }
  end
end

class ThermalZoneID < IDOnlyElement; end

class ThermalZoneLayout < EnumeratedElement
  def specify_enums
    @enums = ["Perimeter",
              "Perimeter and core",
              "Single zone",
              "Other",
              "Unknown"
    ]
  end
end

class ThermalZoneType < SimpleElement
  def specify_children
    @children = {}
    @children[:PremisesName] = { required:false, value: nil }
    @children[:DeliveryID] = { required:false, value: [] }
    @children[:HVACScheduleID] = { required:false, value: [] }
    @children[:SetpointTemperatureHeating] = { required:false, value: nil }
    @children[:SetbackTemperatureHeating] = { required:false, value: nil }
    @children[:HeatLowered] = { required:false, value: nil }
    @children[:SetpointTemperatureCooling] = { required:false, value: nil }
    @children[:SetupTemperatureCooling] = { required:false, value: nil }
    @children[:ACAdjusted] = { required:false, value: nil }
    @children[:Spaces] = { required:false ,value: nil }
    @children[:UserDefinedFields] = { required:false, value: [] }
  end

  def specify_atttributes
    @attributes = {}
    @attributes[:IDref] = { required:true, text: nil }
  end
end

class WallID < SimpleElement
  def specify_children
    @children = {}
    @children[:WallArea] = { required: false, value: nil}
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { required:true, text: nil }
  end
end

class WallArea < SimpleElement; end

class WallSystems < SimpleElement
  def specify_children
    @children = {}
    @children[:WallSystem] = { required: false, type: "WallSystemType", value:  [] }
  end
end

class WallSystemType < SimpleElement 
  def specify_children
    @children = {}
    @children[:ExteriorWallConstruction] = { required: false, type: "ExteriorWallConstructionType",value: nil }
    @children[:ExteriorWallFinish] = { required: false, value: nil }
    @children[:ExteriorWallColor] = { required: false, value: nil }
    @children[:WallInsulations] = { required: false, value:  [] }
    @children[:WallRValue] = { required: false, value: nil }
    @children[:WallUFactor] = { required: false, value: nil }
    @children[:WallFramingMaterial] = { required: false, value: nil }
    @children[:WallFramingSpacing] = { required: false, value: nil }
    @children[:WallFramingDepth] = { required: false, value: nil }
    @children[:WallFramingFactor] = { required: false, value: nil }
    @children[:CMUFill] = { required: false, value: nil }
    @children[:WallExteriorSolarAbsorbtance] = { required: false, value: nil }
    @children[:WallExteriorThermalAbsorbtance] = { required: false, value: nil }
    @children[:InteriorVisibleAbsorbtance] = { required: false, value: nil }
    @children[:ExteriorRoughness] = { required: false, value: nil }
    @children[:Quantity] = { required: false, value: nil }
    @children[:YearInstalled] = { required: false, value: nil }
    #@children[:UserDefinedFields] = { required: false, value: nil }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:ID] = { required:false, text: nil }
  end
end

class WaterCooled < SimpleElement
  def specify_children
    @children = {}
    @children[:WaterCooledCondenserType] = { required: false, value: nil }
    @children[:CondenserWaterTemperature] = { required: false, value: nil }
    @children[:CondensingTemperature] = { required: false, value: nil }
    @children[:WaterCooledCondensingFlowControl] = { required: false, value: nil }
    #TODO add more fields as necessary
  end
end

class WaterCooledCondenserType < EnumeratedElement
  def specify_enums
    @enums = ["Cooling tower",
              "Other",
              "Unknown"]
  end
end

class WaterCooledCondensingFlowControl < EnumeratedElement

  def specify_enums
    @enums = ["Fixed Flow",
              "Two Position Flow",
              "Variable Flow",
              "Other",
              "Unknown"]
  end

end

class WeatherStationID < SimpleElement; end
class WeatherStationName < SimpleElement; end

class WindowID < SimpleElement 
  def specify_children
    @children = {}
    @children[:FenestrationArea] = { required: false, value: nil }
    @children[:WindowToWallRatio] = { required: false, value: nil }
    @children[:PercentOfWindowAreaShaded] = { required: false, value: nil}
  end

  def specify_attributes 
    @attributes = {}
    @attributes[:IDref] = { required:true, text: nil }
  end
end

class WindowToWallRatio < SimpleElement; end

class XOffset < SimpleElement; end

class YOffset < SimpleElement; end

class YearOfConstruction < SimpleElement; end

class ZOffset < SimpleElement; end

class ZoningSystemType < EnumeratedElement
  def specify_enums
    @enums = ["Single zone",
              "Multi zone",
              "Unknown"]
  end
end


