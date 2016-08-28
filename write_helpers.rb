require_relative 'openstudio_buildingsync_v2'
require 'rexml/document'
require 'OpenStudio'
include REXML

#is a master class that performs much of the dirty work and set up
class AuditHelper
  attr_accessor :audit, :constructions

  def initialize(os_model)
    #make systems
    #constructions
    constructions = os_model.getConstructions
    #puts constructions
    #puts 
    ch = ConstructionSystemsHelper.new()
    ch.make_bs_constructions(constructions)
    @constructions = ch
    

    h={}
    children={}
    h[:children] = children
    children[:FenestrationSystems] = { value: ch.fenestration_systems }
    children[:WallSystems] = { value: ch.wall_systems }
    children[:RoofSystems] = { value: ch.roof_systems }
    children[:FoundationSystems] = { value: ch.foundation_systems }
    children[:CeilingSystems] = { value: ch.ceiling_systems}

    lh = LightingSystemsHelper.new(os_model)
    children[:LightingSystems] = { value: lh.lighting_systems }
    plh = PlugLoadsHelper.new(os_model)
    children[:PlugLoads] = { value: plh.plug_loads}

    #HVAC Systems
    hvac = HVACSystemsHelper.new(os_model)
    puts hvac.hvac_systems.children
    children[:HVACSystems] = { value: hvac.hvac_systems }

    sys = Systems.new(h);
    #make schedules


    #make site
    sh = SiteHelper.new(os_model)
    h={}
    children={}
    attributes = {}
    h[:children] = children
    h[:attributes] = attributes
    attributes[:ID] = { value: "Site-1" }
    site = SiteType.new(h)
    #make sites
    h={}
    children={}
    h[:children] = children
    children[:Site] = { value: [sh.site] }
    sites = Sites.new(h)

    
    #make Audit
    h={}
    children={}
    attributes={}
    h[:children] = children
    h[:attributes] = attributes
    children[:Sites] = { value: sites }
    children[:Systems] = { value: sys }
    attributes[:ID] = { value:"Audit_1" }
    @audit = Audit.new(h)
    

  end
end

class ConstructionSystemsHelper
  attr_accessor :wall_systems, :roof_systems, :foundation_systems, :ceiling_systems, :fenestration_systems 

  def initialize; end
  def make_bs_constructions(constructions)
    wallsystems = []
    roofsystems = []
    foundations = []
    ceilsystems = []
    windsystems = []

    constructions.each do |construction|
      #puts("#{construction}")
      #determine construction type (Wall, Roof, Ceiling, Foundation, Window)
      #createConstruction based on type
      if not construction.name.empty?

        res = self.determine_type_from_name(construction)
        if(res.class.name == "WallSystemType")
          wallsystems.push(res)
          #puts("Made Wall")
        elsif(res.class.name == "CeilingSystemType")
          ceilsystems.push(res)
          #puts("Made Ceiling")
        elsif(res.class.name == "FoundationSystemType")
          foundations.push(res)
          #puts("Made Foundation")
        elsif(res.class.name == "RoofSystemType")
          roofsystems.push(res)
          #puts("Made Roof")
        elsif(res.class.name == "FenestrationSystemType")
          windsystems.push(res)
          #puts("Made Fenestration")
        else
          #warning
        end
      else
        #warning
      end
    end
    #puts("Wall Systems: #{wallsystems.length}")
    #puts("Ceiling Systems: #{ceilsystems.length}")
    #puts("Foundation Systems: #{foundations.length}")
    #puts("Roof Systems: #{roofsystems.length}")
    #puts("Fenestration Systems: #{windsystems.length}")
    h = {}
    children = {}
    h[:children] = children
    children[:WallSystem] = { required:  false, type:  "WallSystemType",value: wallsystems };
    self.wall_systems = WallSystems.new(h)
    h = {}
    children = {}
    h[:children] = children
    children[:CeilingSystem] = { required:  false, type:  "CeilingSystemType",value: ceilsystems };
    self.ceiling_systems = CeilingSystems.new(h)
    h = {}
    children = {}
    h[:children] = children
    children[:FoundationSystem] = { required:  false, type:  "FoundationSystemType",value: foundations };
    self.foundation_systems = FoundationSystems.new(h)
    h = {}
    children = {}
    h[:children] = children
    children[:RoofSystem] = { required:  false, type:  "RoofSystemType",value: roofsystems };
    self.roof_systems = RoofSystems.new(h);
    h = {}
    children = {}
    h[:children] = children
    children[:FenestrationSystem] = { required:  false, type:  "FenestrationSystemType",value: windsystems };
    self.fenestration_systems = FenestrationSystems.new(h)
  end
  #return is based on the string evaluation
  def determine_type_from_name(construction)
    name = construction.name.get
    #puts "Passed name", construction.name.get
    if(/wall/i =~ name)
      #puts "Found wall
      h = {}
      h[:children] = {}
      h[:attributes] = {:ID => { :value => construction.handle.to_s } }
      wall = WallSystemType.new(h)
      return wall
    elsif(/ceiling/i =~ name)
      h = {}
      h[:children] = {}
      h[:attributes] = {:ID => { :value => construction.handle.to_s } }
      ceil = CeilingSystemType.new(h)
      return ceil
    elsif(/floor/i =~ name)
      if(/interior/i =~ name)
        #do not add interior floors to the foundation category
      else
        h = {}
        h[:children] = {}
        h[:attributes] = {:ID => { :value => construction.handle.to_s } }
        found = FoundationSystemType.new(h)
      end
    elsif(/roof/i =~ name)
      h = {}
      h[:children] = {}
      h[:attributes] = {:ID => { :value => construction.handle.to_s } }
      roof = RoofSystemType.new(h)
      return roof
    elsif(/shgc/i =~ name || /window/i =~ name || /door/i =~ name)
      h = {}
      h[:children] = {}
      h[:attributes] = {:ID => { :value => construction.handle.to_s } }
      fen = FenestrationSystemType.new(h)
      return fen
    else
      #do nothing, possibly throw error
    end
      
  end
end

class FacilitiesHelper
  attr_accessor :facilities
  def initialize(model)
    os_bldg = model.getBuilding
    #puts os_bldg
    fah = FloorAreasHelper.new(Conversions.new().convertArea(os_bldg.floorArea))
    
    ss = SubsectionsHelper.new(model)

    h={}
    children={}
    attributes = {}
    h[:children] = children
    h[:attributes] = attributes
    attributes[:ID] = { value: "Facility-1" }
    children[:FloorAreas] = { value: fah.floor_areas }
    children[:Subsections] = { value: ss.subsections }

    facility = FacilityType.new(h)

    h={}
    children={}
    attributes = {}
    h[:children] = children
    h[:attributes] = attributes
    children[:Facility] = { value: [facility] }
    @facilities = Facilities.new(h)
  end
end

#this helper is only designed to help at the Facility Level, not the subsection level
class FloorsAboveGradeHelper
  attr_accessor :floors_above_grade
  def initialize(model)

  end
end

class FloorsBelowGradeHelper
  attr_accessor :floors_below_grade
  def initialize(model)

  end

end
#assumes that the floor area does not need to be converted
class FloorAreasHelper
  attr_accessor :floor_areas
  def initialize(area, fully_Conditioned=false)
    #puts "Making Floor Areas"

    #make floor Areas Object
    h = {}
    children = {}
    h[:children] = children
    fgross = FloorAreaType.new({ text: "Gross" })
    fgross_val = FloorAreaValue.new({ text: area })
    children[:FloorAreaType] = { value: fgross } 
    children[:FloorAreaValue] = { value: fgross_val}
    farea_1 = FloorArea.new(h)

    # h = {}
    # children = {}
    # h[:children] = children
    # fcon = FloorAreaType.new({ text: "Conditioned" })
    # fcon_val = FloorAreaValue.new({ text: area })
    # children[:FloorAreaType] = { value: fcon } 
    # children[:FloorAreaValue] = { value: fcon_val}
    # farea_2 = FloorArea.new(h)
    

    #make FloorAreas Wrapper
    h = {}
    children = {}
    h[:children] = children
    children[:FloorArea] = { value: [farea_1] }
    fas = FloorAreas.new(h)
    
    @floor_areas = fas
  end
end

class DuctSystemsHelper
  attr_accessor :duct_systems

  def initialize(air_loops)
    #make *each* DuctSystemType
    duct_systems_arr = []
    air_loops.each_with_index do |air_loop, index|
      h = {}
      children = {}
      attributes = {}
      h[:children] = children
      h[:attributes] = attributes

      delh = {}
      delattributes = {}
      delh[:attributes] = delattributes
      delattributes[:ID] = { value: "DeliveryPod-"+index.to_s }
     #puts delh
      children[:HeatingDeliveryID] = { value: HeatingDeliveryID.new(delh) }
      children[:CoolingDeliveryID] = { value: CoolingDeliveryID.new(delh) }
      children[:Quantity] = { value: Quantity.new({ text: 1 }) }
      children[:Location] = { value: Location.new({ text: "Interior" }) } #TODO, how to NOT hardcode this?

      #puts h
      #create linked premises
      #at a minimum, we want the space object which contains a linked space id and a set of schedules
      #work inside out, schedules, space id, and then linked premises
      ltzid = []
      air_loop.thermalZones.each do |tzone|
        lsh = {}
        lchildren = {}
        lattributes = {}
        lsh[:children] = lchildren
        lsh[:attributes] = lattributes
        lattributes[:IDref] = { value: tzone.handle.to_s }
        lsid = LinkedThermalZoneID.new(lsh)
       #puts lsid
        ltzid.push(lsid)
      end
      sh = {}
      schildren = {}
      sattributes = {}
      sh[:children] = schildren
      sh[:attributes] = sattributes
      schildren[:LinkedThermalZoneID] = { value: ltzid }
     #puts sh
      sp = ThermalZone.new(sh)

      lph = {}
      lphchildren = {}
      lphattributes = {}
      lph[:children] = lphchildren
      lph[:attributes] = lphattributes
      lphchildren[:ThermalZone] = { value: sp } #space is child of LinkedPremises
      lp = LinkedPremises.new(lph)

      children[:LinkedPremises] = { value: lp }
      ds = DuctSystemType.new(h)
      duct_systems_arr.push(ds)
    end
    h = {}
    children = {}
    attributes = {}
    h[:children] = children
    h[:attributes] = attributes
    #hash alread defined globally at the top of initialize
    children[:DuctSystem] = { value: duct_systems_arr }
    @duct_systems = DuctSystems.new(h)
    puts "Duct systems #{@duct_systems}"
  end


end

class HVACSystemsHelper
  attr_accessor :hvac_systems, :unique_hvac_systems, :air_loops, :plant_loops
  def initialize(model)

    @unique_hvac_systems = []
    @air_loops = []
    

    bldg = model.getBuilding
    tzones = bldg.thermalZones()
    tzones.each do |tzone|
      if not tzone.airLoopHVACTerminal.empty? 
        zoneTerm = tzone.airLoopHVACTerminal.get
       #puts "Terminal #{zoneTerm}"
       #puts "Containing ZoneHVAC #{zoneTerm.containingZoneHVACComponent}"
        if not zoneTerm.airLoopHVAC.empty?
          hvac_system = {}

          airLoop = zoneTerm.airLoopHVAC.get
          hvac_system[:airloop] = [airLoop.handle.to_s]
          hwcoils = airLoop.supplyComponents(OpenStudio::Model::CoilHeatingWater::iddObjectType())
          if not hwcoils.empty?
            hwplant = hwcoils.first.to_CoilHeatingWater.get.plantLoop().get()
            hvac_system[:hwPlant] = hwplant.handle.to_s
          else
            hvac_system[:hwPlant] = nil
          end
          cwcoils = airLoop.supplyComponents(OpenStudio::Model::CoilCoolingWater::iddObjectType())
          if not cwcoils.empty?
            chwplant = cwcoils.first.to_CoilCoolingWater.get.plantLoop().get()
            hvac_system[:chwPlant] = chwplant.handle.to_s
          else
            hvac_system[:chwPlant] = nil
          end

          #now process the little hvac_system just created
          if(@unique_hvac_systems.length == 0)
            @unique_hvac_systems.push(hvac_system)
            #puts "Added hvac_system to unique #{hvac_system}"
            @air_loops.push(airLoop)
          else
            foundmatch = false
            @unique_hvac_systems.each do |unique|
              #puts "Comparing unique #{unique} to current def #{hvac_system}"
              #puts unique[:chwPlant] == hvac_system[:chwPlant]
              if(unique.size == hvac_system.size and (unique.keys - hvac_system.keys).empty?)
                if unique[:hwPlant] == hvac_system[:hwPlant] and unique[:chwPlant] == hvac_system[:chwPlant]
                  #puts "Hot water and chilled water plants match"
                  if unique[:airloop].include? hvac_system[:airloop][0]
                    foundmatch = true
                    #puts "Found match for #{hvac_system}" #do nothing
                  else
                    #puts "Adding air loop #{airLoop.handle.to_s} to unique #{unique}"
                    unique[:airloop].push(airLoop.handle.to_s)
                    @air_loops.push(airLoop)
                    foundmatch = true
                  end
                end
              else
                #do nothing
                puts "This would be weird."  #TODO throw something here.
              end
            end
            if not foundmatch
             #puts "No match."
              @unique_hvac_systems.push(hvac_system)
              @air_loops.push(airLoop)
            end
          end
          
        else
          #not sure, do something?
        end

      else
        #not sure, maybe a place to handle hydronic systems? TODO: investigate 
      end
      #may be the same as zoneTerm
      equip = tzone.equipment()
      #potentially handle a situation where we must add more equipment that is not air-based.  TODO:future
    end

    puts "Unique hvac systems found \n #{@unique_hvac_systems}"
    #now try to create the hvac systems based on these
    @plant_loops = model.getPlantLoops
    puts "Air loops #{@air_loops.length} and \n plant loops #{@plant_loops.length}"
    #note, there should be as many unique air loops as total air loops, plant loops may not match because of service water
    unique_hvac_systems.each do |hvac_system|
      if hvac_system[:hwPlant].nil? and hvac_system[:chwPlant].nil?
        #packaged system
        hvac_system[:airloop].each do |aloop_handle|
          aloop = getAirLoop(aloop_handle)
         #puts "Found AirLoop: #{aloop}"
        end
      elsif hvac_system[:chwPlant].nil? and not hvac_system[:hwPlant].nil?
        heatingPlant = makeHeatingPlant(model, hvac_system[:hwPlant])
        puts "Heating plant #{heatingPlant}"
        cond_plants = []
        hvac_system[:airloop].each do |aloop_handle|
          aloop = getAirLoop(aloop_handle)
          if not aloop.nil?
            cl = makeCondensingPlant(model, aloop_handle)
            if not cl.nil?
              cond_plants.push(cl)
            end
          end
        end

        h = {}
        children = {}
        attributes = {}
        h[:children] = children
        h[:attributes] = attributes
        children[:HeatingPlantType] = { value: [heatingPlant] }
        children[:CondenserPlant] = { value: cond_plants }
        plants = Plants.new(h)
        #puts "Plants #{plants}"

        #make heating and cooling systems
        hcool = makeHeatingAndCoolingSystem(model, hvac_system)

        h = {}
        children = {}
        attributes = {}
        h[:children] = children
        h[:attributes] = attributes
        children[:Plants] = { value: plants }
        hvac_system_type = HVACSystemType.new(h)
        #puts "HVAC Systems Type #{hvac_system_type}"

        h = {}
        children = {}
        attributes = {}
        h[:children] = children
        h[:attributes] = attributes
        children[:HVACSystem] = { value: [hvac_system_type] }
        @hvac_systems = HVACSystems.new(h)
        puts "HVACSystems #{@hvac_systems}"

      elsif not hvac_system[:chwPlant].nil? and hvac_system[:hwPlant].nil?
         #TODO, throw here, we've never seen this condition
      else
        #TODO:  This should never happen
         
      end
        
    end
    # ds = DuctSystemsHelper.new(@air_loops)
    # sh = {}
    # schildren = {}
    # sh[:children] = schildren
    # schildren[:DuctSystems] = { value: ds.duct_systems }
    # hvacsystem = HVACSystemType.new(sh);

    # h = {}
    # children = {}
    # h[:children] = children
    # children[:HVACSystem] = {value: [hvacsystem] }
    # @hvac_systems = HVACSystems.new(h)
  end

  def getAirLoop(handle)
    @air_loops.each do |aloop|
      if aloop.handle.to_s == handle
        return aloop
      end
    end
    return nil
  end

  def makeHeatingAndCoolingSystem(model, hvac_system)
    h = {}
    children = {}
    attributes = {}
    h[:children] = children
    h[:attributes] = attributes
    begin
      if not hvac_system[:hwPlant].nil?
        h = {}
        children = {}
        attributes = {}
        h[:children] = children
        h[:attributes] = attributes
        
      end

      if no hvac_system[:chwPlant].nil?
        #have not seen before
        h = {}
        children = {}
        attributes = {}
        h[:children] = children
        h[:attributes] = attributes
      end

      @air_loops.each do |aloop|
        if hvac_system[:airloop].include? aloop.handle.to_s

        end
      end
    rescue

    ensure

    end

  end

  def makeCondensingPlant(model, handle)
    @air_loops.each do |aloop|
      if(aloop.handle.to_s == handle)
        begin
          dxcoil = aloop.supplyComponents(OpenStudio::Model::CoilCoolingDXSingleSpeed::iddObjectType())
          dxcoil_two_speed = aloop.supplyComponents(OpenStudio::Model::CoilCoolingDXTwoSpeed::iddObjectType())
          if not dxcoil.empty? or not dxcoil_two_speed.empty?
            h = {}
            children = {}
            attributes = {}
            h[:children] = children
            h[:attributes] = attributes
            aircool = AirCooled.new(h)
            puts "Aircooled #{aircool}"

            h = {}
            children = {}
            attributes = {}
            h[:children] = children
            h[:attributes] = attributes
            children[:AirCooled] = { value: aircool }
            attributes[:ID] = { value: handle }
            #puts attributes
            cl = CondenserPlantType.new(h)
            puts "Condenser #{cl.attributes}"
          end
        rescue
          h = {}
          children = {}
          attributes = {}
          h[:children] = children
          h[:attributes] = attributes
          attributes[:ID] = { value: "undef-condenserplant" }
          cl = CondenserPlantType.new(h)
          throw "Error when creating CondenserPlant"
        ensure
          return cl
        end
      end
    end
    return nil
  end

  def makeHeatingPlant(model, handle)
    @plant_loops.each do |plant_loop|
      if plant_loop.handle.to_s == handle
        begin
          boiler = plant_loop.supplyComponents(OpenStudio::Model::BoilerHotWater::iddObjectType())
          boiler = model.getObject(boiler[0].handle)
          
          b = boiler.get.to_BoilerHotWater.get
          
          puts b
          h = {}
          children = {}
          attributes = {}
          h[:children] = children
          h[:attributes] = attributes
          children[:BoilerType] = { value: BoilerType.new({ value: "Hot water" }) }
          children[:ThermalEfficiency] = { value: ThermalEfficiency.new({ text: b.nominalThermalEfficiency }) }
          if not b.nominalCapacity.empty?
            children[:OutputCapacity] = { value: OutputCapacity.new({ text: b.nominalCapacity.get }) }

            children[:CapacityUnits] = { value: CapacityUnits.new({ text: "kW"}) }
          end

          #TODO: figure out why this is not working
          puts b.designWaterOutletTemperature.get
          #children[:BoilerLWT] = { value: BoilerLWT.new({ text: b.designWaterOutletTemperature.get.to_s })}
          boiler = Boiler.new(h)
          #puts boiler
          h = {}
          children = {}
          attributes = {}
          h[:children] = children
          h[:attributes] = attributes
          children[:Boiler] = { value: boiler}
          attributes[:ID] = { value: handle }
          hpt = HeatingPlantType.new(h)
          #puts "Returning heating plant type #{hpt}"

        rescue
          h = {}
          children = {}
          attributes = {}
          h[:children] = children
          h[:attributes] = attributes
          attributes[:ID] =  { text: "undefined-heatingplant"}
          hpt = HeatingPlantType.new(h)
          throw "An error occurred making the Heating Plant for plant handle #{handle}"

        ensure
          puts "Ensuring in case"
          return hpt
        end
      end
    end
    #if nothing
    return nil
  end
end

#creates lighting systems for the Systems Element
class LightingSystemsHelper
  attr_accessor :lighting_systems
  def initialize(model)
    #currently the initialization method is designed to create one lighting system for each space
    lightingsystems = []
    model.getSpaces.each do |os_space|
      #puts " #{os_space.thermalZone.get.equipment}"
      h={}
      children = {}
      attributes = {}
      h[:children] = children
      h[:attributes] = attributes
      attributes[:ID] = { value: os_space.handle.to_s + "-lighting" }
      children[:InstalledPower] = { value: InstalledPower.new({ text: os_space.lightingPower.round(3) })}
      children[:Location] = { value: Location.new({ text: "Interior" })}

      #linked premises
      #at a minimum, we want the space object which contains a linked space id and a set of schedules
      #work inside out, schedules, space id, and then linked premises
      lsh = {}
      lchildren = {}
      lattributes = {}
      lsh[:children] = lchildren
      lsh[:attributes] = lattributes
      lattributes[:IDref] = { value: os_space.handle.to_s }
      lsid = LinkedSpaceID.new(lsh)
     #puts lsid

      sh = {}
      schildren = {}
      sattributes = {}
      sh[:children] = schildren
      sh[:attributes] = sattributes
      lsidarray = []
      lsidarray.push(lsid)
      schildren[:LinkedSpaceID] = { value: lsidarray }
     #puts sh
      sp = Space.new(sh)
     #puts sp

      lph = {}
      lphchildren = {}
      lphattributes = {}
      lph[:children] = lphchildren
      lph[:attributes] = lphattributes
      lphchildren[:Space] = { value: sp } #space is child of LinkedPremises
      lp = LinkedPremises.new(lph)
     #puts lp

      children[:LinkedPremises] = { value: lp } #LinkedPremises is child of LightingSystemType
      # os_space.thermalZone.get.equipment.each do |equip|
      #  #puts "#{equip}"
      # end
      lstype = LightingSystemType.new(h)
      lightingsystems.push(lstype)
    end
    h={}
    children = {}
    attributes = {}
    h[:children] = children
    h[:attributes] = attributes
    children[:LightingSystem] = { value: lightingsystems }

    @lighting_systems = LightingSystems.new(h)
  end
end

class OccupancyClassificationHelp

  def initialize;end
  def getOccupancyClassificationFromOS(os_type_name)
    #important that the string assigned to type matches the allowed enumerations for OccupancyClassification
    type = nil
    if(/classroom/i =~ os_type_name)
      type = "Classroom"
    elsif /lobby/i =~ os_type_name
      type = "Classroom"
    elsif /corridor/i =~ os_type_name
      type = "Corridor"
    elsif /restroom/i =~ os_type_name
      type = "Restroom"
    elsif /gym/i =~ os_type_name
      type = "Sport play area"
    elsif /office/i =~ os_type_name
      type = "Office"
    elsif /kitchen/i =~ os_type_name #TODO: what is the difference between a kitchen and a kitchenette?
      type = "Kitchen"
    elsif /cafeteria/i =~ os_type_name
      type = "Dining area"
    elsif /mechanical/i =~ os_type_name
      type = "Mechanical room"
    else
      raise "Could not find Occupancy Classification for #{os_type_name}"
    end

    #make Occupancy Classification
    if not type == nil
      return OccupancyClassification.new({ text: type })
    else
      #TODO:  We need some sort of discussion on standard errors returned when a helper method fails
    end
  end
end

class PlugLoadsHelper
  attr_accessor :plug_loads
  def initialize(model)
    plugsystems = []
    model.getSpaces.each do |os_space|
      #puts " #{os_space.thermalZone.get.equipment}"
      h={}
      children = {}
      attributes = {}
      h[:children] = children
      h[:attributes] = attributes
      attributes[:ID] = { value: os_space.handle.to_s + "-plugs" }
      #puts "Plug power #{os_space.electricEquipmentPower}"
      #children[:PlugLoadNominalPower] = { value: PlugLoadNominalPower.new({ text: os_space.electricEquipmentPower.round(3) }) }
      children[:Location] = { value: Location.new({ text: "Interior" })}
      children[:PlugLoadType] = { value: PlugLoadType.new({ text: "Unknown" }) }
      #linked premises
      #at a minimum, we want the space object which contains a linked space id and a set of schedules
      #work inside out, schedules, space id, and then linked premises

      lsh = {}
      lchildren = {}
      lattributes = {}
      lsh[:children] = lchildren
      lsh[:attributes] = lattributes
      lattributes[:IDref] = { value: os_space.handle.to_s }
      lsid = LinkedSpaceID.new(lsh)#puts lsid

      sh = {}
      schildren = {}
      sattributes = {}
      sh[:children] = schildren
      sh[:attributes] = sattributes
      lsidarray = []
      lsidarray.push(lsid)
      schildren[:LinkedSpaceID] = { value: lsidarray }#puts sh
      sp = Space.new(sh)#puts sp

      lph = {}
      lphchildren = {}
      lphattributes = {}
      lph[:children] = lphchildren
      lph[:attributes] = lphattributes
      lphchildren[:Space] = { value: sp } #space is child of LinkedPremises
      lp = LinkedPremises.new(lph)#puts lp

      children[:LinkedPremises] = { value: lp } #LinkedPremises is child of LightingSystemType
      # os_space.thermalZone.get.equipment.each do |equip|
      #puts "#{equip}"
      # end
      lstype = PlugLoad.new(h)
      plugsystems.push(lstype)
    end
    h={}
    children = {}
    attributes = {}
    h[:children] = children
    h[:attributes] = attributes
    children[:PlugLoad] = { value: plugsystems }

    @plug_loads = PlugLoads.new(h)
  end

end


class SchedulesHelp

  def initialize; end

  def make_bs_schedules(os_schedules)
    #make building sync schedules array
    schedules_h = {}
    schedules_h[:children] = {}

    os_schedules.each do |os_schedule|
      #make a ScheduleType
      h = {}
      children = {}
      attributes = {}
      h[:children] = children
      h[:attributes] = attributes
      attributes[:ID] = { :value => os_schedule.handle.to_s }
      #puts os_schedule

      if not os_schedule.to_ScheduleRuleset.empty?
        rules = os_schedule.to_ScheduleRuleset.get.scheduleRules
        
        start_date = nil
        end_date= nil
        ruleset_name = nil
        detailsvector = []
        h_details = {}
        h_details[:children] = {}
        h_details[:attributes] = {}

        rules.each do |rule|
          if not rule.startDate.empty?
            if(start_date.nil?)
              children[:SchedulePeriodBeginDate] = SchedulePeriodBeginDate.new(text: rule.startDate.get)
              start_date = rule.startDate.get
            elsif(rule.startDate.get != start_date)
              detailsvector.push(ScheduleDetails.new({ children: h_details[:children] })) #set the details vector
              children[:ScheduleDetails] = { value: detailsvector }

              children[:SchedulePeriodBeginDate] = SchedulePeriodBeginDate.new(text: rule.startDate.get) #start over again
              start_date = rule.startDate.get
              detailsvector = Array.new
            else
              #don't make anything new
            end
          else
            #RODO: #put some error there is no start date
          end
          if not rule.endDate.empty?
            if(end_date.nil?)
              children[:SchedulePeriodEndDate] = SchedulePeriodEndDate.new(text: rule.endDate.get)
              end_date = rule.endDate.get
            elsif(rule.startDate.get != end_date)
              children[:SchedulePeriodEndDate] = SchedulePeriodEndDate.new(text: rule.endDate.get)
              end_date = rule.endDate.get
            else
              #don't make anything new
            end
            
          else
            #TODO:  #put some error there is no end date
          end
          #make ScheduleDetails
          #puts rule
          
          if(rule.applyMonday&&rule.applyTuesday&&rule.applyWednesday&&rule.applyThursday&&rule.applyFriday)
            if(rule.applySunday&&rule.applySaturday)
              dt = DayType.new(text:"All week")
              daytypevector.push(dt)
            else
              dt = DayType.new(text:"Weekday")
              daytypevector.push(dt)
            end
            
          elsif(rule.applySaturday && rule.applySunday)
            dt = DayType.new(text:"Weekend")
            daytypevector.push(dt)
          else
            if(rule.applyMonday)
              dt = DayType.new(text:"Monday")
              daytypevector.push(dt)
            elsif rule.applyTuesday
              dt = DayType.new(text:"Tuesday")
              daytypevector.push(dt)
            elsif rule.applyWednesday
              dt = DayType.new(text:"Wednesday")
              daytypevector.push(dt)
            elsif rule.applyThursday
              dt = DayType.new(text:"Thursday")
              daytypevector.push(dt)
            elsif rule.applyFriday
              dt = DayType.new(text:"Friday")
              daytypevector.push(dt)
            elsif rule.applySaturday
              dt = DayType.new(text:"Saturday")
              daytypevector.push(dt)
            elsif rule.applySunday
              dt = DayType.new(text:"Sunday")
              daytypevector.push(dt)
            else #TODO: Is there really no applyHoliday?
              dt = DayType.new(text:"Holiday")
              daytypevector.push(dt)
            end
              
          end
          #rule.applyMonday good

          #puts rule.daySchedule
        end #end rules do
        #not sure how to do ScheduleCateogory
        
      end

      #rules = os_schedule.scheduleRules
      #day_schedules = os_schedule
    end
  end
end

class SidesHelper
  attr_accessor :sides
  def initialize(sides)
    h={}
    children = {}
    h[:children] = children
    children[:Side] = { value: sides }
    @sides = Sides.new(h)
  end
end

class SideLengthHelper
  attr_accessor :side_length

  def initialize(side)
    #relies on GeoHelp for some stuff
    gh = GeoHelp.new()
    side.vertices.each_with_index do |vertex,index|
      if index == side.vertices.length - 1 
        break
      end
      nexti = index+1
      v1 = gh.SpaceVector(vertex,side.vertices[nexti])
      xp = gh.UnitVector(gh.XProduct(v1,gh.ZUnit))
      if(xp[:x] == 0 && xp[:y] == 0 && xp[:z] == 0)
        #parallel (meaning it is a vertical, so we don't want to use it.)
        #could be improved to be based on a tolerance as opposed to an absolute number like 0
      else
        #puts "Finding Magnitude"
        mag = gh.MagnitudeVector(v1) #TODO: improve so this conversion from meters to feet is not hardcoded.
        mag = Conversions.new().convertLength(mag)
        @side_length = SideLength.new({ text: mag })
        #puts "Created Side Length of: ", sl.text
        
      end
    end
    v1 = gh.SpaceVector(side.vertices[0], side.vertices[-1])
    xp = gh.UnitVector(gh.XProduct(v1,gh.ZUnit))
    if(xp[:x] == 0 && xp[:y] == 0 && xp[:z] == 0)
      #parallel (meaning it is a vertical, so we don't want to use it.)
      #could be improved to be based on a tolerance as opposed to an absolute number like 0
    else
      #puts "Finding Magnitude"
      mag = gh.MagnitudeVector(v1) #TODO: improve so this conversion from meters to feet is not hardcoded.
      mag = Conversions.new().convertLength(mag)
      @side_length = SideLength.new({ text: mag })
      #puts "Created Side Length of: ", sl.text
    end
  end

end

class SiteHelper
  attr_accessor :site
  def initialize(os_model)
    os_site = os_model.getSite
    os_weather = os_model.getWeatherFile

    wname = os_weather.dataSource
    wmo = os_weather.wMONumber
    lat = os_weather.latitude
    long = os_weather.longitude
    
    h={}
    children={}
    attributes = {}
    h[:children] = children
    h[:attributes] = attributes
    attributes[:ID] = { value: "Site-1" }
    
    children[:WeatherStationID] = { value: WeatherStationID.new({ text: wmo })}
    children[:Latitude] = { value: Latitude.new({ text: lat })}
    children[:Longitude] = { value: Longitude.new({ text: long }) }
    if not os_weather.url.empty?
      url = os_weather.url.get
      #TODO: regex this to cut down on the url size
      children[:WeatherStationName] = { value: WeatherStationName.new({ text: url }) }
    end

    #add a facility
    f = FacilitiesHelper.new(os_model)
    children[:Facilities] = { value: f.facilities }
    @site = SiteType.new(h)

  end
end

class SpaceHelper
  attr_accessor :space 
  def initialize(os_space)
    h={}
    children={}
    attributes = {}
    h[:children] = children
    h[:attributes] = attributes
    attributes[:ID] = { value: "space-" + os_space.handle.to_s } 


    #get floor areas
    fah = FloorAreasHelper.new(Conversions.new().convertArea(os_space.floorArea))
    children[:FloorAreas] = { value: fah.floor_areas }
    #get premises name
    children[:PremisesName] = { value: PremisesName.new({ text: os_space.name.get }) }
    #OccupancyScheduleID

    #OccupancyLevels

    #get the occupancy classification
    if not os_space.spaceType.empty?
      type = os_space.spaceType.get
      oc = OccupancyClassificationHelp.new()
      occClass = oc.getOccupancyClassificationFromOS(type.name.get) 
      children[:OccupancyClassification] = { value: occClass}
      #p "Occ class #{occClass}"
    else
      raise "Boost Optional Get Error for Space when getting type"
    end
    #get the thermal zone
    if not os_space.thermalZone.empty?
      tz = os_space.thermalZone.get
      if(tz.isPlenum)
        #don't put conditioned volume
      else
        #puts "isn't plenum"
        #TODO make it possible to use alternative means to figure if it is conditioned.  For now, we assume it is by default
        #puts Conversions.new().convertVolume(os_space.volume)
        children[:ConditionedVolume] = { value: ConditionedVolume.new({ text: Conversions.new().convertVolume(os_space.volume) }) }
      end
    else
      raise "Boost Optional Get Error for Space when getting Thermal Zone"
    end

    #have made areas, volumes, occupancy classifications
    @space = SpaceType.new(h)
    rescue
      @space = SpaceType.new(h)

  end

  
  #deprecated TODO: consider removal as is incomplete
  def makeSpaces(os_spaces)
    #puts "Making spaces now"
    os_spaces.each_with_index do |space, index|
      h={}
      children={}
      attributes = {}
      h[:children] = children
      h[:attributes] = attributes
      attributes[:ID] = { :value => 'Space-'+index.to_s } 
      #puts "#{space}"
      if(not space.spaceType.empty?)
        stype = space.spaceType.get
        #puts "#{stype}"
        oc = OccupancyClassificationHelp.new()
        occClass = oc.getOccupancyClassificationFromOS(stype.name.get) #TODO: can I get the standards type instead of name?
        children[:OccupancyClassification] = { value: occClass}
      else

      end
      pn = PremisesName.new({ text: space.name })
      children[:PremisesName] = { value: pn }
      # #puts "Space #{space.thermalZone}" 
      # if not space.thermalZone.empty?
      #   tz = space.thermalZone.get
      #   #puts "#{tz}"
      # else
      # end


      children[:FloorAreas] = { value: fah.floor_areas }


    end
  end
end


class SystemsHelper

end


class SubsectionsHelper
  attr_accessor :subsections

  def initialize(os_model)
    #make subsections and all children
    subsections_arr = []
    spaces = os_model.getSpaces
    spaces.each do |os_space|
      subsection_id = "subsection-" + os_space.handle.to_s
      #make thermal zones
      tzh = ThermalZonesHelper.new(os_space)
      
      #make Subsection
      h={}
      children = {}
      attributes = {}
      h[:attributes] = attributes
      h[:children] = children
      attributes[:ID] = { value: subsection_id }
      children[:ThermalZones] = { value: tzh.thermal_zones }

      #make the basics for the subsection
      children[:PremisesName] = { value: PremisesName.new({ text:os_space.name.get + " Block" })}
      #TODO better method for footprint shape
      children[:FootprintShape] = { value: FootprintShape.new( { text:"Rectangular" } )}
      children[:ThermalZoneLayout] = { value: ThermalZoneLayout.new( { text:"Single zone" } )}

      #make sides
      bs_surfs = SurfacesHelper.new({ os_surfaces: os_space.surfaces })
      children[:Sides] = { value: bs_surfs.sides }
      children[:RoofID] = { value: bs_surfs.roofs }
      children[:FoundationID] = { value: bs_surfs.foundations }
      children[:CeilingID] = { value: bs_surfs.ceilings }
      #puts "Surfaces to be made sides etc. #{bs_surfs}"
      subsections_arr.push(Subsection.new(h))
    end


    h = {}
    children = {}
    h[:children] = children
    children[:Subsection] = { value: subsections_arr }
    @subsections = Subsections.new(h)


  end
end

#because of the nature of the test cases, currently there is one zone per thermal zones array and one space per zone.  TODO: Better zone and space management.
class ThermalZonesHelper
  attr_accessor :thermal_zones, :thermal_zone
  def initialize(os_space)
    #for the thermal zone stuff
    h = {}
    children = {}
    attributes = {}
    h[:children] = children
    h[:attributes] = attributes
    

    if not os_space.thermalZone.empty?
      tz = os_space.thermalZone.get
      zone_id = tz.handle.to_s
      attributes[:ID] = { value: zone_id }
      if not tz.name.empty?
        children[:PremisesName] = { value: PremisesName.new({ text: tz.name.get.to_s }) }
        if not tz.thermostatSetpointDualSetpoint.empty?
          tstat = tz.thermostatSetpointDualSetpoint.get
          #puts "Tstat #{tstat}"

          #hvacID schedules
          hvac_ids = []
          if not tstat.coolingSetpointTemperatureSchedule.empty?
            stpt_cool = tstat.coolingSetpointTemperatureSchedule.get
            #p "Setpoint cool #{stpt_cool.handle}"
            ch={}
            cattributes = {}
            ch[:attributes] = cattributes
            cattributes[:ID] = { value: stpt_cool.handle.to_s }
            hvac_ids.push(HVACScheduleID.new(ch))

          else
            raise "Boost Optional Get Error for Thermal Zone when getting Setpoint Cool Sch"
          end

          stpt_heat_handle =  tstat.heatingSetpointTemperatureSchedule.get.handle
          #puts "Setpoint heat #{stpt_heat_handle}"
          hh = {}
          hattributes = {}
          hh[:attributes] = hattributes
          hattributes[:ID] = { value: stpt_heat_handle.to_s }
          hvac_ids.push(HVACScheduleID.new(hh))

          children[:HVACScheduleID] = { value: hvac_ids }


        else
          raise "Boost Optional Get Error for Thermal Zone when getting Dual Setpoint Thermostat"
        end
      else
        raise "Boost Optional Get Error for Thermal Zone when getting Zone Name"
      end
    else
      raise "Boost Optional Get Error for Thermal Zone when getting Thermal Zone from Space"
    end

    #make space stuff
    sh = SpaceHelper.new(os_space)
   #puts sh.space

    shash = {}
    sattr = {}
    shash[:attributes] = sattr
    schild = {}
    shash[:children] = schild
    schild[:Space] = { value: [sh.space] }
    spaces = Spaces.new(shash)

    children[:Spaces] = { value: spaces }
    @thermal_zone = ThermalZoneType.new(h)
   #puts @thermal_zone.children
    #make thermalzones object

    h={}
    children = {}
    attributes = {}
    h[:children] = children
    h[:attributes] = attributes
    children[:ThermalZone] = { value: [@thermal_zone] }
    @thermal_zones = ThermalZones.new(h)
    rescue
      @thermal_zone = ThermalZoneType.new(h)
      h={}
      children = {}
      attributes = {}
      h[:children] = children
      h[:attributes] = attributes
      children[:ThermalZone] = { value: [@thermal_zone] }
      @thermal_zones = ThermalZones.new(h)
  end
end

class WallIDHelper
  attr_accessor :wall_id
  def initialize(side)
    #reliance on GeoHelp
    gh = GeoHelp.new()
    if(side.vertices.length == 4)
      h = {}
      if not side.construction.empty?
        construction = side.construction.get
        #puts "Making wallID for construction #{construction.handle}"
        h[:attributes] = { IDref: { value: construction.handle.to_s } }
        wallarea = gh.calculate_surface_area(side.vertices)
        wa = WallArea.new({ text: wallarea })
        h[:children] = { WallArea: { required: false, value: wa } }
      else

      end
    else
      #lets just not write the algorithm yet to determine the wall area for this more complicated case
      #puts "WARNING: Surface area could not be calculated for WallID"
      if not side.construction.empty?
        construction = side.construction.get
        h[:attributes] = { IDref: { text: construction.handle.to_s } }
      end
    end
    @wall_id = WallID.new(h)
  end
end

#general purpose helpers
class Conversions
  attr_accessor :round_place
  def initialize(round=nil)
    if(round.nil?)
      @round_place = 2
    else
      @round_place = round
    end
  end
  def convertArea(area)
    return (area / 0.3048 / 0.3048).round(round_place)
  end
  def convertLength(length)
    return (length / 0.3048).round(round_place)
  end
  def convertVolume(volume)
    return (volume / 0.3048 / 0.3048 / 0.3048).round(round_place)
  end
end

class GeoHelp

  attr_accessor :sides, :os_sides, :roofs, :os_roofs, :os_ceilings, :foundations, :os_foundations

  def initialize
    @sides = []
    @os_sides = []
    @roofs = []
    @os_roofs = []
    @os_ceilings = []
    @foundations = []
    @os_foundations = []
  end

  def toDeg(rads)
    return rads*180/Math::PI
  end

  def ZUnit
    return { x: 0, y: 0, z: 1}
  end

  def MagnitudeVector(v)
    return Math.sqrt(v[:x] ** 2 + v[:y] ** 2 + v[:z] ** 2)
  end

  def UnitVector(v)
    mag = MagnitudeVector(v)
    x = v[:x]/ mag
    y = v[:y]/ mag
    z = v[:z]/ mag
    return { x: x, y: y, z: z}
  end

  #a method to make a Vector in 3D Space from two Point3Ds
  def SpaceVector(p1,p2)
    #puts "Passed vertices #{p1} #{p2}"
    x = p1.x - p2.x
    y = p1.y - p2.y
    z = p1.z - p2.z
    return { x: x, y: y, z: z}
  end

  #a Method to find the cross product of two vectors in 3D Space
  def XProduct(v1,v2)
    x = v1[:y] * v2[:z] - v2[:y] * v1[:z]
    y = v1[:x] * v2[:z] - v1[:z] * v2[:x]
    z = v1[:x] * v2[:y] - v1[:y] * v2[:x] 
    return { x: x, y: y, z: z}
  end

  #calculates the surface area from an open studio surface
  def calculate_surface_area(vertices)
    if(vertices.length == 4)
      #we are going to assume for now that the surface is a square or rectangle (normal)
      v1 = self.SpaceVector(vertices[0],vertices[1])
      v2 = self.SpaceVector(vertices[1],vertices[2])
      mag1 = self.MagnitudeVector(v1)
      mag2 = self.MagnitudeVector(v2)
      area = Conversions.new().convertArea(mag1 * mag2)
      return area
    else
      raise "WARNING, surface area could not be calculated."
    end
  end
  #checks if an open studio surface is planar
  def isPlanar(surface)
    surface.vertices.each_with_index do |vertex, index|
      if (index == surface.vertices.length - 2)
        break;
      else
        nexti = index+1
        v1 = self.SpaceVector(vertex,surface.vertices[nexti])
        twonexti = index+2
        v2 = self.SpaceVector(surface.vertices[nexti],surface.vertices[twonexti])
        #cross produce
        xp = self.XProduct(v1,v2)

      end
    end

  end

  #passed open studio OpenStudio Point3d vector
  def getFootprintShape(flCoords)
    flCoords = "Checking floorshape algorithm"
    #algorithm to determine the shape TBD
    #puts flCoords
    retval = FootprintShape.new({ text: "Rectangular" })
    return retval
  end

  #deterimines if side length can be computed, if it can, it is computed and returned
  #deprecated TODO: remove
  # def makeSideLength(side)
  #   #puts "Finding Side Length"
  #   side.vertices.each_with_index do |vertex,index|
  #     nexti = index+1
  #     v1 = self.SpaceVector(vertex,side.vertices[nexti])
  #     xp = self.UnitVector(XProduct(v1,self.ZUnit))
  #     if(xp[:x] == 0 && xp[:y] == 0 && xp[:z] == 0)
  #       #parallel (meaning it is a vertical, so we don't want to use it.)
  #       #could be improved to be based on a tolerance as opposed to an absolute number like 0
  #     else
  #       #puts "Finding Magnitude"
  #       mag = MagnitudeVector(v1) #TODO: improve so this conversion from meters to feet is not hardcoded.
  #       mag = mag / 0.3048
  #       sl = SideLength.new({ text: mag })
  #       #puts "Created Side Length of: ", sl.text
  #       return sl
  #     end
  #   end
  # end

  def makeSubSurfaces(side)
    #puts "Making subsurface"
    fenestrationareas = {}
    side.subSurfaces.each do |sub|
      if(/window/i =~ sub.subSurfaceType)
        #puts "Making a WindowID subsurface #{sub.construction.get.name.get}"
        if not sub.construction.empty? #TODO: change to initialized?
          construction = sub.construction.get
          if not construction.name.empty?
            warea = self.calculate_surface_area(sub.vertices)
            name = construction.name.get
            if(fenestrationareas.has_key? name)
              fenestrationareas[name][:text] += warea
            else
              fa = FenestrationArea.new({ text: warea })
              fenestrationareas[name] = fa
            end
          else
            #puts "WARNING: there is no construction name associated with this subsurface #{sub.name}, it could not be created in BuildingSync."
          end
        else
          #puts "WARNING: there is no construction name associated with this subsurface #{sub.name}, it could not be created in BuildingSync."
        end
      else
        #puts "WARNING: Unknown subsurface type.  Not creating."
      end
    end

    ret = {}
    ret[:WindowID] = []
    wallarea = self.calculate_surface_area(side.vertices)
    fenestrationareas.keys.each do |k|
      wwr = (fenestrationareas[k].text / wallarea).round(3) #TODO, should this be hardcoded rounding
      ww = WindowToWallRatio.new({ text: wwr })
      pws = PercentOfWindowAreaShaded.new({ text: 0 }) #TODO, could be improved, but unclear how
      h = {}
      children = {}
      children[:FenestrationArea] = { :value => fenestrationareas }
      children[:WindowToWallRatio] = { :value => ww }
      children[:PercentOfWindowAreaShaded] = { :value => pws }
      attributes = { :IDref => { text: k } }
      h[:children] = children
      h[:attributes] = attributes
      windowID = WindowID.new(h)
      ret[:WindowID].push(windowID)
    end

    #TODO: same for DoorID
    return ret

  end

  #deprecated TODO: remove
  # def makeWallID(side)
  #   #puts "Making WallID"
  #   if(side.vertices.length == 4)
  #     h = {}
  #     if not side.construction.empty?
  #       construction = side.construction.get
  #       if not construction.name.empty?
  #         p "Making wallID for construction #{construction.handle}"
  #         h[:attributes] = { :IDref => { text: construction.handle.to_s } }
  #         wallarea = self.calculate_surface_area(side.vertices)
  #         wa = WallArea.new({ text: wallarea })
  #         h[:children] = { :WallArea => { :required => false, :value => wa } }
          
  #       else
  #         #throw an error that this could not be gotten and the WallID could not be made
  #       end
  #     end
  #   else
  #     #lets just not write the algorithm yet
  #     #puts "WARNING: Surface area could not be calculated for WallID"
  #     if not side.construction.empty?
  #       construction = side.construction.get
  #       if not construction.name.empty?
  #         h[:attributes] = { :IDref => { text: construction.handle.to_s } }
  #       end
  #     end
  #   end
  #     wid = WallID.new(h)
  #     return wid
  # end

  def explainTry
    begin 
      a = 5 / 0
    rescue
      a = 0
    ensure
      #puts "i always run"
    end
  end


  def explainTry2
    a = 5/0
  rescue
    a = nil
  end



  def getZoneLayout(geometry)
    #an algorithm to figure out the type of ThermalZoneLayout
  end

  #deprecated #TODO: remove
  # def defineSidesFromOS_Surfaces(args)
  #   #classify the shape in order to understand how to write the sides
  #   #cannot run this method if these arguments are not passed in
  #   if(([:os_surfaces, :os_constructions] - args.keys).empty?)
  #     foundations = []
  #     subsurfbool = false

  #     shape = "Rectangular" #TODO: shape should be determined based on the floor, or passed into this method
  #     args[:os_surfaces].each do |surface|
  #       #puts "Surface tilt:",toDeg(surface.tilt)
  #       if(surface.subSurfaces.length > 0) 
  #         subsurfbool = true
  #       end

  #       if(toDeg(surface.tilt) > 45 && toDeg(surface.tilt) <= 135)
  #         #puts "Found OS side."
  #         self.os_sides.push(surface)
  #       elsif (toDeg(surface.tilt) > 135)
  #         foundations.push(surface)
  #         if(surface.isPartOfEnvelope)
  #           self.os_foundations.push(surface)
  #         else
  #           #TODO:  do nothing?  or is this a ceiling?
  #         end
  #         #this is what I need to figure out the footprint shape
  #         if(surface.vertices.length == 4)
  #           shape = "Rectangular"
  #         else
  #           #shape should be something else
  #           #puts "Unhandled floor shape exception: vertices are not equal to 4."
  #         end
          
  #       else
  #         #determine the difference between a ceiling and a roof
  #         if(surface.isPartOfEnvelope)
  #           self.os_roofs.push(surface)
  #         else
  #           self.os_ceilings.push(surface)
  #         end
  #       end
  #     end #end the looping through all os_surfaces
  #     #puts "Found #{self.os_sides.length} sides in OS"
  #     #puts "Found #{self.os_foundations.length} foundations in OS"
  #     #puts "Found #{self.os_roofs.length} in OS"
  #     #make roofids
  #     self.os_roofs.each do |os_roof|
  #       h={}
  #       subsurfbool = false #needs to be reset #TODO: this could be made much more programmer friendly
  #       attributes = {}
  #       children = {}
  #       h[:children] = children
  #       h[:attributes] = attributes
  #       if not os_roof.construction.empty?
  #         if not os_roof.construction.get.name.empty?
  #           name = os_roof.construction.get.name.get
  #           attributes[:IDref] = { text: name }
  #           roofarea = self.calculate_surface_area(os_roof.vertices)
  #           ra = RoofArea.new({ text: roofarea })
  #           ria = RoofInsulatedArea.new({ text: roofarea }) #TODO: need to find a more robust way of checking for this
  #           children[:RoofArea] = { :required => false, value: ra }
  #           children[:RoofInsulatedArea] = { :required => false, value: ria }
  #           skylights= []
  #           if(os_roof.subSurfaces.length > 0)
  #             os_roof.subSurfaces.each do |sub|
  #               id = sub.construction.get.name.get
  #               skyarea = self.calculate_surface_area(sub.vertices)
  #               if(skylights.has_key? id)
  #                 skylights[id][:text] += skyarea/roofarea
  #               else

  #                 pa = PercentageSkylightArea.new({ text: skyarea/roofarea })
  #                 skylight = new.SkylightID({:attributes => {:IDref=>id } },{:children => pa})
  #                 skylights.push(skylight) 
  #               end
  #             end
  #             children[:SkylightID] = { :required => false, value: skylights }
  #           end
  #           bs_roof = RoofID.new(h)
  #           self.roofs.push(bs_roof)
  #         end
  #       end
  #     end
  #     #make foundation ids
  #     self.os_foundations.each do |os_foundation|
  #       #the root of FoundationID
  #       h = {}
  #       attributes = {}
  #       children = {}
  #       h[:children] = children
  #       h[:attributes] = attributes
  #       if not os_foundation.construction.empty?
  #         if not os_foundation.construction.get.name.empty?
  #           name = os_foundation.construction.get.name.get
  #           attributes[:IDref] = { text: name }
  #           floorarea = self.calculate_surface_area(os_foundation.vertices)
  #           fa = FoundationArea.new({ text: floorarea })
  #           children[:FoundationArea] = { required: false, value: fa }
  #           if not os_foundation.space.empty?
  #             if not os_foundation.space.get.name.empty?
  #               spacenm = os_foundation.space.get.name.get
  #               #puts "Foundation space name #{spacenm}"
  #             else
  #               #puts "WARNING: Unknown space name for this foundation #{os_foundation.name}"
  #             end
  #           else
  #             #puts "ERROR: Unknown space for this foundation #{os_foundation.name}"
  #           end
  #           #skipping the slab insulation orientation
            
  #         end #TODO, consider adding an error if the name is not available
  #       end #TODO, consider adding an error if the construction is not available
  #       #we assume that all of the foundations are just slab on grade
  #       #should we #put in a second check to see if the z-level is 0 for this slab? 
  #       #or do we look at outdoor conditions = ground?
        
  #     end
  #     #this should be moved as a test inside of the sides each do loop?
  #     if(shape == "Rectangular")
  #       #puts "Making sides."
  #       self.os_sides.each do |os_side|
  #         subsurfbool = false #needs to be reset #TODO: this could be made much more programmer friendly
  #         #puts "Is part of Envelope? ",side.isPartOfEnvelope
  #         #puts "Azimuth: ", toDeg(side.azimuth)
  #         #puts "Number of subsurfaces: #{os_side.subSurfaces.length}"
          
  #         if(os_side.isPartOfEnvelope)
  #           h = {}
  #           sl = self.makeSideLength(os_side)
  #           wid = self.makeWallID(os_side)
  #           if(os_side.subSurfaces.length >= 1)
  #             subs = self.makeSubSurfaces(os_side) #returns a hash of Fenestration and Door arrays as {:WindowID => [], :DoorID =>[]}
  #             #puts "Subsurface objects created: #{subs}"
  #             h[:WindowID] = { :value => subs[:WindowID] }
  #           end

  #           h[:SideLength] = { :required => false, value: sl }
  #           h[:WallID] = { :required => false, value: wid }
  #           if(toDeg(os_side.azimuth) == 0)
  #             if(os_side.isPartOfEnvelope)
  #               #puts "Making Rect A1"
  #               sn = SideNumber.new({ text: "A1" })
  #               h[:SideNumber] = { :required => false, value: sn }
  #               #puts "Completed Rect A1", sides
  #             else #puts "Is not part of envelope, will not write out."
  #             end
  #           elsif(toDeg(os_side.azimuth) == 90)
  #             if(os_side.isPartOfEnvelope)
  #               sn = SideNumber.new( text: "B1")
  #               h[:SideNumber] = { :required=>false,value: sn }
  #               #puts "Completed Rect B1", sides
  #             else #puts "Is not part of envelope, will not write out."
  #             end
  #           elsif(toDeg(os_side.azimuth) == 180)
  #             if(os_side.isPartOfEnvelope)
  #               sn = SideNumber.new( text: "C1")
  #               h[:SideNumber] = { :required=>false,value: sn }
  #               #puts "Completed Rect C1", sides
  #             else #puts "Is not part of envelope, will not write out."
  #             end
  #           elsif(toDeg(os_side.azimuth) == 270)
  #             if(os_side.isPartOfEnvelope)
  #               sn = SideNumber.new( text: "D1")
  #               h[:SideNumber] = { :required=>false,value: sn }
  #               #puts "Completed Rect D1", sides
  #             else #puts "Is not part of envelope, will not write out."
  #             end
  #           else
  #             #puts "WARNING: Unhandled side creation for rectangular shape."
  #           end 
  #           en = {:children => h}
  #           #puts "Making side"
  #           bs_side = Side.new(en)  
  #           #puts "Made side #{bs_side.children}"
  #           self.sides.push(bs_side)
  #         end
  #       end
  #     else
  #       #puts "WARNING: Unhandled floor shape exception: not rectangular"
  #     end
  #     #puts "Sides created:", self.sides.length
  #     #puts "Roofs created:", self.roofs.length
  #   else
  #     #throw some error
  #   end
  # end

end

#classify the shape in order to understand how to write the sides
class SurfacesHelper
  attr_accessor :sides, :os_sides, :roofs, :os_roofs, :os_ceilings, :ceilings, :foundations, :os_foundations
  #returns the side
  def initialize(args)
    gh = GeoHelp.new() #requires geohelper to function
    @sides = []
    @os_sides = []
    @roofs = []
    @os_roofs = []
    @os_ceilings = []
    @ceilings = []
    @foundations = []
    @os_foundations = []


    #cannot run this method if these arguments are not passed in
    if(([:os_surfaces] - args.keys).empty?)
      foundations = []
      subsurfbool = false

      shape = "Rectangular" #TODO: shape should be determined based on the floor, or passed into this method
      args[:os_surfaces].each do |surface|
        #puts "Surface tilt:",toDeg(surface.tilt)
        if(surface.subSurfaces.length > 0) 
          subsurfbool = true
        end

        if(gh.toDeg(surface.tilt) > 45 && gh.toDeg(surface.tilt) <= 135) #GeoHelp
          #puts "Found OS side."
          @os_sides.push(surface)
        elsif (gh.toDeg(surface.tilt) > 135) #GeoHelp
          foundations.push(surface)
          if(surface.isPartOfEnvelope)
            @os_foundations.push(surface)
          else
           #puts "Found ceiling #{surface}"
            @os_ceilings.push(surface)
          end
          #this is what I need to figure out the footprint shape
          if(surface.vertices.length == 4)
            shape = "Rectangular"
          else
            #shape should be something else
            #puts "Unhandled floor shape exception: vertices are not equal to 4."
          end
          
        else
          #determine the difference between a ceiling and a roof
          if(surface.isPartOfEnvelope)
            @os_roofs.push(surface)
          else
           #puts "Found ceiling #{surface}"
            @os_ceilings.push(surface)
          end
        end
      end #end the looping through all os_surfaces
      #puts "Found #{@os_sides.length} sides in OS"
      #puts "Found #{@os_foundations.length} foundations in OS"
      #puts "Found #{@os_roofs.length} in OS"
      #make roofids
      @os_roofs.each do |os_roof|
        h={}
        subsurfbool = false #needs to be reset #TODO: this could be made much more programmer friendly
        attributes = {}
        children = {}
        h[:children] = children
        h[:attributes] = attributes

        name = os_roof.handle
        attributes[:IDref] = { value: name }
        roofarea = gh.calculate_surface_area(os_roof.vertices) #GeoHelp
        ra = RoofArea.new({ text: roofarea })
        ria = RoofInsulatedArea.new({ text:roofarea }) #TODO: need to find a more robust way of checking for this
        children[:RoofArea] = { value:ra }
        children[:RoofInsulatedArea] = { value:ria }
        skylights = []
       #puts "OS_Roof Subsurface length #{os_roof.subSurfaces.length}"
        if(os_roof.subSurfaces.length > 0)
         #puts "There are skylights, first time for everything."
          os_roof.subSurfaces.each do |sub|
            sah = {}
            sachildren = []
            saatts = []
            sah[:children] = sachildren
            sah[:attr_accessor] = saatts
            id = sub.handle
            skyarea = gh.calculate_surface_area(sub.vertices) #GeoHelp
            pa = PercentageSkylightArea.new({ text: skyarea/roofarea.round(3) })
            sachildren[:PercentageSkylightArea] = { value: pa }
            saatts[:IDref] = { value: id }
            skylight = SkylightID.new(sah)
            skylights.push(skylight) 
          end
        end
        children[:SkylightID] = { value: skylights }
        bs_roof = RoofID.new(h)
        @roofs.push(bs_roof)

      end
      #make foundation ids
      @os_foundations.each do |os_foundation|
        #the root of FoundationID
        h = {}
        attributes = {}
        children = {}
        h[:children] = children
        h[:attributes] = attributes
        #puts os_foundation
        attributes[:IDref] = { value: os_foundation.handle.to_s }
        floorarea = gh.calculate_surface_area(os_foundation.vertices) #GeoHelp
        fa = FoundationArea.new({ text: floorarea })
        children[:FoundationArea] = { value: fa }
        @foundations.push(FoundationID.new(h))

        #TODO: consider adding space names and thermal zone names.  For now, these are not included
        if not os_foundation.space.empty?
          if not os_foundation.space.get.name.empty?
            spacenm = os_foundation.space.get.name.get
            #puts "Foundation space name #{spacenm}"
          else
            #puts "WARNING: Unknown space name for this foundation #{os_foundation.name}"
          end
        else
          #puts "ERROR: Unknown space for this foundation #{os_foundation.name}"
        end
        #skipping the slab insulation orientation

        #we assume that all of the foundations are just slab on grade as defined in BuildingSync
      end

      @os_ceilings.each do |os_ceiling|
        h = {}
        attributes = {}
        children = {}
        h[:children] = children
        h[:attributes] = attributes
        attributes[:IDref] = { text: os_ceiling.handle.to_s }
        area = gh.calculate_surface_area(os_ceiling.vertices) #GeoHelp
        fa =CeilingArea.new({ text: floorarea })
        children[:CeilingArea] = { value: fa }
        #by its nature a ceiling has no insulation for commercial buildings?
        #TODO, this could be improved but the use case needs better explanation
        chilren[:CeilingInsulatedArea] = { value: CeilingInsulatedArea.new({ text: 0 })}
        @ceilings.push(CeilingID.new(h))
      end

      #this should be moved as a test inside of the sides each do loop?
      if(shape == "Rectangular")
        #puts "Making sides."
        @os_sides.each do |os_side|
          subsurfbool = false #needs to be reset #TODO: this could be made much more programmer friendly
          #puts "Is part of Envelope? ",side.isPartOfEnvelope
          #puts "Azimuth: ", toDeg(side.azimuth)
          #puts "Number of subsurfaces: #{os_side.subSurfaces.length}"
          
          if(os_side.isPartOfEnvelope)
            h = {}
            if(os_side.subSurfaces.length > 0)
              subs = gh.makeSubSurfaces(os_side) #returns a hash of Fenestration and Door arrays as {:WindowID => [], :DoorID =>[]}
              #puts "Subsurface objects created: #{subs}"
              h[:WindowID] = { :value => subs[:WindowID] }
            end

            h[:SideLength] = { :required => false, value:  SideLengthHelper.new(os_side).side_length }
            h[:WallID] = { :required => false, value:  WallIDHelper.new(os_side).wall_id }
            if(gh.toDeg(os_side.azimuth) == 0) #GeoHelp
              if(os_side.isPartOfEnvelope)
                #puts "Making Rect A1"
                sn = SideNumber.new({ text: "A1" })
                h[:SideNumber] = { :required => false, value: sn }
                #puts "Completed Rect A1", sides
              else #puts "Is not part of envelope, will not write out."
              end
            elsif(gh.toDeg(os_side.azimuth) == 90) #GeoHelp
              if(os_side.isPartOfEnvelope)
                sn = SideNumber.new( text: "B1")
                h[:SideNumber] = { :required=>false,value: sn }
                #puts "Completed Rect B1", sides
              else #puts "Is not part of envelope, will not write out."
              end
            elsif(gh.toDeg(os_side.azimuth) == 180) #GeoHelp
              if(os_side.isPartOfEnvelope)
                sn = SideNumber.new( text: "C1")
                h[:SideNumber] = { :required=>false,value: sn }
                #puts "Completed Rect C1", sides
              else #puts "Is not part of envelope, will not write out."
              end
            elsif(gh.toDeg(os_side.azimuth) == 270) #GeoHelp
              if(os_side.isPartOfEnvelope)
                sn = SideNumber.new( text: "D1")
                h[:SideNumber] = { :required=>false,value: sn }
                #puts "Completed Rect D1", sides
              else #puts "Is not part of envelope, will not write out."
              end
            else
              #puts "WARNING: Unhandled side creation for rectangular shape."
            end 
            en = {:children => h}
            #puts "Making side"
            bs_side = Side.new(en)  
            #puts "Made side #{bs_side.children}"
            @sides.push(bs_side)
          end
        end
      else
        #puts "WARNING: Unhandled floor shape exception: not rectangular"
      end
      #puts "Sides created:", @sides.length
      #puts "Roofs created:", @roofs.length
    else
      #throw some error
    end
  end
end

class WriteXML
  attr_accessor :makingArray, :mostRecentElement, :xmlDoc, :hasType, :typeSub

  def initialize
    @makingArray = false

    @xmlDoc = REXML::Document.new()
    #puts @xmlDoc.nil?
    @hasType = false
    @typeSub = ""
  end

  def WritePretty
    formatter = Formatters::Pretty.new(2)
    formatter.compact = true
    #xmlDoc.write(File.open("some.xml", "w"), 2)
    #formatter.write(@xmlDoc,"some.xml")
    File.open("some.xml", "w"){ |file| file.puts formatter.write(@xmlDoc.root,"")}
  end

  #this returns the immediate children and attributes as a hash instead of instance variables of the given class
  def to_hash(obj)

    hash = obj.instance_variables.each_with_object({}) { |var, hash| hash[var.to_s.delete("@").to_sym] = obj.instance_variable_get(var) }
    #puts "Basic to_hash #{hash}"
    allowable_keys = [:value,:text,:children,"value","text","children"]
    if(hash.is_a?(Hash))
      if(hash.keys.any? {|x| allowable_keys.include?(x) })
        if(hash.has_key?(:text) || hash.has_key?("text"))
          #write text for the latest element
          #puts "Route 1"
          textkey = hash.keys.find{ |k| k == :text || k == "text" }
          if(!hash[textkey].nil?)
            #puts "Route 1a"
            #do something, generally here we are at the end and there is a string, nothing to do
          end
        end
        if(hash.has_key? :value || hash.has_key?("value"))
          #is the value an array, or an object?
          #puts "Route 2"
          valuekey = hash.keys.find{ |k| k == :value || k == "value" }
          if(hash[valuekey].is_a?(Array))
            #puts "Route 2 - array"
            h[valuekey].each do |a|
              #this is an array each of which is supposed to be an object, that also has to be hashified
              #likely here is where we would have a recursive call
            end
          else
            #puts "Route 2 - value on #{valuekey}"
            if(hash[valuekey].is_a?(Hash))
              #I dont think this will happen anymore
            else
              #We will recurse on this object
              hash[valuekey] = to_hash(hash[valuekey])
            end
          end
        end
        if(hash.has_key?(:children) ||hash.has_key?("children"))
          #puts "Route 3"
          childrenkey = hash.keys.find{ |k| k == :children || k == "children" }
          if(hash[childrenkey].keys.length > 0)
            hash[childrenkey].keys.each do |k| #this recursively starts to loop through the keys of a given child
              child = hash[childrenkey][k]
              valuekey = child.keys.find{|k| k == "value" || k == :value } #immediately look for a value, because every child will contain a value
              if(child.has_key? valuekey)
                if(child[valuekey].is_a?(Array))
                  #puts "Route 3-a for #{child[valuekey]}"
                  child[valuekey].each_with_index do |c,index|

                    #it is expected that each of these values of a child will be an object of some kind
                    child[valuekey][index] = to_hash(c)
                    #puts child[valuekey][index]
                  end
                else
                  #likely we want to resurse here
                  #puts "Route 3-b for #{child[valuekey]}"
                  child[valuekey] = to_hash(child[valuekey])
                end
              else
                #puts "Unanticipated error."
              end
            end #end of array each loop
          else
            #puts "The children hash is empty for #{hash}"
            #remove empty children
            hash.delete(childrenkey)
          end
        end
        if(hash.has_key?(:attributes) ||hash.has_key?("attributes"))
          #puts "Route 4"
          attkey = hash.keys.find{ |k| k == :attributes || k == "attributes" }
          if(hash[attkey].keys.length == 0)
            #this is the only possibility we currently have at the moment.
            #puts "The attributes hash is empty"
            hash.delete(attkey)
          end
        end
      end
    else
      #puts "Bigtime error, expected successful hash conversion."
    end
    #adds the object class name as the key at the fromt of the hash, else it wouldn't be included
    #puts obj.class.name
    hash = { obj.class.name.to_sym => hash }
    return hash
  end

  #pass the attributes has as we've made it and make it one that rexml can use
  #it relies on a structure like this, e.g. : {:attributes=>{:ID=>{value: "Typical Insulated Steel Framed Exterior Wall R-18.18"}}}
  def make_rexml_att_hash(our_hash)
    rexml_hash = {}
   #puts our_hash
    our_hash.keys.each do |key|
      if !key.nil?
        if !(our_hash[key][:value].nil?)
          rexml_hash[key.to_s] = our_hash[key][:value].to_s
        else
          #puts "Attribute is nil, not adding the attribute"
        end
      else
        #puts "Attribute is nil, not adding the attribute"
      end
    end

    return rexml_hash
  end
  #all this method should do isrecurse through the hash that is passed. 
  #It blindly assumes all checks, deletions have already occurred upstream.  Its job is to take a hash that begins with "Audits" as the first key,
  #and iteratively add children, attributes, and text as conveyed in the passed hash structure
  #TODO:  This method works well, but can it be refactored so it is easier to follow for the unindoctrinated?
  def hash_to_xml_b(h)
    #puts "Starting hash #{h.inspect}"
    standard_keys = [:value,:text,:children,:required,:type, :attributes] #standard keys are keys that are not new elements, i.e. - instance variables of the element
    standard_keys_s = standard_keys
    standard_keys_s.map { |x| x.to_s}
    child_att_keys = [:children,:attributes]
    child_att_keys_s =  child_att_keys
    child_att_keys_s.map { |x| x.to_s }
    #get keys
    #puts "#{h.keys}"
    h.keys.each do |master_key|
      current_key = master_key
      #puts "Working on hash #{h[current_key]}"
      if(standard_keys.include?(current_key))
        #THIS SHOULD NEVER HAPPEN
        #puts "key of hash passed in is not a class definition.  Seeing a standard"
      elsif(current_key.to_s == "Audits")
        #puts "Pass 1"
        firstelement = Element.new(current_key.to_s)
        self.xmlDoc.add_element(firstelement)
        #puts "Root: " + xmlDoc.root.name
        self.mostRecentElement = firstelement 
        hash_to_xml_b(h[current_key][:children]) #relies on a known structure for audits...no attributes expected #TODO add ID if desired
      else
        #puts "Pass 2"
        if (h[current_key].keys & ["required","value"]).empty? #set intersection here assures we follwing the standard required, value, pattern i.e. it should be ":Audit" => :required, :value, etc.
          #go down into the :value, whose only key should be the same (this is the fast forward point)
          if(h[current_key].has_key?(:type))
            self.hasType = true #TODO when to set to false?
            self.typeSub = current_key #this is for downstream children
            #puts "Contains a type.  Will replace downstream children with #{current_key}"
          end
          if(!h[current_key][:value].is_a?(Array))
            if(h[current_key][:value].keys[0]) == current_key #first match
              #puts "Fast Forward Match as expected"
              #this is new, build the element right now
              if(self.hasType)
                #puts "Making element #{self.typeSub}"
                newelement = Element.new(self.typeSub)
                self.mostRecentElement.add_element(newelement)
                self.mostRecentElement = newelement

                self.hasType = false
                self.typeSub = ""
              else
                #puts "Making element #{current_key.to_s}"
                newelement = Element.new(current_key.to_s)
                self.mostRecentElement.add_element(newelement)
                self.mostRecentElement = newelement
                #puts "Made normal element #{current_key}"
              end
              #fast forward into this object
              inner = h[current_key][:value][current_key] #puts me one nest in, at { :children :attributes}
              #puts "Inner is #{inner}"
              child_keys = inner.keys
              #puts child_keys
              if(child_keys.include?(:text))
                self.mostRecentElement.text = inner[:text]
              end
              if(child_keys.include?(:attributes))
                #make the attributes right away on the elment created a few lines above
                attr_hash = inner[:attributes]
                good_hash = make_rexml_att_hash(attr_hash)
                #puts good_hash
                self.mostRecentElement.add_attributes(good_hash)
                
              end

              if(child_keys.include?(:children))
                hash_to_xml_b(inner[:children])
                self.mostRecentElement = self.mostRecentElement.parent
              else
                #puts "No remaining children."
                self.mostRecentElement = self.mostRecentElement.parent
              end
              #big cuts happened here
            end
          else
            #it is an array
            #puts "Array, working on value array"
            h[current_key][:value].each do |elArr|
              current_key = elArr.keys[0] #we are assuming here that the key is of the not standard variety
              if(self.hasType)
                #puts "Array item is a type, will use #{self.typeSub}"
                newelement = Element.new(self.typeSub.to_s)
                self.mostRecentElement.add_element(newelement)
                self.mostRecentElement = newelement
                child_keys = elArr[current_key].keys
                #puts "Child keys #{child_keys}"
                if(child_keys.include?(:attributes))
                  #puts "Array item has attributes"
                  #make the attributes right away on the elment created a few lines above
                  attr_hash = elArr[current_key][:attributes]
                  good_hash = make_rexml_att_hash(attr_hash)
                  #puts good_hash
                  self.mostRecentElement.add_attributes(good_hash)
                end
                
              else
                newelement = Element.new(current_key.to_s)
                self.mostRecentElement.add_element(newelement)
                self.mostRecentElement = newelement
                child_keys = elArr[current_key].keys
                if(child_keys.include?(:attributes))
                  #make the attributes right away on the elment created a few lines above
                  attr_hash = elArr[current_key][:attributes]
                  good_hash = make_rexml_att_hash(attr_hash)
                  #puts good_hash
                  self.mostRecentElement.add_attributes(good_hash)
                end

              end
              if(child_keys.include?(:text))
                self.mostRecentElement.text = elArr[current_key][:text]
              end
              if(child_keys.include?(:children))
                self.hasType = false
                self.typeSub = ""
                hash_to_xml_b(elArr[current_key][:children])
                self.mostRecentElement = self.mostRecentElement.parent
              else
                #puts "No remaining children."
                self.hasType = false
                self.typeSub = "" 
                self.mostRecentElement = self.mostRecentElement.parent
              end
            end
          end
        end
      end
    end
  end

  # def hash_to_xml(h)
  #   #puts h.inspect
  #   standard_keys = [:value,:text,:children,:required,:type, :attributes] #standard keys are keys that are not new elements, i.e. - instance variables of the element
  #   child_att_keys = [:children,:attributes] 
  #   #get keys

  #   h.keys.each do |k|
  #     if(standard_keys.include?(k))
  #       #we take action in order to continue processing this document as required by the standard keys
  #       if(k == :required)
  #         #do nothing
  #         #puts "Required field, do nothing."
  #       elsif(k == :attributes)
  #         good_hash = make_rexml_att_hash(h)
  #         #puts good_hash
  #         self.mostRecentElement.add_attributes(good_hash)
  #       elsif(k == :children)
  #         #children will need to be handled in a special way, look inside the children hash (we assume for now it is always a hash) TODO: handle if not a hash
  #         #puts "Pass 2 on a child"
  #         #puts h[k].keys
  #         h[k].keys.each do |key|
  #           if(h[k][key].is_a?(Hash))
  #             hash_to_xml({ key => h[k][key] })
  #           end
  #         end
  #       elsif (k == :value)
  #         if (h[k].is_a?(Array))
  #           #TODO make this an official warning
  #           #puts "Seeing an array unusually."
  #         else
  #           #here is the special handle to prevent duplicate children
  #           if(h[k].is_a?(Hash))
  #             #puts "Pass 4 on value key."
  #             h[k].keys.each do |valkey|
  #               if(valkey.to_s == self.mostRecentElement.name)
  #                 hash_to_xml(h[k][valkey]);
  #               else
  #                 #else what?  we don't expect anything other than this from occurring on a children value
  #                 #puts "This is awfully weird behavior"
  #               end
  #             end
  #           end #TODO in the event it is not a hash, because this is what we're expecting
  #         end
          
  #       end

  #     else
  #       if(k.to_s == "Audits")
  #         #puts "Pass 1"
  #         firstelement = Element.new(k.to_s)
  #         self.xmlDoc.add_element(firstelement)
  #         #puts "Root: " + xmlDoc.root.name
  #         self.mostRecentElement = firstelement
  #         hash_to_xml(h[k])
  #       else
  #         #the idea here, is that if it is not the Audits key (not the root, and is not a standard key, we must want to add this element)
  #         #and make it the most recent
  #         #there needs to be a special case to handle instances that prevent duplicate children from being created,
  #         #looking for common patterns
  #         #puts "Pass 3"
  #         if (h[k].keys & ["required","value"]).empty? #set intersection here assures we are not getting required, value
  #           #go down into the :value
  #           #puts h[k][:value].keys[0]
  #           if h[k][:value].keys[0] == k #first match
  #             #puts "Matches as expected"
  #             #fast forward into this object
  #             inner = h[k][:value][k] #puts me one nest in, at { :children :attributes}
  #             #puts "Inner is #{inner}"
  #             standard_keys_s = standard_keys
  #             standard_keys_s.map { |x| x.to_s}
  #             if (inner[:children].keys & standard_keys_s).empty? #set intersection to ensure that we are getting a key *other* than standard"
  #               firstKey = inner[:children].keys[0]
  #               #puts "get inner children #{inner[:children][firstKey]}"
  #               if(inner[:children][firstKey].has_key?(:type))
                  
  #                 self.hasType = true
  #                 self.typeSub = firstKey
  #                 #puts "Contains a type.  Replace with #{firstKey}"
  #               end
  #               if(inner[:children][firstKey].has_key?(:value))
  #                 if inner[:children][firstKey][:value].is_a?(Array)
  #                   #fast forward
  #                   #puts "Fast forwarding on array"
  #                   #ex {:WallSystems=>{:required=>false, value: {:WallSystems=>{:children=>{:WallSystem=>{:required=>false, :type=>"WallSystemType", value: [] }}}}}}
  #                   newelement = Element.new(k.to_s)
  #                   self.mostRecentElement.add_element(newelement)
  #                   self.mostRecentElement = newelement
  #                   #fast forward to skip
  #                   valarr = inner[:children][firstKey][:value]
  #                   valarr.each do |val|
  #                     #make as much of it as you can here
  #                     if(self.hasType)
  #                       #puts self.typeSub
  #                       newelement = Element.new(self.typeSub.to_s)
  #                       self.mostRecentElement.add_element(newelement)
  #                       self.mostRecentElement = newelement #temporarily
  #                     else
  #                       newelement = Element.new(val.keys[0]) #has never been tested
  #                       self.mostRecentElement.add_element(newelement)
  #                       self.mostRecentElement = newelement #temporarily
  #                     end
  #                     if(val.keys & standard_keys_s).empty?
  #                       #this is what we expect #TODO handle what happens if not empty, which we don't expect ever.
  #                       hash_to_xml(val[val.keys[0]])
  #                       #puts self.mostRecentElement.parent
  #                       self.mostRecentElement = self.mostRecentElement.parent
  #                     else
  #                       #puts "Odd things"
  #                     end
  #                   end
  #                 else
  #                   # it is not an array, fall back on the fast forward by adding element
  #                   # then simply decided to pass the inner, which #puts us at children
  #                   newelement = Element.new(k.to_s)
  #                   self.mostRecentElement.add_element(newelement)
  #                   self.mostRecentElement = newelement
  #                   hash_to_xml(inner)
  #                 end
  #               end
  #             end
  #           end
  #         end
  #       end
  #     end
  #   end
  # end
end
