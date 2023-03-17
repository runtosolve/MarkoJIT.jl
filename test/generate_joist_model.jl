using MarkoJIT, CSV, DataFrames, InstantFrame, CrossSection, AISIS100, CUFSM, Unitful, InstantFrame


######inputs

design_code = "AISI S100-16 ASD"

#joist dimensions 
joist_dimensions = MarkoJIT.Geometry.JoistDimensions(span_length = 50.0*12, depth = 35.44, node_spacing = 48.0, x_support_to_bottom_chord = 24.0)

#chord cross section
file = "/Users/crismoen/.julia/dev/MarkoJIT/assets/chord_centerline_cross_section_coordinates.csv"
chord_cross_section = CSV.read(file, DataFrame)

chord_dimensions = MarkoJIT.Geometry.ChordDimensions(t=0.061, centerline_cross_section_coordinates = [(chord_cross_section.X[i], chord_cross_section.Y[i]) for i in eachindex(chord_cross_section.X)], tab_hole_center_location = (Δx=56.0/25.4/2, Δy=2.48, Δz=1.73/2 + 0.061/2), seat_contact_depth = 2.31, flange_punchout_width=1.734)

#diagonal cross sections
diagonal_dimensions = MarkoJIT.Geometry.DiagonalDimensions(name=["16 gauge diagonal", "14 gauge diagonal", "12 gauge diagonal"], t=[0.061, 0.078, 0.105], B=fill((1 + 11/64), 3), H = fill((1 + 23/32), 3), R=fill((1/8 + 5/64), 3))

#bolt properties and dimensions 
bolt_properties = (name = "ASTM A307", diameter=0.375, hole_diameter=0.394, Fnv=24.0)

#shield plate dimensions
shield_plate_dimensions = (t=0.061, slotted_hole_edge_distance=0.59)

#assign diagonal sections
num_diagonals = MarkoJIT.Geometry.calculate_number_of_joist_diagonals(joist_dimensions.span_length, joist_dimensions.node_spacing)

diagonal_sections = [["14 gauge diagonal", "14 gauge diagonal"]; fill("14 gauge diagonal", num_diagonals - 4); ["14 gauge diagonal", "14 gauge diagonal"]]

#define diagonal bracing
diagonal_bracing = [["braced", "braced"]; fill("braced", num_diagonals - 4); ["braced", "braced"]]

#bearing seat dimensions
bearing_seat_dimensions = MarkoJIT.Geometry.BearingSeatDimensions(t=0.078, flange_hole_center_locations = (Δx = [20.0/25.4, 45.0/25.4, 70.0/25.4], Δy = [-0.078/2, -0.078/2, -0.078/2], Δz = [0.0, 0.0, 0.0]), web_hole_center_locations = (Δx = [54.5/25.4, 104.5/25.4], Δy = [-28.0/25.4, -28.0/25.4], Δz = [24.7/25.4 - 0.078/2, 24.7/25.4 - 0.078/2]), height =99.0/25.4, num_webs=2)

#chord splice dimensions 
chord_splice_dimensions = (t=0.105, B=24.6/25.4, H = 43.6/25.4, R=(3.0+2.7)/25.4)

#girder dimensions 
girder_dimensions = MarkoJIT.Geometry.Girder(top_flange_width = 8.0, top_flange_thickness = 1.0)

#girder material properties 
girder_material_properties = (fy=36.0, fu=52.0)

#bearing seat weld info
bearing_seat_weld_properties = (length=2.5, Fxx=60.0, t=1/8, num_lines=2)

#joist material properties 
joist_material_properties = MarkoJIT.Properties.JoistMaterial(fy=37.0, fu=52.0, E=29500.0, ν=0.30)

#define top chord connection types 
top_chord_connections = ["bearing seat"; fill("reinforced connection", num_diagonals-2); "bearing seat"]

#define bottom chord connection types 
bottom_chord_connections = ["bearing seat"; fill("reinforced connection", num_diagonals-2); "bearing seat"]

# using Serialization 
# serialize("/Users/crismoen/.julia/dev/MarkoJIT/assets/chord_local_buckling_properties", joist_span.strength.chord_compressive_strength.local_buckling_properties)
# serialize("/Users/crismoen/.julia/dev/MarkoJIT/assets/chord_Pcrl", joist_span.strength.chord_compressive_strength.Pcrℓ)
# serialize("/Users/crismoen/.julia/dev/MarkoJIT/assets/chord_distortional_buckling_properties", joist_span.strength.chord_compressive_strength.distortional_buckling_properties)
# serialize("/Users/crismoen/.julia/dev/MarkoJIT/assets/chord_Pcrd", joist_span.strength.chord_compressive_strength.Pcrd)


span_lengths = range(40.0*12, 70*12, 16)

joist_spans = Vector{MarkoJIT.JoistSpan}(undef, length(span_lengths))

for i in eachindex(joist_spans)

    design_code = "AISI S100-16 ASD"

    #joist dimensions 
    joist_dimensions = MarkoJIT.Geometry.JoistDimensions(span_length = span_lengths[i], depth = 35.44, node_spacing = 48.0, x_support_to_bottom_chord = 24.0)

    #chord cross section
    file = "/Users/crismoen/.julia/dev/MarkoJIT/assets/chord_centerline_cross_section_coordinates.csv"
    chord_cross_section = CSV.read(file, DataFrame)

    chord_dimensions = MarkoJIT.Geometry.ChordDimensions(t=0.061, centerline_cross_section_coordinates = [(chord_cross_section.X[i], chord_cross_section.Y[i]) for i in eachindex(chord_cross_section.X)], tab_hole_center_location = (Δx=56.0/25.4/2, Δy=2.48, Δz=1.73/2 + 0.061/2), seat_contact_depth = 2.31, flange_punchout_width=1.734)

    #diagonal cross sections
    diagonal_dimensions = MarkoJIT.Geometry.DiagonalDimensions(name=["16 gauge diagonal", "14 gauge diagonal", "12 gauge diagonal"], t=[0.061, 0.078, 0.105], B=fill((1 + 11/64), 3), H = fill((1 + 23/32), 3), R=fill((1/8 + 5/64), 3))

    #bolt properties and dimensions 
    bolt_properties = (name = "ASTM A307", diameter=0.375, hole_diameter=0.394, Fnv=24.0)

    #shield plate dimensions
    shield_plate_dimensions = (t=0.061, slotted_hole_edge_distance=0.59)

    #assign diagonal sections
    num_diagonals = MarkoJIT.Geometry.calculate_number_of_joist_diagonals(joist_dimensions.span_length, joist_dimensions.node_spacing)

    diagonal_sections = [["14 gauge diagonal", "14 gauge diagonal"]; fill("14 gauge diagonal", num_diagonals - 4); ["14 gauge diagonal", "14 gauge diagonal"]]

    #define diagonal bracing
    diagonal_bracing = [["braced", "braced"]; fill("braced", num_diagonals - 4); ["braced", "braced"]]

    #bearing seat dimensions
    bearing_seat_dimensions = MarkoJIT.Geometry.BearingSeatDimensions(t=0.078, flange_hole_center_locations = (Δx = [20.0/25.4, 45.0/25.4, 70.0/25.4], Δy = [-0.078/2, -0.078/2, -0.078/2], Δz = [0.0, 0.0, 0.0]), web_hole_center_locations = (Δx = [54.5/25.4, 104.5/25.4], Δy = [-28.0/25.4, -28.0/25.4], Δz = [24.7/25.4 - 0.078/2, 24.7/25.4 - 0.078/2]), height =99.0/25.4, num_webs=2)

    #chord splice dimensions 
    chord_splice_dimensions = (t=0.105, B=24.6/25.4, H = 43.6/25.4, R=(3.0+2.7)/25.4)

    #girder dimensions 
    girder_dimensions = MarkoJIT.Geometry.Girder(top_flange_width = 8.0, top_flange_thickness = 1.0)

    #girder material properties 
    girder_material_properties = (fy=36.0, fu=52.0)

    #bearing seat weld info
    bearing_seat_weld_properties = (length=2.5, Fxx=60.0, t=1/8, num_lines=2)

    #joist material properties 
    joist_material_properties = MarkoJIT.Properties.JoistMaterial(fy=37.0, fu=52.0, E=29500.0, ν=0.30)

    #define top chord connection types 
    top_chord_connections = ["bearing seat"; fill("reinforced connection", num_diagonals-2); "bearing seat"]

    #define bottom chord connection types 
    bottom_chord_connections = ["bearing seat"; fill("reinforced connection", num_diagonals-2); "bearing seat"]

    joist_spans[i] = MarkoJIT.evaluate_joist_span(design_code, joist_dimensions, chord_dimensions, diagonal_dimensions, bolt_properties, shield_plate_dimensions, diagonal_sections, diagonal_bracing, bearing_seat_dimensions, chord_splice_dimensions,  girder_dimensions, girder_material_properties, bearing_seat_weld_properties, joist_material_properties, top_chord_connections, bottom_chord_connections)

end


span_table = DataFrame()

span_table.A = span_lengths/12.0

span_table.B = [joist_spans[i].design_load for i in eachindex(span_lengths)]

span_table.C = [joist_spans[i].demand_to_capacity.controlling for i in eachindex(span_lengths)]

span_table.D = [joist_spans[i].demand_to_capacity.failure_location for i in eachindex(span_lengths)]

rename!(span_table, :A => :span_length);
rename!(span_table, :B => :JIT_36_MAX);
rename!(span_table, :C => :limit_state);
rename!(span_table, :D => :failure_location);




###Visualization 

model=joist_spans[end].model

element_nodal_coords = InstantFrame.Show.define_element_nodal_start_end_coordinates(model.inputs.element, model.inputs.node)

X, Y, Z = InstantFrame.Show.get_node_XYZ(model.inputs.node)

# plot(node.coordinates, markershape = :o, seriestype = :scatter)

X_range = abs(maximum(X) - minimum(X))
Y_range = abs(maximum(Y) - minimum(Y))
Z_range = abs(maximum(Z) - minimum(Z))


using GLMakie, LinearAlgebra
figure = Figure()
ax = Axis3(figure[1,1])
ax.aspect = (1.0, Y_range/X_range, Z_range/X_range)
# ax.yticks = WilkinsonTicks(2)
# ax.azimuth = π/4
# ax.elevation = 0.0
figure
# GLMakie.ylims!(ax, 0.0, 50.0)

color = :gray
InstantFrame.Show.elements!(ax, element_nodal_coords, color)
figure

markersize = 10
color = :blue
InstantFrame.Show.nodes!(ax, X, Y, Z, markersize, color)
figure

# unit_arrow_head_size = [1.0, 1.0, 1.0]
# arrow_head_scale = 10.0
# arrow_scale = 50.0
# arrowcolor = :red 
# linecolor = :red 
# linewidth = 2
# InstantFrame.UI.show_point_loads!(ax, point_load, node, arrow_scale, arrow_head_scale, unit_arrow_head_size, arrowcolor, linecolor, linewidth)
# figure


# unit_arrow_head_size = [1.0, 1.0, 1.0]
# arrow_head_scale = 5.0
# arrow_scale = 20.0
# linewidth = 2
# arrowcolor = :green 
# linecolor = :green
# InstantFrame.Show.uniform_loads!(ax, uniform_load, element, node, unit_arrow_head_size, arrow_head_scale, arrow_scale, linewidth, arrowcolor, linecolor)
# figure 



####Visualize 


# unit_arrow_head_size = [1.0, 1.0, 1.0]
# arrow_head_scale = 5.0
# arrow_scale = 6.0
# arrowcolor = :orange 
# linecolor = :orange 
# linewidth = 1

# InstantFrame.Show.element_local_axes!(ax, element, node, model, unit_arrow_head_size, arrow_head_scale, arrow_scale, arrowcolor, linecolor, linewidth)
# figure



textsize = 10
color = :darkred
InstantFrame.Show.element_numbers!(ax, model.inputs.element, model.inputs.node, textsize, color)
figure

textsize = 10
color = :green
InstantFrame.Show.node_numbers!(ax, model.inputs.node, textsize, color)
figure


n= fill(5, length(element.numbers))
scale = (1, 1, 1)
linecolor = :brown
InstantFrame.Show.deformed_shape!(ax, model.solution.displacements, model.properties.global_dof, element, node, model.properties, model.solution.connections, n, scale, linecolor)

