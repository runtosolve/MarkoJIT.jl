using MarkoJIT, Unitful, CrossSection, GLMakie


#define joist dimensions 
span_length = 50.0u"ft" |> u"inch"
joist_depth = 35.44u"inch"

diagonal_nodes = MarkoJIT.define_diagonal_geometries(span_length, joist_depth)

x1 = [diagonal_nodes[i].top_node[1] for i in eachindex(diagonal_nodes)]
y1 = [diagonal_nodes[i].top_node[2] for i in eachindex(diagonal_nodes)]
x2 = [diagonal_nodes[i].bottom_node[1] for i in eachindex(diagonal_nodes)]
y2 = [diagonal_nodes[i].bottom_node[2] for i in eachindex(diagonal_nodes)]


MarkoJIT.calculate_diagonal_length_and_angle(x1[1], x2[1], y1[1], y2[1])


#calculate diagonal section properties 
t = 0.061u"inch"
L = [(1.0+11/64)u"inch", (1.0+23/32)u"inch", (1.0+11/64)u"inch"]
θ = [π/2, 0, -π/2]
n = [4, 4, 4]
r = [(1/8)u"inch", (1/8)u"inch"]
n_r = [4, 4, 4]


#bring in top projection
cross_section = Geometry.generate_thin_walled(L, θ, n, r, n_r)

#calculate surface normals
unit_node_normals = Geometry.calculate_cross_section_unit_node_normals(cross_section)


geometry, sect_props = CrossSection.Properties.open_thin_walled(L, θ, r, n, n_r, t, centerline = "to right")

# geometry, member = CrossSection.Properties.open_thin_walled(ustrip(L), θ, ustrip(r), n, n_r, ustrip(t))


function plot_open_thin_walled_cross_section(geometry)
	f = Figure()
	    ax = GLMakie.Axis(f[1, 1])
	
	    lines!(ax, [ustrip(geometry.center[i][1]) for i in eachindex(geometry.center)], [ustrip(geometry.center[i][2]) for i in eachindex(geometry.center)], color=:grey, linestyle=:dash)
	    lines!(ax, [ustrip(geometry.left[i][1]) for i in eachindex(geometry.left)], [ustrip(geometry.left[i][2]) for i in eachindex(geometry.left)], color=:red)
	    lines!(ax, [ustrip(geometry.right[i][1]) for i in eachindex(geometry.right)], [ustrip(geometry.right[i][2]) for i in eachindex(geometry.right)], color=:blue)
	    ax.autolimitaspect = 1
	f
end


plot_open_thin_walled_cross_section(geometry)

y = [geometry.left[i][2] for i in eachindex(geometry.left)]

x = [geometry.left[i][1] for i in eachindex(geometry.left)]

maximum(y)
1.0+11/64

maximum(x)
1.0+23/32

# function calculate_web_diagonal_compressive_strength(ΔL, Θ, n, radius, n_radius, t, Fy, E, L_unbraced, design_code)

# function calculate_web_diagonal_compressive_strength(A, fy, L_u, )


# 	geometry, sect_props = CrossSection.Properties.open_thin_walled(L, θ, r, n, n_r, t, centerline = "to right")

# 	A_diagonal = round(u"inch^2", web_diagonal_section_properties.A*1.0*u"inch^2", sigdigits=3)
		
# 	Py_diagonal = round(u"lbf", A_diagonal * Fy, sigdigits=4)
		
# 	Fcre_diagonal = round(u"lbf/inch^2", calculate_column_critical_elastic_global_buckling_stress(;E=E, I=web_diagonal_section_properties.Ixx*u"inch^4", L=L_unbraced, A=A_diagonal), sigdigits=4)
		
# 	Pne_diagonal, ePne_diagonal = round.(u"lbf", AISIS10016.e2(Fcre=Fcre_diagonal, Fy=Fy, Ag=A_diagonal, design_code=design_code), sigdigits=4)
		
# 	#no local buckling influence
# 	Pnℓ_diagonal = Pne_diagonal
# 	ePnℓ_diagonal = ePne_diagonal
	
# 	return  Pnℓ_diagonal, ePnℓ_diagonal



# 	coords_out, coords_centerline, coords_in = calculate_cross_section_coordinates(ΔL=ΔL, Θ=Θ, n=n, radius=radius, n_radius=n_radius, t=t)
		
# 	element_info = define_cross_section_element_connectivity(num_elem=length(coords_out[1])-1, t=t)
	
# 	web_diagonal_section_properties = CUFSM.cutwp_prop2([ustrip(coords_centerline[1]) ustrip(coords_centerline[2])], ustrip.(element_info))
	
# 	A_diagonal = round(u"inch^2", web_diagonal_section_properties.A*1.0*u"inch^2", sigdigits=3)
		
# 	Py_diagonal = round(u"lbf", A_diagonal * Fy, sigdigits=4)
		
# 	Fcre_diagonal = round(u"lbf/inch^2", calculate_column_critical_elastic_global_buckling_stress(;E=E, I=web_diagonal_section_properties.Ixx*u"inch^4", L=L_unbraced, A=A_diagonal), sigdigits=4)
		
# 	Pne_diagonal, ePne_diagonal = round.(u"lbf", AISIS10016.e2(Fcre=Fcre_diagonal, Fy=Fy, Ag=A_diagonal, design_code=design_code), sigdigits=4)
		
# 	#no local buckling influence
# 	Pnℓ_diagonal = Pne_diagonal
# 	ePnℓ_diagonal = ePne_diagonal
	
# 	return  Pnℓ_diagonal, ePnℓ_diagonal
		
# end


