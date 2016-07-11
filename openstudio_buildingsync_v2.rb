require 'rexml/document'
include REXML


$doc = REXML::Document.new

root = $doc.add_element 'Root'
most_recent_element = root
puts $doc

#helper functions
def to_hash(obj)
    hash = obj.instance_variables.each_with_object({}) { |var, hash| hash[var.to_s.delete("@")] = obj.instance_variable_get(var) }
    return hash
end

class WriteXML
  attr_accessor :makingArray, :mostRecentElement

  def initialize
    @makingArray = false
  end

  def hash_to_xml(h)
    puts self.mostRecentElement
    puts h
    allowable_keys = [:value,:text,:children,"value","text","children"]
    #puts h.keys
    if(h.is_a?(Hash))
      if(h.keys.any? {|x| allowable_keys.include?(x) })
        #puts "Typical"
        #puts h.has_key?("children")
        if(h.has_key?(:attributes) || h.has_key?("attributes"))
          attributeskey = h.keys.find{ |k| k == :attributes || k == "attributes" }
          #write attributes to most_recent element
          #use each loop if array length is greater than 0
          #most_recent_element.attributes["test_attribute"] = 2
        end
        if(h.has_key?(:text) || h.has_key?("text"))
          #write text for the latest element
          textkey = h.keys.find{ |k| k == :text || k == "text" }
          if(!h[textkey].nil?)
            puts "Has text that is not nil.", h[textkey]
            puts self.mostRecentElement
            #self.mostRecentElement.add Text.new(h[textkey])
            puts "Success"
          end
        end
        if(h.has_key?(:children) ||h.has_key?("children"))
          #puts "Has children."
          childrenkey = h.keys.find{ |k| k == :children || k == "children" }
          if(h[childrenkey].keys.length > 0)
            h[childrenkey].keys.each do |k| #there may be one or several children keys
              puts "Drilling through: ", k
              child = h[childrenkey][k]
              valuekey = child.keys.find{|k| k == "value" || k == :value }

              if(child.has_key? valuekey)
                if(child[valuekey].is_a?(Array))
                  puts "The child of " + k.to_s + " is an array"
                  child[valuekey].each do |c|
                    self.makingArray = true
                    self.mostRecentElement = self.mostRecentElement.add_element(k.to_s)
                    hash_to_xml(c)
                    puts "Assigning to parent."
                    self.mostRecentElement = self.mostRecentElement.parent
                  end
                  self.makingArray = false
                else
                  #this is a special case where we revert to tthe parent after creating the most_recent_element
                  self.mostRecentElement = self.mostRecentElement.add_element(k.to_s)
                  puts 'Recursing on ' + k.to_s
                  hash_to_xml(child)
                  self.mostRecentElement = self.mostRecentElement.parent
                end
              else
                puts "This is a problem, a value is expected for hashes of this type."
              end
            end #end of array each loop
          end
        end
        if(h.has_key? :value || h.has_key?("value"))
          #is the value an array, or an object?
          valuekey = h.keys.find{ |k| k == :value || k == "value" }
          if(h[valuekey].is_a?(Array))
            puts "the value Is an array."
            h[valuekey].each do |a|
              hash_to_xml(a)
            end
          else
            puts "the value is not an array, it is a simple element."
            puts h
            if(h[valuekey].is_a?(Hash))
              puts h[valuekey]
              hash_to_xml(h[valuekey])
            else
              puts "Always need hashes."  #todo, throw error that hashes are expected.
              puts (to_hash(h[valuekey]))
              hash_to_xml(to_hash(h[valuekey]))
            end
          end
        end
      else
        #this is an xml element that needs to be written
        if(h.values[0].has_key? :type)
          puts "Writing " + h.values[0][:type] + " element."
          self.mostRecentElement = self.mostRecentElement.add_element(h.values[0][:type]) #this is a string
        else
          puts "Writing " + h.keys[0].to_s + " element."
          self.mostRecentElement = self.mostRecentElement.add_element(h.keys[0].to_s)
        end
        puts "Recursing on ", h.values[0]
        hash_to_xml(h.values[0])
      end
    else
      puts "There is no hash. If this is true, it should be a warning." #todo - there needs to be a warning.  There should always be a hash
      hash_to_xml(to_hash(h))
    end
  end

  
end



class SimpleElement

  def text
    @text = nil
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
      self.text
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
    specify_children()
    specify_attributes()
    if(!args.nil?)
      if(args.is_a?(Hash))
        if(args.has_key? :children)
          bulk_children(args[:children])
        elsif(args.has_key? :attributes)
            
        elsif(args.has_key? :text)
          @text = args[:text]
        else
          #TODO put error that the proper hash keys were not identified.
        end
      end
    else
      #TODO give some indication that no arguments were provided
    end
    #TODO - make this active only on a boolean, and also a filter, not an actual delete
    delete_unwanted_children()
  end


  def bulk_children(args)
    args.keys.each do |k|
      puts "Working on " + k.to_s
      puts @children
      if(args[k][:value].is_a?(Array))
        puts "Value is an array"
        args[k][:value].each do |c|
          @children[k][:value] << c
        end
      else
        if(@children.has_key? k)
          if(args[k][:value].is_a?(Array))
            type_match = true
            args[k][:value].each do |a|
              if(@children[k].has_key? :type)
                if(a.class.name != @children[k][:type])
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
              #TODO: put something to alert user that they supplied the wrong class for children
            end
          else #it is an object
            puts "Looking for an object."
            if(@children[k].has_key? :type)
              puts 'a type for this object'
                if(k === @children[k][:type])
                  @children[k][:value] = args[k][:value]
                end
            else
              puts 'No type for this object.' + k.to_s
              @children[k][:value] = args[k][:value]
            end
          end
        else
          #TODO return some error saying the key could not be found
        end
      end
    end #end of keys outer loop
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
    @attributes[:IDref] = { :required=>true, :value => nil }
  end
end

class EnumeratedElement < SimpleElement

  def specify_enums
    @enums = []
  end

  def post_initialize(args)
    specify_enums()
    if(@enums.include? args[:text])
      @text = args[:text]
    else
      #TODO: put some type of warning to alert user unable to assign the text
    end
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
class AspectRatio < SimpleElement;end


class Audits
  def specify_children
    @children = {}
    @children = {:Audit => { :required=>true,:value=>[] } }
  end
end


class Audit
  def specify_children
    @children = {}
    @children[:Sites] = { :required=>false, :type=> 'SiteType', :value=>[] }
    @children[:Systems] = { :required=>false, :value=>nil }
    @children[:Schedules] = { :required=>false, :type=> 'ScheduleType', :value=>[] }
    @children[:Measures] = { :required=>false, :type=> 'MeasureType', :value=>[] }
    @children[:Report] = { :required=>false, :value=>nil }
    @children[:Contacts] = { :required=>false, :type=> 'ContactType', :value=>[] }
  end

  def specify_attributes
    @attributes = {}
    @attributes = {"ID" => {:value=>nil} }
  end

end

class CeilingArea < SimpleElement; end
class CeilingInsulatedArea < SimpleElement; end

class CeilingID < SimpleElement
  def specify_children 
    @children = {}
    @children[:CeilingArea] = { :required=>false, :value=>nil }
    @children[:CeilingInsulatedArea] = { :required=>false, :value=>nil }
    @children[:ThermalZoneID] = { :required=>false, :value=>nil }
    @children[:SpaceID] = { :required=>false, :value=>nil }
  end

  def specify_attributes
    @attributes[:IDref] = { :required=>true, :value => nil }
  end

end

class ConditionedVolume < SimpleElement; end
class DaylightingIlluminanceSetpoint < SimpleElement; end
class DaylitFloorArea < SimpleElement; end

class DoorID < SimpleElement 
  def specify_children
    @children = {}
    @children[:FenestrationArea] = { :required => false, :value => nil}
  end

  def specify_attributes 
    @attributes = {}
    @attributes[:IDref] = { :required=>true, :value => nil }
  end
end

class DeliveryID < IDOnlyElement; end

class Facilities < SimpleElement
  #initialize the Facility Children with a simple type or array
  def specify_children
    @children = {}
    @children = {:Facility => { :required=>true,:type=>'FacilityType',:value=>[] } }
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
      @children[:PremisesName] = { :required=>false,:value=>nil }
      @children[:PremisesNotes] = { :required=>false,:value=>nil } 
      @children[:PremisesName] = { :required=>false,:value=>nil } 
      @children[:PremisesIdentifiers] = { :required=>false,:value=>nil } 
      @children[:FacilityClassification] = { :required=>false,:value=>nil } 
      @children[:OccupancyClassification] = { :required=>false,:value=>nil } 
      @children[:OccupancyLevels] = { :required=>false,:value=>nil } 
      @children[:SpatialUnits] = { :required=>false,:value=>[] } 
      @children[:Ownership] = { :required=>false,:value=>nil } 
      @children[:OwnershipStatus] = { :required=>false,:value=>nil } 
      @children[:PrimaryContactID] = { :required=>false,:value=>nil } 
      @children[:PubliclySubsidize] = { :required=>false,:value=>nil } 
      @children[:FederalBuilding] = { :required=>false,:value=>nil } 
      @children[:PortfolioManager] = { :required=>false,:value=>nil } 
      @children[:NumberOfBusinesses] = { :required=>false,:value=>nil } 
      @children[:FloorsAboveGrade] = { :required=>false,:value=>nil } 
      @children[:FloorsBelowGrade] = { :required=>false,:value=>nil } 
      @children[:FloorAreas] = { :required=>false,:value=>[] } 
      @children[:AspectRatio] = { :required=>false,:value=>nil } 
      @children[:Perimeter] = { :required=>false,:value=>nil } 
      @children[:HeightDistribution] = { :required=>false,:value=>nil } 
      @children[:HorizontalSurroundings] = { :required=>false,:value=>nil }
      @children[:VerticalSurroundings] = { :required=>false,:value=>nil }  
      @children[:Assessment] = { :required=>false,:value=>nil } 
      @children[:YearOfConstruction] = { :required=>false,:value=>nil } 
      @children[:YearOccupied] = { :required=>false,:value=>nil } 
      @children[:YearOfLastEnergyAudit] = { :required=>false,:value=>nil } 
      @children[:RetrocommissioningDate] = { :required=>false,:value=>nil } 
      @children[:YearOfLastRetrofit] = { :required=>false,:value=>nil } 
      @children[:YearOfLastMajorRemodel] = { :required=>false,:value=>nil } 
      @children[:PercentOccupiedByOwner] = { :required=>false,:value=>nil } 
      @children[:OperatorType] = { :required=>false,:value=>nil } 
      @children[:Subsections] = { :required=>false,:value=>[] } 
      @children[:UserDefinedFields] = { :required=>false,:value=>[] } 
    end 

end

class FenestrationArea < SimpleElement; end

class FloorAreas < SimpleElement
    attr_accessor :FloorAreas
  def specify_children
    @children = {}
    @children = { :FloorAreas => { :required=>false, :value=>[] } }
  end

  def specify_attributes
    @attributes = {}
  end
end

class FloorArea < SimpleElement
  def specify_children
    @children = {}
    @children[:FloorAreaType] = { :required=>false, :value=>nil }
    @children[:FloorAreaCustomName] = { :required=>false, :value=>nil }
    @children[:FloorAreaValue] = { :required=>false, :value=>nil }
    @children[:Story] = { :required=>false, :value=>nil }
  end
  def specify_attributes
    @attributes = {}
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
    @children[:FoundationArea] = { :required=>false, :value=>nil }
    @children[:ThermalZoneID] = { :required=>false, :value=>nil }
    @children[:SpaceID] = { :required=>false, :value=>nil }
  end

  def specify_attributes
    @attributes[:IDref] = { :required=>true, :value => nil }
  end

end

class HeatLowered < SimpleElement; end

class HVACScheduleID < IDOnlyElement; end
# class Longitude < SimpleElement
#     def initialize(args)
#         @attributes={ :Source => args[:source] }
#         @text = args[:text]
#     end
# end
# class Latitude < SimpleElement
#     def initialize(args)
#         @attributes={ :Source => args[:source] }
#         @text = args[:text]
#     end
# end

# class Side < SimpleElement
#     attr_accessor :SideNumber, :SideLength, :WallID, :WindowID, :DoorID, :ThermalZoneID

#     def initialize(args)

#     end

#     def add(obj)
#         case 
#         when obj.class.name === "SideNumber"
#             self.SideNumber = obj
#         when obj.class.name === "SideLength"
#             self.SideLength = obj
#         when obj.class.name === "WallID"
#             self.WallID = obj
#         when obj.class.name === "WindowID"
#             self.WindowID = obj
#         when obj.class.name === "DoorID"
#             self.DoorID = obj
#         when obj.class.name === "ThermalZoneID"
#         end
#     end

# end



class OccupancyLevels < SimpleElement
    
    def specify_children 
      @children = {}
      @children = { :OccupancyLevel=>{ :requred=>false, } }
    end
    def specify_attributes
      @attributs = {}
    end

end

class OccupancyLevel < SimpleElement
    attr_accessor :OccupancyType, :OccupantQuantityType, :OccupantQuantity
    def specify_children
      @children = {}
      @children[:OccupantType] = { :required=>false, :value=>nil }
      @children[:OccupantQuantityType] = { :required=>false, :value=>nil }
      @children[:OccupantQuantity] = { :required=>false, :value=>nil }
    end

    def specify_attributes
      @attributes = {}
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

class PercentageOfCommonSpace < SimpleElement; end

class PercentOfWindowAreaShaded < SimpleElement; end

class PerimeterZoneDepth < SimpleElement; end
# class Ownership < SimpleElement
#     attr_accessor :enums
#     def initialize(args)
#         @enums = ["Property management company",
#         "Corporation/partnership/LLC",
#         "Religious organization",
#         "Individual",
#         "Franchise",
#         "Other non-government",
#         "Government",
#         "Federal government",
#         "State government",
#         "Local government",
#         "Other",
#         "Unknown"]
#         if(@enums.include? args[:text])
#             @text = args[:text]
#         else
#             puts "Throw an error Ownership enums."
#         end
#     end
# end
# class OwnershipStatus < SimpleElement
#     attr_accessor :enums
#     def initialize(args)
#         @attributes = []
#         @enums = ["Owned",
#                     "Mortgaged",
#                     "Leased",
#                     "Rented",
#                     "Occupied without payment of rent",
#                     "Other",
#                     "Unknown"]
#         if(@enums.include? args[:text])
#             @text = args[:text]
#         else
#             puts "Throw an error weather station category."
#         end
#     end
# end
class PremisesName < SimpleElement; end
class PremisesNotes < SimpleElement; end
class PremisesIdentifiers < SimpleElement; end

class RoofID < SimpleElement
  def specify_children 
    @children = {}
    @children[:RoofArea] = { :required=>false, :value=>nil }
    @children[:RoofInsulatedArea] = { :required=>false, :value=>nil }
    @children[:SkylightID] = { :required=>false, :value=>nil }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { :required=>true, :value => nil }
  end

end

class RoofArea < SimpleElement; end
class RoofInsulatedArea < SimpleElement; end

# class PrimaryContactID < SimpleElement
#     def initialize(args)
#         @attributes = { :ID => args[id] }
#         @required = true
#     end
# end

class ScheduleDetails < SimpleElement
  def specify_children
    @children = {}
    @children[:DayType] = { :required=>false,:value=nil }
    @children[:ScheduleCategory] = { :required=>false,:value=nil }
    @children[:DayStartTime] = { :required=>false,:value=nil }
    @children[:DayEndTime] = { :required=>false,:value=nil }
    @children[:PartialOperationPercentage] = { :required=>false,:value=nil }

  end
end

class ScheduleType < SimpleElement
  def specify_children
    @children = {}
    @children[:SchedulePeriodBeginDate] = { :required=>false,:value=>nil }
    @children[:SchedulePeriodEndDate] = { :required=>false,:value=>nil }
    @children[:ScheduleDetails] = { :required=>false,:value=>nil }
    @children[:UserDefinedFields] = { :required=>false,:value=>nil }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { :required=>true, :value => nil }
  end
end

class SkylightID < SimpleElement; 
  def specify_children
    @children={}
    @children = [:PercentSkylightArea] = { :required=>false,:value=>nil }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { :required=>true, :value => nil }
  end
end

class Story < SimpleElement; end
# class WeatherDataStationID < SimpleElement; end
# class WeatherStationName < SimpleElement; end
# class WeatherStationCategory < SimpleElement
#     attr_accessor :enums
#     def initialize(args)
#         @attributes = []
#         @enums = ["FAA",
#                     "ICAO",
#                     "NWS",
#                     "WBAN",
#                     "WMO",
#                     "Other"]
#         if(@enums.include? args[:text])
#             @text = args[:text]
#         else
#             puts "Throw an error weather station category."
#         end
#     end
# end

class SetpointTemperatureHeating < SimpleElement; end
class SetbackTemperatureHeating < SimpleElement; end
class SetpointTemperatureCooling < SimpleElement; end
class SetupTemperatureCooling < SimpleElement; end

class SideA1Orientation < SimpleElement; end

class Sides < SimpleElement
  def specify_children
    @children = {}
    @children[:Side]= { :required=>false, :value=>[] }
  end

end

class Side < SimpleElement
  def specify_children
    @children =  {}
    @children[:SideNumber] = { :required => false, :value => nil}
    @children[:SideLength] = { :required => false, :value => nil}
    @children[:WallID] = { :required => false, :value => nil}
    @children[:WindowID] = { :required => false, :value => nil}
    @children[:DoorID] = { :required => false, :value => nil}
    @children[:ThermalZoneID] = { :required => false, :value => nil}
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

class SpaceID < IDOnlyElement; end

class SpaceType < SimpleElement
  def specify_children
    @children = {}
    @children[:PremisesName] = { :required=>false,:value=>nil }
    @children[:PremisesNotes] = { :required=>false,:value=>nil } 
    @children[:PremisesName] = { :required=>false,:value=>nil } 
    @children[:PremisesIdentifiers] = { :required=>false,:value=>nil } 
    @children[:FacilityClassification] = { :required=>false,:value=>nil } 
    @children[:OccupancyClassification] = { :required=>false,:value=>nil } 
    @children[:OccupancyLevels] = { :required=>false,:value=>nil } 
    @children[:OccupancyScheduleID] = { :required=>false,:value=>nil } 
    @children[:OccupantsActivityLevel] = { :required=>false,:value=>nil } 
    @children[:DaylitFloorArea] = { :required=>false,:value=>nil } 
    @children[:DaylightingIlluminanceSetpoint] = { :required=>false,:value=>nil } 
    @children[:PrimaryContactID] = { :required=>false,:value=>nil } 
    @children[:FloorAreas] = { :required=>false,:value=>[] } 
    @children[:PercentageOfCommonSpace] = { :required=>false,:value=>nil } 
    @children[:ConditionedVolume] = { :required=>false,:value=>nil } 
    @children[:UserDefinedFields] = { :required=>false,:value=>[] } 
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { :required=>true, :value => nil }
  end
end

class Subsections
  def specify_children
    @children = {}
    @children[:Subsection] = { :required=>false, :value=>[] }
    @children[:UserDefinedFields] { :required=>false, :value=>nil }
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { :required=>true, :value => nil }
  end

end

class Subsection < SimpleElement
  def specify_children
    @children = {}
    @children[:PremisesName] = { :required=>false,:value=>nil }
    @children[:PremisesNotes] = { :required=>false,:value=>nil } 
    @children[:PremisesName] = { :required=>false,:value=>nil } 
    @children[:PremisesIdentifiers] = { :required=>false,:value=>nil } 
    @children[:FacilityClassification] = { :required=>false,:value=>nil } 
    @children[:OccupancyClassification] = { :required=>false,:value=>nil } 
    @children[:OccupancyLevels] = { :required=>false,:value=>nil } 
    @children[:PrimaryContactID] = { :required=>false,:value=>nil } 
    @children[:YearOfConstruction] = { :required=>false,:value=>nil } 
    @children[:FootprintShape] = { :required=>false,:value=>nil } 
    @children[:Story] = { :required=>false,:value=>nil } 
    @children[:FloorAreas] = { :required=>false,:value=>[] } 
    @children[:ThermalZoneLayout] = { :required=>false,:value=>nil } 
    @children[:PerimeterZoneDepth] = { :required=>false,:value=>nil } 
    @children[:SideA1Orientation] = { :required=>false,:value=>nil } 
    @children[:Sides] = { :required=>false,:value=>[] } 
    @children[:RoofID] = { :required=>false,:value=>[] } 
    @children[:CeilingID] = { :required=>false,:value=>[] } 
    @children[:FoundationID] = { :required=>false,:value=>[] } 
    @children[:XOffset] = { :required=>false,:value=>nil } 
    @children[:YOffset] = { :required=>false,:value=>nil } 
    @children[:ZOffset] = { :required=>false,:value=>nil } 
    @children[:FloorsAboveGrade] = { :required=>false,:value=>nil } 
    @children[:FloorsBelowGrade] = { :required=>false,:value=>nil } 
    @children[:FloorsPartiallyBelowGrade] = { :required=>false,:value=>nil } 
    @children[:FloorToFloorHeight] = { :required=>false,:value=>nil } 
    @children[:FloorToCeilingHeight] = { :required=>false,:value=>nil } 
    @children[:ThermalZones] = { :required=>false, :type=>'ThermalZoneType', :value=>[] } 
    @children[:UserDefinedFields] = { :required=>false,:value=>nil } 
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { :required=>true, :value => nil }
  end
  
end

class ThermalZones < SimpleElement
  def specify_children
    @children = {}
    @children[:ThermalZone] = { :required=>false, :type=>'ThermalZoneType', :value=>[] }
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
    @children[:PremisesName] = { :required=>false, :value=>nil }
    @children[:DeliveryID] = { :required=>false, :value=>[] }
    @children[:HVACScheduleID] = { :required=>false, :value=>[] }
    @children[:SetpointTemperatureHeating] = { :required=>false, :value=>nil }
    @children[:SetbackTemperatureHeating] = { :required=>false, :value=>nil }
    @children[:HeatLowered] = { :required=>false, :value=>nil }
    @children[:SetpointTemperatureCooling] = { :required=>false, :value=>nil }
    @children[:SetupTemperatureCooling] = { :required=>false, :value=>nil }
    @children[:ACAdjusted] = { :required=>false, :value=>nil }
    @children[:Spaces] = { :required=>false, :type=>'SpaceType' ,:value=>[] }
    @children[:UserDefinedFields] = { :required=>false, :value=>[] }
  end

  def specify_atttributes
    @attributes = {}
    @attributes[:IDref] = { :required=>true, :value => nil }
  end
end

class WallID < SimpleElement
  def specify_children
    @children = {}
    @children[:WallArea] = { :required => false, :value => nil}
  end

  def specify_attributes
    @attributes = {}
    @attributes[:IDref] = { :required=>true, :value => nil }
  end
end

class WallArea < SimpleElement; end

class WindowID < SimpleElement 
  def specify_children
    @children = {}
    @children[:FenestrationArea] = { :required => false, :value => nil}
    @children[:WindowToWallRatio] = { :required => false, :value => nil}
    @children[:PercentOfWindowAreaShaded] = { :required => false, :value => nil}
  end

  def specify_attributes 
    @attributes = {}
    @attributes[:IDref] = { :required=>true, :value => nil }
  end
end

class WindowToWallRatio < SimpleElement; end

class XOffset < SimpleElement; end

class YOffset < SimpleElement; end

class YearOfConstruction < SimpleElement; end

class ZOffset < SimpleElement; end
#simple testing
# s = SimpleElement.new()
# childs = s.get_children
# puts "Got children?", childs
# childs[:one]=1
# puts to_hash(s)

# ft = FacilityType.new
# puts to_hash(ft)


#early prototype 1
# h = {}
# h['PremisesName'] = { :required=>false,:value=>'Jonston square.' }
# h['PremisesNotes'] = { :required=>false,:value=>'Man this place is old!' }
# f = FacilityType.new({ 'children' => h })
# puts f.class.name, to_hash(f)

# fs = Facilities.new({'children' => {'Facility' => { :required=>true,:type=>'FacilityType',:value=>[f] } } })
# puts fs.class.name, to_hash(fs)


#early prototype 2

# puts ot.class.name, to_hash(ot)

au = Audits.new

a = Audit.new

pn = PremisesName.new({ :text => 'Jonstone square.' })
pnt = PremisesNotes.new({ :text=>'Main this place is old!' })
ot = OccupancyClassification.new({ :text => "Office"})
fc = FacilityClassification.new({ :text => "Commercial"})
h = {}
h[:PremisesName] = { :required=>false,:value=>pn }
h[:PremisesNotes] = { :required=>false,:value=> pnt }
h[:OccupancyClassification] = { :required => false, :value => ot }
h[:FacilityClassification] = { :required => false, :value => fc }
en = {:children => h}
puts en
f = FacilityType.new(en)
#puts f.class.name, to_hash(f)

fhash = to_hash(f)
fs = Facilities.new(:children => {:Facility => { :required=>true, :type=>'FacilityType', :value=>[f,f]} })
facilities = {:Facilities=>to_hash(fs)}
puts facilities

puts "writing out to xml"
w = WriteXML.new
w.mostRecentElement = most_recent_element
w.hash_to_xml(facilities)


# class SiteType
#     attr_accessor :attributes, :type, :name, :PremisesName, :PremisesIdentifiers, :PremisesNotes,:OccupancyClassification, :WeatherDataStationID, :WeatherStationName, :WeatherStationCategory
#     attr_accessor :Latitude, :Longitude, :OwnershipStatus, :Ownership, :PrimaryContactID
#     def initialize(args)
#        @name = args[:displayName]
#        @attributes = { :ID => args[:ID] }
#     end
#     def add(obj)
#         puts obj.class
#         case 
#         when obj.class.name === "PremisesName"
#             puts "Site Type Adding", obj
#             self.PremisesName = obj
#         when obj.class.name === "OccupancyClassification"
#             self.OccupancyClassification = obj
#         when obj.class.name === "WeatherDataStationID"
#             self.WeatherDataStationID = obj
#         when obj.class.name === "WeatherStationName"
#             self.WeatherStationName = obj
#         when obj.class.name === "WeatherStationCategory"
#             self.WeatherStationCategory = obj
#         when obj.class.name === "PremisesIdentifiers"
#             self.PremisesIdentifiers = obj
#         when obj.class.name === "PremisesNotes"
#             self.PremisesNotes = obj
#         when obj.class.name === "Latitude"
#             self.Latitude = obj
#         when obj.class.name === "Longitude"
#             self.Longitude === obj
#         when obj.class.name = "Ownership"
#             self.Ownership === obj
#         when obj.class.name = "PrimaryContactID"
#             self.PrimaryContactID === obj
#         else
#             puts "Throw and error making site."
#         end
#     end
# end

# def writeOut(args)
#     puts "starting writeOut", args
#     #$doc = args[:doc]
#     current_class = args[:class]
#     current_el = args[:currentEl]
#     if(current_class.kind_of?(Array))
#         if(current_class.respond_to?("attributes"))
#             puts "this is an attribute array."
#         else
#             #current_el.add_element(current_class.class.name)
#             current_class.each do |a|
#                 puts "Recurse on array..."
#                 writeOut({ :class => a, :currentEl => current_el })
#             end
#         end
#     end    
#     current_class.instance_variables.each do |v|
#         puts "Class Instance Variable",  v.to_s
#         puts "The instance itself: ", current_class.instance_eval(v.to_s)
#         #puts v.to_s[1..-1]
        
#         if(current_class.instance_eval(v.to_s).respond_to?("attributes"))
#             if(current_class.instance_eval(v.to_s).attributes.empty?)
#                 puts "No attributes"
#                 puts "Found old fashioned way"
#                 puts "Writing element " + v.to_s[1..-1]
#                 c = current_el.add_element v.to_s[1..-1]
#                 writeOut({ :class => current_class.instance_eval(v.to_s), :currentEl => c })
#             else
#                 puts "attributes" + current_class.instance_eval(v.to_s)
#                 current_el["ID"]=current_class.instance_eval(v.to_s).attributes[0]
#             end
#         elsif(current_class.instance_eval(v.to_s).respond_to?("@text")) #a simple element
#             puts "Has text element"
#             current_el.text =  current_class.instance_eval(v.to_s).text
#         elsif(v.to_s === "type")
#             #do nothing, continue looping
#             puts "Reached type, ignoring."
#             next
#         else
#             #more complex than I thought
#             puts "Recurse..."
#             puts "Writing element " + v.to_s[1..-1]
#             c = current_el.add_element v.to_s[1..-1]
#             writeOut({ :class => current_class.instance_eval(v.to_s), :currentEl => c })
#         end
#     end
# end


# #create from openstudio model
# premises = PremisesName.new({ :text => "Hong Kong Market" })
# #puts premises.text
# occ = OccupancyClassification.new({ :text => "Office" })
# #puts occ.text
# site = SiteType.new({ :ID => "id_1", :displayName =>"Site" })
# site.add(premises)
# #puts site.PremisesName
# weatherStation = WeatherDataStationID.new({ :text => "123456" })
# site.add(weatherStation)
# weatherstatname = WeatherStationName.new({ :text => "Test" })
# site.add(weatherstatname)
# weatherstationtype = WeatherStationCategory.new({ :text => "WMO" })
# site.add(weatherstationtype)
# #puts site.WeatherStationCategory.text
# audit = Audit.new({ :ID => "Audit1" })
# audit.add_site(site)
# #puts audit
# #puts audit.Sites

# audits = Audits.new()
# audits.add_audit(audit)


#writeOut({ :class => audits, :currentEl => audits_el })
# audits_el = $doc.add_element 'Audits'
# audits.Audit.each do |a|
#     audit_el = audits_el.add_element 'Audit'
#     if a.Sites.length > 0
#         sites_el = audit_el.add_element 'Sites'
#         a.Sites.each do |s|
#             site_el = sites_el.add_element 'Site'
#             s.instance_variables.each do |v|
#                 puts "Site Variable ",v
#                 puts s.instance_eval(v.to_s)
#                 puts v.to_s[1..-1]
#                 if(s.instance_eval(v.to_s).respond_to?("text")) #a simple element
#                     puts "Has text element"
#                     c = site_el.add_element v.to_s[1..-1]
#                     c.text =  s.instance_eval(v.to_s).text
#                 end
#             end
#         end
        
#     end
# end
$doc.write($stdout)
#$doc.write(File.open("/Users/chienharriman/BuildingSync/som.xml","w"), 2)
