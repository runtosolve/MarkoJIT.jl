module Geometry

using DataFrames, LinearAlgebra, Statistics, Parameters, CrossSection

@with_kw struct ShieldPlateDimensions

    t::Float64
    Δy_bolt_hole::Float64
    node_location::Int64 

end


@with_kw struct BearingSeatDimensions

    t::Float64
    flange_hole_center_locations::NamedTuple{(:Δx, :Δy, :Δz), Tuple{Vector{Float64}, Vector{Float64}, Vector{Float64}}}
    web_hole_center_locations::NamedTuple{(:Δx, :Δy, :Δz), Tuple{Vector{Float64}, Vector{Float64}, Vector{Float64}}}
	height::Float64
    num_webs::Int64

end


@with_kw struct ChordDimensions

    t::Float64
    centerline_cross_section_coordinates::Vector{Tuple{Float64, Float64}}
    tab_hole_center_location::NamedTuple{(:Δx, :Δy, :Δz), Tuple{Float64, Float64, Float64}}
	seat_contact_depth::Float64
    flange_punchout_width::Float64

end

 


@with_kw struct DiagonalDimensions

    name::Vector{String}
    t::Vector{Float64}
    B::Vector{Float64}
    H::Vector{Float64}
    R::Vector{Float64}

end


@with_kw struct JoistDimensions

    span_length::Float64
    depth::Float64 
    node_spacing::Float64 
    bottom_chord_tail_length::Float64 
 

end

@with_kw struct Girder

	top_flange_width::Float64
    top_flange_thickness::Float64

end


@with_kw struct Coordinates

    diagonals::NamedTuple{(:top, :bottom), Tuple{Vector{Tuple{Float64, Float64}}, Vector{Tuple{Float64, Float64}}}}
    top_chord::Vector{Tuple{Float64, Float64}}
    bottom_chord::Vector{Tuple{Float64, Float64}}
    top_of_girder::Vector{Tuple{Float64, Float64}}

end




function define_joist_ends(span_length, node_spacing)

	num_nodes = span_length/node_spacing

	num_node_difference = num_nodes - floor(num_nodes)

	if num_node_difference == 0.50

		joist_ends = (4.0*12, (4.0+2.0)*12)

	elseif num_node_difference == 0.0

		joist_ends = ((4.0+2.0)*12, (4.0+2.0)*12)

	elseif num_node_difference == 0.75

		joist_ends = ((4.0+1.0)*12, (4.0+2.0)*12)

	elseif num_node_difference == 0.25
		
		joist_ends = (4.0*12, (4.0 + 1.0)*12)

	end

	return joist_ends

end


function define_first_chord_hole_location(;joist_end_length)

	if joist_end_length == (12.0 + 48.0)

		Δx_chord_hole_from_joist_end = 2.76

	elseif joist_end_length == (24.0 + 48.0)

		Δx_chord_hole_from_joist_end = 2.35

	# elseif joist_end_length == 36.0

	# 	Δx_chord_hole_from_joist_end = 2.76

	elseif joist_end_length == 48.0

		Δx_chord_hole_from_joist_end = 0.98

	end
	
	return Δx_chord_hole_from_joist_end

end

function calculate_bearing_seat_offset(joist_end_length, Δx_chord_hole_from_joist_end, Δx_bearing_seat_chord_holes)

	if joist_end_length == (48.0 + 12.0)

		Δx_seat = Δx_chord_hole_from_joist_end - Δx_bearing_seat_chord_holes[2]

	elseif joist_end_length == (48.0 + 24.0)

		Δx_seat = Δx_chord_hole_from_joist_end - Δx_bearing_seat_chord_holes[2]

	# elseif joist_end_length == 36.0

	# 	Δx_seat = Δx_chord_hole_from_joist_end - Δx_bearing_seat_chord_holes[2]

	elseif joist_end_length == 48.0

		Δx_seat = Δx_chord_hole_from_joist_end - Δx_bearing_seat_chord_holes[1]  #uses 1st bearing seat flange hole 

	end
	
	return Δx_seat 

end 


function calculate_joist_diagonal_coordinates(span_length, depth, bottom_chord_tail_length, node_spacing, bearing_seat, chord)

    #determine joist end node spacing
    joist_ends = define_joist_ends(span_length, node_spacing)

    #calculate number of regularly spaced joist units 
    num_typical_units = floor(Int, (span_length - joist_ends[1] - joist_ends[2])/node_spacing)

    #work from left end, calculate diagonal geometries 

    #end unit

    #first diagonal 

    # find location of chord bolt hole from joist end 
    Δx_chord_hole_from_joist_end = define_first_chord_hole_location(joist_end_length=joist_ends[1])

    # define offset of seat end from centerline bearing 
    Δx_seat_1 = calculate_bearing_seat_offset(joist_ends[1], Δx_chord_hole_from_joist_end, bearing_seat.flange_hole_center_locations.Δx)

    # define location of top bolt hole 
    x_seat_top_bolt_1 = bearing_seat.web_hole_center_locations.Δx[2] + Δx_seat_1

    Δy_chord_seat_contact = chord.centerline_cross_section_coordinates[Int(median(1:length(chord.centerline_cross_section_coordinates)))][2] - chord.t 

    y_seat_top_bolt_1 = -Δy_chord_seat_contact + bearing_seat.web_hole_center_locations.Δy[2]

    #define location of bottom bolt hole

    # if joist_ends[1] == 12.0  #in this case there is no bearing seat at the bottom chord  

        x_seat_bottom_bolt_1 = (joist_ends[1] - node_spacing/2) - chord.tab_hole_center_location.Δx
        y_seat_bottom_bolt_1 = -depth + chord.tab_hole_center_location.Δy

    # else

    #     x_seat_bottom_bolt_1 = x_support_to_bottom_chord + Δx_seat_1 + bearing_seat.web_hole_center_locations.Δx[1]
    #     y_seat_bottom_bolt_1 = -depth + Δy_chord_seat_contact - bearing_seat.web_hole_center_locations.Δy[1]

    # end

    top_coordinates = [(x_seat_top_bolt_1, y_seat_top_bolt_1)]
    bottom_coordinates = [(x_seat_bottom_bolt_1, y_seat_bottom_bolt_1)]

    #second diagonal 
 

    # if joist_ends[1] == 12.0

    #     x_end_compression_diagonal_1_top = joist_ends[1] + node_spacing - chord.tab_hole_center_location.Δx
    #     y_end_compression_diagonal_1_top = -chord.tab_hole_center_location.Δy

    #     x_end_compression_diagonal_1_bottom = x_support_to_bottom_chord + joist_ends[1] + chord.tab_hole_center_location.Δx
    #     y_end_compression_diagonal_1_bottom = -depth + chord.tab_hole_center_location.Δy

    # else

        x_end_compression_diagonal_1_top = joist_ends[1] - chord.tab_hole_center_location.Δx
        y_end_compression_diagonal_1_top = -chord.tab_hole_center_location.Δy

        x_end_compression_diagonal_1_bottom = (joist_ends[1] - node_spacing/2) + chord.tab_hole_center_location.Δx
        y_end_compression_diagonal_1_bottom = -depth + chord.tab_hole_center_location.Δy

    # end

    top_coordinates = [top_coordinates; (x_end_compression_diagonal_1_top, y_end_compression_diagonal_1_top)]
    bottom_coordinates = [bottom_coordinates; (x_end_compression_diagonal_1_bottom, y_end_compression_diagonal_1_bottom)]

    #add the regular joist units now 

    # if joist_ends[1] == 12.0
    #     bottom_start = (joist_ends[1] + x_support_to_bottom_chord + node_spacing, -depth + chord.tab_hole_center_location.Δy)
    #     top_start = (joist_ends[1] + node_spacing, -chord.tab_hole_center_location.Δy)
    #     num_typical_units = num_typical_units - 1
    # else
        bottom_start = (joist_ends[1] + node_spacing/2, -depth + chord.tab_hole_center_location.Δy)
        top_start = (joist_ends[1], -chord.tab_hole_center_location.Δy)
    # end

    for i = 1:num_typical_units

        top = top_start .+ (chord.tab_hole_center_location.Δx, 0.0)  
        bottom = bottom_start .+ ( -chord.tab_hole_center_location.Δx, 0.0) 

        top_coordinates = [top_coordinates; top]
        bottom_coordinates = [bottom_coordinates; bottom]

        top = top_start .+ (node_spacing - chord.tab_hole_center_location.Δx, 0.0)
        bottom = bottom_start .+ (chord.tab_hole_center_location.Δx, 0.0)

        top_coordinates = [top_coordinates; top]
        bottom_coordinates = [bottom_coordinates; bottom]

        top_start = top_start .+ (node_spacing, 0.0)
        bottom_start = bottom_start .+ (node_spacing, 0.0)

    end

    #add last unit 

    # find location of chord bolt hole from joist end 
    Δx_chord_hole_from_joist_end = define_first_chord_hole_location(joist_end_length=joist_ends[2])

    # define offset of seat end from centerline bearing 
    Δx_seat_2 = calculate_bearing_seat_offset(joist_ends[2], Δx_chord_hole_from_joist_end, bearing_seat.flange_hole_center_locations.Δx)


    #second diagonal 
   


    x_end_compression_diagonal_2_top = joist_ends[2] - chord.tab_hole_center_location.Δx
    y_end_compression_diagonal_2_top = -chord.tab_hole_center_location.Δy


    x_end_compression_diagonal_2_bottom =  (joist_ends[2] - node_spacing/2) + chord.tab_hole_center_location.Δx
    y_end_compression_diagonal_2_bottom = -depth + chord.tab_hole_center_location.Δy

    # x_end_compression_diagonal_2_bottom = x_support_to_bottom_chord + Δx_seat_2 + bearing_seat.web_hole_center_locations.Δx[2]
    # y_end_compression_diagonal_2_bottom = -depth + Δy_chord_seat_contact - bearing_seat.web_hole_center_locations.Δy[2]


    x_end_compression_diagonal_2_top = span_length - x_end_compression_diagonal_2_top
    x_end_compression_diagonal_2_bottom = span_length - x_end_compression_diagonal_2_bottom

    top_coordinates = [top_coordinates; (x_end_compression_diagonal_2_top, y_end_compression_diagonal_2_top)]
    bottom_coordinates = [bottom_coordinates; (x_end_compression_diagonal_2_bottom, y_end_compression_diagonal_2_bottom)]

    # define location of top bolt hole 
    x_seat_top_bolt_2 = bearing_seat.web_hole_center_locations.Δx[2] + Δx_seat_2
    y_seat_top_bolt_2 = -Δy_chord_seat_contact + bearing_seat.web_hole_center_locations.Δy[2]

    #define location of bottom bolt hole
    x_seat_bottom_bolt_2 =  (joist_ends[2] - node_spacing/2) - chord.tab_hole_center_location.Δx
    y_seat_bottom_bolt_2 = -depth + chord.tab_hole_center_location.Δy

    x_seat_top_bolt_2 = span_length - x_seat_top_bolt_2
    x_seat_bottom_bolt_2  = span_length - x_seat_bottom_bolt_2 

    top_coordinates = [top_coordinates; (x_seat_top_bolt_2, y_seat_top_bolt_2)]
    bottom_coordinates = [bottom_coordinates; (x_seat_bottom_bolt_2, y_seat_bottom_bolt_2)]

    coordinates = (top = top_coordinates, bottom = bottom_coordinates)

    return coordinates

end


function calculate_diagonal_angle(bottom_node, top_node)

	Δ = bottom_node .- top_node
    θ = atan(Δ[2], Δ[1])

    return θ

end

function define_top_chord_coordinates(chord_section_properties, diagonal_coordinates, joist)

    #define first node at end of joist 
    top_chord_coordinates = [(0.0, chord_section_properties.yc)]

    ##the next node is defined by the bearing seat and the angle of the first tension diagonal, and the girder flange width 

    #calculate the 1st diagonal angle 

    θ = calculate_diagonal_angle(diagonal_coordinates.bottom[1], diagonal_coordinates.top[1])

    #offset from chord centroid to centerline 1st diagonal bolt hole
    Δy_chord_offset = diagonal_coordinates.top[1][2] - chord_section_properties.yc 
    Δx_chord_offset = Δy_chord_offset/tan(θ)

    top_chord_coordinates = [top_chord_coordinates; (diagonal_coordinates.top[1][1] - Δx_chord_offset, chord_section_properties.yc)]

    #now add all the typical top chord node locations 

    for i in eachindex(diagonal_coordinates.top)[2:2:end-1]
        top_chord_coordinates = [top_chord_coordinates; (mean([diagonal_coordinates.top[i][1],diagonal_coordinates.top[i+1][1]]), chord_section_properties.yc)]
    end

    #now add right end bearing seat node
    θ = calculate_diagonal_angle(diagonal_coordinates.bottom[end], diagonal_coordinates.top[end])
    # Δx = diagonal_coordinates.bottom[end][1] - diagonal_coordinates.top[end][1]
    # Δy = diagonal_coordinates.bottom[end][2] - diagonal_coordinates.top[end][2]
    # θ = atan(Δy, Δx)

    Δy_chord_offset = diagonal_coordinates.top[end][2] - chord_section_properties.yc 
    Δx_chord_offset = -Δy_chord_offset/tan(θ)  #negative sign here to move towards bearing seat 

    top_chord_coordinates = [top_chord_coordinates; (diagonal_coordinates.top[end][1] + Δx_chord_offset, chord_section_properties.yc)]

    #add last node at end of joist
    top_chord_coordinates = [top_chord_coordinates; (joist.span_length, chord_section_properties.yc)]

    return top_chord_coordinates

end

function define_bottom_chord_coordinates(joist, chord_section_properties, diagonal_coordinates)

    #determine joist end node spacing
    joist_ends = define_joist_ends(joist.span_length, joist.node_spacing)

    x_support_to_bottom_chord_1 = (joist_ends[1] - joist.node_spacing/2) - joist.bottom_chord_tail_length
    x_support_to_bottom_chord_2 = joist.span_length - ((joist_ends[2] - joist.node_spacing/2) - joist.bottom_chord_tail_length)

    #first coordinate
    bottom_chord_coordinates = [(x_support_to_bottom_chord_1, -joist.depth - chord_section_properties.yc)]

    #fill the field 
    for i in eachindex(diagonal_coordinates.top)[1:2:end-1]
        bottom_chord_coordinates = [bottom_chord_coordinates; (mean([diagonal_coordinates.bottom[i][1],diagonal_coordinates.bottom[i+1][1]]), -joist.depth - chord_section_properties.yc)]
    end

    #last coordinate, end of joist 
    bottom_chord_coordinates = [bottom_chord_coordinates; (x_support_to_bottom_chord_2, -joist.depth - chord_section_properties.yc)]

    return bottom_chord_coordinates

end

function define_top_of_girder_coordinates(bearing_seat, girder, chord, joist)

    Δy = -chord.seat_contact_depth - bearing_seat.height
    girder_flange_coordinates = [(girder.top_flange_width/2/2, Δy), (joist.span_length - girder.top_flange_width/2/2, Δy)]

    return girder_flange_coordinates

end

function define_diagonal_cross_section_geometry(B, H, R, t)

    L = [B, H, B]
    θ = [π/2, 0.0, -π/2]
    r = [R, R]
    n = [5, 5, 5]
    n_r = [5, 5]
    section_geometry = CrossSection.Geometry.create_thin_walled_cross_section_geometry(L, θ, n, r, n_r, t, centerline = "to right", offset = (0.0, 0.0))

    return section_geometry

end

function calculate_number_of_joist_diagonals(span_length, node_spacing)

    joist_ends = define_joist_ends(span_length, node_spacing)
    num_typical_units = floor(Int, (span_length - joist_ends[1] - joist_ends[2])/node_spacing)

    if joist_ends[1] == 12.0
        num_diagonals = num_typical_units * 2 + 2 
    else
        num_diagonals = num_typical_units * 2 + 2 + 2
    end

    return num_diagonals

end

# function define_initial_chord_splice_location(span_length, node_spacing, bottom_chord_tail_length)

#     if span_length <= 36.0 * 12  #for shorter spans, so no splice 
#         top_chord_splice_location = [0.0]
#     elseif (span_length > 36.0 * 12) & (span_length < 50.0 * 12)
#         chord_length = (span_length - 36.0*12.0)
#         if chord_length < 7.0*12
#             chord_length = 7.0*12
#         end
#         top_chord_splice_location = [chord_length]
#     else
#         chord_length = (span_length - 36.0*12.0)/2
#         top_chord_splice_location = [chord_length, chord_length + 36.0*12]
#     end
#     # elseif (span_length > 38.0 * 12) & (span_length < 50.0 * 12)  
#     #     top_chord_splice_location= [span_length - 36.0*12]
#     # elseif (span_length >= 50.0 * 12)  
#     #     chord_length = (span_length - 36.0*12.0)/2
#     #     top_chord_splice_location = [chord_length, chord_length + 36.0*12]
#     # end

#     joist_ends = define_joist_ends(span_length, node_spacing)
#     bottom_chord_length = span_length - (joist_ends[1] - node_spacing/2) - (joist_ends[2] - node_spacing/2) + bottom_chord_tail_length*2

#     if bottom_chord_length <= 32.0 * 12  #for shorter spans, so no splice 
#         bottom_chord_splice_location = [0.0]
#     else
#         chord_length = (bottom_chord_length - 32.0*12.0)/2
#         bottom_chord_splice_location = [chord_length, chord_length + 32.0*12] .+ (joist_ends[1] - node_spacing/2 - bottom_chord_tail_length)
#     end

#     # elseif (bottom_chord_length > 38.0 * 12) & (bottom_chord_length < 50.0 * 12)  
#     #     bottom_chord_splice_location= [bottom_chord_length - 36.0*12] .+ (joist_ends[1] - node_spacing/2 - bottom_chord_tail_length)
#     # elseif (bottom_chord_length >= 50.0 * 12)  
#     #     chord_length = (bottom_chord_length - 36.0*12.0)/2
#     #     top_chord_splice_location = [chord_length, chord_length + 36.0*12] .+ (joist_ends[1] - node_spacing/2 - bottom_chord_tail_length)
#     # end

#     chord_splice_location = (top = top_chord_splice_location, bottom = bottom_chord_splice_location)

#     return chord_splice_location

# end


# function center_splice_location(splice_location, X_chord)

#     node_index = findall(X->X<splice_location, X_chord)[end]

#     X_i = X_chord[node_index]
#     X_j = X_chord[node_index+1]

#     chord_splice_location = (X_i+X_j)/2

#     return chord_splice_location

# end


# function define_chord_splice_locations(span_length, node_spacing, bottom_chord_tail_length, X_top_chord, X_bottom_chord)

#     initial_chord_splice_locations = define_initial_chord_splice_location(span_length, node_spacing, bottom_chord_tail_length)

#     if initial_chord_splice_locations.top != [0.0]
#         top_chord_splice_locations = [center_splice_location(initial_chord_splice_locations.top[i], X_top_chord) for i in eachindex(initial_chord_splice_locations.top)]
#     else
#         top_chord_splice_locations = [0.0]
#     end

#     if initial_chord_splice_locations.bottom != [0.0]
#         bottom_chord_splice_locations = [center_splice_location(initial_chord_splice_locations.bottom[i], X_bottom_chord) for i in eachindex(initial_chord_splice_locations.bottom)]
#     else
#         bottom_chord_splice_locations = [0.0]
#     end

#     chord_splice_locations = (top = top_chord_splice_locations, bottom = bottom_chord_splice_locations)

#     return chord_splice_locations

# end




function define_chord_splice_locations(span_length)


    top_chord_1 = [36	6	6	0	0
    37	4	6	0	3
    38	4	6	6	0
    39	5	6	7	0
    40	6	6	4	0
    41	4	5	5	0
    42	4	6	6	0
    43	5	6	7	0
    44	6	6	8	0]

    span_range = 45:100
    top_chord_2 = Matrix{Float64}(undef, length(span_range), 5)
    top_chord_2[:, 1] = span_range
    top_chord_2[:, 2] = repeat([4, 4, 5, 6], 14)
    top_chord_2[:, 3] = repeat([5, 6, 6, 6], 14)

    end_1_top_chord = []
    for i=1:7
        end_1_top_chord = [end_1_top_chord; [6, 6, 7, 8, 6, 6, 7, 8] .+ (i-1) * 4]
    end

    end_2_top_chord = [7, 8, 8, 8]
    for i=1:7
        end_2_top_chord = [end_2_top_chord; [7, 8, 8, 8, 7, 8, 8, 8] .+ (i-1) * 4]
    end

    top_chord_2[:, 4] = end_1_top_chord
    top_chord_2[:, 5] = end_2_top_chord[1:length(span_range)]

    top_chord = [top_chord_1; top_chord_2]

    top_chord[:, 1] = top_chord[:, 1] .* 12
    top_chord[:, 4] = top_chord[:, 4] .* 12
    top_chord[:, 5] = top_chord[:, 5] .* 12

    bottom_chord_1 = [36	6	6	0	0
    37	4	6	0	0
    38	4	6	0	0
    39	5	6	0	0
    40	6	6	0	0
    41	4	5	3	3
    42	4	6	3	3
    43	5	6	3	3
    44	6	6	3	3
    45	4	5	7	3
    46	4	6	7	3
    47	5	6	7	3
    48	6	6	7	3
    49	4	5	7	7
    50	4	6	7	7
    51	5	6	7	7
    52	6	6	7	7]


    span_range = 53:100
    bottom_chord_2 = Matrix{Float64}(undef, length(span_range), 5)
    bottom_chord_2[:, 1] = span_range

    end_1_bottom_chord = [7, 7, 7, 7]
    for i=1:6
        end_1_bottom_chord = [end_1_bottom_chord; [11, 11, 11, 11, 11, 11, 11, 11] .+ (i-1) * 4]
    end

    end_1_bottom_chord = end_1_bottom_chord[1:length(span_range)]


    end_2_bottom_chord = []
    for i=1:6
        end_2_bottom_chord = [end_2_bottom_chord; [7, 7, 7, 7, 7, 7, 7, 7] .+ (i-1) * 4]
    end

    end_2_bottom_chord = end_2_bottom_chord[1:length(span_range)]

    bottom_chord_2[:, 4] = end_1_bottom_chord
    bottom_chord_2[:, 5] = end_2_bottom_chord

    bottom_chord = [bottom_chord_1; bottom_chord_2]

    bottom_chord[:, 1] = bottom_chord[:, 1] * 12
    bottom_chord[:, 2] = top_chord[:, 2] * 12
    bottom_chord[:, 3] = top_chord[:, 3] * 12
    bottom_chord[:, 4] = bottom_chord[:, 4] * 12
    bottom_chord[:, 5] = bottom_chord[:, 5] * 12

    chord_index = findfirst(span->span==span_length, top_chord[:, 1])

    top_chord_splice_1 = top_chord[chord_index, 4]
    top_chord_splice_2 = top_chord[chord_index, 5]

    if top_chord_splice_1 == 0.0
        top_chord_splice_1 = []
    end

    if top_chord_splice_2 == 0.0
        top_chord_splice_2 = []
    else
        top_chord_splice_2 = span_length - top_chord_splice_2
    end

    top_chord_splice_locations = [top_chord_splice_1; top_chord_splice_2]



    bottom_chord_splice_1 = bottom_chord[chord_index, 4]
    bottom_chord_splice_2 = bottom_chord[chord_index, 5]

    if bottom_chord_splice_1 == 0.0
        bottom_chord_splice_1 = []
    else
        bottom_chord_splice_1 = bottom_chord[chord_index, 2] - 24.0 - 12.0 + bottom_chord_splice_1
    end

    if bottom_chord_splice_2 == 0.0
        bottom_chord_splice_2 = []
    else
        bottom_chord_splice_2 = span_length - (bottom_chord[chord_index, 3] - 24.0 - 12.0 + bottom_chord_splice_2)
    end

    bottom_chord_splice_locations = [bottom_chord_splice_1; bottom_chord_splice_2]


    chord_splice_locations = (top = top_chord_splice_locations, bottom = bottom_chord_splice_locations)

    return chord_splice_locations

end



end #module
