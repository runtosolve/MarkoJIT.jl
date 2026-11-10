module Strength

# Component strengths of the Marko JIT joist.
#
# The AISI S100 edition and design method are selected by the `design_code` string, e.g.
# "AISI S100-16 ASD" or "AISI S100-24 ASD" (LRFD and LSD also accepted). All S100 equations are
# called through MarkoJIT.DesignCode, which dispatches to AISIS100.v16 or AISIS100.v2024.

using Parameters, CUFSM, Serialization

using ..Properties, ..Geometry, ..DesignCode

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
    global_buckling_properties::Union{Nothing, CUFSM.Model}
    Pcrℓ::Float64
    local_buckling_properties::Union{Nothing, CUFSM.Model}
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
    local_buckling_properties::Union{Nothing, CUFSM.Model}
    Pnℓ::Float64
    ePnℓ::Float64
    Pcrd::Float64
    distortional_buckling_properties::Union{Nothing, CUFSM.Model}
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


#### diagonals

function calculate_diagonal_tensile_strength(bolt_hole_diameter, t, diagonal_section_properties, joist_material_properties, design_code)

    Ag = diagonal_section_properties.A

    yield = DesignCode.tension_yield(Ag, joist_material_properties.fy, design_code)            #D2

    Anet = Ag - 2 * bolt_hole_diameter * t

    rupture = DesignCode.tension_rupture(Anet, joist_material_properties.fu, design_code)      #D3

    eTn = min(yield.eRn, rupture.eRn)

    return DiagonalTension(Ag=Ag, Anet=Anet, Tny=yield.Rn, eTny=yield.eRn, Tnu=rupture.Rn, eTnu=rupture.eRn, eTn=eTn)

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
        else
            throw(ArgumentError("diagonal_bracing must be \"braced\" or \"unbraced\", got $(diagonal_bracing[i])"))
        end

        Pcre_diagonal[i], diagonal_global_buckling[i] = Properties.calculate_diagonal_global_buckling_load(diagonal_section_geometry[section_index], diagonal_dimensions.t[section_index], joist_material_properties.E, joist_material_properties.ν, L[i])

    end

    return Pcre_diagonal, diagonal_global_buckling, L

end

function calculate_all_diagonal_tensile_strengths(diagonal_section_assignments, diagonal_dimensions, diagonal_section_properties, joist_material_properties, bolt_hole_diameter, design_code)

    diagonal_tensile_strength = Vector{DiagonalTension}(undef, length(diagonal_section_assignments))

    for i in eachindex(diagonal_section_assignments)

        section_index = findfirst(section->section==diagonal_section_assignments[i], diagonal_dimensions.name)

        diagonal_tensile_strength[i] = calculate_diagonal_tensile_strength(bolt_hole_diameter, diagonal_dimensions.t[section_index], diagonal_section_properties[section_index], joist_material_properties, design_code)

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

# diagonal_global_buckling and diagonal_local_buckling are the CUFSM models (stored for reporting only; `nothing` is accepted)
function calculate_diagonal_compressive_strength(Lu, Pcre, diagonal_global_buckling, Pcrℓ, diagonal_local_buckling, A, fy, design_code)

    Py = fy * A

    global_ = DesignCode.compression_global(Pcre/A, fy, A, design_code)     #E2
    local_ = DesignCode.compression_local(global_.Rn, Pcrℓ, design_code)    #E3.2

    return DiagonalCompression(Lu=Lu, Pcre=Pcre, global_buckling_properties=diagonal_global_buckling, Pcrℓ=Pcrℓ, local_buckling_properties=diagonal_local_buckling, Py=Py, Pne=global_.Rn, ePne=global_.eRn, Pnℓ=local_.Rn, ePnℓ=local_.eRn)

end


#### bolted connections

# one bolted joint with num_bolts bolts in single shear (standard holes); the bearing check uses the thinner ply.
# washers = true: washers under both the bolt head and the nut, mf = 1.00 instead of 0.75 (Table J3.3.1-2)
function calculate_bolted_connection_strength(bolt_diameter, Fnv, Fu, design_code, t_ply1, t_ply2, num_bolts; washers::Bool = false)

    Ab = π * (bolt_diameter/2)^2
    shear = DesignCode.bolt_shear(Ab, Fnv, design_code)                       #App. A J3.4

    t = min(t_ply1, t_ply2)
    C = DesignCode.bearing_factor(bolt_diameter, t, design_code)               #Table J3.3.1-1
    mf = DesignCode.bearing_modification_factor(design_code; washers = washers) #Table J3.3.1-2
    bearing = DesignCode.bolt_bearing(C, mf, bolt_diameter, t, Fu, design_code)  #J3.3.1

    limit_state_strengths = (bolt_shear=shear.eRn, bolt_bearing=bearing.eRn)

    eRn = min(shear.eRn, bearing.eRn) * num_bolts

    return UnreinforcedConnection(Ab=Ab, Fnv=Fnv, Pn_bolt=shear.Rn, ePn_bolt=shear.eRn, C=C, mf=mf, Pnb=bearing.Rn, ePnb=bearing.eRn, limit_state_strengths=limit_state_strengths, num_bolts=num_bolts, eRn=eRn)

end


# diagonal to chord joint with a shield plate (4 bolts in the joint, 2 shield plate slotted-hole shear planes)
function calculate_reinforced_connection_strength(bolt_diameter, Fnv, Fu, design_code, t_chord, t_diagonal, t_shield_plate, shield_plate_slotted_hole_edge_distance)

    Ab = π * (bolt_diameter/2)^2
    shear = DesignCode.bolt_shear(Ab, Fnv, design_code)

    C = DesignCode.bearing_factor(bolt_diameter, min(t_chord, t_diagonal), design_code)
    mf = DesignCode.bearing_modification_factor(design_code)

    t_bearing = min(t_diagonal, t_chord, t_shield_plate)
    bearing_shield_plate = DesignCode.bolt_bearing(C, mf, bolt_diameter, t_bearing, Fu, design_code)
    bearing_diagonal = DesignCode.bolt_bearing(C, mf, bolt_diameter, t_bearing, Fu, design_code)

    Anv = shield_plate_slotted_hole_edge_distance * t_shield_plate * 2       #Eq. J6.1-2, n = 1
    rupture = DesignCode.shear_rupture_bolts(Anv, Fu, design_code)            #J6.1, Table J6-1

    # each limit state uses its own code-specified safety / resistance factor (J3.4, J3.3.1, J6.1)
    ePnb_shield_plate = bearing_shield_plate.eRn
    ePnb_diagonal = bearing_diagonal.eRn
    limit_state_strengths = (bolt_shear = shear.eRn*4, shield_plate_shear_rupture = rupture.eRn*2 + ePnb_diagonal*2, bolt_bearing = ePnb_diagonal*2 + ePnb_shield_plate*2)

    eRn = minimum(limit_state_strengths)

    return ReinforcedConnection(Ab=Ab, C=C, mf=mf, Pn_bolt=shear.Rn, Fnv=Fnv, ePn_bolt=shear.eRn, Pnb_shield_plate=bearing_shield_plate.Rn, ePnb_shield_plate=ePnb_shield_plate, Pnb_diagonal=bearing_diagonal.Rn, ePnb_diagonal=ePnb_diagonal, Anv=Anv, Pnv=rupture.Rn, ePnv=rupture.eRn, limit_state_strengths=limit_state_strengths, eRn=eRn)

end


function calculate_connection_strength_series(connection_types, diagonal_section_assignments, diagonal_dimensions, bolt, joist_material_properties, design_code, bearing_seat_dimensions, shield_plate_dimensions, chord_dimensions)

    connection_strength_series = Vector{Union{UnreinforcedConnection, ReinforcedConnection}}(undef, length(connection_types))

    for i in eachindex(connection_types)

        section_index = findfirst(section->section==diagonal_section_assignments[i], diagonal_dimensions.name)

        if connection_types[i] == "bearing seat"
            #diagonal to bearing seat
            connection_strength_series[i] = calculate_bolted_connection_strength(bolt.diameter, bolt.Fnv, joist_material_properties.fu, design_code, bearing_seat_dimensions.t, diagonal_dimensions.t[section_index], 4)

        elseif connection_types[i] == "unreinforced connection"
            #diagonal to chord
            connection_strength_series[i] = calculate_bolted_connection_strength(bolt.diameter, bolt.Fnv, joist_material_properties.fu, design_code, chord_dimensions.t, diagonal_dimensions.t[section_index], 2)

        elseif connection_types[i] == "reinforced connection"
            #diagonal to chord with shield plate
            connection_strength_series[i] = calculate_reinforced_connection_strength(bolt.diameter, bolt.Fnv, joist_material_properties.fu, design_code, chord_dimensions.t, diagonal_dimensions.t[section_index], shield_plate_dimensions.t, shield_plate_dimensions.slotted_hole_edge_distance)

        else
            throw(ArgumentError("unknown connection type $(connection_types[i])"))
        end

    end

   return connection_strength_series

end


#### chords

# Pcrℓ / Pcrd (and their CUFSM models) default to the package's stored chord buckling results for the chord
# thickness (assets/chord_buckling_results); pass them to use other elastic buckling loads.
function calculate_chord_compressive_strength(chord_section_properties, joist_material_properties, design_code, unbraced_lengths, chord_dimensions; Pcrℓ = nothing, Pcrd = nothing, local_buckling_model = nothing, distortional_buckling_model = nothing)

    Ag = chord_section_properties.A
    Py_chord = Ag * joist_material_properties.fy

    E = joist_material_properties.E
    Ixx = chord_section_properties.Ixx
    Iyy = chord_section_properties.Iyy
    Lx = unbraced_lengths.Lx
    Ly = unbraced_lengths.Ly

    Fcre_flexural(E, I, L) = π^2 * E * I / L^2 / Ag

    Fcre_xx = Fcre_flexural(E, Ixx, Ly)
    Fcre_yy = Fcre_flexural(E, Iyy, Lx)

    Fcre = min(Fcre_xx, Fcre_yy)

    global_ = DesignCode.compression_global(Fcre, joist_material_properties.fy, Ag, design_code)     #E2

    if Pcrℓ === nothing || Pcrd === nothing
        chord_buckling_results = deserialize(joinpath(@__DIR__, "..", "assets", "chord_buckling_results"))
        stored = chord_buckling_results[chord_dimensions.t]
    end

    if Pcrℓ === nothing
        Pcrℓ = stored.local_buckling.Pcr
        local_buckling_model = stored.local_buckling.model
    end

    if Pcrd === nothing
        Pcrd = stored.distortional_buckling.Pcr
        distortional_buckling_model = stored.distortional_buckling.model
    end

    local_ = DesignCode.compression_local(global_.Rn, Pcrℓ, design_code)                  #E3.2
    distortional = DesignCode.compression_distortional(Py_chord, Pcrd, design_code)       #E4

    ePn = min(local_.eRn, distortional.eRn)

    return ChordCompression(Ag=Ag, Py=Py_chord, Pne=global_.Rn, ePne=global_.eRn, Pcrℓ=Pcrℓ, local_buckling_properties=local_buckling_model, Pnℓ=local_.Rn, ePnℓ=local_.eRn, Pcrd=Pcrd, distortional_buckling_properties=distortional_buckling_model, Pnd=distortional.Rn, ePnd=distortional.eRn, ePn=ePn)

end

# chord splice channel to chord, 12 bolts; washers = true for washers under both bolt head and nut (mf = 1.00)
function calculate_chord_splice_strength(bolt_diameter, Fnv, Fu, design_code, t_splice, t_chord; num_bolts = 12, washers::Bool = false)

    return calculate_bolted_connection_strength(bolt_diameter, Fnv, Fu, design_code, t_splice, t_chord, num_bolts; washers = washers)

end

function calculate_chord_tensile_strength(chord_section_properties, chord_dimensions, joist_material_properties, design_code)

    Ag = chord_section_properties.A
    yield = DesignCode.tension_yield(Ag, joist_material_properties.fy, design_code)          #D2

    Anet = Ag - chord_dimensions.flange_punchout_width * chord_dimensions.t

    rupture = DesignCode.tension_rupture(Anet, joist_material_properties.fu, design_code)    #D3

    eTn = min(yield.eRn, rupture.eRn)

    return ChordTension(Ag=Ag, Tn_y=yield.Rn, eTn_y=yield.eRn, Anet=Anet, Tn_u=rupture.Rn, eTn_u=rupture.eRn, eTn=eTn)

end


#### bearing seat

function calculate_bearing_seat_weld_strength(weld, bearing_seat_dimensions, joist_material_properties, girder_dimensions, girder_material_properties, design_code)

    loading_direction = "longitudinal"
    tw = 0.707 * weld.t

    w = DesignCode.fillet_weld(weld.length, bearing_seat_dimensions.t, joist_material_properties.fu, girder_dimensions.top_flange_thickness, girder_material_properties.fu, tw, weld.Fxx, loading_direction, design_code)   #J2.5 (S100-16) / J2.6 (S100-2024)

    eRn = w.eRn * weld.num_lines

    return BearingSeatWeld(L=weld.length, t1=bearing_seat_dimensions.t, Fu1=joist_material_properties.fu, t2=girder_dimensions.top_flange_thickness, Fu2=girder_material_properties.fu, tw=tw, Fxx=weld.Fxx, loading_direction=loading_direction, Pnv1=w.Pnv1, Pnv2=w.Pnv2, Pn=w.Pn, Pnv=w.Rn, ePnv=w.eRn, num_weld_lines=weld.num_lines, eRn=eRn)

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
    local_ = DesignCode.compression_local(Pne, Pcrℓ, design_code)      #E3.2

    eRn = local_.eRn * bearing_seat_dimensions.num_webs

    return BearingSeatCompression(compression_field_width=compression_field_width, fcrℓ=fcrℓ, fy=joist_material_properties.fy, Pcrℓ=Pcrℓ, Pne=Pne, Pnℓ=local_.Rn, ePnℓ=local_.eRn, num_bearing_seat_webs=bearing_seat_dimensions.num_webs, eRn=eRn)

end

function calculate_bearing_seat_chord_connection_strength(joist_dimensions, bolt_properties, joist_material_properties, design_code, bearing_seat_dimensions, chord_dimensions)

    joist_ends = Geometry.define_joist_ends(joist_dimensions.span_length, joist_dimensions.node_spacing)

    strengths = map(joist_ends) do joist_end
        num_bolts = joist_end == 72.0 ? 4 : 3
        calculate_bolted_connection_strength(bolt_properties.diameter, bolt_properties.Fnv, joist_material_properties.fu, design_code, bearing_seat_dimensions.t, chord_dimensions.t, num_bolts)
    end

    return collect(strengths)

end


end  #module
