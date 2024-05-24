module Strength

using Parameters, AISIS100, CUFSM, Unitful, Serialization

using ..Properties, ..Geometry

@with_kw struct DiagonalTension

    Ag::Float64
    Anet::Float64
    Tny::Float64
    eTny::Float64
    Tnu::Float64
    eTnu::Float64
    eTn::Float64

end

@with_kw struct DiagonalCompression

    Lu::Float64
    Pcre::Float64
    global_buckling_properties::CUFSM.Model
    Pcrℓ::Float64
    local_buckling_properties::CUFSM.Model
    Py::Float64
    Pne::Float64
    ePne::Float64
    Pnℓ::Float64
    ePnℓ::Float64

end


@with_kw struct UnreinforcedConnection

    Ab::Float64
    Fnv::Float64
    Pn_bolt::Float64
    ePn_bolt::Float64
    C::Float64
    mf::Float64
    Pnb::Float64
    ePnb::Float64
    limit_state_strengths::NamedTuple{(:bolt_shear, :bolt_bearing), Tuple{Float64, Float64}}
    num_bolts::Int64
    eRn::Float64

end


@with_kw struct ReinforcedConnection
    
    Ab::Float64
    C::Float64
    mf::Float64
    Pn_bolt::Float64
    Fnv::Float64
    ePn_bolt::Float64
    Pnb_shield_plate::Float64
    ePnb_shield_plate::Float64
    Pnb_diagonal::Float64
    ePnb_diagonal::Float64
    Anv::Float64
    Pnv::Float64
    ePnv::Float64
    limit_state_strengths::NamedTuple{(:bolt_shear, :shield_plate_shear_rupture, :bolt_bearing), Tuple{Float64, Float64, Float64}}
    eRn::Float64

end


@with_kw struct ChordCompression

    Ag::Float64 
    Py::Float64 
    Pne::Float64 
    ePne::Float64 
    Pcrℓ::Float64 
    local_buckling_properties::CUFSM.Model
    Pnℓ::Float64  
    ePnℓ::Float64 
    Pcrd::Float64 
    distortional_buckling_properties::CUFSM.Model
    Pnd::Float64 
    ePnd::Float64 
    ePn::Float64 

end

@with_kw struct ChordTension

    Ag::Float64
    Tn_y::Float64
    eTn_y::Float64
    Anet::Float64 
    Tn_u::Float64 
    eTn_u::Float64
    eTn::Float64 

end


@with_kw struct BearingSeatWeld
    
    L::Float64
    t1::Float64
    Fu1::Float64
    t2::Float64 
    Fu2::Float64
    tw::Float64
    Fxx::Float64
    loading_direction::String
    Pnv1::Float64
    Pnv2::Float64 
    Pn::Float64 
    Pnv::Float64 
    ePnv::Float64 
    num_weld_lines::Int64 
    eRn::Float64

end

@with_kw struct BearingSeatCompression
    
    compression_field_width::Float64
    fcrℓ::Float64 
    fy::Float64 
    Pcrℓ::Float64
    Pne::Float64 
    Pnℓ::Float64 
    ePnℓ::Float64 
    num_bearing_seat_webs::Int64 
    eRn::Float64

end


@with_kw struct Components

    diagonal_tensile_strength::Vector{DiagonalTension}
    diagonal_compressive_strength::Vector{DiagonalCompression}
    chord_compressive_strength::ChordCompression
    chord_tensile_strength::ChordTension
    chord_splice_strength::UnreinforcedConnection
    bearing_seat_weld_strength::BearingSeatWeld
    bearing_seat_compression_field_strength::BearingSeatCompression
    bearing_seat_chord_connection_strengths::Vector{UnreinforcedConnection}
    top_chord_connection_strength::Vector{Union{ReinforcedConnection, UnreinforcedConnection}}
    bottom_chord_connection_strength::Vector{Union{ReinforcedConnection, UnreinforcedConnection}}

    eRn_diagonals::Vector{Float64}
    eRn_top_chord_connections::Vector{Float64}
    eRn_bottom_chord_connections::Vector{Float64}
    eRn_top_chord::Float64
    eRn_bottom_chord::Float64
    eRn_chord_splice::Float64
    eRn_bearing_seat_weld::Float64
    eRn_bearing_compression_field::Float64
    eRn_bearing_seat_chord_connections::Vector{Float64}

end




function calculate_diagonal_tensile_strength(bolt_hole_diameter, t, diagonal_section_properties, joist_material_properties, design_code)

    Ag = diagonal_section_properties.A

    Tny, eTny = AISIS100.v16.d21(Ag=Ag, Fy=joist_material_properties.fy, design_code=design_code)

    Anet = Ag - 2 * bolt_hole_diameter * t

    Tnu, eTnu = AISIS100.v16.d31(An=Anet, Fu=joist_material_properties.fu, design_code=design_code)

    eTn = minimum([eTny, eTnu])

    diagonal_tensile_strength = DiagonalTension(Ag=Ag, Anet=Anet, Tny=Tny, eTny=eTny, Tnu=Tnu, eTnu=eTnu, eTn=eTn)

    return diagonal_tensile_strength

end

function calculate_diagonal_global_buckling(model, diagonal_section_assignments, diagonal_bracing, diagonal_dimensions, diagonal_section_geometry, joist_material_properties)

    diagonal_index = findall(section->occursin("diagonal", section), model.inputs.element.cross_section)

    Pcre_diagonal = Vector{Float64}(undef, length(diagonal_index))
    diagonal_global_buckling = Vector{CUFSM.Model}(undef, length(diagonal_index))
    L = Vector{Float64}(undef, length(diagonal_index))

    for i in eachindex(diagonal_index)

        section_index = findfirst(section->section==diagonal_section_assignments[i], diagonal_dimensions.name)

        if diagonal_bracing[i] == "unbraced"
            L[i] = model.properties.L[diagonal_index[i]]
        elseif diagonal_bracing[i] == "braced"
            L[i] = model.properties.L[diagonal_index[i]]/2
        end

        Pcre_diagonal[i], diagonal_global_buckling[i] = Properties.calculate_diagonal_global_buckling_load(diagonal_section_geometry[section_index], diagonal_dimensions.t[section_index], joist_material_properties.E, joist_material_properties.ν, L[i])

    end

    return Pcre_diagonal, diagonal_global_buckling, L

end

function calculate_all_diagonal_tensile_strengths(diagonal_section_assignments, diagonal_dimensions, diagonal_section_properties, joist_material_properties, bolt_hole_diameter, design_code)

    diagonal_tensile_strength = Vector{Strength.DiagonalTension}(undef, length(diagonal_section_assignments))

    for i in eachindex(diagonal_section_assignments)

        section_index = findfirst(section->section==diagonal_section_assignments[i], diagonal_dimensions.name)

        diagonal_tensile_strength[i] = Strength.calculate_diagonal_tensile_strength(bolt_hole_diameter, diagonal_dimensions.t[section_index], diagonal_section_properties[section_index], joist_material_properties, design_code)

    end

    return diagonal_tensile_strength

end




function calculate_all_diagonal_compressive_strengths(diagonal_section_assignments, diagonal_dimensions, Lu, Pcre, diagonal_global_buckling, Pcrℓ, diagonal_local_buckling, diagonal_section_properties, fy, design_code)

    diagonal_compressive_strength = Vector{DiagonalCompression}(undef, length(diagonal_section_assignments))
    for i in eachindex(diagonal_section_assignments)

        section_index = findfirst(section->section==diagonal_section_assignments[i], diagonal_dimensions.name)

        diagonal_compressive_strength[i] = calculate_diagonal_compressive_strength(Lu[i], Pcre[i], diagonal_global_buckling[i], Pcrℓ[section_index], diagonal_local_buckling[section_index], diagonal_section_properties[section_index].A, fy, design_code)

    end

    return diagonal_compressive_strength 

end

function calculate_diagonal_compressive_strength(Lu, Pcre, diagonal_global_buckling, Pcrℓ, diagonal_local_buckling, A, fy, design_code)

    Py = fy * A

	Pne, ePne = AISIS100.v16.e2(Fcre=Pcre/A, Fy=fy, Ag=A, design_code=design_code)
    Pnℓ, ePnℓ = AISIS100.v16.e321(Pne=Pne, Pcrℓ=Pcrℓ, design_code=design_code)

    diagonal_compressive_strength = Strength.DiagonalCompression(Lu = Lu, Pcre=Pcre, global_buckling_properties = diagonal_global_buckling, Pcrℓ=Pcrℓ, local_buckling_properties = diagonal_local_buckling, Py=Py, Pne=Pne, ePne=ePne, Pnℓ=Pnℓ, ePnℓ=ePnℓ)
   
    return diagonal_compressive_strength

		
end

	
# function calculate_unreinforced_connection_strength(bolt_diameter, Fnv, Fu, design_code, t_ply, t_diagonal)

#     Ab = π * (bolt_diameter/2)^2
#     Pn_bolt, ePn_bolt = AISIS100.v16.appAj341(Ab = Ab, Fn = Fnv, design_code = design_code)

# 	C = AISIS100.v16.tablej3311(d=bolt_diameter*u"inch", t=minimum([t_ply, t_diagonal])*u"inch", hole_shape = "standard hole")
	
# 	mf = AISIS100.v16.tablej3312(connection_type="single shear", hole_shape="standard hole", washers="no")
	
# 	Pnb, ePnb = AISIS100.v16.j3311(C=C, mf=mf, d=bolt_diameter, t=minimum([t_ply, t_diagonal]), Fu=Fu, design_code=design_code)
	
#     limit_state_strengths = (bolt_shear=ePn_bolt, bolt_bearing=ePnb)

#     eRn = minimum([ePn_bolt; ePnb]) * 2

#     connection_strength = UnreinforcedConnection(Ab=Ab, Fnv=Fnv, Pn_bolt=Pn_bolt, ePn_bolt=ePn_bolt, C=C, mf=mf, Pnb=Pnb, ePnb=ePnb, limit_state_strengths = limit_state_strengths, num_bolts=2, eRn=eRn) 
	
# 	return connection_strength

# end


function calculate_bolted_connection_strength(bolt_diameter, Fnv, Fu, design_code, t_ply1, t_ply2, num_bolts)

    Ab = π * (bolt_diameter/2)^2
    Pn_bolt, ePn_bolt = AISIS100.v16.appAj341(Ab = Ab, Fn = Fnv, design_code = design_code)

	C = AISIS100.v16.tablej3311(d=bolt_diameter*u"inch", t=minimum([t_ply1, t_ply2])*u"inch", hole_shape = "standard hole")
	
	mf = AISIS100.v16.tablej3312(connection_type="single shear", hole_shape="standard hole", washers="no")
	
	Pnb, ePnb = AISIS100.v16.j3311(C=C, mf=mf, d=bolt_diameter, t=minimum([t_ply1, t_ply2]), Fu=Fu, design_code=design_code)
	
    limit_state_strengths = (bolt_shear=ePn_bolt, bolt_bearing=ePnb)

    eRn = minimum([ePn_bolt; ePnb]) * num_bolts

    connection_strength = UnreinforcedConnection(Ab=Ab, Fnv=Fnv, Pn_bolt=Pn_bolt, ePn_bolt=ePn_bolt, C=C, mf=mf, Pnb=Pnb, ePnb=ePnb, limit_state_strengths = limit_state_strengths, num_bolts=num_bolts, eRn=eRn) 
	
	return connection_strength

end


function calculate_reinforced_connection_strength(bolt_diameter, Fnv, Fu, design_code, t_chord, t_diagonal, t_shield_plate, shield_plate_slotted_hole_edge_distance)

    engineering_judgement = "NO"

    Ab = π * (bolt_diameter/2)^2
	Pn_bolt, ePn_bolt = AISIS100.v16.appAj341(Ab = Ab, Fn = Fnv, design_code = design_code)
	
    C = AISIS100.v16.tablej3311(d=bolt_diameter*u"inch", t=minimum([t_chord, t_diagonal])*u"inch", hole_shape = "standard hole")
	
	mf = AISIS100.v16.tablej3312(connection_type="single shear", hole_shape="standard hole", washers="no")
	
	Pnb_shield_plate, ePnb_shield_plate = AISIS100.v16.j3311(C=C, mf=mf, d=bolt_diameter, t=minimum([t_diagonal, t_chord, t_shield_plate]), Fu=Fu, design_code=design_code)
	
	Pnb_diagonal, ePnb_diagonal = AISIS100.v16.j3311(C=C, mf=mf, d=bolt_diameter, t=minimum([t_diagonal, t_chord, t_shield_plate]), Fu=Fu, design_code=design_code)
	
	Anv = shield_plate_slotted_hole_edge_distance * t_shield_plate * 2
	
	Pnv, ePnv = AISIS100.v16.j611(Anv, Fu, design_code, "bolts")
	

    if engineering_judgement == "YES"
        #consider AISI S100-16 Section A1.2, engineering judgement for the shield plate connection, which means that Ω=3.0 and ϕ = 0.55.

        if design_code == "AISI S100-16 ASD"

            Ω = 3.0
            limit_state_strengths = (bolt_shear = ePn_bolt*4, shield_plate_shear_rupture=(Pnv / Ω) * 2+ (Pnb_diagonal / Ω) * 2, bolt_bearing = (Pnb_diagonal / Ω) * 2 + (Pnb_shield_plate / Ω) * 2)

        elseif design_code == "AISI S100-16 LRFD"

            ϕ = 0.55
            limit_state_strengths = (bolt_shear = ePn_bolt*4, shield_plate_shear_rupture=(ϕ * Pnv) * 2+ (ϕ * Pnb_diagonal) * 2, bolt_bearing = (ϕ * Pnb_diagonal) * 2 + (ϕ * Pnb_shield_plate) * 2)

        end

        eRn = minimum(limit_state_strengths)
        

        if design_code == "AISI S100-16 ASD"

            Ω = 3.0
            connection_strength = ReinforcedConnection(Ab=Ab, C=C, mf=mf, Pn_bolt=Pn_bolt, Fnv = Fnv, ePn_bolt=ePn_bolt, Pnb_shield_plate=Pnb_shield_plate, ePnb_shield_plate=Pnb_shield_plate/Ω, Pnb_diagonal=Pnb_diagonal, ePnb_diagonal=Pnb_diagonal/Ω, Anv=Anv, Pnv=Pnv, ePnv=ePnv, limit_state_strengths=limit_state_strengths, eRn=eRn)

        elseif design_code == "AISI S100-16 LRFD"

            ϕ = 0.55
            connection_strength = ReinforcedConnection(Ab=Ab, C=C, mf=mf, Pn_bolt=Pn_bolt, Fnv = Fnv, ePn_bolt=ePn_bolt, Pnb_shield_plate=Pnb_shield_plate, ePnb_shield_plate=Pnb_shield_plate * ϕ, Pnb_diagonal=Pnb_diagonal, ePnb_diagonal=Pnb_diagonal * ϕ, Anv=Anv, Pnv=Pnv, ePnv=ePnv, limit_state_strengths=limit_state_strengths, eRn=eRn)

        end

    elseif engineering_judgement == "NO"

        limit_state_strengths = (bolt_shear = ePn_bolt*4, shield_plate_shear_rupture = ePnv * 2 + ePnb_diagonal * 2, bolt_bearing = ePnb_diagonal * 2 + ePnb_shield_plate * 2)

        eRn = minimum(limit_state_strengths)

        connection_strength = ReinforcedConnection(Ab=Ab, C=C, mf=mf, Pn_bolt=Pn_bolt, Fnv = Fnv, ePn_bolt=ePn_bolt, Pnb_shield_plate=Pnb_shield_plate, ePnb_shield_plate=ePnb_shield_plate, Pnb_diagonal=Pnb_diagonal, ePnb_diagonal=ePnb_diagonal, Anv=Anv, Pnv=Pnv, ePnv=ePnv, limit_state_strengths=limit_state_strengths, eRn=eRn)


    end


    return connection_strength

end


function calculate_connection_strength_series(connection_types, diagonal_section_assignments, diagonal_dimensions, bolt, joist_material_properties, design_code, bearing_seat_dimensions, shield_plate_dimensions, chord_dimensions)

    connection_strength_series = Vector{Union{UnreinforcedConnection, ReinforcedConnection}}(undef, length(connection_types))

    for i in eachindex(connection_types)

        section_index = findfirst(section->section==diagonal_section_assignments[i], diagonal_dimensions.name)

        if connection_types[i] == "bearing seat" 

            #diagonal to bearing seat
            num_bolts = 4
            connection_strength_series[i] = calculate_bolted_connection_strength(bolt.diameter, bolt.Fnv, joist_material_properties.fu, design_code, bearing_seat_dimensions.t, diagonal_dimensions.t[section_index], num_bolts)

            # connection_strength_series[i] = calculate_unreinforced_connection_strength(bolt.diameter, bolt.Fnv, joist_material_properties.fu, design_code, bearing_seat_dimensions.t, diagonal_dimensions.t[section_index])

        elseif connection_types[i] == "unreinforced connection"
            #diagonal to chord
            num_bolts = 2
            connection_strength_series[i] = calculate_bolted_connection_strength(bolt.diameter, bolt.Fnv, joist_material_properties.fu, design_code, chord_dimensions.t, diagonal_dimensions.t[section_index], num_bolts)
            # connection_strength_series[i] = calculate_unreinforced_connection_strength(bolt.diameter, bolt.Fnv, joist_material_properties.fu, design_code, chord_dimensions.t, diagonal_dimensions.t[section_index])

        elseif connection_types[i] == "reinforced connection"
            
            #diagonal to chord with shield plate
            connection_strength_series[i] = calculate_reinforced_connection_strength(bolt.diameter, bolt.Fnv, joist_material_properties.fu, design_code, chord_dimensions.t, diagonal_dimensions.t[section_index], shield_plate_dimensions.t, shield_plate_dimensions.slotted_hole_edge_distance)

        end

    end

   return connection_strength_series

end


function calculate_chord_compressive_strength(chord_section_properties, joist_material_properties, design_code, chord_dimensions)

    Ag = chord_section_properties.A 
    Py_chord = Ag * joist_material_properties.fy

    #Assume the deck full braces the top chord in compression which means that $P_{ne} = P_y$ in AISI S100-16 Section E2
    Pne_chord, ePne_chord = AISIS100.v16.e2(Fcre=joist_material_properties.fy*100000, Fy=joist_material_properties.fy, Ag=Ag, design_code=design_code)


    lengths = collect(0.25*3.0:3.0/20:1.25*3.0)
    chord_local_buckling = deserialize("/Users/crismoen/.julia/dev/MarkoJIT/assets/chord_local_buckling_properties")
    Pcrℓ_chord = deserialize("/Users/crismoen/.julia/dev/MarkoJIT/assets/chord_Pcrl")
    # Pcrℓ_chord, chord_local_buckling =  Properties.calculate_chord_cross_section_buckling_load(chord_dimensions, joist_material_properties, lengths)

    Pnℓ_chord, ePnℓ_chord = AISIS100.v16.e321(Pne=Pne_chord, Pcrℓ=Pcrℓ_chord, design_code=design_code)


    lengths = collect(26.0:1.0:34.0)
    # Pcrd_chord, chord_distortional_buckling =  Properties.calculate_chord_cross_section_buckling_load(chord_dimensions, joist_material_properties, lengths)
        
    chord_distortional_buckling = deserialize("/Users/crismoen/.julia/dev/MarkoJIT/assets/chord_distortional_buckling_properties")
    Pcrd_chord = deserialize("/Users/crismoen/.julia/dev/MarkoJIT/assets/chord_Pcrd")

    Pnd_chord, ePnd_chord = AISIS100.v16.e41(Py=Py_chord, Pcrd=Pcrd_chord, design_code=design_code)

    ePn = minimum([ePnℓ_chord, ePnd_chord])

    chord_compressive_strength = ChordCompression(Ag=Ag, Py=Py_chord, Pne=Pne_chord, ePne=ePne_chord, Pcrℓ=Pcrℓ_chord, local_buckling_properties=chord_local_buckling, Pnℓ=Pnℓ_chord, ePnℓ=ePnℓ_chord, Pcrd=Pcrd_chord, distortional_buckling_properties=chord_distortional_buckling, Pnd=Pnd_chord, ePnd=ePnd_chord, ePn=ePn)

    return chord_compressive_strength

end

function calculate_chord_splice_strength(bolt_diameter, Fnv, Fu, design_code, t_splice, t_chord)

    Ab = π * (bolt_diameter/2)^2
    Pn_bolt, ePn_bolt = AISIS100.v16.appAj341(Ab = Ab, Fn = Fnv, design_code = design_code)

	C = AISIS100.v16.tablej3311(d=bolt_diameter*u"inch", t=minimum([t_splice, t_chord])*u"inch", hole_shape = "standard hole")
	
	mf = AISIS100.v16.tablej3312(connection_type="single shear", hole_shape="standard hole", washers="no")
	
	Pnb, ePnb = AISIS100.v16.j3311(C=C, mf=mf, d=bolt_diameter, t=minimum([t_splice, t_chord]), Fu=Fu, design_code=design_code)
	
    limit_state_strengths = (bolt_shear=ePn_bolt, bolt_bearing=ePnb)

    eRn = minimum([ePn_bolt; ePnb]) * 12

    connection_strength = UnreinforcedConnection(Ab=Ab, Fnv=Fnv, Pn_bolt=Pn_bolt, ePn_bolt=ePn_bolt, C=C, mf=mf, Pnb=Pnb, ePnb=ePnb, limit_state_strengths = limit_state_strengths, num_bolts=12, eRn=eRn) 
	
	return connection_strength

end

function calculate_chord_tensile_strength(chord_section_properties, chord_dimensions, joist_material_properties, design_code)

    Ag = chord_section_properties.A
    Tn_y, eTn_y = AISIS100.v16.d21(Ag=Ag, Fy=joist_material_properties.fy, design_code=design_code)

    Anet = Ag - chord_dimensions.flange_punchout_width * chord_dimensions.t

    Tn_u, eTn_u = AISIS100.v16.d31(An=Anet, Fu=joist_material_properties.fu, design_code=design_code)

    eTn = minimum([eTn_y, eTn_u])

    chord_tensile_strength = ChordTension(Ag=Ag, Tn_y=Tn_y, eTn_y=eTn_y, Anet=Anet, Tn_u=Tn_u, eTn_u=eTn_u, eTn=eTn)

    return chord_tensile_strength

end


function calculate_bearing_seat_weld_strength(weld, bearing_seat_dimensions, joist_material_properties, girder_dimensions, girder_material_properties, design_code)

    loading_direction = "longitudinal"
    Pnv1, Pnv2, Pn, Pnv, ePnv = AISIS100.v16.j25(L=weld.length*u"inch", t1=bearing_seat_dimensions.t*u"inch", Fu1=joist_material_properties.fu, t2=girder_dimensions.top_flange_thickness*u"inch", Fu2=girder_material_properties.fu, tw=0.707*weld.t*u"inch", Fxx=weld.Fxx, loading_direction=loading_direction, design_code=design_code) 

    eRn = ePnv * weld.num_lines

    bearing_seat_weld_strength = BearingSeatWeld(L=weld.length, t1=bearing_seat_dimensions.t, Fu1=joist_material_properties.fu, t2=girder_dimensions.top_flange_thickness, Fu2=girder_material_properties.fu, tw=0.707*weld.t, Fxx=weld.Fxx, loading_direction=loading_direction, Pnv1=ustrip(Pnv1), Pnv2=ustrip(Pnv2), Pn=ustrip(Pn), Pnv=ustrip(Pnv), ePnv=ustrip(ePnv), num_weld_lines=weld.num_lines, eRn=ustrip(eRn))

    return bearing_seat_weld_strength

end


function plate_buckling_stress(;k, E, ν, t, b)

	fcr = k*π^2*E/(12*(1-ν^2))*(t/b)^2
	
	return fcr
	
end

function calculate_bearing_seat_compression_field_strength(joist_material_properties, bearing_seat_dimensions, design_code)

    compression_field_width = 2.0

    fcrℓ = plate_buckling_stress(k=4.0, E=joist_material_properties.E, ν=joist_material_properties.ν, t=bearing_seat_dimensions.t, b=compression_field_width)

    Pcrℓ = bearing_seat_dimensions.t * compression_field_width * fcrℓ
    Pne = bearing_seat_dimensions.t * compression_field_width * joist_material_properties.fy
    Pnℓ, ePnℓ = AISIS100.v16.e321(Pne = Pne, Pcrℓ = Pcrℓ, design_code=design_code)

    eRn = ePnℓ * bearing_seat_dimensions.num_webs

    bearing_seat_compression_field_strength = BearingSeatCompression(compression_field_width=compression_field_width, fcrℓ=fcrℓ, fy=joist_material_properties.fy, Pcrℓ=Pcrℓ, Pne=Pne, Pnℓ=Pnℓ, ePnℓ=ePnℓ, num_bearing_seat_webs=bearing_seat_dimensions.num_webs, eRn=eRn)

    return bearing_seat_compression_field_strength

end

function calculate_bearing_seat_chord_connection_strength(joist_dimensions, bolt_properties, joist_material_properties, design_code, bearing_seat_dimensions, chord_dimensions)

    joist_ends = Geometry.define_joist_ends(joist_dimensions.span_length, joist_dimensions.node_spacing)
    if joist_ends[1] == 72.0
        num_bolts = 4
    else
        num_bolts = 3
    end

    bearing_seat_chord_connection_strength_1 = Strength.calculate_bolted_connection_strength(bolt_properties.diameter, bolt_properties.Fnv, joist_material_properties.fu, design_code, bearing_seat_dimensions.t, chord_dimensions.t, num_bolts)

    if joist_ends[2] == 72.0
        num_bolts = 4
    else
        num_bolts = 3
    end

    bearing_seat_chord_connection_strength_2 = Strength.calculate_bolted_connection_strength(bolt_properties.diameter, bolt_properties.Fnv, joist_material_properties.fu, design_code, bearing_seat_dimensions.t, chord_dimensions.t, num_bolts)

    bearing_seat_chord_connection_strength = [bearing_seat_chord_connection_strength_1, bearing_seat_chord_connection_strength_2]

    return bearing_seat_chord_connection_strength

end


end  #module 