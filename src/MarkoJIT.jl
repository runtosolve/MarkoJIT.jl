module MarkoJIT

using StructuresKit
using Unitful, UnitfulUS
using DataFrames
using LinearAlgebra



function define_joist_ends(span_length, node_spacing)

	num_nodes = span_length/node_spacing

	num_node_difference = num_nodes - floor(num_nodes)

	if num_node_difference == 0.50

		joist_ends = (4.0u"sft_us", 2.0u"sft_us")

	elseif num_node_difference == 0.00

		joist_ends = (2.0u"sft_us", 2.0u"sft_us")

	elseif num_node_difference == 0.75

		joist_ends = (1.0u"sft_us", 2.0u"sft_us")

	elseif num_node_difference == 0.75
		
		joist_ends = (3.0u"sft_us", 2.0u"sft_us")

	end

	return joist_ends

end


function define_first_chord_hole_location(;joist_end_length)

	if joist_end_length == 1.0u"sft_us"

	#	Δx_chord_hole_from_joist_end =  needs a special treatment I think, there is no bottom chord seat in this case 

	elseif joist_end_length == 2.0u"sft_us"

		Δx_chord_hole_from_joist_end = 2.35u"sinch_us"

	elseif joist_end_length == 3.0u"sft_us"

		Δx_chord_hole_from_joist_end = 2.76

	elseif joist_end_length == 4.0u"sft_us"

		Δx_chord_hole_from_joist_end = 0.98u"sinch_us"

	end
	
	return Δx_chord_hole_from_joist_end

end

function calculate_diagonal_length_and_angle(x1, x2, y1, y2)
	
	L = round(u"sinch_us", norm([(x2 - x1), (y2 - y1)]), sigdigits = 4)
	
	α = abs(round(rad2deg(atan((y2 - y1)/((x2 - x1)))), sigdigits=4)) #degrees

	return L, α

end


function calculate_typical_joist_diagonal_geometry(node_spacing, Δy_chord_to_hole, Δx_node_to_hole, joist_depth)

	y1 = Δy_chord_to_hole
	y2 = joist_depth - Δy_chord_to_hole

	x1 = Δx_node_to_hole
	x2 = node_spacing/2 - Δx_node_to_hole
	
	L_diagonal, α_diagonal = calculate_diagonal_length_and_angle(x1, x2, y1, y2)
	
	return L_diagonal, α_diagonal
	
end


function calculate_bearing_seat_offset(joist_end_length, Δx_chord_hole_from_joist_end, Δx_bearing_seat_chord_holes)

	if joist_end_length == 1.0u"sft_us"

		Δx_seat = Δx_chord_hole_from_joist_end - Δx_bearing_seat_chord_holes[2]

	elseif joist_end_length == 2.0u"sft_us"

		Δx_seat = Δx_chord_hole_from_joist_end - Δx_bearing_seat_chord_holes[2]

	elseif joist_end_length == 3.0u"sft_us"

		Δx_seat = Δx_chord_hole_from_joist_end - Δx_bearing_seat_chord_holes[2]

	elseif joist_end_length == 4.0u"sft_us"

		Δx_seat = Δx_chord_hole_from_joist_end - Δx_bearing_seat_chord_holes[1]

	end

	Δx_seat = round(u"sinch_us", Δx_seat, sigdigits=3)
	
	return Δx_seat 

end 

function calculate_end_tension_diagonal_geometry(Δx_seat_far_bolt_hole, Δx_seat, x_support_to_bottom_chord, Δx_seat_near_bolt_hole, Δy_chord_seat_contact, Δy_seat_top_bolt, joist_depth)
	
	x1 = Δx_seat_far_bolt_hole + Δx_seat
	
	x2 = round(u"sinch_us", x_support_to_bottom_chord + Δx_seat + Δx_seat_near_bolt_hole, sigdigits=4)
	
	y1 = round(u"sinch_us", (Δy_chord_seat_contact + Δy_seat_top_bolt), sigdigits = 4)
	
	y2 = joist_depth - Δy_chord_seat_contact - Δy_seat_top_bolt
	
	L_diagonal, α_diagonal = calculate_diagonal_length_and_angle(x1, x2, y1, y2)
	
	return L_diagonal, α_diagonal
	
end

function calculate_end_compression_diagonal_geometry(joist_end_length, Δx_node_to_hole, x_support_to_bottom_chord, Δx_seat,  Δx_seat_far_bolt_hole, Δy_chord_to_hole, joist_depth, Δy_chord_seat_contact, Δy_seat_top_bolt)

	x1 = joist_end_length - Δx_node_to_hole
	
	x2 = x_support_to_bottom_chord + Δx_seat + Δx_seat_far_bolt_hole 
	
	y1 = Δy_chord_to_hole
	
	y2 = joist_depth - Δy_chord_seat_contact - Δy_seat_top_bolt
	
	L_diagonal, α_diagonal = calculate_diagonal_length_and_angle(x1, x2, y1, y2)
	
	return L_diagonal, α_diagonal
	
end

function calculate_joist_diagonal_geometry(joist_ends, Δx_chord_hole_from_joist_end_1, Δx_chord_hole_from_joist_end_2, Δx_seat_1, Δx_seat_2, node_spacing, Δy_chord_to_hole, Δx_node_to_hole, joist_spacing, Δx_seat_far_bolt_hole, Δx_seat_near_bolt_hole, x_support_to_bottom_chord, Δy_chord_seat_contact, Δy_seat_top_bolt, Δx_bearing_seat_chord_holes, joist_depth)

	#typical diagonal
	L_diagonal, α_diagonal = calculate_typical_joist_diagonal_geometry(node_spacing, Δy_chord_to_hole, Δx_node_to_hole, joist_depth)

	#tension diagonal, end No. 1
	L_end_diagonal_tension_1, α_end_diagonal_tension_1 = calculate_end_tension_diagonal_geometry(Δx_seat_far_bolt_hole, Δx_seat_1, x_support_to_bottom_chord, Δx_seat_near_bolt_hole, Δy_chord_seat_contact, Δy_seat_top_bolt, joist_depth)
	
	#tension diagonal, end No. 2
	L_end_diagonal_tension_2, α_end_diagonal_tension_2 = calculate_end_tension_diagonal_geometry(Δx_seat_far_bolt_hole, Δx_seat_2, x_support_to_bottom_chord, Δx_seat_near_bolt_hole, Δy_chord_seat_contact, Δy_seat_top_bolt, joist_depth)

	#compression diagonal, end No. 1
	L_end_diagonal_compression_1, α_end_diagonal_compression_1 = calculate_end_compression_diagonal_geometry(joist_ends[1], Δx_node_to_hole, x_support_to_bottom_chord, Δx_seat_1, Δx_seat_far_bolt_hole, Δy_chord_to_hole, joist_depth, Δy_chord_seat_contact, Δy_seat_top_bolt)

	#compression diagonal, end No. 2
		L_end_diagonal_compression_2, α_end_diagonal_compression_2 = calculate_end_compression_diagonal_geometry(joist_ends[2], Δx_node_to_hole, x_support_to_bottom_chord, Δx_seat_2, Δx_seat_far_bolt_hole, Δy_chord_to_hole, joist_depth, Δy_chord_seat_contact, Δy_seat_top_bolt)

	#consolidate into named tuple

	α = (typical=α_diagonal, T1 = α_end_diagonal_tension_1,  C1 = α_end_diagonal_compression_1, T2 = α_end_diagonal_tension_2, C2 = α_end_diagonal_compression_2)

	L = (typical=L_diagonal, T1 = L_end_diagonal_tension_1,  C1 = L_end_diagonal_compression_1, T2 = L_end_diagonal_tension_2, C2 = L_end_diagonal_compression_2)

	return L, α

end
	
function calculate_cross_section_coordinates(;ΔL, Θ, n, radius, n_radius, t)

	#Define the cross-section feature.  
	closed_or_open = 1
	feature = CrossSection.Feature(ΔL, Θ, n, radius, n_radius, closed_or_open)
	
	#Calculate the out-to-out surface coordinates.
	xcoords_out, ycoords_out = CrossSection.get_xy_coordinates(feature)
	
	#Shift coordinates.
	xcoords_out = xcoords_out .- maximum(xcoords_out)/2
	ycoords_out = ycoords_out .- minimum(ycoords_out)

	#Calculate surface normals.
	unitnormals = CrossSection.surface_normals(xcoords_out, ycoords_out, closed_or_open)
        
	#Calculate node normals.	
	nodenormals = CrossSection.avg_node_normals(unitnormals, closed_or_open)
    
	#Go from outside surface to centerline coordinates.
	xcoords_center, ycoords_center = CrossSection.xycoords_along_normal(xcoords_out, ycoords_out, nodenormals, t/2)
	
	#Calculate the inside surface.
	xcoords_in, ycoords_in = CrossSection.xycoords_along_normal(xcoords_out, ycoords_out, nodenormals, t)
	
	coords_out = [xcoords_out, ycoords_out]
	coords_centerline = [xcoords_center, ycoords_center]
	coords_in = [xcoords_in, ycoords_in]
	
	return coords_out, coords_centerline, coords_in
	
end

function define_cross_section_element_connectivity(;num_elem, t)
		
	element_info = []
	
	for i = 1:num_elem
		
		if i == 1
			
			element_info = [[i, i+1, t]']
			
		else
			
			element_info = [element_info; [[i, i+1, t]']]
			

		end
		
	end
		

	element_info = vcat(element_info...)
	
	return element_info

end

function calculate_column_critical_elastic_global_buckling_stress(;E, I, L, A)
	
	Fcre = π^2*E*I/L^2/A
	
end

function create_CUFSM_node(coords_centerline)
	
	num_cross_section_nodes = size(coords_centerline[1])[1]
	node = zeros(Float64, (num_cross_section_nodes, 8))
	node[:, 1] .= 1:num_cross_section_nodes
    node[:, 2] .= ustrip(coords_centerline[1])
	node[:, 3] .= ustrip(coords_centerline[2])
	node[:, 4:7] .= ones(num_cross_section_nodes,4)
	
	return node
	
end

function create_CUFSM_elem(;element_info)
	
	num_cross_section_elements = size(element_info)[1]
	elem = zeros(Float64, (num_cross_section_elements, 5))
	elem[:, 1] = 1:num_cross_section_elements
	elem[:, 2:4] .= ustrip.(element_info)
	elem[:, 5] .= ones(num_cross_section_elements) * 100
	
	return elem
end

function grab_CUFSM_load_factor(;curve)
	
	num_lengths = size(curve)[1]
	load_factor = [curve[i,1][2] for i=1:num_lengths]
	
	return load_factor
	
end

function calculate_web_diagonal_compressive_strength(ΔL, Θ, n, radius, n_radius, t, Fy, E, L_unbraced, design_code)
	
	
	coords_out, coords_centerline, coords_in = calculate_cross_section_coordinates(ΔL=ΔL, Θ=Θ, n=n, radius=radius, n_radius=n_radius, t=t)
		
	element_info = define_cross_section_element_connectivity(num_elem=length(coords_out[1])-1, t=t)
	
	web_diagonal_section_properties = CUFSM.cutwp_prop2([ustrip(coords_centerline[1]) ustrip(coords_centerline[2])], ustrip.(element_info))
	
	A_diagonal = round(u"sinch_us^2", web_diagonal_section_properties.A*1.0*u"sinch_us^2", sigdigits=3)
		
	Py_diagonal = round(u"lbf", A_diagonal * Fy, sigdigits=4)
		
	Fcre_diagonal = round(u"lbf/sinch_us^2", calculate_column_critical_elastic_global_buckling_stress(;E=E, I=web_diagonal_section_properties.Ixx*u"sinch_us^4", L=L_unbraced, A=A_diagonal), sigdigits=4)
		
	Pne_diagonal, ePne_diagonal = round.(u"lbf", AISIS10016.e2(Fcre=Fcre_diagonal, Fy=Fy, Ag=A_diagonal, design_code=design_code), sigdigits=4)
		
	#no local buckling influence
	Pnℓ_diagonal = Pne_diagonal
	ePnℓ_diagonal = ePne_diagonal
	
	return  Pnℓ_diagonal, ePnℓ_diagonal
		
end

function calculate_web_diagonal_tensile_strength(cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal,t, Fy, Fu, bolt_hole_diameter, design_code)

    coords_out, coords_centerline, coords_in = calculate_cross_section_coordinates(ΔL=cross_section_segments_diagonal, Θ=cross_section_segment_angles_diagonal, n=n_diagonal, radius=radius_diagonal, n_radius=n_radius_diagonal, t=t)
        
    element_info = define_cross_section_element_connectivity(num_elem=length(coords_out[1])-1, t=t)

    web_diagonal_section_properties = CUFSM.cutwp_prop2([ustrip(coords_centerline[1]) ustrip(coords_centerline[2])], ustrip.(element_info))

    A_diagonal = round(u"sinch_us^2", web_diagonal_section_properties.A*1.0*u"sinch_us^2", sigdigits=3)

    Tn_y, eTn_y = round.(u"lbf", AISIS10016.d21(Ag=A_diagonal, Fy=Fy, design_code=design_code), sigdigits=4)

    Anet_diagonal = round(u"sinch_us^2", A_diagonal - 2 * bolt_hole_diameter * t_diagonal, sigdigits=3)

    Tn_u_diagonal, eTn_u_diagonal = round.(u"lbf", AISIS10016.d31(An=Anet_diagonal, Fu=Fu, design_code=design_code), sigdigits=4)

    eTn_diagonal = minimum([eTn_y_diagonal, eTn_u_diagonal])

    return eTn_diagonal

end	

function define_chord_surfaces(;node, t)
	
	xcoords_center = node[:, 2]
	ycoords_center = node[:, 3]
	
	closed_or_open = 1
	unitnormals = CrossSection.surface_normals(xcoords_center, ycoords_center, closed_or_open)
	nodenormals = CrossSection.avg_node_normals(unitnormals, closed_or_open)
	
	xcoords_out, ycoords_out = CrossSection.xycoords_along_normal(xcoords_center, ycoords_center, nodenormals, -t/2)
	
	xcoords_in, ycoords_in = CrossSection.xycoords_along_normal(xcoords_center, ycoords_center, nodenormals, t/2)
	
	coords_out = [xcoords_out, ycoords_out]
	coords_centerline = [xcoords_center, ycoords_center]
	coords_in = [xcoords_in, ycoords_in]
	
	return coords_out, coords_centerline, coords_in
	
end
	
function unreinforced_truss_node_connection_strength(bolt_diameter, Fnv, t_chord, Fu, design_code)
	
	
	Pn_bolt, ePn_bolt = round.(u"lbf", AISIS10016.appAj341(Ab = π * (bolt_diameter/2)^2, Fn = Fnv, design_code = design_code), sigdigits=4)
	
	C = AISIS10016.tablej3311(d=bolt_diameter, t=t_chord, hole_shape = "standard hole")
	
	mf = AISIS10016.tablej3312(connection_type="single shear", hole_shape="standard hole", washers="no")
	
	Pnb, ePnb = round.(u"lbf", AISIS10016.j3311(C=C, mf=mf, d=bolt_diameter, t=t_chord, Fu=Fu, design_code=design_code), sigdigits=4)
	
	ePn = minimum([ePn_bolt; ePnb])
	
	ePn_unreinforced_connection = minimum([ePn_bolt; ePnb]) .* 2
	
	return ePn_unreinforced_connection
	
end

function reinforced_truss_node_connection_strength(bolt_diameter, Fnv, t_shield_plate, t_diagonal, Fu, design_code)
		
	Pn_bolt, ePn_bolt = round.(u"lbf", AISIS10016.appAj341(Ab = π * (bolt_diameter/2)^2, Fn = Fnv, design_code = design_code), sigdigits=4)
	
	C = AISIS10016.tablej3311(d=bolt_diameter, t=t_chord, hole_shape = "standard hole")
	
	mf = AISIS10016.tablej3312(connection_type="single shear", hole_shape="standard hole", washers="no")
	
	Pnb_shield_plate, ePnb_shield_plate = round.(u"lbf", AISIS10016.j3311(C=C, mf=mf, d=bolt_diameter, t=t_shield_plate, Fu=Fu, design_code=design_code), sigdigits=4)
	
	Pnb_diagonal, ePnb_diagonal = round.(u"lbf", AISIS10016.j3311(C=C, mf=mf, d=bolt_diameter, t=t_diagonal, Fu=Fu, design_code=design_code), sigdigits=4)
	
	Anv = round(u"sinch_us^2", 0.59u"sinch_us" * t_shield_plate * 2, sigdigits=3)
	
	Pnv, ePnv = AISIS10016.j611(Anv, Fu, design_code, "bolts")
	
	reinforced_connection_limit_state_strengths = round.(u"lbf", [ePn_bolt*4; ePnv*2+ ePnb_diagonal*2; ePnb_diagonal*2 + ePnb_shield_plate*2], sigdigits=4)
	
	eRn_reinforced_connection = minimum(reinforced_connection_limit_state_strengths)
	
	return eRn_reinforced_connection
	
end	

function calculate_compression_field_angle(Δx_chord_hole_from_joist_end, Δx_seat,  Δx_seat_far_bolt_hole, girder_flange_width, Δy_chord_seat_contact, h_seat, α_end_diagonal_tension)
		
	x_seat_top_bolt = Δx_seat_far_bolt_hole + Δx_seat
	
	x_seat_centerline = (girder_flange_width/2 - Δx_seat)/2 + Δx_seat

	y_seat_centerline = Δy_chord_seat_contact + h_seat

	x_seat_top_node = round(u"sinch_us", x_seat_top_bolt - (Δy_seat_top_bolt/tan(deg2rad(α_end_diagonal_tension))), sigdigits=4)

	y_seat_top_node = Δy_chord_seat_contact
	
	L_seat_compression_field, θ_seat_compression_field = calculate_diagonal_length_and_angle(x_seat_centerline, x_seat_top_node, y_seat_centerline, y_seat_top_node)
	
	return L_seat_compression_field, θ_seat_compression_field
	
end

function single_shear_bolt_strength(;d_bolt, t_ply, Fu_ply, Fn_bolt, design_code)
	
	
	Pn_bolt, ePn_bolt = AISIS10016.appAj341(Ab = π * (d_bolt/2)^2, Fn = Fn_bolt, design_code = design_code)
	
	C = AISIS10016.tablej3311(d=d_bolt, t=t_ply, hole_shape = "standard hole")
	
	mf = AISIS10016.tablej3312(connection_type="single shear", hole_shape="standard hole", washers="no")
	
	Pnb, ePnb = AISIS10016.j3311(C=C, mf=mf, d=d_bolt, t=t_ply, Fu=Fu_ply, design_code=design_code)
	
	ePn = minimum([ePn_bolt; ePnb])
	
	eRn = ePn 
	
	return eRn
	
end

function plate_buckling_stress(;k, E, ν, t, b)

	fcr = k*π^2*E/(12*(1-ν^2))*(t/b)^2
	
	return fcr
	
end

function bearing_seat_demands(; α, θ, R)
	
	A = [0. 0. 0. 1.0
		 1. -cos(α) 0. -cos(θ)
		 0. -sin(α) 0. sin(θ)
		 1.  0.  -1. 0.]
	
	B = [R/sin(θ) 0.0 0.0 0.0]'
	
	Q = A \ B
	
	return Q
	
end

function bearing_seat_reaction(Q, eRc, eRd, eRs, eRw)

	ePn_all = [eRc/Q[1], eRd/Q[2], eRs/Q[3], eRw/Q[4]]
	
	return ePn_all
	
end

function bearing_seat_strength_gravity(Δx_seat,  Δx_seat_far_bolt_hole, girder_flange_width, Δy_chord_seat_contact, h_seat, α_end_diagonal_tension, bolt_diameter, t_chord, Fu, Fnv, design_code, num_top_chord_bolts, t_end_tension_diagonal, L_seat_weld, Fu_support, t_seat_weld, Fxx_weld, E, ν, compression_field_width)

	L_seat_compression_field, θ_compression_field = calculate_compression_field_angle( Δx_seat,  Δx_seat_far_bolt_hole, girder_flange_width, Δy_chord_seat_contact, h_seat, α_end_diagonal_tension)
	
	eRc = single_shear_bolt_strength(d_bolt=bolt_diameter, t_ply=t_chord, Fu_ply=Fu, Fn_bolt=Fnv, design_code=design_code) * num_top_chord_bolts
	
	eRd = round(u"lbf", single_shear_bolt_strength(d_bolt=bolt_diameter, t_ply=minimum([t_seat, t_end_tension_diagonal]), Fu_ply=Fu, Fn_bolt=Fnv, design_code=design_code) * 4, sigdigits = 4)
	
	Rs, eRs = AISIS10016.j25(L=L_seat_weld, t1=t_seat, Fu1=Fu, t2=t_support, Fu2=Fu_support, tw=0.707*t_seat_weld, Fxx=Fxx_weld, loading_direction="longitudinal", design_code=design_code) .* 2
	
	fcrℓ = round(u"lbf/sinch_us/sinch_us", plate_buckling_stress(;k=4.0, E=E, ν=ν, t=t_seat, b=compression_field_width), sigdigits = 4)
	
	Rw, eRw = AISIS10016.e321(Pne = t_seat * compression_field_width * Fy, Pcrℓ = t_seat * compression_field_width * fcrℓ, design_code=design_code) .* 2
	
	Q = bearing_seat_demands(α=deg2rad(α_end_diagonal_tension), θ=deg2rad(θ_compression_field), R=1.0)
	
	ePn_seat_all = bearing_seat_reaction(Q, eRc, eRd, eRs, eRw)
	
	ePn_seat = round(u"lbf", minimum(ePn_seat_all), sigdigits = 4)
	
	return ePn_seat
	
end

function calculate_joist_load_diagonal_compression_limit_state(span_length, joist_end_length, α_diagonal, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_diagonal, Fy, E, L_diagonal, design_code, bolt_diameter, Fnv, t_chord, Fu, t_shield_plate; node_connection)

	q = 1.0u"lbf/sft_us"

	V = uconvert(u"lbf", q * span_length / 2 - (joist_end_length) * q)

	Pu = V/sin(deg2rad(α_diagonal))
	
	Pn_diagonal, ePn_diagonal = calculate_web_diagonal_compressive_strength(cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_diagonal, Fy, E, L_diagonal, design_code)

	eQn_diagonal = round(u"lbf/sft_us", ePn_diagonal/Pu*u"lbf/sft_us", sigdigits=3)

	if node_connection == "unreinforced"
	
		ePn_connection = unreinforced_truss_node_connection_strength(bolt_diameter, Fnv, t_chord, Fu, design_code)

	elseif node_connection == "reinforced"
		
		ePn_connection = reinforced_truss_node_connection_strength(bolt_diameter, Fnv, t_shield_plate, t_diagonal, Fu, design_code)

	end

	eQn_connection = round(u"lbf/sft_us", ePn_connection/Pu*u"lbf/sft_us", sigdigits=3)

	return eQn_diagonal, eQn_connection 

end

function calculate_joist_load_diagonal_tension_limit_state(span_length, x_top_chord_to_node, α_diagonal, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_diagonal, Fy, E, design_code, bolt_diameter, Fnv, t_chord, Fu, t_shield_plate; node_connection)

	q = 1.0u"lbf/sft_us"

	V = uconvert(u"lbf", q * span_length / 2 - (x_top_chord_to_node) * q)

	Pu = V/sin(deg2rad(α_diagonal))
	
	ePn_diagonal = calculate_web_diagonal_tensile_strength(cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_diagonal, Fy, Fu, bolt_hole_diameter, design_code)

	eQn_diagonal = round(u"lbf/sft_us", ePn_diagonal/Pu*u"lbf/sft_us", sigdigits=3)

	if node_connection=="unreinforced"
		
		ePn_connection = unreinforced_truss_node_connection_strength(bolt_diameter, Fnv, t_chord, Fu, design_code)

	elseif node_connection=="reinforced"

		ePn_connection = reinforced_truss_node_connection_strength(bolt_diameter, Fnv, t_shield_plate, t_diagonal, Fu, design_code)

	end
	
	eQn_connection = round(u"lbf/sft_us", ePn_connection/Pu*u"lbf/sft_us", sigdigits=3)

	return eQn_diagonal, eQn_connection 

end

function calculate_MIN_joist_shear_strength(span_length, joist_ends, α, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_compression_1, Fy, E, L, design_code, bolt_diameter, Fnv, t_chord, Fu, t_end_diagonal_compression_2, t_diagonal, t_end_diagonal_tension_1, t_end_diagonal_tension_2, t_shield_plate)


	eQn_end_diagonal_compression_1, eQn_connection_end_diagonal_compression_1 = calculate_joist_load_diagonal_compression_limit_state(span_length, joist_ends[1], α.C1, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_compression_1, Fy, E, L.C1, design_code, bolt_diameter, Fnv, t_chord, Fu, t_shield_plate, node_connection="unreinforced")

	eQn_end_diagonal_compression_2, eQn_connection_end_diagonal_compression_2 = calculate_joist_load_diagonal_compression_limit_state(span_length, joist_ends[2], α.C2, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_compression_2, Fy, E, L.C2, design_code, bolt_diameter, Fnv, t_chord, Fu, t_shield_plate, node_connection="unreinforced")

		x_top_chord_to_node_typical_diagonal = uconvert(u"sinch_us", node_spacing + joist_ends[2]) 
	
	eQn_typical_diagonal_compression, eQn_connection_typical_diagonal_compression = calculate_joist_load_diagonal_compression_limit_state(span_length, x_top_chord_to_node_typical_diagonal, α.typical, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_diagonal, Fy, E, L.typical, design_code, bolt_diameter, Fnv, t_chord, Fu, t_shield_plate, node_connection="unreinforced")

	x_top_chord_to_node_first_tension_diagonal = 0.0u"sinch_us"
	
	eQn_end_diagonal_tension_1, eQn_connection_end_diagonal_tension_1 = calculate_joist_load_diagonal_tension_limit_state(span_length, x_top_chord_to_node_first_tension_diagonal, α.T1, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_tension_1, Fy, E, design_code, bolt_diameter, Fnv, t_chord, Fu, t_shield_plate, node_connection="unreinforced")

	eQn_end_diagonal_tension_2, eQn_connection_end_diagonal_tension_2 = calculate_joist_load_diagonal_tension_limit_state(span_length, x_top_chord_to_node_first_tension_diagonal, α.T2, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_tension_2, Fy, E, design_code, bolt_diameter, Fnv, t_chord, Fu, t_shield_plate, node_connection="unreinforced")

	eQn_typical_diagonal_tension, eQn_connection_typical_diagonal_tension = calculate_joist_load_diagonal_tension_limit_state(span_length, x_top_chord_to_node_typical_diagonal, α.typical, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_diagonal, Fy, E, design_code, bolt_diameter, Fnv, t_chord, Fu, t_shield_plate, node_connection="unreinforced")

	diagonal_eQn = [eQn_end_diagonal_compression_1; eQn_end_diagonal_compression_2; eQn_typical_diagonal_compression; eQn_end_diagonal_tension_1; eQn_end_diagonal_tension_2;eQn_typical_diagonal_tension]

	connection_eQn = [eQn_connection_end_diagonal_compression_1; eQn_connection_end_diagonal_compression_2; eQn_connection_typical_diagonal_compression; eQn_connection_end_diagonal_tension_1; eQn_connection_end_diagonal_tension_2;eQn_connection_typical_diagonal_tension]

	eQnV = minimum([diagonal_eQn; connection_eQn])	
		
	return eQnV
		
		
end

function calculate_MAX_joist_shear_strength(span_length, joist_ends, α, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_compression_1, Fy, E, L, design_code, bolt_diameter, Fnv, t_chord, Fu, t_end_diagonal_compression_2, t_diagonal, t_end_diagonal_tension_1, t_end_diagonal_tension_2, t_shield_plate)


	eQn_end_diagonal_compression_1, eQn_connection_end_diagonal_compression_1 = calculate_joist_load_diagonal_compression_limit_state(span_length, joist_ends[1], α.C1, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_compression_1, Fy, E, L.C1/2, design_code, bolt_diameter, Fnv, t_chord, Fu, t_shield_plate, node_connection="reinforced")

	eQn_end_diagonal_compression_2, eQn_connection_end_diagonal_compression_2 = calculate_joist_load_diagonal_compression_limit_state(span_length, joist_ends[2], α.C2, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_compression_2, Fy, E, L.C2/2, design_code, bolt_diameter, Fnv, t_chord, Fu, t_shield_plate, node_connection="reinforced")

		x_top_chord_to_node_typical_diagonal = uconvert(u"sinch_us", node_spacing + joist_ends[2]) 
	
	eQn_typical_diagonal_compression, eQn_connection_typical_diagonal_compression = calculate_joist_load_diagonal_compression_limit_state(span_length, x_top_chord_to_node_typical_diagonal, α.typical, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_diagonal, Fy, E, L.typical/2, design_code, bolt_diameter, Fnv, t_chord, Fu, t_shield_plate, node_connection="reinforced")

	x_top_chord_to_node_first_tension_diagonal = 0.0u"sinch_us"
	
	eQn_end_diagonal_tension_1, eQn_connection_end_diagonal_tension_1 = calculate_joist_load_diagonal_tension_limit_state(span_length, x_top_chord_to_node_first_tension_diagonal, α.T1, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_tension_1, Fy, E, design_code, bolt_diameter, Fnv, t_chord, Fu, t_shield_plate, node_connection="reinforced")

	eQn_end_diagonal_tension_2, eQn_connection_end_diagonal_tension_2 = calculate_joist_load_diagonal_tension_limit_state(span_length, x_top_chord_to_node_first_tension_diagonal, α.T2, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_tension_2, Fy, E, design_code, bolt_diameter, Fnv, t_chord, Fu, t_shield_plate, node_connection="reinforced")

	eQn_typical_diagonal_tension, eQn_connection_typical_diagonal_tension = calculate_joist_load_diagonal_tension_limit_state(span_length, x_top_chord_to_node_typical_diagonal, α.typical, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_diagonal, Fy, E, design_code, bolt_diameter, Fnv, t_chord, Fu, t_shield_plate, node_connection="reinforced")

	diagonal_eQn = [eQn_end_diagonal_compression_1; eQn_end_diagonal_compression_2; eQn_typical_diagonal_compression; eQn_end_diagonal_tension_1; eQn_end_diagonal_tension_2;eQn_typical_diagonal_tension]

	connection_eQn = [eQn_connection_end_diagonal_compression_1; eQn_connection_end_diagonal_compression_2; eQn_connection_typical_diagonal_compression; eQn_connection_end_diagonal_tension_1; eQn_connection_end_diagonal_tension_2;eQn_connection_typical_diagonal_tension]

	eQnV = minimum([diagonal_eQn; connection_eQn])	
		
	return eQnV
		
		
end


function joist_moment_strength(span_length, truss_depth, ycg_chord, eTn_chord, ePnℓ_chord)
		
	q=1.0u"lbf/sft_us"

	M_unit = q * span_length^2 / 8

	moment_arm = truss_depth - 2 * ycg_chord

	Pu_chord = round(u"lbf", uconvert(u"lbf", M_unit / moment_arm), sigdigits = 3)

	eQn_chord_compression = round(u"lbf/sft_us", ePnℓ_chord/Pu_chord*u"lbf/sft_us", sigdigits=3)

	eQn_chord_tension = round(u"lbf/sft_us", eTn_chord/Pu_chord*u"lbf/sft_us", sigdigits=3)

	eQnM_chord_limit_states = [eQn_chord_compression; eQn_chord_tension]

	eQnM = minimum(eQnM_chord_limit_states)

	return eQnM
		
end

function joist_moment_strength(span_length, truss_depth, ycg_chord, eTn_chord, ePnℓ_chord)
		
	q=1.0u"lbf/sft_us"

	M_unit = q * span_length^2 / 8

	moment_arm = truss_depth - 2 * ycg_chord

	Pu_chord = round(u"lbf", uconvert(u"lbf", M_unit / moment_arm), sigdigits = 3)

	eQn_chord_compression = round(u"lbf/sft_us", ePnℓ_chord/Pu_chord*u"lbf/sft_us", sigdigits=3)

	eQn_chord_tension = round(u"lbf/sft_us", eTn_chord/Pu_chord*u"lbf/sft_us", sigdigits=3)

	eQnM_chord_limit_states = [eQn_chord_compression; eQn_chord_tension]

	eQnM = minimum(eQnM_chord_limit_states)

	return eQnM
		
end

function joist_moment_strength(span_length, truss_depth, ycg_chord, eTn_chord, ePnℓ_chord)
		
	q=1.0u"lbf/sft_us"

	M_unit = q * span_length^2 / 8

	moment_arm = truss_depth - 2 * ycg_chord

	Pu_chord = round(u"lbf", uconvert(u"lbf", M_unit / moment_arm), sigdigits = 3)

	eQn_chord_compression = round(u"lbf/sft_us", ePnℓ_chord/Pu_chord*u"lbf/sft_us", sigdigits=3)

	eQn_chord_tension = round(u"lbf/sft_us", eTn_chord/Pu_chord*u"lbf/sft_us", sigdigits=3)

	eQnM_chord_limit_states = [eQn_chord_compression; eQn_chord_tension]

	eQnM = minimum(eQnM_chord_limit_states)

	return eQnM
		
end

function calculate_joist_load_limit(span_length, node_spacing, Δx_bearing_seat_chord_holes, Δy_chord_to_hole, Δx_node_to_hole, Δx_seat_far_bolt_hole, Δx_seat_near_bolt_hole, x_support_to_bottom_chord, Δy_chord_seat_contact, Δy_seat_top_bolt, joist_depth, cross_section_segments_diagonal,	cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_compression_1, Fy, E,design_code,bolt_diameter,Fnv,t_chord,Fu,	t_end_diagonal_compression_2, t_diagonal, t_end_diagonal_tension_1,	t_end_diagonal_tension_2,ycg_chord, eTn_chord, ePnℓ_chord, girder_flange_width, h_seat,num_top_chord_bolts_1, L_seat_weld, Fu_support,t_seat_weld, Fxx_weld,ν,	compression_field_width,num_top_chord_bolts_2, A_chord,p_self, p_DL, joist_spacing, t_shield_plate; JIT_configuration)
	
		
	joist_ends = define_joist_ends(span_length, node_spacing)

	Δx_chord_hole_from_joist_end_1 = define_first_chord_hole_location(joist_end_length=joist_ends[1])

	Δx_chord_hole_from_joist_end_2 = define_first_chord_hole_location(joist_end_length=joist_ends[2])

	Δx_seat_1 = calculate_bearing_seat_offset(joist_ends[1], Δx_chord_hole_from_joist_end_1, Δx_bearing_seat_chord_holes)

	Δx_seat_2 = calculate_bearing_seat_offset(joist_ends[2], Δx_chord_hole_from_joist_end_2, Δx_bearing_seat_chord_holes)

	L, α = calculate_joist_diagonal_geometry(joist_ends, Δx_chord_hole_from_joist_end_1, Δx_chord_hole_from_joist_end_2, Δx_seat_1, Δx_seat_2, node_spacing, Δy_chord_to_hole, Δx_node_to_hole, joist_spacing, Δx_seat_far_bolt_hole, Δx_seat_near_bolt_hole, x_support_to_bottom_chord, Δy_chord_seat_contact, Δy_seat_top_bolt, Δx_bearing_seat_chord_holes, joist_depth)

	if JIT_configuration == "MIN"

		eQnV = calculate_MIN_joist_shear_strength(span_length, joist_ends, α, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_compression_1, Fy, E, L, design_code, bolt_diameter, Fnv, t_chord, Fu, t_end_diagonal_compression_2, t_diagonal, t_end_diagonal_tension_1, t_end_diagonal_tension_2, t_shield_plate)

	elseif JIT_configuration == "MAX"

		eQnV = calculate_MAX_joist_shear_strength(span_length, joist_ends, α, cross_section_segments_diagonal, cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_compression_1, Fy, E, L, design_code, bolt_diameter, Fnv, t_chord, Fu, t_end_diagonal_compression_2, t_diagonal, t_end_diagonal_tension_1, t_end_diagonal_tension_2, t_shield_plate)

	end
		

	eQnM = joist_moment_strength(span_length, joist_depth, ycg_chord, eTn_chord, ePnℓ_chord)

	eQnBS = joist_bearing_seat_strength(Δx_seat_1,  Δx_seat_far_bolt_hole, girder_flange_width, Δy_chord_seat_contact, h_seat, α, bolt_diameter, t_chord, Fu, Fnv, design_code, num_top_chord_bolts_1, t_end_tension_diagonal_1, L_seat_weld, Fu_support, t_seat_weld, Fxx_weld, E, ν, compression_field_width, Δx_seat_2, num_top_chord_bolts_2, t_end_tension_diagonal_2, span_length)

	eQnΔ = joist_deflection_load_limit(A_chord, joist_depth, ycg_chord, span_length, E)

	joist_load_limit_states = [eQnV; eQnM; eQnBS; eQnΔ]

	eQn = minimum(joist_load_limit_states) - (p_self + p_DL) * joist_spacing

	return eQn

end

function generate_span_chart_column(span_length_range, node_spacing, Δx_bearing_seat_chord_holes, Δy_chord_to_hole, Δx_node_to_hole, Δx_seat_far_bolt_hole, Δx_seat_near_bolt_hole, x_support_to_bottom_chord, Δy_chord_seat_contact, Δy_seat_top_bolt, joist_depth, cross_section_segments_diagonal,	cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_compression_1, Fy, E,design_code,bolt_diameter,Fnv,t_chord,Fu,	t_end_diagonal_compression_2, t_diagonal, t_end_diagonal_tension_1,	t_end_diagonal_tension_2,ycg_chord, eTn_chord, ePnℓ_chord, girder_flange_width, h_seat,num_top_chord_bolts_1, L_seat_weld, Fu_support,t_seat_weld, Fxx_weld,ν,	compression_field_width,num_top_chord_bolts_2, A_chord, p_self, p_DL, joist_spacing, t_shield_plate; JIT_configuration)

	eQn_chart = []
		
	for i = 1:length(span_length_range)

		if i==1

			eQn_chart = calculate_joist_load_limit(span_length_range[i], node_spacing, Δx_bearing_seat_chord_holes, Δy_chord_to_hole, Δx_node_to_hole, Δx_seat_far_bolt_hole, Δx_seat_near_bolt_hole, x_support_to_bottom_chord, Δy_chord_seat_contact, Δy_seat_top_bolt, joist_depth, cross_section_segments_diagonal,	cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_compression_1, Fy, E,design_code,bolt_diameter,Fnv,t_chord,Fu,	t_end_diagonal_compression_2, t_diagonal, t_end_diagonal_tension_1,	t_end_diagonal_tension_2,ycg_chord, eTn_chord, ePnℓ_chord, girder_flange_width, h_seat,num_top_chord_bolts_1, L_seat_weld, Fu_support,t_seat_weld, Fxx_weld,ν,	compression_field_width,num_top_chord_bolts_2, A_chord, p_self, p_DL, joist_spacing, t_shield_plate, JIT_configuration=JIT_configuration)

		else

			eQn_chart_next = calculate_joist_load_limit(span_length_range[i], node_spacing, Δx_bearing_seat_chord_holes, Δy_chord_to_hole, Δx_node_to_hole, Δx_seat_far_bolt_hole, Δx_seat_near_bolt_hole, x_support_to_bottom_chord, Δy_chord_seat_contact, Δy_seat_top_bolt, joist_depth, cross_section_segments_diagonal,	cross_section_segment_angles_diagonal, n_diagonal, radius_diagonal, n_radius_diagonal, t_end_diagonal_compression_1, Fy, E,design_code,bolt_diameter,Fnv,t_chord,Fu,	t_end_diagonal_compression_2, t_diagonal, t_end_diagonal_tension_1,	t_end_diagonal_tension_2,ycg_chord, eTn_chord, ePnℓ_chord, girder_flange_width, h_seat,num_top_chord_bolts_1, L_seat_weld, Fu_support,t_seat_weld, Fxx_weld,ν,	compression_field_width,num_top_chord_bolts_2, A_chord,p_self, p_DL, joist_spacing, t_shield_plate, JIT_configuration=JIT_configuration)

		eQn_chart = [eQn_chart; eQn_chart_next]

		end
			
	end

	return eQn_chart
	
end



end # module
