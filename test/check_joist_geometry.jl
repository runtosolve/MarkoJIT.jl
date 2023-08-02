using MarkoJIT, DataFrames, CSV 


span_length = 30.0 * 12.0;
 
joist = MarkoJIT.Geometry.JoistDimensions(span_length = span_length, depth = 35.44, node_spacing = 48.0, x_support_to_bottom_chord = 24.0);


 #chord cross section
 file = "/Users/crismoen/.julia/dev/MarkoJIT/assets/chord_centerline_cross_section_coordinates.csv"
 chord_cross_section = CSV.read(file, DataFrame)

# bearing seat dimensions
bearing_seat = MarkoJIT.Geometry.BearingSeatDimensions(t=0.078, flange_hole_center_locations = (Δx = [20.0/25.4, 45.0/25.4, 70.0/25.4], Δy = [-0.078/2, -0.078/2, -0.078/2], Δz = [0.0, 0.0, 0.0]), web_hole_center_locations = (Δx = [54.5/25.4, 104.5/25.4], Δy = [-28.0/25.4, -28.0/25.4], Δz = [24.7/25.4 - 0.078/2, 24.7/25.4 - 0.078/2]), height =99.0/25.4, num_webs=2);

# chord 
chord = MarkoJIT.Geometry.ChordDimensions(t=0.061, centerline_cross_section_coordinates = [(chord_cross_section.X[i], chord_cross_section.Y[i]) for i in eachindex(chord_cross_section.X)], tab_hole_center_location = (Δx=56.0/25.4/2, Δy=2.48, Δz=1.73/2 + 0.061/2), seat_contact_depth = 2.31, flange_punchout_width=1.734);




#joist diagonals 
diagonal_coordinates = Geometry.calculate_joist_diagonal_coordinates(joist.span_length, joist.depth, joist.x_support_to_bottom_chord, joist.node_spacing, bearing_seat, chord)

