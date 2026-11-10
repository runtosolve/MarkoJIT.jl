module DesignCode

# Edition switch for the AISI S100 equations used by MarkoJIT.
#
# Every strength calculation in Strength.jl goes through the functions in this module, which send
# the call to AISIS100.v16 (AISI S100-16) or AISIS100.v2024 (AISI S100-2024) depending on the
# `design_code` string passed to evaluate_joist_span, e.g.
#
#     "AISI S100-16 ASD"   "AISI S100-16 LRFD"   "AISI S100-16 LSD"
#     "AISI S100-24 ASD"   "AISI S100-24 LRFD"   "AISI S100-24 LSD"   ("S100-2024" and "S100-2016" also accepted)
#
# Each function returns a NamedTuple (Rn = nominal strength, eRn = available strength).
#
# Provisions used by the joist and what changed from S100-16 to S100-2024:
#   tension yielding           D2   Eq. D2-1          unchanged
#   tension rupture            D3   Eq. D3-1          unchanged
#   global buckling            E2   Eqs. E2-1 to E2-4 unchanged
#   local buckling (DSM)       E3.2 Eq. E3.2-1       CHANGED: Pn = 1.2 Pne (1 + 0.10λ²)/(1 + 0.55λ²) ≤ Pne
#   distortional buckling      E4   Eq. E4-1          CHANGED: Pnd = 1.2 Py (1 + 0.05λd²)/(1 + 0.67λd²) ≤ Py
#   fillet weld                J2.5 (16) / J2.6 (24)  unchanged equations, section renumbered
#   bolt bearing               J3.3.1 + tables        unchanged
#   bolt shear                 App. A J3.4            unchanged
#   shear rupture              J6.1 + Table J6-1      CHANGED: bolts Ω = 2.22 → 2.00, ϕ(LRFD) = 0.65 → 0.75
#   rational eng. analysis     A1.2(c) / A1.2.6(c)    unchanged: connections Ω = 3.00, ϕ = 0.55 (LRFD), 0.50 (LSD)

using AISIS100, Unitful

export Spec, spec

struct Spec
    edition::Symbol     # :S100_16 or :S100_24
    method::String      # "ASD", "LRFD" or "LSD"
    label::String       # the design_code string as given
end

function spec(design_code::AbstractString)

    edition = if occursin(r"S100-?(2016|16)\b", design_code)
        :S100_16
    elseif occursin(r"S100-?(2024|24)\b", design_code)
        :S100_24
    else
        throw(ArgumentError("design_code must name the edition, e.g. \"AISI S100-16 ASD\" or \"AISI S100-24 ASD\"; got \"$design_code\""))
    end

    m = match(r"\b(ASD|LRFD|LSD)\b", design_code)
    m === nothing && throw(ArgumentError("design_code must name the design method (ASD, LRFD or LSD); got \"$design_code\""))

    return Spec(edition, m.captures[1], design_code)

end

spec(s::Spec) = s

edition_label(s::Spec) = s.edition == :S100_16 ? "AISI S100-16" : "AISI S100-2024"

factored(Rn, Ω, ϕ_LRFD, ϕ_LSD, s::Spec) = s.method == "ASD" ? Rn / Ω : (s.method == "LRFD" ? Rn * ϕ_LRFD : Rn * ϕ_LSD)

#### Chapter D -- tension

function tension_yield(Ag, Fy, design_code)
    s = spec(design_code)
    if s.edition == :S100_16
        Rn, eRn = AISIS100.v16.d21(Ag=Ag, Fy=Fy, design_code=s.method)
        return (Rn=Rn, eRn=eRn)
    else
        return AISIS100.v2024.d2__1(Ag, Fy, s.method)
    end
end

function tension_rupture(Anet, Fu, design_code)
    s = spec(design_code)
    if s.edition == :S100_16
        Rn, eRn = AISIS100.v16.d31(An=Anet, Fu=Fu, design_code=s.method)
        return (Rn=Rn, eRn=eRn)
    else
        return AISIS100.v2024.d3__1(Anet, Fu, s.method)
    end
end

#### Chapter E -- compression

function compression_global(Fcre, Fy, Ag, design_code)
    s = spec(design_code)
    if s.edition == :S100_16
        Rn, eRn = AISIS100.v16.e2(Fcre=Fcre, Fy=Fy, Ag=Ag, design_code=s.method)
        return (Rn=Rn, eRn=eRn)
    else
        return AISIS100.v2024.e2__1to4(Fcre, Fy, Ag, s.method)
    end
end

function compression_local(Pne, Pcrℓ, design_code)
    s = spec(design_code)
    if s.edition == :S100_16
        Rn, eRn = AISIS100.v16.e321(Pne=Pne, Pcrℓ=Pcrℓ, design_code=s.method)
        return (Rn=Rn, eRn=eRn)
    else
        sqrt(Pne/Pcrℓ) > 5.0 && @warn "S100-2024 Eq. E3.2-1 is limited to λℓ ≤ 5 (λℓ = $(sqrt(Pne/Pcrℓ)))"
        return AISIS100.v2024.e3_2__1to2(Pne, Pcrℓ, s.method)
    end
end

function compression_distortional(Py, Pcrd, design_code)
    s = spec(design_code)
    if s.edition == :S100_16
        Rn, eRn = AISIS100.v16.e41(Py=Py, Pcrd=Pcrd, design_code=s.method)
        return (Rn=Rn, eRn=eRn)
    else
        sqrt(Py/Pcrd) > 5.0 && @warn "S100-2024 Eq. E4-1 is limited to λd ≤ 5 (λd = $(sqrt(Py/Pcrd)))"
        return AISIS100.v2024.e4__1to3(Py, Pcrd, s.method)
    end
end

#### Chapter J -- connections (US customary units: in., kips, ksi)

# fillet weld, J2.5 (S100-16) / J2.6 (S100-2024); returns Pnv1, Pnv2, Pn (Eq. J2.5-7 / J2.6-7), Rn = governing nominal strength, eRn
function fillet_weld(L, t1, Fu1, t2, Fu2, tw, Fxx, loading_direction, design_code)
    s = spec(design_code)
    if s.edition == :S100_16
        Pnv1, Pnv2, Pn, Pnv, ePnv = AISIS100.v16.j25(L=L*u"inch", t1=t1*u"inch", Fu1=Fu1, t2=t2*u"inch", Fu2=Fu2, tw=tw*u"inch", Fxx=Fxx, loading_direction=loading_direction, design_code=s.method)
        return (Pnv1=ustrip(Pnv1), Pnv2=ustrip(Pnv2), Pn=ustrip(Pn), Rn=ustrip(Pnv), eRn=ustrip(ePnv))
    else
        r = AISIS100.v2024.j2_6__1to7(L, t1, Fu1, t2, Fu2, tw, Fxx, loading_direction, s.method)
        return (Pnv1=r.Pnv1, Pnv2=r.Pnv2, Pn=r.Pn, Rn=r.Rn, eRn=r.eRn)
    end
end

# Table J3.3.1-1, standard holes
function bearing_factor(d, t, design_code)
    s = spec(design_code)
    if s.edition == :S100_16
        return AISIS100.v16.tablej3311(d=d*u"inch", t=t*u"inch", hole_shape="standard hole")
    else
        return AISIS100.v2024.table_j3_3_1__1(d, t, "standard hole")
    end
end

# Table J3.3.1-2, single shear, standard holes, no washers under both head and nut
function bearing_modification_factor(design_code)
    s = spec(design_code)
    if s.edition == :S100_16
        return AISIS100.v16.tablej3312(connection_type="single shear", hole_shape="standard hole", washers="no")
    else
        return AISIS100.v2024.table_j3_3_1__2("single shear", "standard hole", "no")
    end
end

# Eq. J3.3.1-1
function bolt_bearing(C, mf, d, t, Fu, design_code)
    s = spec(design_code)
    if s.edition == :S100_16
        Rn, eRn = AISIS100.v16.j3311(C=C, mf=mf, d=d, t=t, Fu=Fu, design_code=s.method)
        return (Rn=Rn, eRn=eRn)
    else
        return AISIS100.v2024.j3_3_1__1(C, mf, d, t, Fu, s.method)
    end
end

# Appendix A, Eq. J3.4-1 (bolt shear, Fn = Fnv)
function bolt_shear(Ab, Fnv, design_code)
    s = spec(design_code)
    if s.edition == :S100_16
        Rn, eRn = AISIS100.v16.appAj341(Ab=Ab, Fn=Fnv, design_code=s.method)
        return (Rn=Rn, eRn=eRn)
    else
        return AISIS100.v2024.appendixA_j3_4__1(Ab, Fnv, s.method)
    end
end

# Eq. J6.1-1 with the bolt factors of Table J6-1
function shear_rupture_bolts(Anv, Fu, design_code)
    s = spec(design_code)
    if s.edition == :S100_16
        Rn, eRn = AISIS100.v16.j611(Anv, Fu, s.method, "bolts")
        return (Rn=Rn, eRn=eRn)
    else
        return AISIS100.v2024.j6_1__1(Fu, Anv, "bolts", s.method)
    end
end

# rational engineering analysis factors for connections, S100-16 A1.2(c) / S100-2024 A1.2.6(c)
function rational_analysis_connection_factors(design_code)
    spec(design_code)   # validates the string; the factors are the same in both editions
    return (Ω=3.00, ϕ_LRFD=0.55, ϕ_LSD=0.50)
end

end # module
