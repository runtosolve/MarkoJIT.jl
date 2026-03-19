using MarkoJIT 


calculate_diagonal_length_and_angle(x1, x2, y1, y2) 


joist.diagonal.L







Fy = 50000.0u"lbf/inch^2"
Fu = 65000.0u"lbf/inch^2"
E = 29500000.0u"lbf/inch^2"
ν = 0.30


bolt_diameter = 0.375u"inch"
bolt_hole_diameter = 0.394u"inch"

span_length = 50.0u"ft" |> u"inch"
joist_depth = 35.44u"inch"


struct Bolt 

    diameter
    hole_diameter 

    Fnv

end

struct Diagonal

    top_node
    bottom_node
    fy
    fu
    t

    L
    Lu 

    cross_section

    orientation

    section_properties

    global_buckling
    local_buckling

    Py
    Fcre 
    Pcrℓ
    Pne
    Pnℓ
    ePnℓ
    Tn_rupture
    Tn_yield 
    Tn 
    eTn 

end

struct Chord 

    fy
    fu
    t

    cross_section

    section_properties 

    local_buckling
    distortional_buckling 

    Py 
    Pcrd 
    Pcrℓ
    Pnd
    ePnd
    Pnℓ
    ePnℓ
    Tn_rupture
    Tn_yield
    Tn
    eTn

end


struct ShieldPlate 

    t
    hole_edge_spacing

end


struct UnreinforcedConnection

    Pn_bolt_shear 
    Pn_bolt_bearing
    
    Rn_bolt_shear
    Rn_bolt_bearing 
    Rn
    eRn 

end

struct ReinforcedConnection

    Pn_bolt_shear 
    Pn_bolt_bearing
    Pn_shield_plate_rupture
    
    Rn_bolt_shear
    Rn_shield_plate
    Rn_bolt_bearing 
    Rn
    eRn 
end

struct Girder 

    fu 
    flange_width 
    flange_thickness 

end


struct BearingSeat 

    t
    weld_length
    weld_thickness 
    num_top_chord_bolts 

    Rn_top_chord_connection
    Rn_diagonal_connection 
    Rn_welded_connection 
    Rn_compression_field 

    Q_top_chord_connection
    Q_diagonal_connection 
    Q_welded_connection 
    Q_compression_field 

    compression_field_width 
    fcrℓ
    Pnℓ

end


struct Joist 

    

    properties 
    component_strengths
    system_strength



    diagonals 
    chord 
    bearing_seat
    connections 

end
