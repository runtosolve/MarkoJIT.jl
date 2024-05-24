module Show

using InstantFrame, CairoMakie

function joist_geometry(joist_span, drawing_scale)

    
    element = joist_span.model.inputs.element;
    node = joist_span.model.inputs.node;
    element_nodal_coords = InstantFrame.PlotTools.define_element_nodal_start_end_coordinates(element, node);
    Xij, Yij, Zij = InstantFrame.PlotTools.get_XYZ_element_ij(element_nodal_coords);
    X, Y, Z = InstantFrame.PlotTools.get_node_XYZ(node);
    
    Δx = joist_span.inputs.joist_dimensions.span_length;
    Δy = joist_span.inputs.joist_dimensions.depth;
    num_diagonal_elements = length(findall(section->occursin("diagonal", section), joist_span.model.inputs.element.cross_section));
    num_chord_elements = length(findall(section->occursin("chord", section), joist_span.model.inputs.element.cross_section));
    num_rigid_elements = length(findall(section->occursin("rigid", section), joist_span.model.inputs.element.cross_section));
    num_bearing_seat_elements = length(findall(section->occursin("top of girder", section), joist_span.model.inputs.element.cross_section));
    member_width = [fill(joist_span.inputs.diagonal_dimensions.B[1], num_diagonal_elements); fill(2.36, num_chord_elements); fill(1.0, num_bearing_seat_elements); fill(1.0, num_rigid_elements)];
    
    padding_x = 0.0;
    padding_y = 6.0;
   
    figure = Figure();
    ax = Axis(figure[1, 1], width = (Δx+2*padding_x) * 72 * drawing_scale, height = (Δy+2*padding_y) * 72 * drawing_scale);
    xlims!(0.0 - padding_x, joist_span.inputs.joist_dimensions.span_length + padding_x);
    ylims!(-joist_span.inputs.joist_dimensions.depth - padding_y, 0.0 + padding_y);
    hidedecorations!(ax);
    hidespines!(ax);  
    width_scale = maximum(member_width) * 72 * drawing_scale;
    linewidths = member_width ./ maximum(member_width) * width_scale;
   
    attributes = (color=:grey, linewidth=linewidths);
    InstantFrame.Show.elements!(ax, Xij, Yij, attributes);
    resize_to_layout!(figure);

    # add splices 
    scatter!(ax, joist_span.inputs.chord_splice_locations.top, zeros(length(joist_span.inputs.chord_splice_locations.top)), color=:red);

    scatter!(ax, joist_span.inputs.chord_splice_locations.bottom, ones(length(joist_span.inputs.chord_splice_locations.top)) .* -joist_span.inputs.joist_dimensions.depth,color=:red);

    resize_to_layout!(figure);

    #add nodes 
    attributes = (size = 3, color = :blue);
    InstantFrame.Show.nodes!(ax, X, Y, attributes);

    return ax, figure

end


function joist_internal_forces(joist_span, drawing_scale)

    element = joist_span.model.inputs.element;
    node = joist_span.model.inputs.node;
    element_nodal_coords = InstantFrame.PlotTools.define_element_nodal_start_end_coordinates(element, node);
    Xij, Yij, Zij = InstantFrame.PlotTools.get_XYZ_element_ij(element_nodal_coords);
    X, Y, Z = InstantFrame.PlotTools.get_node_XYZ(node);

    Δx = joist_span.inputs.joist_dimensions.span_length;
    Δy = joist_span.inputs.joist_dimensions.depth;
    num_diagonal_elements = length(findall(section->occursin("diagonal", section), joist_span.model.inputs.element.cross_section));
    num_chord_elements = length(findall(section->occursin("chord", section), joist_span.model.inputs.element.cross_section));
    num_rigid_elements = length(findall(section->occursin("rigid", section), joist_span.model.inputs.element.cross_section));
    num_bearing_seat_elements = length(findall(section->occursin("top of girder", section), joist_span.model.inputs.element.cross_section));
    member_width = [fill(joist_span.inputs.diagonal_dimensions.B[1], num_diagonal_elements); fill(2.36, num_chord_elements); fill(1.0, num_bearing_seat_elements); fill(1.0, num_rigid_elements)];

    #+ echo=false
    padding_x = 8.0;
    padding_y = 6.0;
    # figure = Figure(resolution = (Δx*72, Δy*72) .* drawing_scale)
    figure = Figure();
    ax = Axis(figure[1, 1], width = (Δx+2*padding_x) * 72 * drawing_scale, height = (Δy+2*padding_y) * 72 * drawing_scale);
    xlims!(0.0 - padding_x, joist_span.inputs.joist_dimensions.span_length + padding_x);
    ylims!(-joist_span.inputs.joist_dimensions.depth - padding_y, 0.0 + padding_y);
    hidedecorations!(ax);
    hidespines!(ax);  
    width_scale = maximum(member_width) * 72 * drawing_scale;
    # linewidths = member_width ./ maximum(member_width) * width_scale;

    #+ echo=false
    attributes = (scale = 3.0, tension_color="red", compression_color="blue");
    axial_forces = [joist_span.model.solution.forces[i][7] for i in eachindex(joist_span.model.solution.forces)];
    InstantFrame.Show.axial_force!(ax, Xij, Yij, axial_forces, attributes);
    resize_to_layout!(figure);

    #+ echo=false
    axial_forces = round.(axial_forces .* joist_span.design_load ./ 1000, digits=3);
    attributes = (fontsize = 5, color = :black);

    #+ echo=false
    #Show only chord and diagonal axial forces 
    #+ echo=false
    chord_element_index = findall(section->occursin("chord", section), joist_span.model.inputs.element.cross_section);
    diagonal_element_index = findall(section->occursin("diagonal", section), joist_span.model.inputs.element.cross_section);
    active_element_index = [chord_element_index; diagonal_element_index];
    #+ echo=false
    InstantFrame.Show.axial_force_magnitude!(ax, joist_span.model.inputs.element, joist_span.model.inputs.node, axial_forces, active_element_index, attributes);

    return ax, figure

end


end #module 