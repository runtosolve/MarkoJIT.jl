module SpanTables

using Serialization, DataFrames, CSV
using ..Geometry, ..Joist

function generate_MIN_MAX_span_table_results(span_lengths, joist_depth, bolt_properties, joist_material_properties, diagonal_size_MAX, diagonal_size_MIN, design_code, chord_dimensions, diagonal_dimensions, shield_plate_dimensions, bearing_seat_dimensions, chord_splice_dimensions, girder_dimensions, girder_material_properties, bearing_seat_weld_properties)

    JIT_MAX_spans = Vector{Joist.JoistSpan}(undef, length(span_lengths))
    JIT_MIN_spans = Vector{Joist.JoistSpan}(undef, length(span_lengths))

    for i in eachindex(span_lengths)
        joist_dimensions = Geometry.JoistDimensions(span_length = span_lengths[i], depth = joist_depth, node_spacing = 48.0, bottom_chord_tail_length = 12.0);
        num_diagonals = Geometry.calculate_number_of_joist_diagonals(joist_dimensions.span_length, joist_dimensions.node_spacing);
        diagonal_sections = [[diagonal_size_MAX, diagonal_size_MAX]; fill(diagonal_size_MAX, num_diagonals - 4); [diagonal_size_MAX, diagonal_size_MAX]];
        diagonal_bracing = [["braced", "braced"]; fill("braced", num_diagonals - 4); ["braced", "braced"]];
        top_chord_connections = ["bearing seat"; fill("reinforced connection", num_diagonals-2); "bearing seat"];
        bottom_chord_connections = ["bearing seat"; fill("reinforced connection", num_diagonals-2); "bearing seat"];
        JIT_MAX_spans[i] = Joist.evaluate_joist_span(design_code, joist_dimensions, chord_dimensions, diagonal_dimensions, bolt_properties, shield_plate_dimensions, diagonal_sections, diagonal_bracing, bearing_seat_dimensions, chord_splice_dimensions,  girder_dimensions, girder_material_properties, bearing_seat_weld_properties, joist_material_properties, top_chord_connections, bottom_chord_connections);


        joist_dimensions = Geometry.JoistDimensions(span_length = span_lengths[i], depth = joist_depth, node_spacing = 48.0, bottom_chord_tail_length = 12.0);
        num_diagonals = Geometry.calculate_number_of_joist_diagonals(joist_dimensions.span_length, joist_dimensions.node_spacing);
        diagonal_sections = [[diagonal_size_MIN[1], diagonal_size_MIN[1]]; fill(diagonal_size_MIN[2], num_diagonals - 4); [diagonal_size_MIN[1], diagonal_size_MIN[1]]];
        diagonal_bracing = [["unbraced", "unbraced"]; fill("unbraced", num_diagonals - 4); ["unbraced", "unbraced"]];
        top_chord_connections = ["bearing seat"; fill("unreinforced connection", num_diagonals-2); "bearing seat"];
        bottom_chord_connections = ["bearing seat"; fill("unreinforced connection", num_diagonals-2); "bearing seat"];
        JIT_MIN_spans[i] = Joist.evaluate_joist_span(design_code, joist_dimensions, chord_dimensions, diagonal_dimensions, bolt_properties, shield_plate_dimensions, diagonal_sections, diagonal_bracing, bearing_seat_dimensions, chord_splice_dimensions,  girder_dimensions, girder_material_properties, bearing_seat_weld_properties, joist_material_properties, top_chord_connections, bottom_chord_connections);

    end

    return JIT_MAX_spans, JIT_MIN_spans

end


function display_span_table(results_path, results_files, span_lengths, table_range)

    JIT36_MIN_spans = deserialize(joinpath(results_path, results_files[1]))
    JIT36_MAX_spans = deserialize(joinpath(results_path, results_files[2]))
    JIT48_MIN_spans = deserialize(joinpath(results_path, results_files[3]))
    JIT48_MAX_spans = deserialize(joinpath(results_path, results_files[4]))
    JIT60_MIN_spans = deserialize(joinpath(results_path, results_files[5]))
    JIT60_MAX_spans = deserialize(joinpath(results_path, results_files[6]))

    span_table = DataFrame();
    span_table.A = floor.(Int, span_lengths/12.0)[table_range];
    span_table.B = [round(JIT36_MIN_spans[i].design_load, digits=1) for i in eachindex(span_lengths)][table_range];
    span_table.C = [round(JIT36_MAX_spans[i].design_load, digits=1) for i in eachindex(span_lengths)][table_range];
    span_table.D = [round(JIT48_MIN_spans[i].design_load, digits=1) for i in eachindex(span_lengths)][table_range];
    span_table.E = [round(JIT48_MAX_spans[i].design_load, digits=1) for i in eachindex(span_lengths)][table_range];
    span_table.F = [round(JIT60_MIN_spans[i].design_load, digits=1) for i in eachindex(span_lengths)][table_range];
    span_table.G = [round(JIT60_MAX_spans[i].design_load, digits=1) for i in eachindex(span_lengths)][table_range];


    #+ echo=false
    rename!(span_table, :A => :span_length);
    rename!(span_table, :B => :JIT36_MIN);
    rename!(span_table, :C => :JIT36_MAX);
    rename!(span_table, :D => :JIT48_MIN);
    rename!(span_table, :E => :JIT48_MAX);
    rename!(span_table, :F => :JIT60_MIN);
    rename!(span_table, :G => :JIT60_MAX);

    return span_table

end



function create_MAX_MIN_span_table_CSV(span_lengths, source_path, source_files, csv_path, csv_filename)

    JIT36_MIN_spans = deserialize(joinpath(source_path, source_files[1]));
    JIT36_MAX_spans = deserialize(joinpath(source_path, source_files[2]));
    JIT48_MIN_spans = deserialize(joinpath(source_path, source_files[3]));
    JIT48_MAX_spans = deserialize(joinpath(source_path, source_files[4]));
    JIT60_MIN_spans = deserialize(joinpath(source_path, source_files[5]));
    JIT60_MAX_spans = deserialize(joinpath(source_path, source_files[6]));

    span_table = DataFrame();
    span_table.A = floor.(Int, span_lengths/12.0);

    joist_spans = JIT36_MIN_spans;
    span_table.B = [round(joist_spans[i].design_load, digits=1) for i in eachindex(span_lengths)];
    span_table.C = [joist_spans[i].demand_to_capacity.controlling for i in eachindex(span_lengths)];

    joist_spans = JIT36_MAX_spans;
    span_table.D = [round(joist_spans[i].design_load, digits=1) for i in eachindex(span_lengths)];
    span_table.E = [joist_spans[i].demand_to_capacity.controlling for i in eachindex(span_lengths)];

    joist_spans = JIT48_MIN_spans;
    span_table.F = [round(joist_spans[i].design_load, digits=1) for i in eachindex(span_lengths)];
    span_table.G = [joist_spans[i].demand_to_capacity.controlling for i in eachindex(span_lengths)];

    joist_spans = JIT48_MAX_spans;
    span_table.H = [round(joist_spans[i].design_load, digits=1) for i in eachindex(span_lengths)];
    span_table.I = [joist_spans[i].demand_to_capacity.controlling for i in eachindex(span_lengths)];

    joist_spans = JIT60_MIN_spans;
    span_table.J = [round(joist_spans[i].design_load, digits=1) for i in eachindex(span_lengths)];
    span_table.K = [joist_spans[i].demand_to_capacity.controlling for i in eachindex(span_lengths)];

    joist_spans = JIT60_MAX_spans;
    span_table.L = [round(joist_spans[i].design_load, digits=1) for i in eachindex(span_lengths)];
    span_table.M = [joist_spans[i].demand_to_capacity.controlling for i in eachindex(span_lengths)];



    #+ echo=false
    rename!(span_table, :A => :span_length);
    rename!(span_table, :B => :JIT36_MIN);
    rename!(span_table, :C => :JIT36_MIN_LS);
    rename!(span_table, :D => :JIT36_MAX);
    rename!(span_table, :E => :JIT36_MAX_LS);
    rename!(span_table, :F => :JIT48_MIN);
    rename!(span_table, :G => :JIT48_MIN_LS);
    rename!(span_table, :H => :JIT48_MAX);
    rename!(span_table, :I => :JIT48_MAX_LS);
    rename!(span_table, :J => :JIT60_MIN);
    rename!(span_table, :K => :JIT60_MIN_LS);
    rename!(span_table, :L => :JIT60_MAX);
    rename!(span_table, :M => :JIT60_MAX_LS);


    output_filename = joinpath(csv_path, csv_filename);
    CSV.write(output_filename, span_table);

end


end #module